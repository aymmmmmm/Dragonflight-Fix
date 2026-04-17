-- tradeskill.lua — 统一专业技能面板 (TradeSkill + Craft)
-- 全新自建 UI，书本风格，与 SpellBook 视觉统一
-- 核心策略: 原生面板 SetAlpha(0)+EnableMouse(false) 保持 API 连接，自建面板覆盖其上

setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

local CLASS_ICON_COORDS = DFUI_CLASS_ICON_COORDS

-- 难度颜色 (针对金色羊皮纸背景优化对比度)
local DIFFICULTY_COLORS = {
    optimal  = {0.70, 0.28, 0.05},   -- 深赭橙
    medium   = {0.65, 0.50, 0.08},   -- 琥珀
    easy     = {0.18, 0.48, 0.18},   -- 森林绿
    trivial  = {0.42, 0.38, 0.33},   -- 暖灰褐
    header   = {0.15, 0.10, 0.05},   -- 深黑棕（与右页标题统一）
    none     = {0.18, 0.48, 0.18},   -- 森林绿（未学）
    used     = {0.42, 0.38, 0.33},   -- 暖灰褐（已学，同 trivial）
    default  = {0.42, 0.38, 0.33},   -- 暖灰褐
}

local CreateCheckbox = CreatePanelCheckbox

DFUI:NewDefaults("TradeSkill", {
    enabled = {true},
})

