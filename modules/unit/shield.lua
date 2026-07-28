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
    -- skipped/nskip: 认得出是护盾、却算不出吸收量而被放弃的 buff(诊断用, 见 Rescan)
    -- cast:  SuperWoW 捕获到的【他人】对我施放的护盾 → { [法术名] = {t=} }
    -- slots: 贴图 → GetPlayerBuff 槽位, 每轮 Rescan 重建一次(见 BuildSlots)
    local Q = {list = {}, total = 0, uncertain = false, spill = 0,
               skipped = {}, nskip = 0, skipLog = {}, cast = {}, slots = {}}
    local UI = {}           -- 控件引用
    local F = {t = -1, seen = {}, flagged = false, gotNum = false}   -- 帧批次
    local poller            -- 前置声明: Recalc 要唤醒它, 它在下面才建

    local INTERVAL = 0.1
    local acc = 0
    local REFRESH_TOL = 0.5      -- 剩余时间"变大"多少才算刷新
    local TIMEOUT_EDGE = 1.5     -- 消失前剩余时间小于此值 → 判超时, 不校准
    local CALIBRATE_WINDOW = 1.0 -- 最后一次扣减距消失多久内才认"是被打破的"
    local CALIBRATE_MAX_RATIO = 1.5  -- 校准值相对当前估算的涨幅上限, 超出即判脏账
    local CAST_WINDOW = 3.0      -- 施法事件与 UNIT_AURA 之间允许的最大间隔

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
            -- ⚠ 必须在挂钩当下就把 base 播种进去(且只在真正挂钩这一次做,
            --   重复播种会把上一次的后缀吃成 base, 变成 "+942 +942")。
            --   player.lua 的生命值文字只在 UNIT_HEALTH/UNIT_MANA 等
            --   `arg1 == "player"` 的事件里刷(player.lua:959-963), 【没有 UNIT_AURA】。
            --   不播种的话 _dfAbsorbBase 一直是 nil, RefreshText 整个空转 ——
            --   满血站桩被套盾时血量/资源都不变, 数字就永远出不来。
            hv._dfAbsorbBase = hv:GetText() or ""
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
            and s.key and s.lastHit and (GetTime() - s.lastHit) <= CALIBRATE_WINDOW then
            -- 估低时超出的量记在 overflow 里(见 Deduct), 真值要把它加回来
            local trueValue = s.deducted + (s.overflow or 0)
            local drift = math.abs(trueValue - s.initial) / s.initial
            if drift > 0.05 then
                -- ⚠ 涨幅护栏。overflow 是无上限累加的: 只要记账与服务端脱节
                --   (没追踪到的吸收源、日志漏投、盾早破了队列还没清), 它就能把
                --   "真值"撑到离谱 —— 曾把 234 的 Rank 4 盾学成 900 并写进
                --   SavedVariable 跨会话生效。
                --   而校准本来只为补 tooltip 缺失的法术强度: PW:S 系数只有 0.1,
                --   满级堆满法强也就 +5% 上下。涨到 1.5 倍必然是脏账, 宁可不学。
                -- ⚠ 锚点必须是 est(不含校准的纯估算), 不能是 initial ——
                --   cal 命中时 initial 就是上次学到的值, 拿它当基准会逐轮爬升。
                if trueValue > (s.est or s.initial) * CALIBRATE_MAX_RATIO then
                    Dbg("弃用校准 " .. s.name .. " " .. s.initial .. " -> "
                        .. trueValue .. " (涨幅超上限, 记账已脱节)")
                else
                    lib:Learn(s.key, trueValue)
                    Dbg("校准 " .. s.name .. " " .. s.initial .. " -> " .. trueValue)
                end
            end
        end
        Dbg("移除 " .. s.name .. " (" .. reason .. ")")
    end

    -- 认得出是护盾(在富化表里)、却一个数都算不出来 → 记一笔给 /dfshield 看。
    -- 不记未知法术: 身上绝大多数 buff 本来就不是护盾, 全记等于刷屏。
    -- 条目对象复用, 不每轮重新分配(Rescan 在轮询里 0.1s 跑一次)。
    local function NoteSkip(name, why)
        Q.nskip = Q.nskip + 1
        local e = Q.skipped[Q.nskip]
        if not e then
            e = {}
            Q.skipped[Q.nskip] = e
        end
        e.name, e.why = name, why
        -- Rescan 在轮询期是 10Hz, 同一条原因不许重复刷屏。
        -- 整表在"这一轮一个都没跳过"时清掉(见 Rescan 收尾), 所以盾再出现还会记一次。
        if Q.skipLog[name] ~= why then
            Q.skipLog[name] = why
            Dbg("跳过 " .. name .. " (" .. why .. ")")
        end
    end

    -- "确证是别人放的吗" —— 只在捕获到对方施法事件时为真, 取走即消费。
    -- 它不参与取值(取值走法术 ID), 只影响两件事: 不套自己的天赋、不进校准库。
    local function TakeForeign(name)
        local c = Q.cast[name]
        if not c then return nil end
        Q.cast[name] = nil
        if (GetTime() - c.t) > CAST_WINDOW then return nil end
        return true
    end

    -- 贴图 → GetPlayerBuff 槽位。UnitBuff 与 GetPlayerBuff 在 Turtle 上枚举顺序
    -- 可能不一致, 只能按贴图换算(与 auras.lua:479 FindPlayerBuffIndex 同款问题)。
    -- 每轮建一次表: 原来是每个 buff 各自扫一遍 GetPlayerBuff(0..31), 轮询 10Hz 下
    -- 是 O(32×32); 建表后整轮只扫一次, 而且新护盾候选也能免费拿到槽位去查法术 ID。
    local function BuildSlots()
        local map = Q.slots
        for k in pairs(map) do map[k] = nil end
        if not GetPlayerBuff or not GetPlayerBuffTexture then return end
        for idx = 0, 31 do
            local bIdx = GetPlayerBuff(idx, "HELPFUL")
            if not bIdx or bIdx < 0 then break end
            local t = GetPlayerBuffTexture(bIdx)
            -- 同贴图取首个(两个法术共用图标时的既有行为, 不改)
            if t and not map[t] then map[t] = bIdx end
        end
    end

    -- 全量重扫玩家 buff, 与队列对账
    local function Rescan()
        local seen = {}
        local order = {}
        Q.nskip = 0
        BuildSlots()

        for uiIdx = 1, 32 do
            local tex = UnitBuff("player", uiIdx)
            if not tex then break end
            local bIdx = Q.slots[tex]

            local existing = nil
            for i = 1, table.getn(Q.list) do
                if Q.list[i].uiIdx == uiIdx and Q.list[i].tex == tex then
                    existing = Q.list[i]
                    break
                end
            end

            local name, tipAbsorb, sawKw
            if existing then
                name = existing.name
            else
                name, tipAbsorb, sawKw = lib:ScanBuff(uiIdx)
            end

            if name then
                local s = existing or FindByTex(tex, name)
                if not s then
                    -- 新护盾: 只有能拿到可信初始值才进队列。
                    -- 认不出就【不追踪】, 绝不编一个数糊弄。
                    --
                    -- 法术 ID 路径要开一次 tooltip, 而这段代码对【每个未追踪的 buff】
                    -- 都会跑(轮询期 10Hz), 所以先用"看起来像不像盾"把关:
                    -- tooltip 说了"吸收" 或 在富化表里 —— 两条都不靠猜。
                    local shieldish = tipAbsorb or sawKw
                        or (_G.DFUI_ShieldSpells and _G.DFUI_ShieldSpells[name])
                    local foreign = TakeForeign(name)
                    local spellId = shieldish and lib:AuraSpellID(bIdx) or nil
                    local amount, source, key, est =
                        lib:GetInitial(name, uiIdx, tipAbsorb, spellId, foreign)
                    if not amount and shieldish then
                        NoteSkip(name, "拿不到吸收值")
                    end
                    if amount and amount > 0 then
                        local schools = lib:SchoolsOf(name)
                        if schools and not S.trackWards then
                            amount = nil            -- 用户选择不追单属性结界
                            NoteSkip(name, "已关闭单属性结界追踪")
                        end
                        if amount then
                            -- key 由 libabsorb 按【这个盾的基准吸收值】生成, 原样带在
                            -- 护盾对象上, 破盾校准时回传 —— 存取必定是同一条目,
                            -- 别人的高等级盾再也污染不到自己的低等级盾
                            s = {
                                name = name, tex = tex, uiIdx = uiIdx,
                                key = key, est = est, schools = schools,
                                initial = amount, remaining = amount, deducted = 0,
                                source = source, manaPerPoint = lib:ManaPerPoint(name),
                                foreign = foreign,
                                -- 打脏 = 不许进校准学习库。两种情况:
                                --  1) 天赋修正被用户关掉 → 校准值会偏离"含天赋的真值"
                                --  2) 【确证他人施放】→ 学到的是对方的法强/天赋/套装, 而 key
                                --     只按基准值(等级)生成, 你自己放同一等级的盾会读到
                                --     对方的高值。别人的盾破得再多也不该记进你的账本。
                                tainted = ((foreign or not S.talentFix) and true) or nil,
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
                    local tl = bIdx and GetPlayerBuffTimeLeft and GetPlayerBuffTimeLeft(bIdx) or nil
                    if tl then
                        if s.lastTL and tl > s.lastTL + REFRESH_TOL then
                            -- 重新刮一次 buff tooltip: 重施时装备/天赋可能已经变了
                            local _, tip = lib:ScanBuff(uiIdx)
                            -- 重施也可能换人施放(自己放的盾被牧师覆盖, 反之亦然),
                            -- 所以等级与施法者归属都要跟着这一轮重判, 不能沿用旧的
                            local foreign = TakeForeign(s.name)
                            local amount, source, key, est = lib:GetInitial(
                                s.name, uiIdx, tip, lib:AuraSpellID(bIdx), foreign)
                            s.initial = amount or s.initial
                            s.remaining = s.initial
                            s.deducted = 0
                            s.overflow = nil
                            s.key = key or s.key
                            s.est = est or s.est
                            s.source = source or s.source
                            s.foreign = foreign
                            -- 重施 = 全新一轮记账, 上一轮因归因失败打的脏标记不该顺延
                            s.tainted = ((foreign or not S.talentFix) and true) or nil
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

        -- 这一轮一个都没跳过 → 清掉去重记忆, 让同一个盾下次出现时还能记一次
        if Q.nskip == 0 then
            for k in pairs(Q.skipLog) do Q.skipLog[k] = nil end
        end

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
        -- 真实的盾还在扛。把超出的量记到那个盾头上:
        --   真实初始值 = deducted + overflow
        -- 少了这一步, 估低的情况下 deducted 永远被钳在 initial, drift 恒为 0,
        -- 校准就永远学不到东西 —— 而估低恰恰是常态(1.12 读不到法术强度)。
        --
        -- ⚠ 但归因必须成立才敢记。原来是"给第一个吃这个学派的盾", 那是错的:
        --   多盾并存时服务端按槽位吃, 我们这边已经全部记成 0, 归给谁纯属猜测,
        --   排在前面的盾会替别人背下全部虚账 —— 那正是 234 被学成 900 的来路。
        -- 只有【队列里就一个盾, 且学派对得上】时, "还在吸收"才唯一地指向
        -- "我们低估了它"。其余情况一律打脏, 本轮不参与校准。
        if amount > 0 then
            Q.spill = Q.spill + amount
            local n = table.getn(Q.list)
            local owner = nil
            if n == 1 and SchoolMatches(Q.list[1], school) then owner = Q.list[1] end
            if owner then
                owner.overflow = (owner.overflow or 0) + amount
                owner.lastHit = GetTime()
            else
                -- 多盾并存(归因不了) 或 学派对不上(存在没追踪到的吸收源)
                for i = 1, n do Q.list[i].tainted = true end
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
        Q.nskip = 0
        for k in pairs(Q.cast) do Q.cast[k] = nil end
        for k in pairs(Q.skipLog) do Q.skipLog[k] = nil end
        Recalc()
    end

    -- ═══════════════════════════════════════════════════════
    -- 接线
    -- ═══════════════════════════════════════════════════════

    -- (贴图 → GetPlayerBuff 槽位的换算已收进 Rescan 的 BuildSlots: 整轮建一次表,
    --  取代原来每个 buff 各扫一遍 GetPlayerBuff 的 O(32×32) 写法)

    -- 血条与文字两个接入点【分别】判定, 各自惰性重试。
    -- 原来是一进来就 `if UI.bar then return true end`, HookText 只有唯一一次机会:
    -- 玩家框的 texts 若比血条晚就绪(DFUI.unitTexts.player 在 player.lua:138 才注册),
    -- 盾值数字就永久缺失且不会自愈。
    local function Attach()
        if UI.bar and UI.healthValue then return true end
        if not UI.bar then
            local bar = DFUI.predictBars and DFUI.predictBars.player
            if bar then
                UI.bar = bar
                if S.showBar then
                    bar:EnableAbsorb()
                    ApplyStyle()
                end
            end
        end
        if not UI.healthValue then HookText() end
        return UI.bar and true or false
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

        -- Attach 现在负责血条与文字两处的惰性补挂, 所以每次都要走一遍;
        -- 两处都就绪后它首行即返回, 开销可忽略
        if not Attach() then return end

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

    -- ═══════════════════════════════════════════════════════
    -- SuperWoW: 判定护盾是不是【别人】给我上的
    -- ═══════════════════════════════════════════════════════
    --
    -- ⚠ 这条路径【不负责取值】。取值走 Rescan 里的法术 ID(GetPlayerBuffID),
    --   那个更可靠: 光环自带 ID, 不怕漏事件、不怕 /reload、不怕上盾时你不在场。
    --   这里只回答一个问题: 这盾是不是别人放的? 它只影响两件事 ——
    --     1) 不套自己的天赋(自己也会同一法术时, IsLikelySelfCast 会误判成自施)
    --     2) 不许进校准学习库(学到的是对方的法强/套装, 会污染你自己的值)
    --   捕获不到时两条都退回原有的启发式, 属于良性降级。
    --
    --   arg1=施法者GUID  arg2=目标GUID  arg3=事件  arg4=spellID  arg5=计时
    --   (语义见 ShaguPlates/modules/superwow.lua:230-249、ShaguTweaks/mods/superwow.lua:25)
    --   玩家自身 GUID: UnitExists("player") 的第二个返回值。
    --
    -- ⚠ 探测必须实时读 _G.SUPERWOW_VERSION(不缓存), 且 RegisterEvent 要在探测
    --   通过之后才做 —— 没有 SuperWoW 时 UNIT_CASTEVENT 是个不存在的事件。
    -- 这个要缓存: 它记录的是"事件到底注册了没有", 而注册只发生一次。
    -- (取值路径的能力判定不缓存, 由 libabsorb:AuraSpellID 每次调用现场判, 诊断
    --  那边也现场判 —— 缓存一个与实际调用路径不同步的值只会让诊断说谎。)
    UI.castOK = (SUPERWOW_VERSION and type(SpellInfo) == "function") and true or false
    if UI.castOK then
        local castTracker = CreateFrame("Frame")
        castTracker:RegisterEvent("UNIT_CASTEVENT")
        castTracker:SetScript("OnEvent", function()
            if arg3 ~= "CAST" or not arg4 then return end
            local _, pg = UnitExists("player")
            if not pg or arg2 ~= pg then return end   -- 目标不是我
            if arg1 == pg then return end             -- 自施, 无需标记
            -- 自己的宠物不算"外人": 术士的"牺牲"由虚空行者施放, 但数值随主人的属性走,
            -- 跨会话稳定 —— 按外人处理会白白关掉它的校准, 反而更不准。
            local _, petg = UnitExists("pet")
            if petg and arg1 == petg then return end
            local name = SpellInfo(arg4)
            if not name then return end
            if not (_G.DFUI_ShieldSpells and _G.DFUI_ShieldSpells[name]) then return end
            local c = Q.cast[name]
            if not c then
                c = {}
                Q.cast[name] = c
            end
            c.t = GetTime()
            Dbg("他人施放 " .. name)
            -- UNIT_CASTEVENT 与 UNIT_AURA 谁先到没有保证。补扫一次, 让 foreign
            -- 标记能落到刚上身的那个盾上(队列为空时轮询器是睡着的, 等不到下一轮)。
            Rescan()
        end)
    end

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
            -- full: 连 tooltip 原文一起打。刮取失败时这是唯一能看清"客户端到底
            -- 给了什么"的手段 —— 别人给你上的盾全靠 tooltip, 必须能验它。
            local full = (string.lower(rest or "") == "full")
            out:AddMessage("|cff00ff00[护盾] buff 扫描|r" ..
                (full and "" or "  |cff888888(加 full 参数可打印 tooltip 原文)|r"))
            BuildSlots()
            for uiIdx = 1, 32 do
                local tex = UnitBuff("player", uiIdx)
                if not tex then break end
                local name, absorb, kw = lib:ScanBuff(uiIdx)
                out:AddMessage(string.format("  %d. %s  buff吸收=%s%s", uiIdx,
                    tostring(name), absorb and tostring(absorb) or "|cff888888否|r",
                    (kw and not absorb) and " |cffffff00(说了吸收但没数字)|r" or ""))
                -- 逐层展开取值级联, 一眼看出断在哪一环。
                -- 只对"看起来像盾"的 buff 打, 否则一屏都是无关法术。
                local known = _G.DFUI_ShieldSpells and _G.DFUI_ShieldSpells[name]
                if full or absorb or kw or known then
                    -- ID 反查出来的法术名一并打出来供人眼核对, 但【不据此拦截取值】
                    -- (拦过一次, 把整条路掐死了, 见 libabsorb:AuraSpellID 的注释)
                    local sid = lib:AuraSpellID(Q.slots[tex])
                    local sidName = sid and SpellInfo and SpellInfo(sid) or nil
                    local amount, source = lib:GetInitial(name, uiIdx, absorb, sid)
                    out:AddMessage(string.format(
                        "       法术ID=%s(%s)%s 等级=%s  ID取值=%s  →|cff00ff00 采用 %s|r (来源 %s)",
                        tostring(sid), tostring(sidName),
                        (sidName and sidName ~= name) and " |cffffff00名字与buff不同|r" or "",
                        tostring(sid and lib:SpellRankNum(sid)),
                        tostring(sid and lib:ScanSpellID(sid)),
                        amount and tostring(amount) or "|cffff5555无|r",
                        tostring(source)))
                end
                if full then
                    local lines, n = lib:DumpBuff(uiIdx)
                    for i = 1, n do
                        out:AddMessage("       |cff888888" .. i .. "|r " .. lines[i])
                    end
                end
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
            out:AddMessage("  (无参数)      当前护盾队列 + 已跳过 + 环境自检")
            out:AddMessage("  gs            吸收日志模式与来源全局串")
            out:AddMessage("  scan [full]   逐个 buff 的吸收值刮取结果; full 附 tooltip 原文")
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
            -- 显示值与纯估算值不一致时把估算一并打出来: "900/900(估算234)" 一眼
            -- 就能看出是校准层给的高值, 不用再逐层猜是 tip/book/tbl 哪一环出的数
            local est = ""
            if s.est and s.est ~= s.initial then est = "(估算" .. s.est .. ")" end
            out:AddMessage(string.format("  %d. %s [%s] %d/%d%s  来源=%s%s  剩余时间=%s",
                i, s.name, sc, s.remaining, s.initial, est, s.source,
                s.foreign and " |cff88ccff(他人施放)|r" or "",
                s.lastTL and string.format("%.0fs", s.lastTL) or "?"))
        end

        -- 认得出是护盾却算不出数值的, 在这里现形。
        -- 少了这一节, Rescan 是静默丢弃的, 用户侧只能看到"什么都没有"。
        if Q.nskip > 0 then
            out:AddMessage("|cffffff00[护盾] 已跳过|r (认得出是护盾, 但算不出吸收量)")
            for i = 1, Q.nskip do
                out:AddMessage("  " .. Q.skipped[i].name .. "  |cff888888"
                    .. Q.skipped[i].why .. "|r")
            end
        end

        -- 环境自检: "什么都看不到"最常见的几个非 bug 原因, 一次性摆出来
        local hp, hpmax = UnitHealth("player"), UnitHealthMax("player")
        out:AddMessage("|cff00ff00[护盾] 环境|r  护盾段="
            .. (S.showBar and "开" or "|cffff5555关|r")
            .. "  盾值文字=" .. (S.showText and "开" or "|cffff5555关|r")
            .. "  玩家框文字=" .. (DFUI:GetTempDB("Player", "textShow")
                and "开" or "|cffff5555关(盾值数字会一并隐藏)|r")
            .. "  文字挂钩=" .. (UI.healthValue and "已挂" or "|cffff5555未挂|r"))
        out:AddMessage("  法术ID取值(GetPlayerBuffID)="
            .. ((type(GetPlayerBuffID) == "function") and "|cff00ff00可用|r"
                or "|cffffff00不可用 —— 别人给你上的盾只能靠 buff tooltip 取值|r")
            .. "   施法者归属(UNIT_CASTEVENT)=" .. (UI.castOK and "可用" or "不可用"))
        -- 玩家框架「满血且非战斗时隐藏框架」开着时, 恰好在"开怪前套盾"这个场景下
        -- 把整个框架连同护盾一起藏起来 —— 表现与"护盾没生效"完全一样, 必须点名
        if DFUI:GetTempDB("Player", "frameHide") then
            out:AddMessage("  |cffffff00玩家框架「满血且非战斗时隐藏框架」已开启|r —— "
                .. "当前框架" .. (PlayerFrame and PlayerFrame:IsShown() and "显示中"
                    or "|cffff5555已隐藏, 护盾也跟着看不见|r"))
        end
        if hpmax > 0 and hp >= hpmax then
            out:AddMessage("  |cffffff00当前满血: 护盾段宽度按原版规则恒为 0, "
                .. "只有血条右端一根光柱, 属正常|r")
        end
        if not UI.bar then
            out:AddMessage("  |cffff5555未接入玩家血条|r (玩家框架模块是否已关闭?)")
        end
    end
end)
