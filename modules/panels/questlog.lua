setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

DFUI:NewDefaults("QuestLog", {
    enabled = {true},
})

DFUI:NewMod("QuestLog", 5, function()
    local regions = {QuestLogFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and string.find(texture, "QuestLog") and not string.find(texture, "Highlight") and not string.find(texture, "Check") then
                region:Hide()
            end
        end
    end

    QuestLogFrameCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_QuestLogBg", QuestLogFrame, 384, 400, 1)
    customBg:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", QuestLogFrame, "BOTTOMRIGHT", -91, 50)
    customBg:SetFrameLevel(QuestLogFrame:GetFrameLevel() - 1)

    CenterFrame(QuestLogFrame)
    HookScript(QuestLogFrame, "OnShow", function()
        customBg:Show()
    end)

    local topWood = customBg:CreateTexture(nil, "BORDER")
    topWood:SetTexture(TEX .. "panels\\spellbook_top_wood.blp")
    topWood:SetPoint("TOPLEFT", customBg, "TOPLEFT", 0, -10)
    topWood:SetPoint("RIGHT", customBg, "RIGHT", 0, -60)
    topWood:SetWidth(customBg:GetWidth() - 10)
    topWood:SetHeight(64)

    local bookIcon = customBg:CreateTexture(nil, "ARTWORK")
    bookIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon")
    bookIcon:SetPoint("TOPLEFT", customBg, "TOPLEFT", -3, 6)
    bookIcon:SetWidth(56)
    bookIcon:SetHeight(56)

    local leftBg = customBg:CreateTexture(nil, "ARTWORK")
    leftBg:SetTexture(TEX .. "panels\\questlog_left_bg.blp")
    leftBg:SetPoint("TOPLEFT", customBg, "TOPLEFT", 1, -60)
    leftBg:SetPoint("BOTTOM", customBg, "BOTTOM", 0, -310)
    leftBg:SetPoint("RIGHT", customBg, "CENTER", 0, 0)

    local rightBg = customBg:CreateTexture(nil, "ARTWORK")
    rightBg:SetTexture(TEX .. "panels\\questlog_right_bg.blp")
    rightBg:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", -25, -60)
    rightBg:SetPoint("BOTTOM", customBg, "BOTTOM", 0, -173)
    rightBg:SetPoint("LEFT", customBg, "CENTER", 0, 0)

    local bookmark = customBg:CreateTexture(nil, "OVERLAY")
    bookmark:SetTexture(TEX .. "panels\\spellbook_bookmark.blp")
    bookmark:SetPoint("TOP", customBg, "TOP", 7, -55)
    bookmark:SetWidth(50)
    bookmark:SetHeight(400)

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(QuestLogFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    -- 物品栏高亮
    local highlightTex = TEX .. "actionbars\\uiactionbariconframehighlight.tga"
    for i = 1, 10 do
        local item = getglobal("QuestLogItem" .. i)
        if item then
            local icon = getglobal("QuestLogItem" .. i .. "IconTexture")
            if icon then
                local hl = item:CreateTexture(nil, "HIGHLIGHT")
                hl:SetPoint("TOPLEFT", icon, "TOPLEFT", -6, 6)
                hl:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 6, -6)
                hl:SetTexture(highlightTex)
                hl:SetBlendMode("ADD")
                item:SetHighlightTexture(hl)
            end
        end
    end

    local callbacks = {}
    DFUI:NewCallbacks("QuestLog", callbacks)
end)
