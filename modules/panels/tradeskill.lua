-- tradeskill.lua — 统一专业技能面板 (TradeSkill + Craft)
-- DF 风格，右侧专业背景画（DF retail 10.1 素材），1069x658 大框体
-- 核心策略: 原生面板 SetAlpha(0)+EnableMouse(false) 保持 API 连接，自建面板覆盖其上

-- P0-#1 setfenv 守卫：core 未加载时给可读警告而非沉默崩溃
if not (DFUI and DFUI.GetEnv) then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4040[DFUI-tradeskill]|r DFUI core not loaded, abort tradeskill panel")
    return
end
setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")
local PROF_TEX = TEX .. "panels\\df\\professions\\"

-- 图标兜底：Craft API 对某些专业(如 Turtle 自定义"生存")返回 nil 图标时，
-- 用 vanilla 问号占位，避免空白/隐藏导致"没图标"观感
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local CLASS_ICON_COORDS = DFUI_CLASS_ICON_COORDS

-- API 专业名/法术名 → 背景画 key（PROF_BG_KEY）
local PROF_BG_KEY = {
    ["Alchemy"]="alchemy", ["炼金术"]="alchemy",
    ["Blacksmithing"]="blacksmithing", ["锻造"]="blacksmithing",
    ["Cooking"]="cooking", ["烹饪"]="cooking",
    ["Enchanting"]="enchanting", ["附魔"]="enchanting",
    ["Engineering"]="engineering", ["工程学"]="engineering",
    -- 急救→alchemy: retail DF 已废除 First Aid，且 bg_default（professionbackgroundart.blp 通用版）
    -- 解码后纹理细节比专业 BG 弱，视觉接近"无背景"。alchemy 药剂瓶台面与医疗治疗语义关联强。
    ["First Aid"]="alchemy", ["急救"]="alchemy",
    ["Fishing"]="fishing", ["钓鱼"]="fishing",
    ["Herbalism"]="herbalism", ["草药学"]="herbalism",
    ["Leatherworking"]="leatherworking", ["制皮"]="leatherworking",
    ["Mining"]="mining", ["采矿"]="mining",
    ["Smelting"]="mining", ["熔炼"]="mining",
    ["Skinning"]="skinning", ["剥皮"]="skinning",
    ["Tailoring"]="tailoring", ["裁缝"]="tailoring",
    ["Beast Training"]="default", ["宠物训练"]="default",
    ["野兽训练"]="default", ["宠物技能"]="default", ["训练野兽"]="default",
    ["Survival"]="survival", ["生存"]="survival",
}

-- ============================================================
-- DF retail Atlas 切片表 (来自 _references/dragonflight_ui/db2_csv 三表 join)
-- 用法: ApplyAtlas(tex, "icon-skill-high") → SetTexture + SetTexCoord
-- TGA 资源: atlas_main.tga ← interface/professions/professions.blp (2048×1024 ARGB8888)
-- 经 _tools/blp2_to_tga_512.js 解码，WoW 1.12 原生支持 BGRA32 TGA
-- ============================================================
local ATLAS_MAIN       = PROF_TEX .. "atlas_main.tga"          -- 2048×1024 (retail professions.blp)
local RANKBAR_FILL     = PROF_TEX .. "rankbar_fill_blue.tga"   -- 256×16 POT (retail uiframebars.blp ui-frame-bar-fill-blue 切片, T88-B103 蓝色 gradient)
local SCROLL_THUMB_TB  = PROF_TEX .. "scroll_thumb_tb.tga"     -- 64×64  (DF minimal-scrollbar-small thumb top/bot)
local SCROLL_THUMB_MID = PROF_TEX .. "scroll_thumb_mid.tga"    -- 64×1024 (thumb middle 段)
local SCROLL_TRACK_TB  = PROF_TEX .. "scroll_track_tb.tga"     -- 128×64 (track top/bot)
local UIACTIONBAR_TEX  = PROF_TEX .. "uiactionbar_atlas.tga"   -- 256×1024 (ui-hud-actionbar page arrow ×3态)

local ATLAS_SIZE = {
    [ATLAS_MAIN]       = {2048, 1024},
    [SCROLL_THUMB_TB]  = {64,   64},
    [SCROLL_THUMB_MID] = {64,   1024},
    [SCROLL_TRACK_TB]  = {128,  64},
    [UIACTIONBAR_TEX]  = {256,  1024},
}

-- P2-#11 布局常量（散落的魔术数字集中管理，便于调优）
local LAYOUT = {
    SCROLL_BAR_WIDTH    = 18,    -- 滚动条宽度 (V21.1 14→18 让滚动条更显眼)
    SCROLL_ARROW_HEIGHT = 16,    -- 滚动条上下箭头按钮高度
    SCROLL_THUMB_MIN_H  = 20,    -- 滚动条 thumb 最小高度（避免长列表上缩成一线）
    PANEL_SCALE         = 0.85,  -- 主面板缩放比例
    DETAIL_DESC_WIDTH   = 460,   -- 详情区描述文本宽度（retail SchematicForm 标准）
}

