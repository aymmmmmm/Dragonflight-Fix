----------------------------------------------------------------------
-- DFUI.Assist  --  Attack Bar Module (Dual-Wield + Ranged)
-- Melee: SP_SwingTimer / VGAttackBar landing-time model
-- Ranged: KallyoAutoShot / Quiver / YaHT approach:
--   ITEM_LOCK_CHANGED for shot detection (ammo consumed),
--   UnitRangedDamage("player") for speed (includes all haste).
----------------------------------------------------------------------

DFUI.Assist.AttackBarState = {
    mhStart    = 0,
    mhLandsAt  = 0,
    ohStart    = 0,
    ohLandsAt  = 0,
    mhSpeed    = 0,
    ohSpeed    = 0,
    extraAttacks = 0,
    isAttacking  = false,
    isDualWield  = false,
    rangedStart       = 0,
    rangedLandsAt     = 0,
    rangedSpeed       = 0,
    isRangedAttacking = false,
    autoRepeatActive  = false,
    isCasting          = false,
    lastRangedShotTime = 0,
}

local BAR_WIDTH          = 200
local BAR_HEIGHT_SINGLE  = 18
local BAR_HEIGHT_DUAL    = 10
local BAR_GAP_DUAL       = 1
local FONT_SIZE_SINGLE   = 11
local FONT_SIZE_DUAL     = 8
local SHOT_DEDUP_WINDOW  = 0.4
local lastCastEndTime    = 0

local cachedMHLink = nil
local cachedOHLink = nil

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local NEXT_MELEE_ABILITIES = {
    "Heroic Strike", "英勇打击",
    "Cleave", "顺劈斩",
    "Maul", "槌击",
    "Raptor Strike", "猛禽一击",
    "Slam", "猛击",
}

local function IsNextMeleeAbility(msg)
    if not msg then return false end
    for _, name in ipairs(NEXT_MELEE_ABILITIES) do
        if string.find(msg, name) then return true end
    end
    return false
end

-- Returns "ranged" or nil. 中英双语（中文客户端战斗日志为中文）
local RANGED_PATTERNS = {
    "Auto Shot", "自动射击",
    "Shoot Bow", "弓射击",
    "Shoot Crossbow", "弩射击",
    "Shoot Gun", "枪械射击",
    "Your Throw", "投掷",
}
local function DetectRangedType(msg)
    if not msg then return nil end
    for _, p in ipairs(RANGED_PATTERNS) do
        if string.find(msg, p) then return "ranged" end
    end
    return nil
end

-- 招架/额外攻击：优先用 WoW 内置 GlobalString 格式串(语言无关)构造 pattern，
-- 存到 DFUI.Assist 上(避免增加 OnEvent 闭包 upvalue，防 Lua5.0 上限)；运行时再叠加双语硬编码兜底。
do
    local function buildGS(gs)
        if not gs or gs == "" then return nil end
        local p = string.gsub(gs, "%%%d?%$?s", "(.+)")
        p = string.gsub(p, "%%%d?%$?d", "%%d+")
        return p
    end
    DFUI.Assist.parryPattern = buildGS(VSPARRYOTHERSELF)
    DFUI.Assist.extraPattern = buildGS(SPELLEXTRAATTACKSSELF) or buildGS(SPELLEXTRAATTACKSOTHER)
end

-- Consumable flag: CHAT_MSG_SPELL_SELF_BUFF fires before ITEM_LOCK_CHANGED
-- for potions/food etc. We use this to filter non-shot lock changes.
local isConsumableItem = false

local function SetBarFontSize(fontString, size)
    local fontPath, _, fontFlags = fontString:GetFont()
    if fontPath then
        fontString:SetFont(fontPath, size, fontFlags)
    end
end

-- 仅在文本变化时 SetText：避免 OnUpdate 每帧重布局 FontString（仿 cast.lua 的 _lastTimeStr 缓存）。
-- %.1f 精度下同一 0.1s 窗口内多帧字符串相同，可挡掉约 5/6 的 SetText 调用。
local function SetTextIfChanged(fs, str)
    if fs._dfLastText ~= str then
        fs:SetText(str)
        fs._dfLastText = str
    end
end

