setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Merchant", {
    enabled = {true},
})

DFUI:NewMod("Merchant", 5, function()
    local regions = {MerchantFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and string.find(texture, "Merchant") then
                region:Hide()
            end
        end
    end

    MerchantFrameTab1:Hide()
    MerchantFrameTab2:Hide()
    MerchantFrameCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_MerchantBg", MerchantFrame, 384, 512, 1)
    customBg:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -32, 55)
    customBg:SetFrameLevel(MerchantFrame:GetFrameLevel() - 1)

    MerchantFramePortrait:SetParent(customBg)
    MerchantFramePortrait:SetDrawLayer("BORDER", 0)
    MerchantFramePortrait:ClearAllPoints()
    MerchantFramePortrait:SetPoint("TOPLEFT", customBg, "TOPLEFT", -4, 8)

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(MerchantFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    customBg:AddTab("商人", function()
        PanelTemplates_SetTab(MerchantFrame, 1)
        MerchantFrame_Update()
    end, 70)

    customBg:AddTab("回购", function()
        PanelTemplates_SetTab(MerchantFrame, 2)
        MerchantFrame_Update()
    end, 70)

    CenterFrame(MerchantFrame)
    HookScript(MerchantFrame, "OnShow", function()
        customBg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("Merchant", callbacks)
end)