DFUI:NewMod("TradeSkill", 5, function()

    -- ============================================================
    -- 状态变量
    -- ============================================================
    local currentMode = nil        -- "tradeskill" or "craft"
    local selectedIndex = nil      -- 当前选中的配方 index
    local recipeButtons = {}       -- 配方按钮池
    local reagentSlots = {}        -- 材料格池
    local MAX_RECIPE_BUTTONS = 13
    local MAX_REAGENTS = 8
    local scrollOffset = 0
    local filterHasMats = false
    local tradeSkillOpen = false   -- 事件状态标记
    local craftOpen = false
    local isClosing = false        -- OnHide 重入守卫
    local activeProfName = nil     -- 当前打开的专业名（用于 tab 防重复点击）
    local tradeSkillHooked = false -- 原生面板 hook 标志
    local craftHooked = false

    -- 透明化原生面板（保持 API 连接，移出视野）
    local function HideNativeFrame(frame)
        frame:SetAlpha(0)
        frame:EnableMouse(false)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000)
    end

    -- API 专业名 → 法术名 映射（GetTradeSkillLine 返回名与法术名不同时，仅采矿需要）
    local PROF_API_TO_SPELL = {
        ["Mining"] = "Smelting", ["采矿"] = "熔炼",
    }

    -- 法术名 → 显示名（Tab / 标题显示用，仅宠物训练需要）
    local PROF_DISPLAY_NAME = {
        ["训练野兽"] = "宠物技能",
        ["Pet Training"] = "Beast Training",
    }

    -- ============================================================
    -- 1. 面板框架
    -- ============================================================
    local panel = DFUI.CreatePaperDollFrame("DFUI_ProfessionFrame", UIParent, 750, 530, 1)
    panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 30, -104)
    panel:SetFrameStrata("MEDIUM")
    panel:SetFrameLevel(25)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function() panel:StartMoving() end)
    panel:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)
    panel:SetScale(0.9)

    -- ============================================================
    -- 2. 页面纹理
    -- ============================================================
    local leftPage = panel:CreateTexture(nil, "ARTWORK")
    leftPage:SetTexture(TEX .. "panels\\spellbook_right_page.blp")
    leftPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -60)
    leftPage:SetPoint("BOTTOM", panel, "BOTTOM", -5, 10)
    leftPage:SetWidth(365)

    local rightPage = panel:CreateTexture(nil, "ARTWORK")
    rightPage:SetTexture(TEX .. "panels\\spellbook_left_page.blp")
    rightPage:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -60)
    rightPage:SetPoint("BOTTOM", panel, "BOTTOM", 5, 10)
    rightPage:SetWidth(365)

    local topWood = panel:CreateTexture(nil, "BORDER")
    topWood:SetTexture(TEX .. "panels\\spellbook_top_wood.blp")
    topWood:SetPoint("TOP", panel, "TOP", 0, -20)
    topWood:SetWidth(730)
    topWood:SetHeight(64)

    local bookmark = panel:CreateTexture(nil, "OVERLAY")
    bookmark:SetTexture(TEX .. "panels\\spellbook_bookmark.blp")
    bookmark:SetPoint("TOPRIGHT", leftPage, "TOPRIGHT", 45, 0)
    bookmark:SetWidth(50)
    bookmark:SetHeight(500)

    -- ============================================================
    -- 3. 专业图标 + 标题 + 关闭按钮
    -- ============================================================
    local profIcon = panel:CreateTexture(nil, "ARTWORK")
    profIcon:SetTexture(TEX .. "ui\\UI-Classes-Circles.tga")
    local _, playerClass = UnitClass("player")
    local coords = CLASS_ICON_COORDS[playerClass]
    if coords then
        profIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end
    profIcon:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 3)
    profIcon:SetWidth(52)
    profIcon:SetHeight(52)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText("专业技能")
    title:SetTextColor(0.95, 0.90, 0.80)
    title:SetPoint("TOP", panel, "TOP", 0, -6)

    local closeBtn = DFUI.CreateRedButton(panel, "close", function() panel:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -1)

    -- ============================================================
    -- 4. 熟练度进度条
    -- ============================================================
    local rankBarBg = CreateFrame("Frame", nil, panel)
    rankBarBg:SetPoint("TOPLEFT", leftPage, "TOPLEFT", 30, -12)
    rankBarBg:SetPoint("RIGHT", leftPage, "RIGHT", -30, 0)
    rankBarBg:SetHeight(18)
    rankBarBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    rankBarBg:SetBackdropColor(0.10, 0.08, 0.05, 0.75)
    rankBarBg:SetBackdropBorderColor(0.55, 0.42, 0.20, 0.70)
    rankBarBg:SetFrameLevel(panel:GetFrameLevel() + 2)

    local rankBar = CreateFrame("StatusBar", nil, rankBarBg)
    rankBar:SetPoint("TOPLEFT", rankBarBg, "TOPLEFT", 3, -3)
    rankBar:SetPoint("BOTTOMRIGHT", rankBarBg, "BOTTOMRIGHT", -3, 3)
    rankBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    rankBar:SetStatusBarColor(0.85, 0.65, 0.20)
    rankBar:SetMinMaxValues(0, 300)
    rankBar:SetValue(0)

    local rankText = rankBar:CreateFontString(nil, "OVERLAY")
    rankText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    rankText:SetPoint("CENTER", rankBar, "CENTER", 0, 0)
    rankText:SetTextColor(0.10, 0.08, 0.05)


    -- ============================================================
    -- 5. 左页 — 配方列表
    -- ============================================================
    local listFrame = CreateFrame("Frame", nil, panel)
    listFrame:SetPoint("TOPLEFT", leftPage, "TOPLEFT", 30, -10)
    listFrame:SetPoint("BOTTOMRIGHT", leftPage, "BOTTOMRIGHT", -30, 45)
    listFrame:SetFrameLevel(panel:GetFrameLevel() + 3)

    -- 折叠全部按钮（模拟原版 "全部" header 行）
    local collapseAllBtn = CreateFrame("Button", nil, listFrame)
    collapseAllBtn:SetHeight(16)
    collapseAllBtn:SetPoint("TOPLEFT", rankBarBg, "BOTTOMLEFT", 0, -12)
    collapseAllBtn:SetPoint("RIGHT", listFrame, "RIGHT", -10, 0)
    local collapseAllText = collapseAllBtn:CreateFontString(nil, "OVERLAY")
    collapseAllText:SetFont("Fonts\\FRIZQT__.TTF", 10)
    collapseAllText:SetPoint("LEFT", collapseAllBtn, "LEFT", 2, 0)
    collapseAllText:SetWidth(14)
    collapseAllText:SetTextColor(0.15, 0.10, 0.05)
    collapseAllText:SetText("-")
    local collapseAllLabel = collapseAllBtn:CreateFontString(nil, "OVERLAY")
    collapseAllLabel:SetFont("Fonts\\FRIZQT__.TTF", 13)
    collapseAllLabel:SetPoint("LEFT", collapseAllBtn, "LEFT", 18, 0)
    collapseAllLabel:SetPoint("RIGHT", collapseAllBtn, "RIGHT", -5, 0)
    collapseAllLabel:SetJustifyH("LEFT")
    collapseAllLabel:SetText("全部")
    local hc = DIFFICULTY_COLORS.header
    collapseAllLabel:SetTextColor(hc[1], hc[2], hc[3])

    -- 配方按钮工厂
    local function CreateRecipeButton(parent)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetHeight(16)

        -- 悬停: 柔和全行金色亮光
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight:SetAllPoints(btn)
        highlight:SetVertexColor(0.85, 0.70, 0.20, 0.15)
        highlight:SetBlendMode("ADD")

        -- 选中: 三层结构
        local selectedBg = btn:CreateTexture(nil, "BACKGROUND")
        selectedBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        selectedBg:SetAllPoints(btn)
        selectedBg:SetVertexColor(0.60, 0.45, 0.15, 0.25)
        selectedBg:Hide()
        btn.selectedBg = selectedBg

        local selectedBar = btn:CreateTexture(nil, "ARTWORK")
        selectedBar:SetTexture("Interface\\Buttons\\WHITE8X8")
        selectedBar:SetWidth(3)
        selectedBar:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        selectedBar:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        selectedBar:SetVertexColor(0.85, 0.70, 0.20, 1.0)
        selectedBar:Hide()
        btn.selectedBar = selectedBar

        local selectedTop = btn:CreateTexture(nil, "ARTWORK")
        selectedTop:SetTexture("Interface\\Buttons\\WHITE8X8")
        selectedTop:SetHeight(1)
        selectedTop:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, 0)
        selectedTop:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        selectedTop:SetVertexColor(0.85, 0.70, 0.20, 0.40)
        selectedTop:Hide()
        btn.selectedTop = selectedTop

        local selectedBot = btn:CreateTexture(nil, "ARTWORK")
        selectedBot:SetTexture("Interface\\Buttons\\WHITE8X8")
        selectedBot:SetHeight(1)
        selectedBot:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 3, 0)
        selectedBot:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        selectedBot:SetVertexColor(0.85, 0.70, 0.20, 0.40)
        selectedBot:Hide()
        btn.selectedBot = selectedBot

        -- Header 分隔线
        local headerSep = btn:CreateTexture(nil, "ARTWORK")
        headerSep:SetTexture("Interface\\Buttons\\WHITE8X8")
        headerSep:SetHeight(1)
        headerSep:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 2)
        headerSep:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 2)
        headerSep:SetVertexColor(0.55, 0.42, 0.20, 0.50)
        headerSep:Hide()
        btn.headerSep = headerSep

        -- 配方产物图标
        local recipeIcon = btn:CreateTexture(nil, "ARTWORK")
        recipeIcon:SetWidth(20)
        recipeIcon:SetHeight(20)
        recipeIcon:SetPoint("LEFT", btn, "LEFT", 2, 0)
        recipeIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        recipeIcon:Hide()
        btn.recipeIcon = recipeIcon

        local collapseIcon = btn:CreateFontString(nil, "OVERLAY")
        collapseIcon:SetFont("Fonts\\FRIZQT__.TTF", 10)
        collapseIcon:SetPoint("LEFT", btn, "LEFT", 2, 0)
        collapseIcon:SetWidth(14)
        collapseIcon:SetTextColor(0.15, 0.10, 0.05)
        btn.collapseIcon = collapseIcon

        local nameText = btn:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        nameText:SetPoint("LEFT", btn, "LEFT", 18, 0)
        nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
        nameText:SetJustifyH("LEFT")
        btn.nameText = nameText

        btn.recipeIndex = nil
        btn.isHeader = false
        return btn
    end

    local function SetButtonSelected(btn, isSelected)
        if isSelected then
            btn.selectedBg:Show()
            btn.selectedBar:Show()
            btn.selectedTop:Show()
            btn.selectedBot:Show()
        else
            btn.selectedBg:Hide()
            btn.selectedBar:Hide()
            btn.selectedTop:Hide()
            btn.selectedBot:Hide()
        end
    end

    for i = 1, MAX_RECIPE_BUTTONS do
        local btn = CreateRecipeButton(listFrame)
        btn:SetHeight(20)
        if i == 1 then
            btn:SetPoint("TOPLEFT", collapseAllBtn, "BOTTOMLEFT", 0, -4)
        else
            btn:SetPoint("TOPLEFT", recipeButtons[i - 1], "BOTTOMLEFT", 0, -1)
        end
        btn:SetPoint("RIGHT", listFrame, "RIGHT", -10, 0)
        table.insert(recipeButtons, btn)
    end

    -- ============================================================
    -- 6. 右页 — 配方详情
    -- ============================================================
    local detailFrame = CreateFrame("Frame", nil, panel)
    detailFrame:SetPoint("TOPLEFT", rightPage, "TOPLEFT", 40, -55)
    detailFrame:SetPoint("BOTTOMRIGHT", rightPage, "BOTTOMRIGHT", -20, 45)
    detailFrame:SetFrameLevel(panel:GetFrameLevel() + 3)

    local detailIconBtn = CreateFrame("Button", nil, detailFrame)
    detailIconBtn:SetWidth(35)
    detailIconBtn:SetHeight(35)
    detailIconBtn:SetPoint("TOPLEFT", detailFrame, "TOPLEFT", 5, -15)

    local detailIcon = detailIconBtn:CreateTexture(nil, "BACKGROUND")
    detailIcon:SetAllPoints(detailIconBtn)
    detailIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local detailIconBorder = detailIconBtn:CreateTexture(nil, "ARTWORK")
    detailIconBorder:SetTexture(TEX .. "panels\\spellbook_actives_border.blp")
    detailIconBorder:SetWidth(48)
    detailIconBorder:SetHeight(48)
    detailIconBorder:SetPoint("CENTER", detailIconBtn, "CENTER", -2, -1)

    local detailName = detailFrame:CreateFontString(nil, "OVERLAY")
    detailName:SetFont("Fonts\\FRIZQT__.TTF", 13)
    detailName:SetPoint("TOPLEFT", detailIconBtn, "TOPRIGHT", 8, -2)
    detailName:SetPoint("RIGHT", detailFrame, "RIGHT", -10, 0)
    detailName:SetJustifyH("LEFT")
    detailName:SetTextColor(0.15, 0.10, 0.05)

    local detailSubText = detailFrame:CreateFontString(nil, "OVERLAY")
    detailSubText:SetFont("Fonts\\FRIZQT__.TTF", 10)
    detailSubText:SetPoint("TOPLEFT", detailName, "BOTTOMLEFT", 0, -4)
    detailSubText:SetPoint("RIGHT", detailFrame, "RIGHT", -10, 0)
    detailSubText:SetJustifyH("LEFT")
    detailSubText:SetTextColor(0.85, 0.70, 0.20)

    local detailCooldown = detailFrame:CreateFontString(nil, "OVERLAY")
    detailCooldown:SetFont("Fonts\\FRIZQT__.TTF", 10)
    detailCooldown:SetPoint("TOPLEFT", detailSubText, "BOTTOMLEFT", 0, -8)
    detailCooldown:SetPoint("RIGHT", detailFrame, "RIGHT", -10, 0)
    detailCooldown:SetTextColor(0.85, 0.70, 0.20)

    local detailRequire = detailFrame:CreateFontString(nil, "OVERLAY")
    detailRequire:SetFont("Fonts\\FRIZQT__.TTF", 10)
    detailRequire:SetPoint("TOPLEFT", detailCooldown, "BOTTOMLEFT", 0, -4)
    detailRequire:SetPoint("RIGHT", detailFrame, "RIGHT", -10, 0)
    detailRequire:SetTextColor(0.85, 0.70, 0.20)

    local detailPoints = detailFrame:CreateFontString(nil, "OVERLAY")
    detailPoints:SetFont("Fonts\\FRIZQT__.TTF", 10)
    detailPoints:SetPoint("TOPLEFT", detailRequire, "BOTTOMLEFT", 0, -4)
    detailPoints:SetPoint("RIGHT", detailFrame, "RIGHT", -10, 0)
    detailPoints:SetTextColor(0.85, 0.70, 0.20)

    local detailDesc = detailFrame:CreateFontString(nil, "OVERLAY")
    detailDesc:SetFont("Fonts\\FRIZQT__.TTF", 10)
    detailDesc:SetPoint("TOPLEFT", detailPoints, "BOTTOMLEFT", 0, -8)
    detailDesc:SetPoint("RIGHT", detailFrame, "RIGHT", -10, 0)
    detailDesc:SetJustifyH("LEFT")
    detailDesc:SetTextColor(0.20, 0.15, 0.10)

    local reagentLabel = detailFrame:CreateFontString(nil, "OVERLAY")
    reagentLabel:SetFont("Fonts\\FRIZQT__.TTF", 11)
    reagentLabel:SetText("材料:")
    reagentLabel:SetTextColor(0.15, 0.10, 0.05)

    -- 材料格工厂
    local function CreateReagentSlot(parent)
        local slot = CreateFrame("Frame", nil, parent)
        slot:SetWidth(155)
        slot:SetHeight(40)

        local iconFrame = CreateFrame("Button", nil, slot)
        iconFrame:SetWidth(32)
        iconFrame:SetHeight(32)
        iconFrame:SetPoint("LEFT", slot, "LEFT", 4, 0)

        local icon = iconFrame:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints(iconFrame)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon = icon

        local border = iconFrame:CreateTexture(nil, "ARTWORK")
        border:SetTexture(TEX .. "panels\\spellbook_actives_border.blp")
        border:SetWidth(42)
        border:SetHeight(42)
        border:SetPoint("CENTER", iconFrame, "CENTER", -2, -1)

        local nameText = slot:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 10)
        nameText:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 5, -2)
        nameText:SetPoint("RIGHT", slot, "RIGHT", -3, 0)
        nameText:SetJustifyH("LEFT")
        slot.nameText = nameText

        local countText = slot:CreateFontString(nil, "OVERLAY")
        countText:SetFont("Fonts\\FRIZQT__.TTF", 9)
        countText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -1)
        slot.countText = countText

        slot.iconFrame = iconFrame
        slot.reagentIndex = nil
        return slot
    end

    for i = 1, MAX_REAGENTS do
        local slot = CreateReagentSlot(detailFrame)
        slot:Hide()
        table.insert(reagentSlots, slot)
    end


    -- ============================================================
    -- 7. 底部操作区 (不用 UIPanelButtonTemplate，手动创建按钮)
    -- ============================================================
    local function CreateSimpleButton(parent, width, text)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetWidth(width)
        btn:SetHeight(24)
        btn:SetFrameLevel(parent:GetFrameLevel() + 5)
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(btn)
        bg:SetVertexColor(0.12, 0.10, 0.08, 0.80)
        local border = CreateFrame("Frame", nil, btn)
        border:SetAllPoints(btn)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
        })
        border:SetBackdropBorderColor(0.55, 0.42, 0.20, 0.80)
        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 11)
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        label:SetText(text)
        label:SetTextColor(0.95, 0.90, 0.80)
        btn.label = label
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface\\Buttons\\WHITE8X8")
        hl:SetAllPoints(btn)
        hl:SetVertexColor(0.40, 0.30, 0.10, 0.3)
        hl:SetBlendMode("ADD")
        return btn
    end

    local createBtn = CreateSimpleButton(panel, 70, "制作")
    createBtn:SetPoint("BOTTOMRIGHT", rightPage, "BOTTOMRIGHT", -20, 15)

    local cancelBtn = CreateSimpleButton(panel, 55, "取消")
    cancelBtn:SetPoint("RIGHT", createBtn, "LEFT", -6, 0)

    -- 训练点数显示（仅宠物训练模式，在取消按钮左侧）
    local trainingPointsText = panel:CreateFontString(nil, "OVERLAY")
    trainingPointsText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    trainingPointsText:SetPoint("RIGHT", cancelBtn, "LEFT", -12, 0)
    trainingPointsText:SetTextColor(0.15, 0.10, 0.05)
    trainingPointsText:Hide()

    local createAllBtn = CreateSimpleButton(panel, 55, "全部")
    createAllBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -6, 0)

    local incrementBtn = CreateSimpleButton(panel, 20, "+")
    incrementBtn:SetPoint("RIGHT", createAllBtn, "LEFT", -10, 0)

    local inputBoxBg = CreateFrame("Frame", nil, panel)
    inputBoxBg:SetWidth(36)
    inputBoxBg:SetHeight(24)
    inputBoxBg:SetPoint("RIGHT", incrementBtn, "LEFT", -1, 0)
    inputBoxBg:SetFrameLevel(panel:GetFrameLevel() + 5)
    inputBoxBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    inputBoxBg:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
    inputBoxBg:SetBackdropBorderColor(0.45, 0.35, 0.20, 0.70)

    local inputBox = CreateFrame("EditBox", nil, inputBoxBg)
    inputBox:SetPoint("TOPLEFT", inputBoxBg, "TOPLEFT", 4, -3)
    inputBox:SetPoint("BOTTOMRIGHT", inputBoxBg, "BOTTOMRIGHT", -4, 3)
    inputBox:SetAutoFocus(false)
    inputBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    inputBox:SetJustifyH("CENTER")
    inputBox:SetText("1")
    inputBox:SetTextColor(0.95, 0.90, 0.80)
    inputBox:SetNumeric(true)
    inputBox:SetFrameLevel(inputBoxBg:GetFrameLevel() + 1)
    inputBox:SetScript("OnEscapePressed", function() inputBox:ClearFocus() end)
    inputBox:SetScript("OnEnterPressed", function() inputBox:ClearFocus() end)

    local decrementBtn = CreateSimpleButton(panel, 20, "-")
    decrementBtn:SetPoint("RIGHT", inputBoxBg, "LEFT", -1, 0)


    -- 搜索框 (Frame 容器承载 Backdrop + 裸 EditBox)
    local searchBg = CreateFrame("Frame", nil, panel)
    searchBg:SetWidth(180)
    searchBg:SetHeight(24)
    searchBg:SetPoint("BOTTOMLEFT", leftPage, "BOTTOMLEFT", 20, 15)
    searchBg:SetFrameLevel(panel:GetFrameLevel() + 5)
    searchBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    searchBg:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
    searchBg:SetBackdropBorderColor(0.45, 0.35, 0.20, 0.70)

    local searchBox = CreateFrame("EditBox", nil, searchBg)
    searchBox:SetPoint("TOPLEFT", searchBg, "TOPLEFT", 6, -4)
    searchBox:SetPoint("BOTTOMRIGHT", searchBg, "BOTTOMRIGHT", -6, 4)
    searchBox:SetAutoFocus(false)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 10)
    searchBox:SetTextColor(0.95, 0.90, 0.80)
    searchBox:SetFrameLevel(searchBg:GetFrameLevel() + 1)
    searchBox:SetTextInsets(2, 2, 0, 0)

    local searchPlaceholder = searchBg:CreateFontString(nil, "OVERLAY")
    searchPlaceholder:SetFont("Fonts\\FRIZQT__.TTF", 10)
    searchPlaceholder:SetPoint("LEFT", searchBg, "LEFT", 8, 0)
    searchPlaceholder:SetText("搜索...")
    searchPlaceholder:SetTextColor(0.55, 0.50, 0.40)

    local matsCheckbox = CreateCheckbox(panel, "有材料")
    matsCheckbox:SetPoint("LEFT", searchBg, "RIGHT", 10, 0)
    matsCheckbox:SetFrameLevel(panel:GetFrameLevel() + 5)
    matsCheckbox:SetChecked(false)


    -- ============================================================
    -- 8. 数据函数 (全部定义在此，闭包安全引用)
    -- ============================================================

    local function UpdateRankBar()
        if not currentMode then return end
        local name, rank, maxRank
        if currentMode == "tradeskill" then
            name, rank, maxRank = GetTradeSkillLine()
        elseif currentMode == "craft" then
            if GetCraftDisplaySkillLine then
                name, rank, maxRank = GetCraftDisplaySkillLine()
            end
            if not name then
                name = GetCraftName and GetCraftName() or "Craft"
            end
        end
        -- 标题用显示名（Tab 上的名字），保证一致
        local displayName = activeProfName and (PROF_DISPLAY_NAME[activeProfName] or activeProfName)
        if displayName then title:SetText(displayName)
        elseif name then title:SetText(name) end
        rank = rank or 0
        maxRank = maxRank or 0
        rankBar:Show()
        rankBar:SetMinMaxValues(0, math.max(maxRank, 1))
        rankBar:SetValue(rank)
        if maxRank > 0 then
            local rankName = "初级"
            if maxRank >= 300 then rankName = "大师"
            elseif maxRank >= 225 then rankName = "专家"
            elseif maxRank >= 150 then rankName = "熟练"
            end
            rankText:SetText(rankName .. "  " .. rank .. " / " .. maxRank)
            rankBarBg:Show()
        else
            rankText:SetText("")
            rankBarBg:Hide()
        end
    end

    local UpdateDetail  -- 前向声明，供 UpdateRecipeList 内部引用

    local function UpdateRecipeList()
        if not currentMode then return end
        local numItems = 0
        if currentMode == "tradeskill" then
            numItems = GetNumTradeSkills() or 0
        elseif currentMode == "craft" then
            numItems = GetNumCrafts() or 0
        end

        local searchText = searchBox:GetText() or ""
        searchText = string.lower(searchText)
        if searchText == "" then searchText = nil end

        local visibleItems = {}
        local lastHeaderIndex = nil
        local lastHeaderConfirmed = false

        for i = 1, numItems do
            local name, skillType, numAvail, isExpanded, subName
            if currentMode == "tradeskill" then
                name, skillType, numAvail, isExpanded = GetTradeSkillInfo(i)
            elseif currentMode == "craft" then
                local n, sub, st, na, ie = GetCraftInfo(i)
                name, skillType, numAvail, isExpanded = n, st, na, ie
                subName = sub
            end

            if name then
                local isHeader = (skillType == "header")
                if isHeader then
                    -- 连续 header 时，确认上一个 pending 的 header（分组层级应显示）
                    if lastHeaderIndex and not lastHeaderConfirmed then
                        local h = visibleItems[lastHeaderIndex]
                        if h and h.pending then h.pending = nil end
                    end
                    lastHeaderIndex = table.getn(visibleItems) + 1
                    lastHeaderConfirmed = false
                    -- 折叠状态的 header 直接确认（子项被 API 隐藏，不会出现在循环中）
                    local isPending = isExpanded and true or false
                    table.insert(visibleItems, {
                        index = i, name = name, skillType = skillType,
                        numAvail = numAvail, isExpanded = isExpanded,
                        isHeader = true, pending = isPending,
                    })
                else
                    local passSearch = not searchText or string.find(string.lower(name), searchText, 1, true)
                    local passMats = not filterHasMats or (numAvail and numAvail > 0)
                    if passSearch and passMats then
                        if not lastHeaderConfirmed and lastHeaderIndex then
                            local h = visibleItems[lastHeaderIndex]
                            if h and h.pending then h.pending = nil end
                            lastHeaderConfirmed = true
                        end
                        table.insert(visibleItems, {
                            index = i, name = name, skillType = skillType,
                            numAvail = numAvail, isExpanded = isExpanded,
                            isHeader = false, subName = subName,
                        })
                    end
                end
            end
        end

        -- 去掉无子项的 header
        local cleanItems = {}
        for _, item in ipairs(visibleItems) do
            if not item.pending then
                table.insert(cleanItems, item)
            end
        end

        local maxOffset = math.max(0, table.getn(cleanItems) - MAX_RECIPE_BUTTONS)
        if scrollOffset > maxOffset then scrollOffset = maxOffset end

        -- 过滤后检查 selectedIndex 是否仍可见，不可见则自动重选
        if selectedIndex then
            local selectionVisible = false
            for _, item in ipairs(cleanItems) do
                if not item.isHeader and item.index == selectedIndex then
                    selectionVisible = true
                    break
                end
            end
            if not selectionVisible then
                selectedIndex = nil
                for _, item in ipairs(cleanItems) do
                    if not item.isHeader then selectedIndex = item.index; break end
                end
                UpdateDetail()
            end
        end

        for i = 1, MAX_RECIPE_BUTTONS do
            local btn = recipeButtons[i]
            local item = cleanItems[scrollOffset + i]
            if item then
                btn.recipeIndex = item.index
                btn.isHeader = item.isHeader
                btn.isExpanded = item.isExpanded
                if item.isHeader then
                    -- Header 行: 折叠图标 + 名称，无产物图标
                    btn.collapseIcon:SetText(item.isExpanded and "-" or "+")
                    btn.collapseIcon:Show()
                    btn.recipeIcon:Hide()
                    -- 锚定到按钮本身 (避免 FontString→FontString 锚定在 1.12 中边界计算不可靠)
                    btn.nameText:ClearAllPoints()
                    btn.nameText:SetPoint("LEFT", btn, "LEFT", 18, 0)
                    btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                    btn.nameText:SetText(item.name)
                    local hc = DIFFICULTY_COLORS.header
                    btn.nameText:SetTextColor(hc[1], hc[2], hc[3])
                    btn.nameText:SetFont("Fonts\\FRIZQT__.TTF", 13)
                    -- 非首行 header 显示分隔线
                    if i > 1 then btn.headerSep:Show() else btn.headerSep:Hide() end
                else
                    -- 配方行: 产物图标 + 名称
                    btn.collapseIcon:SetText("")
                    btn.collapseIcon:Hide()
                    btn.headerSep:Hide()
                    local texture
                    if currentMode == "tradeskill" then
                        texture = GetTradeSkillIcon(item.index)
                    elseif currentMode == "craft" then
                        texture = GetCraftIcon(item.index)
                    end
                    if texture then
                        btn.recipeIcon:SetTexture(texture)
                        btn.recipeIcon:Show()
                        btn.nameText:ClearAllPoints()
                        btn.nameText:SetPoint("LEFT", btn.recipeIcon, "RIGHT", 4, 0)
                        btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                    else
                        btn.recipeIcon:Hide()
                        btn.nameText:ClearAllPoints()
                        btn.nameText:SetPoint("LEFT", btn, "LEFT", 20, 0)
                        btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                    end
                    local displayName = item.name
                    if item.subName and item.subName ~= "" then
                        local localSub = string.gsub(item.subName, "^Rank ", "等级 ")
                        displayName = displayName .. " (" .. localSub .. ")"
                    end
                    if item.numAvail and item.numAvail > 0 then
                        displayName = displayName .. " [" .. item.numAvail .. "]"
                    end
                    btn.nameText:SetText(displayName)
                    local dc = DIFFICULTY_COLORS[item.skillType] or DIFFICULTY_COLORS.default
                    btn.nameText:SetTextColor(dc[1], dc[2], dc[3])
                    btn.nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                end
                SetButtonSelected(btn, not item.isHeader and item.index == selectedIndex)
                btn:Show()
            else
                btn.recipeIndex = nil
                btn.isHeader = false
                btn.recipeIcon:Hide()
                btn.headerSep:Hide()
                btn:Hide()
            end
        end

        -- 折叠按钮状态
        local anyCollapsed = false
        for _, item in ipairs(cleanItems) do
            if item.isHeader and not item.isExpanded then anyCollapsed = true; break end
        end
        collapseAllText:SetText(anyCollapsed and "+" or "-")
    end

    UpdateDetail = function()
        if not selectedIndex or not currentMode then
            detailFrame:Hide()
            return
        end

        local ok, name, skillType, numAvail, texture, numReagents, cooldown, description

        if currentMode == "tradeskill" then
            ok, name, skillType, numAvail = pcall(GetTradeSkillInfo, selectedIndex)
            if not ok then detailFrame:Hide(); return end
            local texOk, tex = pcall(GetTradeSkillIcon, selectedIndex)
            texture = texOk and tex or nil
            local nrOk, nr = pcall(GetTradeSkillNumReagents, selectedIndex)
            numReagents = nrOk and nr or 0
            local cdOk, cd = pcall(GetTradeSkillCooldown, selectedIndex)
            cooldown = cdOk and cd or nil
            if GetTradeSkillDescription then
                local descOk, desc = pcall(GetTradeSkillDescription, selectedIndex)
                description = descOk and desc or nil
            end
        elseif currentMode == "craft" then
            local n, sub, st, na
            ok, n, sub, st, na = pcall(GetCraftInfo, selectedIndex)
            if not ok then detailFrame:Hide(); return end
            name, skillType, numAvail = n, st, na
            local texOk, tex = pcall(GetCraftIcon, selectedIndex)
            texture = texOk and tex or nil
            local nrOk, nr = pcall(GetCraftNumReagents, selectedIndex)
            numReagents = nrOk and nr or 0
            local cdOk, cd = pcall(GetCraftCooldown, selectedIndex)
            cooldown = cdOk and cd or nil
            if GetCraftDescription then
                local descOk, desc = pcall(GetCraftDescription, selectedIndex)
                description = descOk and desc or nil
            end
        end

        if not name or skillType == "header" then
            detailFrame:Hide()
            return
        end
        detailFrame:Show()

        detailIcon:SetTexture(texture)
        detailName:SetText(name)
        detailSubText:SetText("")

        -- 冷却
        if cooldown and cooldown > 0 then
            local h = math.floor(cooldown / 3600)
            local m = math.floor((cooldown - h * 3600) / 60)
            detailCooldown:SetText(h > 0 and ("冷却: " .. h .. "h " .. m .. "m") or ("冷却: " .. m .. "m"))
            detailCooldown:Show()
        else
            detailCooldown:SetText("")
            detailCooldown:Hide()
        end

        detailRequire:SetText("")
        detailRequire:Hide()

        -- 训练点数已挪到按钮左侧 trainingPointsText，这里隐藏避免重复
        detailPoints:SetText(""); detailPoints:Hide()

        -- 描述
        if description and description ~= "" then
            detailDesc:SetText(description); detailDesc:Show()
        else
            detailDesc:SetText(""); detailDesc:Hide()
        end

        -- 材料标签动态锚点
        local anchor = detailSubText
        if detailCooldown:IsShown() then anchor = detailCooldown end
        if detailRequire:IsShown() then anchor = detailRequire end
        if detailPoints:IsShown() then anchor = detailPoints end
        if detailDesc:IsShown() then anchor = detailDesc end
        reagentLabel:ClearAllPoints()
        reagentLabel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -43, -30)

        numReagents = numReagents or 0
        if numReagents > 0 then reagentLabel:Show() else reagentLabel:Hide() end

        for i = 1, MAX_REAGENTS do
            local slot = reagentSlots[i]
            if i <= numReagents then
                local rName, rTex, rCount, pCount
                if currentMode == "tradeskill" then
                    rName, rTex, rCount, pCount = GetTradeSkillReagentInfo(selectedIndex, i)
                elseif currentMode == "craft" then
                    rName, rTex, rCount, pCount = GetCraftReagentInfo(selectedIndex, i)
                end
                if rName then
                    slot.icon:SetTexture(rTex)
                    slot.nameText:SetText(rName)
                    pCount = pCount or 0
                    slot.countText:SetText("(" .. pCount .. "/" .. rCount .. ")")
                    local enough = pCount >= rCount
                    local r, g, b = 0.20, 0.15, 0.10
                    if not enough then r, g, b = 0.80, 0.10, 0.10 end
                    slot.nameText:SetTextColor(r, g, b)
                    slot.countText:SetTextColor(r, g, b)
                    slot.reagentIndex = i
                    slot:ClearAllPoints()
                    local col = math.mod(i - 1, 2)
                    local row = math.floor((i - 1) / 2)
                    slot:SetPoint("TOPLEFT", reagentLabel, "BOTTOMLEFT", col * 160, -5 - row * 42)
                    slot:Show()
                else
                    slot:Hide()
                end
            else
                slot:Hide()
            end
        end

        -- TradeSkill 专属控件可见性
        local isTrade = (currentMode == "tradeskill")
        if isTrade then createAllBtn:Show() else createAllBtn:Hide() end
        if isTrade then inputBoxBg:Show() else inputBoxBg:Hide() end
        if isTrade then decrementBtn:Show() else decrementBtn:Hide() end
        if isTrade then incrementBtn:Show() else incrementBtn:Hide() end
        if isTrade then inputBox:SetText("1") end
        -- "有材料"勾选框仅 TradeSkill 有用
        if isTrade then matsCheckbox:Show() else matsCheckbox:Hide() end
        -- 按钮文字：宠物训练用"学习"，其他 Craft(附魔) 和 TradeSkill 用"制作"
        local isPetTraining = (activeProfName == "训练野兽" or activeProfName == "Pet Training" or activeProfName == "Beast Training")
        if createBtn.label then
            createBtn.label:SetText(isPetTraining and "学习" or "制作")
        end
        -- 宠物训练即刻学习无法取消，隐藏取消按钮
        if isPetTraining then cancelBtn:Hide() else cancelBtn:Show() end
        -- 训练点数文字（仅宠物训练显示在按钮左侧）
        if isPetTraining and GetPetTrainingPoints then
            local total, spent = GetPetTrainingPoints()
            if total and total > 0 then
                trainingPointsText:SetText("训练点: " .. (total - (spent or 0)))
                trainingPointsText:Show()
            else
                trainingPointsText:Hide()
            end
        else
            trainingPointsText:Hide()
        end
    end

    -- ============================================================
    -- 9. 绑定 OnClick/OnEvent 到已定义函数
    -- ============================================================

    -- 配方按钮点击 (WoW 1.12: 用 this 代替循环变量，避免闭包捕获问题)
    for _, btn in ipairs(recipeButtons) do
        btn:SetScript("OnClick", function()
            if this.isHeader then
                if currentMode == "tradeskill" then
                    if this.isExpanded then
                        CollapseTradeSkillSubClass(this.recipeIndex)
                    else
                        ExpandTradeSkillSubClass(this.recipeIndex)
                    end
                    UpdateRecipeList()
                end
            else
                selectedIndex = this.recipeIndex
                UpdateDetail()
                UpdateRecipeList()
            end
        end)
        btn:SetScript("OnEnter", function()
            if not this.isHeader and this.recipeIndex then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                if currentMode == "tradeskill" then
                    GameTooltip:SetTradeSkillItem(this.recipeIndex)
                elseif currentMode == "craft" then
                    GameTooltip:SetCraftSpell(this.recipeIndex)
                end
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- 材料格 tooltip (this = iconFrame, :GetParent() = slot)
    for _, slot in ipairs(reagentSlots) do
        slot.iconFrame:SetScript("OnEnter", function()
            local s = this:GetParent()
            if s.reagentIndex and selectedIndex then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                if currentMode == "tradeskill" then
                    GameTooltip:SetTradeSkillItem(selectedIndex, s.reagentIndex)
                elseif currentMode == "craft" then
                    GameTooltip:SetCraftItem(selectedIndex, s.reagentIndex)
                end
                GameTooltip:Show()
            end
        end)
        slot.iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- 详情图标 tooltip
    detailIconBtn:SetScript("OnEnter", function()
        if selectedIndex then
            GameTooltip:SetOwner(detailIconBtn, "ANCHOR_RIGHT")
            if currentMode == "tradeskill" then
                GameTooltip:SetTradeSkillItem(selectedIndex)
            elseif currentMode == "craft" then
                GameTooltip:SetCraftSpell(selectedIndex)
            end
            GameTooltip:Show()
        end
    end)
    detailIconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- 折叠全部
    collapseAllBtn:SetScript("OnClick", function()
        if currentMode == "tradeskill" then
            -- 判断当前状态
            local anyCollapsed = false
            local num = GetNumTradeSkills() or 0
            for i = 1, num do
                local _, st, _, ie = GetTradeSkillInfo(i)
                if st == "header" and not ie then anyCollapsed = true; break end
            end
            if anyCollapsed then
                ExpandTradeSkillSubClass(0)
            else
                CollapseTradeSkillSubClass(0)
            end
            UpdateRecipeList()
        end
    end)

    -- 操作按钮
    createBtn:SetScript("OnClick", function()
        if not selectedIndex then return end
        if currentMode == "tradeskill" then
            local count = tonumber(inputBox:GetText()) or 1
            DoTradeSkill(selectedIndex, count)
        elseif currentMode == "craft" then
            DoCraft(selectedIndex)
        end
    end)
    cancelBtn:SetScript("OnClick", function() SpellStopCasting() end)
    createAllBtn:SetScript("OnClick", function()
        if not selectedIndex or currentMode ~= "tradeskill" then return end
        local _, _, numAvail = GetTradeSkillInfo(selectedIndex)
        if numAvail and numAvail > 0 then
            DoTradeSkill(selectedIndex, numAvail)
        end
    end)
    decrementBtn:SetScript("OnClick", function()
        local v = tonumber(inputBox:GetText()) or 1
        if v > 1 then inputBox:SetText(tostring(v - 1)) end
    end)
    incrementBtn:SetScript("OnClick", function()
        local v = tonumber(inputBox:GetText()) or 1
        inputBox:SetText(tostring(v + 1))
    end)

    -- 搜索框
    searchBox:SetScript("OnTextChanged", function()
        local t = searchBox:GetText() or ""
        if t == "" then searchPlaceholder:Show() else searchPlaceholder:Hide() end
        UpdateRecipeList()
    end)
    searchBox:SetScript("OnEscapePressed", function() searchBox:ClearFocus() end)

    -- 有材料过滤
    matsCheckbox:SetScript("OnClick", function()
        filterHasMats = not filterHasMats
        matsCheckbox:SetChecked(filterHasMats)
        UpdateRecipeList()
    end)

    -- 滚轮 (上限由 UpdateRecipeList 内部 clamp，此处只管方向)
    listFrame:EnableMouseWheel(true)
    listFrame:SetScript("OnMouseWheel", function()
        if arg1 > 0 then
            scrollOffset = math.max(0, scrollOffset - 3)
        else
            scrollOffset = scrollOffset + 3
        end
        UpdateRecipeList()
    end)

    -- ============================================================
    -- 10. Tab 系统
    -- ============================================================
    local tabPool = {}
    local tabPoolSize = 0
    local knownProfessions = {}

    local function ReleaseAllTabs()
        for i = 1, tabPoolSize do
            tabPool[i]:SetSelected(false)
            tabPool[i]:Hide()
        end
        panel.Tabs = {}
        panel.selectedTab = nil
        tabPoolSize = 0
    end

    local function AcquireTab(text, onClick, tabWidth, spacing)
        tabPoolSize = tabPoolSize + 1
        local tab = tabPool[tabPoolSize]
        if tab then
            tab.Text:SetText(text)
            tab:SetScript("OnClick", function()
                PlaySound("igCharacterInfoTab")
                if panel.selectedTab then panel.selectedTab:SetSelected(false) end
                tab:SetSelected(true)
                panel.selectedTab = tab
                if onClick then onClick() end
            end)
            tab:ClearAllPoints()
            local n = table.getn(panel.Tabs)
            if n == 0 then tab:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 8, -30)
            else tab:SetPoint("BOTTOMLEFT", panel.Tabs[n], "BOTTOMRIGHT", spacing or 4, 0) end
            tab:SetSelected(false)
            tab:Show()
            table.insert(panel.Tabs, tab)
        else
            tab = panel:AddTab(text, onClick, tabWidth, spacing)
            tabPool[tabPoolSize] = tab
        end
        return tab
    end

    -- 已知能打开专业面板的法术名（中英文）
    local PROFESSION_SPELLS = {
        ["Alchemy"] = true, ["炼金术"] = true,
        ["Blacksmithing"] = true, ["锻造"] = true,
        ["Cooking"] = true, ["烹饪"] = true,
        ["Enchanting"] = true, ["附魔"] = true,
        ["Engineering"] = true, ["工程学"] = true,
        ["First Aid"] = true, ["急救"] = true,
        ["Leatherworking"] = true, ["制皮"] = true,
        ["Smelting"] = true, ["熔炼"] = true,
        ["Tailoring"] = true, ["裁缝"] = true,
        ["Beast Training"] = true, ["宠物训练"] = true,
        ["野兽训练"] = true, ["宠物技能"] = true, ["训练野兽"] = true,
    }

    -- 扫描法术书综合 tab（第1页），匹配已知专业名
    local function ScanSpellbookForProfessions()
        knownProfessions = {}
        local _, _, tabOffset, tabNumSpells = GetSpellTabInfo(1)
        if not tabOffset or not tabNumSpells then return end
        for i = 1, tabNumSpells do
            local si = tabOffset + i
            local spellName = GetSpellName(si, BOOKTYPE_SPELL)
            if spellName and PROFESSION_SPELLS[spellName] then
                table.insert(knownProfessions, {
                    name = spellName,
                    spellIndex = si,
                    texture = GetSpellTexture(si, BOOKTYPE_SPELL),
                })
            end
        end
    end

    -- 延迟到法术书数据就绪后扫描（初始化时 GetNumSpellTabs 为 0）
    local profScanned = false

    local function CreateProfessionTabs()
        ReleaseAllTabs()
        local currentName
        if currentMode == "tradeskill" then currentName = GetTradeSkillLine()
        elseif currentMode == "craft" then currentName = GetCraftName and GetCraftName() or nil end

        for i, prof in ipairs(knownProfessions) do
            local captured = prof
            local displayName = PROF_DISPLAY_NAME[prof.name] or prof.name
            local tab = AcquireTab(displayName, function()
                -- 已选中的 tab 不重复施法（避免 CLOSE 关闭面板）
                if activeProfName and captured.name == activeProfName then return end
                CastSpell(captured.spellIndex, BOOKTYPE_SPELL)
            end, nil, (i == 1 and 2 or 4))
            if currentName and prof.name == currentName then
                tab:SetSelected(true)
                panel.selectedTab = tab
            end
        end
    end

    -- ============================================================
    -- 11. 面板打开/关闭
    -- ============================================================

    local function OpenProfession(mode)
        currentMode = mode
        selectedIndex = nil
        scrollOffset = 0
        searchBox:SetText("")

        -- 不 Hide 原生面板! 用 SetAlpha(0) 保持 API 连接
        -- ADDON_LOADED hook 已处理原生面板透明化

        -- 记录当前专业名（转换为 Tab 上显示的法术名）
        local apiName
        if mode == "tradeskill" then apiName = GetTradeSkillLine()
        elseif mode == "craft" then apiName = GetCraftName and GetCraftName() or nil end
        activeProfName = PROF_API_TO_SPELL[apiName] or apiName

        UpdateRankBar()
        if not profScanned then
            ScanSpellbookForProfessions()
            if table.getn(knownProfessions) > 0 then profScanned = true end
            CreateProfessionTabs()
        elseif table.getn(panel.Tabs) == 0 then
            CreateProfessionTabs()
        else
            -- Tab 已存在，只更新选中状态（保留点击动画）
            if panel.selectedTab then panel.selectedTab:SetSelected(false) end
            panel.selectedTab = nil
            local activeDisplay = activeProfName and (PROF_DISPLAY_NAME[activeProfName] or activeProfName)
            for _, tab in ipairs(panel.Tabs) do
                if tab.Text and activeDisplay and tab.Text:GetText() == activeDisplay then
                    tab:SetSelected(true)
                    panel.selectedTab = tab
                end
            end
        end

        -- 自动选中第一个非 header
        local numItems = 0
        if mode == "tradeskill" then numItems = GetNumTradeSkills() or 0
        elseif mode == "craft" then numItems = GetNumCrafts() or 0 end
        for i = 1, numItems do
            local name, skillType
            if mode == "tradeskill" then name, skillType = GetTradeSkillInfo(i)
            elseif mode == "craft" then
                local n, _, st = GetCraftInfo(i)
                name, skillType = n, st
            end
            if name and skillType ~= "header" then selectedIndex = i; break end
        end

        if mode == "tradeskill" then collapseAllBtn:Show() else collapseAllBtn:Hide() end
        UpdateDetail()
        UpdateRecipeList()
        panel:Show()
    end

    panel:SetScript("OnShow", function() PlaySound("igSpellBookOpen") end)
    panel:SetScript("OnHide", function()
        if isClosing then return end
        isClosing = true
        PlaySound("igSpellBookClose")
        if currentMode == "tradeskill" then CloseTradeSkill()
        elseif currentMode == "craft" then CloseCraft() end
        currentMode = nil
        activeProfName = nil
        isClosing = false
    end)

    -- ============================================================
    -- 12. 事件系统
    -- ============================================================
    panel:RegisterEvent("ADDON_LOADED")
    panel:RegisterEvent("TRADE_SKILL_SHOW")
    panel:RegisterEvent("TRADE_SKILL_CLOSE")
    panel:RegisterEvent("TRADE_SKILL_UPDATE")
    panel:RegisterEvent("CRAFT_SHOW")
    panel:RegisterEvent("CRAFT_CLOSE")
    panel:RegisterEvent("CRAFT_UPDATE")
    panel:RegisterEvent("UNIT_PET_TRAINING_POINTS")

    panel:SetScript("OnEvent", function()
        if event == "TRADE_SKILL_SHOW" then
            tradeSkillOpen = true
            craftOpen = false
            OpenProfession("tradeskill")
        elseif event == "CRAFT_SHOW" then
            craftOpen = true
            tradeSkillOpen = false
            OpenProfession("craft")
        elseif event == "TRADE_SKILL_CLOSE" then
            tradeSkillOpen = false
            if not isClosing and not craftOpen and panel:IsShown() then panel:Hide() end
        elseif event == "CRAFT_CLOSE" then
            craftOpen = false
            if not isClosing and not tradeSkillOpen and panel:IsShown() then panel:Hide() end
        elseif event == "TRADE_SKILL_UPDATE" then
            if currentMode == "tradeskill" and panel:IsShown() then
                UpdateRankBar(); UpdateRecipeList(); UpdateDetail()
            end
        elseif event == "CRAFT_UPDATE" then
            if currentMode == "craft" and panel:IsShown() then
                UpdateRankBar(); UpdateRecipeList(); UpdateDetail()
            end
        elseif event == "UNIT_PET_TRAINING_POINTS" then
            if currentMode == "craft" and panel:IsShown() then UpdateDetail() end
        elseif event == "ADDON_LOADED" then
            -- 透明化原生面板 (保持 API 连接，不 Hide)
            if arg1 == "Blizzard_TradeSkillUI" and TradeSkillFrame and not tradeSkillHooked then
                tradeSkillHooked = true
                HookScript(TradeSkillFrame, "OnShow", function() HideNativeFrame(TradeSkillFrame) end)
                if TradeSkillFrame:IsShown() then HideNativeFrame(TradeSkillFrame) end
            end
            if arg1 == "Blizzard_CraftUI" and CraftFrame and not craftHooked then
                craftHooked = true
                HookScript(CraftFrame, "OnShow", function() HideNativeFrame(CraftFrame) end)
                if CraftFrame:IsShown() then HideNativeFrame(CraftFrame) end
            end
        end
    end)

    -- 竞态修复: 若原生面板在本模块加载前已存在，立即 hook
    if TradeSkillFrame and not tradeSkillHooked then
        tradeSkillHooked = true
        HookScript(TradeSkillFrame, "OnShow", function() HideNativeFrame(TradeSkillFrame) end)
    end
    if CraftFrame and not craftHooked then
        craftHooked = true
        HookScript(CraftFrame, "OnShow", function() HideNativeFrame(CraftFrame) end)
    end

    panel:Hide()
    table.insert(UISpecialFrames, panel:GetName())

    local callbacks = {}
    DFUI:NewCallbacks("TradeSkill", callbacks)
end)
