setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("KeyBinding", {
    enabled = {true},
})

DFUI:NewMod("KeyBinding", 5, function()
    local skinned = false

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

    local function SkinKeyBindingFrame()
        if skinned or not KeyBindingFrame then return end
        skinned = true

        HideBlizzardTextures(KeyBindingFrame)

        if KeyBindingFrameCloseButton then KeyBindingFrameCloseButton:Hide() end

        local customBg = DFUI.CreatePaperDollFrame("DFUI_KeyBindingBg", KeyBindingFrame, 384, 512, 2)
        customBg:SetPoint("TOPLEFT", KeyBindingFrame, "TOPLEFT", 0, -8)
        customBg:SetPoint("BOTTOMRIGHT", KeyBindingFrame, "BOTTOMRIGHT", -32, 10)
        customBg:SetFrameLevel(KeyBindingFrame:GetFrameLevel() - 1)
        customBg.Bg:SetDrawLayer("BACKGROUND", -5)

        local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(KeyBindingFrame) end)
        closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

        -- 重定位标题文字到边框内
        if KeyBindingFrameHeaderText then
            KeyBindingFrameHeaderText:ClearAllPoints()
            KeyBindingFrameHeaderText:SetPoint("TOP", customBg, "TOP", 0, -5)
        end

        -- 重定位角色专用按键设置 checkbox，紧跟标题右侧
        if KeyBindingFrameCharacterButton and KeyBindingFrameHeaderText then
            KeyBindingFrameCharacterButton:ClearAllPoints()
            KeyBindingFrameCharacterButton:SetPoint("LEFT", KeyBindingFrameHeaderText, "RIGHT", 15, 0)
        end

        CenterFrame(KeyBindingFrame)
        HookScript(KeyBindingFrame, "OnShow", function()
            customBg:Show()
        end)
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function()
        if arg1 == "Blizzard_BindingUI" then
            SkinKeyBindingFrame()
        end
    end)

    if KeyBindingFrame then
        SkinKeyBindingFrame()
    end

    local callbacks = {}
    DFUI:NewCallbacks("KeyBinding", callbacks)
end)
