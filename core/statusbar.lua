setfenv(1, DFUI:GetEnv())

-- 各单位框体把自己的血条注册到这里, 供治疗预读模块消费
-- (血条都存在各模块 NewMod 闭包内的 local Setup 表里, 外部拿不到)
DFUI.predictBars = DFUI.predictBars or {}

local animations = setmetatable({}, { __mode = "k" })
local pulses = setmetatable({}, { __mode = "k" })
local cutouts = setmetatable({}, { __mode = "k" })

local ANIMATION_RATE = 6
local PULSE_DURATION = 0.3
local PULSE_FADE_IN = 0.1
local PULSE_CURVE = 0.7
local CUTOUT_DURATION = .3
local CUTOUT_ALPHA = 1
local ABSORB_PATH = 'Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\unitframes\\'

-- Cutout texture pool per bar (avoids permanent texture allocation leak)
local cutoutPools = setmetatable({}, { __mode = "k" })

local function AcquireCutoutTexture(bar)
    local pool = cutoutPools[bar]
    if not pool then
        pool = {}
        cutoutPools[bar] = pool
    end
    for i = 1, table.getn(pool) do
        local tex = pool[i]
        if not tex._inUse then
            tex._inUse = true
            tex:Show()
            tex:ClearAllPoints()
            return tex
        end
    end
    local tex = bar:CreateTexture(nil, 'ARTWORK')
    tex._inUse = true
    table.insert(pool, tex)
    return tex
end

local function ReleaseCutoutTexture(tex)
    tex._inUse = false
    tex:Hide()
    tex:SetAlpha(0)
end

