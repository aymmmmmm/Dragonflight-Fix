-- Orbs Module - Diablo-style Health/Mana globes
-- Textures: Roth_UI (MIT License) + BeardleysDiabloOrbsVanilla
-- Fill method: SetHeight + SetTexCoord

DFUI:NewDefaults("Orbs", {
    enabled = {false},
    showOrbs = {true, "checkbox", nil, nil, "通用", 1, "显示血球/蓝球", nil, nil},
    orbScale = {0.6, "slider", {0.3, 1.5, 0.05}, "showOrbs", "通用", 2, "球体大小", nil, nil},
    orbAlpha = {1, "slider", {0.1, 1, 0.05}, "showOrbs", "通用", 3, "球体透明度", nil, nil},
    orbXOffset = {0, "slider", {-500, 500, 1}, "showOrbs", "位置", 4, "水平偏移", nil, nil},
    orbYOffset = {0, "slider", {-400, 400, 1}, "showOrbs", "位置", 5, "垂直偏移", nil, nil},
    showFrame = {true, "checkbox", nil, "showOrbs", "边框", 6, "显示球体边框", nil, nil},
    frameScale = {1, "slider", {0.3, 2, 0.05}, "showFrame", "边框", 7, "边框大小", nil, nil},
    frameLX = {0, "slider", {-100, 100, 1}, "showFrame", "左边框", 8, "左边框水平偏移", nil, nil},
    frameLY = {0, "slider", {-100, 100, 1}, "showFrame", "左边框", 9, "左边框垂直偏移", nil, nil},
    frameRX = {0, "slider", {-100, 100, 1}, "showFrame", "右边框", 10, "右边框水平偏移", nil, nil},
    frameRY = {0, "slider", {-100, 100, 1}, "showFrame", "右边框", 11, "右边框垂直偏移", nil, nil},
    showGloss = {true, "checkbox", nil, "showOrbs", "外观", 12, "显示高光反射", nil, nil},
    showText = {true, "checkbox", nil, "showOrbs", "文字", 13, "显示数值", nil, nil},
    textFormat = {"percent", "dropdown", {"percent", "current", "current/max"}, "showText", "文字", 14, "数值格式", nil, nil},
    textSize = {12, "slider", {8, 22}, "showText", "文字", 15, "文字大小", nil, nil},
    lowHealthAlert = {0.25, "slider", {0.1, 0.5, 0.05}, "showOrbs", "警告", 16, "低血量警告阈值", nil, nil},
})

