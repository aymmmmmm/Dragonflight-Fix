DFUI:NewDefaults("Ui", {
    enabled = {true},
    hideErrorMessage = {false, "checkbox", nil, nil, "界面调整", 1, "隐藏顶部UI错误消息(例如'法术尚未准备好')", nil, nil},
    lowHpWarn = {true, "checkbox", nil, nil, "界面调整", 2, "低血量时显示红色边框", nil, nil},
    lowHpThreshold = {70, "slider", {5, 95, 5}, nil, "界面调整", 3, "低血量警告的生命值阈值", nil, nil},
    cameraDistanceFactor = {3, "slider", {1, 5, 1}, nil, "界面调整", 4, "扩展最大镜头距离", nil, nil},
    showPlates = {false, "checkbox", nil, nil, "界面调整", 5, "仅在战斗中显示姓名板", nil, nil},
})

DFUI:NewMod("Ui", 5, function()
    -- locals
    local UnitHealth = UnitHealth
    local UnitHealthMax = UnitHealthMax
    local GetTime = GetTime
    local sin = math.sin

    -- (面板美化代码已迁移到 modules/panels/)

    -- optionsframe
    do
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:SetScript("OnEvent", function ()
            if not UIOptionsFrame then return end
            UIOptionsFrame:SetParent(UIParent)
            UIOptionsFrame:SetWidth(1024)
            UIOptionsFrame:SetHeight(700)
            UIOptionsFrame:SetFrameStrata("DIALOG")
            UIOptionsFrame:ClearAllPoints()
            UIOptionsFrame:SetPoint("CENTER", 0, 0)
            UIOptionsFrameTab1:SetFrameLevel(10)
            UIOptionsFrameTab2:SetFrameLevel(10)
            UIOptionsFrameDefaults:SetFrameLevel(10)
            UIOptionsFrameCancel:SetFrameLevel(10)
            UIOptionsFrameOkay:SetFrameLevel(10)
            UIOptionsFrame:SetHitRectInsets(0,0,0,50)
        end)

    end

    -- timer frame
    do
        local originalManageFramePositions = _G.UIParent_ManageFramePositions
        _G.UIParent_ManageFramePositions = function()
            originalManageFramePositions()

            if DFUI_FRAMEPOS and DFUI_FRAMEPOS['QuestTimerFrame'] then
                local pos = DFUI_FRAMEPOS['QuestTimerFrame']
                QuestTimerFrame:ClearAllPoints()
                QuestTimerFrame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', pos.x, pos.y)
            else
                QuestTimerFrame:ClearAllPoints()
                QuestTimerFrame:SetPoint('TOPRIGHT', Minimap, 'BOTTOMLEFT', -20, 40)
            end
        end

        -- QuestTimerFrame:UnregisterAllEvents()
        -- QuestTimerFrame:SetScript('OnUpdate', nil)
        QuestTimerFrame:Show()
        -- debugframe(QuestTimerFrame)
    end

    -- callbacks
    local callbacks = {}

    callbacks.hideErrorMessage = function (value)
        if value then
            UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
        else
            UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
        end
    end

    callbacks.lowHpWarn = function(value)
        if not DFUI.lowHpWarnFrame then
            local frame = CreateFrame("Frame", "DFUI_LowHpWarnFrame", UIParent)
            frame:SetFrameStrata("BACKGROUND")
            frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
            frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
            frame:Hide()

            local top = frame:CreateTexture(nil, "BACKGROUND")
            top:SetTexture("Interface\\Buttons\\WHITE8X8")
            top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            top:SetHeight(64)
            top:SetGradientAlpha("VERTICAL", 1, 0, 0, 0, 1, 0, 0, 0.7)

            local bottom = frame:CreateTexture(nil, "BACKGROUND")
            bottom:SetTexture("Interface\\Buttons\\WHITE8X8")
            bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
            bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
            bottom:SetHeight(64)
            bottom:SetGradientAlpha("VERTICAL", 1, 0, 0, 0.7, 1, 0, 0, 0)

            local left = frame:CreateTexture(nil, "BACKGROUND")
            left:SetTexture("Interface\\Buttons\\WHITE8X8")
            left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
            left:SetWidth(64)
            left:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0.7, 1, 0, 0, 0)

            local right = frame:CreateTexture(nil, "BACKGROUND")
            right:SetTexture("Interface\\Buttons\\WHITE8X8")
            right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
            right:SetWidth(64)
            right:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0, 1, 0, 0, 0.7)

            -- store
            frame.textures = {top, bottom, left, right}
            frame.pulseTime = 0
            frame.baseAlpha = 0.1

            DFUI.lowHpWarnFrame = frame

            local healthCheckFrame = CreateFrame("Frame")
            local updateFunc = function()
                if (this.tick or 0) > GetTime() then
                    DFUI.activeScripts["LowHpWarnScript"] = false
                    return
                end
                this.tick = GetTime() + 0.01

                local healthPercent = UnitHealth("player") / UnitHealthMax("player") * 100

                local threshold = DFUI:GetTempDB("Ui", "lowHpThreshold")
                if healthPercent <= threshold then
                    DFUI.lowHpWarnFrame:Show()
                    DFUI.activeScripts["LowHpWarnScript"] = true

                    -- calculate alpha
                    -- at 45% hp: alpha = 0.1, at 0% hp: alpha = 1.0
                    local warningRange = threshold * 0.9  -- start fading at 90% of threshold
                    local alphaMultiplier = (warningRange - healthPercent) / warningRange
                    local baseAlpha = 0.1 + (0.9 * alphaMultiplier)

                    -- calculate pulse speed
                    -- lower health = faster pulsing
                    local pulseSpeed = 1 + (7 * alphaMultiplier)

                    -- update pulse time
                    DFUI.lowHpWarnFrame.pulseTime = DFUI.lowHpWarnFrame.pulseTime + (arg1 * pulseSpeed)

                    -- calculate pulse factor using sine wave
                    local pulseFactor = (sin(DFUI.lowHpWarnFrame.pulseTime) + 1) / 2 -- normalized to 0-1

                    -- apply pulsing to alpha
                    local finalAlpha = baseAlpha * (0.3 + 0.7 * pulseFactor) -- pulse between 30% and 100% of base alpha

                    -- update
                    for i = 1, 4 do
                        local texture = DFUI.lowHpWarnFrame.textures[i]
                        if i == 1 then
                            texture:SetGradientAlpha("VERTICAL", 1, 0, 0, 0, 1, 0, 0, 0.7 * finalAlpha)
                        elseif i == 2 then
                            texture:SetGradientAlpha("VERTICAL", 1, 0, 0, 0.7 * finalAlpha, 1, 0, 0, 0)
                        elseif i == 3 then
                            texture:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0.7 * finalAlpha, 1, 0, 0, 0)
                        else
                            texture:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0, 1, 0, 0, 0.7 * finalAlpha)
                        end
                    end
                else
                    DFUI.lowHpWarnFrame:Hide()
                    -- reset pulse time
                    DFUI.lowHpWarnFrame.pulseTime = 0
                    DFUI.activeScripts["LowHpWarnScript"] = false
                end
            end

            healthCheckFrame:SetScript("OnUpdate", updateFunc)
            healthCheckFrame.updateFunc = updateFunc

            DFUI.healthCheckFrame = healthCheckFrame
        end

        if value then
            DFUI.healthCheckFrame:SetScript("OnUpdate", DFUI.healthCheckFrame.updateFunc)
        else
            DFUI.lowHpWarnFrame:Hide()
            DFUI.healthCheckFrame:SetScript("OnUpdate", nil)
            DFUI.activeScripts["LowHpWarnScript"] = false
        end
    end

    callbacks.lowHpThreshold = function(value)
        if DFUI.lowHpWarnFrame and DFUI.lowHpWarnFrame:IsShown() then
            DFUI.healthCheckFrame.tick = 0
        end
    end

    callbacks.cameraDistanceFactor = function(value)
        SetCVar("CameraDistanceMaxFactor", value)
    end

    callbacks.showPlates = function(value)
        if not DFUI.nameplateFrame then
            local f = CreateFrame("Frame")
            f:SetScript("OnEvent", function()
                if event == "PLAYER_ENTERING_WORLD" then
                    this:UnregisterEvent("PLAYER_ENTERING_WORLD")
                    HideNameplates()
                elseif event == "PLAYER_REGEN_DISABLED" then
                    ShowNameplates()
                else
                    HideNameplates()
                end
            end)
            DFUI.nameplateFrame = f
        end

        if value then
            DFUI.nameplateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
            DFUI.nameplateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
            DFUI.nameplateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            HideNameplates()
        else
            DFUI.nameplateFrame:UnregisterAllEvents()
        end
    end

    DFUI.activeScripts["LowHpWarnScript"] = false

    -- execute  callbacks
    DFUI:NewCallbacks("Ui", callbacks)
end)
