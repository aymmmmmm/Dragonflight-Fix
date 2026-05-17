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

    -- 居中"交易"标题（与拾取窗口"物品"标题一致风格）
    -- 注：左右两块 paperdoll frame 的金属角在 TradeFrame 顶部完全覆盖，
    -- 用独立 titleHolder 提高 FrameLevel 确保 title 显示在金属之上、可读。
    local titleHolder = CreateFrame("Frame", nil, TradeFrame)
    titleHolder:SetAllPoints(TradeFrame)
    titleHolder:SetFrameLevel(rightBg:GetFrameLevel() + 5)

    local title = titleHolder:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetText("交易")
    title:SetTextColor(0.96875, 0.8984375, 0.578125)
    title:SetPoint("TOP", TradeFrame, "TOP", 0, -7)

    -- 接收方金币显示底（羊皮纸 inset 风格，替代原黑底+灰描边）
    local recipientMoneyBg = CreateFrame("Frame", nil, rightBg)
    recipientMoneyBg:SetPoint("TOPLEFT", rightBg, "TOPLEFT", 10, -75)
    recipientMoneyBg:SetPoint("BOTTOMRIGHT", rightBg, "TOPRIGHT", -30, -95)
    recipientMoneyBg:SetFrameLevel(rightBg:GetFrameLevel() + 2)

    local moneyInset = recipientMoneyBg:CreateTexture(nil, "BACKGROUND")
    moneyInset:SetTexture("Interface\\Buttons\\WHITE8X8")
    moneyInset:SetAllPoints(recipientMoneyBg)
    moneyInset:SetVertexColor(0.08, 0.05, 0.02, 0.55)

    -- recipientMoneyBg 双锚定宽度 ≈ 185(rightBg) - 10 - 30 = 145px
    DFUI.tools.GradientLine(recipientMoneyBg, "TOP", -1, 2, 140)
    DFUI.tools.GradientLine(recipientMoneyBg, "BOTTOM", 1, 2, 140)

    -- 交易槽位品质边框（仿拾取窗口，按物品品质切 slot_*.tga 纹理）
    local PROF_TEX = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\panels\\df\\professions\\"
    local SLOT_TEX_BY_QUALITY = {
        [0] = PROF_TEX .. "slot_neutral.tga",
        [1] = PROF_TEX .. "slot_neutral.tga",
        [2] = PROF_TEX .. "slot_green.tga",
        [3] = PROF_TEX .. "slot_blue.tga",
        [4] = PROF_TEX .. "slot_epic.tga",
        [5] = PROF_TEX .. "slot_legendary.tga",
    }
    local MAX_TRADE_SLOTS = 7

    local function GetSlotButton(prefix, i)
        return getglobal(prefix .. i .. "ItemButton") or getglobal(prefix .. i)
    end

    local function AttachSlotBorder(btn)
        if not btn or btn.dfuiBorder then return end
        -- 清除 vanilla ItemButton 的灰底凹槽 NormalTexture（pfUI 同款处理）
        -- 保留 IconTexture，让 slot_*.tga 透明中心区干净透出物品图标
        if btn.SetNormalTexture then btn:SetNormalTexture("") end
        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetTexture(PROF_TEX .. "slot_neutral.tga")
        border:SetTexCoord(12/64, 51/64, 12/64, 51/64)
        border:SetAllPoints(btn)
        btn.dfuiBorder = border
    end

    local function UpdateSlotBorder(btn, quality)
        if not btn or not btn.dfuiBorder then return end
        local q = (quality and quality >= 0) and quality or 1
        btn.dfuiBorder:SetTexture(SLOT_TEX_BY_QUALITY[q] or SLOT_TEX_BY_QUALITY[1])
    end

    for i = 1, MAX_TRADE_SLOTS do
        AttachSlotBorder(GetSlotButton("TradePlayerItem", i))
        AttachSlotBorder(GetSlotButton("TradeRecipientItem", i))
    end

    local slotWatcher = CreateFrame("Frame")
    slotWatcher:RegisterEvent("TRADE_SHOW")
    slotWatcher:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
    slotWatcher:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
    slotWatcher:SetScript("OnEvent", function()
        if event == "TRADE_SHOW" or event == "TRADE_PLAYER_ITEM_CHANGED" then
            for i = 1, MAX_TRADE_SLOTS do
                local _, _, _, quality = GetTradePlayerItemInfo(i)
                UpdateSlotBorder(GetSlotButton("TradePlayerItem", i), quality)
            end
        end
        if event == "TRADE_SHOW" or event == "TRADE_TARGET_ITEM_CHANGED" then
            for i = 1, MAX_TRADE_SLOTS do
                local _, _, _, quality = GetTradeTargetItemInfo(i)
                UpdateSlotBorder(GetSlotButton("TradeRecipientItem", i), quality)
            end
        end
    end)

    CenterFrame(TradeFrame)
    HookScript(TradeFrame, "OnShow", function()
        leftBg:Show()
        rightBg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("Trade", callbacks)
end)