DFUI:NewMod("Orbs", 6, function()
    -- clean up stale keys from previous versions
    local staleKeys = {"replaceGryphons", "frameCropBottom", "frameXOffset", "frameYOffset", "frameDecorX", "frameDecorY", "showFrameDecor"}
    local setup = DFUI.tempDB.Orbs
    for _, key in ipairs(staleKeys) do
        setup[key] = nil
    end
    local texpath = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\orbs\\"
    local ORB_SIZE = 150
    local FILL_TEX = texpath .. "orb_filling21.tga"

    -- ================================================================
    -- CreateOrb
    -- ================================================================
    local function CreateOrb(name, side)
        local orb = CreateFrame("Frame", name, UIParent)
        orb:SetWidth(ORB_SIZE)
        orb:SetHeight(ORB_SIZE)
        orb:SetFrameStrata("LOW")
        orb:SetFrameLevel(5)
        orb:SetScale(setup.orbScale or 0.6)
        orb:SetAlpha(setup.orbAlpha or 1)

        orb.bg = orb:CreateTexture(nil, "BACKGROUND")
        orb.bg:SetTexture(texpath .. "orb_bg.tga")
        orb.bg:SetAllPoints()

        orb.fill = orb:CreateTexture(nil, "BORDER")
        orb.fill:SetTexture(FILL_TEX)
        orb.fill:SetWidth(ORB_SIZE)
        orb.fill:SetHeight(ORB_SIZE)
        orb.fill:SetPoint("BOTTOM", orb, "BOTTOM", 0, 0)

        orb.innerShadow = orb:CreateTexture(nil, "ARTWORK")
        orb.innerShadow:SetTexture(texpath .. "orb_innershadow.tga")
        orb.innerShadow:SetAllPoints()

        orb.frame = orb:CreateTexture(nil, "OVERLAY")
        if side == "left" then
            orb.frame:SetTexture(texpath .. "orb_frame_left.tga")
        else
            orb.frame:SetTexture(texpath .. "orb_frame_right.tga")
        end
        local fScale = setup.frameScale or 1
        orb.frame:SetWidth(ORB_SIZE * fScale)
        orb.frame:SetHeight(ORB_SIZE * fScale)
        if side == "left" then
            orb.frame:SetPoint("CENTER", orb, "CENTER", setup.frameLX or 0, setup.frameLY or 0)
        else
            orb.frame:SetPoint("CENTER", orb, "CENTER", setup.frameRX or 0, setup.frameRY or 0)
        end
        if not setup.showFrame then orb.frame:Hide() end

        orb.gloss = orb:CreateTexture(nil, "OVERLAY")
        orb.gloss:SetTexture(texpath .. "orb_gloss.tga")
        orb.gloss:SetAllPoints()
        orb.gloss:SetAlpha(0.35)
        if not setup.showGloss then orb.gloss:Hide() end

        orb.lowGlow = orb:CreateTexture(nil, "BACKGROUND")
        orb.lowGlow:SetTexture(texpath .. "orb_lowhp_glow.tga")
        orb.lowGlow:SetPoint("CENTER", orb, "CENTER", 0, 0)
        orb.lowGlow:SetWidth(ORB_SIZE * 1.4)
        orb.lowGlow:SetHeight(ORB_SIZE * 1.4)
        orb.lowGlow:Hide()

        orb.text = orb:CreateFontString(nil, "OVERLAY")
        orb.text:SetFont("Fonts\\FRIZQT__.TTF", setup.textSize or 12, "OUTLINE")
        orb.text:SetPoint("CENTER", orb, "CENTER", 0, 0)
        orb.text:SetTextColor(1, 1, 1, 1)
        if not setup.showText then orb.text:Hide() end

        -- cached state to avoid redundant updates
        orb.lastPct = -1

        function orb:SetFillValue(current, max)
            if not max or max <= 0 then return end
            local pct = current / max
            if pct < 0 then pct = 0 end
            if pct > 1 then pct = 1 end

            -- skip if unchanged
            local rounded = math.floor(pct * 1000)
            if rounded == self.lastPct then return end
            self.lastPct = rounded

            if pct <= 0.001 then
                self.fill:Hide()
            else
                self.fill:Show()
                self.fill:SetHeight(ORB_SIZE * pct)
                self.fill:SetTexCoord(0, 1, 1 - pct, 1)
            end
        end

        function orb:UpdateText(current, max, fmt)
            if not max or max <= 0 then return end
            local db = DFUI.tempDB.Orbs
            if not db.showText then return end
            local f = db.textFormat or "percent"
            if f == "percent" then
                self.text:SetText(math.floor(current / max * 100) .. "%")
            elseif f == "current" then
                self.text:SetText(current)
            else
                self.text:SetText(current .. "/" .. max)
            end
        end

        function orb:SetLowAlert(on) end -- replaced after glow functions are defined

        orb:EnableMouse(true)
        orb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOP")
            if this.tipTitle then GameTooltip:AddLine(this.tipTitle, 1, 1, 1) end
            if this.tipValue then GameTooltip:AddLine(this.tipValue, 0.8, 0.8, 0.8) end
            GameTooltip:Show()
        end)
        orb:SetScript("OnLeave", function() GameTooltip:Hide() end)

        return orb
    end

    -- ================================================================
    -- Create orbs
    -- ================================================================
    local actionBar = _G["DFUI_ActionBar"] or MainMenuBar

    local healthOrb = CreateOrb("DFUI_HealthOrb", "left")
    healthOrb:SetPoint("RIGHT", actionBar, "LEFT", 45 + (setup.orbXOffset or 0), 10 + (setup.orbYOffset or 0))
    healthOrb.fill:SetVertexColor(0.8, 0.1, 0.1, 1)
    healthOrb.tipTitle = "生命值"

    local manaOrb = CreateOrb("DFUI_ManaOrb", "right")
    manaOrb:SetPoint("LEFT", actionBar, "RIGHT", -45 - (setup.orbXOffset or 0), 10 + (setup.orbYOffset or 0))
    manaOrb.tipTitle = "法力值"

    -- initial visibility
    if not setup.showOrbs then
        healthOrb:Hide()
        manaOrb:Hide()
    end

    -- shared reposition function (used by callbacks and PLAYER_ENTERING_WORLD)
    local function RepositionOrbs()
        local db = DFUI.tempDB.Orbs
        local xOff = db.orbXOffset or 0
        local yOff = db.orbYOffset or 0
        healthOrb:ClearAllPoints()
        healthOrb:SetPoint("RIGHT", actionBar, "LEFT", 45 + xOff, 10 + yOff)
        manaOrb:ClearAllPoints()
        manaOrb:SetPoint("LEFT", actionBar, "RIGHT", -45 - xOff, 10 + yOff)
    end

    -- ================================================================
    -- Power colors - use DFUI.powerColors from Colors module
    -- ================================================================
    local POWER_NAMES = {
        [0] = "法力值", [1] = "怒气", [2] = "集中值", [3] = "能量",
    }

    local function GetPowerColor(pt)
        if DFUI.powerColors and DFUI.powerColors[pt] then
            return DFUI.powerColors[pt]
        end
        -- fallback if Colors module not loaded
        local fallback = {[0] = {0.2, 0.4, 1.0}, [1] = {0.9, 0.15, 0.15}, [2] = {1, 0.5, 0.2}, [3] = {1, 0.9, 0.2}}
        return fallback[pt] or fallback[0]
    end

    local function UpdatePowerColor()
        local pt = UnitPowerType("player")
        local c = GetPowerColor(pt)
        manaOrb.fill:SetVertexColor(c[1], c[2], c[3], 1)
        manaOrb.tipTitle = POWER_NAMES[pt] or "法力值"
    end
    UpdatePowerColor()

    -- ================================================================
    -- Event-driven updates with change detection
    -- ================================================================
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("UNIT_MAXHEALTH")
    eventFrame:RegisterEvent("UNIT_MANA")
    eventFrame:RegisterEvent("UNIT_RAGE")
    eventFrame:RegisterEvent("UNIT_ENERGY")
    eventFrame:RegisterEvent("UNIT_FOCUS")
    eventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    local lastHP, lastHPMax, lastMP, lastMPMax = -1, -1, -1, -1

    local function UpdateHealth()
        local hp = UnitHealth("player")
        local hpMax = UnitHealthMax("player")
        if hp == lastHP and hpMax == lastHPMax then return end
        lastHP, lastHPMax = hp, hpMax
        if hpMax <= 0 then hpMax = 1 end
        healthOrb:SetFillValue(hp, hpMax)
        healthOrb:UpdateText(hp, hpMax)
        local pct = hp / hpMax
        healthOrb.tipValue = hp .. " / " .. hpMax .. "  (" .. math.floor(pct * 100) .. "%)"
        local threshold = DFUI.tempDB.Orbs.lowHealthAlert or 0.25
        healthOrb:SetLowAlert(pct < threshold)
    end

    local function UpdatePower()
        local mp = UnitMana("player")
        local mpMax = UnitManaMax("player")
        if mp == lastMP and mpMax == lastMPMax then return end
        lastMP, lastMPMax = mp, mpMax
        if mpMax <= 0 then mpMax = 1 end
        manaOrb:SetFillValue(mp, mpMax)
        manaOrb:UpdateText(mp, mpMax)
        local pct = mp / mpMax
        manaOrb.tipValue = mp .. " / " .. mpMax .. "  (" .. math.floor(pct * 100) .. "%)"
    end

    eventFrame:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            -- clear stale DFUI_FRAMEPOS entries to prevent Frames module from overriding orb positions
            if DFUI_FRAMEPOS then
                DFUI_FRAMEPOS["DFUI_HealthOrb"] = nil
                DFUI_FRAMEPOS["DFUI_ManaOrb"] = nil
            end
            -- re-apply orb positions (Frames module's RestoreFramePositions may have cleared them)
            RepositionOrbs()
            UpdatePowerColor()
            lastHP, lastHPMax, lastMP, lastMPMax = -1, -1, -1, -1
            UpdateHealth()
            UpdatePower()
            return
        end
        if event == "UNIT_DISPLAYPOWER" and arg1 == "player" then
            UpdatePowerColor()
            lastMP, lastMPMax = -1, -1
            UpdatePower()
            return
        end
        if arg1 ~= "player" then return end
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            UpdateHealth()
        else
            UpdatePower()
        end
    end)

    -- low health glow animation - only attach OnUpdate when needed
    local glowPhase = 0
    local glowActive = false

    local function StartGlowPulse()
        if glowActive then return end
        glowActive = true
        glowPhase = 0
        eventFrame:SetScript("OnUpdate", function()
            glowPhase = glowPhase + arg1 * 3
            healthOrb.lowGlow:SetAlpha(0.4 + 0.4 * math.abs(math.sin(glowPhase)))
        end)
    end

    local function StopGlowPulse()
        if not glowActive then return end
        glowActive = false
        eventFrame:SetScript("OnUpdate", nil)
    end

    local function SetLowAlert(orb, on)
        if on then
            orb.lowGlow:Show()
            StartGlowPulse()
        else
            orb.lowGlow:Hide()
            StopGlowPulse()
        end
    end

    healthOrb.SetLowAlert = SetLowAlert
    manaOrb.SetLowAlert = SetLowAlert

    -- ================================================================
    -- Callbacks (real-time config)
    -- ================================================================
    local callbacks = {}

    callbacks.orbScale = function(v) healthOrb:SetScale(v); manaOrb:SetScale(v) end
    callbacks.orbAlpha = function(v) healthOrb:SetAlpha(v); manaOrb:SetAlpha(v) end

    callbacks.orbXOffset = function() RepositionOrbs() end
    callbacks.orbYOffset = function() RepositionOrbs() end

    callbacks.showFrame = function(v)
        if v then healthOrb.frame:Show(); manaOrb.frame:Show()
        else healthOrb.frame:Hide(); manaOrb.frame:Hide() end
    end

    callbacks.frameScale = function(v)
        local s = v or 1
        healthOrb.frame:SetWidth(ORB_SIZE * s)
        healthOrb.frame:SetHeight(ORB_SIZE * s)
        manaOrb.frame:SetWidth(ORB_SIZE * s)
        manaOrb.frame:SetHeight(ORB_SIZE * s)
    end

    local function RepositionLeftFrame()
        local db = DFUI.tempDB.Orbs
        healthOrb.frame:ClearAllPoints()
        healthOrb.frame:SetPoint("CENTER", healthOrb, "CENTER", db.frameLX or 0, db.frameLY or 0)
    end

    local function RepositionRightFrame()
        local db = DFUI.tempDB.Orbs
        manaOrb.frame:ClearAllPoints()
        manaOrb.frame:SetPoint("CENTER", manaOrb, "CENTER", db.frameRX or 0, db.frameRY or 0)
    end

    callbacks.frameLX = function() RepositionLeftFrame() end
    callbacks.frameLY = function() RepositionLeftFrame() end
    callbacks.frameRX = function() RepositionRightFrame() end
    callbacks.frameRY = function() RepositionRightFrame() end

    callbacks.showGloss = function(v)
        if v then healthOrb.gloss:Show(); manaOrb.gloss:Show()
        else healthOrb.gloss:Hide(); manaOrb.gloss:Hide() end
    end

    callbacks.showText = function(v)
        if v then healthOrb.text:Show(); manaOrb.text:Show()
        else healthOrb.text:Hide(); manaOrb.text:Hide() end
    end

    callbacks.textSize = function(v)
        healthOrb.text:SetFont("Fonts\\FRIZQT__.TTF", v, "OUTLINE")
        manaOrb.text:SetFont("Fonts\\FRIZQT__.TTF", v, "OUTLINE")
    end

    callbacks.textFormat = function()
        lastHP, lastHPMax, lastMP, lastMPMax = -1, -1, -1, -1
        UpdateHealth()
        UpdatePower()
    end

    callbacks.lowHealthAlert = function()
        lastHP, lastHPMax = -1, -1
        UpdateHealth()
    end

    callbacks.showOrbs = function(v)
        if v then
            healthOrb:Show()
            manaOrb:Show()
            lastHP, lastHPMax, lastMP, lastMPMax = -1, -1, -1, -1
            UpdateHealth()
            UpdatePower()
        else
            healthOrb:Hide()
            manaOrb:Hide()
            StopGlowPulse()
        end
    end

    DFUI:NewCallbacks("Orbs", callbacks)
end)
