DFUI:NewDefaults("Bars", {
    enabled = {true},
    movable = {true},
    barsDarkMode = {0, "slider", {0, 1, 0.1}, nil, "外观", 1, "调整深色模式强度", nil, nil},
    barsColor = {{1, 1, 1}, "colour", nil, nil, "外观", 2, "更改动作条颜色", nil, nil},
    mainBarBG = {true, "checkbox", nil, nil, "主动作条", 3, "显示或隐藏主动作条背景", nil, nil},
    mainBarScale = {1, "slider", {0.5, 2, 0.1}, nil, "主动作条", 4, "调整主动作条的缩放", nil, nil},
    mainBarSpacing = {6, "slider", {0, 20, 1}, nil, "主动作条", 5, "调整主动作条按钮间距", nil, nil},
    mainBarAlpha = {1, "slider", {0.1, 1, 0.1}, nil, "主动作条", 6, "调整主动作条的透明度", nil, nil},
    mainBarGrid = {1, "slider", {1, 6, 1}, nil, "主动作条", 7, "更改主动作条的网格布局", nil, nil},
    highlightColor = {{1, 0.82, 0}, "colour", nil, nil, "主动作条", 8, "更改动作按钮高亮颜色", nil, nil},
    multiBarOneShow = {false, "checkbox", nil, nil, "多功能条 1", 9, "显示或隐藏左下动作条", nil, nil},
    multiBarOneScale = {1, "slider", {0.2, 2, 0.1}, nil, "多功能条 1", 10, "调整左下动作条的缩放", nil, nil},
    multiBarOneSpacing = {6, "slider", {0, 20, 1}, nil, "多功能条 1", 11, "调整左下动作条按钮间距", nil, nil},
    multiBarOneAlpha = {1, "slider", {0.1, 1, 0.1}, nil, "多功能条 1", 12, "调整左下动作条的透明度", nil, nil},
    multiBarOneGrid = {1, "slider", {1, 6, 1}, nil, "多功能条 1", 13, "更改左下动作条的网格布局", nil, nil},
    multiBarTwoShow = {false, "checkbox", nil, nil, "多功能条 2", 14, "显示或隐藏右下动作条", nil, nil},
    multiBarTwoScale = {1, "slider", {0.2, 2, 0.1}, nil, "多功能条 2", 15, "调整右下动作条的缩放", nil, nil},
    multiBarTwoSpacing = {6, "slider", {0, 20, 1}, nil, "多功能条 2", 16, "调整右下动作条按钮间距", nil, nil},
    multiBarTwoAlpha = {1, "slider", {0.1, 1, 0.1}, nil, "多功能条 2", 17, "调整右下动作条的透明度", nil, nil},
    multiBarTwoGrid = {1, "slider", {1, 6, 1}, nil, "多功能条 2", 18, "更改右下动作条的网格布局", nil, nil},
    multiBarThreeShow = {false, "checkbox", nil, nil, "多功能条 3", 19, "显示或隐藏左侧动作条", nil, nil},
    multiBarThreeScale = {0.8, "slider", {0.2, 2, 0.1}, nil, "多功能条 3", 20, "调整左侧动作条的缩放", nil, nil},
    multiBarThreeSpacing = {6, "slider", {0, 20, 1}, nil, "多功能条 3", 21, "调整左侧动作条按钮间距", nil, nil},
    multiBarThreeAlpha = {1, "slider", {0.1, 1, 0.1}, nil, "多功能条 3", 22, "调整左侧动作条的透明度", nil, nil},
    multiBarThreeGrid = {6, "slider", {1, 6, 1}, nil, "多功能条 3", 23, "更改左侧动作条的网格布局", nil, nil},
    multiBarFourShow = {true, "checkbox", nil, nil, "多功能条 4", 24, "显示或隐藏右侧动作条", nil, nil},
    multiBarFourScale = {0.8, "slider", {0.2, 2, 0.1}, nil, "多功能条 4", 25, "调整右侧动作条的缩放", nil, nil},
    multiBarFourSpacing = {6, "slider", {0, 20, 1}, nil, "多功能条 4", 26, "调整右侧动作条按钮间距", nil, nil},
    multiBarFourAlpha = {1, "slider", {0.1, 1, 0.1}, nil, "多功能条 4", 27, "调整右侧动作条的透明度", nil, nil},
    multiBarFourGrid = {6, "slider", {1, 6, 1}, nil, "多功能条 4", 28, "更改右侧动作条的网格布局", nil, nil},
    showGryphoon = {true, "checkbox", nil, nil, "主动作条装饰", 29, "显示或隐藏狮鹫/双足飞龙装饰", nil, nil},
    altGryphoon = {false, "checkbox", nil, nil, "主动作条装饰", 30, "使用备选狮鹫/双足飞龙材质", nil, nil},
    flipGryphoon = {false, "checkbox", nil, nil, "主动作条装饰", 31, "翻转狮鹫/双足飞龙材质", nil, nil},
    gryphoonScale = {1, "slider", {0.2, 2, 0.1}, nil, "主动作条装饰", 32, "调整狮鹫/双足飞龙装饰的大小", nil, nil},
    gryphoonX = {-48, "slider", {-200, 200, 1}, nil, "主动作条装饰", 33, "调整狮鹫/双足飞龙装饰的水平位置", nil, nil},
    gryphoonY = {10, "slider", {-200, 200, 1}, nil, "主动作条装饰", 34, "调整狮鹫/双足飞龙装饰的垂直位置", nil, nil},
    gryphoonAlpha = {1, "slider", {0.1, 1, 0.1}, nil, "主动作条装饰", 35, "调整狮鹫/双足飞龙装饰的透明度", nil, nil},
    pagingShow = {true, "checkbox", nil, nil, "主动作条翻页", 36, "显示或隐藏动作条翻页按钮", nil, nil},
    pagingSwap = {true, "checkbox", nil, nil, "主动作条翻页", 37, "交换翻页按钮的锚点", nil, nil},
    pagingX = {15, "slider", {0, 150, 1}, nil, "主动作条翻页", 38, "调整翻页按钮的水平位置", nil, nil},
    pagingScale = {0.9, "slider", {0.7, 1.8, 0.1}, nil, "主动作条翻页", 39, "调整翻页按钮的缩放", nil, nil},
    hotkeyFont = {"FRIZQT__.TTF", "dropdown", {"FRIZQT__.TTF", "Expressway", "Homespun", "Hooge", "Myriad-Pro", "Prototype", "PT-Sans-Narrow-Bold", "PT-Sans-Narrow-Regular", "RobotoMono", "BigNoodleTitling", "Continuum", "DieDieDie"}, nil, "文字设置", 40, "更改快捷键和宏的字体", nil, nil},
    hotkeyColour = {{1, 0.82, 0}, "colour", nil, nil, "文字设置", 41, "更改动作按钮上快捷键文字的颜色", nil, nil},
    hotkeyShow = {true, "checkbox", nil, nil, "文字设置", 42, "显示或隐藏动作按钮上的快捷键文字", nil, nil},
    hotkeyScale = {1.4, "slider", {0.5, 2, 0.1}, nil, "文字设置", 43, "调整动作按钮上快捷键文字的大小", nil, nil},
    hotkeyX = {0, "slider", {-50, 50, 1}, nil, "文字设置", 44, "调整快捷键文字的水平位置", nil, nil},
    hotkeyY = {-2, "slider", {-50, 50, 1}, nil, "文字设置", 45, "调整快捷键文字的垂直位置", nil, nil},
    macroColour = {{1, 1, 1}, "colour", nil, nil, "文字设置", 46, "更改动作按钮上宏文字的颜色", nil, nil},
    macroShow = {true, "checkbox", nil, nil, "文字设置", 47, "显示或隐藏动作按钮上的宏文字", nil, nil},
    macroScale = {1.3, "slider", {0.5, 2, 0.1}, nil, "文字设置", 48, "调整动作按钮上宏文字的大小", nil, nil},
    macroX = {0, "slider", {-50, 50, 1}, nil, "文字设置", 49, "调整宏文字的水平位置", nil, nil},
    macroY = {2, "slider", {-50, 50, 1}, nil, "文字设置", 50, "调整宏文字的垂直位置", nil, nil},
    petbarScale = {0.8, "slider", {0.2, 2, 0.1}, nil, "宠物条", 51, "调整宠物动作条的缩放", nil, nil},
    petbarSpacing = {6, "slider", {0, 20, 1}, nil, "宠物条", 52, "调整宠物动作条按钮间距", nil, nil},
    petbarAlpha = {1, "slider", {0.1, 1, 0.1}, nil, "宠物条", 53, "调整宠物动作条的透明度", nil, nil},
    shapeshiftScale = {0.8, "slider", {0.2, 2, 0.1}, nil, "变形条", 54, "调整变形条的缩放", nil, nil},
    shapeshiftSpacing = {6, "slider", {0, 20, 1}, nil, "变形条", 55, "调整变形按钮间距", nil, nil},
    shapeshiftAlpha = {1, "slider", {0.1, 1, 0.1}, nil, "变形条", 56, "调整变形条的透明度", nil, nil},
})

