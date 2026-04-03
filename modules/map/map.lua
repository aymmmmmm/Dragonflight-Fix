DFUI:NewDefaults("Map", {
    enabled = {true},
    mapDarkMode = {0, "slider", {0, 1, 0.1}, nil, "外观", 1, "调整深色模式强度", nil, nil},
    mapColor = {{1, 1, 1}, "colour", nil, nil, "外观", 2, "更改地图颜色", nil, nil},
    mapSquare = {false, "checkbox", nil, nil, "地图基础", 3, "显示小地图方形设计", nil, nil},
    showSunMoon = {false, "checkbox", nil, nil, "地图基础", 4, "显示暴雪的日/月指示器", nil, nil},
    mapSize = {180, "slider", {140, 350, 1}, nil, "地图基础", 5, "调整小地图的整体大小", "Bug: 设置后移动角色(无法修复)", nil},
    mapAlpha = {1, "slider", {0.1, 1, 0.1}, nil, "地图基础", 6, "调整整个小地图的透明度", nil, nil},
    mapShadow = {true, "checkbox", nil, nil, "地图阴影", 7, "显示或隐藏小地图内的阴影", nil, nil},
    alphaShadow = {0.3, "slider", {0.1, 1, 0.1}, nil, "地图阴影", 8, "调整小地图阴影的透明度", nil, nil},
    showZoom = {true, "checkbox", nil, nil, "地图缩放", 9, "显示或隐藏小地图上的缩放按钮", nil, nil},
    scaleZoom = {0.8, "slider", {0.2, 2, 0.1}, nil, "地图缩放", 10, "调整缩放按钮的大小", nil, nil},
    alphaZoom = {1, "slider", {0.1, 1, 0.1}, nil, "地图缩放", 11, "调整缩放按钮的透明度", nil, nil},
    zoomX = {-5, "slider", {-100, 100, 1}, nil, "地图缩放", 12, "调整缩放按钮的水平位置", nil, nil},
    zoomY = {40, "slider", {-100, 100, 1}, nil, "地图缩放", 13, "调整缩放按钮的垂直位置", nil, nil},
    showTopPanel = {true, "checkbox", nil, nil, "顶部面板", 14, "显示或隐藏顶部信息面板", nil, nil},
    topPanelWidth = {180, "slider", {100, 600, 1}, nil, "顶部面板", 15, "调整顶部面板的宽度", nil, nil},
    topPanelHeight = {12, "slider", {5, 50, 1}, nil, "顶部面板", 16, "调整顶部面板的高度", nil, nil},
    topPanelFont = {"FRIZQT__.TTF", "dropdown", {
        "FRIZQT__.TTF",
        "Expressway",
        "Homespun",
        "Hooge",
        "Myriad-Pro",
        "Prototype",
        "PT-Sans-Narrow-Bold",
        "PT-Sans-Narrow-Regular",
        "RobotoMono",
        "BigNoodleTitling",
        "Continuum",
        "DieDieDie"
    }, nil, "小地图文字设置", 17, "更改小地图使用的字体", nil, nil},
    zoneTextSize = {10, "slider", {6, 30, 1}, nil, "顶部面板区域", 18, "调整区域文字的字体大小", nil, nil},
    zoneTextY = {-3, "slider", {-50, 50, 1}, nil, "顶部面板区域", 19, "调整区域文字的垂直位置", nil, nil},
    zoneTextX = {4, "slider", {-50, 50, 1}, nil, "顶部面板区域", 20, "调整区域文字的水平位置", nil, nil},
    mapTime = {true, "checkbox", nil, nil, "顶部面板时间", 21, "显示或隐藏小地图上的时间显示", nil, nil},
    timeSize = {10, "slider", {6, 30, 1}, nil, "顶部面板时间", 22, "调整时间显示的字体大小", nil, nil},
    timeY = {-3, "slider", {-50, 50, 1}, nil, "顶部面板时间", 23, "调整时间显示的垂直位置", nil, nil},
    timeX = {-4, "slider", {-50, 50, 1}, nil, "顶部面板时间", 24, "调整时间显示的水平位置", nil, nil},
    timeFormat12h = {false, "checkbox", nil, nil, "顶部面板时间", 25, "使用12小时制AM/PM格式代替24小时制", nil, nil},
    textColor = {false, "checkbox", nil, nil, "扩展 PizzaWorldBuffs", 26, "为PizzaWorldBuffs联盟/部落文字着色", "BUG: 斜杠命令尚未实现 - 即将修复", nil},
})

