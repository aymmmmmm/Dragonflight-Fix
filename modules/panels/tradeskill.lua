-- tradeskill.lua — 统一专业技能面板 (TradeSkill + Craft)
-- DF 风格，右侧专业背景画（DF retail 10.1 素材），1069x658 大框体
-- 核心策略: 原生面板 SetAlpha(0)+EnableMouse(false) 保持 API 连接，自建面板覆盖其上

setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")
local PROF_TEX = TEX .. "panels\\df\\professions\\"

local CLASS_ICON_COORDS = DFUI_CLASS_ICON_COORDS

-- API 专业名/法术名 → 背景画 key（PROF_BG_KEY）
local PROF_BG_KEY = {
    ["Alchemy"]="alchemy", ["炼金术"]="alchemy",
    ["Blacksmithing"]="blacksmithing", ["锻造"]="blacksmithing",
    ["Cooking"]="cooking", ["烹饪"]="cooking",
    ["Enchanting"]="enchanting", ["附魔"]="enchanting",
    ["Engineering"]="engineering", ["工程学"]="engineering",
    ["First Aid"]="default", ["急救"]="default",
    ["Fishing"]="fishing", ["钓鱼"]="fishing",
    ["Herbalism"]="herbalism", ["草药学"]="herbalism",
    ["Leatherworking"]="leatherworking", ["制皮"]="leatherworking",
    ["Mining"]="mining", ["采矿"]="mining",
    ["Smelting"]="mining", ["熔炼"]="mining",
    ["Skinning"]="skinning", ["剥皮"]="skinning",
    ["Tailoring"]="tailoring", ["裁缝"]="tailoring",
    ["Beast Training"]="default", ["宠物训练"]="default",
    ["野兽训练"]="default", ["宠物技能"]="default", ["训练野兽"]="default",
}

-- ============================================================
-- DF retail Atlas 切片表 (来自 _references/dragonflight_ui/db2_csv 三表 join)
-- 用法: ApplyAtlas(tex, "icon-skill-high") → SetTexture + SetTexCoord
-- TGA 资源: atlas_main.tga ← interface/professions/professions.blp (2048×1024 ARGB8888)
-- 经 _tools/blp2_to_tga_512.js 解码，WoW 1.12 原生支持 BGRA32 TGA
-- ============================================================
local ATLAS_MAIN = PROF_TEX .. "atlas_main.tga"  -- 2048×1024 (retail professions.blp)

local ATLAS_SIZE = {
    [ATLAS_MAIN] = {2048, 1024},
}

local ATLAS = {
    -- key = {left, right, top, bottom, file, width, height}  (px on retail atlas)
    ["recipe-active"]          = {1614, 1881,  39,  58, ATLAS_MAIN, 267, 19 },  -- 选中行全宽 overlay (金色)
    ["recipe-hover"]           = {1275, 1584,  39,  60, ATLAS_MAIN, 309, 21 },  -- 悬停行全宽 overlay (暖色)
    ["icon-skill-high"]        = { 539,  552,  55,  70, ATLAS_MAIN,  13, 15 },
    ["icon-skill-medium"]      = { 604,  617,  55,  70, ATLAS_MAIN,  13, 15 },
    ["icon-skill-low"]         = { 524,  537,  55,  70, ATLAS_MAIN,  13, 15 },
}

-- ApplyAtlas: 把 atlas 元素切片到 tex 上
--   tex       Texture 对象
--   key       ATLAS 表的 key
--   applySize false 跳过 SetWidth/SetHeight (调用方手动控制尺寸时用)
local function ApplyAtlas(tex, key, applySize)
    local a = ATLAS[key]
    if not a then return end
    local l, r, t, b, file = a[1], a[2], a[3], a[4], a[5]
    local sz = ATLAS_SIZE[file] or {2048, 1024}
    local aw, ah = sz[1], sz[2]
    if tex.atlasFile ~= file then
        tex:SetTexture(file)
        tex.atlasFile = file
    end
    tex:SetTexCoord(l / aw, r / aw, t / ah, b / ah)
    if applySize ~= false then
        tex:SetWidth(a[6])
        tex:SetHeight(a[7])
    end
end

