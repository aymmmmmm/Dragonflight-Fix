setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

DFUI:NewDefaults("Bank", {
    enabled = {true},
})

DFUI:NewMod("Bank", 5, function()
    local regions = {BankFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" and region ~= BankPortraitTexture then
            region:Hide()
        end
    end

    BankCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_BankBg", BankFrame, 370, 435, 1)
    customBg:SetPoint("TOPLEFT", BankFrame, "TOPLEFT", 5, 0)
    customBg:SetFrameLevel(BankFrame:GetFrameLevel() - 1)
    customBg.Bg:SetDrawLayer("BACKGROUND", -1)

    CenterFrame(BankFrame)

    BankPortraitTexture:SetParent(customBg)
    BankPortraitTexture:ClearAllPoints()
    BankPortraitTexture:SetPoint("TOPLEFT", customBg, "TOPLEFT", -5, 7)
    BankPortraitTexture:SetDrawLayer("BORDER", 0)

    BankFrameTitleText:ClearAllPoints()
    BankFrameTitleText:SetPoint("CENTER", customBg, "TOP", 0, -10)

    local borderTex = TEX .. "actionbars\\border.blp"
    local highlightTex = TEX .. "actionbars\\HDActionBarBtn.tga"

    for i = 1, 24 do
        local btn = getglobal("BankFrameItem" .. i)
        if btn then
            local icon = getglobal("BankFrameItem" .. i .. "IconTexture")
            if icon then
                btn.bg = btn:CreateTexture(nil, "BACKGROUND")
                btn.bg:SetTexture(highlightTex)
                btn.bg:SetAllPoints(btn)
                btn.bg:SetVertexColor(1, 1, 1, 1)
                icon:SetDrawLayer("BORDER")

                local border = btn:CreateTexture(nil, "ARTWORK")
                border:SetTexture(borderTex)
                border:SetAllPoints(btn)

                local hl = btn:CreateTexture(nil, "HIGHLIGHT")
                hl:SetTexture(TEX .. "actionbars\\uiactionbariconframehighlight.tga")
                hl:SetPoint("TOPLEFT", btn, "TOPLEFT", -4, 4)
                hl:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 4, -4)
            end
        end
    end

    for i = 1, 6 do
        local btn = getglobal("BankFrameBag" .. i)
        if btn then
            local icon = getglobal("BankFrameBag" .. i .. "IconTexture")
            if icon then
                icon:SetDrawLayer("BORDER")

                local border = btn:CreateTexture(nil, "ARTWORK")
                border:SetTexture(borderTex)
                border:SetAllPoints(btn)

                local hl = btn:CreateTexture(nil, "HIGHLIGHT")
                hl:SetTexture(TEX .. "actionbars\\uiactionbariconframehighlight.tga")
                hl:SetPoint("TOPLEFT", btn, "TOPLEFT", -4, 4)
                hl:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 4, -4)
            end
        end
    end

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() CloseBankFrame() end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    local callbacks = {}
    DFUI:NewCallbacks("Bank", callbacks)
end)