-- 填充：普通 Texture 用 SetWidth + SetTexCoord 模拟 StatusBar（仿 cast.lua UpdateBarVisual）。
-- 避开 1.12/DXVK 下 StatusBar 每帧裁剪自定义大图(CastingBarStandard3 512×32)导致的卡顿。
-- 纹理锚 LEFT 于父 frame，progress 0~1：宽度按比例、texcoord 横向裁剪。高度在 ApplyBarLayout 设。
local function SetBarFill(tex, progress)
    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end
    local w = BAR_WIDTH * progress
    if w < 0.1 then w = 0.1 end   -- SetWidth(0) 在 1.12 行为异常，保留极小值
    tex:SetWidth(w)
    tex:SetTexCoord(0, progress, 0, 1)
end

local function ApplyBarLayout(f)
    if not f then return end
    local state = DFUI.Assist.AttackBarState

    local barCount = 0
    if state.isAttacking then
        barCount = barCount + 1
        if state.isDualWield then barCount = barCount + 1 end
    end
    if state.isRangedAttacking then barCount = barCount + 1 end

    local layoutKey = tostring(barCount)
        .. (state.isDualWield and "d" or "")
        .. (state.isRangedAttacking and "r" or "")
    if f.currentLayout == layoutKey then return end
    f.currentLayout = layoutKey

    local isMulti = barCount > 1
    local h  = isMulti and BAR_HEIGHT_DUAL or BAR_HEIGHT_SINGLE
    local fs = isMulti and FONT_SIZE_DUAL  or FONT_SIZE_SINGLE

    f:SetHeight(h)
    if f.bar then f.bar:SetHeight(h) end
    SetBarFontSize(f.txt, fs)

    if f.ohFrame then
        f.ohFrame:SetHeight(h)
        if f.ohBar then f.ohBar:SetHeight(h) end
        f.ohFrame:ClearAllPoints()
        f.ohFrame:SetPoint("TOP", f, "BOTTOM", 0, -BAR_GAP_DUAL)
        SetBarFontSize(f.ohTxt, fs)
    end

    if f.rangedFrame then
        f.rangedFrame:SetHeight(h)
        if f.rangedBar then f.rangedBar:SetHeight(h) end
        SetBarFontSize(f.rangedTxt, fs)
        f.rangedFrame:ClearAllPoints()
        if not state.isAttacking then
            f.rangedFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        elseif state.isDualWield then
            f.rangedFrame:SetPoint("TOP", f.ohFrame, "BOTTOM", 0, -BAR_GAP_DUAL)
        else
            f.rangedFrame:SetPoint("TOP", f, "BOTTOM", 0, -BAR_GAP_DUAL)
        end
    end
end

local function UpdateWeaponCache()
    local mhSlot = GetInventorySlotInfo("MainHandSlot")
    local ohSlot = GetInventorySlotInfo("SecondaryHandSlot")
    cachedMHLink = GetInventoryItemLink("player", mhSlot)
    cachedOHLink = GetInventoryItemLink("player", ohSlot)
end

-- UnitRangedDamage("player") returns the fully modified ranged attack speed,
-- already including haste from quivers, ammo pouches, enchants, and buffs.
-- This is confirmed by all major vanilla 1.12 auto-shot addons
-- (KallyoAutoShot, Quiver, YaHT).
--
-- Tooltip scan is kept as a fallback, because some servers
-- return 0 from UnitRangedDamage.
local SCAN_TIP_NAME = "DFUIAssistAttackBarScanTip"

local function GetRangedSlotSpeedFromTooltip()
    local slotID = GetInventorySlotInfo("RangedSlot")
    if not slotID then return 0 end
    if not GetInventoryItemLink("player", slotID) then return 0 end

    local tip = getglobal(SCAN_TIP_NAME)
    if not tip then
        tip = CreateFrame("GameTooltip", SCAN_TIP_NAME, nil, "GameTooltipTemplate")
    end
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetInventoryItem("player", slotID)

    for i = 1, tip:NumLines() do
        local right = getglobal(SCAN_TIP_NAME .. "TextRight" .. i)
        if right and right:IsShown() then
            local text = right:GetText()
            if text then
                local _, _, s = string.find(text, "(%d+%.?%d*)")
                if s then
                    local speed = tonumber(s)
                    if speed and speed > 0 then
                        tip:Hide()
                        return speed
                    end
                end
            end
        end
    end
    tip:Hide()
    return 0
