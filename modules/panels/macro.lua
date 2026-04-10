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

    local function SkinMacroFrame()
        if skinned or not MacroFrame then return end
        skinned = true

        HideBlizzardTextures(MacroFrame)

        if MacroFrameCloseButton then MacroFrameCloseButton:Hide() end
        -- Vanilla 可能用单数或复数 Tab 名
        if MacroFrameTab then MacroFrameTab:Hide() end
        if MacroFrameTab1 then MacroFrameTab1:Hide() end
        if MacroFrameTab2 then MacroFrameTab2:Hide() end

        local customBg = DFUI.CreatePaperDollFrame("DFUI_MacroBg", MacroFrame, 384, 512, 2)
        customBg:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 12, -12)
        customBg:SetPoint("BOTTOMRIGHT", MacroFrame, "BOTTOMRIGHT", -32, 75)
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

        HookScript(MacroFrame, "OnShow", function()
            customBg:Show()
        end)
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
