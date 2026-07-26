-- ═══════════════════════════════════════════════════════════════
-- 护盾吸收 (Absorb Shields) 表现层
-- 数据/解析在 libs/libabsorb.lua, 这里只负责: 队列记账 → 往血条刷值 + 追加文字
--
-- 观感严格复刻 retail DF 10.1 (见 core/statusbar.lua 的护盾层注释), 唯一补强是
-- 在生命值文字后追加吸收量 —— 因为 retail 满血时护盾段宽度恒为 0(只剩一根光柱),
-- 而"开怪前先套盾"恰恰全是满血场景, 不补数字就完全读不出量。
--
-- ⚠ 1.12 没有 UnitGetTotalAbsorbs, 服务端也不下发护盾剩余量。
--   全部数值都是客户端推算, 天生有误差上限, 详见 GUI 里各配置项的说明。
-- ═══════════════════════════════════════════════════════════════

DFUI:NewDefaults("Shield", {
    enabled = {true},

    -- ═══ 显示 ═══
    shieldShowBar = {true, "checkbox", nil, nil, "显示", 1,
        "在生命条上显示护盾吸收段", nil, nil},
    shieldOverlay = {true, "checkbox", nil, "shieldShowBar", "显示", 2,
        "护盾段叠加斜纹（巨龙时代原版效果）", nil, nil},
    shieldGlow = {true, "checkbox", nil, "shieldShowBar", "显示", 3,
        "护盾超出生命上限时在生命条右端显示光柱",
        "满血时护盾段宽度为 0，光柱是唯一的可视提示（原版行为）", nil},
    shieldGlowWidth = {16, "slider", {8, 32, 1}, "shieldGlow", "显示", 4,
        "溢出光柱宽度（原版为 16）", nil, nil},
    shieldGlowOffset = {-7, "slider", {-16, 4, 1}, "shieldGlow", "显示", 5,
        "光柱相对生命条右端的横向偏移（原版为 -7）", nil, nil},
    shieldAlpha = {1, "slider", {0.2, 1, 0.05}, "shieldShowBar", "显示", 6,
        "护盾段不透明度", nil, nil},
    shieldTint = {{1, 1, 1}, "colour", nil, "shieldShowBar", "显示", 7,
        "护盾段染色（原版为纯白不染色）", nil, nil},

    -- ═══ 文字 ═══
    shieldShowText = {true, "checkbox", nil, nil, "文字", 8,
        "在生命值文字后追加护盾总吸收量",
        "需要玩家框架的『显示生命值和法力值文字』同时开启", nil},
    shieldTextFormat = {"+N", "dropdown", {"+N", "(N)", "N"}, "shieldShowText", "文字", 9,
        "护盾数字的格式", nil, nil},
    shieldTextColor = {{0.55, 0.80, 1.00}, "colour", nil, "shieldShowText", "文字", 10,
        "护盾数字颜色", nil, nil},
    shieldTextShort = {false, "checkbox", nil, "shieldShowText", "文字", 11,
        "数值超过 1 万时缩写（12340 → 1.2万）", nil, nil},

    -- ═══ 数值 ═══
    shieldTalentFix = {true, "checkbox", nil, nil, "数值", 12,
        "按天赋等级修正护盾数值",
        "仅对自己会的法术生效；别人给你上的盾无法识别施法者，只用基础值", nil},
    shieldAutoCalibrate = {true, "checkbox", nil, nil, "数值", 13,
        "根据实际破盾伤害自动校准",
        "护盾被打满时记录真实吸收量，自动吃进法术强度/套装/服务器改动；换装或加点后重新学习", nil},
    shieldTrackWards = {true, "checkbox", nil, nil, "数值", 14,
        "追踪单属性防护结界（火焰/冰霜/暗影）",
        "关闭后只统计全属性护盾，数值更保守", nil},
    shieldUncertainMark = {true, "checkbox", nil, nil, "数值", 15,
        "无法确定扣减量时在数字前加 ~ 标记",
        "伤害被完全吸收时战斗日志不带数字，此时无法精确扣减", nil},

    -- ═══ 行为 ═══
    shieldSuppressCutout = {false, "checkbox", nil, nil, "行为", 16,
        "有护盾时抑制生命条掉血余晖（原版行为）",
        "注意：会连带关闭生命条的平滑动画，变成瞬时跳变", nil},
    shieldDebug = {false, "checkbox", nil, nil, "行为", 17,
        "输出护盾调试日志（/dfshield 始终可用）", nil, nil},
})