end

local function GetRangedSpeed()
    local speed = UnitRangedDamage("player") or 0
    if speed > 0 then return speed end
    return GetRangedSlotSpeedFromTooltip()
end

----------------------------------------------------------------------
-- State management
----------------------------------------------------------------------

function DFUI.Assist.ResetAttackBarState()
    local s = DFUI.Assist.AttackBarState
    s.mhStart    = 0
    s.mhLandsAt  = 0
    s.ohStart    = 0
    s.ohLandsAt  = 0
    s.mhSpeed    = 0
    s.ohSpeed    = 0
    s.extraAttacks = 0
    s.isAttacking  = false
    s.isDualWield  = false
    s.rangedStart       = 0
    s.rangedLandsAt     = 0
    s.rangedSpeed       = 0
    s.isRangedAttacking = false
    s.autoRepeatActive  = false
    s.isCasting          = false
    s.lastRangedShotTime = 0
    isConsumableItem    = false
    lastCastEndTime     = 0
end

----------------------------------------------------------------------
-- Core swing handlers  (VGAttackBar landing-time approach)
----------------------------------------------------------------------

local function HandleAutoAttackSwing(f)
    local state = DFUI.Assist.AttackBarState
    local now   = GetTime()

    state.mhSpeed, state.ohSpeed = UnitAttackSpeed("player")
    state.mhSpeed = state.mhSpeed or 0
    state.ohSpeed = state.ohSpeed or 0
    state.isDualWield = (state.ohSpeed > 0)
    state.isAttacking = true
    ApplyBarLayout(f)

    if now >= state.mhLandsAt + 0.3 then state.mhLandsAt = 0 end
    if now >= state.ohLandsAt + 0.3 then state.ohLandsAt = 0 end
    if state.mhLandsAt == 0 then state.mhLandsAt = now end
    if state.ohLandsAt == 0 then state.ohLandsAt = now end
    if not state.isDualWield then state.ohLandsAt = now + 1000000 end

    if state.extraAttacks > 0 or state.mhLandsAt <= state.ohLandsAt then
        if state.extraAttacks > 0 then
            state.extraAttacks = state.extraAttacks - 1
        end
        state.mhStart   = now
        state.mhLandsAt = now + state.mhSpeed
        if state.isDualWield and state.ohLandsAt < now + 0.2 then
            state.ohLandsAt = now + 0.2
        end
    else
        state.ohStart   = now
        state.ohLandsAt = now + state.ohSpeed
        if state.mhLandsAt < now + 0.2 then
            state.mhLandsAt = now + 0.2
        end
    end

    f:Show()

    if state.isDualWield then
        f.ohFrame:Show()
    else
        f.ohFrame:Hide()
    end

    if f.StartOnUpdate then f.StartOnUpdate() end
end

local function HandleNextMeleeSwing(f)
    local state = DFUI.Assist.AttackBarState
    local now   = GetTime()

    state.mhSpeed, state.ohSpeed = UnitAttackSpeed("player")
    state.mhSpeed = state.mhSpeed or 0
    state.ohSpeed = state.ohSpeed or 0
    state.isDualWield = (state.ohSpeed > 0)
    state.isAttacking = true
    ApplyBarLayout(f)

    if now >= state.ohLandsAt + 0.3 then state.ohLandsAt = 0 end
    if state.ohLandsAt == 0 then state.ohLandsAt = now end
    if not state.isDualWield then state.ohLandsAt = now + 1000000 end

    state.mhStart   = now
    state.mhLandsAt = now + state.mhSpeed

    if state.isDualWield and state.ohLandsAt < now + 0.2 then
        state.ohLandsAt = now + 0.2
    end

    f:Show()

    if state.isDualWield then
        f.ohFrame:Show()
    else
        f.ohFrame:Hide()
    end

    if f.StartOnUpdate then f.StartOnUpdate() end
end

----------------------------------------------------------------------
-- Ranged swing handler
-- Based on proven techniques from KallyoAutoShot, Quiver, and YaHT:
-- Always use UnitRangedDamage("player") for speed (includes all haste).
-- Detection via ITEM_LOCK_CHANGED (ranged) or combat log.
----------------------------------------------------------------------

