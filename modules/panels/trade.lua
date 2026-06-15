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
    -- 4. 头像：复用 DFUI.AttachPortrait 工厂摆放 + DFUI.AddPortraitRing 金环（section 6b）。
    --    全插件 NPC 面板统一走 AttachPortrait；交易有玩家+对方两个自由位置头像，各调一次。
    --    ★reparent 到高层 titleHolder(TradeFrame+5,高于 bg 金属边)→头像不被金属顶边盖；
    --      环 OVERLAY > 头像 BORDER → 环框住头像方角。缝隙由"环+裁边"收，不再手写岩石底。
    --    ★尺寸/裁边是头像属性(非摆放)，保留；裁边留最小消黑边量（圆环风固有，实测可调）。
    ---------------------------------------------------------------------------
    -- 金环载体（高 FrameLevel 盖头像方角 + 承载头像/环）；提前建以供 AttachPortrait reparent
    local titleHolder = CreateFrame("Frame", nil, TradeFrame)
    titleHolder:SetAllPoints(TradeFrame)
    titleHolder:SetFrameLevel(TradeFrame:GetFrameLevel() + 5)

    local PORTRAIT_SIZE = 58            -- 放大填满金环内孔（环 80，内孔约 60；实测可调）
    local PORTRAIT_ZOOM = 0.10          -- 裁掉脸贴图四周黑边（圆环风固有，留最小量，实测可调）

    -- 摆放走 DFUI.AttachPortrait 工厂（reparent titleHolder + BORDER 层 + 锚 TOPLEFT+(x,y)）；
    -- x,y 相对 titleHolder(=TradeFrame)左上，取自原坐标→位置不变（实测可调）
    local function SetupPortrait(portrait, x, y)
        if not portrait then return end
        DFUI.AttachPortrait(titleHolder, portrait, x, y)
        portrait:SetWidth(PORTRAIT_SIZE)
        portrait:SetHeight(PORTRAIT_SIZE)
        portrait:SetTexCoord(PORTRAIT_ZOOM, 1 - PORTRAIT_ZOOM, PORTRAIT_ZOOM, 1 - PORTRAIT_ZOOM)
    end
    SetupPortrait(TradeFramePlayerPortrait,    14,  -8)
    SetupPortrait(TradeFrameRecipientPortrait, 183, -8)

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
    -- 5b. 货币：DF 大理石凹框直接画成 money frame 自身 region（根因修复）
    --     ★旧方案（独立 box + OnUpdate 跟随 money level-1）在 1.12 跨 frame 层级
    --       是动态竞态 → 框糊住金银铜/闪烁（多轮静态压 level + OnUpdate 全失败）。
    --     ★根因解法：凹框作 moneyFrame 自身 region —— marble 放 BACKGROUND 最底
    --       sublevel(-8)，金银铜图标(≥BACKGROUND/0)恒在其上；同 frame draw layer
    --       绝对确定，物理上绝不遮挡，无需任何 OnUpdate。
    --     边框(BORDER)只在外扩 pad 的四周，不覆盖中心图标 → 不挡金银铜。
    --     对方没钱时 SmallMoneyFrame 自隐，右侧凹框随之消失（vanilla 行为，暂不占位）。
    ---------------------------------------------------------------------------
    local MARBLE_TEX = TEX .. "interface\\ui-background-marble.tga"
    local UIH_TEX    = TEX .. "panels\\df\\professions\\uiframe_h.tga"
    local UIV_TEX    = TEX .. "panels\\df\\professions\\uiframe_v.tga"
    local CORNER_TEX = TEX .. "interface\\generalframeinsetborders.tga"
    -- ★列横向对齐基准 pad：货币凹框 + 物品凹框 + 附魔凹框三者共用同一基准，
    --   marble 横向锚 item1（容器 153=整行宽，左右= item1.left+COL_PAD_L .. item1.right+COL_PAD_R），
    --   因 item1.right=item6.right=item7.right（同列同宽）→ 三个凹框左右边严格对齐成一竖列（对齐根因修复）。
    local COL_PAD_L, COL_PAD_R = 3, 3
    -- 货币凹框纵向：相对 item1 顶的偏移 + 固定高，只覆盖金银铜行（实测微调）
    local MONEY_TOP_DY, MONEY_H = 26, 24
    -- 凹框横向锚 item1(对齐 items-inset)，纵向锚 item1 顶+固定高(覆盖币行)；
    -- marble 仍是 host(money frame)的 texture → draw level 跟 money、金银铜恒在其上(no race)
    local function DrawMoneyInset(host, item1)
        local eT, eB, eL, eR, cz = 3, 3, 2, 2, 5
        local marble = host:CreateTexture(nil, "BACKGROUND")
        marble:SetDrawLayer("BACKGROUND", -8)        -- 最底：金银铜恒在其上
        marble:SetTexture(MARBLE_TEX)
        marble:SetPoint("TOPLEFT",     item1, "TOPLEFT",  COL_PAD_L,  MONEY_TOP_DY)
        marble:SetPoint("BOTTOMRIGHT", item1, "TOPRIGHT", COL_PAD_R,  MONEY_TOP_DY - MONEY_H)
        local top = host:CreateTexture(nil, "BORDER")
        top:SetTexture(UIH_TEX); top:SetTexCoord(0.0, 1.0, 0.9063, 0.9297)
        top:SetPoint("TOPLEFT",  marble, "TOPLEFT",  0, 0)
        top:SetPoint("TOPRIGHT", marble, "TOPRIGHT", 0, 0)
        top:SetHeight(eT)
        local bot = host:CreateTexture(nil, "BORDER")
        bot:SetTexture(UIH_TEX); bot:SetTexCoord(0.0, 1.0, 0.8672, 0.8906)
        bot:SetPoint("BOTTOMLEFT",  marble, "BOTTOMLEFT",  0, 0)
        bot:SetPoint("BOTTOMRIGHT", marble, "BOTTOMRIGHT", 0, 0)
        bot:SetHeight(eB)
        local left = host:CreateTexture(nil, "BORDER")
        left:SetTexture(UIV_TEX); left:SetTexCoord(0.4844, 0.5313, 0.0, 1.0)
        left:SetPoint("TOPLEFT",    marble, "TOPLEFT",    0, 0)
        left:SetPoint("BOTTOMLEFT", marble, "BOTTOMLEFT", 0, 0)
        left:SetWidth(eL)
        local right = host:CreateTexture(nil, "BORDER")
        right:SetTexture(UIV_TEX); right:SetTexCoord(0.5313, 0.4844, 0.0, 1.0)
        right:SetPoint("TOPRIGHT",    marble, "TOPRIGHT",    0, 0)
        right:SetPoint("BOTTOMRIGHT", marble, "BOTTOMRIGHT", 0, 0)
        right:SetWidth(eR)
        local function corner(point, l, r, t, b)
            local c = host:CreateTexture(nil, "BORDER")
            c:SetTexture(CORNER_TEX); c:SetTexCoord(l, r, t, b)
            c:SetPoint(point, marble, point, 0, 0)
            c:SetWidth(cz); c:SetHeight(cz)
        end
        corner("TOPLEFT",     0.703125, 0.828125, 0.03125, 0.28125)
        corner("TOPRIGHT",    0.859375, 0.984375, 0.03125, 0.28125)
        corner("BOTTOMLEFT",  0.328125, 0.453125, 0.6875,  0.9375)
        corner("BOTTOMRIGHT", 0.515625, 0.640625, 0.6875,  0.9375)
    end

    -- money frame 重锚头像下方；凹框横向对齐 item 列(=对齐 items-inset)，纵向覆盖币行
    local function SetupMoney(portrait, moneyFrame, item1)
        if not moneyFrame or not item1 then return end
        moneyFrame:ClearAllPoints()
        moneyFrame:SetPoint("TOPLEFT", portrait, "BOTTOMLEFT", 14, -16)
        DrawMoneyInset(moneyFrame, item1)
    end
    SetupMoney(TradeFramePlayerPortrait,    TradePlayerInputMoneyFrame, TradePlayerItem1)
    SetupMoney(TradeFrameRecipientPortrait, TradeRecipientMoneyFrame,   TradeRecipientItem1)

    ---------------------------------------------------------------------------
    -- 6b. 头像金色圆环（DFUI.AddPortraitRing 工厂，df_portrait_ring 整图）
    --     环挂 titleHolder(高 FrameLevel，section 4 已建)，OVERLAY 盖住头像方角；
    --     环略大于头像，内孔透出脸部，SetTexture 整张 + 居中（不切片）。
    ---------------------------------------------------------------------------
    DFUI.AddPortraitRing(TradeFramePlayerPortrait, titleHolder)
    DFUI.AddPortraitRing(TradeFrameRecipientPortrait, titleHolder)

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
        -- 深色凹槽底（照 loot.lua:141 范式 WHITE8X8+黑，BACKGROUND 层）：
        -- 空槽透出深凹陷感，有物品时被 Icon/边框盖住；α 半透露一点岩石底（可调）
        local slotBg = btn:CreateTexture(nil, "BACKGROUND")
        slotBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        slotBg:SetAllPoints(btn)
        slotBg:SetVertexColor(0, 0, 0, 0.55)
        btn.dfuiBg = slotBg
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

    -- 第7槽(附魔/不会被交易)自带 UI-TradeFrame-EnchantIcon 纹理(子 region，
    -- 不在第1步 TradeFrame:GetRegions() 直属遍历内) → 单独隐藏避免与 DF 风格冲突
    local function HideEnchantIcon(slotName)
        local slot = getglobal(slotName)
        if not slot then return end
        local rs = {slot:GetRegions()}
        for i = 1, table.getn(rs) do
            local r = rs[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                local t = r:GetTexture()
                if t and string.find(t, "UI%-TradeFrame") then r:Hide() end
            end
        end
    end
    HideEnchantIcon("TradePlayerItem7")
    HideEnchantIcon("TradeRecipientItem7")

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
    -- 8b. 物品槽凹陷大理石框（DF retail 结构补全）
    --     retail：每侧 6 物品槽在独立凹陷框 ItemsInset、第7槽(附魔/"不会被交易")
    --     在独立小凹框 EnchantInset 内。当前槽边框裸浮岩石底 → 补两组凹框。
    --     ★复用工厂 DFUI.CreateRetailInset（marble 底+uiframe_h/v 9-slice 边+
    --       generalframeinsetborders 四角），零自制贴图。
    --     ★层级：凹框作 bg 子 frame（levelOffset=1 → level=bg+1=TradeFrame），
    --       物品 ItemButton(TradeFrame+2)恒在其上 → marble 绝不盖图标，无需 OnUpdate。
    --     ★锚"容器"TradePlayerItem1..7（153×37，含右侧物品名区）→ 整条行宽，
    --       有物品时物品名落在大理石框内不外溢（用户确认的包裹范围）。
    --     ★全程只对 inset 自身 ClearAllPoints+SetPoint，绝不碰 Trade*Item* 槽锚点
    --       （遵循"换皮禁改框体大小/控件位置"铁律）。
    ---------------------------------------------------------------------------
    local tradeInsets = {}

    -- pad 量级初值；终值游戏内实测（见铁律：marble 贴合行外缘/不盖图标）。
    -- 水平 pad 保持小值：item 容器本就 153 全行宽，且避免内侧边触碰中央竖 divider
    -- （player 右侧 / recipient 左侧贴近面板中线，与 divider 打架须实测收住）。
    -- 横向 pad 复用货币段定义的 COL_PAD_L/R（三个凹框横向同基准 → 严格对齐成一竖列）
    local ITEMS_PAD_T, ITEMS_PAD_B = 3, 3
    local ENCH_GAP, ENCH_PAD_B = 4, 3

    local function MakeItemsInset(name, item1, item6)
        if not item1 or not item6 then return nil end
        local ins = DFUI.CreateRetailInset(bg, { name = name })   -- parent=bg → level=TradeFrame
        ins:ClearAllPoints()
        ins:SetPoint("TOPLEFT",     item1, "TOPLEFT",      COL_PAD_L,  ITEMS_PAD_T)
        ins:SetPoint("BOTTOMRIGHT", item6, "BOTTOMRIGHT",  COL_PAD_R, -ITEMS_PAD_B)
        ins:Show()                                                -- 工厂默认 Hide，手动 Show
        table.insert(tradeInsets, ins)
        return ins
    end

    local function MakeEnchantInset(name, itemsInset, item7)
        if not item7 then return nil end
        local en = DFUI.CreateRetailInset(bg, { name = name })
        en:ClearAllPoints()
        -- 顶：items-inset 底下方留 GAP（"不会被交易"标签落此带内）；底/右：item7 容器
        if itemsInset then
            en:SetPoint("TOPLEFT", itemsInset, "BOTTOMLEFT", 0, -ENCH_GAP)
        else
            en:SetPoint("TOPLEFT", item7, "TOPLEFT", COL_PAD_L, ITEMS_PAD_T)
        end
        en:SetPoint("BOTTOMRIGHT", item7, "BOTTOMRIGHT", COL_PAD_R, -ENCH_PAD_B)
        en:Show()
        table.insert(tradeInsets, en)
        return en
    end

    local playerItemsInset = MakeItemsInset("DFUI_TradePlayerItemsInset",    TradePlayerItem1,    TradePlayerItem6)
    local recipItemsInset  = MakeItemsInset("DFUI_TradeRecipientItemsInset", TradeRecipientItem1, TradeRecipientItem6)
    MakeEnchantInset("DFUI_TradePlayerEnchantInset",    playerItemsInset, TradePlayerItem7)
    MakeEnchantInset("DFUI_TradeRecipientEnchantInset", recipItemsInset,  TradeRecipientItem7)

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
        for i = 1, table.getn(tradeInsets) do tradeInsets[i]:Show() end
    end)

    local callbacks = {}
    DFUI:NewCallbacks("Trade", callbacks)
end)