-- public
function CreateStatusBar(parent, width, height, animConfig)
    local bar = CreateFrame('Frame', nil, parent)
    bar:SetWidth(width or 200)
    bar:SetHeight(height or 20)

    bar.bg = bar:CreateTexture(nil, 'BACKGROUND')
    bar.bg:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, 0)
    bar.bg:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 0, 0)
    bar.bg:SetTexture('Interface\\Buttons\\WHITE8X8')
    bar.bg:SetVertexColor(0, 0, 0, 0.5)

    bar.fill = bar:CreateTexture(nil, 'ARTWORK')
    bar.fill:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, 0)
    bar.fill:SetTexture('Interface\\TargetingFrame\\UI-StatusBar')
    bar.fill:SetVertexColor(0, 0.9, 0.2, 1)

    bar.val = 0
    bar.val_ = 0
    bar.max = 1
    bar.baseColor = {0, 0.9, 0.2, 1}
    bar.pulseColor = {1, 1, 1, 1}
    bar.cutoutColor = {0, 0.9, 0.2, 1}
    bar.bgColor = {0, 0, 0, 0.5}
    bar.cutoutDuration = CUTOUT_DURATION
    bar.cutoutTexture = 'Interface\\TargetingFrame\\UI-StatusBar'
    bar.fillDirection = 'LEFT_TO_RIGHT'
    bar.cutoutSuppressed = 0
    -- 治疗预读层 (惰性创建, 见 EnablePrediction)
    bar.predictColor = {0, 1, 0, 0.6}
    bar.predictOverheal = 20
    bar.predictAmount = 0
    -- 护盾吸收层 (惰性创建, 见 EnableAbsorb)。默认值取自 retail:
    -- unitframe.xml OverAbsorbGlowTemplate <Size x="16"/> + unitframe.lua:106 的 -7 偏移
    -- + UnitFrame_Initialize 里的 overlay.tileSize = 32
    bar.absorbAmount = 0
    bar.absorbGlowWidth = 16
    bar.absorbGlowOffset = -7
    bar.absorbTileSize = 32
    bar.absorbAlpha = 1
    bar.absorbTint = {1, 1, 1}
    bar.absorbOverlay = true
    bar.absorbGlowShow = true

    animConfig = animConfig or {}
    bar.enableBarAnim = animConfig.barAnim ~= false
    bar.enablePulse = animConfig.pulse ~= false
    bar.enableCutout = animConfig.cutout ~= false

    function bar:Update()
        if self.max <= 0 then
            self.fill:SetWidth(0)
            self.fill:SetHeight(self:GetHeight())
            if self.predict then self.predict:Hide() end
            if self.predictCap then self.predictCap:Hide() end
            if self.absorb then self:HideAbsorb() end
            return
        end
        local pct = self.val_ / self.max
        if pct <= 0.001 then
            pct = 0.001
        elseif pct > 1 then
            pct = 1
        end
        if self.fillDirection == 'RIGHT_TO_LEFT' then
            self.fill:SetTexCoord(1-pct, 1, 0, 1)
        else
            self.fill:SetTexCoord(0, pct, 0, 1)
        end
        self.fill:SetWidth(self:GetWidth() * pct)
        self.fill:SetHeight(self:GetHeight())
        -- 预读层必须跟着重算: 血条是 lerp 平滑动画的, 只在轮询时算一次
        -- 会让预读条起点在动画期间与血条末端脱节
        if self.predict then self:UpdatePrediction() end
        -- 护盾层同理: 它锚在"血量末端(+预读段)"之后, 不跟着 lerp 走就会脱节
        if self.absorb then self:UpdateAbsorb() end
    end

    function bar:SetValue(val, instant)
        -- only process if value actually changed
        if self.val ~= val then
            local currentTime = GetTime()
            local oldVal = self.val
            if val < oldVal and not instant and self.enableCutout and currentTime > self.cutoutSuppressed and self.max > 0 then
                -- calculate old and new percentages (clamped to [0,1] so a power-type
                -- switch — where oldVal belongs to the previous power and far exceeds the
                -- new max — can't drive TexCoord/width out of bounds)
                local oldPct = oldVal / self.max
                local newPct = val / self.max
                if oldPct > 1 then oldPct = 1 elseif oldPct < 0 then oldPct = 0 end
                if newPct > 1 then newPct = 1 elseif newPct < 0 then newPct = 0 end
                local cutWidth = self:GetWidth() * (oldPct - newPct)

                -- acquire cutout texture from pool (avoids permanent allocation)
                local cutout = AcquireCutoutTexture(self)
                cutout:SetTexture(self.cutoutTexture)
                cutout:SetVertexColor(self.cutoutColor[1], self.cutoutColor[2], self.cutoutColor[3], CUTOUT_ALPHA)
                -- set texture coordinates for cutout portion
                if self.cutoutTexCoord then
                    cutout:SetTexCoord(self.cutoutTexCoord[1], self.cutoutTexCoord[2], self.cutoutTexCoord[3], self.cutoutTexCoord[4])
                else
                    if self.fillDirection == 'RIGHT_TO_LEFT' then
                        cutout:SetTexCoord(1-oldPct, 1-newPct, 0, 1)
                    else
                        cutout:SetTexCoord(newPct, oldPct, 0, 1)
                    end
                end
                -- constrain cutout width to bar boundaries
                local maxCutWidth = self:GetWidth() * (self.fillDirection == 'RIGHT_TO_LEFT' and oldPct or (1 - newPct))
                cutWidth = math.min(cutWidth, maxCutWidth)
                -- position cutout at the lost value area
                if self.fillDirection == 'RIGHT_TO_LEFT' then
                    cutout:SetPoint('TOPLEFT', self, 'TOPLEFT', self:GetWidth() * (1-oldPct), 0)
                else
                    cutout:SetPoint('TOPLEFT', self, 'TOPLEFT', self:GetWidth() * newPct, 0)
                end
                cutout:SetWidth(cutWidth)
                cutout:SetHeight(self:GetHeight())

                -- register cutout for fade animation
                cutouts[cutout] = {endTime = GetTime() + self.cutoutDuration, duration = self.cutoutDuration}
            end

            -- determine if we should use instant update
            local useInstant = instant or self.instant or (currentTime <= self.cutoutSuppressed)
            self.val = val
            -- handle animated vs instant updates
            if not useInstant and (self.enableBarAnim or self.enablePulse) then
                -- register for smooth value animation
                if self.enableBarAnim then
                    animations[self] = true
                end
                -- register for pulse color animation (damage only — recovery should not flash)
                if self.enablePulse and val < oldVal then
                    pulses[self] = GetTime() + PULSE_DURATION
                end
                -- if no bar animation, update display value immediately
                if not self.enableBarAnim then
                    self.val_ = val
                    self:Update()
                end
            else
                -- instant update - no animations
                pulses[self] = nil
                self.fill:SetVertexColor(self.baseColor[1], self.baseColor[2], self.baseColor[3], self.baseColor[4])
                self.val_ = val
                self:Update()
            end
        end
    end

    function bar:SetInstant(instant)
        self.instant = instant
    end

    function bar:SetBarAnimation(enabled)
        self.enableBarAnim = enabled
        if not enabled then animations[self] = nil end
    end

    function bar:SetPulseAnimation(enabled)
        self.enablePulse = enabled
        if not enabled then pulses[self] = nil end
    end

    function bar:SetCutoutAnimation(enabled)
        self.enableCutout = enabled
    end

    function bar:SuppressCutout(duration)
        self.cutoutSuppressed = GetTime() + (duration or 0.1)
    end

    function bar:SetTextures(fillTex, bgTex)
        self.fill:SetTexture(fillTex)
        self.bg:SetTexture(bgTex)
        self.cutoutTexture = fillTex
        -- 预读层复用血条同一张真实素材, 仅靠 vertexColor 染绿
        if self.predict then
            self.predict:SetTexture(fillTex)
            self.predict:SetVertexColor(self.predictColor[1], self.predictColor[2],
                self.predictColor[3], self.predictColor[4])
        end
        if self.predictCap then
            self.predictCap:SetTexture(fillTex)
            self.predictCap:SetVertexColor(self.predictColor[1], self.predictColor[2],
                self.predictColor[3], self.predictColor[4])
        end
    end

    function bar:SetFillColor(r, g, b, a)
        self.baseColor = {r, g, b, a}
        self.fill:SetVertexColor(r, g, b, a)
    end

    function bar:SetCutoutColor(r, g, b, a)
        self.cutoutColor = {r, g, b, a}
    end

    function bar:SetPulseColor(r, g, b, a)
        self.pulseColor = {r, g, b, a}
    end

    function bar:SetBgColor(r, g, b, a)
        self.bgColor = {r, g, b, a}
        self.bg:SetVertexColor(r, g, b, a)
    end

    -- ═══ 治疗预读层 ═══
    -- 右端增量式: 从当前血量末端往右画增量长度, 允许溢出满血线 predictOverheal%
    -- texture 挂在 bar 内部(而非独立 frame), 同一 frame 内 layer 顺序确定,
    -- 天然规避跨 frame 同 (strata, level) 随机互盖的问题

    function bar:EnablePrediction()
        if self.predict then return self.predict end
        local tex = self:CreateTexture(nil, 'OVERLAY')
        tex:SetTexture(self.cutoutTexture)
        tex:SetVertexColor(self.predictColor[1], self.predictColor[2],
            self.predictColor[3], self.predictColor[4])
        tex:Hide()
        self.predict = tex
        -- 圆角帽: 单独一张贴纹理最右端。血条纹理是左暗右亮的横向渐变(约 1.6 倍),
        -- 若整条预读都去取纹理尾段, 颜色会比血条末端亮一大截, 像贴上去的亮块。
        -- 所以拆两段: 中段接着血条继续采样(保住渐变), 只有右缘这一小顶取纹理最右,
        -- 把素材自带的圆角收边带过来。
        local cap = self:CreateTexture(nil, 'OVERLAY')
        cap:SetTexture(self.cutoutTexture)
        cap:SetVertexColor(self.predictColor[1], self.predictColor[2],
            self.predictColor[3], self.predictColor[4])
        cap:Hide()
        self.predictCap = cap
        return tex
    end

    function bar:SetPredictionColor(r, g, b, a)
        self.predictColor = {r, g, b, a}
        if self.predict then self.predict:SetVertexColor(r, g, b, a) end
        if self.predictCap then self.predictCap:SetVertexColor(r, g, b, a) end
    end

    function bar:SetPredictionOverheal(pct)
        self.predictOverheal = pct or 20
        if self.predict then self:UpdatePrediction() end
    end

    -- 圆角帽在纹理里占的宽度比例。healthDF2.tga 头尾各 2 列是 alpha 收边,
    -- 取 3 列留一点余量; 显示宽度按同比例算, 所以圆角是 1:1 过来的不会变形。
    local PREDICT_CAP = 3 / 128

    function bar:UpdatePrediction()
        local tex, cap = self.predict, self.predictCap
        if not tex then return end

        local amount = self.predictAmount or 0
        if amount <= 0 or self.max <= 0 then
            tex:Hide()
            if cap then cap:Hide() end
            return
        end

        local W = self:GetWidth()
        local H = self:GetHeight()
        local hpPct = self.val_ / self.max
        if hpPct > 1 then hpPct = 1 elseif hpPct < 0 then hpPct = 0 end

        local healthWidth = W * hpPct
        local incWidth = W * (amount / self.max)

        -- 溢出封顶
        local limit = W * (1 + (self.predictOverheal or 20) / 100)
        if healthWidth + incWidth > limit then
            incWidth = limit - healthWidth
        end

        if incWidth <= 0 then
            tex:Hide()
            if cap then cap:Hide() end
            return
        end

        local mirror = (self.fillDirection == 'RIGHT_TO_LEFT')
        -- 把一段贴到"距离血条起始端 offset 处、宽 w"的位置, 采样区间 u1..u2
        local function place(t, offset, w, u1, u2)
            t:ClearAllPoints()
            t:SetWidth(w)
            t:SetHeight(H)
            if mirror then
                t:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -offset, 0)
                t:SetTexCoord(1 - u2, 1 - u1, 0, 1)
            else
                t:SetPoint('TOPLEFT', self, 'TOPLEFT', offset, 0)
                t:SetTexCoord(u1, u2, 0, 1)
            end
            t:Show()
        end

        local capW = W * PREDICT_CAP

        if not cap or incWidth <= capW then
            -- 太短了放不下"中段+帽子", 整段当帽子用(圆角会被压窄一点, 可接受)
            local frac = incWidth / W
            if frac > 1 then frac = 1 end
            place(tex, healthWidth, incWidth, 1 - frac, 1)
            if cap then cap:Hide() end

        else
            -- 中段接着血条末端继续采样(亮度平滑接续) + 右缘一顶圆角帽。
            -- ⚠ 满血溢出时也走这里, 别再给它开"整张纹理"的特殊分支:
            -- 溢出段只有 W*overheal% 宽(默认约 26px), 把 128px 纹理整个压进去,
            -- 两端 3/128 的圆角会被压成 0.6px = 肉眼等于直角。帽子必须保持
            -- 1:1 比例(capW = W*3/128 对应采样 3/128)圆角才画得出来。
            -- 满血时 bodyU1=1 会让下面的区间反向, 由 fallback 兜住。
            local bodyW = incWidth - capW
            local bodyU1 = hpPct
            local bodyU2 = hpPct + bodyW / W
            -- 中段的采样终点必须给帽子让位, 不能自己采进纹理尾部的收边区 ——
            -- 否则中段右缘先收窄一次, 帽子再画一次圆角, 拼缝处会露出一条竖线。
            local BODY_MAX = 1 - PREDICT_CAP
            if bodyU2 > BODY_MAX then bodyU2 = BODY_MAX end
            if bodyU2 <= bodyU1 then
                -- 血量已经高到没有可用采样区间了(接近满血), 退一小段实色区顶上
                bodyU1 = BODY_MAX - 0.05
                bodyU2 = BODY_MAX
            end
            place(tex, healthWidth, bodyW, bodyU1, bodyU2)
            place(cap, healthWidth + bodyW, capW, 1 - PREDICT_CAP, 1)
        end
    end

    -- amount 为绝对治疗量; 0/nil 表示隐藏
    -- 刻意不做"amount 没变就 return"的短路: 切目标时治疗量可能不变但 self.max 变了,
    -- 短路会让几何继续用旧 max 算。UpdatePrediction 只是几次算术, 每 tick 重算无妨。
    function bar:SetPrediction(amount)
        self.predictAmount = amount or 0
        self:UpdatePrediction()
    end

    -- ═══ 护盾吸收层 ═══
    -- 严格复刻 retail DF 10.1 (_references/.../framexml/unitframe.lua):
    --   :283-405 计算与钳位   :437-470 段宽公式   :104-107 溢出光柱锚点
    -- 核心规则(暴雪原注释): "We don't fill outside the health bar with absorbs.
    -- Instead, an overAbsorbGlow is shown." → 护盾段被截断到剩余空槽,
    -- 满血时段宽恒为 0, 只剩右端一根光柱。
    --
    -- 与预读层同样把 texture 挂在 bar 内部: 同一 frame 内 layer 顺序确定(创建顺序),
    -- 天然规避跨 frame 同 (strata, level) 随机互盖。创建次序必须是
    --   predict → fill → stripes[] → glow
    -- 才能得到 retail 的叠放关系(glow 在 stripes 之上, 见 unitframe.xml:116-119)。

    function bar:EnableAbsorb()
        if self.absorb then return self.absorb end
        -- 幂等: 保证预读纹理先于护盾纹理创建, 护盾恒画在预读之上
        self:EnablePrediction()

        local A = {stripes = {}}

        A.fill = self:CreateTexture(nil, 'OVERLAY')
        A.fill:SetTexture(ABSORB_PATH .. 'shield-fill.blp')
        A.fill:Hide()

        -- 斜纹池一次建满。1.12 没有 SetTexture 的 wrap 参数, retail 的
        -- horizTile 平铺只能靠 N 张 tileSize 宽的贴图手工拼接。
        -- 条宽创建后不再变更(DFUI 全局无 healthBar:SetWidth), 所以池尺寸在此定死;
        -- 万一将来条被加宽, UpdateAbsorb 会把最后一张拉伸兜底(见那里的注释),
        -- 绝不会在 glow 之后新建纹理而破坏叠放次序。
        local n = math.ceil((self:GetWidth() or 0) / (self.absorbTileSize or 32)) + 2
        if n < 3 then n = 3 end
        for i = 1, n do
            local t = self:CreateTexture(nil, 'OVERLAY')
            t:SetTexture(ABSORB_PATH .. 'shield-overlay.blp')
            t:Hide()
            A.stripes[i] = t
        end

        A.glow = self:CreateTexture(nil, 'OVERLAY')
        A.glow:SetTexture(ABSORB_PATH .. 'shield-overshield.blp')
        -- retail alphaMode="ADD"。这张图无 alpha 通道, 纯黑靠 ADD 变透明,
        -- 所以绝不能用 SetVertexColor 调色/调暗(纯黑染不动, ADD 下压暗只会整体消失),
        -- 要调强度只能走 SetAlpha。
        A.glow:SetBlendMode('ADD')
        A.glow:Hide()

        self.absorb = A
        return A
    end

    function bar:HideAbsorb()
        local A = self.absorb
        if not A then return end
        A.fill:Hide()
        A.glow:Hide()
        for i = 1, table.getn(A.stripes) do A.stripes[i]:Hide() end
    end

    function bar:UpdateAbsorb()
        local A = self.absorb
        if not A then return end

        local amount = self.absorbAmount or 0
        if amount <= 0 or self.max <= 0 then
            self:HideAbsorb()
            return
        end
        -- 反向填充条(目标框法力条那类)几何是镜像的, 本层只服务玩家血条, 不猜
        if self.fillDirection == 'RIGHT_TO_LEFT' then
            self:HideAbsorb()
            return
        end

        local W = self:GetWidth()
        local H = self:GetHeight()

        -- 起点 = 血量末端(+预读段), 即 retail 的 appendTexture 链
        -- (unitframe.lua:395-404: 护盾接在治疗预读之后)
        local hpPct = self.val_ / self.max
        if hpPct > 1 then hpPct = 1 elseif hpPct < 0 then hpPct = 0 end
        local startX = W * hpPct
        if self.predict and self.predict:IsShown() then
            startX = startX + self.predict:GetWidth()
        end
        -- 预读允许溢出满血线(predictOverheal), 护盾不允许
        if startX > W then startX = W end

        -- retail 钳位 (unitframe.lua:327-337)
        local want = (amount / self.max) * W
        local room = W - startX
        local over = false
        if want >= room then
            over = true
            want = room
        end
        if want < 0 then want = 0 end

        local alpha = self.absorbAlpha or 1
        local tint = self.absorbTint or {1, 1, 1}

        -- ── 护盾段主体: 整张纹理横向拉伸。这张图是竖向渐变、横向均匀,
        --    所以 TexCoord 保持默认(纵向取满), 只改宽度。
        if want > 0.5 then
            A.fill:ClearAllPoints()
            A.fill:SetPoint('TOPLEFT', self, 'TOPLEFT', startX, 0)
            A.fill:SetWidth(want)
            A.fill:SetHeight(H)
            A.fill:SetVertexColor(tint[1], tint[2], tint[3], 1)
            A.fill:SetAlpha(alpha)
            A.fill:Show()
        else
            A.fill:Hide()
        end

        -- ── 斜纹叠层: retail 是 overlay:SetTexCoord(0, barSize/32, 0, height/32) + 平铺。
        --    这里逐张 32px 拼, 末张按余量截 u。纹理本身可平铺(u=1 接 u=0 连续), 无拼缝。
        local TS = self.absorbTileSize or 32
        local vMax = H / TS
        if vMax > 1 then vMax = 1 end
        local slots = table.getn(A.stripes)
        local used = 0
        if self.absorbOverlay and want > 0.5 then
            local rest = want
            while rest > 0.5 and used < slots do
                used = used + 1
                local t = A.stripes[used]
                local w = rest
                if w > TS then w = TS end
                -- 池耗尽兜底(仅当条被加宽到超出建池时的假设): 最后一张吃掉全部余量。
                -- 这会损失该段的平铺重复, 但绝不越界、也绝不新建纹理破坏叠放次序。
                if used == slots and rest > TS then w = rest end
                t:ClearAllPoints()
                t:SetPoint('TOPLEFT', self, 'TOPLEFT', startX + (used - 1) * TS, 0)
                local u2 = w / TS
                if u2 > 1 then u2 = 1 end
                t:SetWidth(w)
                t:SetHeight(H)
                t:SetTexCoord(0, u2, 0, vMax)
                t:SetAlpha(alpha)
                t:Show()
                rest = rest - w
            end
        end
        for i = used + 1, slots do A.stripes[i]:Hide() end

        -- ── 溢出光柱: retail 锚在血条右端内缩 7px, 宽 16 (unitframe.lua:104-107)
        if over and self.absorbGlowShow ~= false then
            local off = self.absorbGlowOffset or -7
            A.glow:ClearAllPoints()
            A.glow:SetPoint('TOPLEFT', self, 'TOPRIGHT', off, 0)
            A.glow:SetPoint('BOTTOMLEFT', self, 'BOTTOMRIGHT', off, 0)
            A.glow:SetWidth(self.absorbGlowWidth or 16)
            A.glow:SetAlpha(alpha)
            A.glow:Show()
        else
            A.glow:Hide()
        end
    end

    -- amount 为绝对吸收量; 0/nil 表示隐藏。
    -- 与 SetPrediction 同理不做"值没变就 return"的短路: max 变了几何也要重算。
    function bar:SetAbsorb(amount)
        self.absorbAmount = amount or 0
        if self.absorb then self:UpdateAbsorb() end
    end

    -- 样式一次性设置; 传 nil 的字段保持原值
    function bar:SetAbsorbStyle(opts)
        if not opts then return end
        if opts.alpha ~= nil then self.absorbAlpha = opts.alpha end
        if opts.tint ~= nil then self.absorbTint = opts.tint end
        if opts.overlay ~= nil then self.absorbOverlay = opts.overlay and true or false end
        if opts.glow ~= nil then self.absorbGlowShow = opts.glow and true or false end
        if opts.glowWidth ~= nil then self.absorbGlowWidth = opts.glowWidth end
        if opts.glowOffset ~= nil then self.absorbGlowOffset = opts.glowOffset end
        if self.absorb then self:UpdateAbsorb() end
    end

    function bar:SetFillDirection(direction)
        self.fillDirection = direction
        if direction == 'RIGHT_TO_LEFT' then
            self.fill:ClearAllPoints()
            self.fill:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, 0)
        else
            self.fill:ClearAllPoints()
            self.fill:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 0)
        end
        self:Update()
    end

    return bar
