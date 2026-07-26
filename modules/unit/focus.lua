-- ═══════════════════════════════════════════════════════════════
-- Focus 焦点框体模块（1.12 无原生 focus API，全模拟）
-- 入口：小队/团队成员右键菜单"设置焦点"（UnitPopupMenus 注入）
-- 身份：SuperWoW GUID 优先（GUID 即合法 unit token，零扫描）；
--       无 SuperWoW 按名字扫 player/party/raid/target/mouseover
-- 刷新：0.2s 热档（血/蓝/debuff）+ ~3s 冷档（名字/等级/头像），
--       焦点框无事件可听（自建 frame），纯 OnUpdate 轮询
-- debuff 计时：tooltip 刮名 → zhCN 时长表（提取自 FocusFrame/
--       SpellGlobals）→ 首次观测记时倒数；表 miss 只显示图标层数
-- ═══════════════════════════════════════════════════════════════

DFUI:NewDefaults("Focus", {
    enabled = {true},
    focusFrameScale  = {1, "slider", {0.7, 1.5, 0.1}, nil, "外观", 1, "调整焦点框架大小", nil, nil},
    focusShowDebuffs = {true, "checkbox", nil, nil, "外观", 2, "在焦点框架下方显示负面效果图标", nil, nil},
    focusDebuffSize  = {16, "slider", {12, 24, 1}, "focusShowDebuffs", "外观", 3, "负面效果图标大小", nil, nil},
})