DFUI:NewMod("Bars", 1, function()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")

        local Setup = {
            texpath = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\actionbars\\",
            fontpath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\",

            mainBar = nil,
            actionBarFrame = nil,
            newPetBar = nil,
            newShapeshiftBar = nil,
            pagingContainer = nil,
            actionBarBGleft = nil,
            actionBarBGright = nil,
            gryphonContainer = nil,
            leftGryphon = nil,
            rightGryphon = nil,

            buttonTypes = {
                "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
                "MultiBarRightButton", "MultiBarLeftButton", "BonusActionButton",
                "ShapeshiftButton", "PetActionButton"
            },

            layouts = {
                [1] = {rows = 1, cols = 12},
                [2] = {rows = 2, cols = 6},
                [3] = {rows = 3, cols = 4},
                [4] = {rows = 4, cols = 3},
                [5] = {rows = 6, cols = 2},
                [6] = {rows = 12, cols = 1}
            },

            hightlightColor = {1, 0.82, 0},

            texts = {
                hotkey = nil,
                macro = nil,
                config = {
                    font = "Fonts\\FRIZQT__.TTF",
                    hotkeyFontSize = 10,
                    macroFontSize = 9,
                    hotkeyColor = {1, 0.82, 0},
                    macroColor = {1, 1, 1},
                    outline = "OUTLINE",
                }
            }
        }

        -- ✅ PATCH: Immersion compat helper (não força alpha quando Immersion estiver ativo)
        local _IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
        local function DFUI_IsImmersionLoaded()
            return _IsAddOnLoaded and _IsAddOnLoaded("Immersion")
        end

        function Setup:HideBlizzard()
            HideFrameTextures(MainMenuBar)
            HideFrameTextures(MainMenuBarArtFrame)
            HideFrameTextures(PetActionBarFrame)

            MainMenuBar:EnableMouse(false)
            MainMenuBarArtFrame:EnableMouse(false)
            PetActionBarFrame:EnableMouse(false)

            KillFrame(_G.ExhaustionTick)

            SlidingActionBarTexture0:SetTexture(nil)
            SlidingActionBarTexture1:SetTexture(nil)

            BonusActionBarTexture0:Hide()
            BonusActionBarTexture1:Hide()

            ShapeshiftBarLeft:Hide()
            ShapeshiftBarMiddle:Hide()
            ShapeshiftBarRight:Hide()
            ShapeshiftBarLeft:SetAlpha(0)
            ShapeshiftBarMiddle:SetAlpha(0)
            ShapeshiftBarRight:SetAlpha(0)

            for i = 1, 10 do
                local button = _G["ShapeshiftButton"..i]
                if button then
                    local name = button:GetName()
                    local background = _G[name.."Background"]
                    local normalTexture = _G[name.."NormalTexture"]
                    if background then background:Hide() end
                    if normalTexture then normalTexture:Hide() end
                end
            end
        end

        function Setup:MainBarFrames()
            UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomLeft"] = nil

            self.mainBar = CreateFrame("Frame", "DFUI_MainBar", UIParent)
            self.mainBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 55)
            self.mainBar:SetHeight(45)
            self.mainBar:SetWidth(500)
            self.mainBar:SetClampedToScreen(true)
            self.mainBar:SetFrameStrata("LOW")
            self.mainBar:SetFrameLevel(1)

            ActionButton1:ClearAllPoints()
            ActionButton1:SetPoint("BOTTOMLEFT", self.mainBar, "BOTTOMLEFT", 0, 0)

            BonusActionButton1:ClearAllPoints()
            BonusActionButton1:SetPoint("BOTTOMLEFT", self.mainBar, "BOTTOMLEFT", 0, 0)

            self.actionBarFrame = CreateFrame("Frame", "DFUI_ActionBar", UIParent)
            self.actionBarFrame:SetPoint("TOPLEFT", ActionButton1, "TOPLEFT", 0, 0)
            self.actionBarFrame:SetPoint("BOTTOMRIGHT", ActionButton12, "BOTTOMRIGHT", 0, 0)
            self.actionBarFrame:SetFrameStrata("LOW")
            self.actionBarFrame:SetFrameLevel(2)
        end

        function Setup:RepositionBars()
            local function RepositionBars()
                local movable = DFUI:GetTempDB("Bars", "movable")
                if movable ~= true then return end

                local bottomLeftState = _G["SHOW_MULTI_ACTIONBAR_1"]
                local bottomRightState = _G["SHOW_MULTI_ACTIONBAR_2"]

                if not (DFUI_FRAMEPOS and DFUI_FRAMEPOS["MultiBarBottomRight"]) then
                    MultiBarBottomRight:ClearAllPoints()
                    if bottomLeftState then
                        MultiBarBottomRight:SetPoint("BOTTOM", MultiBarBottomLeft, "TOP", 0, 10)
                    else
                        MultiBarBottomRight:SetPoint("BOTTOM", self.actionBarFrame, "TOP", 0, 10)
                    end
                end

                if self.newPetBar and not (DFUI_FRAMEPOS and DFUI_FRAMEPOS["DFUI_PetBar"]) then
                    self.newPetBar:ClearAllPoints()
                    if bottomLeftState and bottomRightState then
                        self.newPetBar:SetPoint("BOTTOM", MultiBarBottomRight, "TOP", 0, 9)
                    elseif bottomLeftState then
                        self.newPetBar:SetPoint("BOTTOM", MultiBarBottomLeft, "TOP", 0, 9)
                    elseif bottomRightState then
                        self.newPetBar:SetPoint("BOTTOM", MultiBarBottomRight, "TOP", 0, 9)
                    else
                        self.newPetBar:SetPoint("BOTTOM", self.actionBarFrame, "TOP", 0, 9)
                    end
                end

                if self.newShapeshiftBar and not (DFUI_FRAMEPOS and DFUI_FRAMEPOS["DFUI_ShapeshiftBar"]) then
                    self.newShapeshiftBar:ClearAllPoints()
                    self.newShapeshiftBar:SetPoint("BOTTOM", self.newPetBar, "TOP", 0, 9)
                end
            end

            local updateTimer = 0
            local barPositionFrame = CreateFrame("Frame")
            barPositionFrame:RegisterEvent("CVAR_UPDATE")
            barPositionFrame:SetScript("OnEvent", function()
                updateTimer = 1
                barPositionFrame:SetScript("OnUpdate", function()
                    updateTimer = updateTimer - arg1
                    if updateTimer <= 0 then
                        RepositionBars()
                        barPositionFrame:SetScript("OnUpdate", nil)
                        DFUI.activeScripts["BarRepositionScript"] = false
                    else
                        DFUI.activeScripts["BarRepositionScript"] = true
                    end
                end)
            end)

            RepositionBars()
        end

        function Setup:MainBarBackground()
            self.actionBarBGleft = self.actionBarFrame:CreateTexture("DFUI_ActionBarLeftTexture", "BACKGROUND")
            self.actionBarBGleft:SetTexture(self.texpath .. "HDActionBar.tga")
            self.actionBarBGleft:SetPoint("LEFT", self.actionBarFrame, "LEFT", -6, 0)
            self.actionBarBGleft:SetPoint("RIGHT", self.actionBarFrame, "CENTER", 0, 0)
            self.actionBarBGleft:SetPoint("TOP", self.actionBarFrame, "TOP", 0, 14)
            self.actionBarBGleft:SetPoint("BOTTOM", self.actionBarFrame, "BOTTOM", 0, -14)

            self.actionBarBGright = self.actionBarFrame:CreateTexture("DFUI_ActionBarRightTexture", "BACKGROUND")
            self.actionBarBGright:SetTexture(self.texpath .. "HDActionBar.tga")
            self.actionBarBGright:SetPoint("LEFT", self.actionBarFrame, "CENTER", 0, 0)
            self.actionBarBGright:SetPoint("RIGHT", self.actionBarFrame, "RIGHT", 6, 0)
            self.actionBarBGright:SetPoint("TOP", self.actionBarFrame, "TOP", 0, 14)
            self.actionBarBGright:SetPoint("BOTTOM", self.actionBarFrame, "BOTTOM", 0, -14)
            self.actionBarBGright:SetTexCoord(1, 0, 0, 1)

        end

        function Setup:ButtonBackgroundsAndBorders()
            local buttonBgTexture = self.texpath .. "HDActionBarBtn.tga"
            local borderTexture = self.texpath .. "border.blp"

            for i = 1, 12 do
                local bgTexture = self.actionBarFrame:CreateTexture("DFUI_ActionButtonBg" .. i, "BORDER")
                bgTexture:SetTexture(buttonBgTexture)
                bgTexture:SetPoint("CENTER", _G["ActionButton" .. i], "CENTER", 0, 0)
                bgTexture:SetWidth(ActionButton1:GetWidth() + 5)
                bgTexture:SetHeight(ActionButton1:GetHeight() + 5)

                local borderTex = self.actionBarFrame:CreateTexture("DFUI_ActionButtonBorder" .. i, "BORDER")
                borderTex:SetTexture(borderTexture)
                borderTex:SetPoint("CENTER", _G["ActionButton" .. i], "CENTER", 0, 0)
                borderTex:SetWidth(ActionButton1:GetWidth() + 5)
                borderTex:SetHeight(ActionButton1:GetHeight() + 5)
            end
        end

        function Setup:ButtonBorderHighlight()
            local borderTexture = self.texpath .. "border.blp"
            local highlightTexture = self.texpath .. "uiactionbariconframehighlight.tga"

            for _, buttonType in ipairs(self.buttonTypes) do
                for i = 1, 12 do
                    local button = _G[buttonType .. i]
                    if button and not button.DFUI_BorderOverlay then
                        local overlayName = button:GetName() .. "DFUI_BorderOverlay"
                        local overlay = button:CreateTexture(overlayName, "OVERLAY")
                        overlay:SetTexture(borderTexture)
                        overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
                        overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
                        overlay:SetVertexColor(0.9, 0.9, 0.9, 1)
                        button.DFUI_BorderOverlay = overlay

                        button:SetHighlightTexture(highlightTexture)
                        local highlight = button:GetHighlightTexture()
                        highlight:SetAllPoints(button)
                        highlight:SetBlendMode("ADD")
                        overlay:Show()
                    end
                end
            end
        end

        function Setup:PositionMultiBars()
            MultiBarBottomLeft:ClearAllPoints()
            MultiBarBottomLeft:SetPoint("BOTTOM", self.actionBarFrame, "TOP", 0, 12)
            MultiBarBottomLeft:SetClampedToScreen(true)
            MultiBarBottomLeft:SetFrameStrata("LOW")
            MultiBarBottomLeft:SetFrameLevel(1)

            MultiBarBottomRight:ClearAllPoints()
            MultiBarBottomRight:SetPoint("BOTTOM", MultiBarBottomLeft, "TOP", 0, 10)
            MultiBarBottomRight:SetClampedToScreen(true)
            MultiBarBottomRight:SetFrameStrata("LOW")
            MultiBarBottomRight:SetFrameLevel(1)

            MultiBarRight:ClearAllPoints()
            MultiBarRight:SetPoint("RIGHT", UIParent, "RIGHT", -15, -50)
            MultiBarRight:SetClampedToScreen(true)
            MultiBarRight:SetFrameStrata("LOW")
            MultiBarRight:SetFrameLevel(1)

            MultiBarLeft:SetClampedToScreen(true)
            MultiBarLeft:SetFrameStrata("LOW")
            MultiBarLeft:SetFrameLevel(1)
        end

        function Setup:PetBar()
            self.newPetBar = CreateFrame("Frame", "DFUI_PetBar", UIParent)
            self.newPetBar:SetPoint("BOTTOM", self.actionBarFrame, "TOP", 0, 8)
            self.newPetBar:SetHeight(36)
            self.newPetBar:SetWidth(360)
            self.newPetBar:SetFrameStrata("LOW")
            self.newPetBar:SetFrameLevel(1)

            for i = 1, 10 do
                local button = _G["PetActionButton"..i]
                button:SetParent(self.newPetBar)
                button:ClearAllPoints()
                button:SetPoint("LEFT", self.newPetBar, "LEFT", (i-1)*36, 0)
            end
        end

        function Setup:ShapeshiftBar()
            self.newShapeshiftBar = CreateFrame("Frame", "DFUI_ShapeshiftBar", UIParent)
            self.newShapeshiftBar:SetPoint("BOTTOM", self.newPetBar, "TOP", 0, 8)
            self.newShapeshiftBar:SetHeight(36)
            self.newShapeshiftBar:SetWidth(360)
            self.newShapeshiftBar:SetFrameStrata("LOW")
            self.newShapeshiftBar:SetFrameLevel(1)

            local numButtons = 0
            for j = 1, 10 do
                if GetShapeshiftFormInfo(j) then numButtons = numButtons + 1 end
            end
            local totalWidth = numButtons * 43
            local startOffset = (360 - totalWidth) / 2

            for i = 1, 10 do
                local button = _G["ShapeshiftButton"..i]
                button:SetParent(self.newShapeshiftBar)
                button:ClearAllPoints()
                button:SetPoint("LEFT", self.newShapeshiftBar, "LEFT", startOffset + (i-1)*43, 0)
            end
        end

        function Setup:BonusBarWatcher()
            local bonusBarWatcher = CreateFrame("Frame")
            bonusBarWatcher:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
            bonusBarWatcher:SetScript("OnEvent", function()
                local bonusBarActive = GetBonusBarOffset() > 0
                for i = 1, 12 do
                    if bonusBarActive then
                        _G["ActionButton"..i]:SetAlpha(0)
                        _G["ActionButton"..i]:EnableMouse(false)
                    else
                        -- ✅ PATCH: não forçar alpha quando Immersion estiver carregado
                        if not DFUI_IsImmersionLoaded() then
                            _G["ActionButton"..i]:SetAlpha(1)
                        end
                        _G["ActionButton"..i]:EnableMouse(true)
                    end
                end
            end)
        end

        function Setup:PagingButtons()
            self.pagingContainer = CreateFrame("Frame", "DFUI_PagingContainer", UIParent)
            self.pagingContainer:SetWidth(ActionBarUpButton:GetWidth())
            self.pagingContainer:SetHeight(65)
            self.pagingContainer:SetPoint("LEFT", ActionButton12, "RIGHT", 15, -1)
            self.pagingContainer:SetFrameStrata("MEDIUM")
            self.pagingContainer:SetFrameLevel(5)

            ActionBarUpButton:SetNormalTexture(self.texpath.. "page_up_normal.tga")
            ActionBarUpButton:SetPushedTexture(self.texpath.. "page_up_pushed.tga")
            ActionBarUpButton:SetHighlightTexture(self.texpath.. "page_up_highlight.tga")

            ActionBarDownButton:SetNormalTexture(self.texpath.. "page_down_normal.tga")
            ActionBarDownButton:SetPushedTexture(self.texpath.. "page_down_pushed.tga")
            ActionBarDownButton:SetHighlightTexture(self.texpath.. "page_down_highlight.tga")

            ActionBarUpButton:ClearAllPoints()
            ActionBarUpButton:SetPoint("TOP", self.pagingContainer, "TOP", -1, 0)
            ActionBarUpButton:SetFrameStrata("MEDIUM")
            ActionBarUpButton:SetFrameLevel(6)
            ActionBarUpButton:SetHeight(25)
            ActionBarUpButton:SetWidth(25)

            MainMenuBarPageNumber:ClearAllPoints()
            MainMenuBarPageNumber:SetParent(self.pagingContainer)
            MainMenuBarPageNumber:SetPoint("CENTER", self.pagingContainer, "CENTER", -1, 1)

            ActionBarDownButton:ClearAllPoints()
            ActionBarDownButton:SetPoint("BOTTOM", self.pagingContainer, "BOTTOM", 1, 0)
            ActionBarDownButton:SetFrameStrata("MEDIUM")
            ActionBarDownButton:SetFrameLevel(6)
            ActionBarDownButton:SetHeight(25)
            ActionBarDownButton:SetWidth(25)
        end

        function Setup:HotkeyMacroText()
            local config = self.texts.config

            local commandMap = {
                ["ActionButton"] = "ACTIONBUTTON",
                ["MultiBarBottomLeftButton"] = "MULTIACTIONBAR1BUTTON",
                ["MultiBarBottomRightButton"] = "MULTIACTIONBAR2BUTTON",
                ["MultiBarRightButton"] = "MULTIACTIONBAR3BUTTON",
                ["MultiBarLeftButton"] = "MULTIACTIONBAR4BUTTON",
                ["BonusActionButton"] = "ACTIONBUTTON",
                ["ShapeshiftButton"] = "SHAPESHIFTBUTTON",
                ["PetActionButton"] = "BONUSACTIONBUTTON"
            }

            local function UpdateHotkeys()
                for _, buttonType in ipairs(Setup.buttonTypes) do
                    for i = 1, 12 do
                        local button = _G[buttonType .. i]
                        if button and button.DFUI_KeybindText then
                            local key1 = GetBindingKey(commandMap[buttonType] .. i)
                            if key1 then
                                key1 = string.gsub(key1, "BUTTON", "M")
                                key1 = string.gsub(key1, "SHIFT%-", "S-")
                                key1 = string.gsub(key1, "CTRL%-", "C-")
                                key1 = string.gsub(key1, "ALT%-", "A-")
                                key1 = string.gsub(key1, "SPACE", "SP")
                                key1 = string.gsub(key1, "NUMPAD", "NP-")
                                key1 = string.gsub(key1, "MOUSEWHEELUP", "MWU")
                                key1 = string.gsub(key1, "MOUSEWHEELDOWN", "MWD")
                                button.DFUI_KeybindText:SetText(key1)
                            else
                                button.DFUI_KeybindText:SetText("")
                            end
                        end
                    end
                end
            end

            for _, buttonType in ipairs(Setup.buttonTypes) do
                for i = 1, 12 do
                    local button = _G[buttonType .. i]
                    if button then
                        local hotkey = _G[button:GetName() .. "HotKey"]
                        if hotkey then
                            hotkey:Hide()
                        end

                        local keybindText = button:CreateFontString(button:GetName() .. "DFUI_KeybindText", "OVERLAY")
                        keybindText:SetPoint("BOTTOM", button, "BOTTOM", 0, -2)
                        keybindText:SetFont(config.font, config.hotkeyFontSize, config.outline)
                        keybindText:SetTextColor(unpack(config.hotkeyColor))
                        button.DFUI_KeybindText = keybindText

                        local macroName = _G[button:GetName() .. "Name"]
                        if macroName then
                            macroName:SetFont(config.font, config.macroFontSize, config.outline)
                            macroName:SetTextColor(unpack(config.macroColor))
                        end
                    end
                end
            end

            if not self.hotkeyBindingFrame then
                self.hotkeyBindingFrame = CreateFrame("Frame", "DFUI_HotkeyBinding")
                self.hotkeyBindingFrame:RegisterEvent("UPDATE_BINDINGS")
                self.hotkeyBindingFrame:SetScript("OnEvent", function()
                    UpdateHotkeys()
                end)
            end

            UpdateHotkeys()
        end

        function Setup:Gryphoons()
            self.gryphonContainer = CreateFrame("Frame", "DFUI_GryphonContainer", UIParent)
            self.gryphonContainer:SetFrameStrata("LOW")
            self.gryphonContainer:SetFrameLevel(3)
            self.gryphonContainer:SetAllPoints(self.actionBarFrame)

            self.leftGryphon = self.gryphonContainer:CreateTexture("DFUI_LeftGryphon", "OVERLAY")
            self.rightGryphon = self.gryphonContainer:CreateTexture("DFUI_RightGryphon", "OVERLAY")

            self.leftGryphon:SetPoint("RIGHT", self.actionBarFrame, "LEFT", 45, 10)
            self.rightGryphon:SetPoint("LEFT", self.actionBarFrame, "RIGHT", -45, 10)

            local faction = UnitFactionGroup("player")
            local texturePath
            if faction == "Alliance" then
                texturePath = self.texpath .. "GryphonNew.tga"
            else
                texturePath = self.texpath .. "WyvernNew.tga"
            end

            self.leftGryphon:SetTexture(texturePath)
            self.rightGryphon:SetTexture(texturePath)

            self.leftGryphon:SetWidth(180)
            self.leftGryphon:SetHeight(180)
            self.rightGryphon:SetWidth(180)
            self.rightGryphon:SetHeight(180)

            self.rightGryphon:SetTexCoord(1, 0, 0, 1)
        end

        function Setup:Run()
            self:HideBlizzard()
            self:MainBarFrames()
            self:PositionMultiBars()
            self:PetBar()
            self:ShapeshiftBar()
            self:BonusBarWatcher()
            self:ButtonBorderHighlight()
            self:PagingButtons()
            self:MainBarBackground()
            self:ButtonBackgroundsAndBorders()
            self:HotkeyMacroText()
            self:Gryphoons()
        end

        Setup:Run()

        -- expose
        DFUI.mainBar = Setup.mainBar
        DFUI.actionBarFrame = Setup.actionBarFrame
        DFUI.newPetBar = Setup.newPetBar
        DFUI.newShapeshiftBar = Setup.newShapeshiftBar
        DFUI.pagingContainer = Setup.pagingContainer
        DFUI.actionBarBGleft = Setup.actionBarBGleft
        DFUI.actionBarBGright = Setup.actionBarBGright

        -- callbacks
        local callbacks = {}
        local helpers = {
            getFontPath = function(fontName)
                if fontName == 'Expressway' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Expressway.ttf'
                elseif fontName == 'Homespun' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Homespun.ttf'
                elseif fontName == 'Hooge' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Hooge.ttf'
                elseif fontName == 'Myriad-Pro' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Myriad-Pro.ttf'
                elseif fontName == 'Prototype' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Prototype.ttf'
                elseif fontName == 'PT-Sans-Narrow-Bold' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\PT-Sans-Narrow-Bold.ttf'
                elseif fontName == 'PT-Sans-Narrow-Regular' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\PT-Sans-Narrow-Regular.ttf'
                elseif fontName == 'RobotoMono' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\RobotoMono.ttf'
                elseif fontName == 'BigNoodleTitling' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\BigNoodleTitling.ttf'
                elseif fontName == 'Continuum' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\Continuum.ttf'
                elseif fontName == 'DieDieDie' then
                    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\DieDieDie.ttf'
                else
                    return 'Fonts\\FRIZQT__.TTF'
                end
            end,

            setGridLayout = function(barFrame, buttonPrefix, value, spacingKey)
                local layoutIndex = math.floor(value + 0.5)
                if layoutIndex < 1 then layoutIndex = 1 end
                if layoutIndex > 6 then layoutIndex = 6 end
                local layout = Setup.layouts[layoutIndex]
                if not layout then return end

                local spacing = DFUI:GetTempDB('Bars', spacingKey)
                local buttonSize = _G[buttonPrefix .. '1']:GetWidth()
                local isReversed = buttonPrefix == 'MultiBarLeftButton' or buttonPrefix == 'MultiBarRightButton'

                for i = (isReversed and 12 or 1), (isReversed and 1 or 12), (isReversed and -1 or 1) do
                    local button = _G[buttonPrefix .. i]
                    if button then
                        button:ClearAllPoints()
                        local index = isReversed and (13 - i) or i
                        local row = math.floor((index - 1) / layout.cols)
                        local col = (index - 1) - (row * layout.cols)
                        button:SetPoint('BOTTOMLEFT', barFrame, 'BOTTOMLEFT', col * (buttonSize + spacing), row * (buttonSize + spacing))
                    end
                end

                barFrame:SetHeight((buttonSize + spacing) * layout.rows - spacing)
                barFrame:SetWidth((buttonSize + spacing) * layout.cols - spacing)
            end,

            iterateButtons = function(callback)
                for _, buttonType in ipairs(Setup.buttonTypes) do
                    for i = 1, 12 do
                        local button = _G[buttonType .. i]
                        if button then
                            callback(button, buttonType, i)
                        end
                    end
                end
            end,

            setSpacing = function(buttonPrefix, spacing, direction, maxButtons)
                maxButtons = maxButtons or 12
                for i = 2, maxButtons do
                    local button = _G[buttonPrefix .. i]
                    if button then
                        button:ClearAllPoints()
                        if direction == 'vertical' then
                            button:SetPoint('TOP', _G[buttonPrefix .. (i-1)], 'BOTTOM', 0, -spacing)
                        else
                            button:SetPoint('LEFT', _G[buttonPrefix .. (i-1)], 'RIGHT', spacing, 0)
                        end
                    end
                end
            end
        }

        


        callbacks.multiBarOneScale = function(value)
            MultiBarBottomLeft:SetScale(value)
        end

        callbacks.multiBarOneSpacing = function(value)
            helpers.setSpacing('MultiBarBottomLeftButton', value)
        end

        callbacks.multiBarOneAlpha = function(value)
            MultiBarBottomLeft:SetAlpha(value)
        end

        callbacks.multiBarTwoScale = function(value)
            MultiBarBottomRight:SetScale(value)
        end

        callbacks.multiBarTwoSpacing = function(value)
            local gridLayout = DFUI:GetTempDB('Bars', 'multiBarTwoGrid')
            if math.floor(gridLayout + 0.5) ~= 1 then return end
            helpers.setSpacing('MultiBarBottomRightButton', value)
        end

        callbacks.multiBarTwoAlpha = function(value)
            MultiBarBottomRight:SetAlpha(value)
        end

        callbacks.multiBarThreeScale = function(value)
            MultiBarLeft:SetScale(value)
        end

        callbacks.multiBarThreeSpacing = function(value)
            helpers.setSpacing('MultiBarLeftButton', value, 'vertical')
        end

        callbacks.multiBarThreeAlpha = function(value)
            MultiBarLeft:SetAlpha(value)
        end

        callbacks.multiBarFourScale = function(value)
            MultiBarRight:SetScale(value)
        end

        callbacks.multiBarFourSpacing = function(value)
            helpers.setSpacing('MultiBarRightButton', value, 'vertical')
        end

        callbacks.multiBarFourAlpha = function(value)
            MultiBarRight:SetAlpha(value)
        end

        callbacks.gryphoonScale = function(value)
            local leftGryphon = _G["DFUI_LeftGryphon"]
            local rightGryphon = _G["DFUI_RightGryphon"]

            if leftGryphon then
                leftGryphon:SetWidth(180 * value)
                leftGryphon:SetHeight(180 * value)
            end

            if rightGryphon then
                rightGryphon:SetWidth(180 * value)
                rightGryphon:SetHeight(180 * value)
            end
        end

        callbacks.showGryphoon = function(value)
            local leftGryphon = _G["DFUI_LeftGryphon"]
            local rightGryphon = _G["DFUI_RightGryphon"]

            if leftGryphon then
                if value then
                    leftGryphon:Show()
                else
                    leftGryphon:Hide()
                end
            end

            if rightGryphon then
                if value then
                    rightGryphon:Show()
                else
                    rightGryphon:Hide()
                end
            end
        end

        callbacks.gryphoonX = function(value)
            local leftGryphon = _G["DFUI_LeftGryphon"]
            local rightGryphon = _G["DFUI_RightGryphon"]
            local yOffset = DFUI:GetTempDB("Bars", "gryphoonY")

            if leftGryphon then
                leftGryphon:ClearAllPoints()
                leftGryphon:SetPoint("RIGHT", DFUI.actionBarFrame, "LEFT", -value, yOffset)
            end

            if rightGryphon then
                rightGryphon:ClearAllPoints()
                rightGryphon:SetPoint("LEFT", DFUI.actionBarFrame, "RIGHT", value, yOffset)
            end
        end

        callbacks.gryphoonY = function(value)
            local leftGryphon = _G["DFUI_LeftGryphon"]
            local rightGryphon = _G["DFUI_RightGryphon"]
            local xOffset = DFUI:GetTempDB("Bars", "gryphoonX")

            if leftGryphon then
                leftGryphon:ClearAllPoints()
                leftGryphon:SetPoint("RIGHT", DFUI.actionBarFrame, "LEFT", -xOffset, value)
            end

            if rightGryphon then
                rightGryphon:ClearAllPoints()
                rightGryphon:SetPoint("LEFT", DFUI.actionBarFrame, "RIGHT", xOffset, value)
            end
        end

        callbacks.gryphoonAlpha = function(value)
            local leftGryphon = _G['DFUI_LeftGryphon']
            local rightGryphon = _G['DFUI_RightGryphon']

            if leftGryphon then
                leftGryphon:SetAlpha(value)
            end

            if rightGryphon then
                rightGryphon:SetAlpha(value)
            end
        end

        callbacks.barsDarkMode = function(value)
            local intensity = DFUI:GetTempDB("Bars", "barsDarkMode")
            local barsColor = DFUI:GetTempDB("Bars", "barsColor")
            local r, g, b = barsColor[1] * (1 - intensity), barsColor[2] * (1 - intensity), barsColor[3] * (1 - intensity)
            local color = value and {r, g, b} or {1, 1, 1}

            local leftGryphon = _G["DFUI_LeftGryphon"]
            local rightGryphon = _G["DFUI_RightGryphon"]
            if leftGryphon then leftGryphon:SetVertexColor(color[1], color[2], color[3]) end
            if rightGryphon then rightGryphon:SetVertexColor(color[1], color[2], color[3]) end

            local leftTexture = _G["DFUI_ActionBarLeftTexture"]
            local rightTexture = _G["DFUI_ActionBarRightTexture"]
            if leftTexture then leftTexture:SetVertexColor(color[1], color[2], color[3]) end
            if rightTexture then rightTexture:SetVertexColor(color[1], color[2], color[3]) end

            for i = 1, 12 do
                local borderTex = _G["DFUI_ActionButtonBorder" .. i]
                if borderTex then borderTex:SetVertexColor(color[1], color[2], color[3]) end
            end

            for _, buttonType in ipairs(Setup.buttonTypes) do
                for i = 1, 12 do
                    local button = _G[buttonType .. i]
                    if button then
                        local overlay = _G[button:GetName() .. "DFUI_BorderOverlay"]
                        if overlay then overlay:SetVertexColor(color[1], color[2], color[3]) end
                    end
                end
            end
        end

        callbacks.barsColor = function(value)
            local intensity = DFUI:GetTempDB("Bars", "barsDarkMode")
            local r, g, b = value[1] * (1 - intensity), value[2] * (1 - intensity), value[3] * (1 - intensity)

            local leftGryphon = _G["DFUI_LeftGryphon"]
            local rightGryphon = _G["DFUI_RightGryphon"]
            if leftGryphon then leftGryphon:SetVertexColor(r, g, b) end
            if rightGryphon then rightGryphon:SetVertexColor(r, g, b) end

            local leftTexture = _G["DFUI_ActionBarLeftTexture"]
            local rightTexture = _G["DFUI_ActionBarRightTexture"]
            if leftTexture then leftTexture:SetVertexColor(r, g, b) end
            if rightTexture then rightTexture:SetVertexColor(r, g, b) end

            for i = 1, 12 do
                local borderTex = _G["DFUI_ActionButtonBorder" .. i]
                if borderTex then borderTex:SetVertexColor(r, g, b) end
            end

            for _, buttonType in ipairs(Setup.buttonTypes) do
                for i = 1, 12 do
                    local button = _G[buttonType .. i]
                    if button then
                        local overlay = _G[button:GetName() .. "DFUI_BorderOverlay"]
                        if overlay then overlay:SetVertexColor(r, g, b) end
                    end
                end
            end
        end

        callbacks.pagingShow = function(value)
            if DFUI.pagingContainer then
                if value then
                    DFUI.pagingContainer:Show()
                    ActionBarUpButton:Show()
                    ActionBarDownButton:Show()
                    MainMenuBarPageNumber:Show()
                else
                    DFUI.pagingContainer:Hide()
                    ActionBarUpButton:Hide()
                    ActionBarDownButton:Hide()
                    MainMenuBarPageNumber:Hide()
                end
            end
        end

        callbacks.pagingScale = function(value)
            DFUI.pagingContainer:SetScale(value)
        end

        callbacks.hotkeyColour = function(value)
            local r, g, b = unpack(value)
            helpers.iterateButtons(function(button)
                if button.DFUI_KeybindText then
                    button.DFUI_KeybindText:SetTextColor(r, g, b)
                end
            end)
        end

        callbacks.hotkeyShow = function(value)
            helpers.iterateButtons(function(button)
                if button.DFUI_KeybindText then
                    if value then
                        button.DFUI_KeybindText:Show()
                    else
                        button.DFUI_KeybindText:Hide()
                    end
                end
            end)
        end

        callbacks.hotkeyScale = function(value)
            local fontPath = helpers.getFontPath(DFUI:GetTempDB('Bars', 'hotkeyFont'))
            helpers.iterateButtons(function(button)
                if button.DFUI_KeybindText then
                    button.DFUI_KeybindText:SetFont(fontPath, 10 * value, 'OUTLINE')
                end
            end)
        end

        callbacks.hotkeyX = function(value)
            local yOffset = DFUI.tempDB['Bars']['hotkeyY']
            helpers.iterateButtons(function(button)
                if button.DFUI_KeybindText then
                    button.DFUI_KeybindText:ClearAllPoints()
                    button.DFUI_KeybindText:SetPoint('BOTTOM', button, 'BOTTOM', value, yOffset)
                end
            end)
        end

        callbacks.hotkeyY = function(value)
            local xOffset = DFUI.tempDB['Bars']['hotkeyX']
            helpers.iterateButtons(function(button)
                if button.DFUI_KeybindText then
                    button.DFUI_KeybindText:ClearAllPoints()
                    button.DFUI_KeybindText:SetPoint('BOTTOM', button, 'BOTTOM', xOffset, value)
                end
            end)
        end

        callbacks.macroColour = function(value)
            local r, g, b = unpack(value)
            helpers.iterateButtons(function(button)
                local macroName = _G[button:GetName() .. 'Name']
                if macroName then
                    macroName:SetTextColor(r, g, b)
                end
            end)
        end

        callbacks.macroShow = function(value)
            helpers.iterateButtons(function(button)
                local macroName = _G[button:GetName() .. 'Name']
                if macroName then
                    if value then
                        macroName:Show()
                    else
                        macroName:Hide()
                    end
                end
            end)
        end

        callbacks.macroScale = function(value)
            local fontPath = helpers.getFontPath(DFUI:GetTempDB('Bars', 'hotkeyFont'))
            helpers.iterateButtons(function(button)
                local macroName = _G[button:GetName() .. 'Name']
                if macroName then
                    macroName:SetFont(fontPath, 9 * value, 'OUTLINE')
                end
            end)
        end

        callbacks.macroX = function(value)
            local yOffset = DFUI.tempDB['Bars']['macroY']
            helpers.iterateButtons(function(button)
                local macroName = _G[button:GetName() .. 'Name']
                if macroName then
                    macroName:ClearAllPoints()
                    macroName:SetPoint('TOP', button, 'TOP', value, yOffset)
                end
            end)
        end

        callbacks.macroY = function(value)
            local xOffset = DFUI.tempDB['Bars']['macroX']
            helpers.iterateButtons(function(button)
                local macroName = _G[button:GetName() .. 'Name']
                if macroName then
                    macroName:ClearAllPoints()
                    macroName:SetPoint('TOP', button, 'TOP', xOffset, value)
                end
            end)
        end

        callbacks.petbarScale = function(value)
            if DFUI.newPetBar then
                DFUI.newPetBar:SetScale(value)
            end
        end

        callbacks.shapeshiftScale = function(value)
            if DFUI.newShapeshiftBar then
                DFUI.newShapeshiftBar:SetScale(value)
            end
        end

        callbacks.petbarSpacing = function(value)
            helpers.setSpacing('PetActionButton', value, 'horizontal', 10)
        end

        callbacks.petbarAlpha = function(value)
            if DFUI.newPetBar then
                DFUI.newPetBar:SetAlpha(value)
            end
        end

        callbacks.shapeshiftSpacing = function(value)
            helpers.setSpacing('ShapeshiftButton', value, 'horizontal', 10)
        end

        callbacks.shapeshiftAlpha = function(value)
            if DFUI.newShapeshiftBar then
                DFUI.newShapeshiftBar:SetAlpha(value)
            end
        end

        callbacks.flipGryphoon = function (value)
            local leftGryphon = _G["DFUI_LeftGryphon"]
            local rightGryphon = _G["DFUI_RightGryphon"]

            if value then
                leftGryphon:SetTexCoord(1, 0, 0, 1)
                rightGryphon:SetTexCoord(0, 1, 0, 1)
            else
                leftGryphon:SetTexCoord(0, 1, 0, 1)
                rightGryphon:SetTexCoord(1, 0, 0, 1)
            end
        end

        callbacks.altGryphoon = function(value)
            local leftGryphon = _G["DFUI_LeftGryphon"]
            local rightGryphon = _G["DFUI_RightGryphon"]

            local faction = UnitFactionGroup("player")
            local texturePath

            if value then
                if faction == "Alliance" then
                    texturePath = Setup.texpath.. "altGyph.tga"
                else
                    texturePath = Setup.texpath.. "altWyv.tga"
                end
            else
                if faction == "Alliance" then
                    texturePath = Setup.texpath.. "GryphonNew.tga"
                else
                    texturePath = Setup.texpath.. "WyvernNew.tga"
                end
            end

            if leftGryphon and rightGryphon then
                leftGryphon:SetTexture(texturePath)
                rightGryphon:SetTexture(texturePath)

                -- maintain flip
                local isFlipped = DFUI:GetTempDB("Bars", "flipGryphoon")
                if isFlipped then
                    leftGryphon:SetTexCoord(1, 0, 0, 1)
                    rightGryphon:SetTexCoord(0, 1, 0, 1)
                else
                    leftGryphon:SetTexCoord(0, 1, 0, 1)
                    rightGryphon:SetTexCoord(1, 0, 0, 1)
                end
            end
        end

        callbacks.pagingSwap = function(value)
            if DFUI.pagingContainer then
                DFUI.pagingContainer:ClearAllPoints()
                if value then
                    DFUI.pagingContainer:SetPoint("RIGHT", ActionButton1, "LEFT", -15, -1)
                else
                    DFUI.pagingContainer:SetPoint("LEFT", ActionButton12, "RIGHT", 15, -1)
                end
            end
        end

        callbacks.pagingX = function(value)
            if DFUI.pagingContainer then
                local isSwapped = DFUI:GetTempDB("Bars", "pagingSwap")
                DFUI.pagingContainer:ClearAllPoints()
                if isSwapped then
                    DFUI.pagingContainer:SetPoint("RIGHT", ActionButton1, "LEFT", -value, -1)
                else
                    DFUI.pagingContainer:SetPoint("LEFT", ActionButton12, "RIGHT", value, -1)
                end
            end
        end

        callbacks.multiBarOneGrid = function(value)
            helpers.setGridLayout(MultiBarBottomLeft, 'MultiBarBottomLeftButton', value, 'multiBarOneSpacing')
        end

        callbacks.multiBarTwoGrid = function(value)
            if not MultiBarBottomRight then return end
            helpers.setGridLayout(MultiBarBottomRight, 'MultiBarBottomRightButton', value, 'multiBarTwoSpacing')
        end

        callbacks.multiBarThreeGrid = function(value)
            helpers.setGridLayout(MultiBarLeft, 'MultiBarLeftButton', value, 'multiBarThreeSpacing')
        end

        callbacks.multiBarFourGrid = function(value)
            helpers.setGridLayout(MultiBarRight, 'MultiBarRightButton', value, 'multiBarFourSpacing')
        end

        callbacks.mainBarScale = function(value)
            DFUI.mainBar:SetScale(value)
            DFUI.actionBarFrame:SetScale(value)

            for i = 1, 12 do
                local button = _G["ActionButton"..i]
                button:SetScale(value)

                local bonusButton = _G["BonusActionButton"..i]
                bonusButton:SetScale(value)

                if i > 1 then
                    button:ClearAllPoints()
                    button:SetPoint("LEFT", _G["ActionButton"..(i-1)], "RIGHT", 6, 0)

                    bonusButton:ClearAllPoints()
                    bonusButton:SetPoint("LEFT", _G["BonusActionButton"..(i-1)], "RIGHT", 6, 0)
                end
            end
        end

        callbacks.mainBarSpacing = function(value)
            local gridLayout = DFUI:GetTempDB('Bars', 'mainBarGrid')
            if math.floor(gridLayout + 0.5) ~= 1 then return end
            
            local buttonSize = ActionButton1:GetWidth()

            for i = 2, 12 do
                local button = _G["ActionButton"..i]
                button:ClearAllPoints()
                button:SetPoint("LEFT", _G["ActionButton"..(i-1)], "RIGHT", value, 0)

                local bonusButton = _G["BonusActionButton"..i]
                bonusButton:ClearAllPoints()
                bonusButton:SetPoint("LEFT", _G["BonusActionButton"..(i-1)], "RIGHT", value, 0)
            end

            local totalWidth = (buttonSize * 12) + (value * 11)
            DFUI.mainBar:SetWidth(totalWidth)
            DFUI.actionBarFrame:SetWidth(totalWidth)
        end

        callbacks.mainBarAlpha = function(value)
            DFUI.mainBar:SetAlpha(value)
            DFUI.actionBarFrame:SetAlpha(value)

            for i = 1, 12 do
                local button = _G["ActionButton"..i]
                button:SetAlpha(value)

                local bonusButton = _G["BonusActionButton"..i]
                bonusButton:SetAlpha(value)
            end
        end

        callbacks.mainBarBG = function(value)
            local gridLayout = DFUI:GetTempDB('Bars', 'mainBarGrid')
            local layoutIndex = math.floor(gridLayout + 0.5)
            local showBG = value and layoutIndex == 1

            if DFUI.actionBarBGleft then
                if showBG then
                    DFUI.actionBarBGleft:Show()
                else
                    DFUI.actionBarBGleft:Hide()
                end
            end

            if DFUI.actionBarBGright then
                if showBG then
                    DFUI.actionBarBGright:Show()
                else
                    DFUI.actionBarBGright:Hide()
                end
            end
        end

        callbacks.hotkeyFont = function(value)
            local fontPath = helpers.getFontPath(value)
            helpers.iterateButtons(function(button, buttonType, i)
                if button.DFUI_KeybindText then
                    button.DFUI_KeybindText:SetFont(fontPath, 10 * DFUI:GetTempDB('Bars', 'hotkeyScale'), 'OUTLINE')
                end
                local macroName = _G[buttonType .. i .. 'Name']
                if macroName then
                    macroName:SetFont(fontPath, 10 * DFUI:GetTempDB('Bars', 'macroScale'), 'OUTLINE')
                end
            end)
        end

        callbacks.multiBarOneShow = function(value)
            if value then
                MultiBarBottomLeft:Show()
                _G["SHOW_MULTI_ACTIONBAR_1"] = 1
                Setup:RepositionBars()
            else
                MultiBarBottomLeft:Hide()
                _G["SHOW_MULTI_ACTIONBAR_1"] = nil
                Setup:RepositionBars()
            end
        end

        callbacks.multiBarTwoShow = function(value)
            if value then
                MultiBarBottomRight:Show()
                _G["SHOW_MULTI_ACTIONBAR_2"] = 1
                Setup:RepositionBars()
            else
                MultiBarBottomRight:Hide()
                _G["SHOW_MULTI_ACTIONBAR_2"] = nil
                Setup:RepositionBars()
            end
        end

        callbacks.multiBarThreeShow = function(value)
            if value then
                MultiBarLeft:Show()
                _G["SHOW_MULTI_ACTIONBAR_3"] = 1
            else
                MultiBarLeft:Hide()
                _G["SHOW_MULTI_ACTIONBAR_3"] = nil
            end
        end

        callbacks.multiBarFourShow = function(value)
            if value then
                MultiBarRight:Show()
                _G["SHOW_MULTI_ACTIONBAR_4"] = 1
            else
                MultiBarRight:Hide()
                _G["SHOW_MULTI_ACTIONBAR_4"] = nil
            end
        end

        callbacks.highlightColor = function(value)
            Setup.hightlightColor = value
            helpers.iterateButtons(function(button)
                local highlight = button:GetHighlightTexture()
                if highlight then
                    highlight:SetVertexColor(unpack(value))
                end
            end)
        end

        callbacks.mainBarGrid = function(value)
            if not ActionButton1 or not DFUI.mainBar then return end
            local layoutIndex = math.floor(value + 0.5)
            if layoutIndex < 1 then layoutIndex = 1 end
            if layoutIndex > 6 then layoutIndex = 6 end
            local layout = Setup.layouts[layoutIndex]
            if not layout then return end

            local spacing = DFUI:GetTempDB('Bars', 'mainBarSpacing')
            local buttonSize = ActionButton1:GetWidth()

            for i = 1, 12 do
                local button = _G['ActionButton' .. i]
                local bonusButton = _G['BonusActionButton' .. i]
                if button then
                    button:ClearAllPoints()
                    local row = math.floor((i - 1) / layout.cols)
                    local col = (i - 1) - (row * layout.cols)
                    button:SetPoint('BOTTOMLEFT', DFUI.mainBar, 'BOTTOMLEFT', col * (buttonSize + spacing), row * (buttonSize + spacing))
                end
                if bonusButton then
                    bonusButton:ClearAllPoints()
                    local row = math.floor((i - 1) / layout.cols)
                    local col = (i - 1) - (row * layout.cols)
                    bonusButton:SetPoint('BOTTOMLEFT', DFUI.mainBar, 'BOTTOMLEFT', col * (buttonSize + spacing), row * (buttonSize + spacing))
                end
            end

            local newWidth = (buttonSize + spacing) * layout.cols - spacing
            local newHeight = (buttonSize + spacing) * layout.rows - spacing
            DFUI.mainBar:SetWidth(newWidth)
            DFUI.mainBar:SetHeight(newHeight)
            DFUI.actionBarFrame:SetWidth(newWidth)
            DFUI.actionBarFrame:SetHeight(newHeight)

            if layoutIndex == 1 then
                if DFUI.actionBarBGleft then DFUI.actionBarBGleft:Show() end
                if DFUI.actionBarBGright then DFUI.actionBarBGright:Show() end
            else
                if DFUI.actionBarBGleft then DFUI.actionBarBGleft:Hide() end
                if DFUI.actionBarBGright then DFUI.actionBarBGright:Hide() end
            end

            local leftGryphon = _G['DFUI_LeftGryphon']
            local rightGryphon = _G['DFUI_RightGryphon']
            local xOffset = DFUI:GetTempDB('Bars', 'gryphoonX')
            local yOffset = DFUI:GetTempDB('Bars', 'gryphoonY')

            if leftGryphon then
                leftGryphon:ClearAllPoints()
                leftGryphon:SetPoint('RIGHT', ActionButton1, 'LEFT', -xOffset, yOffset)
            end

            if rightGryphon then
                rightGryphon:ClearAllPoints()
                local rightCornerButton = _G['ActionButton' .. layout.cols]
                rightGryphon:SetPoint('LEFT', rightCornerButton, 'RIGHT', xOffset, yOffset)
            end
        end

        DFUI.activeScripts["BarRepositionScript"] = false

        -- execute callbacks
        DFUI:NewCallbacks("Bars", callbacks)

        _G["MultiActionBar_Update"] = function() end

        local checkboxes = {33, 34, 35, 36}
        for i = 1, 4 do
            local checkbox = _G["UIOptionsFrameCheckButton" .. checkboxes[i]]
            if checkbox then
                checkbox:Hide()
            end
        end
    end)
end)
