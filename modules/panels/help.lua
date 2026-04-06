setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Help", {
    enabled = {true},
})

DFUI:NewMod("Help", 5, function()
    local regions = {HelpFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            region:Hide()
        end
    end

    HelpFrameHeader:Hide()
    HelpFrameCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_HelpBg", HelpFrame, 640, 512, 2)
    customBg:SetPoint("TOPLEFT", HelpFrame, "TOPLEFT", 0, 0)
    customBg:SetPoint("BOTTOMRIGHT", HelpFrame, "BOTTOMRIGHT", -50, 15)
    customBg:SetFrameLevel(HelpFrame:GetFrameLevel() + 1)

    local helpBg = customBg:CreateTexture(nil, "BORDER")
    helpBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    helpBg:SetPoint("TOPLEFT", customBg, "TOPLEFT", 3, -20)
    helpBg:SetPoint("BOTTOMRIGHT", customBg, "BOTTOMRIGHT", -3, 3)
    helpBg:SetVertexColor(0, 0, 0, 0.3)

    local title = customBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", customBg, "TOP", 0, -6)
    title:SetText("帮助")

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(HelpFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    HookScript(HelpFrame, "OnShow", function()
        customBg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("Help", callbacks)
end)
