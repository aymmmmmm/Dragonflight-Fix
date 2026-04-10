setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Mail", {
    enabled = {true},
})

DFUI:NewMod("Mail", 5, function()
    local regions = {MailFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and (string.find(texture, "UI%-ItemText") or string.find(texture, "UI%-Spellbook") or string.find(texture, "UI%-ClassTrainer")) then
                region:Hide()
            end
        end
    end

    MailFrameTab1:Hide()
    MailFrameTab2:Hide()
    InboxCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_MailBg", MailFrame, 384, 512, 1)
    customBg:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", MailFrame, "BOTTOMRIGHT", -32, 75)
    customBg.Bg:SetDrawLayer("BACKGROUND", -1)

    -- 邮件图标放入头像框
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and string.find(texture, "Mail%-Icon") then
                region:SetParent(customBg)
                region:SetDrawLayer("BORDER", 0)
                region:ClearAllPoints()
                region:SetPoint("CENTER", customBg, "TOPLEFT", 27, -23)
                region:SetWidth(54)
                region:SetHeight(54)
                break
            end
        end
    end

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(MailFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    customBg:AddTab("收件箱", function()
        MailFrameTab_OnClick(1)
    end, 70)

    customBg:AddTab("发信", function()
        MailFrameTab_OnClick(2)
    end, 70)

    HookScript(MailFrame, "OnShow", function()
        customBg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("Mail", callbacks)
end)