local function HandleRangedSwing(f)
    local state = DFUI.Assist.AttackBarState
    local now   = GetTime()

    if now - state.lastRangedShotTime < SHOT_DEDUP_WINDOW then return end

    local speed = GetRangedSpeed()
    if speed <= 0 then return end

    state.lastRangedShotTime = now
    state.isCasting = false
    state.isAttacking = false
    state.isDualWield = false
    state.isRangedAttacking = true
    state.rangedSpeed   = speed
    state.rangedStart   = now
    state.rangedLandsAt = now + speed

    f.rangedBar:SetVertexColor(0.3, 0.7, 0.4)

    ApplyBarLayout(f)
    f.rangedFrame:Show()
    f:Show()

    if f.StartOnUpdate then f.StartOnUpdate() end
end

----------------------------------------------------------------------
-- Haste change: proportionally adjust remaining swing time
----------------------------------------------------------------------

local function HandleHasteChange()
    local state = DFUI.Assist.AttackBarState
    if not state.isAttacking and not state.isRangedAttacking then return end

    local now = GetTime()
    local f   = DFUI.Assist.AttackBarFrame
    if not f then return end

    if state.isAttacking then
        local oldMH = state.mhSpeed
        local oldOH = state.ohSpeed
        state.mhSpeed, state.ohSpeed = UnitAttackSpeed("player")
        state.mhSpeed = state.mhSpeed or 0
        state.ohSpeed = state.ohSpeed or 0

        if oldMH > 0 and state.mhSpeed > 0 and oldMH ~= state.mhSpeed
           and state.mhLandsAt > now then
            local timeLeft = (state.mhLandsAt - now) / (oldMH / state.mhSpeed)
            state.mhLandsAt = now + timeLeft
        end

        if oldOH > 0 and state.ohSpeed > 0 and oldOH ~= state.ohSpeed
           and state.ohLandsAt > now then
            local timeLeft = (state.ohLandsAt - now) / (oldOH / state.ohSpeed)
            state.ohLandsAt = now + timeLeft
        end
    end

    if state.isRangedAttacking and f.rangedBar then
        local oldRanged = state.rangedSpeed
        local newRanged = GetRangedSpeed()
        if oldRanged > 0 and newRanged > 0 and oldRanged ~= newRanged
           and state.rangedLandsAt > now then
            local timeLeft = (state.rangedLandsAt - now) / (oldRanged / newRanged)
            state.rangedSpeed   = newRanged
            state.rangedLandsAt = now + timeLeft
        end
    end
end

----------------------------------------------------------------------
-- Parry haste: reduce MH timer by 40 %, capped at 20 % minimum
----------------------------------------------------------------------

local function HandleParryHaste()
    local state = DFUI.Assist.AttackBarState
    if not state.isAttacking then return end

    local now        = GetTime()
    local swingTotal = state.mhLandsAt - state.mhStart
    if swingTotal <= 0 then return end

    local timeLeft = state.mhLandsAt - now
    local minimum  = swingTotal * 0.20

    if timeLeft > minimum then
        local reduction  = swingTotal * 0.40
        local newTimeLeft = timeLeft - reduction
        if newTimeLeft < minimum then
            state.mhLandsAt = now + minimum
        else
            state.mhLandsAt = now + newTimeLeft
        end
    end
end

----------------------------------------------------------------------
-- Frame creation
----------------------------------------------------------------------

