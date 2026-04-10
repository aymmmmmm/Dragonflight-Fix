setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("OpenMail", {
    enabled = {true},
})

DFUI:NewMod("OpenMail", 5, function()
    -- 隐藏所有暴雪纹理
    local regions = {OpenMailFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            region:Hide()
        end
    end

    if OpenMailCloseButton then OpenMailCloseButton:Hide() end

    local customBg = DFUI.CreatePaperDollFrame("DFUI_OpenMailBg", OpenMailFrame, 384, 512, 2)
    customBg:SetPoint("TOPLEFT", OpenMailFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", OpenMailFrame, "BOTTOMRIGHT", -32, 75)
    customBg:SetFrameLevel(OpenMailFrame:GetFrameLevel())
    customBg.Bg:SetDrawLayer("BACKGROUND", -1)

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(OpenMailFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    HookScript(OpenMailFrame, "OnShow", function()
        customBg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("OpenMail", callbacks)
end)