DFUI:NewMod("Focus", 1, function()
    local path = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\unitframes\\"

    -- ═══ A. debuff 类型边框色（同 auras.lua）+ zhCN 时长表 ═══
    local DEBUFF_COLORS = {
        none    = {0.8, 0.0, 0.0},
        Magic   = {0.2, 0.6, 1.0},
        Disease = {0.6, 0.4, 0.0},
        Poison  = {0.0, 0.6, 0.0},
        Curse   = {0.6, 0.0, 1.0},
    }

    -- 中文键名 debuff 时长表（秒），提取自 FocusFrame SpellGlobals.lua
    -- 只收"会出现在友方玩家身上"的减益/控制；连击点技能取最大值
    local ZH_DEBUFF_DURATIONS = {
        -- 通用/工程/杂项
        ["逃跑"] = 10, ["撒网器"] = 10, ["新近包扎"] = 60,
        ["闪光雷"] = 10, ["瑟银手榴弹"] = 3, ["铁皮手雷"] = 3,
        ["催眠术"] = 12, ["无畏冲锋"] = 12,
        -- 德鲁伊
        ["纠缠根须"] = 12, ["休眠"] = 20, ["月火术"] = 12, ["虫群"] = 12,
        ["挫志咆哮"] = 30, ["野性冲锋效果"] = 4, ["低吼"] = 3,
        ["血袭"] = 2, ["扫击"] = 9, ["撕扯"] = 12,
        -- 猎人
        ["震荡射击"] = 4, ["强化震荡射击"] = 3, ["反击"] = 5, ["胁迫"] = 3,
        ["献祭陷阱效果"] = 15, ["冰冻陷阱效果"] = 20, ["驱散射击"] = 4,
        ["恐吓野兽"] = 10, ["毒蝎钉刺"] = 20, ["毒蛇钉刺"] = 15,
        ["蝰蛇钉刺"] = 8, ["翼龙钉刺"] = 12, ["摔绊"] = 10, ["强化摔绊"] = 5,
        -- 法师
        ["冲击波"] = 6, ["冲击"] = 2, ["法术反制 - 沉默"] = 4,
        ["冰锥术"] = 10, ["冰冻"] = 7, ["霜寒刺骨"] = 5, ["冰霜新星"] = 8,
        ["寒冰箭"] = 10, ["火球术"] = 8, ["炎爆术"] = 12, ["深冬之寒"] = 15,
        ["变形术"] = 12, ["变形术：猪"] = 12, ["变形术：龟"] = 12,
        -- 圣骑士
        ["制裁之锤"] = 5, ["忏悔"] = 6, ["昏迷"] = 2, ["辩护"] = 10,
        ["十字军审判"] = 10, ["公正审判"] = 10, ["圣光审判"] = 10, ["智慧审判"] = 10,
        -- 牧师
        ["昏厥"] = 3, ["噬灵瘟疫"] = 24, ["精神鞭笞"] = 3, ["心灵尖啸"] = 8,
        ["暗影易伤"] = 15, ["暗言术：痛"] = 24, ["沉默"] = 5, ["虚弱灵魂"] = 15,
        -- 盗贼
        ["致盲"] = 10, ["偷袭"] = 4, ["致残毒药"] = 12, ["致命毒药 V"] = 12,
        ["破甲"] = 30, ["绞喉"] = 18, ["鬼魅攻击"] = 7, ["凿击"] = 5,
        ["出血"] = 15, ["脚踢 - 沉默"] = 2, ["麻痹毒药 III"] = 14,
        ["还击"] = 6, ["闷棍"] = 11, ["肾击"] = 6, ["致伤毒药 IV"] = 15,
        ["割裂"] = 16,
        -- 萨满
        ["地缚术"] = 5, ["烈焰震击"] = 12, ["冰霜震击"] = 8,
        -- 术士
        ["腐蚀术"] = 18, ["痛苦诅咒"] = 24, ["疲劳诅咒"] = 30, ["语言诅咒"] = 30,
        ["死亡缠绕"] = 3, ["吸取生命"] = 5, ["吸取法力"] = 5, ["吸取灵魂"] = 15,
        ["恐惧术"] = 15, ["献祭"] = 15, ["诱惑"] = 10, ["暗影灼烧"] = 5,
        -- 战士
        ["挑战怒吼"] = 6, ["冲锋"] = 1, ["震荡猛击"] = 5, ["重伤"] = 12,
        ["挫志怒吼"] = 30, ["缴械"] = 8, ["断筋"] = 15, ["强化断筋"] = 5,
        ["拦截昏迷"] = 3, ["破胆怒吼"] = 8, ["锤击昏迷效果"] = 3,
        ["致死打击"] = 10, ["撕裂"] = 21, ["反击风暴"] = 15,
        ["盾击 - 沉默"] = 3, ["雷霆一击"] = 30,
    }

    -- ═══ B. 状态 ═══
    -- guid：SuperWoW 身份主键（团队序号平移/同名免疫）；name：显示 + 降级匹配；
    -- token：最近解析出的真实 unit token（头像/tooltip 优先用它）
    local state = { guid = nil, name = nil, token = nil }
    local ui = {}               -- 所有子件引用收进单表（控 upvalue 数量）
    local debuffTimers = {}     -- [debuff名] = {start, duration}
    local slotCache = {}        -- [槽位i] = {tex, stacks, name}：贴图/层数没变不重刮名
    local curUnit = nil         -- 本 tick 解析出的查询 unit（token 或 GUID）
    local scanner = DFUI_Libs and DFUI_Libs.libtipscan and DFUI_Libs.libtipscan:GetScanner("dfui_focus")

    local function IsGuidStr(u)
        return u and string.find(u, "^0x")
    end

    local function SameIdentity(t)
        if state.guid then
            local _, g = UnitExists(t)
            return g == state.guid
        end
        return UnitName(t) == state.name
    end

    -- 便宜路径优先：缓存 token → GUID 直用 → 全池重扫（一次 tick 扫完）
    local function ResolveUnit()
        local t = state.token
        if t and UnitExists(t) and SameIdentity(t) then return t end
        for i = 1, 4 do
            t = "party" .. i
            if UnitExists(t) and SameIdentity(t) then state.token = t; return t end
        end
        local n = GetNumRaidMembers()
        for i = 1, n do
            t = "raid" .. i
            if UnitExists(t) and SameIdentity(t) then state.token = t; return t end
        end
        for _, extra in ipairs({"player", "target", "mouseover"}) do
            if UnitExists(extra) and SameIdentity(extra) then state.token = extra; return extra end
        end
        state.token = nil
        if state.guid and UnitExists(state.guid) then return state.guid end
        return nil
    end

    -- ═══ C. 框体构建（幂等，模块体=ADDON_LOADED 时建，绝不进 PEW） ═══
    local focusFrame = _G["DFUIFocusFrame"] or CreateFrame("Button", "DFUIFocusFrame", UIParent)

    if not focusFrame._dfFocusInit then
        focusFrame._dfFocusInit = true
        focusFrame:SetWidth(128)
        focusFrame:SetHeight(82)

        -- 边框/头像/文字载体，抬 2 级让金属边压住血蓝条两端（仿 mini 队友框层序）
        local art = CreateFrame("Frame", nil, focusFrame)
        art:SetWidth(128)
        art:SetHeight(64)
        art:SetPoint("TOP", focusFrame, "TOP", 0, 0)
        art:SetFrameLevel(focusFrame:GetFrameLevel() + 2)
        focusFrame._dfArt = art

        local border = art:CreateTexture(nil, "OVERLAY")
        border:SetTexture(path .. "pet")
        border:SetDrawLayer("BORDER", 1)
        border:SetPoint("CENTER", art, 0, 0)
        border:SetWidth(128)
        border:SetHeight(64)
        focusFrame._dfBorder = border

        local portrait = art:CreateTexture(nil, "BACKGROUND")
        portrait:SetWidth(35)
        portrait:SetHeight(35)
        portrait:SetDrawLayer("BACKGROUND", 1)
        portrait:SetPoint("CENTER", art, -40, 8.25)
        focusFrame._dfPortrait = portrait

        local nameText = art:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        nameText:SetPoint("CENTER", art, "CENTER", 6, 23)
        nameText:SetTextColor(1, 0.82, 0)
        focusFrame._dfName = nameText

        local levelText = art:CreateFontString(nil, "OVERLAY")
        levelText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        levelText:SetPoint("LEFT", nameText, "RIGHT", 3, 0)
        levelText:SetTextColor(1, 0.82, 0)
        focusFrame._dfLevel = levelText

        local hpBar = CreateStatusBar(focusFrame, 69, 18)
        hpBar:SetPoint("CENTER", art, "CENTER", 15, 10)
        hpBar:SetFrameLevel(focusFrame:GetFrameLevel() + 1)
        hpBar:SetTextures(path .. "healthDF2.tga")
        hpBar:SetFillColor(0, 1, 0)
        hpBar.max = 100
        focusFrame._dfHpBar = hpBar
        DFUI.predictBars.focus = hpBar

        local hpBg = hpBar:CreateTexture(nil, "BACKGROUND")
        hpBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        hpBg:SetVertexColor(0, 0, 0, 0.3)
        hpBg:SetAllPoints()

        local mpBar = CreateStatusBar(focusFrame, 69, 7)
        mpBar:SetPoint("CENTER", art, "CENTER", 15, 0.5)
        mpBar:SetFrameLevel(focusFrame:GetFrameLevel() + 1)
        mpBar:SetTextures(path .. "UI-HUD-UnitFrame-Target-PortraitOn-Bar-Mana-Status.blp")
        mpBar:SetFillColor(0, 0, 1)
        mpBar.max = 100
        focusFrame._dfMpBar = mpBar

        local mpBg = mpBar:CreateTexture(nil, "BACKGROUND")
        mpBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        mpBg:SetVertexColor(0, 0, 0, 0.3)
        mpBg:SetAllPoints()

        local hpText = hpBar:CreateFontString(nil, "OVERLAY")
        hpText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        hpText:SetPoint("CENTER", 0, 0)
        hpText:SetTextColor(1, 1, 1)
        focusFrame._dfHpText = hpText

        local offlineBg = focusFrame:CreateTexture(nil, "BACKGROUND")
        offlineBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        offlineBg:SetVertexColor(0, 0, 0, 0.5)
        offlineBg:SetPoint("CENTER", art, "CENTER", 15, 5.25)
        offlineBg:SetWidth(69)
        offlineBg:SetHeight(25)
        offlineBg:Hide()
        focusFrame._dfOfflineBg = offlineBg

        local offlineText = focusFrame:CreateFontString(nil, "OVERLAY")
        offlineText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        offlineText:SetPoint("CENTER", art, "CENTER", 15, 5.25)
        offlineText:SetTextColor(0.7, 0.7, 0.7)
        offlineText:SetText("OFFLINE")
        offlineText:Hide()
        focusFrame._dfOfflineText = offlineText

        -- 取消焦点：系统模板红圆 X，抬高 level 防被 art 盖住
        local closeBtn = CreateFrame("Button", nil, focusFrame, "UIPanelCloseButton")
        closeBtn:SetWidth(20)
        closeBtn:SetHeight(20)
        closeBtn:SetPoint("TOPRIGHT", art, "TOPRIGHT", -10, -1)
        closeBtn:SetFrameLevel(focusFrame:GetFrameLevel() + 5)
        focusFrame._dfCloseBtn = closeBtn

        -- debuff 行：8 个图标，结构同 auras.lua CreateAuraButton 精简版
        focusFrame._dfDebuffs = {}
        for i = 1, 8 do
            local btn = CreateFrame("Button", nil, focusFrame)
            btn:SetWidth(16)
            btn:SetHeight(16)
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetAllPoints(btn)
            btn.border = btn:CreateTexture(nil, "OVERLAY")
            btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
            btn.border:SetAllPoints(btn)
            btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
            btn.timer = btn:CreateFontString(nil, "OVERLAY")
            btn.timer:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
            btn.timer:SetTextColor(1, 1, 1)
            btn.timer:SetPoint("BOTTOM", btn, "BOTTOM", 0, -2)
            btn.timer:Hide()
            -- 层数抬独立子帧：1.12 同帧同层 FontString 绘制顺序无保证
            local countFrame = CreateFrame("Frame", nil, btn)
            countFrame:SetAllPoints(btn)
            countFrame:SetFrameLevel(btn:GetFrameLevel() + 2)
            btn.count = countFrame:CreateFontString(nil, "OVERLAY")
            btn.count:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
            btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            btn.count:Hide()
            btn.debuffIndex = i
            btn:Hide()
            focusFrame._dfDebuffs[i] = btn
        end
    end

    -- reload 后子件引用从守护字段取回（frame 跨 reload 残留铁律）
    ui.art        = focusFrame._dfArt
    ui.border     = focusFrame._dfBorder
    ui.portrait   = focusFrame._dfPortrait
    ui.name       = focusFrame._dfName
    ui.level      = focusFrame._dfLevel
    ui.hpBar      = focusFrame._dfHpBar
    ui.mpBar      = focusFrame._dfMpBar
    ui.hpText     = focusFrame._dfHpText
    ui.offlineBg  = focusFrame._dfOfflineBg
    ui.offlineTxt = focusFrame._dfOfflineText
    ui.closeBtn   = focusFrame._dfCloseBtn
    ui.debuffs    = focusFrame._dfDebuffs

    local function ApplyDebuffLayout(size)
        size = size or 16
        for i = 1, 8 do
            local btn = ui.debuffs[i]
            btn:SetWidth(size)
            btn:SetHeight(size)
            btn:ClearAllPoints()
            if i == 1 then
                btn:SetPoint("TOPLEFT", ui.art, "BOTTOMLEFT", 44, 12)
            else
                btn:SetPoint("LEFT", ui.debuffs[i - 1], "RIGHT", 2, 0)
            end
        end
        focusFrame:SetHeight(64 + size + 2)
    end

    local function HideAllDebuffs()
        for i = 1, 8 do ui.debuffs[i]:Hide() end
    end

    -- ═══ D. 公共 API（挂 DFUI 表，为将来 /castfocus、焦点读条留口） ═══
    DFUI.Focus = DFUI.Focus or {}

    function DFUI.Focus:HasFocus()
        return state.name ~= nil
    end

    -- 返回 (token, guid, name)：token 可能为 nil（失联），guid 仅 SuperWoW 下有
    function DFUI.Focus:GetFocus()
        return state.token, state.guid, state.name
    end

    function DFUI.Focus:SetFocusUnit(unit)
        if not unit or not UnitExists(unit) then return end
        state.name = UnitName(unit)
        state.token = unit
        state.guid = nil
        if SUPERWOW_VERSION then
            local _, g = UnitExists(unit)
            state.guid = g
        end
        debuffTimers = {}
        slotCache = {}
        curUnit = nil
        focusFrame._dfColdTick = 0  -- 强制下个 tick 立即跑冷档
        focusFrame._dfPreview = nil
        focusFrame:SetAlpha(1)
        focusFrame:Show()
    end

    function DFUI.Focus:ClearFocus()
        state.guid, state.name, state.token = nil, nil, nil
        debuffTimers = {}
        slotCache = {}
        curUnit = nil
        focusFrame:Hide()
    end

    ui.closeBtn:SetScript("OnClick", function()
        DFUI.Focus:ClearFocus()
    end)

    -- 左键点焦点框选中焦点
    focusFrame:RegisterForClicks("LeftButtonUp")
    focusFrame:SetScript("OnClick", function()
        if not state.name then return end
        if curUnit then
            TargetUnit(curUnit)
        else
            TargetByName(state.name, true)
        end
    end)

    -- debuff tooltip
    for i = 1, 8 do
        local btn = ui.debuffs[i]
        btn:SetScript("OnEnter", function()
            if not curUnit then return end
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetUnitDebuff(curUnit, this.debuffIndex)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    -- ═══ E. 渲染 ═══
    local function FormatTimer(tl)
        if tl >= 60 then
            return math.floor(tl / 60) .. "m"
        end
        return math.floor(tl + 0.5)
    end

    local function UpdateDebuffRow(unit)
        if not DFUI:GetTempDB("Focus", "focusShowDebuffs") then
            HideAllDebuffs()
            return
        end
        local now = GetTime()
        local seen = {}
        for i = 1, 8 do
            local texture, stacks, dtype = UnitDebuff(unit, i)
            local btn = ui.debuffs[i]
            if texture then
                btn.icon:SetTexture(texture)
                local c = DEBUFF_COLORS[dtype] or DEBUFF_COLORS.none
                btn.border:SetVertexColor(c[1], c[2], c[3])
                if stacks and stacks > 1 then
                    btn.count:SetText(stacks)
                    btn.count:Show()
                else
                    btn.count:Hide()
                end
                -- 刮名（带槽位缓存：贴图/层数没变不重刮）
                local cache = slotCache[i]
                if not cache or cache.tex ~= texture or cache.stacks ~= stacks then
                    local dname = nil
                    if scanner then
                        scanner:SetUnitDebuff(unit, i)
                        dname = scanner:GetLine(1)
                    end
                    cache = { tex = texture, stacks = stacks, name = dname }
                    slotCache[i] = cache
                end
                -- 计时：首次观测记时 + 查表；过期仍在场视为被刷新，重新起算
                local dname = cache.name
                if dname and dname ~= "" then
                    seen[dname] = true
                    local dur = ZH_DEBUFF_DURATIONS[dname]
                    if dur then
                        local rec = debuffTimers[dname]
                        if not rec or (rec.start + rec.duration) <= now then
                            rec = { start = now, duration = dur }
                            debuffTimers[dname] = rec
                        end
                        local tl = rec.start + rec.duration - now
                        btn.timer:SetText(FormatTimer(tl))
                        btn.timer:Show()
                    else
                        btn.timer:Hide()
                    end
                else
                    btn.timer:Hide()
                end
                btn:Show()
            else
                slotCache[i] = nil
                btn:Hide()
            end
        end
        -- 消失的 debuff 清计时，重新中招时从头起算
        for dname in pairs(debuffTimers) do
            if not seen[dname] then debuffTimers[dname] = nil end
        end
    end

    -- 冷档：名字/等级/职业色/头像（队友冷字段几乎不变，~3s 一刷）
    local function RenderCold(unit)
        local name = UnitName(unit) or state.name or ""
        ui.name:SetText(name)
        local lvl = UnitLevel(unit)
        ui.level:SetText((lvl and lvl > 0) and lvl or "")
        local _, classEng = UnitClass(unit)
        local cc = classEng and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classEng]
        if cc and UnitIsPlayer(unit) then
            ui.hpBar:SetFillColor(cc.r, cc.g, cc.b)
        else
            ui.hpBar:SetFillColor(0, 1, 0)
        end
        -- 头像只用真实 token 刷（SetPortraitTexture 吃 GUID 未实证）
        if not IsGuidStr(unit) and name ~= focusFrame._dfPortraitName then
            SetPortraitTexture(ui.portrait, unit)
            focusFrame._dfPortraitName = name
        end
    end

    local function RenderLive(unit)
        focusFrame:SetAlpha(1)
        if UnitIsConnected(unit) ~= nil or IsGuidStr(unit) then
            ui.offlineBg:Hide()
            ui.offlineTxt:Hide()
            ui.hpBar:Show()
            local maxHp = UnitHealthMax(unit) or 0
            local hp = UnitHealth(unit) or 0
            ui.hpBar.max = maxHp > 0 and maxHp or 1
            if UnitIsDead(unit) or UnitIsGhost(unit) then
                ui.hpBar:SetValue(0, true)
                ui.hpText:SetText("死亡")
            else
                ui.hpBar:SetValue(hp)
                local pct = maxHp > 0 and math.floor(hp / maxHp * 100) or 0
                ui.hpText:SetText(pct .. "%")
            end
            ui.hpText:Show()
            local maxMp = UnitManaMax(unit) or 0
            if maxMp > 0 then
                local r, g, b = GetPowerColor(UnitPowerType(unit))
                ui.mpBar:SetFillColor(r, g, b)
                ui.mpBar.max = maxMp
                ui.mpBar:SetValue(UnitMana(unit) or 0)
                ui.mpBar:Show()
            else
                ui.mpBar:Hide()
            end
        else
            -- 离线：同 mini 队友框范式
            ui.hpBar:Hide()
            ui.mpBar:Hide()
            ui.hpText:Hide()
            ui.offlineBg:Show()
            ui.offlineTxt:Show()
            HideAllDebuffs()
            return
        end
        UpdateDebuffRow(unit)
    end

    -- 陈旧态：解析不到单位（跑远/退组），灰条降透明度，等玩家自己点 x
    local function RenderStale()
        focusFrame:SetAlpha(0.6)
        ui.offlineBg:Hide()
        ui.offlineTxt:Hide()
        ui.hpBar:Show()
        ui.hpBar:SetFillColor(0.5, 0.5, 0.5)
        ui.hpBar.max = 1
        ui.hpBar:SetValue(1, true)
        ui.hpText:SetText("?")
        ui.hpText:Show()
        ui.mpBar:Hide()
        HideAllDebuffs()
    end

    -- 0.2s tick（挂 focusFrame 自身：无焦点=隐藏=零开销）
    focusFrame:SetScript("OnUpdate", function()
        if (this._dfTick or 0) > GetTime() then return end
        this._dfTick = GetTime() + 0.2
        if not state.name then return end  -- 布局预览态不跑数据
        local unit = ResolveUnit()
        if unit then
            if unit ~= curUnit or (this._dfColdTick or 0) <= GetTime() then
                this._dfColdTick = GetTime() + 3
                RenderCold(unit)
            end
            curUnit = unit
            RenderLive(unit)
            DFUI.predictFocus = unit
        else
            curUnit = nil
            RenderStale()
            DFUI.predictFocus = nil
        end
    end)

    -- ═══ F. 右键菜单注入（pfUI chat/gm/loot.lua 范式） ═══
    local function MenuHas(menu, val)
        for i = 1, table.getn(menu) do
            if menu[i] == val then return true end
        end
        return false
    end

    local function InsertBeforeCancel(menu, val)
        if MenuHas(menu, val) then return end
        for i = 1, table.getn(menu) do
            if menu[i] == "CANCEL" then
                table.insert(menu, i, val)
                return
            end
        end
        table.insert(menu, val)
    end

    UnitPopupButtons["DFUI_SET_FOCUS"]   = { text = "设置焦点", dist = 0 }
    UnitPopupButtons["DFUI_CLEAR_FOCUS"] = { text = "取消焦点", dist = 0 }

    -- PARTY 覆盖 vanilla 小队框 + ShaguTweaks 团队格；RAID 覆盖名册按钮
    if UnitPopupMenus and UnitPopupMenus["PARTY"] then
        InsertBeforeCancel(UnitPopupMenus["PARTY"], "DFUI_SET_FOCUS")
        InsertBeforeCancel(UnitPopupMenus["PARTY"], "DFUI_CLEAR_FOCUS")
    end
    if UnitPopupMenus and UnitPopupMenus["RAID"] then
        InsertBeforeCancel(UnitPopupMenus["RAID"], "DFUI_SET_FOCUS")
        InsertBeforeCancel(UnitPopupMenus["RAID"], "DFUI_CLEAR_FOCUS")
    end

    -- 点击处理（DFUI 版 hooksecurefunc 默认新先旧后，append=true 才是原函数先跑）
    hooksecurefunc("UnitPopup_OnClick", function()
        local value = this and this.value
        if value ~= "DFUI_SET_FOCUS" and value ~= "DFUI_CLEAR_FOCUS" then return end
        if value == "DFUI_CLEAR_FOCUS" then
            DFUI.Focus:ClearFocus()
            return
        end
        local dropdown = _G[UIDROPDOWNMENU_INIT_MENU]
        if not dropdown then return end
        local unit = dropdown.unit
        if (not unit or not UnitExists(unit)) and dropdown.name then
            -- 名册路径兜底：只有 name 时按名反查 raid token
            for i = 1, GetNumRaidMembers() do
                if UnitName("raid" .. i) == dropdown.name then
                    unit = "raid" .. i
                    break
                end
            end
        end
        if unit and UnitExists(unit) then
            DFUI.Focus:SetFocusUnit(unit)
        end
    end, true)

    -- "取消焦点"只在已设焦点时显示（原 HideButtons 会重置为显示，必须 append 在其后跑）
    hooksecurefunc("UnitPopup_HideButtons", function()
        if DFUI.Focus:HasFocus() then return end
        local dropdown = _G[UIDROPDOWNMENU_INIT_MENU]
        if not dropdown or not dropdown.which then return end
        local menu = UnitPopupMenus[dropdown.which]
        if not menu then return end
        for index = 1, table.getn(menu) do
            if menu[index] == "DFUI_CLEAR_FOCUS" then
                UnitPopupShown[index] = 0
            end
        end
    end, true)

    -- ═══ G. 布局模式预览（frames.lua Ctrl+Shift+Alt 钩子） ═══
    function DFUI.ShowFocusPreview()
        if state.name then return end  -- 有真焦点本来就显示
        focusFrame._dfPreview = true
        ui.name:SetText("焦点预览")
        ui.level:SetText("60")
        ui.hpBar:SetFillColor(0, 1, 0)
        ui.hpBar.max = 1
        ui.hpBar:SetValue(1, true)
        ui.hpText:SetText("100%")
        ui.hpText:Show()
        ui.mpBar:SetFillColor(0, 0, 1)
        ui.mpBar.max = 1
        ui.mpBar:SetValue(1, true)
        ui.mpBar:Show()
        ui.offlineBg:Hide()
        ui.offlineTxt:Hide()
        focusFrame:SetAlpha(1)
        focusFrame:Show()
    end

    function DFUI.HideFocusPreview()
        if focusFrame._dfPreview then
            focusFrame._dfPreview = nil
            if not state.name then focusFrame:Hide() end
        end
    end

    -- ═══ H. 初始化 + callbacks ═══
    if not DFUI_FRAMEPOS or not DFUI_FRAMEPOS["DFUIFocusFrame"] then
        focusFrame:ClearAllPoints()
        focusFrame:SetPoint("LEFT", UIParent, "LEFT", 10, 60)
    end
    focusFrame:SetScale(DFUI:GetTempDB("Focus", "focusFrameScale") or 1)
    ApplyDebuffLayout(DFUI:GetTempDB("Focus", "focusDebuffSize"))
    focusFrame:Hide()

    local callbacks = {}

    callbacks.focusFrameScale = function(value)
        focusFrame:SetScale(value)
    end

    callbacks.focusShowDebuffs = function(value)
        if not value then HideAllDebuffs() end
    end

    callbacks.focusDebuffSize = function(value)
        ApplyDebuffLayout(value)
    end

    DFUI:NewCallbacks("Focus", callbacks)
end)