function DFUI.Assist.CreateAttackBar()
    if DFUI.Assist.AttackBarFrame then return end

    local f = getglobal("DFUIAssistAttackBar")
              or CreateFrame("Frame", "DFUIAssistAttackBar", UIParent)
    f:SetWidth(BAR_WIDTH)
    f:SetHeight(BAR_HEIGHT_SINGLE)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f.currentLayout = nil

    -- 位置/拖动交给 DFUI 统一布局系统（frames.lua 的 MakeFrameMovable + DFUI_FRAMEPOS）：
    -- 主框 DFUIAssistAttackBar 已注册进 framesToMakeMovable，按住 Ctrl+Shift+Alt 进布局模式拖动。

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetTexture("Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\castbar\\CastingBarBackground.blp")

    -- Main Hand fill texture（普通 Texture，左对齐，宽度/texcoord 由 SetBarFill 推进）
    local bar = f:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("LEFT", f, "LEFT", 0, 0)
    bar:SetHeight(BAR_HEIGHT_SINGLE)
    bar:SetWidth(0.1)
    bar:SetTexture("Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\castbar\\CastingBarStandard3.tga")
    bar:SetVertexColor(0.85, 0.55, 0.2)

    -- 文字 parent 外层 frame（非 bar）：bar 宽度随进度变，文字须固定居中
    local txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("CENTER", f, "CENTER", 0, 0)
    txt:SetTextColor(1, 1, 1)
    txt:SetText("攻击")

    f.mhBg = bg
    f.bar  = bar
    f.txt  = txt

    -- Off-Hand frame
    local ohFrame = getglobal("DFUIAssistAttackBarOH")
                    or CreateFrame("Frame", "DFUIAssistAttackBarOH", f)
    ohFrame:SetWidth(BAR_WIDTH)
    ohFrame:SetHeight(BAR_HEIGHT_DUAL)
    ohFrame:SetPoint("TOP", f, "BOTTOM", 0, -BAR_GAP_DUAL)
    ohFrame:EnableMouse(true)   -- 仅为 tooltip；拖动随主框（统一布局系统）

    local ohBg = ohFrame:CreateTexture(nil, "BACKGROUND")
    ohBg:SetAllPoints(ohFrame)
    ohBg:SetTexture("Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\castbar\\CastingBarBackground.blp")

    local ohBar = ohFrame:CreateTexture(nil, "ARTWORK")
    ohBar:SetPoint("LEFT", ohFrame, "LEFT", 0, 0)
    ohBar:SetHeight(BAR_HEIGHT_DUAL)
    ohBar:SetWidth(0.1)
    ohBar:SetTexture("Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\castbar\\CastingBarStandard3.tga")
    ohBar:SetVertexColor(0.3, 0.55, 0.8)

    local ohTxt = ohFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ohTxt:SetPoint("CENTER", ohFrame, "CENTER", 0, 0)
    ohTxt:SetTextColor(1, 1, 1)
    ohTxt:SetText("副手")

    ohFrame:Hide()
    f.ohFrame = ohFrame
    f.ohBar   = ohBar
    f.ohTxt   = ohTxt

    ohFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(f, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("攻击条 (副手)")
        GameTooltip:AddLine("双持武器时自动显示副手攻击进度", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("按住 Ctrl+Shift+Alt 进入布局模式拖动", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    ohFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ----------------------------------------------------------------
    -- Ranged frame
    ----------------------------------------------------------------
    local rangedFrame = getglobal("DFUIAssistAttackBarRanged")
                        or CreateFrame("Frame", "DFUIAssistAttackBarRanged", f)
    rangedFrame:SetWidth(BAR_WIDTH)
    rangedFrame:SetHeight(BAR_HEIGHT_SINGLE)
    rangedFrame:SetPoint("TOP", f, "BOTTOM", 0, -BAR_GAP_DUAL)
    rangedFrame:EnableMouse(true)   -- 仅为 tooltip；拖动随主框（统一布局系统）

    local rangedBg = rangedFrame:CreateTexture(nil, "BACKGROUND")
    rangedBg:SetAllPoints(rangedFrame)
    rangedBg:SetTexture("Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\castbar\\CastingBarBackground.blp")

    local rangedBar = rangedFrame:CreateTexture(nil, "ARTWORK")
    rangedBar:SetPoint("LEFT", rangedFrame, "LEFT", 0, 0)
    rangedBar:SetHeight(BAR_HEIGHT_SINGLE)
    rangedBar:SetWidth(0.1)
    rangedBar:SetTexture("Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\castbar\\CastingBarStandard3.tga")
    rangedBar:SetVertexColor(0.3, 0.7, 0.4)

    local rangedTxt = rangedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rangedTxt:SetPoint("CENTER", rangedFrame, "CENTER", 0, 0)
    rangedTxt:SetTextColor(1, 1, 1)
    rangedTxt:SetText("射击")

    rangedFrame:Hide()
    f.rangedFrame = rangedFrame
    f.rangedBar   = rangedBar
    f.rangedTxt   = rangedTxt

    rangedFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(f, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("攻击条 (远程)")
        GameTooltip:AddLine("自动检测射击(Auto Shot)攻击", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("射击条为绿色", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("按住 Ctrl+Shift+Alt 进入布局模式拖动", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    rangedFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdateWeaponCache()

    ----------------------------------------------------------------
    -- Events
    ----------------------------------------------------------------
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
    f:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
    f:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
    f:RegisterEvent("CHAT_MSG_SPELL_SELF_MISSES")
    f:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
    f:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
    f:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
    f:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
    f:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES")
    f:RegisterEvent("UNIT_INVENTORY_CHANGED")
    f:RegisterEvent("START_AUTOREPEAT_SPELL")
    f:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    f:RegisterEvent("ITEM_LOCK_CHANGED")
    f:RegisterEvent("SPELLCAST_STOP")
    f:RegisterEvent("SPELLCAST_START")
    f:RegisterEvent("SPELLCAST_FAILED")
    f:RegisterEvent("SPELLCAST_INTERRUPTED")

    f:SetScript("OnEvent", function()
        if not DFUI.Assist:IsEnabled("uiAttackBar") then return end
        local state = DFUI.Assist.AttackBarState

        if event == "PLAYER_ENTERING_WORLD" then
            if not UnitAffectingCombat("player") then
                DFUI.Assist.ResetAttackBarState()
                ApplyBarLayout(f)
                f:Hide()
                f.ohFrame:Hide()
                f.rangedFrame:Hide()
            end
            UpdateWeaponCache()

        elseif event == "PLAYER_REGEN_ENABLED" then
            DFUI.Assist.ResetAttackBarState()
            ApplyBarLayout(f)
            f:Hide()
            f.ohFrame:Hide()
            f.rangedFrame:Hide()

        -- Melee auto-attack hit / miss (NEVER ranged — ranged hits go
        -- to CHAT_MSG_SPELL_SELF_DAMAGE as "Your Auto Shot / Shoot …")
        elseif event == "CHAT_MSG_COMBAT_SELF_HITS"
            or event == "CHAT_MSG_COMBAT_SELF_MISSES" then
            if not state.autoRepeatActive then
                HandleAutoAttackSwing(f)
            end

        -- Spell damage / misses: next-melee abilities, ranged attacks.
        elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE"
            or event == "CHAT_MSG_SPELL_SELF_MISSES" then
            if arg1 then
                if IsNextMeleeAbility(arg1) then
                    HandleNextMeleeSwing(f)
                else
                    local rtype = DetectRangedType(arg1)
                    if rtype == "ranged" then
                        HandleRangedSwing(f)
                    end
                end
            end

        -- ITEM_LOCK_CHANGED: fires when ammo is consumed (ranged shot).
        elseif event == "ITEM_LOCK_CHANGED" then
            if state.autoRepeatActive then
                if not isConsumableItem then
                    local now = GetTime()
                    local isBarReady = not state.isRangedAttacking
                                       or now >= state.rangedLandsAt - 0.1
                    local isPostCast = (now - lastCastEndTime) < 1.0
                    if isBarReady or isPostCast then
                        HandleRangedSwing(f)
                    end
                end
                isConsumableItem = false
            end

        -- SPELLCAST_STOP: fires when any spell finishes casting.
        elseif event == "SPELLCAST_STOP" then
            if state.autoRepeatActive then
                state.isCasting = false
                lastCastEndTime = GetTime()
            end

        elseif event == "SPELLCAST_START" then
            if state.autoRepeatActive then
                state.isCasting = true
            end

        elseif event == "SPELLCAST_FAILED"
            or event == "SPELLCAST_INTERRUPTED" then
            state.isCasting = false

        -- Buff gain / loss → haste tracking + extra-attack detection
        -- Also sets consumable flag for ITEM_LOCK_CHANGED filtering:
        -- CHAT_MSG_SPELL_SELF_BUFF fires BEFORE ITEM_LOCK_CHANGED
        -- when using potions/food/consumables.
        elseif event == "CHAT_MSG_SPELL_SELF_BUFF"
            or event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
            if arg1 then
                local ep = DFUI.Assist.extraPattern
                if (ep and string.find(arg1, ep))
                    or string.find(arg1, "extra attack") or string.find(arg1, "额外") then
                    state.extraAttacks = state.extraAttacks + 1
                elseif string.find(arg1, "Fury of Forgewright") then
                    state.extraAttacks = state.extraAttacks + 2
                else
                    if state.autoRepeatActive then
                        isConsumableItem = true
                    end
                end
            end
            HandleHasteChange()

        elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF"
            or event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
            HandleHasteChange()

        -- Player parried an incoming attack → parry haste
        elseif event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" then
            local pp = DFUI.Assist.parryPattern
            if arg1 and ((pp and string.find(arg1, pp))
                or string.find(arg1, "You parry") or string.find(arg1, "招架")) then
                HandleParryHaste()
            end

        -- Auto-repeat started (Auto Shot)
        elseif event == "START_AUTOREPEAT_SPELL" then
            state.autoRepeatActive = true
            local speed = GetRangedSpeed()
            if speed > 0 then
                HandleRangedSwing(f)
            end

        -- Auto-repeat stopped
        elseif event == "STOP_AUTOREPEAT_SPELL" then
            state.autoRepeatActive = false
            state.isRangedAttacking = false
            state.isCasting = false
            f.rangedFrame:Hide()
            ApplyBarLayout(f)

        -- Weapon swap while in combat
        elseif event == "UNIT_INVENTORY_CHANGED" then
            if arg1 == "player" then
                local mhSlot = GetInventorySlotInfo("MainHandSlot")
                local ohSlot = GetInventorySlotInfo("SecondaryHandSlot")
                local newMH  = GetInventoryItemLink("player", mhSlot)
                local newOH  = GetInventoryItemLink("player", ohSlot)

                if state.isAttacking then
                    local now = GetTime()
                    if newMH ~= cachedMHLink then
                        state.mhSpeed = UnitAttackSpeed("player") or 0
                        state.mhStart   = now
                        state.mhLandsAt = now + state.mhSpeed
                    end
                    local _, newOHSpd = UnitAttackSpeed("player")
                    if newOH ~= cachedOHLink and newOHSpd and newOHSpd > 0 then
                        state.ohSpeed   = newOHSpd
                        state.ohStart   = now
                        state.ohLandsAt = now + state.ohSpeed
                    end
                end
                cachedMHLink = newMH
                cachedOHLink = newOH
            end
        end
    end)

    ----------------------------------------------------------------
    -- OnUpdate  —  absolute-time StatusBar
    ----------------------------------------------------------------
    local function AttackBarOnUpdate()
        if not DFUI.Assist:IsEnabled("uiAttackBar") then
            f:Hide()
            f.ohFrame:Hide()
            f.rangedFrame:Hide()
            f:SetScript("OnUpdate", nil)
            return
        end

        local state = DFUI.Assist.AttackBarState
        local now   = GetTime()
        local mhActive = false
        local ohActive = false
        local rangedActive = false

        -- Main hand  (min/max 已在 swing handler 设好，OnUpdate 只推进 value)
        if state.isAttacking and state.mhLandsAt > 0 then
            if now < state.mhLandsAt then
                local total = state.mhLandsAt - state.mhStart
                SetBarFill(f.bar, total > 0 and (now - state.mhStart) / total or 1)
                local remaining = state.mhLandsAt - now
                if state.isDualWield then
                    SetTextIfChanged(f.txt, string.format("主手 %.1f", remaining))
                else
                    SetTextIfChanged(f.txt, string.format("%.1f", remaining))
                end
                mhActive = true
            elseif now <= state.mhLandsAt + 0.5 then
                SetBarFill(f.bar, 1)
                if state.isDualWield then
                    SetTextIfChanged(f.txt, "主手 就绪")
                else
                    SetTextIfChanged(f.txt, "Ready")
                end
                mhActive = true
            end
        end

        if mhActive then
            f.bar:Show()
            if f.mhBg then f.mhBg:Show() end
        else
            f.bar:Hide()
            if f.mhBg then f.mhBg:Hide() end
        end

        -- Off-hand  (同上，去掉每帧冗余 SetMinMaxValues)
        if state.isAttacking and state.isDualWield and state.ohLandsAt > 0
           and state.ohLandsAt < now + 999999 then
            if now < state.ohLandsAt then
                local total = state.ohLandsAt - state.ohStart
                SetBarFill(f.ohBar, total > 0 and (now - state.ohStart) / total or 1)
                SetTextIfChanged(f.ohTxt, string.format("副手 %.1f", state.ohLandsAt - now))
                f.ohFrame:Show()
                ohActive = true
            elseif now <= state.ohLandsAt + 0.5 then
                SetBarFill(f.ohBar, 1)
                SetTextIfChanged(f.ohTxt, "副手 就绪")
                f.ohFrame:Show()
                ohActive = true
            else
                f.ohFrame:Hide()
            end
        end

        -- Ranged  (同上，去掉每帧冗余 SetMinMaxValues)
        if state.isRangedAttacking and state.rangedLandsAt > 0 then
            if now < state.rangedLandsAt then
                local total = state.rangedLandsAt - state.rangedStart
                SetBarFill(f.rangedBar, total > 0 and (now - state.rangedStart) / total or 1)
                local remaining = state.rangedLandsAt - now
                SetTextIfChanged(f.rangedTxt, string.format("射击 %.1f", remaining))
                f.rangedFrame:Show()
                rangedActive = true
            elseif state.autoRepeatActive then
                SetBarFill(f.rangedBar, 1)
                if state.isCasting then
                    SetTextIfChanged(f.rangedTxt, "射击 施法中")
                else
                    SetTextIfChanged(f.rangedTxt, "射击 就绪")
                end
                f.rangedFrame:Show()
                rangedActive = true
            elseif now <= state.rangedLandsAt + 0.5 then
                SetBarFill(f.rangedBar, 1)
                SetTextIfChanged(f.rangedTxt, "射击 就绪")
                f.rangedFrame:Show()
                rangedActive = true
            else
                f.rangedFrame:Hide()
            end
        end

        if mhActive or ohActive or rangedActive then
            f:Show()
        else
            state.isAttacking = false
            state.isRangedAttacking = false
            ApplyBarLayout(f)
            f:Hide()
            f.ohFrame:Hide()
            f.rangedFrame:Hide()
            f:SetScript("OnUpdate", nil)
        end
    end

    f.StartOnUpdate = function()
        f:SetScript("OnUpdate", AttackBarOnUpdate)
    end

    f:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("攻击条")
        GameTooltip:AddLine("自动检测双持武器，分别显示主/副手进度", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("支持远程射击(Auto Shot)", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("急速变化 / 招架加速 / 额外攻击 实时修正", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("按住 Ctrl+Shift+Alt 进入布局模式拖动", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("在 ESC→辅助功能 配置页开关", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f:Hide()
    DFUI.Assist.AttackBarFrame = f
end

----------------------------------------------------------------------
-- 测试/排查：强制显示一次主手挥击条(不依赖战斗) + 打印开关状态
-- 用法： /script DFUI.Assist.AttackBarTest()
----------------------------------------------------------------------
function DFUI.Assist.AttackBarTest()
    local f = DFUI.Assist.AttackBarFrame
    local en = DFUI.Assist:IsEnabled("uiAttackBar")
    local master = DFUI.tempDB and DFUI.tempDB["Assist"] and DFUI.tempDB["Assist"].masterOn
    DEFAULT_CHAT_FRAME:AddMessage("[攻击条] frame="..tostring(f ~= nil)
        .."  uiAttackBar="..tostring(en).."  masterOn="..tostring(master))
    if not f then return end
    local s = DFUI.Assist.AttackBarState
    local now = GetTime()
    local mh = UnitAttackSpeed("player") or 2.0
    if mh <= 0 then mh = 2.0 end
    s.isAttacking = true
    s.isDualWield = false
    s.isRangedAttacking = false
    s.mhSpeed = mh
    s.mhStart = now
    s.mhLandsAt = now + mh
    ApplyBarLayout(f)
    f:Show()
    f.ohFrame:Hide()
    f.rangedFrame:Hide()
    if f.StartOnUpdate then f.StartOnUpdate() end
end

----------------------------------------------------------------------
-- DFUI.Assist 注册：key=uiAttackBar，登录建条，开关即时门控
----------------------------------------------------------------------
DFUI.Assist:register({
    key = "uiAttackBar",
    title = DFUI.Assist.L["uiAttackBar"],
    desc = DFUI.Assist.L["uiAttackBarDesc"],
    default = true,
    load = function(self)
        if DFUI.Assist.CreateAttackBar then DFUI.Assist.CreateAttackBar() end
    end,
})