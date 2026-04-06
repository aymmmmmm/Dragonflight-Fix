setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Trade", {
    enabled = {true},
})

DFUI:NewMod("Trade", 5, function()
    local regions = {TradeFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and string.find(texture, "UI%-TradeFrame") then
                region:Hide()
            end
        end
    end

    TradeFrameCloseButton:Hide()

    local leftBg = DFUI.CreatePaperDollFrame("DFUI_TradeLeftBg", TradeFrame, 185, 460, 1)
    leftBg:SetPoint("TOPLEFT", TradeFrame, "TOPLEFT", 2, 0)
    leftBg:SetFrameLevel(TradeFrame:GetFrameLevel() - 1)
    leftBg.Bg:SetDrawLayer("BACKGROUND", -1)

    local rightBg = DFUI.CreatePaperDollFrame("DFUI_TradeRightBg", TradeFrame, 185, 460, 1)
    rightBg:SetPoint("TOPRIGHT", TradeFrame, "TOPRIGHT", -15, 0)
    rightBg:SetFrameLevel(TradeFrame:GetFrameLevel())
    rightBg.Bg:SetDrawLayer("BACKGROUND", -1)

    TradeFramePlayerPortrait:ClearAllPoints()
    TradeFramePlayerPortrait:SetPoint("TOPLEFT", leftBg, "TOPLEFT", -5, 7)
    TradeFramePlayerPortrait:SetParent(leftBg)
    TradeFramePlayerPortrait:SetDrawLayer("BORDER", 0)

    TradeFrameRecipientPortrait:ClearAllPoints()
    TradeFrameRecipientPortrait:SetPoint("TOPLEFT", rightBg, "TOPLEFT", -5, 7)
    TradeFrameRecipientPortrait:SetParent(rightBg)
    TradeFrameRecipientPortrait:SetDrawLayer("BORDER", 0)

    TradeFramePlayerNameText:ClearAllPoints()
    TradeFramePlayerNameText:SetPoint("TOPLEFT", TradeFrame, "TOPLEFT", 75, -7)

    TradeFrameRecipientNameText:ClearAllPoints()
    TradeFrameRecipientNameText:SetPoint("TOPLEFT", TradeFrame, "TOPLEFT", 245, -7)

    local closeButton = DFUI.CreateRedButton(rightBg, "close", function() HideUIPanel(TradeFrame) end)
    closeButton:SetPoint("TOPRIGHT", rightBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(rightBg:GetFrameLevel() + 3)

    local recipientMoneyBg = CreateFrame("Frame", nil, rightBg)
    recipientMoneyBg:SetPoint("TOPLEFT", rightBg, "TOPLEFT", 10, -75)
    recipientMoneyBg:SetPoint("BOTTOMRIGHT", rightBg, "TOPRIGHT", -30, -95)
    recipientMoneyBg:SetFrameLevel(rightBg:GetFrameLevel() + 2)
    recipientMoneyBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 2,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    recipientMoneyBg:SetBackdropColor(0, 0, 0, 0.5)
    recipientMoneyBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    HookScript(TradeFrame, "OnShow", function()
        leftBg:Show()
        rightBg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("Trade", callbacks)
end)
