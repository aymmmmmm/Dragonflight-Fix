setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("DressUp", {
    enabled = {true},
})

DFUI:NewMod("DressUp", 5, function()
    local regions = {DressUpFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and (string.find(texture, "UI%-Character") or string.find(texture, "SkillFrame")) then
                region:Hide()
            end
        end
    end

    DressUpFrameCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_DressUpBg", DressUpFrame, 384, 512, 1)
    customBg:SetPoint("TOPLEFT", DressUpFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", DressUpFrame, "BOTTOMRIGHT", -32, 75)
    customBg:SetFrameLevel(DressUpFrame:GetFrameLevel() - 1)
    customBg.Bg:SetDrawLayer("BACKGROUND", -1)

    DressUpFramePortrait:SetParent(customBg)
    DressUpFramePortrait:SetDrawLayer("BORDER", 0)

    DressUpFrameDescriptionText:SetParent(customBg)
    DressUpFrameDescriptionText:SetDrawLayer("OVERLAY", 0)

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(DressUpFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    CenterFrame(DressUpFrame)
    HookScript(DressUpFrame, "OnShow", function()
        customBg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("DressUp", callbacks)
end)