end

-- update functions
local function UpdateBarAnimations(dt)
    -- frame-rate independent lerp factor; clamp so big dt still completes in one step
    local factor = ANIMATION_RATE * dt
    if factor > 1 then factor = 1 end
    for bar in pairs(animations) do
        if bar.enableBarAnim then
            -- check if animation is complete
            if bar.instant or bar.val_ == bar.val then
                -- snap to final value
                bar.val_ = bar.val
                -- remove from animation table
                animations[bar] = nil
            else
                -- lerp current value toward target value
                bar.val_ = bar.val_ + (bar.val - bar.val_) * factor
            end
            -- update bar visual width
            bar:Update()
        else
            -- remove disabled bars
            animations[bar] = nil
        end
    end
end

local function UpdatePulseAnimations(now)
    for bar, endTime in pairs(pulses) do
        if bar.enablePulse then
            -- check if pulse is finished
            if now >= endTime then
                -- reset to base color
                bar.fill:SetVertexColor(bar.baseColor[1], bar.baseColor[2], bar.baseColor[3], bar.baseColor[4])
                bar:Update()
                -- remove from pulse table
                pulses[bar] = nil
            else
            -- calculate remaining time
            local timeLeft = endTime - now
            local progress
            -- determine fade phase
            if timeLeft > PULSE_DURATION * (1 - PULSE_FADE_IN) then
                -- fade in phase
                progress = 1 - ((timeLeft - PULSE_DURATION * (1 - PULSE_FADE_IN)) / (PULSE_DURATION * PULSE_FADE_IN))
            else
                -- fade out phase
                progress = (timeLeft / (PULSE_DURATION * (1 - PULSE_FADE_IN))) ^ PULSE_CURVE
            end
            -- interpolate between base and pulse colors
            local r = bar.baseColor[1] + (bar.pulseColor[1] - bar.baseColor[1]) * progress
            local g = bar.baseColor[2] + (bar.pulseColor[2] - bar.baseColor[2]) * progress
            local b = bar.baseColor[3] + (bar.pulseColor[3] - bar.baseColor[3]) * progress
            -- apply interpolated color
            bar.fill:SetVertexColor(r, g, b, 1)
            -- keep fill width/height in sync with current animated value (no scale puff)
            bar:Update()
            -- restore pulse color (bar:Update doesn't touch VertexColor, but explicit for safety against future edits)
            bar.fill:SetVertexColor(r, g, b, 1)
            end
        else
            -- remove disabled pulses
            pulses[bar] = nil
        end
    end
end

local function UpdateCutoutAnimations(now)
    for cutout, data in pairs(cutouts) do
        -- check if cutout fade is complete
        if now >= data.endTime then
            -- release cutout back to pool for reuse
            ReleaseCutoutTexture(cutout)
            cutouts[cutout] = nil
        else
            -- calculate fade progress
            local progress = (data.endTime - now) / data.duration
            -- apply fading alpha
            cutout:SetAlpha(CUTOUT_ALPHA * progress)
        end
    end
end

-- handler (auto-disables when idle, re-enabled by SetValue)
local animate = CreateFrame'Frame'
local lastUpdate = GetTime()
local function AnimateOnUpdate()
    local now = GetTime()
    local dt = now - lastUpdate
    lastUpdate = now
    UpdateBarAnimations(dt)
    UpdatePulseAnimations(now)
    UpdateCutoutAnimations(now)
    -- disable when all tables are empty
    if not next(animations) and not next(pulses) and not next(cutouts) then
        animate:SetScript('OnUpdate', nil)
    end
end

local function EnsureAnimating()
    if not animate:GetScript('OnUpdate') then
        -- reset clock so the first frame after idle doesn't snap with a huge dt
        lastUpdate = GetTime()
        animate:SetScript('OnUpdate', AnimateOnUpdate)
    end
end

-- Patch SetValue to re-enable the animation pump
local origCreateStatusBar = CreateStatusBar
function CreateStatusBar(parent, width, height, animConfig)
    local bar = origCreateStatusBar(parent, width, height, animConfig)
    local origSetValue = bar.SetValue
    bar.SetValue = function(self, val, instant)
        origSetValue(self, val, instant)
        EnsureAnimating()
    end
    return bar
end