DFUI:NewMod("Map", 1, function()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        -- setup
        local Setup = {
            texpath = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\minimap\\",

            minimapBorder = nil,
            minimapShadow = nil,
            topPanel = nil,
            bgTexture = nil,
            timeFrame = nil,
            timeText = nil,
            updateTimer = nil,
            mailIcon = nil,
            questframe = nil,
        }

        function Setup:HideBlizzard()
            Minimap:ClearAllPoints()
            Minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -35, -60)
            Minimap:SetFrameStrata("MEDIUM")

            MinimapCluster:EnableMouse(false)
            MinimapBorder:Hide()
            MinimapBorderTop:Hide()
            MinimapToggleButton:Hide()

            GameTimeFrame:SetScale(0.8)
            GameTimeFrame:ClearAllPoints()
            GameTimeFrame:SetPoint("BOTTOMLEFT", Minimap, "TOPRIGHT", -10, -30)
            KillFrame(MinimapShopFrame)
        end

        function Setup:Minimap()
            self.minimapBorder = Minimap:CreateTexture("MinimapBorder", "OVERLAY")
            self.minimapBorder:SetTexture(self.texpath .. "uiminimapborder.tga")

            self.minimapShadow = Minimap:CreateTexture("MinimapShadow", "BORDER")
            self.minimapShadow:SetTexture(self.texpath .. "uiminimapshadow.tga")

            Minimap:EnableMouseWheel(true)
            Minimap:SetScript("OnMouseWheel", function()
                if arg1 > 0 then
                    MinimapZoomIn:Click()
                elseif arg1 < 0 then
                    MinimapZoomOut:Click()
                end
            end)
        end

        function Setup:TopPanel()
            self.topPanel = CreateFrame("Frame", "MinimapTopPanel", Minimap)
            self.topPanel:SetWidth(200)
            self.topPanel:SetHeight(13)
            self.topPanel:SetPoint("BOTTOM", Minimap, "TOP", 0, 30)

            self.bgTexture = self.topPanel:CreateTexture(nil, "BACKGROUND")
            self.bgTexture:SetTexture(self.texpath .. "uiminimap_toppanel.tga")
            self.bgTexture:SetPoint("TOPLEFT", self.topPanel, "TOPLEFT", 0, 0)
            self.bgTexture:SetPoint("BOTTOMRIGHT", self.topPanel, "BOTTOMRIGHT", 5, -20)

            MinimapZoneTextButton:ClearAllPoints()
            MinimapZoneTextButton:SetParent(self.topPanel)
            MinimapZoneTextButton:SetPoint("LEFT", self.topPanel, "LEFT", 4, -2)
            MinimapZoneText:SetJustifyH("LEFT")
            MinimapZoneText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")

            self.timeFrame = CreateFrame("Frame", "MinimapTimeFrame", self.topPanel)
            self.timeFrame:SetWidth(40)
            self.timeFrame:SetHeight(20)
            self.timeFrame:SetPoint("RIGHT", self.topPanel, "RIGHT", -4, -2)
            self.timeFrame:EnableMouse(true)

            self.timeText = self.timeFrame:CreateFontString("MinimapTimeText", "OVERLAY", "GameFontNormal")
            self.timeText:SetPoint("CENTER", self.timeFrame, "CENTER", 0, 0)
            self.timeText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            self.timeText:SetTextColor(1, 1, 1, 1)

            self.updateTimer = CreateFrame("Frame")
            self.updateTimer:SetScript("OnUpdate", function()
                if (this.tick or 0) > GetTime() then
                    return
                end
                this.tick = GetTime() + 5

                local use12h = DFUI:GetTempDB('Map', 'timeFormat12h')
                local localTime = use12h and date('%I:%M %p') or date('%H:%M')
                self.timeText:SetText(localTime)
                DFUI.activeScripts['MapTimeScript'] = true
            end)

            self.timeFrame:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
                local hour, minute = GetGameTime()
                local use12h = DFUI:GetTempDB('Map', 'timeFormat12h')
                local localTime = use12h and date('%I:%M %p') or date('%H:%M')
                local serverTime = format('%d:%02d', hour, minute)
                GameTooltip:AddLine('Time')
                GameTooltip:AddLine('Local: ' .. localTime, 1, 1, 1)
                GameTooltip:AddLine('Server: ' .. serverTime, 1, 1, 1)
                GameTooltip:Show()
            end)

            self.timeFrame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            DFUI.topPanel = self.topPanel
        end

        function Setup:ZoomButtons()
            MinimapZoomIn:ClearAllPoints()
            MinimapZoomIn:SetParent(Minimap)
            MinimapZoomIn:SetPoint("TOPLEFT", Minimap, "BOTTOMRIGHT", -5, 40)
            MinimapZoomIn:SetScale(0.9)

            MinimapZoomIn:SetNormalTexture(self.texpath.. "ZoomIn32.tga")
            MinimapZoomIn:SetDisabledTexture(self.texpath.. "ZoomIn32-disabled.tga")
            MinimapZoomIn:SetHighlightTexture(self.texpath.. "ZoomIn32-over.tga")
            MinimapZoomIn:SetPushedTexture(self.texpath.. "ZoomIn32-push.tga")

            MinimapZoomOut:ClearAllPoints()
            MinimapZoomOut:SetParent(Minimap)
            MinimapZoomOut:SetPoint("TOPRIGHT", MinimapZoomIn, "BOTTOMLEFT", 0, 0)
            MinimapZoomOut:SetScale(0.9)

            MinimapZoomOut:SetNormalTexture(self.texpath.. "ZoomOut32.tga")
            MinimapZoomOut:SetDisabledTexture(self.texpath.. "ZoomOut32-disabled.tga")
            MinimapZoomOut:SetHighlightTexture(self.texpath.. "ZoomOut32-over.tga")
            MinimapZoomOut:SetPushedTexture(self.texpath.. "ZoomOut32-push.tga")
        end

        function Setup:Mail()
            MiniMapMailFrame:ClearAllPoints()
            MiniMapMailFrame:SetPoint("TOPLEFT", self.topPanel, "BOTTOMLEFT", -2, -1)
            MiniMapMailIcon:SetTexture(self.texpath .. "mail.tga")
            MiniMapMailIcon:SetWidth(32)
            MiniMapMailIcon:SetHeight(32)
            MiniMapMailBorder:Hide()

            self.mailIcon = MiniMapMailIcon
        end

        function Setup:Buffs()
            BuffButton0:ClearAllPoints()
            BuffButton0:SetPoint("TOPRIGHT", Setup.topPanel, "TOPLEFT", -50, 0)

            BuffButton8:ClearAllPoints()
            BuffButton8:SetPoint("TOPRIGHT", Setup.topPanel, "TOPLEFT", -50, -50)

            TempEnchant1:ClearAllPoints()
            TempEnchant1:SetPoint("TOPRIGHT", Setup.topPanel, "TOPLEFT", -50, -100)

            BuffButton16:ClearAllPoints()
            BuffButton16:SetPoint("TOPRIGHT", Setup.topPanel, "TOPLEFT", -50, -150)

	    BuffButton32:ClearAllPoints()
            BuffButton32:SetPoint("TOPRIGHT", Setup.topPanel, "TOPLEFT", -50, -200)
        end

        function Setup:Tracker()
            MiniMapTrackingFrame:ClearAllPoints()
            MiniMapTrackingFrame:SetPoint("TOPRIGHT", self.topPanel, "TOPLEFT", -15, 0)
            MiniMapTrackingFrame:SetScale(0.6)
            MiniMapTrackingBorder:Hide()
            MiniMapTrackingFrame:Hide()
            MiniMapTrackingFrame.Show = function() end
        end

        function Setup:Durability()
            DurabilityFrame:ClearAllPoints()
            DurabilityFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", 15, 15)
            DurabilityFrame.SetPoint = function() return end
            DurabilityFrame:SetScale(0.7)
        end

        function Setup:Questlog()
            self.questframe = CreateFrame("Frame", "DFUI_questframe", UIParent)
            self.questframe:SetPoint("LEFT", Minimap, -150, -130)
            self.questframe:SetWidth(170)
            self.questframe:SetHeight(5)

            QuestWatchFrame:SetParent(self.questframe)
            QuestWatchFrame:SetAllPoints(self.questframe)
            QuestWatchFrame:SetFrameLevel(1)
            QuestWatchFrame.SetPoint = function() end

            DFUI.questframe = self.questframe
        end

        function Setup:LFT()
            LFTMinimapButton:Hide()
            LFTMinimapButton:ClearAllPoints()
            LFTMinimapButton:SetParent(Minimap)
            LFTMinimapButton:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 45, 20)
            if LFT_OnQueueEnter and LFT_OnQueueLeave then
                hooksecurefunc("LFT_OnQueueEnter", function()
                    LFTMinimapButton:Show()
                end)
                hooksecurefunc("LFT_OnQueueLeave", function()
                    LFTMinimapButton:Hide()
                end)
            end
        end

        function Setup:EBC()
            if _G.EBC_Minimap then
                _G.EBC_Minimap:Hide()
                _G.EBC_Minimap.Show = function() end

                self.ebcMinimap = _G.EBC_Minimap
            end
        end

        local PWBInit
        function Setup:PizzaWorldBuffs()
            local currentColorMode = true

            function PWBInit(color)
                currentColorMode = color and true or false

                -- single check should be good enough
                local PWB_Panel = _G["DFUI_PWB_Panel"]
                if not PWB_Panel and PizzaWorldBuffs then
                    PWB_Panel = CreateFrame("Frame", "DFUI_PWB_Panel", UIParent)
                    PWB_Panel:SetFrameStrata("MEDIUM")
                    PWB_Panel:SetPoint("TOP", Minimap, "BOTTOM", -0, -45)
                    PWB_Panel:SetWidth(110)
                    PWB_Panel:SetHeight(160)

                    PWB_Panel.bg = PWB_Panel:CreateTexture(nil, "BACKGROUND")
                    PWB_Panel.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
                    PWB_Panel.bg:SetAllPoints()
                    PWB_Panel.bg:SetGradientAlpha("VERTICAL", 0.1, 0.1, 0.1, 0, 0.1, 0.1, 0.1, 0.7)
                    DFUI.PWB_Panel = PWB_Panel
                end

                -- hook
                HookAddonOrVariable("PizzaWorldBuffs", function()
                    local CONTROL = {
                        anchor_point = "TOP",
                        anchor_parent = PWB_Panel,
                        anchor_to = "TOP",
                        x_offset = -0,
                        y_offset = -10,

                        font_path = "Fonts\\FRIZQT__.TTF",
                        font_flags = "OUTLINE",
                        font_custom = 13,
                        font_size = 10,

                        frame_width = 200,
                        frame_height = 20,

                        custom_text  = color and "|cffff9999Horde"    or "|cffddddddHorde",
                        custom_text2 = color and "|cff99ccffAlliance" or "|cffddddddAlliance",
                        custom_text3 = "",

                        line_spacing = 0,

                        color_prefix = "|cffffcc00",
                        color_suffix = "|cffeeeeee",
                        color_header = "|cffeeeeee"
                    }

                    local function getCustomText()
                        if currentColorMode then
                            return "|cffff9999Horde", "|cff99ccffAlliance"
                        else
                            return "|cffddddddHorde", "|cffddddddAlliance"
                        end
                    end

                    local PWB_txt1 = _G["DFUICustomBuffText"]
                    if not PWB_txt1 then
                        PWB_txt1 = CreateFrame("Frame", "DFUICustomBuffText", PizzaWorldBuffs.frame)
                        PWB_txt1:SetWidth(CONTROL.frame_width)
                        PWB_txt1:SetHeight(CONTROL.frame_height)
                        PWB_txt1.text = PWB_txt1:CreateFontString(nil, "MEDIUM", "GameFontWhite")
                        PWB_txt1.text:SetPoint("BOTTOM", 0, 0)
                    end
                    -- PWB_txt1.text:SetFont(CONTROL.font_path, CONTROL.font_custom, CONTROL.font_flags)
                    -- PWB_txt1.text:SetText(CONTROL.custom_text)

                    local PWB_txt2 = _G["DFUICustomBuffText2"]
                    if not PWB_txt2 then
                        PWB_txt2 = CreateFrame("Frame", "DFUICustomBuffText2", PizzaWorldBuffs.frame)
                        PWB_txt2:SetWidth(CONTROL.frame_width)
                        PWB_txt2:SetHeight(CONTROL.frame_height)
                        PWB_txt2.text = PWB_txt2:CreateFontString(nil, "MEDIUM", "GameFontWhite")
                        PWB_txt2.text:SetPoint("BOTTOM", 0, 0)
                    end
                    -- PWB_txt2.text:SetFont(CONTROL.font_path, CONTROL.font_custom, CONTROL.font_flags)
                    -- PWB_txt2.text:SetText(CONTROL.custom_text2)

                    local PWB_txt3 = _G["DFUICustomBuffText3"]
                    if not PWB_txt3 then
                        PWB_txt3 = CreateFrame("Frame", "DFUICustomBuffText3", PizzaWorldBuffs.frame)
                        PWB_txt3:SetWidth(CONTROL.frame_width)
                        PWB_txt3:SetHeight(CONTROL.frame_height)
                        PWB_txt3.text = PWB_txt3:CreateFontString(nil, "MEDIUM", "GameFontWhite")
                        PWB_txt3.text:SetPoint(CONTROL.anchor_point, 0, 0)
                    end
                    -- PWB_txt3.text:SetFont(CONTROL.font_path, CONTROL.font_custom, CONTROL.font_flags)
                    -- PWB_txt3.text:SetText(CONTROL.custom_text3)

                    -- update
                    local hordeText, allianceText = getCustomText()
                    PWB_txt1.text:SetFont(CONTROL.font_path, CONTROL.font_custom, CONTROL.font_flags)
                    PWB_txt1.text:SetText(hordeText)
                    PWB_txt2.text:SetFont(CONTROL.font_path, CONTROL.font_custom, CONTROL.font_flags)
                    PWB_txt2.text:SetText(allianceText)
                    PWB_txt3.text:SetFont(CONTROL.font_path, CONTROL.font_custom, CONTROL.font_flags)
                    PWB_txt3.text:SetText("") -- hack to give us a free space

                    if not PizzaWorldBuffs.frame._dfui_update_hooked then
                        local originalUpdateFrames = PizzaWorldBuffs.frame.updateFrames
                        PizzaWorldBuffs.frame.updateFrames = function()
                            originalUpdateFrames()

                            local yOffset = 0
                            local frameCount = 0
                            local headerFound = false

                            PizzaWorldBuffs.frame:SetParent(PWB_Panel)
                            PizzaWorldBuffs.frame:ClearAllPoints()
                            PizzaWorldBuffs.frame:SetPoint("TOP", PWB_Panel, "TOP", 0, 0)

                            for i, frame in ipairs(PizzaWorldBuffs.frames) do
                                if frame.frame and frame.frame.text and frame.frame:IsShown() then
                                    if frame.name == "PizzaWorldBuffsHeader" then
                                        headerFound = true

                                        frame.frame:ClearAllPoints()
                                        frame.frame:SetPoint(CONTROL.anchor_point, CONTROL.anchor_parent, CONTROL.anchor_to, CONTROL.x_offset, CONTROL.y_offset + yOffset)
                                        yOffset = yOffset - frame.frame.text:GetHeight() - CONTROL.line_spacing

                                        PWB_txt1:ClearAllPoints()
                                        PWB_txt1:SetPoint(CONTROL.anchor_point, CONTROL.anchor_parent, CONTROL.anchor_to, CONTROL.x_offset, CONTROL.y_offset + yOffset)
                                        PWB_txt1:Show()
                                        yOffset = yOffset - CONTROL.frame_height - CONTROL.line_spacing
                                    else
                                        frameCount = frameCount + 1

                                        if frameCount == 3 then
                                            PWB_txt2:ClearAllPoints()
                                            PWB_txt2:SetPoint(CONTROL.anchor_point, CONTROL.anchor_parent, CONTROL.anchor_to, CONTROL.x_offset, CONTROL.y_offset + yOffset)
                                            PWB_txt2:Show()
                                            yOffset = yOffset - CONTROL.frame_height - CONTROL.line_spacing
                                        end

                                        if frameCount == 5 then
                                            PWB_txt3:ClearAllPoints()
                                            PWB_txt3:SetPoint(CONTROL.anchor_point, CONTROL.anchor_parent, CONTROL.anchor_to, CONTROL.x_offset, CONTROL.y_offset + yOffset)
                                            PWB_txt3:Show()
                                            yOffset = yOffset - CONTROL.frame_height - CONTROL.line_spacing
                                        end

                                        frame.frame:ClearAllPoints()
                                        frame.frame:SetPoint(CONTROL.anchor_point, CONTROL.anchor_parent, CONTROL.anchor_to, CONTROL.x_offset, CONTROL.y_offset + yOffset)
                                        yOffset = yOffset - frame.frame.text:GetHeight() - CONTROL.line_spacing
                                    end

                                    local text = frame.frame.text:GetText()
                                    if text then
                                        frame.frame.text:SetFont(CONTROL.font_path, CONTROL.font_size, CONTROL.font_flags)

                                        text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
                                        text = string.gsub(text, "|r", "")

                                        if frame.name == "PizzaWorldBuffsHeader" then
                                            text = CONTROL.color_header .. text
                                            frame.frame.text:SetText(text)
                                        else
                                            local colonPos = string.find(text, ":")
                                            if colonPos then
                                                local before = string.sub(text, 1, colonPos-1)
                                                local after = string.sub(text, colonPos)
                                                text = CONTROL.color_prefix .. before .. CONTROL.color_suffix .. after
                                                frame.frame.text:SetText(text)
                                            end
                                        end
                                    end
                                end
                            end
                            if not headerFound then
                                PWB_txt1:Hide()
                                PWB_txt2:Hide()
                                PWB_txt3:Hide()
                            end

                            -- update custom frame
                            local hordeText2, allianceText2 = getCustomText()
                            PWB_txt1.text:SetText(hordeText2)
                            PWB_txt2.text:SetText(allianceText2)
                        end
                        PizzaWorldBuffs.frame._dfui_update_hooked = true
                    end

                    -- force update to apply new color
                    if PizzaWorldBuffs.frame.updateFrames and PizzaWorldBuffs.frames then
                        PizzaWorldBuffs.frame:updateFrames()
                    end
                end)

                -- minimap toggle
                local toggleButton
                if PizzaWorldBuffs then
                    toggleButton = CreateFrame("Button", "MinimapButtonCollectorToggle", UIParent)
                    toggleButton:SetWidth(16)
                    toggleButton:SetHeight(16)
                    toggleButton:SetPoint("TOP", Minimap, "BOTTOM", -1, -15)
                    toggleButton:SetNormalTexture(self.texpath.. "dfui_collector_toggle.tga")
                    toggleButton:GetNormalTexture():SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
                    toggleButton:SetHighlightTexture(self.texpath.. "dfui_collector_toggle.tga")
                    toggleButton:GetHighlightTexture():SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)

                    local panelVisible = DFUI:GetTempValue("pwb", "visible")
                    if panelVisible == false then
                        PWB_Panel:Hide()
                    else
                        PWB_Panel:Show()
                    end

                    toggleButton:SetScript("OnClick", function()
                        if PWB_Panel:IsVisible() then
                            UIFrameFadeOut(PWB_Panel, 0.3, 1, 0)
                            PWB_Panel.fadeInfo.finishedFunc = PWB_Panel.Hide
                            PWB_Panel.fadeInfo.finishedArg1 = PWB_Panel
                            DFUI:SetTempDBNoCallback("pwb", "visible", false)
                        else
                            PWB_Panel:SetAlpha(0)
                            PWB_Panel:Show()
                            UIFrameFadeIn(PWB_Panel, 0.3, 0, 1)
                            DFUI:SetTempDBNoCallback("pwb", "visible", true)
                        end
                    end)

                    DFUI.PWBtoggleButton = toggleButton
                end
            end

            PWBInit(true)
        end

        -- init setup
        function Setup:Run()
            Setup:HideBlizzard()
            Setup:Minimap()
            Setup:TopPanel()
            Setup:ZoomButtons()
            Setup:Mail()
            Setup:Buffs()
            Setup:Tracker()
            Setup:Durability()
            Setup:Questlog()
            Setup:LFT()
            Setup:EBC()
            Setup:PizzaWorldBuffs()
        end

        Setup:Run()

        -- callbacks
        local callbacks = {}

        local function CalculateTexOffset(size)
            local minSize, maxSize = 140, 350
            local minOffset, maxOffset = 10, 26

            local offset = minOffset + (size - minSize) * (maxOffset - minOffset) / (maxSize - minSize)
            return offset
        end

        callbacks.mapDarkMode = function(value)
            local intensity = DFUI:GetTempDB("Map", "mapDarkMode")
            local mapColor = DFUI:GetTempDB("Map", "mapColor")
            local r, g, b = mapColor[1] * (1 - intensity), mapColor[2] * (1 - intensity), mapColor[3] * (1 - intensity)
            local color = value and {r, g, b} or {1, 1, 1}

            Setup.minimapBorder:SetVertexColor(color[1], color[2], color[3])

            local zoomInNormal = MinimapZoomIn:GetNormalTexture()
            local zoomOutNormal = MinimapZoomOut:GetNormalTexture()
            zoomInNormal:SetVertexColor(color[1], color[2], color[3])
            zoomOutNormal:SetVertexColor(color[1], color[2], color[3])

            local zoomInDisabled = MinimapZoomIn:GetDisabledTexture()
            local zoomOutDisabled = MinimapZoomOut:GetDisabledTexture()
            zoomInDisabled:SetVertexColor(color[1], color[2], color[3])
            zoomOutDisabled:SetVertexColor(color[1], color[2], color[3])

            if DFUI.PWBtoggleButton then
                local pwbNormalTex = DFUI.PWBtoggleButton:GetNormalTexture()
                local pwbHighlightTex = DFUI.PWBtoggleButton:GetHighlightTexture()
                if pwbNormalTex then pwbNormalTex:SetVertexColor(color[1], color[2], color[3]) end
                if pwbHighlightTex then pwbHighlightTex:SetVertexColor(color[1], color[2], color[3]) end
            end
        end

        callbacks.mapColor = function(value)
            local intensity = DFUI:GetTempDB("Map", "mapDarkMode")
            local r, g, b = value[1] * (1 - intensity), value[2] * (1 - intensity), value[3] * (1 - intensity)

            Setup.minimapBorder:SetVertexColor(r, g, b)

            local zoomInNormal = MinimapZoomIn:GetNormalTexture()
            local zoomOutNormal = MinimapZoomOut:GetNormalTexture()
            zoomInNormal:SetVertexColor(r, g, b)
            zoomOutNormal:SetVertexColor(r, g, b)

            local zoomInDisabled = MinimapZoomIn:GetDisabledTexture()
            local zoomOutDisabled = MinimapZoomOut:GetDisabledTexture()
            zoomInDisabled:SetVertexColor(r, g, b)
            zoomOutDisabled:SetVertexColor(r, g, b)

            if DFUI.PWBtoggleButton then
                local pwbNormalTex = DFUI.PWBtoggleButton:GetNormalTexture()
                local pwbHighlightTex = DFUI.PWBtoggleButton:GetHighlightTexture()
                if pwbNormalTex then pwbNormalTex:SetVertexColor(r, g, b) end
                if pwbHighlightTex then pwbHighlightTex:SetVertexColor(r, g, b) end
            end
        end

        callbacks.mapSize = function(value)
            Minimap:SetHeight(value)
            Minimap:SetWidth(value)

            local offset = CalculateTexOffset(value)

            Setup.minimapBorder:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -offset, offset)
            Setup.minimapBorder:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", offset, -offset)

            Setup.minimapShadow:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -offset, offset)
            Setup.minimapShadow:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", offset, -offset)
        end

        callbacks.mapShadow = function(value)
            if value then
                Setup.minimapShadow:Show()
            else
                Setup.minimapShadow:Hide()
            end
        end

        callbacks.alphaShadow = function(value)
            Setup.minimapShadow:SetAlpha(value)
        end

        callbacks.showZoom = function(value)
            if value then
                MinimapZoomIn:Show()
                MinimapZoomOut:Show()
            else
                MinimapZoomIn:Hide()
                MinimapZoomOut:Hide()
            end
        end

        callbacks.scaleZoom = function(value)
            MinimapZoomIn:SetScale(value)
            MinimapZoomOut:SetScale(value)
        end

        callbacks.alphaZoom = function(value)
            MinimapZoomIn:SetAlpha(value)
            MinimapZoomOut:SetAlpha(value)
        end

        callbacks.mapAlpha = function(value)
            Minimap:SetAlpha(value)
        end

        callbacks.showTopPanel = function(value)
            if value then
                Setup.topPanel:Show()
            else
                Setup.topPanel:Hide()
            end
        end

        callbacks.topPanelWidth = function(value)
            Setup.topPanel:SetWidth(value)
        end

        callbacks.topPanelHeight = function(value)
            Setup.topPanel:SetHeight(value)
        end

        callbacks.zoneTextSize = function(value)
            local fontPath
            local fontValue = DFUI:GetTempDB("Map", "topPanelFont")
            if fontValue == "Expressway" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Expressway.ttf"
            elseif fontValue == "Homespun" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Homespun.ttf"
            elseif fontValue == "Hooge" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Hooge.ttf"
            elseif fontValue == "Myriad-Pro" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Myriad-Pro.ttf"
            elseif fontValue == "Prototype" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Prototype.ttf"
            elseif fontValue == "PT-Sans-Narrow-Bold" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\PT-Sans-Narrow-Bold.ttf"
            elseif fontValue == "PT-Sans-Narrow-Regular" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\PT-Sans-Narrow-Regular.ttf"
            elseif fontValue == "RobotoMono" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\RobotoMono.ttf"
            elseif fontValue == "BigNoodleTitling" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\BigNoodleTitling.ttf"
            elseif fontValue == "Continuum" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Continuum.ttf"
            elseif fontValue == "DieDieDie" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\DieDieDie.ttf"
            else
                fontPath = "Fonts\\FRIZQT__.TTF"
            end
            MinimapZoneText:SetFont(fontPath, value, "")
        end

        callbacks.zoneTextY = function(value)
            MinimapZoneTextButton:ClearAllPoints()
            MinimapZoneTextButton:SetPoint("LEFT", Setup.topPanel, "LEFT", DFUI:GetTempDB("Map", "zoneTextX"), value)
        end

        callbacks.zoneTextX = function(value)
            MinimapZoneTextButton:ClearAllPoints()
            MinimapZoneTextButton:SetPoint("LEFT", Setup.topPanel, "LEFT", value, DFUI:GetTempDB("Map", "zoneTextY"))
        end

        callbacks.timeSize = function(value)
            local fontPath
            local fontValue = DFUI:GetTempDB("Map", "topPanelFont")
            if fontValue == "Expressway" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Expressway.ttf"
            elseif fontValue == "Homespun" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Homespun.ttf"
            elseif fontValue == "Hooge" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Hooge.ttf"
            elseif fontValue == "Myriad-Pro" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Myriad-Pro.ttf"
            elseif fontValue == "Prototype" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Prototype.ttf"
            elseif fontValue == "PT-Sans-Narrow-Bold" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\PT-Sans-Narrow-Bold.ttf"
            elseif fontValue == "PT-Sans-Narrow-Regular" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\PT-Sans-Narrow-Regular.ttf"
            elseif fontValue == "RobotoMono" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\RobotoMono.ttf"
            elseif fontValue == "BigNoodleTitling" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\BigNoodleTitling.ttf"
            elseif fontValue == "Continuum" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Continuum.ttf"
            elseif fontValue == "DieDieDie" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\DieDieDie.ttf"
            else
                fontPath = "Fonts\\FRIZQT__.TTF"
            end
            Setup.timeText:SetFont(fontPath, value, "")
        end

        callbacks.timeY = function(value)
            Setup.timeText:ClearAllPoints()
            Setup.timeText:SetPoint("RIGHT", Setup.topPanel, "RIGHT", DFUI:GetTempDB("Map", "timeX"), value)
        end

        callbacks.timeX = function(value)
            Setup.timeText:ClearAllPoints()
            Setup.timeText:SetPoint("RIGHT", Setup.topPanel, "RIGHT", value, DFUI:GetTempDB("Map", "timeY"))
        end

        callbacks.mapTime = function(value)
            if value then
                Setup.timeText:Show()
            else
                Setup.timeText:Hide()
            end
        end

        callbacks.mapSquare = function(value)
            if value then
                Setup.minimapBorder:SetTexture(Setup.texpath.. "map_dragonflight_square2.tga")
                Setup.minimapShadow:SetTexture(Setup.texpath.. "map_dragonflight_square_shadow.tga")
                Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
            else
                Setup.minimapBorder:SetTexture(Setup.texpath.. "uiminimapborder.tga")
                Setup.minimapShadow:SetTexture(Setup.texpath.. "uiminimapshadow.tga")
                Minimap:SetMaskTexture("Textures\\MinimapMask")
            end
        end

        callbacks.zoomX = function(value)
            MinimapZoomIn:ClearAllPoints()
            MinimapZoomIn:SetPoint("TOPLEFT", Minimap, "BOTTOMRIGHT", value, DFUI:GetTempDB("Map", "zoomY"))
        end

        callbacks.zoomY = function(value)
            MinimapZoomIn:ClearAllPoints()
            MinimapZoomIn:SetPoint("TOPLEFT", Minimap, "BOTTOMRIGHT", DFUI:GetTempDB("Map", "zoomX"), value)
        end

        callbacks.textColor = function(value)
            PWBInit(value and true or false)
        end

        callbacks.showSunMoon = function(value)
            if value then
                GameTimeFrame:Show()
            else
                GameTimeFrame:Hide()
            end
        end

        callbacks.topPanelFont = function(value)
            local fontPath
            if value == "Expressway" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Expressway.ttf"
            elseif value == "Homespun" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Homespun.ttf"
            elseif value == "Hooge" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Hooge.ttf"
            elseif value == "Myriad-Pro" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Myriad-Pro.ttf"
            elseif value == "Prototype" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Prototype.ttf"
            elseif value == "PT-Sans-Narrow-Bold" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\PT-Sans-Narrow-Bold.ttf"
            elseif value == "PT-Sans-Narrow-Regular" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\PT-Sans-Narrow-Regular.ttf"
            elseif value == "RobotoMono" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\RobotoMono.ttf"
            elseif value == "BigNoodleTitling" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\BigNoodleTitling.ttf"
            elseif value == "Continuum" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Continuum.ttf"
            elseif value == "DieDieDie" then
                fontPath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\DieDieDie.ttf"
            else
                fontPath = "Fonts\\FRIZQT__.TTF"
            end

            MinimapZoneText:SetFont(fontPath, DFUI:GetTempDB("Map", "zoneTextSize"), "")
            Setup.timeText:SetFont(fontPath, DFUI:GetTempDB("Map", "timeSize"), "")
        end

        callbacks.timeFormat12h = function(value)
            local localTime = value and string.gsub(date('%I:%M %p'), ' ', '  ') or date('%H:%M')
            Setup.timeText:SetText(localTime)
        end

        -- execute callbacks
        DFUI:NewCallbacks("Map", callbacks)

        f:UnregisterEvent("PLAYER_ENTERING_WORLD")

        -- /track slash command: show tracking spell menu
        _G.SLASH_DFUITRACK1 = "/track"
        _G.SlashCmdList["DFUITRACK"] = function()
            local trackSpells = {}
            for tab = 1, _G.GetNumSpellTabs() do
                local _, _, offset, numSpells = _G.GetSpellTabInfo(tab)
                for i = 1, numSpells do
                    local idx = offset + i
                    local tex = _G.GetSpellTexture(idx, "spell")
                    local name = _G.GetSpellName(idx, "spell")
                    if tex and name then
                        local isTrack = false
                        if _G.string.find(name, "追踪") or _G.string.find(name, "寻找")
                            or _G.string.find(name, "感知")
                            or _G.string.find(name, "Track") or _G.string.find(name, "Find")
                            or _G.string.find(name, "Sense") then
                            isTrack = true
                        end
                        if not isTrack then
                            if _G.string.find(tex, "Tracking") or _G.string.find(tex, "Flower")
                                or _G.string.find(tex, "Earthquake") or _G.string.find(tex, "FindTreasure")
                                or _G.string.find(tex, "SenseUndead") or _G.string.find(tex, "Metamorphosis")
                                or _G.string.find(tex, "Stealth") or _G.string.find(tex, "PrayerOfHealing")
                                or _G.string.find(tex, "DarkSummoning") or _G.string.find(tex, "SummonWaterElemental")
                                or _G.string.find(tex, "SummonFelHunter") or _G.string.find(tex, "Racial_Avatar")
                                or _G.string.find(tex, "Head_Dragon") then
                                isTrack = true
                            end
                        end
                        if isTrack then
                            table.insert(trackSpells, { name = name, index = idx, texture = tex })
                        end
                    end
                end
            end
            if table.getn(trackSpells) == 0 then
                _G.DEFAULT_CHAT_FRAME:AddMessage("|cffff6666没有可用的追踪技能。|r")
                return
            end
            local menuFrame = _G["DFUI_TrackCmdMenu"] or _G.CreateFrame("Frame", "DFUI_TrackCmdMenu", _G.UIParent, "UIDropDownMenuTemplate")
            _G.UIDropDownMenu_Initialize(menuFrame, function()
                _G.UIDropDownMenu_AddButton({ text = "选择追踪", isTitle = 1, notCheckable = 1 })
                local curTex = _G.GetTrackingTexture()
                for i = 1, table.getn(trackSpells) do
                    local spell = trackSpells[i]
                    _G.UIDropDownMenu_AddButton({
                        text = spell.name,
                        icon = spell.texture,
                        value = spell.name,
                        checked = (curTex and spell.texture == curTex),
                        func = function()
                            _G.CastSpellByName(this.value)
                            _G.CloseDropDownMenus()
                        end
                    })
                end
            end, "MENU")
            _G.ToggleDropDownMenu(1, nil, menuFrame, "cursor", 0, 0)
        end
    end)

    -- ============================================================
    -- Independent tracking button (DFUI_TrackBtn)
    -- Completely separate from MiniMapTrackingFrame
    -- ============================================================
    local trackBtnFrame = _G.CreateFrame("Button", "DFUI_TrackBtn", _G.UIParent)
    trackBtnFrame:SetFrameStrata("HIGH")
    trackBtnFrame:SetWidth(24)
    trackBtnFrame:SetHeight(24)
    trackBtnFrame:SetPoint("TOPRIGHT", _G.Minimap, "TOPLEFT", -5, -5)
    trackBtnFrame:SetMovable(true)
    trackBtnFrame:EnableMouse(true)
    trackBtnFrame:RegisterForDrag("LeftButton")
    trackBtnFrame:RegisterForClicks("RightButtonUp")

    local trackIcon = trackBtnFrame:CreateTexture(nil, "ARTWORK")
    trackIcon:SetAllPoints(trackBtnFrame)
    trackIcon:SetTexture("Interface\\Minimap\\Tracking\\None")
    trackIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local trackHL = trackBtnFrame:CreateTexture(nil, "HIGHLIGHT")
    trackHL:SetAllPoints(trackBtnFrame)
    trackHL:SetTexture(1, 1, 1, 0.3)

    local trackMenuFrame = _G.CreateFrame("Frame", "DFUI_TrackBtnMenu", _G.UIParent, "UIDropDownMenuTemplate")

    -- Scan tracking spells
    local trackBtnSpells = {}
    local function ScanTrackBtn()
        trackBtnSpells = {}
        local added = {}
        for tab = 1, _G.GetNumSpellTabs() do
            local _, _, offset, numSpells = _G.GetSpellTabInfo(tab)
            for i = 1, numSpells do
                local idx = offset + i
                local tex = _G.GetSpellTexture(idx, "spell")
                local name = _G.GetSpellName(idx, "spell")
                if tex and name and not added[name] then
                    local isTrack = false
                    -- Match by spell name keywords (most reliable)
                    if _G.string.find(name, "追踪") or _G.string.find(name, "寻找")
                        or _G.string.find(name, "感知")
                        or _G.string.find(name, "Track") or _G.string.find(name, "Find")
                        or _G.string.find(name, "Sense") then
                        isTrack = true
                    end
                    -- Match by texture (fallback for edge cases)
                    if not isTrack then
                        if _G.string.find(tex, "Tracking")
                            or _G.string.find(tex, "Flower")
                            or _G.string.find(tex, "Earthquake")
                            or _G.string.find(tex, "FindTreasure")
                            or _G.string.find(tex, "SenseUndead")
                            or _G.string.find(tex, "Metamorphosis")
                            or _G.string.find(tex, "Stealth")
                            or _G.string.find(tex, "PrayerOfHealing")
                            or _G.string.find(tex, "DarkSummoning")
                            or _G.string.find(tex, "SummonWaterElemental")
                            or _G.string.find(tex, "SummonFelHunter")
                            or _G.string.find(tex, "Racial_Avatar")
                            or _G.string.find(tex, "Head_Dragon") then
                            isTrack = true
                        end
                    end
                    if isTrack then
                        added[name] = true
                        table.insert(trackBtnSpells, { name = name, texture = tex })
                    end
                end
            end
        end
    end

    -- Update icon
    local function UpdateTrackBtnIcon()
        local curTex = _G.GetTrackingTexture()
        if curTex then
            trackIcon:SetTexture(curTex)
        else
            trackIcon:SetTexture("Interface\\Minimap\\Tracking\\None")
        end
    end

    -- Events
    trackBtnFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    trackBtnFrame:RegisterEvent("SPELLS_CHANGED")
    trackBtnFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
    trackBtnFrame:SetScript("OnEvent", function()
        ScanTrackBtn()
        UpdateTrackBtnIcon()
    end)

    -- Right-click: show menu
    trackBtnFrame:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            ScanTrackBtn()
            _G.UIDropDownMenu_Initialize(trackMenuFrame, function()
                _G.UIDropDownMenu_AddButton({
                    text = "选择追踪",
                    isTitle = 1,
                    notCheckable = 1
                })
                local curTex = _G.GetTrackingTexture()
                for i = 1, table.getn(trackBtnSpells) do
                    local spell = trackBtnSpells[i]
                    _G.UIDropDownMenu_AddButton({
                        text = spell.name,
                        icon = spell.texture,
                        value = spell.name,
                        checked = (curTex and spell.texture == curTex),
                        func = function()
                            _G.CastSpellByName(this.value)
                            _G.CloseDropDownMenus()
                            UpdateTrackBtnIcon()
                        end
                    })
                end
            end, "MENU")
            _G.ToggleDropDownMenu(1, nil, trackMenuFrame, "cursor", 0, 0)
        end
    end)

    -- Draggable
    trackBtnFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    trackBtnFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    -- Tooltip
    trackBtnFrame:SetScript("OnEnter", function()
        _G.GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        _G.GameTooltip:SetText("右键: 选择追踪\n左键拖动: 移动位置")
        _G.GameTooltip:Show()
    end)
    trackBtnFrame:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
end)