local ATLAS = {
    -- key = {left, right, top, bottom, file, width, height}  (px on retail atlas)
    ["recipe-active"]          = {1614, 1881,  39,  58, ATLAS_MAIN, 267, 19 },  -- 选中行全宽 overlay (金色, alpha 弱)
    ["recipe-hover"]           = {1275, 1584,  39,  60, ATLAS_MAIN, 309, 21 },  -- 悬停行全宽 overlay (暖色, alpha 弱)
    -- V23 retail 真 3-slice header 横条 (替代项目自制纯色)
    ["recipe-header-left"]     = { 885,  899,  28,  54, ATLAS_MAIN,  14,  26 },
    ["recipe-header-middle"]   = { 709,  710,  43,  69, ATLAS_MAIN,   1,  26 },
    ["recipe-header-right"]    = { 932,  946,  46,  72, ATLAS_MAIN,  14,  26 },
    -- V24 retail header 折叠图标 (右侧 22×16, expand=已折叠态/collapse=已展开态)
    ["recipe-header-expand"]   = { 619,  641,  55,  71, ATLAS_MAIN,  22,  16 },
    ["recipe-header-collapse"] = { 554,  576,  55,  71, ATLAS_MAIN,  22,  16 },
    ["icon-skill-high"]        = { 539,  552,  55,  70, ATLAS_MAIN,  13, 15 },
    ["icon-skill-medium"]      = { 604,  617,  55,  70, ATLAS_MAIN,  13, 15 },
    ["icon-skill-low"]         = { 524,  537,  55,  70, ATLAS_MAIN,  13, 15 },
    -- DF minimal-scrollbar 3-slice thumb + track
    ["scroll-thumb-top"]       = {  20,   28,  54,  62, SCROLL_THUMB_TB,   8,   8 },
    ["scroll-thumb-mid"]       = {  31,   39,   1, 716, SCROLL_THUMB_MID,  8, 715 },
    ["scroll-thumb-bot"]       = {  39,   47,  31,  39, SCROLL_THUMB_TB,   8,   8 },
    ["scroll-track-top"]       = {  21,   29,  39,  47, SCROLL_TRACK_TB,   8,   8 },
    ["scroll-track-bot"]       = {  11,   19,  49,  57, SCROLL_TRACK_TB,   8,   8 },
    -- DF ui-hud-actionbar page arrow ×3态 (17×14, up/down × normal/hover/down)
    ["arrow-up-normal"]        = { 200,  217, 458, 472, UIACTIONBAR_TEX,  17,  14 },
    ["arrow-up-hover"]         = { 181,  198, 458, 472, UIACTIONBAR_TEX,  17,  14 },
    ["arrow-up-down"]          = { 234,  251, 390, 404, UIACTIONBAR_TEX,  17,  14 },
    ["arrow-down-normal"]      = { 234,  251, 358, 372, UIACTIONBAR_TEX,  17,  14 },
    ["arrow-down-hover"]       = { 234,  251, 337, 351, UIACTIONBAR_TEX,  17,  14 },
    ["arrow-down-down"]        = { 234,  251, 321, 335, UIACTIONBAR_TEX,  17,  14 },
    -- V26 disabled 态箭头 (字典: ui-hud-actionbar-page{up|down}arrow-disabled)
    ["arrow-up-disabled"]      = { 234,  251, 374, 388, UIACTIONBAR_TEX,  17,  14 },
    ["arrow-down-disabled"]    = { 234,  251, 305, 319, UIACTIONBAR_TEX,  17,  14 },
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

-- P0-#4 ATLAS 表 sanity 校验：坐标错误或 ATLAS_SIZE 缺失时给警告，避免静默失真
for k, e in pairs(ATLAS) do
    local size = ATLAS_SIZE[e[5]]
    if not size or e[2] <= e[1] or e[4] <= e[3] then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[DFUI-tradeskill]|r ATLAS["..tostring(k).."] invalid (坐标错误或 ATLAS_SIZE 缺失)")
    end
end

-- ============================================================
-- CreateInsetBackdrop helper — V8.1 完整 retail InsetFrame 8 元素 (零自制)
-- 按 retail nineslicelayouts.lua InsetFrameTemplate 完整 XML 翻译为 1.12 Lua:
--   4 corner @ uiframe.blp (atlas 948, FileDataID 1723831):
--     UI-Frame-InnerTopLeft       (97-103, 71-77)
--     UI-Frame-InnerTopRight      (105-111, 71-77)
--     UI-Frame-InnerBotLeftCorner (81-87, 71-77, y offset -1)
--     UI-Frame-InnerBotRight      (89-95, 71-77, y offset -1)
--   2 vertical edge @ uiframevertical.blp (atlas 949, FileDataID 1723832):
--     !UI-Frame-InnerLeftTile  (31-34, 0-256)
--     !UI-Frame-InnerRightTile (36-39, 0-256)
--   2 horizontal edge @ uiframehorizontal.blp (atlas 950, FileDataID 1723833):
--     _UI-Frame-InnerTopTile (0-256, 116-119)
--     _UI-Frame-InnerBotTile (0-256, 111-114)
-- 暖灰金属 RGB 16-107 自然渐变 = retail "暗内陷"凹陷视觉 (零染色)
-- 数据源: 用户提供 _references/dragonflight_ui/_html_dict/data/dict.json
-- ============================================================
local UIFRAME_CORNER_TEX = PROF_TEX .. "uiframe_corner.tga"
local UIFRAME_V_TEX      = PROF_TEX .. "uiframe_v.tga"
local UIFRAME_H_TEX      = PROF_TEX .. "uiframe_h.tga"
local UI_TC_CTL = {97/128, 103/128, 71/128, 77/128}
local UI_TC_CTR = {105/128, 111/128, 71/128, 77/128}
local UI_TC_CBL = {81/128, 87/128, 71/128, 77/128}
local UI_TC_CBR = {89/128, 95/128, 71/128, 77/128}
local UI_TC_L   = {31/64, 34/64, 0, 1}
local UI_TC_R   = {36/64, 39/64, 0, 1}
local UI_TC_T   = {0, 1, 116/128, 119/128}
local UI_TC_B   = {0, 1, 111/128, 114/128}

local function CreateInsetBackdrop(frame, bgAlpha)
    -- V25.2 bgAlpha=0 时完全跳过 bg 创建, 避免占用 BACKGROUND 层覆盖外部木纹底
    if bgAlpha and bgAlpha > 0 then
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(frame)
        bg:SetVertexColor(0, 0, 0, bgAlpha)
    end
    -- V11: corner 5px 可见 (picture frame 4 角凸出) + edge 2px 细薄
    local CSZ = 5  -- corner 物理尺寸
    local EW  = 2  -- edge 厚度
    -- 4 corner (retail uiframe.blp atlas 真 6×6 → 渲染 5×5)
    local function corner(point, tc, oy)
        local c = frame:CreateTexture(nil, "BORDER")
        c:SetTexture(UIFRAME_CORNER_TEX)
        c:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
        c:SetWidth(CSZ); c:SetHeight(CSZ)
        c:SetPoint(point, frame, point, 0, oy or 0)
        return c
    end
    local cTL = corner("TOPLEFT",     UI_TC_CTL)
    local cTR = corner("TOPRIGHT",    UI_TC_CTR)
    local cBL = corner("BOTTOMLEFT",  UI_TC_CBL, -1)  -- retail XML y=-1 微调
    local cBR = corner("BOTTOMRIGHT", UI_TC_CBR, -1)
    -- 4 edge tile (EW 厚, 单边锚定让 edge 比 corner 薄)
    -- Top: 顶部锚到 cTL.TR 和 cTR.TL, 高 EW
    local T = frame:CreateTexture(nil, "BORDER")
    T:SetTexture(UIFRAME_H_TEX)
    T:SetTexCoord(UI_TC_T[1], UI_TC_T[2], UI_TC_T[3], UI_TC_T[4])
    T:SetPoint("TOPLEFT", cTL, "TOPRIGHT", 0, 0)
    T:SetPoint("TOPRIGHT", cTR, "TOPLEFT", 0, 0)
    T:SetHeight(EW)
    -- Bot: 底部锚到 cBL.BR 和 cBR.BL, 高 EW
    local B = frame:CreateTexture(nil, "BORDER")
    B:SetTexture(UIFRAME_H_TEX)
    B:SetTexCoord(UI_TC_B[1], UI_TC_B[2], UI_TC_B[3], UI_TC_B[4])
    B:SetPoint("BOTTOMLEFT", cBL, "BOTTOMRIGHT", 0, 0)
    B:SetPoint("BOTTOMRIGHT", cBR, "BOTTOMLEFT", 0, 0)
    B:SetHeight(EW)
    -- Left: 左侧锚到 cTL.BL 和 cBL.TL, 宽 EW
    local L = frame:CreateTexture(nil, "BORDER")
    L:SetTexture(UIFRAME_V_TEX)
    L:SetTexCoord(UI_TC_L[1], UI_TC_L[2], UI_TC_L[3], UI_TC_L[4])
    L:SetPoint("TOPLEFT", cTL, "BOTTOMLEFT", 0, 0)
    L:SetPoint("BOTTOMLEFT", cBL, "TOPLEFT", 0, 0)
    L:SetWidth(EW)
    -- Right: 右侧锚到 cTR.BR 和 cBR.TR, 宽 EW
    local R = frame:CreateTexture(nil, "BORDER")
    R:SetTexture(UIFRAME_V_TEX)
    R:SetTexCoord(UI_TC_R[1], UI_TC_R[2], UI_TC_R[3], UI_TC_R[4])
    R:SetPoint("TOPRIGHT", cTR, "BOTTOMRIGHT", 0, 0)
    R:SetPoint("BOTTOMRIGHT", cBR, "TOPRIGHT", 0, 0)
    R:SetWidth(EW)
end

-- ============================================================
-- CreateMinimalScrollbar — V21 DF minimal-scrollbar 3-slice + ui-hud-actionbar 小三角箭头
-- 几何: [up-arrow 14h] [track-top 8h] [track-mid 弹性 暗色] [track-bot 8h] [down-arrow 14h]
-- 参数:
--   parent      : 锚定容器 (leftColumn)
--   listFrame   : 列表 frame, sb 锚 listFrame TOPRIGHT/BOTTOMRIGHT
--   onScrollDelta: function(dRows) — 点上下箭头时调用 (-1 或 +1)
--   onScrollAbs : function(ratio)  — 拖动 thumb 时调用 (0..1)
-- 返回: sb (含 sb.thumb / sb.track / sb.UpdateThumb(scrollOffset, maxOffset, visibleRows, totalRows))  -- 点调用,无 self
-- ============================================================
local function CreateMinimalScrollbar(parent, listFrame, onScrollDelta, onScrollAbs)
    local sb = CreateFrame("Frame", nil, parent)
    sb:SetWidth(LAYOUT.SCROLL_BAR_WIDTH)
    sb:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", LAYOUT.SCROLL_BAR_WIDTH, 0)
    sb:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", LAYOUT.SCROLL_BAR_WIDTH, 0)
    sb:SetFrameLevel(parent:GetFrameLevel() + 5)

    -- V22.1: 用 BACKGROUND 层 (唯一在 sb 容器内验证工作的层) + atlas SetTexCoord
    -- 3 态用 3 个 BACKGROUND texture, OnMouseDown/Up + OnEnter/Leave 切换 Show/Hide
    local function makeArrowBtn(point, normKey, hovKey, dnKey)
        local btn = CreateFrame("Button", nil, sb)
        btn:SetWidth(LAYOUT.SCROLL_BAR_WIDTH); btn:SetHeight(LAYOUT.SCROLL_ARROW_HEIGHT)
        btn:SetPoint(point, sb, point, 0, 0)
        local function bgTex(key)
            local a = ATLAS[key]
            local file = a[5]; local sz = ATLAS_SIZE[file]
            local t = btn:CreateTexture(nil, "BACKGROUND")
            t:SetTexture(file)
            t:SetTexCoord(a[1]/sz[1], a[2]/sz[1], a[3]/sz[2], a[4]/sz[2])
            t:SetAllPoints(btn)
            return t
        end
        local norm = bgTex(normKey)
        local hov  = bgTex(hovKey);  hov:Hide()
        local dn   = bgTex(dnKey);   dn:Hide()
        btn:SetScript("OnEnter",     function() if not btn.pushed then norm:Hide(); hov:Show() end end)
        btn:SetScript("OnLeave",     function() if not btn.pushed then hov:Hide();  norm:Show() end end)
        btn:SetScript("OnMouseDown", function() btn.pushed = true;  norm:Hide(); hov:Hide(); dn:Show() end)
        btn:SetScript("OnMouseUp",   function() btn.pushed = false; dn:Hide(); norm:Show() end)
        return btn
    end
    -- V26 normal 态用 disabled 版本 (用户指定: ui-hud-actionbar-page{up|down}arrow-disabled)
    local upBtn = makeArrowBtn("TOP",    "arrow-up-disabled",   "arrow-up-hover",   "arrow-up-down")
    local dnBtn = makeArrowBtn("BOTTOM", "arrow-down-disabled", "arrow-down-hover", "arrow-down-down")
    upBtn:SetScript("OnClick", function() onScrollDelta(-1) end)
    dnBtn:SetScript("OnClick", function() onScrollDelta(1)  end)

    -- track 容器 (up/down 之间)
    local track = CreateFrame("Frame", nil, sb)
    track:SetWidth(12)  -- V21.1 8→12
    track:SetPoint("TOP", upBtn, "BOTTOM", 0, -2)
    track:SetPoint("BOTTOM", dnBtn, "TOP", 0, 2)
    track:SetPoint("LEFT", sb, "LEFT", 3, 0)
    track:SetPoint("RIGHT", sb, "RIGHT", -3, 0)

    -- track 3-slice: top + middle (WHITE8X8 暗色) + bot (12×12 拉伸)
    local trTop = track:CreateTexture(nil, "BACKGROUND"); ApplyAtlas(trTop, "scroll-track-top", false)
    trTop:SetWidth(12); trTop:SetHeight(12); trTop:SetPoint("TOP", track, "TOP", 0, 0)
    local trBot = track:CreateTexture(nil, "BACKGROUND"); ApplyAtlas(trBot, "scroll-track-bot", false)
    trBot:SetWidth(12); trBot:SetHeight(12); trBot:SetPoint("BOTTOM", track, "BOTTOM", 0, 0)
    local trMid = track:CreateTexture(nil, "BACKGROUND")
    trMid:SetTexture("Interface\\Buttons\\WHITE8X8")
    trMid:SetVertexColor(0.04, 0.04, 0.04, 0.85)
    trMid:SetPoint("TOPLEFT", trTop, "BOTTOMLEFT", 0, 0)
    trMid:SetPoint("BOTTOMRIGHT", trBot, "TOPRIGHT", 0, 0)

    -- V22.1 thumb 3-slice: Frame + EnableMouse + BACKGROUND 层 (容器内唯一工作的层)
    local thumb = CreateFrame("Frame", nil, track)
    thumb:EnableMouse(true)
    thumb:SetWidth(12)
    thumb:SetHeight(50)
    thumb:SetPoint("TOP", track, "TOP", 0, 0)
    local thTop = thumb:CreateTexture(nil, "BACKGROUND"); ApplyAtlas(thTop, "scroll-thumb-top", false)
    thTop:SetWidth(12); thTop:SetHeight(12); thTop:SetPoint("TOP", thumb, "TOP", 0, 0)
    local thBot = thumb:CreateTexture(nil, "BACKGROUND"); ApplyAtlas(thBot, "scroll-thumb-bot", false)
    thBot:SetWidth(12); thBot:SetHeight(12); thBot:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)
    local thMid = thumb:CreateTexture(nil, "BACKGROUND")
    thMid:SetTexture(SCROLL_THUMB_MID)
    thMid:SetTexCoord(31/64, 39/64, 100/1024, 600/1024)
    thMid:SetPoint("TOPLEFT", thTop, "BOTTOMLEFT", 0, 0)
    thMid:SetPoint("BOTTOMRIGHT", thBot, "TOPRIGHT", 0, 0)

    -- 拖动: OnMouseDown 启动 OnUpdate 跟随鼠标 y, OnMouseUp 停止
    thumb.dragging = false
    thumb:SetScript("OnMouseDown", function()
        thumb.dragging = true
        thumb.dragStartCursorY = nil
    end)
    thumb:SetScript("OnMouseUp", function()
        thumb.dragging = false
    end)
    thumb:SetScript("OnUpdate", function()
        if not thumb.dragging then return end
        local _, cy = GetCursorPosition()
        local scale = thumb:GetEffectiveScale()
        local trackTop = track:GetTop()
        local trackBot = track:GetBottom()
        if not trackTop or not trackBot then return end
        local trackH = (trackTop - trackBot) * scale
        local cursorOnTrack = (trackTop * scale) - cy
        local thumbH = thumb:GetHeight() * scale
        local maxY = trackH - thumbH
        if maxY <= 0 then return end
        local ratio = cursorOnTrack / maxY
        if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
        onScrollAbs(ratio)
    end)

    sb.thumb = thumb
    sb.track = track

    -- UpdateThumb: 由 UpdateRecipeList 调用同步 thumb 几何 + 缓存 maxOff (拖动时换算 ratio→scrollOff 用)
    sb.lastMaxOffset = 0
    sb.UpdateThumb = function(scrollOff, maxOff, visRows, totalRows)
        sb.lastMaxOffset = maxOff or 0
        local trackH = track:GetHeight()
        if not trackH or trackH <= 0 then return end
        local thumbH = math.max(LAYOUT.SCROLL_THUMB_MIN_H, trackH * visRows / math.max(visRows, totalRows))
        if thumbH > trackH then thumbH = trackH end
        thumb:SetHeight(thumbH)
        local thumbMaxY = trackH - thumbH
        local thumbY = (maxOff and maxOff > 0) and (thumbMaxY * scrollOff / maxOff) or 0
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -thumbY)
    end

    return sb
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
    local recipeCache = {}         -- RebuildRecipeData 产出、RenderRecipeButtons 消费：滚动只读缓存不重扫全表
    local tradeSkillOpen = false   -- 事件状态标记
    local craftOpen = false
    local isClosing = false        -- OnHide 重入守卫
    local activeProfName = nil     -- 当前打开的专业名（用于 tab 防重复点击）
    local tradeSkillHooked = false -- 原生面板 hook 标志
    local craftHooked = false

    -- 透明化原生面板（保持 API 连接，移出视野）
    -- 1.12 ScrollFrame 子 scrollbar 首次 OnShow 走 UpdateScrollChildRect 初始化时, alpha cascade
    -- 可能失效, 导致 scrollbar 在面板首开时短暂可见。显式 Hide 兜底, 关闭重开后状态稳定。
    local NATIVE_SCROLLBARS = {
        "TradeSkillListScrollFrameScrollBar",
        "TradeSkillDetailScrollFrameScrollBar",
        "CraftListScrollFrameScrollBar",
        "CraftDetailScrollFrameScrollBar",
    }
    local function HideNativeFrame(frame)
        frame:SetAlpha(0)
        frame:EnableMouse(false)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000)
        for i = 1, table.getn(NATIVE_SCROLLBARS) do
            local sb = getglobal(NATIVE_SCROLLBARS[i])
            if sb then sb:Hide() end
        end
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
    panel:SetScale(LAYOUT.PANEL_SCALE)

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
    -- V25 左栏底色: 程序化生成的暗棕渐变木纹 + 交叉锤子 (模仿 retail craftingorders-categories-background)
    -- 颜色采样自原 atlas 真像素 (顶 BGR 45,56,67 → 底 BGR 8,14,20), 加细微噪声模拟木纹
    -- 绕过 ARGB BLP→TGA 解码路径(1.12 不接受), 用程序化生成的纯 BGRA32 TGA
    local leftColumnBg = leftColumn:CreateTexture(nil, "BACKGROUND")
    -- 用项目已加载的 UI-Background-Rock.blp (panel.Bg 同源) + SetVertexColor 染暖棕区分
    leftColumnBg:SetPoint("TOPLEFT",     leftColumn, "TOPLEFT",     4, -4)
    leftColumnBg:SetPoint("BOTTOMRIGHT", leftColumn, "BOTTOMRIGHT", -4, 4)
    leftColumnBg:SetTexture(TEX .. "interface\\leftbg2.tga")
    -- 暖棕染色, 跟底层 panel.Bg 灰色岩石视觉区分
    leftColumnBg:SetVertexColor(0.7, 0.55, 0.4)
    -- InsetFrame 金属外框保留, bg 透明让木纹底层显出 (CreateInsetBackdrop bgAlpha=0 已跳过 bg 创建)
    CreateInsetBackdrop(leftColumn, 0)  -- V8 retail InsetFrame 真 edge tile 凹陷

    local rightColumn = CreateFrame("Frame", nil, panel)
    rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", 8, 0)
    rightColumn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 50)  -- V9 底部上移 34px 让出按钮区
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
    -- V5 右栏: 透明 bg (不挡 detailBg 专业画) + 仅 nineslice 边框
    CreateInsetBackdrop(rightColumn, 0)  -- V8 retail InsetFrame (透明 bg + 真 edge tile)

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
    title:SetFont("Fonts\\FRIZQT__.TTF", 16)  -- 专业名缩小 20% (20→16)
    title:SetText("专业技能")
    title:SetTextColor(1.00, 0.82, 0.00)
    title:SetPoint("TOP", panel, "TOP", 0, -4)

    local closeBtn = DFUI.CreateRedButton(panel, "close", function() panel:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -2)

    -- ============================================================
    -- 4. 熟练度进度条
    -- ============================================================
    -- 熟练度条: StatusBar + atlas_main 切片 qualitybar-bg (185×25 实心黑 mask) + VertexColor 金色染色
    -- 替代之前的项目自制 rankbar_fill.tga, 全 retail 数据
    local rankBarBg = CreateFrame("Frame", nil, panel)
    rankBarBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 60, -38)
    rankBarBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -60, -38)
    rankBarBg:SetHeight(18)
    rankBarBg:SetFrameLevel(panel:GetFrameLevel() + 2)
    -- V5 熟练度条: 1.12 内置 SetBackdrop nineslice
    CreateInsetBackdrop(rankBarBg, 0.85)

    local rankBar = CreateFrame("StatusBar", nil, rankBarBg)
    rankBar:SetPoint("TOPLEFT", rankBarBg, "TOPLEFT", 3, -3)
    rankBar:SetPoint("BOTTOMRIGHT", rankBarBg, "BOTTOMRIGHT", -3, 3)
    -- StatusBar fill 用独立 TGA 文件路径而非 Texture 对象。
    -- Why: 1.12 StatusBar 引擎接管 Texture 对象后, SetValue 会重写 SetTexCoord 做横向 mask, 同时
    -- 覆盖预设 VertexColor; 因此 atlas 子区域切片 + SetStatusBarTexture(texObj) 组合在 1.12 不显示填充。
    -- 解法: 从 retail uiframebars.blp atlas 取 ui-frame-bar-fill-blue 区域 (L0 R256 T88 B103, 截到 16
    -- 行满足 1.12 POT 要求) 预切为独立 256×16 蓝色 TGA, 用文件路径 SetStatusBarTexture 让引擎当整张图吃。
    rankBar:SetStatusBarTexture(RANKBAR_FILL)
    rankBar:SetStatusBarColor(1, 1, 1, 0.6)  -- alpha 0.6 让暗底透出, 稀释饱和蓝
    rankBar:SetMinMaxValues(0, 300)
    rankBar:SetValue(0)

    local rankText = rankBar:CreateFontString(nil, "OVERLAY")
    rankText:SetFont("Fonts\\FRIZQT__.TTF", 14.4)  -- 专业等级缩小 10% (16→14.4)
    rankText:SetPoint("CENTER", rankBar, "CENTER", 0, 0)
    rankText:SetTextColor(1, 1, 1)


    -- ============================================================
    -- 5. 左页 — 配方列表
    -- ============================================================
    local listFrame = CreateFrame("Frame", nil, panel)
    -- listFrame 顶移 28px 让出顶部 checkbox 区域 (-10 → -38)
    -- bottom 也调整 (原 72 = checkbox 14px + 下间距 58, 现 checkbox 上移后底部不需要 = 14)
    listFrame:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 12, -60)  -- V17 -38→-60 下移 22px
    listFrame:SetPoint("BOTTOMRIGHT", leftColumn, "BOTTOMRIGHT", -10, 42)  -- 无滚动条，列表占满左栏宽
    listFrame:SetFrameLevel(panel:GetFrameLevel() + 3)

    local UpdateRecipeList  -- forward decl: 在 L1070+ 定义（拆为 Rebuild+Render+包装）
    local RebuildRecipeData    -- 数据层：全表扫描+过滤+图标预取
    local RenderRecipeButtons  -- 渲染层：仅读缓存（滚动热点路径）
    -- 制造面板不接自定义滚动条：CreateRetailScrollbar 多轮尝试效果差，已移除接线。
    -- 列表仅靠滚轮 OnMouseWheel 滚动（L~1764）。工厂函数与素材保留备用，见尝试记录。
    local recipeScrollbar = nil

    -- Layer C 图标常驻池: 每个唯一图标路径各建一个持久隐藏 1×1 纹理, **持有引用**防纹理缓存逐出。
    -- 根因(上滚卡/下滚不卡)：旧方案单一 warmTex 轮流 SetTexture 只持有最后一张引用，其余预热后变无引用→
    -- 进时间缓存。下滚(刚预热,时间缓存命中)顺；回头上滚时顶部图标的时间缓存已过期被逐出→需重新解码 BLP→卡。
    -- 实证：旧 warmTex 也是隐藏纹理而下滚不卡，证明隐藏 SetTexture 确实触发加载，问题仅在"没保住引用"。
    -- 持久池为每张图标常驻一个 Texture 引用→引用计数>0→永不逐出→双向滚动都命中常驻。可整层回退，零视觉/零每帧开销。
    local iconKeep = {}    -- [图标路径] = 持久隐藏 Texture (常驻引用，跨专业累积，面板生命周期内保留)
    local warmQueue = {}   -- 待建常驻纹理的图标路径 (分帧处理，避免打开瞬间集中解码造成单帧卡)
    local warmDone = {}    -- 去重: 已入队/已建池的路径

    -- 折叠全部按钮（模拟原版 "全部" header 行）
    local collapseAllBtn = CreateFrame("Button", nil, listFrame)
    collapseAllBtn:SetHeight(16)
    -- collapseAllBtn 锚到 listFrame 顶部 (在 checkbox 下方, listFrame TOPLEFT 已下移到 -38)
    collapseAllBtn:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, 0)
    collapseAllBtn:SetPoint("RIGHT", listFrame, "RIGHT", -2, 0)  -- V21 listFrame 已收窄, 内边距 -2
    local collapseAllText = collapseAllBtn:CreateFontString(nil, "OVERLAY")
    collapseAllText:SetFont("Fonts\\FRIZQT__.TTF", 14)
    collapseAllText:SetPoint("LEFT", collapseAllBtn, "LEFT", 2, 0)
    collapseAllText:SetWidth(14)
    collapseAllText:SetTextColor(0.98, 0.91, 0.58)
    collapseAllText:SetText("-")
    local collapseAllLabel = collapseAllBtn:CreateFontString(nil, "OVERLAY")
    collapseAllLabel:SetFont("Fonts\\FRIZQT__.TTF", 17)
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

        -- V24 Header 3-slice (retail Professions-recipe-header-left/middle/right)
        -- atlas 原像素 BGR(24,26,29) 暗灰, ADD blend 叠加到亮色 marble 背景 → 视觉变亮
        -- (selectedOverlay / hoverOverlay 已验证 atlas + ADD blend 模式可靠)
        local headerLeft = btn:CreateTexture(nil, "BACKGROUND")
        ApplyAtlas(headerLeft, "recipe-header-left", false)
        headerLeft:SetWidth(14); headerLeft:SetHeight(20)
        headerLeft:SetPoint("LEFT", btn, "LEFT", 0, 0)
        headerLeft:SetBlendMode("ADD")
        headerLeft:Hide()
        btn.headerLeft = headerLeft

        local headerRight = btn:CreateTexture(nil, "BACKGROUND")
        ApplyAtlas(headerRight, "recipe-header-right", false)
        headerRight:SetWidth(14); headerRight:SetHeight(20)
        headerRight:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
        headerRight:SetBlendMode("ADD")
        headerRight:Hide()
        btn.headerRight = headerRight

        local headerMid = btn:CreateTexture(nil, "BACKGROUND")
        ApplyAtlas(headerMid, "recipe-header-middle", false)
        headerMid:SetPoint("TOPLEFT", headerLeft, "TOPRIGHT", 0, 0)
        headerMid:SetPoint("BOTTOMRIGHT", headerRight, "BOTTOMLEFT", 0, 0)
        headerMid:SetBlendMode("ADD")
        headerMid:Hide()
        btn.headerMid = headerMid

        -- 悬停: vanilla UI-QuestLogTitleHighlight 是灰色 alpha mask, SetVertexColor 染金
        local hoverOverlay = btn:CreateTexture(nil, "HIGHLIGHT")
        hoverOverlay:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
        hoverOverlay:SetTexCoord(0, 1, 0, 1)
        hoverOverlay:SetAllPoints(btn)
        hoverOverlay:SetBlendMode("ADD")
        hoverOverlay:SetVertexColor(1.00, 0.82, 0.00)

        -- 选中: 同源金色 bar, Show/Hide 由 SetButtonSelected 切换
        local selectedOverlay = btn:CreateTexture(nil, "BORDER")
        selectedOverlay:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
        selectedOverlay:SetTexCoord(0, 1, 0, 1)
        selectedOverlay:SetAllPoints(btn)
        selectedOverlay:SetBlendMode("ADD")
        selectedOverlay:SetVertexColor(1.00, 0.82, 0.00)
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

        -- V26 回退 V24 atlas Texture → FontString +/- (atlas 在游戏内不显示, 文字稳定)
        local collapseIcon = btn:CreateFontString(nil, "OVERLAY")
        collapseIcon:SetFont("Fonts\\FRIZQT__.TTF", 14)
        collapseIcon:SetPoint("LEFT", btn, "LEFT", 2, 0)
        collapseIcon:SetWidth(14)
        collapseIcon:SetTextColor(0.98, 0.91, 0.58)
        btn.collapseIcon = collapseIcon

        local nameText = btn:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 16)
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
            btn:SetPoint("TOPLEFT", recipeButtons[i - 1], "BOTTOMLEFT", 0, -3)  -- V13 行间距 0→-3 适配大字
        end
        btn:SetPoint("RIGHT", listFrame, "RIGHT", -2, 0)  -- V21 listFrame 已收窄, 内边距 -2
        table.insert(recipeButtons, btn)
    end

    -- ============================================================
    -- 6. 右页 — 配方详情
    -- ============================================================
    local detailFrame = CreateFrame("Frame", nil, panel)
    detailFrame:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 20, -18)
    detailFrame:SetPoint("BOTTOMRIGHT", rightColumn, "BOTTOMRIGHT", -18, 48)
    detailFrame:SetFrameLevel(panel:GetFrameLevel() + 3)

    -- V5 detailFrame: 1.12 内置 SetBackdrop nineslice (替代 V4 textPanel + 自制 shadow)
    -- alpha 0.40 暗底, 让专业背景画局部透出, 同时为右侧内容提供凹陷容器边框
    -- V8.7 删除 detailFrame InsetFrame (右侧已有 rightColumn 单层 InsetFrame, 避免"框中框")

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
    detailIconCount:SetFont("Fonts\\FRIZQT__.TTF", 17, "OUTLINE")
    detailIconCount:SetPoint("BOTTOMRIGHT", detailIconBtn, "BOTTOMRIGHT", -3, 2)
    detailIconCount:SetTextColor(1, 1, 1)
    detailIconCount:Hide()

    -- 主图标边框 (retail Slot-Frame, 按产物品质动态切换 - 见 UpdateDetail)
    -- TGA 64×64 但实际边框内容在 (12,12)-(50,50)，用 TexCoord 裁掉外围透明 padding
    -- v5: 比 detailIconBtn 外扩 4px（每边），边框更粗 + 包图标外留间距
    local detailIconBorder = detailIconBtn:CreateTexture(nil, "OVERLAY")
    detailIconBorder:SetTexture(PROF_TEX .. "slot_blue.tga")
    detailIconBorder:SetTexCoord(12/64, 51/64, 12/64, 51/64)
    detailIconBorder:SetPoint("TOPLEFT",     detailIconBtn, "TOPLEFT",     -4,  4)
    detailIconBorder:SetPoint("BOTTOMRIGHT", detailIconBtn, "BOTTOMRIGHT",  4, -4)

    -- detailName (retail GameFontHighlightMed2 ≈ 14pt, LEFT icon RIGHT +14,+17)
    -- 加 OUTLINE 因为浮在专业背景画上 (无暗底)
    local detailName = detailFrame:CreateFontString(nil, "OVERLAY")
    detailName:SetFont("Fonts\\FRIZQT__.TTF", 18)
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
    detailSubText:SetFont("Fonts\\FRIZQT__.TTF", 16)
    detailSubText:SetPoint("TOPLEFT", detailName, "BOTTOMLEFT", 0, -8)
    detailSubText:SetWidth(400)
    detailSubText:SetJustifyH("LEFT")
    detailSubText:SetTextColor(0.98, 0.91, 0.58)

    -- detailCooldown / Require / Points: -3 间距统一, OUTLINE 保可读
    local detailCooldown = detailFrame:CreateFontString(nil, "OVERLAY")
    detailCooldown:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    detailCooldown:SetPoint("TOPLEFT", detailSubText, "BOTTOMLEFT", 0, -6)
    detailCooldown:SetWidth(400)
    detailCooldown:SetTextColor(0.95, 0.90, 0.80)

    local detailRequire = detailFrame:CreateFontString(nil, "OVERLAY")
    detailRequire:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    detailRequire:SetPoint("TOPLEFT", detailCooldown, "BOTTOMLEFT", 0, -6)
    detailRequire:SetWidth(400)
    detailRequire:SetTextColor(0.95, 0.90, 0.80)

    local detailPoints = detailFrame:CreateFontString(nil, "OVERLAY")
    detailPoints:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    detailPoints:SetPoint("TOPLEFT", detailRequire, "BOTTOMLEFT", 0, -6)
    detailPoints:SetWidth(400)
    detailPoints:SetTextColor(0.98, 0.91, 0.58)

    -- detailDesc (12pt OUTLINE, 宽度 460)
    local detailDesc = detailFrame:CreateFontString(nil, "OVERLAY")
    detailDesc:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    detailDesc:SetPoint("TOPLEFT", detailPoints, "BOTTOMLEFT", 0, -6)
    detailDesc:SetWidth(LAYOUT.DETAIL_DESC_WIDTH)
    detailDesc:SetJustifyH("LEFT")
    detailDesc:SetTextColor(0.90, 0.86, 0.72)

    -- reagentLabel (retail Reagents container Label, OUTLINE 保浮在背景画上可读)
    local reagentLabel = detailFrame:CreateFontString(nil, "OVERLAY")
    reagentLabel:SetFont("Fonts\\FRIZQT__.TTF", 17)
    reagentLabel:SetText("材料:")
    reagentLabel:SetTextColor(0.98, 0.91, 0.58)

    -- 材料格工厂 (retail ProfessionsReagentSlotBaseTemplate: 180×50 容器 + 39×39 按钮)
    local function CreateReagentSlot(parent)
        local slot = CreateFrame("Frame", nil, parent)
        slot:SetWidth(180)
        slot:SetHeight(50)

        local iconFrame = CreateFrame("Button", nil, slot)
        iconFrame:SetWidth(40)   -- V14: 39→40 匹配 retail professions-slot-frame 真尺寸
        iconFrame:SetHeight(40)
        iconFrame:SetPoint("LEFT", slot, "LEFT", 0, 0)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(iconFrame)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon = icon

        -- V16: retail 真 reagent slot frame (professions-slot-frame-blue)
        -- 经验证 atlas_main.tga 中 gray slot-frame 区域无数据 (空), 但 4 品质色 frame 都有真 metallic 边
        -- 用 blue 与主产物 detailIconBtn slot_blue.tga 同色调统一 (截图风格)
        -- dict.json: professions-slot-frame-blue px=(773, 28)-(813, 68), 40×40
        -- P1-D2 v2: 用独立 slot_*.tga 文件而非 atlas_main 切片
        -- 第九轮续2: 5 张 slot_*.tga 64×64 真实内容仅 (12,12)-(50,50), 需 SetTexCoord 裁外围 padding
        -- v5: 比 iconFrame 外扩 4px（每边），边框更粗 + 包图标外留间距
        local border = iconFrame:CreateTexture(nil, "OVERLAY")
        border:SetTexture(PROF_TEX .. "slot_blue.tga")
        border:SetTexCoord(12/64, 51/64, 12/64, 51/64)
        border:SetPoint("TOPLEFT",     iconFrame, "TOPLEFT",     -4,  4)
        border:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT",  4, -4)
        slot.border = border

        -- nameText (retail LEFT x=46 from slot LEFT, i.e. iconFrame RIGHT +7, 无 OUTLINE)
        local nameText = slot:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 16)
        nameText:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 7, 0)
        nameText:SetPoint("RIGHT", slot, "RIGHT", -5, 0)
        nameText:SetJustifyH("LEFT")
        slot.nameText = nameText

        -- countText (retail BOTTOMRIGHT 小字, 我们用 TOPLEFT 下方 -2 间距)
        local countText = slot:CreateFontString(nil, "OVERLAY")
        countText:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
        countText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
        slot.countText = countText

        slot.iconFrame = iconFrame
        slot.reagentIndex = nil
        return slot
    end

    -- P1-D2 v4: 修正品质→边框映射（retail Professions 真实约定）
    -- 关键：slot_blue.tga 实际是 retail "rare(3) 蓝色"边框，不是 common 默认；slot_green 是 uncommon(2)
    -- 1.12 大部分材料是 common(1)，之前误映射到 slot_blue 导致全蓝
    local QUALITY_TGA = {
        common    = PROF_TEX .. "slot_neutral.tga",    -- common(0/1) 灰色 neutral
        uncommon  = PROF_TEX .. "slot_green.tga",      -- uncommon(2) 绿色
        rare      = PROF_TEX .. "slot_blue.tga",       -- rare(3) 蓝色（retail "blue" 的本意）
        epic      = PROF_TEX .. "slot_epic.tga",       -- epic(4) 紫色
        legendary = PROF_TEX .. "slot_legendary.tga",  -- legendary(5) 橙色
    }
    local function RarityToQuality(rarity)
        if rarity == 5 then return "legendary"
        elseif rarity == 4 then return "epic"
        elseif rarity == 3 then return "rare"
        elseif rarity == 2 then return "uncommon"
        else return "common" end  -- 0/1/nil → common (灰色)
    end
    -- 1.12 vanilla item quality 颜色头映射 (|cffXXXXXX prefix)
    -- 比 GetItemInfo 更可靠：itemLink 本身就带颜色码，不需要 itemCache
    local LINK_COLOR_TO_RARITY = {
        ["9d9d9d"] = 0,  -- 灰 poor
        ["ffffff"] = 1,  -- 白 common
        ["1eff00"] = 2,  -- 绿 uncommon
        ["0070dd"] = 3,  -- 蓝 rare
        ["a335ee"] = 4,  -- 紫 epic
        ["ff8000"] = 5,  -- 橙 legendary
    }
    for i = 1, MAX_REAGENTS do
        local slot = CreateReagentSlot(detailFrame)
        slot:Hide()
        -- P1-D2: 不再按 slot index 硬编码循环色 (与材料品质无关), 由 UpdateDetail 动态切换
        table.insert(reagentSlots, slot)
    end


    -- ============================================================
    -- 7. 底部操作区 (retail ui-panel-button 9-slice 三段拼接, V4 修补 V3 圆形拉伸变形)
    -- TGA 128×32: 按钮形状 x=2-76 y=2-22, 9-slice 拆 leftCap 12px + middle 拉伸 + rightCap 12px
    -- retail emboss 金属红按钮: 中央暗红木纹 + 顶/左暖灰高光 + 底/右黑色阴影 = 凸起金属感
    -- ============================================================
    local BTN_UP_TEX   = PROF_TEX .. "btn_up.tga"
    local BTN_DOWN_TEX = PROF_TEX .. "btn_down.tga"
    local BTN_HL_TEX   = PROF_TEX .. "btn_hl.tga"
    -- 9-slice TexCoord (按钮内容区 atlas 比例)
    local BTN_TC_L = {2/128,  14/128, 2/32, 22/32}  -- leftCap 12px (含 atlas 左 cap)
    local BTN_TC_M = {14/128, 64/128, 2/32, 22/32}  -- middle 50px atlas, 拉伸到任意宽度
    local BTN_TC_R = {64/128, 78/128, 2/32, 22/32}  -- rightCap：右边界 76→78 补全最右边框线（同 CreateActionButton AB_TC_R）

    local function CreateSimpleButton(parent, width, text)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetWidth(width)
        btn:SetHeight(24)
        btn:SetFrameLevel(parent:GetFrameLevel() + 5)

        -- 9-slice 三段拼接 helper
        local function makeSlice(layer, tex, blend)
            local L = btn:CreateTexture(nil, layer)
            L:SetTexture(tex)
            L:SetTexCoord(BTN_TC_L[1], BTN_TC_L[2], BTN_TC_L[3], BTN_TC_L[4])
            L:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
            L:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
            L:SetWidth(12)
            if blend then L:SetBlendMode(blend) end
            local R = btn:CreateTexture(nil, layer)
            R:SetTexture(tex)
            R:SetTexCoord(BTN_TC_R[1], BTN_TC_R[2], BTN_TC_R[3], BTN_TC_R[4])
            R:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
            R:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            R:SetWidth(12)
            if blend then R:SetBlendMode(blend) end
            local M = btn:CreateTexture(nil, layer)
            M:SetTexture(tex)
            M:SetTexCoord(BTN_TC_M[1], BTN_TC_M[2], BTN_TC_M[3], BTN_TC_M[4])
            M:SetPoint("TOPLEFT", L, "TOPRIGHT", 0, 0)
            M:SetPoint("BOTTOMRIGHT", R, "BOTTOMLEFT", 0, 0)
            if blend then M:SetBlendMode(blend) end
            return {L, M, R}
        end

        -- Normal 态 (BACKGROUND 默认显示, btn_up emboss 凸起红)
        local normal = makeSlice("BACKGROUND", BTN_UP_TEX)
        -- Pushed 态用 OnMouseDown 切换 (1.12 SetPushedTexture 不支持多 texture nineslice)
        btn:SetScript("OnMouseDown", function()
            for _, t in ipairs(normal) do t:SetTexture(BTN_DOWN_TEX) end
        end)
        btn:SetScript("OnMouseUp", function()
            for _, t in ipairs(normal) do t:SetTexture(BTN_UP_TEX) end
        end)
        -- Highlight 态 (HIGHLIGHT 层 ADD blend 引擎自动管理)
        makeSlice("HIGHLIGHT", BTN_HL_TEX, "ADD")

        -- 标签 (金色 + OUTLINE 浮在按钮红底上保可读)
        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        label:SetText(text)
        label:SetTextColor(1.00, 0.82, 0.00)
        btn.label = label

        return btn
    end

    local createBtn = CreateSimpleButton(panel, 160, "制作")
    createBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -36, 16)  -- V9 锚 panel 底部固定位置 (不随 rightColumn 上移)

    local cancelBtn = CreateSimpleButton(panel, 70, "取消")
    cancelBtn:SetPoint("RIGHT", createBtn, "LEFT", -10, 0)

    -- 训练点数显示（仅宠物训练模式，在取消按钮左侧）
    local trainingPointsText = panel:CreateFontString(nil, "OVERLAY")
    trainingPointsText:SetFont("Fonts\\FRIZQT__.TTF", 16)
    trainingPointsText:SetPoint("RIGHT", cancelBtn, "LEFT", -12, 0)
    trainingPointsText:SetTextColor(0.98, 0.91, 0.58)
    trainingPointsText:Hide()

    local createAllBtn = CreateSimpleButton(panel, 80, "全部")
    createAllBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -10, 0)

    local incrementBtn = CreateSimpleButton(panel, 20, "+")
    incrementBtn:SetPoint("RIGHT", createAllBtn, "LEFT", -12, 0)

    local inputBoxBg = CreateFrame("Frame", nil, panel)
    inputBoxBg:SetWidth(36)
    inputBoxBg:SetHeight(24)
    inputBoxBg:SetPoint("RIGHT", incrementBtn, "LEFT", -3, 0)
    inputBoxBg:SetFrameLevel(panel:GetFrameLevel() + 5)
    -- V5 数量输入框: 1.12 内置 SetBackdrop nineslice
    CreateInsetBackdrop(inputBoxBg, 0.85)

    local inputBox = CreateFrame("EditBox", nil, inputBoxBg)
    inputBox:SetPoint("TOPLEFT", inputBoxBg, "TOPLEFT", 4, -3)
    inputBox:SetPoint("BOTTOMRIGHT", inputBoxBg, "BOTTOMRIGHT", -4, 3)
    inputBox:SetAutoFocus(false)
    inputBox:SetFont("Fonts\\FRIZQT__.TTF", 15)
    inputBox:SetJustifyH("CENTER")
    inputBox:SetText("1")
    inputBox:SetTextColor(0.95, 0.90, 0.80)
    inputBox:SetNumeric(true)
    inputBox:SetFrameLevel(inputBoxBg:GetFrameLevel() + 1)
    inputBox:SetScript("OnEscapePressed", function() inputBox:ClearFocus() end)
    inputBox:SetScript("OnEnterPressed", function() inputBox:ClearFocus() end)

    local decrementBtn = CreateSimpleButton(panel, 20, "-")
    decrementBtn:SetPoint("RIGHT", inputBoxBg, "LEFT", -3, 0)


    -- 搜索框 (Frame 容器承载 Backdrop + 裸 EditBox)
    local searchBg = CreateFrame("Frame", nil, panel)
    searchBg:SetWidth(140)  -- V26 缩小让位 "有材料" checkbox
    searchBg:SetHeight(22)
    searchBg:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 10, -15)  -- V26 搬到顶部跟 checkbox 同行
    searchBg:SetFrameLevel(panel:GetFrameLevel() + 5)
    -- V5 搜索框: 1.12 内置 SetBackdrop nineslice
    CreateInsetBackdrop(searchBg, 0.85)

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
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 15)
    searchBox:SetTextColor(0.95, 0.90, 0.80)
    searchBox:SetFrameLevel(searchBg:GetFrameLevel() + 1)
    searchBox:SetTextInsets(2, 2, 0, 0)

    local searchPlaceholder = searchBg:CreateFontString(nil, "OVERLAY")
    searchPlaceholder:SetFont("Fonts\\FRIZQT__.TTF", 15)
    searchPlaceholder:SetPoint("LEFT", searchBg, "LEFT", 24, 0)
    searchPlaceholder:SetText("搜索配方...")
    searchPlaceholder:SetTextColor(0.55, 0.50, 0.40)

    -- 过滤器移到 leftColumn 顶部 (retail 风格, "过滤器" 区在列表上方)
    local matsCheckbox = CreateCheckbox(panel, "有材料")
    matsCheckbox:SetPoint("LEFT", searchBg, "RIGHT", 14, 0)  -- V26 跟搜索框同行 + 右移
    matsCheckbox:SetFrameLevel(panel:GetFrameLevel() + 5)
    matsCheckbox:SetChecked(false)
    -- V26 字体 11 → 15 跟搜索框 / 面板其他文字尺寸协调
    matsCheckbox.label:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")


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

    RebuildRecipeData = function()  -- 数据层：全表扫描→过滤→图标预取→写入 recipeCache。仅数据变化时调用，不在滚动路径
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
            -- P0-#7 与 UpdateDetail 防守风格一致：pcall 包装避免 API 未就绪时崩溃
            if currentMode == "tradeskill" then
                local ok, n, st, na, ie = pcall(GetTradeSkillInfo, i)
                if ok then name, skillType, numAvail, isExpanded = n, st, na, ie end
            elseif currentMode == "craft" then
                local ok, n, sub, st, na, ie = pcall(GetCraftInfo, i)
                if ok then
                    name, skillType, numAvail, isExpanded = n, st, na, ie
                    subName = sub
                end
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

        -- 自审 B3: 回退 P0-#5"末位 header pending 清理"。原代码逻辑正确：
        --   末位展开 header 若其后子项全被搜索过滤 → pending=true 不被清 → cleanItems 过滤掉空 header (正确 UX)
        --   第十轮 #1.14 已修"连续 header"场景；末位空 header 应该消失而非保留显示。

        -- 去掉无子项的 header；同时把所有滚动派生量预计算进缓存（渲染阶段直接读，不再跨 C 边界/拼字符串/查表——滚动热点）
        -- 注意：displayName/skillKey/color/isFav 仅在此刷新；新增"非滚动"刷新点必须走 Rebuild(UpdateRecipeList)，否则缓存陈旧
        local cleanItems = {}
        for _, item in ipairs(visibleItems) do
            if not item.pending then
                if not item.isHeader then
                    if currentMode == "tradeskill" then
                        local ok, tex = pcall(GetTradeSkillIcon, item.index)
                        if ok then item.icon = tex end
                    elseif currentMode == "craft" then
                        local ok, tex = pcall(GetCraftIcon, item.index)
                        if ok then item.icon = tex end
                    end
                    -- Layer A: 预计算 displayName（等价旧 Render 的 gsub+拼接）
                    local displayName = item.name
                    if item.subName and item.subName ~= "" then
                        local localSub = string.gsub(item.subName, "^Rank ", "等级 ")
                        displayName = displayName .. " (" .. localSub .. ")"
                    end
                    if item.numAvail and item.numAvail > 0 then
                        displayName = displayName .. " [" .. item.numAvail .. "]"
                    end
                    item.displayName = displayName
                    -- Layer A: 预计算难度 atlas key（仅 tradeskill 模式）
                    if currentMode == "tradeskill" then
                        if item.skillType == "optimal" then item.skillKey = "icon-skill-high"
                        elseif item.skillType == "medium" then item.skillKey = "icon-skill-medium"
                        elseif item.skillType == "easy" or item.skillType == "trivial" then item.skillKey = "icon-skill-low"
                        else item.skillKey = nil end
                    else
                        item.skillKey = nil
                    end
                    -- Layer A: 难度色（DIFFICULTY_COLORS 子表引用，零新建表）+ 收藏态
                    item.color = DIFFICULTY_COLORS[item.skillType] or DIFFICULTY_COLORS.default
                    item.isFav = IsFavorite(item.name)
                end
                table.insert(cleanItems, item)
            end
        end

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

        recipeCache = cleanItems

        -- Layer C: 把未预热的图标路径入队（warmDone 去重），由 panel:OnUpdate 分帧载入
        for i = 1, table.getn(cleanItems) do
            local ic = cleanItems[i].icon
            if ic and not warmDone[ic] then
                table.insert(warmQueue, ic)
                warmDone[ic] = true
            end
        end

        -- 折叠按钮状态（依赖完整数据集，归数据层）
        local anyCollapsed = false
        for _, item in ipairs(cleanItems) do
            if item.isHeader and not item.isExpanded then anyCollapsed = true; break end
        end
        collapseAllText:SetText(anyCollapsed and "+" or "-")
    end

    -- Layer B layout mode 枚举：与 (isHeader, 有无产物图标, 有无难度图标) 一一对应；同 mode 锚点字节级相同 → 可跳过重锚
    local LMODE_HEADER       = 1
    local LMODE_ICON_SKILL   = 2
    local LMODE_ICON_ONLY    = 3
    local LMODE_NOICON_SKILL = 4
    local LMODE_NOICON       = 5

    RenderRecipeButtons = function()  -- 渲染层：仅读 recipeCache 按 scrollOffset 绘制 20 个按钮（滚动只调这个）
        -- clamp 必须在渲染层：滚动改了 scrollOffset 但不 Rebuild，缺它会越界
        local maxOffset = math.max(0, table.getn(recipeCache) - MAX_RECIPE_BUTTONS)
        if scrollOffset > maxOffset then scrollOffset = maxOffset end
        if scrollOffset < 0 then scrollOffset = 0 end

        for i = 1, MAX_RECIPE_BUTTONS do
            local btn = recipeButtons[i]
            local item = recipeCache[scrollOffset + i]
            if item then
                btn.recipeIndex = item.index
                btn.recipeName = item.name
                btn.isHeader = item.isHeader
                btn.isExpanded = item.isExpanded
                if item.isHeader then
                    -- V26 +/- FontString (回退 V24 atlas, 文字稳定显示)
                    btn.collapseIcon:SetText(item.isExpanded and "-" or "+")
                    btn.collapseIcon:Show()
                    btn.recipeIcon:Hide()
                    btn.skillIcon:Hide()
                    btn.favStar:Hide()
                    -- B4 名称锚定 LEFT 18 (留出左侧 +/- 14px + 间距 4)；仅 layout mode 变化时重锚
                    if btn._lastLayoutMode ~= LMODE_HEADER then
                        btn.nameText:ClearAllPoints()
                        btn.nameText:SetPoint("LEFT", btn, "LEFT", 18, 0)
                        btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                        btn._lastLayoutMode = LMODE_HEADER
                    end
                    btn.nameText:SetText(item.name)
                    local hc = DIFFICULTY_COLORS.header
                    btn.nameText:SetTextColor(hc[1], hc[2], hc[3])
                    -- B3 字号仅变化时 SetFont
                    if btn._lastFontSize ~= 17 then
                        btn.nameText:SetFont("Fonts\\FRIZQT__.TTF", 17)
                        btn._lastFontSize = 17
                    end
                    -- V24 3-slice retail header 背景
                    btn.headerLeft:Show()
                    btn.headerMid:Show()
                    btn.headerRight:Show()
                else
                    -- 配方行: 产物图标 + 名称（Render 仅读 Rebuild 预计算字段，不再拼字符串/查表/跨 C 边界）
                    btn.collapseIcon:Hide()
                    btn.headerLeft:Hide()
                    btn.headerMid:Hide()
                    btn.headerRight:Hide()
                    local texture = item.icon or DEFAULT_ICON  -- A: 预取自 RebuildRecipeData；nil 兜底问号
                    local skillKey = item.skillKey  -- A: 难度 atlas key，预计算自 RebuildRecipeData
                    -- B2 难度图标: 仅 skillKey 变化时 ApplyAtlas (同 key 纹理/尺寸不变)
                    if skillKey then
                        if btn._lastSkillKey ~= skillKey then
                            ApplyAtlas(btn.skillIcon, skillKey, false)
                            btn.skillIcon:SetWidth(13); btn.skillIcon:SetHeight(15)
                            btn._lastSkillKey = skillKey
                        end
                        btn.skillIcon:Show()
                    else
                        btn.skillIcon:Hide()
                    end
                    -- B1 产物图标: 仅纹理路径变化时 SetTexture (消除重复纹理绑定)
                    if texture then
                        if btn._lastIcon ~= texture then
                            btn.recipeIcon:SetTexture(texture)
                            btn._lastIcon = texture
                        end
                        btn.recipeIcon:Show()
                    else
                        btn.recipeIcon:Hide()
                    end
                    -- B4 锚定: 5 种 layout mode，仅 mode 变化时重锚 (同 mode 锚点字节级相同)
                    local lmode
                    if texture then
                        lmode = skillKey and LMODE_ICON_SKILL or LMODE_ICON_ONLY
                    else
                        lmode = skillKey and LMODE_NOICON_SKILL or LMODE_NOICON
                    end
                    if btn._lastLayoutMode ~= lmode then
                        if lmode == LMODE_ICON_SKILL then
                            btn.skillIcon:ClearAllPoints()
                            btn.skillIcon:SetPoint("LEFT", btn.recipeIcon, "RIGHT", 2, 0)
                            btn.nameText:ClearAllPoints()
                            btn.nameText:SetPoint("LEFT", btn.skillIcon, "RIGHT", 2, 0)
                            btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                        elseif lmode == LMODE_ICON_ONLY then
                            btn.nameText:ClearAllPoints()
                            btn.nameText:SetPoint("LEFT", btn.recipeIcon, "RIGHT", 4, 0)
                            btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                        elseif lmode == LMODE_NOICON_SKILL then
                            btn.skillIcon:ClearAllPoints()
                            btn.skillIcon:SetPoint("LEFT", btn, "LEFT", 4, 0)
                            btn.nameText:ClearAllPoints()
                            btn.nameText:SetPoint("LEFT", btn.skillIcon, "RIGHT", 3, 0)
                            btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                        else  -- LMODE_NOICON
                            btn.nameText:ClearAllPoints()
                            btn.nameText:SetPoint("LEFT", btn, "LEFT", 20, 0)
                            btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                        end
                        btn._lastLayoutMode = lmode
                    end
                    -- A: 读预计算的 displayName / color / isFav (V10 已删 SkillUps 后缀)
                    btn.nameText:SetText(item.displayName)
                    btn.nameText:SetTextColor(item.color[1], item.color[2], item.color[3])
                    -- B3 字号仅变化时 SetFont
                    if btn._lastFontSize ~= 16 then
                        btn.nameText:SetFont("Fonts\\FRIZQT__.TTF", 16)
                        btn._lastFontSize = 16
                    end
                    -- 收藏星标
                    if item.isFav then btn.favStar:Show() else btn.favStar:Hide() end
                end
                SetButtonSelected(btn, not item.isHeader and item.index == selectedIndex)
                btn:Show()
            else
                btn.recipeIndex = nil
                btn.recipeName = nil
                btn.isHeader = false
                btn.recipeIcon:Hide()
                btn.skillIcon:Hide()
                btn.headerLeft:Hide()
                btn.headerMid:Hide()
                btn.headerRight:Hide()
                btn.collapseIcon:Hide()
                btn.favStar:Hide()
                -- B 缓存失效: 空槽复位，避免下次复用此按钮时脏值跳过必要的 SetTexture/ApplyAtlas/锚定
                btn._lastIcon = nil
                btn._lastSkillKey = nil
                btn._lastFontSize = nil
                btn._lastLayoutMode = nil
                btn:Hide()
            end
        end

    end

    -- 兼容包装：数据真变化的调用点（搜索/过滤/折叠/事件刷新）走这里；滚动只调 RenderRecipeButtons
    UpdateRecipeList = function()
        RebuildRecipeData()
        RenderRecipeButtons()
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

        detailIcon:SetTexture(texture or DEFAULT_ICON)
        detailName:SetText(name)
        detailSubText:SetText(""); detailSubText:Hide()

        -- v5: 主产物图标边框按产物品质动态切换（与 reagent slot 同套 QUALITY_TGA）
        -- craft 模式（附魔等）产物非 inventory item 通常无 itemLink → outputRarity=nil → common(灰)
        if detailIconBorder then
            local outputLink
            if currentMode == "tradeskill" and GetTradeSkillItemLink then
                local lok, link = pcall(GetTradeSkillItemLink, selectedIndex)
                if lok then outputLink = link end
            elseif currentMode == "craft" and GetCraftItemLink then
                local lok, link = pcall(GetCraftItemLink, selectedIndex)
                if lok then outputLink = link end
            end
            local outputRarity
            if outputLink then
                local _, _, colorHex = string.find(outputLink, "|cff(%x%x%x%x%x%x)")
                if colorHex then outputRarity = LINK_COLOR_TO_RARITY[string.lower(colorHex)] end
            end
            if not outputRarity then
                local _, _, _, q = pcall(GetItemInfo, outputLink or name)
                outputRarity = q
            end
            local outputTga = QUALITY_TGA[RarityToQuality(outputRarity)]
            if outputTga then
                detailIconBorder:SetTexture(outputTga)
                detailIconBorder:SetTexCoord(12/64, 51/64, 12/64, 51/64)
            end
        end

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
        reagentLabel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -61, -50)  -- V15 -30→-50 reagent 区整体下移 20px

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
                    slot.icon:SetTexture(rTex or DEFAULT_ICON)
                    slot.nameText:SetText(rName)
                    pCount = pCount or 0
                    slot.countText:SetText("(" .. pCount .. "/" .. rCount .. ")")
                    local enough = pCount >= rCount
                    local r, g, b = 0.95, 0.90, 0.78
                    if not enough then r, g, b = 1.00, 0.30, 0.30 end
                    slot.nameText:SetTextColor(r, g, b)
                    slot.countText:SetTextColor(r, g, b)
                    -- P1-D2 v4: 优先从 itemLink 颜色头解析 rarity（验证 OK：颜色头提取稳定）
                    -- fallback 链：itemLink 颜色头 → GetItemInfo(itemLink) → GetItemInfo(itemName)
                    if slot.border then
                        local itemLink
                        if currentMode == "tradeskill" and GetTradeSkillReagentItemLink then
                            local lok, link = pcall(GetTradeSkillReagentItemLink, selectedIndex, i)
                            if lok then itemLink = link end
                        elseif currentMode == "craft" and GetCraftReagentItemLink then
                            local lok, link = pcall(GetCraftReagentItemLink, selectedIndex, i)
                            if lok then itemLink = link end
                        end
                        local rarity
                        if itemLink then
                            local _, _, colorHex = string.find(itemLink, "|cff(%x%x%x%x%x%x)")
                            if colorHex then rarity = LINK_COLOR_TO_RARITY[string.lower(colorHex)] end
                        end
                        if not rarity then
                            local _, _, _, q = pcall(GetItemInfo, itemLink or rName)
                            rarity = q
                        end
                        local tga = QUALITY_TGA[RarityToQuality(rarity)]
                        if tga then
                            slot.border:SetTexture(tga)
                            slot.border:SetTexCoord(12/64, 51/64, 12/64, 51/64)
                        end
                    end
                    slot.reagentIndex = i
                    slot:ClearAllPoints()
                    -- retail 网格: 3 列 × 3 行 (适配 detailFrame 717 宽), spacing 5px
                    local col = math.mod(i - 1, 3)
                    local row = math.floor((i - 1) / 3)
                    slot:SetPoint("TOPLEFT", reagentLabel, "BOTTOMLEFT", col * 200, -8 - row * 65)  -- V5 col 185→200 row 55→65 加大网格呼吸
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

    -- 滚轮 (上限由 UpdateRecipeList 内部 clamp，此处只管方向)
    listFrame:EnableMouseWheel(true)
    listFrame:SetScript("OnMouseWheel", function()
        if arg1 > 0 then
            scrollOffset = math.max(0, scrollOffset - 3)
        else
            scrollOffset = scrollOffset + 3
        end
        RenderRecipeButtons()  -- 滚动不改数据，只重绘缓存（clamp 在 Render 内）
    end)

    -- ============================================================
    -- 10. Tab 系统
    -- ============================================================
    local tabPool = {}
    local tabPoolSize = 0
    local knownProfessions = {}
    local pendingTab        -- 用户点击意图打开的 tab（OpenProfession 用它高亮，不依赖 GetCraftName）
    local activeTab         -- 当前已激活的 tab 引用（防重复点击 → 避免对已开专业再施法 = toggle 关闭面板）

    local function ReleaseAllTabs()
        for i = 1, tabPoolSize do
            tabPool[i]:SetSelected(false)
            tabPool[i]:Hide()
        end
        panel.Tabs = {}
        panel.selectedTab = nil
        tabPoolSize = 0
        pendingTab = nil
        activeTab = nil
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
        ["Survival"] = true, ["生存"] = true,
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
            local tab
            tab = AcquireTab(displayName, function()
                -- 防重复：点已激活的 tab 不再施法（对已开专业再施法 = toggle 关闭面板）
                -- 用 tab 引用判断，不靠 GetCraftName 字符串（生存等自定义专业 API 名会乱报成"烹饪"）
                if activeTab == tab then return end
                activeTab = tab    -- 立即标记（不等 CRAFT_SHOW 回调），防快速双击在事件回调前再次施法→关闭
                pendingTab = tab
                CastSpell(captured.spellIndex, BOOKTYPE_SPELL)
            end, nil, (i == 1 and 2 or 4))
            -- 首建时按当前专业名高亮（外部施法打开的回退；点 tab 打开由 OpenProfession 用 pendingTab 处理）
            if currentName and prof.name == currentName then
                tab:SetSelected(true)
                panel.selectedTab = tab
                activeTab = tab
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
        matsCheckbox:SetChecked(false)

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
        if bgKey == "survival" then
            -- bg_survival 取自 DF specialization-background 系列(铭文)，内容区 708×522，UV 来自 _html_dict 字典
            detailBg:SetTexCoord(0.000977, 0.692383, 0.000977, 0.510742)
        else
            -- 其余取自 recipe-background 系列，内容区 676×549
            detailBg:SetTexCoord(0, 339/512, 0, 275/512)
        end
        detailBg:SetVertexColor(1, 1, 1, 1)

        -- 扫描法术书专业（需在设置图标前完成，避免首次打开没 texture）
        if not profScanned then
            ScanSpellbookForProfessions()
            if table.getn(knownProfessions) > 0 then profScanned = true end
        end

        -- 左上角图标保持玩家职业图标（不随专业切换）

        UpdateRankBar()
        if table.getn(panel.Tabs) == 0 then
            CreateProfessionTabs()
        end
        -- 高亮：优先用"用户点击的 tab"(pendingTab)——不依赖 GetCraftName 字符串，
        -- 对生存等 API 名乱报的自定义专业也能正确高亮 + 标记激活（防重复点击关闭）
        if pendingTab then
            if panel.selectedTab then panel.selectedTab:SetSelected(false) end
            pendingTab:SetSelected(true)
            panel.selectedTab = pendingTab
            activeTab = pendingTab
            pendingTab = nil
        else
            -- 外部施法/首次打开：回退按当前专业名匹配
            if panel.selectedTab then panel.selectedTab:SetSelected(false) end
            panel.selectedTab = nil
            local activeDisplay = activeProfName and (PROF_DISPLAY_NAME[activeProfName] or activeProfName)
            for _, tab in ipairs(panel.Tabs) do
                if tab.Text and activeDisplay and tab.Text:GetText() == activeDisplay then
                    tab:SetSelected(true)
                    panel.selectedTab = tab
                    activeTab = tab
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
        activeTab = nil
        pendingTab = nil
        -- P0-#2 完整复位 UI 状态：避免重开继承前次过滤/选中/滚动位置
        selectedIndex = nil
        scrollOffset = 0
        filterHasMats = false
        if matsCheckbox and matsCheckbox.SetChecked then
            matsCheckbox:SetChecked(false)
        end
        if searchBox and searchBox.SetText then
            searchBox:SetText("")
        end
        -- 释放背景画显存引用
        detailBg:SetTexture("")
        -- B 缓存失效: 重开绝不脏值 (Layer C 的 iconKeep/warmDone/warmQueue 跨开关持久保留，使图标常驻不重复解码)
        for i = 1, MAX_RECIPE_BUTTONS do
            local b = recipeButtons[i]
            b._lastIcon = nil; b._lastSkillKey = nil; b._lastFontSize = nil; b._lastLayoutMode = nil
        end
        isClosing = false
    end)

    -- P0-#3 OnUpdate 兜底：flush 节流期间累积的 pendingUpdate（避免最后一次 update 丢失）
    panel:SetScript("OnUpdate", function()
        if panel.pendingUpdate and panel.lastUpdate and (GetTime() - panel.lastUpdate) >= 0.1 then
            panel.lastUpdate = GetTime()
            panel.pendingUpdate = false
            if panel:IsShown() then
                UpdateRankBar(); UpdateRecipeList(); UpdateDetail()
            end
        end
        -- Layer C: 分帧为图标建持久常驻纹理 (每帧最多 6 张)，各保留一个引用防逐出 → 上滚回看也命中常驻
        if table.getn(warmQueue) > 0 then
            local budget = 6
            while budget > 0 and table.getn(warmQueue) > 0 do
                local ic = table.remove(warmQueue)
                if not iconKeep[ic] then
                    local t = listFrame:CreateTexture(nil, "BACKGROUND")
                    t:SetWidth(1); t:SetHeight(1)
                    t:SetPoint("BOTTOMLEFT", listFrame, "BOTTOMLEFT", 0, 0)
                    t:SetTexture(ic)   -- 触发解码+载入；隐藏但持有引用 → 常驻
                    t:Hide()
                    iconKeep[ic] = t
                end
                budget = budget - 1
            end
        end
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
        elseif event == "TRADE_SKILL_UPDATE" or event == "CRAFT_UPDATE" then
            -- P0-#3 100ms 节流：合并 BAG_UPDATE/SkillUp/CRAFT_UPDATE 高频连发，避免帧卡顿
            local validMode = (event == "TRADE_SKILL_UPDATE" and currentMode == "tradeskill")
                           or (event == "CRAFT_UPDATE"       and currentMode == "craft")
            if validMode and panel:IsShown() then
                local now = GetTime()
                if panel.lastUpdate and (now - panel.lastUpdate) < 0.1 then
                    panel.pendingUpdate = true
                else
                    panel.lastUpdate = now
                    panel.pendingUpdate = false
                    UpdateRankBar(); UpdateRecipeList(); UpdateDetail()
                end
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
