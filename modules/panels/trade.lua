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
    local PORTRAIT_SIZE = 58            -- 放大填满金环内孔（环 80，内孔约 60；实测可调）
    local PORTRAIT_ZOOM = 0.10         -- SetTexCoord 裁掉脸贴图四周黑边（zoom in，实测可调）
    local ROCK_TEX = TEX .. "interface\\UI-Background-Rock.blp"

    -- 头像后垫暗岩石底（金属矿质感）：脸没填满内孔处露岩石而非黑；
    -- 放 bg 层（FrameLevel 低于 portrait）→ 垫在脸之下、面板岩石底之上
    local function AddPortraitRock(portrait)
        local rock = bg:CreateTexture(nil, "ARTWORK")
        rock:SetTexture(ROCK_TEX)
        rock:SetWidth(PORTRAIT_SIZE)
        rock:SetHeight(PORTRAIT_SIZE)
        rock:SetPoint("CENTER", portrait, "CENTER", 0, 0)
        return rock
    end

    -- 头像：放大填内孔 + 裁边去黑 + 垫岩石底（对齐 debug 反馈：消黑边、缝隙填金属矿）
    local function SetupPortrait(portrait, anchorItem)
        portrait:SetWidth(PORTRAIT_SIZE)
        portrait:SetHeight(PORTRAIT_SIZE)
        portrait:SetDrawLayer("BORDER", 0)
        portrait:SetTexCoord(PORTRAIT_ZOOM, 1 - PORTRAIT_ZOOM, PORTRAIT_ZOOM, 1 - PORTRAIT_ZOOM)
        portrait:ClearAllPoints()
        portrait:SetPoint("BOTTOMLEFT", anchorItem, "TOPLEFT", -12, 38)
        AddPortraitRock(portrait)
    end
    SetupPortrait(TradeFramePlayerPortrait,    TradePlayerItem1)
    SetupPortrait(TradeFrameRecipientPortrait, TradeRecipientItem1)

    -- vanilla TradeFrame_Update 每次刷新调 SetPortraitTexture，会把 TexCoord 重置回 (0,1,0,1)，
    -- 裁边随之失效黑边重现 → post-hook(append=true) 在其后重设裁边，保持去黑边持续生效
    hooksecurefunc("TradeFrame_Update", function()
        TradeFramePlayerPortrait:SetTexCoord(PORTRAIT_ZOOM, 1 - PORTRAIT_ZOOM, PORTRAIT_ZOOM, 1 - PORTRAIT_ZOOM)
        TradeFrameRecipientPortrait:SetTexCoord(PORTRAIT_ZOOM, 1 - PORTRAIT_ZOOM, PORTRAIT_ZOOM, 1 - PORTRAIT_ZOOM)
    end, true)

    ---------------------------------------------------------------------------
    -- 5. 名字：锚各自头像右上（金币在头像正下方，名字在右上）
    ---------------------------------------------------------------------------
    TradeFramePlayerNameText:ClearAllPoints()
    TradeFramePlayerNameText:SetPoint("TOPLEFT", TradeFramePlayerPortrait, "TOPRIGHT", 12, -2)

    TradeFrameRecipientNameText:ClearAllPoints()
    TradeFrameRecipientNameText:SetPoint("TOPLEFT", TradeFrameRecipientPortrait, "TOPRIGHT", 12, -2)

    ---------------------------------------------------------------------------
    -- 5b. 货币：左右各画 DF 大理石凹框 + 裸放 vanilla 金银铜
    --     左 TradePlayerInputMoneyFrame=MoneyInputFrame compact(输入,永显)；
    --     右 TradeRecipientMoneyFrame=只读(对方出钱才显)。
    --     关键：凹框画成 bg(面板底框)自己的 region(非独立 frame)，跨 frame 恒在
    --     money(parent=TradeFrame,高 level)之下 → 金银铜物理上绝不被盖；左右同函数=一致。
    --     对方没钱时 SmallMoneyFrame 自隐但凹框 region 仍在 → 对称占位。
    --     -14：下移到金环底缘以下，避免环下半弧压住框。
    ---------------------------------------------------------------------------
    local MARBLE_TEX = TEX .. "interface\\ui-background-marble.tga"
    local UIH_TEX    = TEX .. "panels\\df\\professions\\uiframe_h.tga"
    local UIV_TEX    = TEX .. "panels\\df\\professions\\uiframe_v.tga"
    local CORNER_TEX = TEX .. "interface\\generalframeinsetborders.tga"
    -- 大理石凹框作 host(=box) 自己的 region；box level 运行时跟随 money-1 → 框恒在金银铜之下
    local function DrawMoneyInset(host)
        local eT, eB, eL, eR, cz = 3, 3, 2, 2, 5
        local marble = host:CreateTexture(nil, "BACKGROUND")
        marble:SetTexture(MARBLE_TEX)
        marble:SetAllPoints(host)
        local top = host:CreateTexture(nil, "ARTWORK")
        top:SetTexture(UIH_TEX); top:SetTexCoord(0.0, 1.0, 0.9063, 0.9297)
        top:SetPoint("TOPLEFT",  host, "TOPLEFT",  0, 0)
        top:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0)
        top:SetHeight(eT)
        local bot = host:CreateTexture(nil, "ARTWORK")
        bot:SetTexture(UIH_TEX); bot:SetTexCoord(0.0, 1.0, 0.8672, 0.8906)
        bot:SetPoint("BOTTOMLEFT",  host, "BOTTOMLEFT",  0, 0)
        bot:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
        bot:SetHeight(eB)
        local left = host:CreateTexture(nil, "ARTWORK")
        left:SetTexture(UIV_TEX); left:SetTexCoord(0.4844, 0.5313, 0.0, 1.0)
        left:SetPoint("TOPLEFT",    host, "TOPLEFT",    0, 0)
        left:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 0)
        left:SetWidth(eL)
        local right = host:CreateTexture(nil, "ARTWORK")
        right:SetTexture(UIV_TEX); right:SetTexCoord(0.5313, 0.4844, 0.0, 1.0)
        right:SetPoint("TOPRIGHT",    host, "TOPRIGHT",    0, 0)
        right:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
        right:SetWidth(eR)
        local function corner(point, l, r, t, b)
            local c = host:CreateTexture(nil, "ARTWORK")
            c:SetTexture(CORNER_TEX); c:SetTexCoord(l, r, t, b)
            c:SetPoint(point, host, point, 0, 0)
            c:SetWidth(cz); c:SetHeight(cz)
        end
        corner("TOPLEFT",     0.703125, 0.828125, 0.03125, 0.28125)
        corner("TOPRIGHT",    0.859375, 0.984375, 0.03125, 0.28125)
        corner("BOTTOMLEFT",  0.328125, 0.453125, 0.6875,  0.9375)
        corner("BOTTOMRIGHT", 0.515625, 0.640625, 0.6875,  0.9375)
    end

    local moneyPairs = {}
    local MONEY_BOX_W, MONEY_BOX_H = 116, 24
    local function CreateMoneyBox(portrait, moneyFrame)
        if not moneyFrame then return end
        local box = CreateFrame("Frame", nil, bg)   -- 货币框载体（始终显示=对方没钱也占位对称）
        box:SetWidth(MONEY_BOX_W)
        box:SetHeight(MONEY_BOX_H)
        box:SetPoint("TOPLEFT", portrait, "BOTTOMLEFT", 8, -14)
        DrawMoneyInset(box)                          -- 大理石凹框作 box region
        moneyFrame:ClearAllPoints()
        moneyFrame:SetPoint("LEFT", box, "LEFT", 6, 0)
        table.insert(moneyPairs, { box = box, money = moneyFrame })
        return box
    end
    CreateMoneyBox(TradeFramePlayerPortrait,    TradePlayerInputMoneyFrame)
    CreateMoneyBox(TradeFrameRecipientPortrait, TradeRecipientMoneyFrame)

    -- ★真因：money 是 UIPanel 子 frame，FrameLevel 在显示时由 UIParent 动态决定，
    --   加载时设的静态 box/bg level 对不上（常 ≥ money）→ 大理石框压住金银铜。
    --   解法：运行时让 box level 跟随 money-1（同 strata），框恒在金银铜之下；
    --   box parent=bg 始终显示 → 对方没出钱也保留框、左右对称。
    local lvlWatcher = CreateFrame("Frame", nil, bg)
    lvlWatcher:SetScript("OnUpdate", function()
        if not TradeFrame:IsShown() then return end
        for i = 1, table.getn(moneyPairs) do
            local p = moneyPairs[i]
            local target = p.money:GetFrameLevel() - 1
            if target < 0 then target = 0 end
            if p.box:GetFrameLevel() ~= target then
                p.box:SetFrameLevel(target)
            end
        end
    end)

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
