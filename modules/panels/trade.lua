setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Trade", {
    enabled = {true},
})

DFUI:NewMod("Trade", 5, function()
    local TEX = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\"
    local MAX_SLOTS = MAX_TRADE_ITEMS or 7   -- 1.12=7（第7槽=附魔/"不会被交易"槽）

    ---------------------------------------------------------------------------
    -- 1. 隐藏 vanilla 原生边框纹理
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- 2. 单框金属外壳（拾取同款 frameStyle=2 纯金属角 + 岩石背景）
    --    双锚覆盖整个 TradeFrame，FrameLevel-1 垫底；边框纹理锚四角自适应
    ---------------------------------------------------------------------------
    local bg = DFUI.CreatePaperDollFrame("DFUI_TradeBg", TradeFrame, 100, 100, 2)
    bg:ClearAllPoints()
    bg:SetPoint("TOPLEFT", TradeFrame, "TOPLEFT", 0, 0)
    bg:SetPoint("BOTTOMRIGHT", TradeFrame, "BOTTOMRIGHT", 0, 0)
    bg:SetFrameLevel(TradeFrame:GetFrameLevel() - 1)
    bg.Bg:SetDrawLayer("BACKGROUND", -1)

    ---------------------------------------------------------------------------
    -- 3. 中间竖分隔线（复用拾取边框竖边素材 UIFrameMetalVertical2x）
    ---------------------------------------------------------------------------
    local divider = bg:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(TEX .. "interface\\UIFrameMetalVertical2x.BLP")
    divider:SetTexCoord(0.00195312, 0.294922, 0.0, 1.0)
    divider:SetWidth(16)
    divider:SetPoint("TOP", bg, "TOP", 0, -24)
    divider:SetPoint("BOTTOM", bg, "BOTTOM", 0, 8)

    ---------------------------------------------------------------------------
    -- 4. 头像：锚各自首槽正上方（自动对齐两栏 = 参考图布局）
    --    向上留足空间放金环 + 名字(右上) + 金币(右下)。
    --    不 reparent —— 保持 parent=TradeFrame，其 FrameLevel 高于 bg，
    --    整体压在 bg 金属边框(ARTWORK/OVERLAY)之上，避免被角/边盖住。
    ---------------------------------------------------------------------------
    local PORTRAIT_SIZE = 50

    -- 对齐参考图(交易.png)：头像靠左/中、金环顶边贴框顶（接近 vanilla 原 x=7/183）
    TradeFramePlayerPortrait:SetWidth(PORTRAIT_SIZE)
    TradeFramePlayerPortrait:SetHeight(PORTRAIT_SIZE)
    TradeFramePlayerPortrait:SetDrawLayer("BORDER", 0)
    TradeFramePlayerPortrait:ClearAllPoints()
    TradeFramePlayerPortrait:SetPoint("BOTTOMLEFT", TradePlayerItem1, "TOPLEFT", -12, 38)

    TradeFrameRecipientPortrait:SetWidth(PORTRAIT_SIZE)
    TradeFrameRecipientPortrait:SetHeight(PORTRAIT_SIZE)
    TradeFrameRecipientPortrait:SetDrawLayer("BORDER", 0)
    TradeFrameRecipientPortrait:ClearAllPoints()
    TradeFrameRecipientPortrait:SetPoint("BOTTOMLEFT", TradeRecipientItem1, "TOPLEFT", -12, 38)

    ---------------------------------------------------------------------------
    -- 5. 名字：锚各自头像右上（金币在头像正下方，名字在右上）
    ---------------------------------------------------------------------------
    TradeFramePlayerNameText:ClearAllPoints()
    TradeFramePlayerNameText:SetPoint("TOPLEFT", TradeFramePlayerPortrait, "TOPRIGHT", 12, -2)

    TradeFrameRecipientNameText:ClearAllPoints()
    TradeFrameRecipientNameText:SetPoint("TOPLEFT", TradeFrameRecipientPortrait, "TOPRIGHT", 12, -2)

    ---------------------------------------------------------------------------
    -- 5b. 金币：左右各加 DF 凹底框（素材框），金币框叠其上 —— 视觉对称
    --     左 TradePlayerInputMoneyFrame=输入格(永显)；右 TradeRecipientMoneyFrame
    --     =SmallMoneyFrame(出钱才显)。框始终在 → 空着也对称；金币行为保持 vanilla。
    --     复用 DFUI.CreateRetailInset(大理石底+边+角，已有 TGA，无新素材)。
    --     -14：下移到金环底缘以下，避免环下半弧压住框（环比头像大 15px）。
    ---------------------------------------------------------------------------
    local MONEY_BOX_W, MONEY_BOX_H = 116, 24
    local function CreateMoneyBox(portrait, moneyFrame)
        if not moneyFrame then return end
        local box = CreateFrame("Frame", nil, bg)
        box:SetWidth(MONEY_BOX_W)
        box:SetHeight(MONEY_BOX_H)
        box:SetPoint("TOPLEFT", portrait, "BOTTOMLEFT", 8, -14)
        box:SetFrameLevel(bg:GetFrameLevel() + 2)
        DFUI.CreateRetailInset(box, { anchors = {0, 0, 0, 0}, followFrame = TradeFrame })
        moneyFrame:ClearAllPoints()
        moneyFrame:SetPoint("LEFT", box, "LEFT", 6, 0)
        -- 金币框 parent 仍 TradeFrame（保 vanilla 金钱逻辑），抬帧层压在 inset 大理石底之上
        if moneyFrame.SetFrameLevel then moneyFrame:SetFrameLevel(box:GetFrameLevel() + 8) end
        return box
    end
    CreateMoneyBox(TradeFramePlayerPortrait,    TradePlayerInputMoneyFrame)
    CreateMoneyBox(TradeFrameRecipientPortrait, TradeRecipientMoneyFrame)

    ---------------------------------------------------------------------------
    -- 6. 高层覆盖框 titleHolder（金环挂这层确保盖住头像方角；
    --    参考图(交易.png)顶部无"交易"标题文字 → 已移除标题，仅保留载体框）
    ---------------------------------------------------------------------------
    local titleHolder = CreateFrame("Frame", nil, TradeFrame)
    titleHolder:SetAllPoints(TradeFrame)
    titleHolder:SetFrameLevel(TradeFrame:GetFrameLevel() + 5)

    ---------------------------------------------------------------------------
    -- 6b. 头像金色圆环（DF retail playerframe portraitring-large 抠图整图）
    --     绘制在 titleHolder(高 FrameLevel) 之上，盖住方形头像四角；
    --     环略大于头像，内孔透出脸部，SetTexture 整张 + 居中（不切片）。
    ---------------------------------------------------------------------------
    local RING_TEX = TEX .. "unitframes\\df_portrait_ring.tga"
    local RING_SIZE = 80
    local function AddPortraitRing(portrait)
        local ring = titleHolder:CreateTexture(nil, "OVERLAY")
        ring:SetTexture(RING_TEX)
        ring:SetWidth(RING_SIZE)
        ring:SetHeight(RING_SIZE)
        ring:SetPoint("CENTER", portrait, "CENTER", 0, 0)
        return ring
    end
    AddPortraitRing(TradeFramePlayerPortrait)
    AddPortraitRing(TradeFrameRecipientPortrait)

    ---------------------------------------------------------------------------
    -- 7. 关闭按钮（对齐拾取窗口 21x21 红钮）
    ---------------------------------------------------------------------------
    local closeButton = DFUI.CreateRedButton(bg, "close", function() HideUIPanel(TradeFrame) end)
    closeButton:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(21)
    closeButton:SetHeight(21)
    closeButton:SetFrameLevel(bg:GetFrameLevel() + 5)

    ---------------------------------------------------------------------------
    -- 8. 物品槽位品质边框（仿拾取窗口，按物品品质切 slot_*.tga 纹理）
    ---------------------------------------------------------------------------
    local PROF_TEX = TEX .. "panels\\df\\professions\\"
    local SLOT_TEX_BY_QUALITY = {
        [0] = PROF_TEX .. "slot_neutral.tga",
        [1] = PROF_TEX .. "slot_neutral.tga",
        [2] = PROF_TEX .. "slot_green.tga",
        [3] = PROF_TEX .. "slot_blue.tga",
        [4] = PROF_TEX .. "slot_epic.tga",
        [5] = PROF_TEX .. "slot_legendary.tga",
    }

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

    for i = 1, MAX_SLOTS do
        AttachSlotBorder(GetSlotButton("TradePlayerItem", i))
        AttachSlotBorder(GetSlotButton("TradeRecipientItem", i))
    end

    local slotWatcher = CreateFrame("Frame")
    slotWatcher:RegisterEvent("TRADE_SHOW")
    slotWatcher:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
    slotWatcher:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
    slotWatcher:SetScript("OnEvent", function()
        if event == "TRADE_SHOW" or event == "TRADE_PLAYER_ITEM_CHANGED" then
            for i = 1, MAX_SLOTS do
                local _, _, _, quality = GetTradePlayerItemInfo(i)
                UpdateSlotBorder(GetSlotButton("TradePlayerItem", i), quality)
            end
        end
        if event == "TRADE_SHOW" or event == "TRADE_TARGET_ITEM_CHANGED" then
            for i = 1, MAX_SLOTS do
                local _, _, _, quality = GetTradeTargetItemInfo(i)
                UpdateSlotBorder(GetSlotButton("TradeRecipientItem", i), quality)
            end
        end
    end)

    ---------------------------------------------------------------------------
    -- 9. 底部"交易/取消"按钮换皮（DF 金属文字按钮，对齐参考图）
    --    vanilla 按钮保活转发：alpha0 + Click 转发 + IsEnabled 镜像
    ---------------------------------------------------------------------------
    local function ReskinActionButton(vanillaBtn, width, anchorPoint, relTo, relPoint, x, y)
        if not vanillaBtn or not DFUI.CreateActionButton then return end
        local skin = DFUI.CreateActionButton(bg, width, vanillaBtn:GetText() or "", function()
            local en = vanillaBtn:IsEnabled()
            if en and en ~= 0 then vanillaBtn:Click() end
        end)
        skin:ClearAllPoints()
        skin:SetPoint(anchorPoint, relTo, relPoint, x, y)
        -- vanilla 按钮保活（隐形）维持安全动作链
        vanillaBtn:SetAlpha(0)
        vanillaBtn:EnableMouse(false)
        -- 启用态镜像（vanilla 在不可交易时禁用 Trade 按钮），仅状态变化时刷新
        local watcher = CreateFrame("Frame", nil, bg)
        watcher:SetScript("OnUpdate", function()
            if not TradeFrame:IsShown() then return end
            local en = vanillaBtn:IsEnabled()
            en = (en and en ~= 0) and true or false
            if en ~= skin._dfEnabled then
                skin._dfEnabled = en
                skin:SetEnabledDF(en)
            end
        end)
        return skin
    end

    local cancelSkin = ReskinActionButton(TradeFrameCancelButton, 80, "BOTTOMRIGHT", bg, "BOTTOMRIGHT", -16, 14)
    if cancelSkin then
        ReskinActionButton(TradeFrameTradeButton, 80, "RIGHT", cancelSkin, "LEFT", -6, 0)
    end

    ---------------------------------------------------------------------------
    CenterFrame(TradeFrame)
    HookScript(TradeFrame, "OnShow", function()
        bg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("Trade", callbacks)
end)