DFUI:NewMod("Shield", 2, function()
    local lib = DFUI_Libs and DFUI_Libs.libabsorb
    if not lib then return end

    -- Lua 5.0 每函数 upvalue <= 32, 超出整文件不加载。
    -- 状态一律收进这几张表, 别散成一堆 local。
    local S = {}            -- 设置快照
    local Q = {list = {}, total = 0, uncertain = false, spill = 0}
    local UI = {}           -- 控件引用
    local F = {t = -1, seen = {}, flagged = false, gotNum = false}   -- 帧批次
    local poller            -- 前置声明: Recalc 要唤醒它, 它在下面才建

    local INTERVAL = 0.1
    local acc = 0
    local REFRESH_TOL = 0.5      -- 剩余时间"变大"多少才算刷新
    local TIMEOUT_EDGE = 1.5     -- 消失前剩余时间小于此值 → 判超时, 不校准
    local CALIBRATE_WINDOW = 1.0 -- 最后一次扣减距消失多久内才认"是被打破的"

    local function Dbg(msg)
        if S.debug and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66aaff[护盾]|r " .. tostring(msg))
        end
    end

    -- ═══════════════════════════════════════════════════════
    -- 设置
    -- ═══════════════════════════════════════════════════════

    local function ReadSettings()
        S.showBar     = DFUI:GetTempDB("Shield", "shieldShowBar")
        S.showText    = DFUI:GetTempDB("Shield", "shieldShowText")
        S.textFormat  = DFUI:GetTempDB("Shield", "shieldTextFormat") or "+N"
        S.textColor   = DFUI:GetTempDB("Shield", "shieldTextColor") or {0.55, 0.8, 1}
        S.textShort   = DFUI:GetTempDB("Shield", "shieldTextShort")
        S.talentFix   = DFUI:GetTempDB("Shield", "shieldTalentFix")
        S.calibrate   = DFUI:GetTempDB("Shield", "shieldAutoCalibrate")
        S.trackWards  = DFUI:GetTempDB("Shield", "shieldTrackWards")
        S.uncertain   = DFUI:GetTempDB("Shield", "shieldUncertainMark")
        S.suppressCut = DFUI:GetTempDB("Shield", "shieldSuppressCutout")
        S.debug       = DFUI:GetTempDB("Shield", "shieldDebug")
    end

    local function ApplyStyle()
        local bar = UI.bar
        if not bar or not bar.absorb then return end
        bar:SetAbsorbStyle({
            alpha      = DFUI:GetTempDB("Shield", "shieldAlpha"),
            tint       = DFUI:GetTempDB("Shield", "shieldTint"),
            overlay    = DFUI:GetTempDB("Shield", "shieldOverlay"),
            glow       = DFUI:GetTempDB("Shield", "shieldGlow"),
            glowWidth  = DFUI:GetTempDB("Shield", "shieldGlowWidth"),
            glowOffset = DFUI:GetTempDB("Shield", "shieldGlowOffset"),
        })
    end

    -- ═══════════════════════════════════════════════════════
    -- 文字: 包裹 healthValue 的 SetText
    -- ═══════════════════════════════════════════════════════
    --
    -- 不另建 FontString: healthValue 的锚点是动态的(player.lua:433-439,
    -- 有百分比时 RIGHT -5, 无百分比时 CENTER -3), 在旁边挂东西会顶出血条外
    -- 或与 healthPercent 打架。包进同一个字符串, 布局问题自动消失,
    -- 还能白蹭 frameFont / healthSize 的配置变更。
    --
    -- 也不能往 DFUI.callbacks 里 append: core.lua:371 的 NewCallbacks 会先清空
    -- 整个回调表, Player 模块一重注册我们挂的东西就没了。

    local function FormatNum(v)
        if S.textShort and v >= 10000 then
            return string.format("%.1f万", v / 10000)
        end
        return string.format("%d", v)
    end

    local function Suffix()
        if not S.showText then return "" end
        local total = Q.total
        if total <= 0 then return "" end
        local n = FormatNum(total)
        if S.textFormat == "+N" then n = "+" .. n
        elseif S.textFormat == "(N)" then n = "(" .. n .. ")" end
        -- ~ 放最前面读作"约等于", 放中间会变成 +~692 那种怪东西
        if Q.uncertain and S.uncertain then n = "~" .. n end
        local c = S.textColor
        -- 必须内嵌颜色码: player.lua 的 textColoringHealth 会对整个 FontString
        -- SetTextColor(1, pct, pct) 把血量染红, 那会连护盾数字一起染。
        -- 1.12 里内联 |cff..|r 的优先级高于 SetTextColor, 能保住独立配色。
        return string.format(" |cff%02x%02x%02x%s|r",
            math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255), n)
    end

    local function HookText()
        if UI.healthValue then return true end
        local t = DFUI.unitTexts and DFUI.unitTexts.player
        local hv = t and t.healthValue
        if not hv then return false end
        if not hv._dfAbsorbHook then
            hv._dfAbsorbHook = true
            local orig = hv.SetText
            hv.SetText = function(self, txt)
                self._dfAbsorbBase = txt or ""
                orig(self, self._dfAbsorbBase .. Suffix())
            end
        end
        UI.healthValue = hv
        return true
    end

    -- 护盾量变了但血量没变时主动重刷。不会递归: 传回的是同一个 base。
    local function RefreshText()
        local hv = UI.healthValue
        if hv and hv._dfAbsorbBase then hv:SetText(hv._dfAbsorbBase) end
    end

    -- ═══════════════════════════════════════════════════════
    -- 队列
    -- ═══════════════════════════════════════════════════════

    local function Recalc()
        -- 盾都没了, 上一轮的"不确定"也就没有意义了, 别让 ~ 粘到下一次上盾
        if table.getn(Q.list) == 0 and Q.uncertain then Q.uncertain = false end

        local sum = 0
        for i = 1, table.getn(Q.list) do
            local s = Q.list[i]
            local r = s.remaining
            -- 法力护盾还受法力量限制: 蓝不够时实际吸收不到标称值。
            -- 只钳显示, 不动 remaining 的记账(记账要留给校准用)。
            if s.manaPerPoint then
                local cap = math.floor((UnitMana("player") or 0) / s.manaPerPoint)
                if cap < r then r = cap end
            end
            if r > 0 then sum = sum + r end
        end
        Q.total = sum

        local bar = UI.bar
        if bar then
            if S.showBar then
                if not bar.absorb then
                    bar:EnableAbsorb()
                    ApplyStyle()
                end
                bar:SetAbsorb(sum)
            elseif bar.absorb then
                bar:SetAbsorb(0)
            end
        end
        RefreshText()

        -- 队列非空就唤醒轮询器(超时/刷新检测要靠它)
        if poller and table.getn(Q.list) > 0 and not poller:IsShown() then
            DFUI.activeScripts["ShieldPoller"] = true
            poller:Show()
        end
    end

    local function FindByTex(tex, name)
        for i = 1, table.getn(Q.list) do
            local s = Q.list[i]
            if s.tex == tex and s.name == name then return s, i end
        end
        return nil
    end

    -- 护盾离场。reason: "broken" / "timeout" / "dispel" / "wipe"
    local function Retire(s, reason)
        -- 校准: 只有"确实被打破"才敢学 —— 那一刻累计扣减量【就是】真实初始值。
        -- 这是 1.12 唯一能把法强/套装/服务器改动全吃进去的路径。
        --
        -- ⚠ "buff 消失了" 不等于 "被打破了"。手动右键取消、离开区域、
        --   被我们没认出来的方式移除, 都会走到这里, 而它们的 deducted 远小于真值,
        --   学下来会把估算越带越低。判据: 【最后一次扣减必须紧挨着消失那一刻】。
        --   真的被打破时, 打破它的那一下就在眼前; 取消/换区则早就没伤害了。
        if reason == "broken" and S.calibrate and s.deducted > 0 and not s.tainted
            and s.lastHit and (GetTime() - s.lastHit) <= CALIBRATE_WINDOW then
            -- 估低时超出的量记在 overflow 里(见 Deduct), 真值要把它加回来
            local trueValue = s.deducted + (s.overflow or 0)
            local drift = math.abs(trueValue - s.initial) / s.initial
            if drift > 0.05 then
                lib:Learn(s.name, s.rank, trueValue)
                Dbg("校准 " .. s.name .. " " .. s.initial .. " -> " .. trueValue)
            end
        end
        Dbg("移除 " .. s.name .. " (" .. reason .. ")")
    end

    -- 全量重扫玩家 buff, 与队列对账
    local function Rescan()
        local seen = {}
        local order = {}

        for uiIdx = 1, 32 do
            local tex = UnitBuff("player", uiIdx)
            if not tex then break end

            local existing = nil
            for i = 1, table.getn(Q.list) do
                if Q.list[i].uiIdx == uiIdx and Q.list[i].tex == tex then
                    existing = Q.list[i]
                    break
                end
            end

            local name, tipAbsorb
            if existing then
                name = existing.name
            else
                name, tipAbsorb = lib:ScanBuff(uiIdx)
            end

            if name then
                local s = existing or FindByTex(tex, name)
                if not s then
                    -- 新护盾: 只有能拿到可信初始值才进队列。
                    -- 认不出就【不追踪】, 绝不编一个数糊弄。
                    local amount, source = lib:GetInitial(name, uiIdx, tipAbsorb)
                    if amount and amount > 0 then
                        local schools = lib:SchoolsOf(name)
                        if schools and not S.trackWards then
                            amount = nil            -- 用户选择不追单属性结界
                        end
                        if amount then
                            local rankStr = DFUI_Libs.libspell
                                and DFUI_Libs.libspell:GetSpellMaxRank(name) or nil
                            s = {
                                name = name, tex = tex, uiIdx = uiIdx,
                                rank = rankStr, schools = schools,
                                initial = amount, remaining = amount, deducted = 0,
                                source = source, manaPerPoint = lib:ManaPerPoint(name),
                                -- 天赋修正被用户关掉时, 校准值会偏离"含天赋的真值",
                                -- 打个标记不让它污染学习库
                                tainted = (not S.talentFix) or nil,
                                lastTL = nil, firstSeen = GetTime(),
                            }
                            Dbg("新增 " .. name .. " = " .. amount .. " (" .. source .. ")")
                        end
                    end
                end

                if s then
                    s.uiIdx = uiIdx
                    -- 刷新检测: 剩余时间"变大"就是重新上了盾。
                    -- 这条通用规则替代 Nanami 的"虚弱灵魂刚出现"特判,
                    -- 对寒冰护体/法力护盾/各种结界一并生效。
                    local bIdx = UI.FindBuffIdx(tex)
                    local tl = bIdx and GetPlayerBuffTimeLeft and GetPlayerBuffTimeLeft(bIdx) or nil
                    if tl then
                        if s.lastTL and tl > s.lastTL + REFRESH_TOL then
                            -- 重新刮一次 buff tooltip: 重施时装备/天赋可能已经变了
                            local _, tip = lib:ScanBuff(uiIdx)
                            local amount, source = lib:GetInitial(s.name, uiIdx, tip)
                            s.initial = amount or s.initial
                            s.remaining = s.initial
                            s.deducted = 0
                            s.overflow = nil
                            s.source = source or s.source
                            Dbg("刷新 " .. s.name .. " -> " .. s.initial)
                        end
                        s.lastTL = tl
                    end
                    seen[s] = true
                    table.insert(order, {s = s, slot = bIdx or 999})
                end
            end
        end

        -- 退场
        local keep = {}
        for i = 1, table.getn(Q.list) do
            local s = Q.list[i]
            if not seen[s] then
                local reason = "broken"
                if s.dispelled then reason = "dispel"
                elseif s.lastTL and s.lastTL <= TIMEOUT_EDGE then reason = "timeout" end
                Retire(s, reason)
            end
        end

        -- 扣减顺序 = GetPlayerBuff 槽位升序。
        -- 服务端按光环槽位表迭代吸收; 槽位在施放时取最低空闲位, 所以稳定期
        -- 槽位序 == 施放序。更妙的是早期盾过期释放低位槽后, 槽位序才是服务端
        -- 真相 —— 自己记账施放序反而会永久错位。每次重扫都重读, 自愈。
        table.sort(order, function(a, b)
            if a.slot ~= b.slot then return a.slot < b.slot end
            return a.s.firstSeen < b.s.firstSeen
        end)
        for i = 1, table.getn(order) do keep[i] = order[i].s end
        Q.list = keep

        Recalc()
    end

    -- ═══════════════════════════════════════════════════════
    -- 扣减
    -- ═══════════════════════════════════════════════════════

    local function SchoolMatches(s, school)
        if not s.schools then return true end        -- 全学派盾, 什么都吃
        if not school then return false end          -- 物理/未知只能被全学派盾吃
        return s.schools[school] and true or false
    end

    local function Deduct(amount, school)
        if amount <= 0 then return end
        for i = 1, table.getn(Q.list) do
            local s = Q.list[i]
            if s.remaining > 0 and SchoolMatches(s, school) then
                local take = amount
                if take > s.remaining then take = s.remaining end
                s.remaining = s.remaining - take
                s.deducted = s.deducted + take
                s.lastHit = GetTime()        -- 校准判据: 见 Retire
                amount = amount - take
                if amount <= 0 then break end
            end
        end
        -- ── 溢出归属 ──
        -- 所有盾都被我们记成 0 了, 伤害却还在被吸收 → buff 还在, 说明【我们估低了】,
        -- 真实的盾还在扛。把超出的量记到第一个还挂着、且吃这个学派的盾头上:
        --   真实初始值 = deducted + overflow
        -- 少了这一步, 估低的情况下 deducted 永远被钳在 initial, drift 恒为 0,
        -- 校准就永远学不到东西 —— 而估低恰恰是常态(1.12 读不到法术强度)。
        if amount > 0 then
            Q.spill = Q.spill + amount
            for i = 1, table.getn(Q.list) do
                local s = Q.list[i]
                if SchoolMatches(s, school) then
                    s.overflow = (s.overflow or 0) + amount
                    s.lastHit = GetTime()
                    break
                end
            end
        end

        -- retail 在有护盾时取消掉血余晖动画 (unitframe.lua:811-814)。
        -- 默认关: 1.12 里被吸收的伤害不改变生命值, SetValue 根本不会以更小的值
        -- 被调用, 余晖本来就不触发; 唯一有区别的"部分吸收+部分穿透"确实掉了血,
        -- 画余晖反而是正确信息。而且 SuppressCutout 的副作用比字面大 ——
        -- statusbar.lua 的 useInstant 会把整条血条的平滑 lerp 一并变成瞬时跳变。
        if S.suppressCut and UI.bar and UI.bar.SuppressCutout then
            UI.bar:SuppressCutout(0.35)
        end

        Recalc()
    end

    -- 帧批次收尾。依据: 1.12 的 GetTime() 在同一帧内返回值恒定,
    -- 同一个伤害包产生的所有事件必然共享同一个 GetTime()。
    local function NewFrame()
        local now = GetTime()
        if now == F.t then return end
        -- 上一帧: 确实被完全吸收但整帧没拿到数字 → 只打标记, 绝不臆测扣减
        if F.flagged and not F.gotNum then
            if not Q.uncertain then
                Q.uncertain = true
                RefreshText()
            end
            Dbg("完全吸收, 无数值可扣")
        end
        F.t = now
        F.flagged = false
        F.gotNum = false
        for k in pairs(F.seen) do F.seen[k] = nil end
    end

    local function Wipe()
        for i = 1, table.getn(Q.list) do Retire(Q.list[i], "wipe") end
        Q.list = {}
        Q.uncertain = false
        Q.spill = 0
        Recalc()
    end

    -- ═══════════════════════════════════════════════════════
    -- 接线
    -- ═══════════════════════════════════════════════════════

    UI.FindBuffIdx = function(texture)
        -- UnitBuff 与 GetPlayerBuff 在 Turtle 上枚举顺序可能不一致,
        -- 必须按贴图换算 (与 auras.lua:479 FindPlayerBuffIndex 同款)
        if not texture or not GetPlayerBuff then return nil end
        for idx = 0, 31 do
            local bIdx = GetPlayerBuff(idx, "HELPFUL")
            if not bIdx or bIdx < 0 then return nil end
            if GetPlayerBuffTexture(bIdx) == texture then return bIdx end
        end
        return nil
    end

    local function Attach()
        if UI.bar then return true end
        local bar = DFUI.predictBars and DFUI.predictBars.player
        if not bar then return false end
        UI.bar = bar
        HookText()
        if S.showBar then
            bar:EnableAbsorb()
            ApplyStyle()
        end
        return true
    end

    local ABSORB_EVENTS = {
        "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
        "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
        "CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS",
        "CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES",
        "CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS",
        "CHAT_MSG_COMBAT_SELF_HITS",
        "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE",
        "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE",
        "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
        "CHAT_MSG_SPELL_SELF_DAMAGE",
        "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
        "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
        "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
    }
    local isAbsorbEvent = {}
    for i = 1, table.getn(ABSORB_EVENTS) do isAbsorbEvent[ABSORB_EVENTS[i]] = true end

    local f = CreateFrame("Frame", "DFUIShieldMonitor", UIParent)
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("UNIT_COMBAT")
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("PLAYER_DEAD")
    f:RegisterEvent("CHAT_MSG_SPELL_BREAK_AURA")
    for i = 1, table.getn(ABSORB_EVENTS) do f:RegisterEvent(ABSORB_EVENTS[i]) end

    f:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            ReadSettings()
            Attach()
            Wipe()
            Rescan()
            return
        end

        if not UI.bar and not Attach() then return end

        if event == "PLAYER_DEAD" then
            Wipe()
            return
        end

        if event == "UNIT_AURA" and arg1 == "player" then
            Rescan()
            return
        end

        if event == "UNIT_MAXHEALTH" and arg1 == "player" then
            -- max 变了, 护盾段的比例要重算(几何吃 amount/max)
            if UI.bar and UI.bar.absorb then UI.bar:UpdateAbsorb() end
            return
        end

        if event == "CHAT_MSG_SPELL_BREAK_AURA" and arg1 then
            -- 驱散/偷取: 比等 UNIT_AURA 快一帧, 且要标记成"不参与校准"
            for i = 1, table.getn(Q.list) do
                local s = Q.list[i]
                if string.find(arg1, s.name, 1, true) then
                    s.dispelled = true
                    Rescan()
                    break
                end
            end
            return
        end

        -- ── UNIT_COMBAT: 架构级去重的关键一环 ──
        -- 1.12 里 UNIT_COMBAT("player","ABSORB",...) 的 arg4 恒为 0
        -- (它只是飘字用的标记, 不携带数值), 真正带数的只有 CHAT_MSG_* 文本。
        -- 所以这里【永不出数】, 只置"本帧发生过完全吸收"。
        -- Nanami 的双重扣减(UNIT_COMBAT 与 CHAT_MSG 各扣一次)因此在结构上不可能发生。
        if event == "UNIT_COMBAT" and arg1 == "player" and arg2 == "ABSORB" then
            NewFrame()
            F.flagged = true
            return
        end

        if isAbsorbEvent[event] and arg1 then
            NewFrame()
            -- 帧内同源去重: 同一帧 + 同事件 + 逐字节相同的原文 = 重复投递。
            -- 用"原文全等"而不是"数值+时间窗": 时间窗会误杀两只怪打出同样伤害的
            -- 真实连击(系统性少扣), 而原文全等只在极罕见的完全相同日志上误杀。
            -- 方向是刻意的 —— 少扣是良性的(显示偏高, 盾消失时自动归零 + 校准修正),
            -- 多扣是恶性的(盾还在但数字已经归零)。
            local sig = event .. "\001" .. arg1
            if F.seen[sig] then return end
            F.seen[sig] = true

            local amount, school, src = lib:Parse(arg1)
            if amount and amount > 0 then
                F.gotNum = true
                if table.getn(Q.list) > 0 then
                    Dbg("扣 " .. amount .. " (" .. tostring(school or "物理")
                        .. ", " .. tostring(src) .. ")")
                    Deduct(amount, school)
                end
            elseif src then
                F.flagged = true
            end
        end
    end)

    -- ═══ 轮询 ═══
    -- UNIT_AURA 在 1.12 有丢事件的情况, 而且超时/刷新检测本来就得靠读剩余时间。
    -- 几何跟随 lerp 由 bar:Update() 负责, 这里只管数值, 很轻。
    poller = CreateFrame("Frame")
    poller:Hide()
    poller:SetScript("OnUpdate", function()
        acc = acc + (arg1 or 0)         -- 1.12: OnUpdate 的 elapsed 在全局 arg1
        if acc < INTERVAL then return end
        acc = 0
        NewFrame()
        Rescan()
        if table.getn(Q.list) == 0 then
            if Q.uncertain then
                Q.uncertain = false
                RefreshText()
            end
            DFUI.activeScripts["ShieldPoller"] = false
            poller:Hide()
        end
    end)
    DFUI.activeScripts["ShieldPoller"] = false

    -- ═══ 配置回调 ═══
    local callbacks = {}
    callbacks.shieldShowBar = function(value)
        S.showBar = value
        if UI.bar then
            if value then
                if not UI.bar.absorb then UI.bar:EnableAbsorb() end
                ApplyStyle()
            end
            Recalc()
        end
    end
    callbacks.shieldOverlay      = function() ApplyStyle() end
    callbacks.shieldGlow         = function() ApplyStyle() end
    callbacks.shieldGlowWidth    = function() ApplyStyle() end
    callbacks.shieldGlowOffset   = function() ApplyStyle() end
    callbacks.shieldAlpha        = function() ApplyStyle() end
    callbacks.shieldTint         = function() ApplyStyle() end
    callbacks.shieldShowText     = function(v) S.showText = v; RefreshText() end
    callbacks.shieldTextFormat   = function(v) S.textFormat = v; RefreshText() end
    callbacks.shieldTextColor    = function(v) S.textColor = v; RefreshText() end
    callbacks.shieldTextShort    = function(v) S.textShort = v; RefreshText() end
    callbacks.shieldUncertainMark = function(v) S.uncertain = v; RefreshText() end
    callbacks.shieldSuppressCutout = function(v) S.suppressCut = v end
    callbacks.shieldDebug        = function(v) S.debug = v end
    callbacks.shieldTalentFix    = function(v) S.talentFix = v; Wipe(); Rescan() end
    callbacks.shieldTrackWards   = function(v) S.trackWards = v; Wipe(); Rescan() end
    callbacks.shieldAutoCalibrate = function(v)
        S.calibrate = v
        if not v then lib:ForgetAll() end
    end
    DFUI:NewCallbacks("Shield", callbacks)

    -- ═══ 诊断 ═══
    -- 模块跑在 setfenv 环境里, 新建全局必须走 _G, 否则只写进 DFUI.env
    _G.SLASH_DFUISHIELD1 = "/dfshield"
    _G.SlashCmdList["DFUISHIELD"] = function(msg)
        local out = DEFAULT_CHAT_FRAME
        local _, _, cmd, rest = string.find(msg or "", "^(%S*)%s*(.*)$")
        cmd = string.lower(cmd or "")

        if cmd == "gs" then
            local sp, fa, tr = lib:GetPatterns()
            out:AddMessage("|cff00ff00[护盾] 吸收模式|r")
            out:AddMessage("  吸收尾巴: " .. tostring(tr))
            out:AddMessage("  目标=我 的基础串: " .. table.getn(sp) .. " 条")
            for i = 1, table.getn(sp) do
                out:AddMessage("    " .. sp[i].src .. "  |cff888888" .. sp[i].fmt .. "|r")
            end
            out:AddMessage("  完全吸收串: " .. table.getn(fa) .. " 条")
            for i = 1, table.getn(fa) do
                out:AddMessage("    " .. fa[i].src .. "  |cff888888" .. fa[i].fmt .. "|r")
            end
            return
        end

        if cmd == "scan" then
            out:AddMessage("|cff00ff00[护盾] buff 扫描|r")
            for uiIdx = 1, 32 do
                local tex = UnitBuff("player", uiIdx)
                if not tex then break end
                local name, absorb = lib:ScanBuff(uiIdx)
                out:AddMessage(string.format("  %d. %s  吸收=%s", uiIdx,
                    tostring(name), absorb and tostring(absorb) or "|cff888888否|r"))
            end
            return
        end

        if cmd == "ranks" then
            out:AddMessage("|cff00ff00[护盾] 数值表 vs 法术书|r")
            for name, def in pairs(_G.DFUI_ShieldSpells or {}) do
                if def.ranks then
                    local book = lib:ScanSpellbook(name)
                    local rankStr, rankNum = nil, nil
                    if DFUI_Libs.libspell then
                        rankStr, rankNum = DFUI_Libs.libspell:GetSpellMaxRank(name)
                    end
                    local tbl = rankNum and def.ranks[rankNum] or nil
                    if book or tbl then
                        local flag = (book and tbl and book ~= tbl) and " |cffff5555不符|r" or ""
                        out:AddMessage(string.format("  %s (%s) 表=%s 法术书=%s%s",
                            name, tostring(rankStr), tostring(tbl), tostring(book), flag))
                    end
                end
            end
            return
        end

        if cmd == "learned" then
            out:AddMessage("|cff00ff00[护盾] 校准学习值|r")
            local n = 0
            for k, v in pairs(lib:DumpLearned()) do
                n = n + 1
                out:AddMessage("  " .. k .. " = " .. tostring(v[1])
                    .. (v[2] and " |cffffff00(已失效, 待重学)|r" or ""))
            end
            if n == 0 then out:AddMessage("  (空)") end
            return
        end

        if cmd == "forget" then
            lib:ForgetAll()
            out:AddMessage("|cff00ff00[护盾]|r 已清空校准学习值")
            return
        end

        if cmd == "test" then
            local v = tonumber(rest) or 1000
            if not UI.bar then Attach() end
            if UI.bar then
                if not UI.bar.absorb then UI.bar:EnableAbsorb(); ApplyStyle() end
                UI.bar:SetAbsorb(v)
                out:AddMessage("|cff00ff00[护盾]|r 注入测试护盾段 " .. v
                    .. " (纯 UI 几何验证, 不进队列; 下次刷新即消)")
            end
            return
        end

        if cmd == "hit" then
            local _, _, n, sc = string.find(rest, "^(%d+)%s*(%S*)$")
            local v = tonumber(n)
            if v then
                Deduct(v, (sc ~= "" and sc) or nil)
                out:AddMessage("|cff00ff00[护盾]|r 注入扣减 " .. v .. " " .. tostring(sc))
            else
                out:AddMessage("用法: /dfshield hit <数值> [学派]")
            end
            return
        end

        if cmd == "help" then
            out:AddMessage("|cff00ff00[护盾] /dfshield|r")
            out:AddMessage("  (无参数)      当前护盾队列")
            out:AddMessage("  gs            吸收日志模式与来源全局串")
            out:AddMessage("  scan          逐个 buff 的吸收值刮取结果")
            out:AddMessage("  ranks         数值表 vs 法术书 tooltip 对照")
            out:AddMessage("  learned       自动校准学到的值")
            out:AddMessage("  forget        清空校准值")
            out:AddMessage("  test <N>      注入假护盾段, 验 UI 几何")
            out:AddMessage("  hit <N> [学派] 注入假扣减")
            return
        end

        -- 默认: 打印队列
        out:AddMessage("|cff00ff00[护盾] 队列|r  总量=" .. Q.total
            .. (Q.uncertain and " |cffffff00~不确定|r" or "")
            .. (Q.spill > 0 and ("  溢出=" .. Q.spill) or ""))
        if table.getn(Q.list) == 0 then
            out:AddMessage("  (无护盾)")
        end
        for i = 1, table.getn(Q.list) do
            local s = Q.list[i]
            local sc = "全部"
            if s.schools then
                sc = ""
                for w in pairs(s.schools) do sc = (sc == "" and w) or (sc .. "/" .. w) end
            end
            out:AddMessage(string.format("  %d. %s [%s] %d/%d  来源=%s  剩余时间=%s",
                i, s.name, sc, s.remaining, s.initial, s.source,
                s.lastTL and string.format("%.0fs", s.lastTL) or "?"))
        end
        if not UI.bar then
            out:AddMessage("  |cffff5555未接入玩家血条|r (玩家框架模块是否已关闭?)")
        end
    end
end)
