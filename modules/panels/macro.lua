setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

DFUI:NewDefaults("Macros", {
    enabled = {true},
})

DFUI:NewMod("Macros", 5, function()
    local skinned = false

    -- 通用纹理隐藏：保留图标/头像/高亮
    local function HideBlizzardTextures(frame)
        if not frame then return end
        local regions = {frame:GetRegions()}
        for i = 1, table.getn(regions) do
            local region = regions[i]
            if region:GetObjectType() == "Texture" then
                local name = region:GetName()
                local texture = region:GetTexture()
                local skip = false
                if name then
                    if string.find(name, "Icon") or string.find(name, "Portrait") or string.find(name, "Check") or string.find(name, "Highlight") then
                        skip = true
                    end
                end
                if texture and (string.find(texture, "Icon") or string.find(texture, "Portrait") or string.find(texture, "StatusBar")) then
                    skip = true
                end
                if not skip then
                    region:Hide()
                end
            end
        end
    end

    local SkinMacroPopupFrame  -- 前置声明，在 SkinMacroFrame 末尾调用

    local function SkinMacroFrame()
        if skinned or not MacroFrame then return end
        skinned = true

        HideBlizzardTextures(MacroFrame)

        if MacroFrameCloseButton then MacroFrameCloseButton:Hide() end
        -- 隐藏原生 Tab，下面用 DFUI 风格 Tab 替代（原生 Tab 显示出来会有不可见 hit area 压住整个面板交互）
        if MacroFrameTab then MacroFrameTab:Hide() end
        if MacroFrameTab1 then MacroFrameTab1:Hide() end
        if MacroFrameTab2 then MacroFrameTab2:Hide() end

        local customBg = DFUI.CreatePaperDollFrame("DFUI_MacroBg", MacroFrame, 384, 512, 2)
        customBg:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 12, -12)
        -- 底部留 110px 给原生底部按钮带（New/Edit/Delete/Exit 在底部 79~101px）+ DFUI Tab 行
        customBg:SetPoint("BOTTOMRIGHT", MacroFrame, "BOTTOMRIGHT", -32, 110)
        customBg:SetFrameLevel(MacroFrame:GetFrameLevel() - 1)
        customBg.Bg:SetDrawLayer("BACKGROUND", -5)

        if MacroFramePortrait then
            MacroFramePortrait:Hide()
        end

        local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(MacroFrame) end)
        closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

        -- 高亮 18 个宏按钮图标
        local hlTex = TEX .. "actionbars\\uiactionbariconframehighlight.tga"
        for i = 1, 18 do
            local button = getglobal("MacroButton" .. i)
            if button then
                local icon = getglobal("MacroButton" .. i .. "Icon")
                if icon then
                    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
                    highlight:SetPoint("TOPLEFT", icon, "TOPLEFT", -6, 6)
                    highlight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 6, -6)
                    highlight:SetTexture(hlTex)
                    highlight:SetBlendMode("ADD")
                    button:SetHighlightTexture(highlight)
                end
            end
        end

        -- 高亮选中的宏按钮
        if MacroFrameSelectedMacroButton and MacroFrameSelectedMacroButtonIcon then
            local highlight = MacroFrameSelectedMacroButton:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetPoint("TOPLEFT", MacroFrameSelectedMacroButtonIcon, "TOPLEFT", -6, 6)
            highlight:SetPoint("BOTTOMRIGHT", MacroFrameSelectedMacroButtonIcon, "BOTTOMRIGHT", 6, -6)
            highlight:SetTexture(hlTex)
            highlight:SetBlendMode("ADD")
            MacroFrameSelectedMacroButton:SetHighlightTexture(highlight)
        end

        -- DFUI 风格 Tab：通用宏 / 个人宏
        customBg:AddTab("通用宏", function()
            if MacroFrameTab1 then MacroFrameTab1:Click() end
            PanelTemplates_SetTab(MacroFrame, 1)
        end, 70)

        customBg:AddTab("个人宏", function()
            if MacroFrameTab2 then MacroFrameTab2:Click() end
            PanelTemplates_SetTab(MacroFrame, 2)
        end, 70)

        -- Fix B：把 Tab 锚到 MacroFrame 底部 45px（按钮带 79~101 下方），避免 customBg 让位后 Tab 撞按钮
        if customBg.Tabs[1] then
            customBg.Tabs[1]:ClearAllPoints()
            customBg.Tabs[1]:SetPoint("BOTTOMLEFT", MacroFrame, "BOTTOMLEFT", 20, 45)
        end
        if customBg.Tabs[2] then
            customBg.Tabs[2]:ClearAllPoints()
            customBg.Tabs[2]:SetPoint("BOTTOMLEFT", customBg.Tabs[1], "BOTTOMRIGHT", 4, 0)
        end

        -- Fix C：保险——显式把底部按钮 / 文本框 FrameLevel 拉到 customBg 之上，防止 Z 序问题挡住交互
        local boostLvl = MacroFrame:GetFrameLevel() + 5
        local boostList = {
            MacroNewButton, MacroEditButton, MacroDeleteButton, MacroExitButton,
            MacroFrameText, MacroFrameScrollFrame, MacroFrameScrollFrameScrollBar,
        }
        for i = 1, table.getn(boostList) do
            local btn = boostList[i]
            if btn and btn.SetFrameLevel then btn:SetFrameLevel(boostLvl) end
        end

        CenterFrame(MacroFrame)
        HookScript(MacroFrame, "OnShow", function()
            customBg:Show()
            -- 同步 customBg.Tabs 选中态到原生当前 Tab
            local sel = PanelTemplates_GetSelectedTab(MacroFrame) or 1
            if customBg.Tabs then
                for i = 1, table.getn(customBg.Tabs) do
                    local t = customBg.Tabs[i]
                    if t and t.SetSelected then
                        t:SetSelected(i == sel)
                        if i == sel then customBg.selectedTab = t end
                    end
                end
            end
        end)

        SkinMacroPopupFrame()
    end

    local popupSkinned = false
    SkinMacroPopupFrame = function()
        if popupSkinned or not MacroPopupFrame then return end
        popupSkinned = true

        HideBlizzardTextures(MacroPopupFrame)
        if MacroPopupFrameCloseButton then MacroPopupFrameCloseButton:Hide() end
        if MacroPopupFramePortrait then MacroPopupFramePortrait:Hide() end

        -- DFUI 风格背景。MacroPopupFrame 297x378，无 portrait 凸出，留白比主面板小
        -- 右留白 10（避开 ScrollBar，ScrollBar 约在距右 23~39px 内），底留白 30（容 Okay/Cancel 22 高 + 内边距）
        local popupBg = DFUI.CreatePaperDollFrame("DFUI_MacroPopupBg", MacroPopupFrame, 290, 340, 2)
        popupBg:SetPoint("TOPLEFT", MacroPopupFrame, "TOPLEFT", 12, -12)
        popupBg:SetPoint("BOTTOMRIGHT", MacroPopupFrame, "BOTTOMRIGHT", -10, 30)
        popupBg:SetFrameLevel(MacroPopupFrame:GetFrameLevel() - 1)
        popupBg.Bg:SetDrawLayer("BACKGROUND", -5)

        -- 红色关闭按钮
        local closeBtn = DFUI.CreateRedButton(popupBg, "close", function() MacroPopupFrame:Hide() end)
        closeBtn:SetPoint("TOPRIGHT", popupBg, "TOPRIGHT", 0, -1)
        closeBtn:SetWidth(20)
        closeBtn:SetHeight(20)
        closeBtn:SetFrameLevel(popupBg:GetFrameLevel() + 3)

        -- 高亮 icon 按钮（1.12 NUM_MACRO_ICONS_SHOWN = 20）
        local hlTex = TEX .. "actionbars\\uiactionbariconframehighlight.tga"
        local numIcons = NUM_MACRO_ICONS_SHOWN or 20
        for i = 1, numIcons do
            local button = getglobal("MacroPopupButton" .. i)
            if button then
                local icon = getglobal("MacroPopupButton" .. i .. "Icon")
                if icon then
                    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
                    highlight:SetPoint("TOPLEFT", icon, "TOPLEFT", -6, 6)
                    highlight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 6, -6)
                    highlight:SetTexture(hlTex)
                    highlight:SetBlendMode("ADD")
                    button:SetHighlightTexture(highlight)
                end
            end
        end

        -- 保险：把交互控件 FrameLevel 拉到 popupBg 之上
        local boostLvl = MacroPopupFrame:GetFrameLevel() + 5
        local boostList = {
            MacroPopupOkayButton, MacroPopupCancelButton,
            MacroPopupEditBox, MacroPopupScrollFrame, MacroPopupScrollFrameScrollBar,
        }
        for i = 1, table.getn(boostList) do
            local w = boostList[i]
            if w and w.SetFrameLevel then w:SetFrameLevel(boostLvl) end
        end

        HookScript(MacroPopupFrame, "OnShow", function() popupBg:Show() end)
        HookScript(MacroPopupFrame, "OnHide", function() popupBg:Hide() end)
        if not MacroPopupFrame:IsShown() then popupBg:Hide() end
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function()
        if arg1 == "Blizzard_MacroUI" then
            SkinMacroFrame()
        end
    end)

    if MacroFrame then
        SkinMacroFrame()
    end

    local callbacks = {}
    DFUI:NewCallbacks("Macros", callbacks)
end)