-- 难度颜色 (针对 DF 深色背景画优化对比度，文字全部加 OUTLINE 保证可读)
local DIFFICULTY_COLORS = {
    optimal  = {1.00, 0.50, 0.25},   -- 橙（最高收益）
    medium   = {1.00, 0.82, 0.00},   -- 金黄
    easy     = {0.40, 0.90, 0.40},   -- 亮绿
    trivial  = {0.75, 0.75, 0.75},   -- 银灰
    header   = {0.98, 0.91, 0.58},   -- 暖金（header 分组色）
    none     = {0.40, 0.90, 0.40},   -- 亮绿（未学）
    used     = {0.75, 0.75, 0.75},   -- 银灰（已学，同 trivial）
    default  = {0.90, 0.86, 0.76},   -- 亮米色
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
    local MAX_RECIPE_BUTTONS = 20
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

    -- 收藏机制：持久化到 DFUI_CUR_PROFILE.TradeSkillFavorites[专业名][配方名] = true
    local filterFavOnly = false
    local function GetFavTable()
        if not DFUI_CUR_PROFILE then return nil end
        if not DFUI_CUR_PROFILE.TradeSkillFavorites then
            DFUI_CUR_PROFILE.TradeSkillFavorites = {}
        end
        return DFUI_CUR_PROFILE.TradeSkillFavorites
    end
    local function IsFavorite(recipeName)
        if not activeProfName or not recipeName then return false end
        local t = GetFavTable(); if not t then return false end
        return t[activeProfName] and t[activeProfName][recipeName] or false
    end
    local function ToggleFavorite(recipeName)
        if not activeProfName or not recipeName then return end
        local t = GetFavTable(); if not t then return end
        if not t[activeProfName] then t[activeProfName] = {} end
        if t[activeProfName][recipeName] then
            t[activeProfName][recipeName] = nil
        else
            t[activeProfName][recipeName] = true
        end
    end

    -- ============================================================
    -- 1. 面板框架 (1069x658，DF retail Professions 等比)
    -- ============================================================
    local panel = DFUI.CreatePaperDollFrame("DFUI_ProfessionFrame", UIParent, 1069, 658, 1)
    panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 30, -104)
    panel:SetFrameStrata("MEDIUM")
    panel:SetFrameLevel(25)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function() panel:StartMoving() end)
    panel:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)
    panel:SetScale(0.85)

    -- ============================================================
    -- 2. 左右分栏容器 + 右侧专业背景画
    --    leftColumn: 274 宽，放配方列表
    --    rightColumn: 763 宽，放详情，底图是专业背景画
    -- ============================================================
    local leftColumn = CreateFrame("Frame", nil, panel)
    leftColumn:SetWidth(274)
    leftColumn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -68)
    leftColumn:SetPoint("BOTTOM", panel, "BOTTOM", 0, 16)
    leftColumn:SetFrameLevel(panel:GetFrameLevel() + 1)
    -- 左栏暗底 (无边框)，分隔配方列表与右侧背景画
    local leftColumnBg = leftColumn:CreateTexture(nil, "BACKGROUND")
    leftColumnBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    leftColumnBg:SetAllPoints(leftColumn)
    leftColumnBg:SetVertexColor(0.10, 0.07, 0.04, 0.92)

    local rightColumn = CreateFrame("Frame", nil, panel)
    rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", 8, 0)
    rightColumn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16)
    rightColumn:SetFrameLevel(panel:GetFrameLevel() + 1)
    -- 右栏裸 Frame，由内部 detailBg 专业背景画填充

    -- 右侧专业背景画（占满 rightColumn 内部）
    -- retail BLP 1024×1024 实际内容只在左上 676×549 (= recipe-background atlas region)，
    -- 降采样到 512×512 后内容 339×275。用 SetTexCoord 裁出有效区域再拉伸填满
    local detailBg = rightColumn:CreateTexture(nil, "BACKGROUND")
    detailBg:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 4, -4)
    detailBg:SetPoint("BOTTOMRIGHT", rightColumn, "BOTTOMRIGHT", -4, 4)
    detailBg:SetTexture(PROF_TEX .. "bg_default.tga")
    detailBg:SetTexCoord(0, 339/512, 0, 275/512)

    -- ============================================================
    -- 3. 专业图标 + 标题 + 关闭按钮
    -- ============================================================
    -- 左上角职业图标 (圆形 UI-Classes-Circles atlas)
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

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16)
    title:SetText("专业技能")
    title:SetTextColor(1.00, 0.82, 0.00)
    title:SetPoint("TOP", panel, "TOP", 0, -10)

    local closeBtn = DFUI.CreateRedButton(panel, "close", function() panel:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)

    -- ============================================================
    -- 4. 熟练度进度条
    -- ============================================================
    -- 熟练度条: StatusBar + retail atlas 切片 recipe-active (267×19 金色横条)
    -- 替代之前的项目自制 rankbar_fill.tga, 全 retail 数据
    local rankBarBg = CreateFrame("Frame", nil, panel)
    rankBarBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 60, -38)
    rankBarBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -60, -38)
    rankBarBg:SetHeight(18)
    rankBarBg:SetFrameLevel(panel:GetFrameLevel() + 2)
    local rankBarBgTex = rankBarBg:CreateTexture(nil, "BACKGROUND")
    rankBarBgTex:SetTexture("Interface\\Buttons\\WHITE8X8")
    rankBarBgTex:SetAllPoints(rankBarBg)
    rankBarBgTex:SetVertexColor(0.10, 0.07, 0.04, 0.92)

    local rankBar = CreateFrame("StatusBar", nil, rankBarBg)
    rankBar:SetPoint("TOPLEFT", rankBarBg, "TOPLEFT", 3, -3)
    rankBar:SetPoint("BOTTOMRIGHT", rankBarBg, "BOTTOMRIGHT", -3, 3)
    -- StatusBar fill 用 atlas_main 切片 qualitybar-bg (186×26 实心 mask, alpha avg 212)
    -- retail atlas 元素是黑色 alpha mask，VertexColor 染金色得到 retail 金条效果
    local rankFillTex = rankBar:CreateTexture(nil, "ARTWORK")
    rankFillTex:SetTexture(ATLAS_MAIN)
    rankFillTex:SetTexCoord(717/2048, 902/2048, 1/1024, 26/1024)
    rankFillTex:SetVertexColor(1.00, 0.78, 0.20)  -- retail 金色
    rankBar:SetStatusBarTexture(rankFillTex)
    rankBar:SetMinMaxValues(0, 300)
    rankBar:SetValue(0)

    local rankText = rankBar:CreateFontString(nil, "OVERLAY")
    rankText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    rankText:SetPoint("CENTER", rankBar, "CENTER", 0, 0)
    rankText:SetTextColor(0.98, 0.91, 0.58)


    -- ============================================================
    -- 5. 左页 — 配方列表
    -- ============================================================
    local listFrame = CreateFrame("Frame", nil, panel)
    -- listFrame 顶移 28px 让出顶部 checkbox 区域 (-10 → -38)
    -- bottom 也调整 (原 72 = checkbox 14px + 下间距 58, 现 checkbox 上移后底部不需要 = 14)
    listFrame:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 12, -38)
    listFrame:SetPoint("BOTTOMRIGHT", leftColumn, "BOTTOMRIGHT", -12, 14)
    listFrame:SetFrameLevel(panel:GetFrameLevel() + 3)

    -- 折叠全部按钮（模拟原版 "全部" header 行）
    local collapseAllBtn = CreateFrame("Button", nil, listFrame)
    collapseAllBtn:SetHeight(16)
    -- collapseAllBtn 锚到 listFrame 顶部 (在 checkbox 下方, listFrame TOPLEFT 已下移到 -38)
    collapseAllBtn:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, 0)
    collapseAllBtn:SetPoint("RIGHT", listFrame, "RIGHT", -10, 0)
    local collapseAllText = collapseAllBtn:CreateFontString(nil, "OVERLAY")
    collapseAllText:SetFont("Fonts\\FRIZQT__.TTF", 10)
    collapseAllText:SetPoint("LEFT", collapseAllBtn, "LEFT", 2, 0)
    collapseAllText:SetWidth(14)
    collapseAllText:SetTextColor(0.98, 0.91, 0.58)
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
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        -- 收藏星标（左上角 8x8，普通行才显示）
        local favStar = btn:CreateTexture(nil, "OVERLAY")
        favStar:SetTexture("Interface\\COMMON\\ReputationStar")
        favStar:SetTexCoord(0, 0.25, 0, 0.5)
        favStar:SetWidth(10)
        favStar:SetHeight(10)
        favStar:SetPoint("LEFT", btn, "LEFT", -1, 4)
        favStar:SetVertexColor(1.0, 0.82, 0.0)
        favStar:Hide()
        btn.favStar = favStar

        -- Header 行深灰底色 (替代 1px 分隔线，retail 风格)
        local headerBg = btn:CreateTexture(nil, "BACKGROUND")
        headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        headerBg:SetAllPoints(btn)
        headerBg:SetVertexColor(0.14, 0.09, 0.05, 0.85)
        headerBg:Hide()
        btn.headerBg = headerBg

        -- 悬停: retail recipe-hover atlas (HIGHLIGHT 层 WoW 自动管理)
        -- atlas 是稀疏光晕设计 (alpha avg 29), ADD blend 让金色像素叠加到暗底上更显著
        local hoverOverlay = btn:CreateTexture(nil, "HIGHLIGHT")
        ApplyAtlas(hoverOverlay, "recipe-hover", false)
        hoverOverlay:SetAllPoints(btn)
        hoverOverlay:SetBlendMode("ADD")

        -- 选中: retail recipe-active atlas (alpha avg 38, ADD blend 增强视觉)
        local selectedOverlay = btn:CreateTexture(nil, "BORDER")
        ApplyAtlas(selectedOverlay, "recipe-active", false)
        selectedOverlay:SetAllPoints(btn)
        selectedOverlay:SetBlendMode("ADD")
        selectedOverlay:Hide()
        btn.selectedOverlay = selectedOverlay

        -- 配方产物图标
        local recipeIcon = btn:CreateTexture(nil, "ARTWORK")
        recipeIcon:SetWidth(20)
        recipeIcon:SetHeight(20)
        recipeIcon:SetPoint("LEFT", btn, "LEFT", 2, 0)
        recipeIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        recipeIcon:Hide()
        btn.recipeIcon = recipeIcon

        -- 难度图标 (DF retail icon-skill-high/medium/low, 仅 tradeskill 模式)
        local skillIcon = btn:CreateTexture(nil, "ARTWORK")
        skillIcon:SetWidth(13)
        skillIcon:SetHeight(15)
        skillIcon:Hide()
        btn.skillIcon = skillIcon

        local collapseIcon = btn:CreateFontString(nil, "OVERLAY")
        collapseIcon:SetFont("Fonts\\FRIZQT__.TTF", 10)
        collapseIcon:SetPoint("LEFT", btn, "LEFT", 2, 0)
        collapseIcon:SetWidth(14)
        collapseIcon:SetTextColor(0.98, 0.91, 0.58)
        btn.collapseIcon = collapseIcon

        local nameText = btn:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 12)
        nameText:SetPoint("LEFT", btn, "LEFT", 18, 0)
        nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
        nameText:SetJustifyH("LEFT")
        btn.nameText = nameText

        btn.recipeIndex = nil
        btn.isHeader = false
        return btn
    end

    local function SetButtonSelected(btn, isSelected)
        if isSelected then btn.selectedOverlay:Show() else btn.selectedOverlay:Hide() end
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
    detailFrame:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 20, -18)
    detailFrame:SetPoint("BOTTOMRIGHT", rightColumn, "BOTTOMRIGHT", -18, 48)
    detailFrame:SetFrameLevel(panel:GetFrameLevel() + 3)

    -- 局部 text panel 暗底 (retail QualityPane / InsetFrame 风格)
    -- 覆盖左上文字+3列材料网格区 (596×380), 右侧露 ~120px 让专业画显出，避免全屏画中画
    local textPanel = detailFrame:CreateTexture(nil, "BACKGROUND")
    textPanel:SetTexture("Interface\\Buttons\\WHITE8X8")
    textPanel:SetPoint("TOPLEFT", detailFrame, "TOPLEFT", 16, -16)
    textPanel:SetWidth(596)
    textPanel:SetHeight(380)
    textPanel:SetVertexColor(0.08, 0.05, 0.03, 0.60)

    -- 主产物图标 (retail OutputIcon 规格: 47×47 at TOPLEFT 28,-33)
    local detailIconBtn = CreateFrame("Button", nil, detailFrame)
    detailIconBtn:SetWidth(47)
    detailIconBtn:SetHeight(47)
    detailIconBtn:SetPoint("TOPLEFT", detailFrame, "TOPLEFT", 28, -33)

    local detailIcon = detailIconBtn:CreateTexture(nil, "BACKGROUND")
    detailIcon:SetAllPoints(detailIconBtn)
    detailIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Count 徽章 (retail OutputButton.Count, 多产物配方右下角数量)
    local detailIconCount = detailIconBtn:CreateFontString(nil, "OVERLAY")
    detailIconCount:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    detailIconCount:SetPoint("BOTTOMRIGHT", detailIconBtn, "BOTTOMRIGHT", -3, 2)
    detailIconCount:SetTextColor(1, 1, 1)
    detailIconCount:Hide()

    -- 主图标边框 (retail Slot-Frame-Blue, 严丝合缝包住图标)
    -- TGA 64×64 但实际边框内容在 (12,12)-(50,50)，用 TexCoord 裁掉外围透明 padding
    local detailIconBorder = detailIconBtn:CreateTexture(nil, "OVERLAY")
    detailIconBorder:SetTexture(PROF_TEX .. "slot_blue.tga")
    detailIconBorder:SetTexCoord(12/64, 51/64, 12/64, 51/64)
    detailIconBorder:SetAllPoints(detailIconBtn)

    -- detailName (retail GameFontHighlightMed2 ≈ 14pt, LEFT icon RIGHT +14,+17)
    -- 加 OUTLINE 因为浮在专业背景画上 (无暗底)
    local detailName = detailFrame:CreateFontString(nil, "OVERLAY")
    detailName:SetFont("Fonts\\FRIZQT__.TTF", 14)
    detailName:SetPoint("LEFT", detailIconBtn, "RIGHT", 14, 17)
    detailName:SetWidth(400)
    detailName:SetJustifyH("LEFT")
    detailName:SetTextColor(1.00, 0.82, 0.00)

    -- detail ☆ 收藏指示 (retail OutputText 旁的 favorite 标记)
    local detailFavStar = detailFrame:CreateTexture(nil, "OVERLAY")
    detailFavStar:SetTexture("Interface\\COMMON\\ReputationStar")
    detailFavStar:SetTexCoord(0, 0.25, 0, 0.5)
    detailFavStar:SetWidth(14); detailFavStar:SetHeight(14)
    detailFavStar:SetPoint("LEFT", detailName, "RIGHT", 4, 0)
    detailFavStar:SetVertexColor(1.0, 0.82, 0.0)
    detailFavStar:Hide()

    -- detailSubText (12pt OUTLINE, -5 间距)
    local detailSubText = detailFrame:CreateFontString(nil, "OVERLAY")
    detailSubText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    detailSubText:SetPoint("TOPLEFT", detailName, "BOTTOMLEFT", 0, -5)
    detailSubText:SetWidth(400)
    detailSubText:SetJustifyH("LEFT")
    detailSubText:SetTextColor(0.98, 0.91, 0.58)

    -- detailCooldown / Require / Points: -3 间距统一, OUTLINE 保可读
    local detailCooldown = detailFrame:CreateFontString(nil, "OVERLAY")
    detailCooldown:SetFont("Fonts\\FRIZQT__.TTF", 12)
    detailCooldown:SetPoint("TOPLEFT", detailSubText, "BOTTOMLEFT", 0, -3)
    detailCooldown:SetWidth(400)
    detailCooldown:SetTextColor(0.95, 0.90, 0.80)

    local detailRequire = detailFrame:CreateFontString(nil, "OVERLAY")
    detailRequire:SetFont("Fonts\\FRIZQT__.TTF", 12)
    detailRequire:SetPoint("TOPLEFT", detailCooldown, "BOTTOMLEFT", 0, -3)
    detailRequire:SetWidth(400)
    detailRequire:SetTextColor(0.95, 0.90, 0.80)

    local detailPoints = detailFrame:CreateFontString(nil, "OVERLAY")
    detailPoints:SetFont("Fonts\\FRIZQT__.TTF", 12)
    detailPoints:SetPoint("TOPLEFT", detailRequire, "BOTTOMLEFT", 0, -3)
    detailPoints:SetWidth(400)
    detailPoints:SetTextColor(0.98, 0.91, 0.58)

    -- detailDesc (12pt OUTLINE, 宽度 460)
    local detailDesc = detailFrame:CreateFontString(nil, "OVERLAY")
    detailDesc:SetFont("Fonts\\FRIZQT__.TTF", 12)
    detailDesc:SetPoint("TOPLEFT", detailPoints, "BOTTOMLEFT", 0, -3)
    detailDesc:SetWidth(460)
    detailDesc:SetJustifyH("LEFT")
    detailDesc:SetTextColor(0.90, 0.86, 0.72)

    -- reagentLabel (retail Reagents container Label, OUTLINE 保浮在背景画上可读)
    local reagentLabel = detailFrame:CreateFontString(nil, "OVERLAY")
    reagentLabel:SetFont("Fonts\\FRIZQT__.TTF", 13)
    reagentLabel:SetText("材料:")
    reagentLabel:SetTextColor(0.98, 0.91, 0.58)

    -- 材料格工厂 (retail ProfessionsReagentSlotBaseTemplate: 180×50 容器 + 39×39 按钮)
    local function CreateReagentSlot(parent)
        local slot = CreateFrame("Frame", nil, parent)
        slot:SetWidth(180)
        slot:SetHeight(50)

        local iconFrame = CreateFrame("Button", nil, slot)
        iconFrame:SetWidth(39)
        iconFrame:SetHeight(39)
        iconFrame:SetPoint("LEFT", slot, "LEFT", 0, 0)

        -- 仅图标 + 透明边框，无 slot-bg 暗底 (避免 8 个"独立小方块"散落感)
        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(iconFrame)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon = icon

        -- 材料槽边框 (retail Professions-Slot-Frame, OVERLAY 覆盖 icon)
        -- TGA 外围有 12px 透明 padding，TexCoord 裁掉
        local border = iconFrame:CreateTexture(nil, "OVERLAY")
        border:SetTexture(PROF_TEX .. "slot_neutral.tga")
        border:SetTexCoord(12/64, 51/64, 12/64, 51/64)
        border:SetAllPoints(iconFrame)
        slot.border = border

        -- nameText (retail LEFT x=46 from slot LEFT, i.e. iconFrame RIGHT +7, 无 OUTLINE)
        local nameText = slot:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 12)
        nameText:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 7, 0)
        nameText:SetPoint("RIGHT", slot, "RIGHT", -5, 0)
        nameText:SetJustifyH("LEFT")
        slot.nameText = nameText

        -- countText (retail BOTTOMRIGHT 小字, 我们用 TOPLEFT 下方 -2 间距)
        local countText = slot:CreateFontString(nil, "OVERLAY")
        countText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        countText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
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
        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 11)
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        label:SetText(text)
        label:SetTextColor(0.95, 0.90, 0.80)
        btn.label = label
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface\\Buttons\\WHITE8X8")
        hl:SetAllPoints(btn)
        hl:SetVertexColor(0.98, 0.91, 0.58, 0.18)
        hl:SetBlendMode("ADD")
        return btn
    end

    local createBtn = CreateSimpleButton(panel, 160, "制作")
    createBtn:SetPoint("BOTTOMRIGHT", rightColumn, "BOTTOMRIGHT", -20, 12)

    local cancelBtn = CreateSimpleButton(panel, 70, "取消")
    cancelBtn:SetPoint("RIGHT", createBtn, "LEFT", -6, 0)

    -- 训练点数显示（仅宠物训练模式，在取消按钮左侧）
    local trainingPointsText = panel:CreateFontString(nil, "OVERLAY")
    trainingPointsText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    trainingPointsText:SetPoint("RIGHT", cancelBtn, "LEFT", -12, 0)
    trainingPointsText:SetTextColor(0.98, 0.91, 0.58)
    trainingPointsText:Hide()

    local createAllBtn = CreateSimpleButton(panel, 80, "全部")
    createAllBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -6, 0)

    local incrementBtn = CreateSimpleButton(panel, 20, "+")
    incrementBtn:SetPoint("RIGHT", createAllBtn, "LEFT", -10, 0)

    local inputBoxBg = CreateFrame("Frame", nil, panel)
    inputBoxBg:SetWidth(36)
    inputBoxBg:SetHeight(24)
    inputBoxBg:SetPoint("RIGHT", incrementBtn, "LEFT", -1, 0)
    inputBoxBg:SetFrameLevel(panel:GetFrameLevel() + 5)
    local inputBoxBgTex = inputBoxBg:CreateTexture(nil, "BACKGROUND")
    inputBoxBgTex:SetTexture("Interface\\Buttons\\WHITE8X8")
    inputBoxBgTex:SetAllPoints(inputBoxBg)
    inputBoxBgTex:SetVertexColor(0.10, 0.07, 0.04, 0.92)

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
    searchBg:SetWidth(250)
    searchBg:SetHeight(22)
    searchBg:SetPoint("BOTTOMLEFT", leftColumn, "BOTTOMLEFT", 12, 36)
    searchBg:SetFrameLevel(panel:GetFrameLevel() + 5)
    local searchBgTex = searchBg:CreateTexture(nil, "BACKGROUND")
    searchBgTex:SetTexture("Interface\\Buttons\\WHITE8X8")
    searchBgTex:SetAllPoints(searchBg)
    searchBgTex:SetVertexColor(0.10, 0.07, 0.04, 0.92)

    -- 放大镜图标（Blizzard 内置的搜索框图标）
    local searchIcon = searchBg:CreateTexture(nil, "OVERLAY")
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    searchIcon:SetWidth(14)
    searchIcon:SetHeight(14)
    searchIcon:SetPoint("LEFT", searchBg, "LEFT", 5, 0)
    searchIcon:SetVertexColor(0.98, 0.91, 0.58)

    local searchBox = CreateFrame("EditBox", nil, searchBg)
    searchBox:SetPoint("TOPLEFT", searchBg, "TOPLEFT", 22, -4)
    searchBox:SetPoint("BOTTOMRIGHT", searchBg, "BOTTOMRIGHT", -6, 4)
    searchBox:SetAutoFocus(false)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    searchBox:SetTextColor(0.95, 0.90, 0.80)
    searchBox:SetFrameLevel(searchBg:GetFrameLevel() + 1)
    searchBox:SetTextInsets(2, 2, 0, 0)

    local searchPlaceholder = searchBg:CreateFontString(nil, "OVERLAY")
    searchPlaceholder:SetFont("Fonts\\FRIZQT__.TTF", 11)
    searchPlaceholder:SetPoint("LEFT", searchBg, "LEFT", 24, 0)
    searchPlaceholder:SetText("搜索配方...")
    searchPlaceholder:SetTextColor(0.55, 0.50, 0.40)

    -- 过滤器移到 leftColumn 顶部 (retail 风格, "过滤器" 区在列表上方)
    local matsCheckbox = CreateCheckbox(panel, "有材料")
    matsCheckbox:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 10, -8)
    matsCheckbox:SetFrameLevel(panel:GetFrameLevel() + 5)
    matsCheckbox:SetChecked(false)

    local favOnlyCheckbox = CreateCheckbox(panel, "仅收藏")
    favOnlyCheckbox:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 130, -8)
    favOnlyCheckbox:SetFrameLevel(panel:GetFrameLevel() + 5)
    favOnlyCheckbox:SetChecked(false)


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
                    local passFav = not filterFavOnly or IsFavorite(name)
                    if passSearch and passMats and passFav then
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
                btn.recipeName = item.name
                btn.isHeader = item.isHeader
                btn.isExpanded = item.isExpanded
                if item.isHeader then
                    -- Header 行: 折叠图标 + 名称，无产物图标
                    btn.collapseIcon:SetText(item.isExpanded and "-" or "+")
                    btn.collapseIcon:Show()
                    btn.recipeIcon:Hide()
                    btn.skillIcon:Hide()
                    btn.favStar:Hide()
                    -- 锚定到按钮本身 (避免 FontString→FontString 锚定在 1.12 中边界计算不可靠)
                    btn.nameText:ClearAllPoints()
                    btn.nameText:SetPoint("LEFT", btn, "LEFT", 18, 0)
                    btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                    btn.nameText:SetText(item.name)
                    local hc = DIFFICULTY_COLORS.header
                    btn.nameText:SetTextColor(hc[1], hc[2], hc[3])
                    btn.nameText:SetFont("Fonts\\FRIZQT__.TTF", 13)
                    -- Header 行深灰背景 (retail 风格，全行显示)
                    btn.headerBg:Show()
                else
                    -- 配方行: 产物图标 + 名称
                    btn.collapseIcon:SetText("")
                    btn.collapseIcon:Hide()
                    btn.headerBg:Hide()
                    local texture
                    if currentMode == "tradeskill" then
                        texture = GetTradeSkillIcon(item.index)
                    elseif currentMode == "craft" then
                        texture = GetCraftIcon(item.index)
                    end
                    -- 难度图标: 仅 tradeskill 模式 + 已知 skillType 才显示
                    local skillKey = nil
                    if currentMode == "tradeskill" then
                        if item.skillType == "optimal" then skillKey = "icon-skill-high"
                        elseif item.skillType == "medium" then skillKey = "icon-skill-medium"
                        elseif item.skillType == "easy" or item.skillType == "trivial" then skillKey = "icon-skill-low"
                        end
                    end
                    if skillKey then
                        ApplyAtlas(btn.skillIcon, skillKey, false)
                        btn.skillIcon:SetWidth(13); btn.skillIcon:SetHeight(15)
                        btn.skillIcon:Show()
                    else
                        btn.skillIcon:Hide()
                    end

                    if texture then
                        btn.recipeIcon:SetTexture(texture)
                        btn.recipeIcon:Show()
                        if skillKey then
                            btn.skillIcon:ClearAllPoints()
                            btn.skillIcon:SetPoint("LEFT", btn.recipeIcon, "RIGHT", 2, 0)
                            btn.nameText:ClearAllPoints()
                            btn.nameText:SetPoint("LEFT", btn.skillIcon, "RIGHT", 2, 0)
                            btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                        else
                            btn.nameText:ClearAllPoints()
                            btn.nameText:SetPoint("LEFT", btn.recipeIcon, "RIGHT", 4, 0)
                            btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                        end
                    else
                        btn.recipeIcon:Hide()
                        if skillKey then
                            btn.skillIcon:ClearAllPoints()
                            btn.skillIcon:SetPoint("LEFT", btn, "LEFT", 4, 0)
                            btn.nameText:ClearAllPoints()
                            btn.nameText:SetPoint("LEFT", btn.skillIcon, "RIGHT", 3, 0)
                            btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                        else
                            btn.nameText:ClearAllPoints()
                            btn.nameText:SetPoint("LEFT", btn, "LEFT", 20, 0)
                            btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                        end
                    end
                    local displayName = item.name
                    if item.subName and item.subName ~= "" then
                        local localSub = string.gsub(item.subName, "^Rank ", "等级 ")
                        displayName = displayName .. " (" .. localSub .. ")"
                    end
                    if item.numAvail and item.numAvail > 0 then
                        displayName = displayName .. " [" .. item.numAvail .. "]"
                    end
                    -- SkillUps 数字 (retail 风格, 1.12 用 skillType 映射推断)
                    if currentMode == "tradeskill" then
                        if item.skillType == "optimal" then displayName = displayName .. " (+1~3)"
                        elseif item.skillType == "medium" then displayName = displayName .. " (+1~2)"
                        elseif item.skillType == "easy" then displayName = displayName .. " (+1)"
                        end
                    end
                    btn.nameText:SetText(displayName)
                    local dc = DIFFICULTY_COLORS[item.skillType] or DIFFICULTY_COLORS.default
                    btn.nameText:SetTextColor(dc[1], dc[2], dc[3])
                    btn.nameText:SetFont("Fonts\\FRIZQT__.TTF", 12)
                    -- 收藏星标
                    if IsFavorite(item.name) then btn.favStar:Show() else btn.favStar:Hide() end
                end
                SetButtonSelected(btn, not item.isHeader and item.index == selectedIndex)
                btn:Show()
            else
                btn.recipeIndex = nil
                btn.recipeName = nil
                btn.isHeader = false
                btn.recipeIcon:Hide()
                btn.skillIcon:Hide()
                btn.headerBg:Hide()
                btn.favStar:Hide()
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
        detailSubText:SetText(""); detailSubText:Hide()

        -- ☆ 收藏指示 (跟随 IsFavorite 状态)
        -- 必须用 GetStringWidth 重锚: detailName SetWidth(400) 让 RIGHT 锚固定在 400px 远而非文本末
        if name and IsFavorite(name) then
            detailFavStar:ClearAllPoints()
            detailFavStar:SetPoint("LEFT", detailName, "LEFT", (detailName:GetStringWidth() or 0) + 6, 0)
            detailFavStar:Show()
        else
            detailFavStar:Hide()
        end

        -- Count 徽章 (retail OutputIcon Count)
        local minMade, maxMade
        if currentMode == "tradeskill" and GetTradeSkillNumMade then
            local nmOk, mn, mx = pcall(GetTradeSkillNumMade, selectedIndex)
            if nmOk then minMade, maxMade = mn, mx end
        end
        if minMade and maxMade and (minMade > 1 or maxMade > 1) then
            if minMade == maxMade then
                detailIconCount:SetText(minMade)
            else
                detailIconCount:SetText(minMade .. "-" .. maxMade)
            end
            detailIconCount:Show()
        else
            detailIconCount:Hide()
        end

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

        -- 材料标签动态锚点 (跟随最末显示的文字行下方 18px, 避免与 desc 重叠)
        -- 默认 anchor 为 detailName (detailSubText 当前是死字段总隐藏)
        local anchor = detailName
        if detailCooldown:IsShown() then anchor = detailCooldown end
        if detailRequire:IsShown() then anchor = detailRequire end
        if detailPoints:IsShown() then anchor = detailPoints end
        if detailDesc:IsShown() then anchor = detailDesc end
        -- anchor.x = detailIconBtn.RIGHT + 14 = 28+47+14 = 89, 目标 x = 28, offsetX = -61
        reagentLabel:ClearAllPoints()
        reagentLabel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -61, -18)

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
                    local r, g, b = 0.95, 0.90, 0.78
                    if not enough then r, g, b = 1.00, 0.30, 0.30 end
                    slot.nameText:SetTextColor(r, g, b)
                    slot.countText:SetTextColor(r, g, b)
                    -- DF Slot-Frame 按足量/不足动态切色 (保 TexCoord 裁透明 padding)
                    if slot.border then
                        slot.border:SetTexture(PROF_TEX .. (enough and "slot_green.tga" or "slot_epic.tga"))
                        slot.border:SetTexCoord(12/64, 51/64, 12/64, 51/64)
                    end
                    slot.reagentIndex = i
                    slot:ClearAllPoints()
                    -- retail 网格: 3 列 × 3 行 (适配 detailFrame 717 宽), spacing 5px
                    local col = math.mod(i - 1, 3)
                    local row = math.floor((i - 1) / 3)
                    slot:SetPoint("TOPLEFT", reagentLabel, "BOTTOMLEFT", col * 185, -8 - row * 55)
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
                elseif currentMode == "craft" then
                    if this.isExpanded then
                        CollapseCraftSkillLine(this.recipeIndex)
                    else
                        ExpandCraftSkillLine(this.recipeIndex)
                    end
                    UpdateRecipeList()
                end
            else
                if arg1 == "RightButton" then
                    -- 右键切换收藏
                    ToggleFavorite(this.recipeName)
                    UpdateRecipeList()
                else
                    selectedIndex = this.recipeIndex
                    UpdateDetail()
                    UpdateRecipeList()
                end
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
        elseif currentMode == "craft" then
            local anyCollapsed = false
            local num = GetNumCrafts() or 0
            for i = 1, num do
                local _, _, st, _, ie = GetCraftInfo(i)
                if st == "header" and not ie then anyCollapsed = true; break end
            end
            if anyCollapsed then
                ExpandCraftSkillLine(0)
            else
                CollapseCraftSkillLine(0)
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

    favOnlyCheckbox:SetScript("OnClick", function()
        filterFavOnly = not filterFavOnly
        favOnlyCheckbox:SetChecked(filterFavOnly)
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
        filterHasMats = false
        filterFavOnly = false
        matsCheckbox:SetChecked(false)
        favOnlyCheckbox:SetChecked(false)

        -- 不 Hide 原生面板! 用 SetAlpha(0) 保持 API 连接
        -- ADDON_LOADED hook 已处理原生面板透明化

        -- 记录当前专业名（转换为 Tab 上显示的法术名）
        local apiName
        if mode == "tradeskill" then apiName = GetTradeSkillLine()
        elseif mode == "craft" then apiName = GetCraftName and GetCraftName() or nil end
        activeProfName = PROF_API_TO_SPELL[apiName] or apiName

        -- 切换右侧专业背景画（按需加载：只在 Open 时切一次，OnHide 释放）
        -- SetTexCoord 重设保险 (1.12 SetTexture 通常不重置 TexCoord, 但保险起见)
        local bgKey = PROF_BG_KEY[apiName] or PROF_BG_KEY[activeProfName] or "default"
        detailBg:SetTexture(PROF_TEX .. "bg_" .. bgKey .. ".tga")
        detailBg:SetTexCoord(0, 339/512, 0, 275/512)

        -- 扫描法术书专业（需在设置图标前完成，避免首次打开没 texture）
        if not profScanned then
            ScanSpellbookForProfessions()
            if table.getn(knownProfessions) > 0 then profScanned = true end
        end

        -- 左上角图标保持玩家职业图标（不随专业切换）

        UpdateRankBar()
        if table.getn(panel.Tabs) == 0 then
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
        -- 释放背景画显存引用
        detailBg:SetTexture("")
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
