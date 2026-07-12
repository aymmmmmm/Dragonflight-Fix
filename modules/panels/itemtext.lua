-- itemtext.lua — 书籍阅读面板(ItemTextFrame)换皮：背包书籍/信件、世界铭牌/墓碑
-- 完全复用 questskin 工厂（金属框+岩石底+羊皮纸+凹陷+红关闭+minimal 滚动条），零自创素材
-- 材质变体(Stone/Bronze/Marble/Silver)统一收敛为 DF 羊皮纸（同 pfUI 做法）
-- 注意：1.12 该框体右侧边框复用法术书贴图(UI-SpellbookPanel-*)、左上自带 Spellbook-Icon
--       region，按名匹配必漏 → 全量隐藏（1.12 源码实证：边框无运行时重 Show，一次隐藏即永久）

setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("ItemText", {
    enabled = {true},
})

DFUI:NewMod("ItemText", 5, function()
    -- 全量隐藏原生贴图（4 边框 + 原生 Spellbook-Icon + 4 材质角，无 match 一网打尽）
    DFUI.HidePanelTextures(ItemTextFrame, {})

    -- 材质四角补 no-op Show（Blizzard 每次 ITEM_TEXT_READY 都重新 SetTexture+Show）
    local mats = {ItemTextMaterialTopLeft, ItemTextMaterialTopRight,
                  ItemTextMaterialBotLeft, ItemTextMaterialBotRight}
    for i = 1, table.getn(mats) do
        if mats[i] then
            mats[i].Show = function() end
        end
    end

    -- vanilla 关闭按钮名不规则（ItemTextCloseButton 无 "Frame" 前缀），工厂按
    -- frame:GetName().."CloseButton" 推导不到，手动隐藏
    if ItemTextCloseButton then
        ItemTextCloseButton:Hide()
        ItemTextCloseButton.Show = function() end
    end

    -- 共通换皮（与闲聊/接任务/飞行点同款，视觉统一）
    local customBg = DFUI.SkinQuestStyleFrame(ItemTextFrame, {
        name     = "DFUI_ItemTextBg",
        nameText = ItemTextTitleText,
        onClose  = function() HideUIPanel(ItemTextFrame) end,  -- OnHide 自动触发 CloseItemText()
    })

    -- 首轮遗留清理：旧版曾把 Spellbook-Icon 挂上 customBg，/reload 不销毁 frame → 按贴图名兜底隐藏
    if customBg then
        local regions = {customBg:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r:GetObjectType() == "Texture" then
                local tex = r:GetTexture()
                if tex and string.find(tex, "Spellbook", 1, true) then r:Hide() end
            end
        end
    end

    -- 金环书本图标（照 questlog.lua 配方；UI-QuestLog-BookIcon 即接任务面板无 NPC 时的同款圆形书图标）
    if customBg and not customBg._dfBookIcon then
        local bookIcon = customBg:CreateTexture(nil, "ARTWORK")
        bookIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon")
        bookIcon:SetPoint("TOPLEFT", customBg, "TOPLEFT", -3, 6)
        bookIcon:SetWidth(56)
        bookIcon:SetHeight(56)
        customBg._dfBookIcon = bookIcon
    end

    -- 滚动条轨道装饰：1.12 源码里这仨叫 ItemTextScrollFrameTop/Middle/Bottom（$parentTop 挂
    -- ScrollFrame 名下），不是 quest 家族的 $parentScrollBarTop 命名 → 工厂 keepArrowsHideTrack
    -- 按 <滚动条名>Top 查找必落空，须对 ScrollFrame 本体全量隐藏（无运行时重 Show，一次即永久）
    DFUI.HidePanelTextures(ItemTextScrollFrame, {})

    -- minimal 滚动条接管正文 ScrollFrame
    DFUI.AttachMinimalScrolls(ItemTextFrame, {
        {sf = "ItemTextScrollFrame", sb = "ItemTextScrollFrameScrollBar"},
    })

    -- 翻页排（照 retail DF：页码居中、箭头分列两侧，落在标题与羊皮纸之间的岩石带上）
    -- 保留 vanilla 原生 UI-SpellbookIcon-PrevPage/NextPage 箭头素材
    if ItemTextCurrentPage and customBg then
        ItemTextCurrentPage:ClearAllPoints()
        ItemTextCurrentPage:SetPoint("TOP", customBg, "TOP", 0, -34)
    end
    if ItemTextPrevPageButton and ItemTextCurrentPage then
        ItemTextPrevPageButton:ClearAllPoints()
        ItemTextPrevPageButton:SetPoint("RIGHT", ItemTextCurrentPage, "LEFT", -10, 0)
    end
    if ItemTextNextPageButton and ItemTextCurrentPage then
        ItemTextNextPageButton:ClearAllPoints()
        ItemTextNextPageButton:SetPoint("LEFT", ItemTextCurrentPage, "RIGHT", 10, 0)
    end

    DFUI:NewCallbacks("ItemText", {})
end)
