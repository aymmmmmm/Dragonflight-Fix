setfenv(1, DFUI:GetEnv())

function KillFrame(frame)
    if not frame then return end

    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end

    if frame.Hide then
        frame:Hide()
    end

    if frame.GetScript and frame.SetScript then
        local scriptTypes = {
            "OnShow", "OnHide", "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp",
            "OnClick", "OnDoubleClick", "OnDragStart", "OnDragStop", "OnUpdate",
            "OnEvent", "OnLoad", "OnSizeChanged", "OnValueChanged"
        }

        for _, scriptType in ipairs(scriptTypes) do
            local success = pcall(function() return frame:GetScript(scriptType) end)
            if success and frame:GetScript(scriptType) then
            frame:SetScript(scriptType, nil)
            end
        end
    end

    if frame.SetParent then
        frame:SetParent(UIParent)
    end

    if frame.ClearAllPoints then
        frame:ClearAllPoints()
    end

    if frame.SetAlpha then
        frame:SetAlpha(0)
    end

    if frame.EnableMouse then
        frame:EnableMouse(false)
    end

    if frame.EnableKeyboard then
        frame:EnableKeyboard(false)
    end
end

-- 软隐藏：透明 + 移出屏幕 + 禁交互，但【不 Hide、不清事件/脚本】，
-- 使 frame 继续活在 UIPanel 系统中（用于让自定义面板复用原生 frame 的 UIPanel 互斥）。
function SoftHideFrame(frame)
    if not frame then return end
    frame:SetAlpha(0)
    frame:EnableMouse(false)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000)
end

function HideFrameTextures(frame)
    local regions = {frame:GetRegions()}
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "Texture" then
            region:Hide()
        end
    end
end

function AbbreviateName(name)
    if name and string.len(name) > 5 then
        return string.sub(name, 1, 8) .. "..."
    elseif name then
        return name
    else
        return "无目标"
    end
end

-- 面板打开时恢复默认位置（由原生 ShowUIPanel 系统处理左侧堆叠）
-- 保留函数签名，避免调用处报错；原生面板无需额外干预
function CenterFrame(frame)
    -- no-op: 让 ShowUIPanel 的原生定位生效
end

-- 给深色背景上的控件添加描边（仅边框，无背景）
function AddSubBorder(parent, frame, inset)
    inset = inset or 0
    local border = CreateFrame("Frame", nil, parent)
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset, inset)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset, -inset)
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
    })
    border:SetBackdropBorderColor(0.6, 0.55, 0.5, 1)
    return border
end

HookScript = function(f, script, func)
    local prev = f:GetScript(script)
    f:SetScript(script, function(a1,a2,a3,a4,a5,a6,a7,a8,a9)
    if prev then prev(a1,a2,a3,a4,a5,a6,a7,a8,a9) end
        func(a1,a2,a3,a4,a5,a6,a7,a8,a9)
    end)
end

function hooksecurefunc(name, func, append)
    if not _G[name] then return end

    DFUI.hooks[tostring(func)] = {}
    DFUI.hooks[tostring(func)]["old"] = _G[name]
    DFUI.hooks[tostring(func)]["new"] = func

    if append then
        DFUI.hooks[tostring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            DFUI.hooks[tostring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            DFUI.hooks[tostring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    else
        DFUI.hooks[tostring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            DFUI.hooks[tostring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            DFUI.hooks[tostring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    end

    _G[name] = DFUI.hooks[tostring(func)]["function"]
end

function HookAddonOrVariable(addon, func)
    local lurker = CreateFrame("Frame", nil)
    lurker.func = func
    lurker:RegisterEvent("ADDON_LOADED")
    lurker:RegisterEvent("VARIABLES_LOADED")
    lurker:RegisterEvent("PLAYER_ENTERING_WORLD")
    lurker:SetScript("OnEvent",function()
        -- only run when config is available
        if event == "ADDON_LOADED" and not this.foundConfig then
            return
        elseif event == "VARIABLES_LOADED" then
            this.foundConfig = true
        end

        if IsAddOnLoaded(addon) or _G[addon] then
            this:func()
            this:UnregisterAllEvents()
        end
    end)
end

function HookUnitData(unit, func)
    local lurker = CreateFrame("Frame", nil)
    lurker.func = func
    lurker:RegisterEvent("ADDON_LOADED")
    lurker:RegisterEvent("VARIABLES_LOADED")
    lurker:RegisterEvent("PLAYER_ENTERING_WORLD")
    lurker:SetScript("OnEvent", function()
        if event == "ADDON_LOADED" and not this.foundConfig then
            return
        elseif event == "VARIABLES_LOADED" then
            this.foundConfig = true
        end

        if UnitHealth(unit) > 0 then
            this:func()
            this:UnregisterAllEvents()
        end
    end)
end

-- Font name → path lookup table (shared across all modules)
local FONT_BASE = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\"
DFUI_FONT_PATHS = {
    ["FRIZQT__.TTF"]         = "Fonts\\FRIZQT__.TTF",
    ["Expressway"]           = FONT_BASE .. "Expressway.ttf",
    ["Homespun"]             = FONT_BASE .. "Homespun.ttf",
    ["Hooge"]                = FONT_BASE .. "Hooge.ttf",
    ["Myriad-Pro"]           = FONT_BASE .. "Myriad-Pro.ttf",
    ["Prototype"]            = FONT_BASE .. "Prototype.ttf",
    ["PT-Sans-Narrow-Bold"]  = FONT_BASE .. "PT-Sans-Narrow-Bold.ttf",
    ["PT-Sans-Narrow-Regular"] = FONT_BASE .. "PT-Sans-Narrow-Regular.ttf",
    ["RobotoMono"]           = FONT_BASE .. "RobotoMono.ttf",
    ["BigNoodleTitling"]     = FONT_BASE .. "BigNoodleTitling.ttf",
    ["Continuum"]            = FONT_BASE .. "Continuum.ttf",
    ["DieDieDie"]            = FONT_BASE .. "DieDieDie.ttf",
}

function GetFontPath(fontName, fallback)
    return DFUI_FONT_PATHS[fontName] or fallback or "Fonts\\FRIZQT__.TTF"
end

-- Shared power type → color mapping (0=Mana, 1=Rage, 2=Focus, 3=Energy)
DFUI_POWER_COLORS = {
    [0] = {0, 0, 1},     -- Mana - blue
    [1] = {1, 0, 0},     -- Rage - red
    [2] = {1, 1, 0},     -- Focus - yellow
    [3] = {1, 1, 0},     -- Energy - yellow
}

function GetPowerColor(powerType)
    local c = DFUI_POWER_COLORS[powerType]
    if c then return c[1], c[2], c[3] end
    return 0, 0, 1
end

-- Shared class icon TexCoord table
DFUI_CLASS_ICON_COORDS = {
    WARRIOR = {0, 0.25, 0, 0.25},
    MAGE = {0.25, 0.49609375, 0, 0.25},
    ROGUE = {0.49609375, 0.7421875, 0, 0.25},
    DRUID = {0.7421875, 0.98828125, 0, 0.25},
    HUNTER = {0, 0.25, 0.25, 0.5},
    SHAMAN = {0.25, 0.49609375, 0.25, 0.5},
    PRIEST = {0.49609375, 0.7421875, 0.25, 0.5},
    WARLOCK = {0.7421875, 0.98828125, 0.25, 0.5},
    PALADIN = {0, 0.25, 0.5, 0.75},
}

-- Shared checkbox factory (spellbook / tradeskill panels)
function CreatePanelCheckbox(parent, text)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(20)
    cb:SetHeight(20)
    local label = cb:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    label:SetText(text)
    label:SetTextColor(0.9, 0.9, 0.9)
    cb.label = label
    return cb
end

-- Shared number formatting (1000 → 1.0k, 1000000 → 1.0M)
function FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fk", num / 1000)
    else
        return tostring(num)
    end
end

-- DF 真实纹理九宫格框架工厂（取代 SetBackdrop + UI-Tooltip-Border 线框）
-- 复用 spellbook 已走通的 uiframe_inner 三件套 + UV 切片 + ADD blend + 金色 tint 方案
--
-- Usage:
--   DFUI.ApplyInnerFrame(frame, {
--       preset = "auto" | "hairline" | "small" | "medium" | "large",
--       tint = {r, g, b, a},       -- 默认 {2.5, 2.0, 1.0, 1.0} 金色提亮（与 ADD blend 配）
--       showBackground = true,
--       bgColor = {r, g, b, a},    -- 默认 {0.06, 0.06, 0.09, 0.90}
--       levelOffset = 5,
--   }) -> borderFrame
--
-- 返回 borderFrame 挂 .corners={tl,tr,bl,br} / .edges={top,bot,left,right} / .bg
DFUI.APPLY_INNER_FRAME_ENABLED = true

local IF_TEX = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\"
local IF_ATLAS = IF_TEX .. "interface\\uiframe_inner.tga"
local IF_HORIZ = IF_TEX .. "interface\\uiframe_inner_horizontal.tga"
local IF_VERT  = IF_TEX .. "interface\\uiframe_inner_vertical.tga"

-- UV 坐标（来自 spellbook.lua:138-194，已验证的值）
local UV_TL    = {81/128, 115/128, 1/128, 34/128}
local UV_TR    = {81/128, 114/128, 36/128, 69/128}
local UV_BL    = {57/128, 71/128, 81/128, 95/128}
local UV_BR    = {116/128, 127/128, 63/128, 74/128}
local UV_TOP   = {0, 1, 1/128, 44/128}
local UV_BOT   = {0, 1, 95/128, 104/128}
local UV_LEFT  = {1/64, 17/64, 0, 1}
local UV_RIGHT = {19/64, 29/64, 0, 1}

-- 4 级 preset 尺寸梯度（按 spellbook 512×512 原型缩放）
local IF_SIZES = {
    small  = {tl_w=12, tl_h=12, tr_w=12, tr_h=12, bl_w=12, bl_h=12, br_w=12, br_h=12, top=16, bot=6,  left=8,  right=6},
    medium = {tl_w=32, tl_h=32, tr_w=32, tr_h=32, bl_w=24, bl_h=24, br_w=24, br_h=24, top=43, bot=9,  left=16, right=10},
    large  = {tl_w=102,tl_h=99, tr_w=99, tr_h=99, bl_w=42, bl_h=42, br_w=33, br_h=33, top=129,bot=27, left=48, right=30},
}

function DFUI.ApplyInnerFrame(frame, opts)
    opts = opts or {}

    -- 关闭开关 → 降级到 AddSubBorder（UI-Tooltip-Border 兜底）
    if not DFUI.APPLY_INNER_FRAME_ENABLED then
        return AddSubBorder(frame:GetParent() or UIParent, frame, 0)
    end

    -- 清理可能存在的旧 backdrop
    if frame.SetBackdrop then frame:SetBackdrop(nil) end

    -- DF 金色（0-1 范围，适合深色底 + BLEND 模式）
    -- 如果父容器是浅色/羊皮纸底，可覆盖为 ADD + {2.5, 2.0, 1.0, 1.0} 获得金光效果
    local tint = opts.tint or {1.0, 0.82, 0.4, 1.0}
    local blendMode = opts.blendMode or "BLEND"
    local showBg = opts.showBackground
    if showBg == nil then showBg = true end
    local bgColor = opts.bgColor or {0.06, 0.06, 0.09, 0.90}
    local levelOffset = opts.levelOffset or 5

    -- preset auto：按 frame height 选
    local preset = opts.preset or "auto"
    if preset == "auto" then
        local h = frame:GetHeight() or 0
        if h < 28 then preset = "hairline"
        elseif h < 80 then preset = "small"
        elseif h < 300 then preset = "medium"
        else preset = "large" end
    end

    local borderFrame = CreateFrame("Frame", nil, frame)
    borderFrame:SetAllPoints(frame)
    borderFrame:SetFrameLevel(frame:GetFrameLevel() + levelOffset)
    borderFrame.corners = {}
    borderFrame.edges = {}

    -- 背景层：必须挂 frame 自己的 BACKGROUND 层（不是 borderFrame）
    -- 否则 borderFrame (FL+5) 里的 bg 会盖住 frame 内所有 children
    if showBg and frame.CreateTexture then
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(frame)
        bg:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        borderFrame.bg = bg
    end

    local function tintTex(tex)
        tex:SetBlendMode(blendMode)
        tex:SetVertexColor(tint[1], tint[2], tint[3], tint[4])
    end

    -- hairline: 4 条细贴边，不做九宫（< 28 高度容器用）
    if preset == "hairline" then
        local thick = 2
        local top = borderFrame:CreateTexture(nil, "OVERLAY")
        top:SetTexture("Interface\\Buttons\\WHITE8X8")
        top:SetPoint("TOPLEFT", borderFrame, "TOPLEFT", 0, 0)
        top:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT", 0, 0)
        top:SetHeight(thick)
        tintTex(top)

        local bot = borderFrame:CreateTexture(nil, "OVERLAY")
        bot:SetTexture("Interface\\Buttons\\WHITE8X8")
        bot:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT", 0, 0)
        bot:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT", 0, 0)
        bot:SetHeight(thick)
        tintTex(bot)

        local left = borderFrame:CreateTexture(nil, "OVERLAY")
        left:SetTexture("Interface\\Buttons\\WHITE8X8")
        left:SetPoint("TOPLEFT", borderFrame, "TOPLEFT", 0, 0)
        left:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT", 0, 0)
        left:SetWidth(thick)
        tintTex(left)

        local right = borderFrame:CreateTexture(nil, "OVERLAY")
        right:SetTexture("Interface\\Buttons\\WHITE8X8")
        right:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT", 0, 0)
        right:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT", 0, 0)
        right:SetWidth(thick)
        tintTex(right)

        borderFrame.edges = {top=top, bot=bot, left=left, right=right}
        return borderFrame
    end

    -- 九宫格（small / medium / large）
    local s = IF_SIZES[preset] or IF_SIZES.medium

    local tl = borderFrame:CreateTexture(nil, "OVERLAY")
    tl:SetTexture(IF_ATLAS)
    tl:SetTexCoord(UV_TL[1], UV_TL[2], UV_TL[3], UV_TL[4])
    tl:SetPoint("TOPLEFT", borderFrame, "TOPLEFT", 0, 0)
    tl:SetWidth(s.tl_w); tl:SetHeight(s.tl_h)
    tintTex(tl)

    local tr = borderFrame:CreateTexture(nil, "OVERLAY")
    tr:SetTexture(IF_ATLAS)
    tr:SetTexCoord(UV_TR[1], UV_TR[2], UV_TR[3], UV_TR[4])
    tr:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT", 0, 0)
    tr:SetWidth(s.tr_w); tr:SetHeight(s.tr_h)
    tintTex(tr)

    local bl = borderFrame:CreateTexture(nil, "OVERLAY")
    bl:SetTexture(IF_ATLAS)
    bl:SetTexCoord(UV_BL[1], UV_BL[2], UV_BL[3], UV_BL[4])
    bl:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT", 0, 0)
    bl:SetWidth(s.bl_w); bl:SetHeight(s.bl_h)
    tintTex(bl)

    local br = borderFrame:CreateTexture(nil, "OVERLAY")
    br:SetTexture(IF_ATLAS)
    br:SetTexCoord(UV_BR[1], UV_BR[2], UV_BR[3], UV_BR[4])
    br:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT", 0, 0)
    br:SetWidth(s.br_w); br:SetHeight(s.br_h)
    tintTex(br)

    borderFrame.corners = {tl=tl, tr=tr, bl=bl, br=br}

    local top = borderFrame:CreateTexture(nil, "OVERLAY")
    top:SetTexture(IF_HORIZ)
    top:SetTexCoord(UV_TOP[1], UV_TOP[2], UV_TOP[3], UV_TOP[4])
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
    top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
    top:SetHeight(s.top)
    tintTex(top)

    local bot = borderFrame:CreateTexture(nil, "OVERLAY")
    bot:SetTexture(IF_HORIZ)
    bot:SetTexCoord(UV_BOT[1], UV_BOT[2], UV_BOT[3], UV_BOT[4])
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0)
    bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
    bot:SetHeight(s.bot)
    tintTex(bot)

    local left = borderFrame:CreateTexture(nil, "OVERLAY")
    left:SetTexture(IF_VERT)
    left:SetTexCoord(UV_LEFT[1], UV_LEFT[2], UV_LEFT[3], UV_LEFT[4])
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
    left:SetWidth(s.left)
    tintTex(left)

    local right = borderFrame:CreateTexture(nil, "OVERLAY")
    right:SetTexture(IF_VERT)
    right:SetTexCoord(UV_RIGHT[1], UV_RIGHT[2], UV_RIGHT[3], UV_RIGHT[4])
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
    right:SetWidth(s.right)
    tintTex(right)

    borderFrame.edges = {top=top, bot=bot, left=left, right=right}

    return borderFrame
end

-- ============================================================
-- DFUI.CreateRetailInset — retail-style 9-slice 内嵌凹陷容器
-- 视觉：marble 大理石底 + 4 边凹陷描线（uiframe_h/v）+ 4 角圆角（generalframeinsetborders）
-- 用于在 customBg (CreatePaperDollFrame) 内部某个子页面加凹陷感
-- 已验证：声望 tab (character.lua reputationInset)
--
-- Usage:
--   local inset = DFUI.CreateRetailInset(parent, {
--       anchors     = {3, -65, -6, 6},   -- TL.x, TL.y, BR.x, BR.y 相对 parent
--       followFrame = ReputationFrame,   -- 可选，跟随其 OnShow/OnHide 显示
--       -- 以下均可选（有默认值）
--       name        = "DFUI_XXX_Inset",
--       bg          = "interface\\ui-background-marble.tga",  -- TEX 内相对路径
--       edgeTop     = 5, edgeBot = 3, edgeLeft = 2, edgeRight = 2,
--       cornerSize  = 5,
--       levelOffset = 1,
--   })
--
-- 返回：inset frame，挂 .bg / .edges = {top,bot,left,right} / .corners = {tl,tr,bl,br}
-- ============================================================
local RIT_TEX = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\"

function DFUI.CreateRetailInset(parent, opts)
    opts = opts or {}
    local anchors = opts.anchors or {3, -65, -6, 6}
    local eT  = opts.edgeTop    or 3
    local eB  = opts.edgeBot    or 3
    local eL  = opts.edgeLeft   or 2
    local eR  = opts.edgeRight  or 2
    local cz  = opts.cornerSize or 5
    local lvl = opts.levelOffset or 1

    local inset = CreateFrame("Frame", opts.name, parent)
    inset:SetPoint("TOPLEFT",     parent, "TOPLEFT",     anchors[1], anchors[2])
    inset:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", anchors[3], anchors[4])
    inset:SetFrameLevel(parent:GetFrameLevel() + lvl)

    -- 背景大理石底
    local bg = inset:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(RIT_TEX .. (opts.bg or "interface\\ui-background-marble.tga"))
    bg:SetAllPoints(inset)
    inset.bg = bg

    -- 4 边纹理（来自 tradeskill 已验证 TGA）
    local TEX_H = RIT_TEX .. "panels\\df\\professions\\uiframe_h.tga"
    local TEX_V = RIT_TEX .. "panels\\df\\professions\\uiframe_v.tga"

    local top = inset:CreateTexture(nil, "ARTWORK")
    top:SetTexture(TEX_H)
    top:SetTexCoord(0.0, 1.0, 0.9063, 0.9297)
    top:SetPoint("TOPLEFT",  inset, "TOPLEFT",  0, 0)
    top:SetPoint("TOPRIGHT", inset, "TOPRIGHT", 0, 0)
    top:SetHeight(eT)

    local bot = inset:CreateTexture(nil, "ARTWORK")
    bot:SetTexture(TEX_H)
    bot:SetTexCoord(0.0, 1.0, 0.8672, 0.8906)
    bot:SetPoint("BOTTOMLEFT",  inset, "BOTTOMLEFT",  0, 0)
    bot:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", 0, 0)
    bot:SetHeight(eB)

    local left = inset:CreateTexture(nil, "ARTWORK")
    left:SetTexture(TEX_V)
    left:SetTexCoord(0.4844, 0.5313, 0.0, 1.0)
    left:SetPoint("TOPLEFT",    inset, "TOPLEFT",    0, 0)
    left:SetPoint("BOTTOMLEFT", inset, "BOTTOMLEFT", 0, 0)
    left:SetWidth(eL)

    -- 右边复用左 UV 做 X 反转（保证左右镜像深浅一致）
    local right = inset:CreateTexture(nil, "ARTWORK")
    right:SetTexture(TEX_V)
    right:SetTexCoord(0.5313, 0.4844, 0.0, 1.0)
    right:SetPoint("TOPRIGHT",    inset, "TOPRIGHT",    0, 0)
    right:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(eR)

    inset.edges = {top=top, bot=bot, left=left, right=right}

    -- 可选上下内阴影渐变（凹陷立体感）；默认关闭，不影响现有调用
    if opts.shade then
        local sa = type(opts.shade) == "table" and opts.shade or {}
        local aTop, aBot = sa.top or 0.55, sa.bot or 0.55
        local shH = sa.height or 40
        local shT = inset:CreateTexture(nil, "ARTWORK")
        shT:SetTexture("Interface\\Buttons\\WHITE8X8")
        shT:SetGradientAlpha("VERTICAL", 0,0,0,aTop, 0,0,0,0)
        shT:SetPoint("TOPLEFT",  inset, "TOPLEFT",  eL, -eT)
        shT:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -eR, -eT)
        shT:SetHeight(shH)
        local shB = inset:CreateTexture(nil, "ARTWORK")
        shB:SetTexture("Interface\\Buttons\\WHITE8X8")
        shB:SetGradientAlpha("VERTICAL", 0,0,0,0, 0,0,0,aBot)
        shB:SetPoint("BOTTOMLEFT",  inset, "BOTTOMLEFT",  eL, eB)
        shB:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -eR, eB)
        shB:SetHeight(shH)
        inset.shade = {top=shT, bot=shB}
    end

    -- 4 角（generalframeinsetborders atlas）
    local TEX_CORNER = RIT_TEX .. "interface\\generalframeinsetborders.tga"
    local function makeCorner(point, l, r, t, b)
        local c = inset:CreateTexture(nil, "OVERLAY")
        c:SetTexture(TEX_CORNER)
        c:SetTexCoord(l, r, t, b)
        c:SetPoint(point, inset, point, 0, 0)
        c:SetWidth(cz); c:SetHeight(cz)
        return c
    end

    inset.corners = {
        tl = makeCorner("TOPLEFT",     0.703125, 0.828125, 0.03125, 0.28125),
        tr = makeCorner("TOPRIGHT",    0.859375, 0.984375, 0.03125, 0.28125),
        bl = makeCorner("BOTTOMLEFT",  0.328125, 0.453125, 0.6875,  0.9375),
        br = makeCorner("BOTTOMRIGHT", 0.515625, 0.640625, 0.6875,  0.9375),
    }

    inset:Hide()

    -- 跟随显示状态（可选）—— 单个 frame 用 followFrame，多个互斥 frame 用 followFrames {f1, f2,...}
    local follows = opts.followFrames or (opts.followFrame and {opts.followFrame})
    if follows then
        local function checkVisible()
            for _, f in ipairs(follows) do
                if f and f:IsVisible() then inset:Show(); return end
            end
            inset:Hide()
        end
        checkVisible()
        for _, f in ipairs(follows) do
            if f then
                HookScript(f, "OnShow", checkVisible)
                HookScript(f, "OnHide", checkVisible)
            end
        end
    end

    return inset
end

-- ============================================================
-- DFUI.CreateRetailScrollbar — retail-style 滚动条套件
-- 套装：箭头 3 态 + 滑轨 3-slice + 滑块 3-slice
-- 素材：minimal-scrollbar-* atlas (retail) + ui-hud-actionbar 箭头
-- 已验证：tradeskill.lua:198+ CreateMinimalScrollbar 的抽离版
--
-- Usage:
--   local sb = DFUI.CreateRetailScrollbar(parent, listFrame, {
--       onScrollDelta = function(d) ... end,  -- 上下箭头 -1/+1
--       onScrollAbs   = function(r) ... end,  -- 拖动 thumb 0..1
--       width         = 18,                   -- 可选
--       xOffset       = 18,                   -- 可选，sb 锚到 listFrame 右外侧偏移
--   })
--   sb.UpdateThumb(scrollOffset, maxOffset, visibleRows, totalRows)  -- 点调用（非 method，无 self）
-- ============================================================
local RSB_TEX = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\interface\\buttons\\"
-- ui-scrollbar 整图系列：每部件一张独立 TGA，零 UV 切片（根治 atlas 切片显示不全）
local RSB_UP_UP       = RSB_TEX .. "ui-scrollbar-scrollupbutton-up"
local RSB_UP_DOWN     = RSB_TEX .. "ui-scrollbar-scrollupbutton-down"
local RSB_UP_HILIGHT  = RSB_TEX .. "ui-scrollbar-scrollupbutton-highlight"
local RSB_UP_DISABLED = RSB_TEX .. "ui-scrollbar-scrollupbutton-disabled"
local RSB_DN_UP       = RSB_TEX .. "ui-scrollbar-scrolldownbutton-up"
local RSB_DN_DOWN     = RSB_TEX .. "ui-scrollbar-scrolldownbutton-down"
local RSB_DN_HILIGHT  = RSB_TEX .. "ui-scrollbar-scrolldownbutton-highlight"
local RSB_DN_DISABLED = RSB_TEX .. "ui-scrollbar-scrolldownbutton-disabled"
local RSB_KNOB        = RSB_TEX .. "ui-scrollbar-knob"            -- 32×32 滑块
local RSB_TRACK_BG    = RSB_TEX .. "ui-sliderbar-background"      -- 8×8 轨道底（拉伸）

function DFUI.CreateRetailScrollbar(parent, listFrame, opts)
    opts = opts or {}
    local tex       = opts.textures               -- 可选 {up,down,thumb,trackColor}：提供则走 minimal 整图皮肤
    local scale     = opts.scale or 1
    local width     = (opts.width or 18) * scale  -- sb 宽
    local arrowH    = (opts.arrowH or 16) * scale -- 箭头按钮高
    local trackW    = 12 * scale                  -- 轨道/滑块宽
    local inset     = 3 * scale                   -- 轨道左右内缩
    local gap       = (opts.gap or 2) * scale     -- 箭头与轨道间距（opts.gap 可调；越大滑块越短、离箭头越远）
    local thumbMinH = 30 * scale                  -- 滑块最小高
    local xOff      = opts.xOffset or width        -- 默认贴 listFrame 右外侧
    local onDelta = opts.onScrollDelta or function() end
    local onAbs   = opts.onScrollAbs   or function() end

    local sb = CreateFrame("Frame", nil, parent)
    sb:SetWidth(width)
    -- topInset/botInset：sb 上下端各向内缩，让箭头对齐 listFrame 内容区(避开列头/底部留白)；固定 px 不随 scale
    sb:SetPoint("TOPRIGHT",    listFrame, "TOPRIGHT",    xOff, -(opts.topInset or 0))
    sb:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", xOff,  (opts.botInset or 0))
    sb:SetFrameLevel(parent:GetFrameLevel() + 5)

    -- 箭头按钮：Button 原生纹理（normal/pushed/highlight/disabled 各一张整图，highlight 自动叠加）
    -- yPad: 上箭头正值往上、下箭头负值往下，微调箭头与轨道间距
    local function makeArrowBtn(point, yPad, normalT, pushedT, hiT, disT)
        local btn = CreateFrame("Button", nil, sb)
        btn:SetWidth(width); btn:SetHeight(arrowH)
        btn:SetPoint(point, sb, point, 0, yPad)
        btn:SetNormalTexture(normalT)
        btn:SetPushedTexture(pushedT)
        btn:SetHighlightTexture(hiT)
        if disT then btn:SetDisabledTexture(disT) end
        return btn
    end
    local topPad = (opts.arrowTopPad or 0) * scale
    local botPad = (opts.arrowBotPad or 0) * scale
    local upBtn, dnBtn
    if tex then
        -- minimal 整图皮肤：单张箭头整图，normal/pushed/highlight 共用（highlight 默认 ADD 叠亮作 hover），禁用靠 alpha
        upBtn = makeArrowBtn("TOP",     topPad, tex.up,   tex.up,   tex.up,   nil)
        dnBtn = makeArrowBtn("BOTTOM", -botPad, tex.down, tex.down, tex.down, nil)
    else
        upBtn = makeArrowBtn("TOP",     topPad, RSB_UP_UP, RSB_UP_DOWN, RSB_UP_HILIGHT, RSB_UP_DISABLED)
        dnBtn = makeArrowBtn("BOTTOM", -botPad, RSB_DN_UP, RSB_DN_DOWN, RSB_DN_HILIGHT, RSB_DN_DISABLED)
    end
    upBtn:SetScript("OnClick", function() onDelta(-1) end)
    dnBtn:SetScript("OnClick", function() onDelta(1)  end)

    -- track 容器
    local track = CreateFrame("Frame", nil, sb)
    track:SetWidth(trackW)   -- 固定细宽；不锚 sb LEFT/RIGHT(否则会跟 sb 变宽)，靠 TOP/BOTTOM 中点锚水平居中
    track:SetPoint("TOP",    upBtn, "BOTTOM", 0, -gap)
    track:SetPoint("BOTTOM", dnBtn, "TOP",    0,  gap)

    -- track 背景：retail 3-slice（上端盖+中段拉伸+下端盖，各独立小整图、零切片）/ WHITE8X8 染色 / 默认整图
    if tex and tex.trackTop and tex.trackBot and tex.trackMid then
        local tcapH = (tex.trackCapH or 6) * scale
        local trTop = track:CreateTexture(nil, "BACKGROUND")
        trTop:SetTexture(tex.trackTop); trTop:SetHeight(tcapH)
        trTop:SetPoint("TOPLEFT",  track, "TOPLEFT",  0, 0)
        trTop:SetPoint("TOPRIGHT", track, "TOPRIGHT", 0, 0)
        local trBot = track:CreateTexture(nil, "BACKGROUND")
        trBot:SetTexture(tex.trackBot); trBot:SetHeight(tcapH)
        trBot:SetPoint("BOTTOMLEFT",  track, "BOTTOMLEFT",  0, 0)
        trBot:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", 0, 0)
        local trMid = track:CreateTexture(nil, "BACKGROUND")
        trMid:SetTexture(tex.trackMid)
        trMid:SetPoint("TOPLEFT",     trTop, "BOTTOMLEFT",  0, 0)
        trMid:SetPoint("BOTTOMRIGHT", trBot, "TOPRIGHT",    0, 0)
    else
        local trackBg = track:CreateTexture(nil, "BACKGROUND")
        -- minimal 用 WHITE8X8 才能被 trackColor 染色（sliderbar-background 是纯黑，vertexColor 乘黑恒为黑→不可见）
        trackBg:SetTexture((tex and "Interface\\Buttons\\WHITE8X8") or RSB_TRACK_BG)
        trackBg:SetAllPoints(track)
        if tex and tex.trackColor then
            local c = tex.trackColor
            trackBg:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        else
            trackBg:SetVertexColor(0.6, 0.6, 0.6, 0.9)
        end
    end

    -- thumb：3-slice（上圆头+中段拉伸+下圆头，各独立小整图、零切片）或单张 knob 整图拉伸
    local thumb = CreateFrame("Frame", nil, track)
    thumb:EnableMouse(true)
    thumb:SetWidth(trackW)
    thumb:SetHeight(thumbMinH)
    thumb:SetPoint("TOP", track, "TOP", 0, 0)
    if tex and tex.thumbTop and tex.thumbBot then
        local capH = (tex.thumbCapH or 7) * scale
        local tTop = thumb:CreateTexture(nil, "ARTWORK")
        tTop:SetTexture(tex.thumbTop); tTop:SetHeight(capH)
        tTop:SetPoint("TOPLEFT",  thumb, "TOPLEFT",  0, 0)
        tTop:SetPoint("TOPRIGHT", thumb, "TOPRIGHT", 0, 0)
        local tBot = thumb:CreateTexture(nil, "ARTWORK")
        tBot:SetTexture(tex.thumbBot); tBot:SetHeight(capH)
        tBot:SetPoint("BOTTOMLEFT",  thumb, "BOTTOMLEFT",  0, 0)
        tBot:SetPoint("BOTTOMRIGHT", thumb, "BOTTOMRIGHT", 0, 0)
        local tMid = thumb:CreateTexture(nil, "ARTWORK")
        tMid:SetTexture(tex.thumb)
        tMid:SetPoint("TOPLEFT",     tTop, "BOTTOMLEFT",  0, 0)
        tMid:SetPoint("BOTTOMRIGHT", tBot, "TOPRIGHT",    0, 0)
    else
        local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
        thumbTex:SetTexture((tex and tex.thumb) or RSB_KNOB)
        thumbTex:SetAllPoints(thumb)
    end

    -- 拖动逻辑：OnMouseDown 启动 OnUpdate 跟随鼠标 y, OnMouseUp 停止
    thumb.dragging = false
    thumb:SetScript("OnMouseDown", function() thumb.dragging = true  end)
    thumb:SetScript("OnMouseUp",   function() thumb.dragging = false end)
    thumb:SetScript("OnUpdate", function()
        if not thumb.dragging then return end
        -- 必须用 UIParent scale：GetCursorPosition 的物理坐标对应根缩放，
        -- 而 thumb:GetEffectiveScale() 含 panel SetScale(0.85)→坐标错位、拖不到底("拉到一半就停")
        local uiScale = UIParent:GetEffectiveScale()
        if uiScale <= 0 then return end
        local _, cy = GetCursorPosition()
        cy = cy / uiScale                                       -- 物理像素 → UIParent UI 坐标(与 GetTop 同系)
        local trackTop = track:GetTop()
        local trackBot = track:GetBottom()
        if not trackTop or not trackBot then return end
        local maxY = (trackTop - trackBot) - thumb:GetHeight()  -- 全程 UIParent UI，不再乘 panel scale
        if maxY <= 0 then return end
        local ratio = (trackTop - cy) / maxY
        if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
        onAbs(ratio)
    end)

    sb.thumb = thumb
    sb.track = track
    sb.lastMaxOffset = 0

    -- 由滚动逻辑调用：同步 thumb 几何 + 到顶/底禁用对应箭头（disabled 整图）
    sb.UpdateThumb = function(scrollOff, maxOff, visRows, totalRows)
        scrollOff = scrollOff or 0
        maxOff = maxOff or 0
        sb.lastMaxOffset = maxOff
        if tex then
            -- minimal 皮肤无 disabled 整图，到顶/底用 alpha 表示禁用
            upBtn:SetAlpha((scrollOff <= 0) and 0.35 or 1)
            dnBtn:SetAlpha((scrollOff >= maxOff) and 0.35 or 1)
        else
            if scrollOff <= 0      then upBtn:Disable() else upBtn:Enable() end
            if scrollOff >= maxOff  then dnBtn:Disable() else dnBtn:Enable() end
        end
        local tT, tB = track:GetTop(), track:GetBottom()
        if not tT or not tB then return end
        local trackH = tT - tB   -- 双锚 GetHeight 在 1.12 常返错值，用 GetTop-GetBottom(与拖动一致)否则 thumb 拖不到底
        if trackH <= 0 then return end
        local thumbH = math.max(thumbMinH, trackH * visRows / math.max(visRows, totalRows))
        if thumbH > trackH then thumbH = trackH end
        thumb:SetHeight(thumbH)
        local thumbMaxY = trackH - thumbH
        local thumbY = (maxOff > 0) and (thumbMaxY * scrollOff / maxOff) or 0
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -thumbY)
    end

    return sb
end

-- DF minimal 风滚动条整图素材集 (media\tex\interface\buttons\minimal-sb-*，全 retail 精确坐标抠图)
local MINIMAL_SB_TEXTURES = {
    up       = RSB_TEX .. "minimal-sb-arrow-up",
    down     = RSB_TEX .. "minimal-sb-arrow-down",
    thumb    = RSB_TEX .. "minimal-sb-thumb",
    thumbTop = RSB_TEX .. "minimal-sb-thumb-top",
    thumbBot = RSB_TEX .. "minimal-sb-thumb-bot",
    trackTop = RSB_TEX .. "minimal-sb-track-top",
    trackBot = RSB_TEX .. "minimal-sb-track-bot",
    trackMid = RSB_TEX .. "minimal-sb-track-mid",
}
-- DFUI.CreateMinimalScrollbar — DF minimal 风滚动条(整图皮肤预设)，薄封装 CreateRetailScrollbar
-- 其他面板复用一行: DFUI.CreateMinimalScrollbar(parent, listFrame, { onScrollDelta=fn, onScrollAbs=fn })
--   onScrollDelta(±1): 点上/下箭头   onScrollAbs(0..1): 拖 thumb
--   可选覆盖: width(默22)/arrowH(默12)/arrowTopPad(默5)/arrowBotPad(默5)/scale
--   返回 sb；列表刷新末尾点调用 sb.UpdateThumb(scrollOff, maxOff, visRows, totalRows)
function DFUI.CreateMinimalScrollbar(parent, listFrame, opts)
    opts = opts or {}
    if opts.textures    == nil then opts.textures    = MINIMAL_SB_TEXTURES end
    if opts.width       == nil then opts.width       = 22 end
    if opts.arrowH      == nil then opts.arrowH      = 12 end
    if opts.arrowTopPad == nil then opts.arrowTopPad = 5  end
    if opts.arrowBotPad == nil then opts.arrowBotPad = 5  end
    return DFUI.CreateRetailScrollbar(parent, listFrame, opts)
end

-- 获取单位真实血量
-- 1.12 原生 UnitHealth/UnitHealthMax 行为:
--   - 自己/宠物/小队/团队 token → 真实值
--   - 怪物/敌玩/非小队友玩 → 百分比 (cur 0-100, max=100)
--   - 不可攻击友善 NPC(商人/任务) → 无数据 (cur=0, max=0)
-- SuperWoW 1.5 不接管这两个 API
--
-- 返回 cur, max, status:
--   "real"    — 真实值,可显示绝对数
--   "percent" — 仅百分比可信,cur=0-100 max=100,UI 应显示百分号
--   "none"    — 无数据,UI 应隐藏血量
local function ResolveToTrueUnit(unit)
    if not UnitExists(unit) then return nil end
    if UnitIsUnit(unit, "player") then return "player" end
    if UnitIsUnit(unit, "pet") then return "pet" end
    for i = 1, 4 do
        if UnitExists("party" .. i) and UnitIsUnit(unit, "party" .. i) then
            return "party" .. i
        end
    end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            if UnitExists("raid" .. i) and UnitIsUnit(unit, "raid" .. i) then
                return "raid" .. i
            end
        end
    end
    return nil
end

function GetUnitRealHealth(unit)
    unit = unit or "target"

    -- 1. 反向映射到自己/宠物/队友/团友 token → 原生真值
    local trueUnit = ResolveToTrueUnit(unit)
    if trueUnit then
        return UnitHealth(trueUnit), UnitHealthMax(trueUnit), "real"
    end

    -- 2. 原生数据
    local rawCur = UnitHealth(unit)
    local rawMax = UnitHealthMax(unit)
    if rawMax == 0 then
        return 0, 0, "none"
    end

    -- 3. max=100 (典型怪/友方玩家百分比模式) → 走 DFUI.libhealth 估算
    if rawMax == 100 then
        if DFUI and DFUI.libhealth and DFUI.libhealth.GetUnitHealth then
            local cur, max, found = DFUI.libhealth:GetUnitHealth(unit)
            if found then
                return cur, max, "real"
            end
        end
        return rawCur, rawMax, "percent"
    end

    -- 4. max≠100 且≠0:别的插件接管了 API 返回真值,直接信任
    return rawCur, rawMax, "real"
end


-- ============================================================
-- DFUI.SocialRowColors — DF UI 设计规范配色（与 plans/9-10 一致）
-- ============================================================
-- 列表 row 字体配色（与 vanilla FriendsList + 项目其他面板对齐）
-- 注意：之前"主金/次金/暗金"是 DF 面板背景羊皮纸配色，不是列表字体规范
-- vanilla FriendsList 字体：name = 白/职业色，info = 灰；与项目内其他 panel 默认色一致
DFUI.SocialRowColors = {
    main    = {1.00, 1.00, 1.00},   -- 白色（name 在线时被职业色覆盖，离线 fallback 白）
    next_   = {0.60, 0.60, 0.60},   -- 灰（FRIENDS_GRAY_COLOR 风格：info/zone/lc 次要文字）
    dim     = {0.50, 0.50, 0.50},   -- 离线灰
    online  = {0.20, 0.85, 0.20},   -- status 在线绿
    offline = {0.45, 0.45, 0.45},   -- status 离线灰
    afk     = {1.00, 0.82, 0.00},   -- status AFK 黄
    dnd     = {0.85, 0.20, 0.20},   -- status DND 红
}

-- ============================================================
-- DFUI.CreateSocialRow(parent, opts) — DF retail 风格列表 row 工厂
-- ============================================================
-- 用途：Friend / Who / Guild 列表共用的单行 row 工厂
-- 设计：column-driven，左右双向链锚，hover/selected 内置
--
-- opts = {
--     name        = "DFUI_FriendRow1",       -- 可选全局名
--     frameLevel  = sf:GetFrameLevel() + 5,  -- 可选
--     columns = {
--         { name="dot",    type="texture",    width=9,  height=9,
--           anchor="LEFT", offsetX=4,
--           texture="Interface\\Buttons\\WHITE8X8" },
--         { name="title",  type="fontstring", width=100,
--           font="GameFontNormal",      color="main",
--           anchor="LEFT", offsetX=5 },
--         { name="lc",     type="fontstring", width=80,
--           font="GameFontNormalSmall", color="next_",
--           anchor="LEFT", offsetX=4 },
--         { name="status", type="fontstring", width=40,
--           font="GameFontNormalSmall", color="next_",
--           anchor="RIGHT", offsetX=-6 },
--         { name="zone",   type="fontstring", width=80,
--           font="GameFontNormalSmall", color="next_",
--           anchor="RIGHT", offsetX=-8 },
--     },
--     onLeftClick  = function(row) ... end,
--     onRightClick = function(row) ... end,
-- }
--
-- 返回：row Frame，含 row.dot / row.title / row.lc / ... 子元素
-- row:SetSelected(true/false) 切换选中视觉
-- ============================================================
function DFUI.CreateSocialRow(parent, opts)
    opts = opts or {}
    local row = CreateFrame("Button", opts.name, parent)
    row:EnableMouse(true)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if opts.frameLevel then row:SetFrameLevel(opts.frameLevel) end

    -- 滚轮事件：直接改 sf 的 VerticalScroll + 调 opts.onWheel 手动触发列表 *_Update
    -- 不调 vanilla OnMouseWheel handler（vanilla 1.12 ScrollFrameTemplate_OnMouseWheel 访问
    -- self.scrollBar 但 FauxScrollFrame 没设此字段 → nil 报错）
    -- 不依赖 sb:SetValue → OnValueChanged → OnVerticalScroll → updateFunction 链路（vanilla
    -- 中间 handler 可能 broken），直接 SetVerticalScroll + 手动调对应 *_Update
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function()
        local p = row:GetParent()
        -- parent 是 vanilla ScrollFrame（friend/guild）：走 SetVerticalScroll；
        -- parent 是普通 Frame（who 全自制，offset 自管）：跳过滚动逻辑，仅靠 onWheel 翻页
        if p and p.SetVerticalScroll then
            local cur = p:GetVerticalScroll() or 0
            local step = 18  -- 一行高度（与 FIXED_ROW_H 一致）
            local newScroll = cur - arg1 * step  -- arg1=1 上滚（scroll 减）；arg1=-1 下滚（加）
            if newScroll < 0 then newScroll = 0 end
            -- 限制 max：从 ScrollBar 拿 maxValues
            local pname = p.GetName and p:GetName()
            local sb = pname and getglobal(pname.."ScrollBar")
            if sb and sb.GetMinMaxValues then
                local _, maxV = sb:GetMinMaxValues()
                if maxV and newScroll > maxV then newScroll = maxV end
            end
            p:SetVerticalScroll(newScroll)
            -- 同步 scrollbar value（让 scrollbar 视觉跟随，虽然我们 nuke 了视觉但其他逻辑可能依赖）
            if sb and sb.SetValue then sb:SetValue(newScroll) end
        end
        -- 调用 opts.onWheel：friend/guild 触发 *_Update；who 自管 offset 翻页
        if opts.onWheel then opts.onWheel() end
    end)

    -- hover highlight（金色 ADD）
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    hl:SetAllPoints(row)
    hl:SetAlpha(0.35)
    hl:SetBlendMode("ADD")

    -- selected（蓝半透明 ADD，初始 Hide）
    local sel = row:CreateTexture(nil, "BACKGROUND")
    sel:SetTexture("Interface\\Buttons\\WHITE8X8")
    sel:SetAllPoints(row)
    sel:SetVertexColor(0.30, 0.50, 1.00, 0.30)
    sel:SetBlendMode("ADD")
    sel:Hide()
    row.sel = sel

    -- 创建列：LEFT 链从 row.LEFT 起，RIGHT 链从 row.RIGHT 起反向
    local prevLeft, prevRight = nil, nil
    local cols = opts.columns or {}
    for i = 1, table.getn(cols) do
        local col = cols[i]
        local element
        if col.type == "texture" then
            element = row:CreateTexture(nil, col.drawLayer or "OVERLAY")
            element:SetTexture(col.texture or "Interface\\Buttons\\WHITE8X8")
            if col.width  then element:SetWidth(col.width)  end
            if col.height then element:SetHeight(col.height) end
        else
            element = row:CreateFontString(nil, "OVERLAY", col.font or "GameFontNormalSmall")
            if col.width then element:SetWidth(col.width) end
            element:SetJustifyH(col.justifyH or (col.anchor == "RIGHT" and "RIGHT" or "LEFT"))
            if element.SetNonSpaceWrap then element:SetNonSpaceWrap(false) end
            local cname = col.color or "main"
            local c = DFUI.SocialRowColors[cname] or DFUI.SocialRowColors.main
            element:SetTextColor(c[1], c[2], c[3])
        end

        local anchor = col.anchor or "LEFT"
        if anchor == "LEFT" then
            if prevLeft then
                element:SetPoint("LEFT", prevLeft, "RIGHT", col.offsetX or 4, col.offsetY or 0)
            else
                element:SetPoint("LEFT", row, "LEFT", col.offsetX or 4, col.offsetY or 0)
            end
            prevLeft = element
        else  -- RIGHT
            if prevRight then
                element:SetPoint("RIGHT", prevRight, "LEFT", col.offsetX or -4, col.offsetY or 0)
            else
                element:SetPoint("RIGHT", row, "RIGHT", col.offsetX or -6, col.offsetY or 0)
            end
            prevRight = element
        end
        row[col.name] = element
    end

    -- OnClick 分发左/右键 + 自实现双击检测（vanilla 1.12 Button OnDoubleClick 不一定触发，
    -- 用 GetTime 记录上次 LeftButton 时间，<0.4s 内第二次视为双击）
    local lastLeftClick = 0
    row:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            if opts.onRightClick then opts.onRightClick(row) end
        else
            local now = GetTime and GetTime() or 0
            local dt = now - lastLeftClick
            lastLeftClick = now
            if dt > 0 and dt < 0.4 and opts.onDoubleClick then
                opts.onDoubleClick(row)
                lastLeftClick = 0  -- 重置避免三击连发
            else
                if opts.onLeftClick then opts.onLeftClick(row) end
            end
        end
    end)

    function row:SetSelected(on)
        if on then self.sel:Show() else self.sel:Hide() end
    end

    return row
end

-- ============================================================
-- DFUI.CreateActionButton — DF 风格文字操作按钮（红金属 9-slice + 金色 OUTLINE 文字）
-- 抽自 tradeskill.lua CreateSimpleButton，素材复用 professions btn_*.tga（128×32 POT）
-- 增 onClick 参数 + :SetEnabledDF(bool) 禁用态（变暗 + 屏蔽 hover/点击）
-- 用法：local b = DFUI.CreateActionButton(parent, width, "文字", function(btn) ... end)
-- ============================================================
local AB_TEX  = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\panels\\df\\professions\\"
local AB_UP   = AB_TEX .. "btn_up.tga"
local AB_DOWN = AB_TEX .. "btn_down.tga"
local AB_HL   = AB_TEX .. "btn_hl.tga"
local AB_TC_L = {2/128,  14/128, 2/32, 22/32}
local AB_TC_M = {14/128, 64/128, 2/32, 22/32}
local AB_TC_R = {64/128, 78/128, 2/32, 22/32}  -- 右边界 76→78：76/128 卡在像素76左缘会切掉最右边框线，抠到 78 含全右边框

function DFUI.CreateActionButton(parent, width, text, onClick, height)
    local btn = CreateFrame("Button", nil, parent)
    local h = height or 24
    btn:SetWidth(width)
    btn:SetHeight(h)
    btn:SetFrameLevel(parent:GetFrameLevel() + 5)
    btn:RegisterForClicks("LeftButtonUp")

    local function makeSlice(layer, tex, blend)
        local L = btn:CreateTexture(nil, layer)
        L:SetTexture(tex); L:SetTexCoord(AB_TC_L[1], AB_TC_L[2], AB_TC_L[3], AB_TC_L[4])
        L:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        L:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0); L:SetWidth(12)
        if blend then L:SetBlendMode(blend) end
        local R = btn:CreateTexture(nil, layer)
        R:SetTexture(tex); R:SetTexCoord(AB_TC_R[1], AB_TC_R[2], AB_TC_R[3], AB_TC_R[4])
        R:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        R:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0); R:SetWidth(12)
        if blend then R:SetBlendMode(blend) end
        local M = btn:CreateTexture(nil, layer)
        M:SetTexture(tex); M:SetTexCoord(AB_TC_M[1], AB_TC_M[2], AB_TC_M[3], AB_TC_M[4])
        M:SetPoint("TOPLEFT", L, "TOPRIGHT", 0, 0)
        M:SetPoint("BOTTOMRIGHT", R, "BOTTOMLEFT", 0, 0)
        if blend then M:SetBlendMode(blend) end
        return {L, M, R}
    end

    local normal = makeSlice("BACKGROUND", AB_UP)
    local hl     = makeSlice("HIGHLIGHT", AB_HL, "ADD")
    btn:SetScript("OnMouseDown", function()
        if btn.dfDisabled then return end
        for _, t in ipairs(normal) do t:SetTexture(AB_DOWN) end
    end)
    btn:SetScript("OnMouseUp", function()
        for _, t in ipairs(normal) do t:SetTexture(AB_UP) end
    end)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", math.floor(h / 24 * 16 + 0.5), "OUTLINE")
    label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    label:SetText(text)
    label:SetTextColor(1.00, 0.82, 0.00)
    btn.label = label

    if onClick then
        btn:SetScript("OnClick", function()
            if btn.dfDisabled then return end
            onClick(btn)
        end)
    end

    -- 禁用态：变暗 + 屏蔽 hover 高光/点击（不覆盖 vanilla Enable/Disable，避免冲突）
    function btn:SetEnabledDF(on)
        self.dfDisabled = not on
        local nv = on and 1 or 0.4
        for _, t in ipairs(normal) do t:SetVertexColor(nv, nv, nv) end
        for _, t in ipairs(hl) do t:SetAlpha(on and 1 or 0) end
        if on then self.label:SetTextColor(1.00, 0.82, 0.00)
        else self.label:SetTextColor(0.55, 0.50, 0.35) end
    end

    return btn
end

-- ============================================================
-- DFUI.TruncateToWidth(text, maxW, font) — 像素级 UTF-8 截断 + 省略号
-- ============================================================
-- 1.12 无原生省略号截断。手动按 UTF-8 字符边界步进，用隐藏 FontString 测宽
-- （复用本项目已验证的 FontString:GetStringWidth，参考 tradeskill.lua / loot.lua）。
-- text 渲染宽 ≤ maxW → 原样返回；否则截到「再加一字符就超 maxW−省略号宽」并接 …
-- 客户端中文为 UTF-8（汉字 3 字节，lead byte 0xE0-0xEF）；font 缺省与 social row 一致。
local _dfuiMeasureFS = {}   -- 按 font 缓存测量 FontString（不同字体/字号宽度不同）
local function dfuiGetMeasureFS(font)
    font = font or "GameFontNormalSmall"
    local fs = _dfuiMeasureFS[font]
    if not fs then
        fs = UIParent:CreateFontString(nil, "ARTWORK", font)
        fs:Hide()
        _dfuiMeasureFS[font] = fs
    end
    return fs
end

local truncCache = {}
function DFUI.TruncateToWidth(text, maxW, font)
    if not text or text == "" or not maxW or maxW <= 0 then return text or "" end
    -- 结果缓存：切 tab / 列表刷新会反复对同文本+同宽截断，命中缓存可跳过整个逐字符测宽循环
    local key = text.."\1"..maxW.."\1"..(font or "")
    local cached = truncCache[key]
    if cached ~= nil then return cached end
    local fs = dfuiGetMeasureFS(font)
    fs:SetText(text)
    if (fs:GetStringWidth() or 0) <= maxW then truncCache[key] = text; return text end
    -- 省略号：优先单字符 …（U+2026），字体缺字形(测宽 0)则退回三点 ...
    local ell = "…"
    fs:SetText(ell)
    local ellW = fs:GetStringWidth() or 0
    if ellW <= 0 then ell = "..."; fs:SetText(ell); ellW = fs:GetStringWidth() or 0 end
    local budget = maxW - ellW
    if budget <= 0 then truncCache[key] = ell; return ell end
    local out, i, n = "", 1, string.len(text)
    while i <= n do
        local b = string.byte(text, i)
        local clen = 1                          -- UTF-8 lead byte → 字符字节数
        if     b >= 240 then clen = 4
        elseif b >= 224 then clen = 3           -- 中文 BMP
        elseif b >= 192 then clen = 2 end
        local ch = string.sub(text, i, i + clen - 1)
        fs:SetText(out .. ch)
        if (fs:GetStringWidth() or 0) > budget then break end
        out = out .. ch
        i = i + clen
    end
    local result = (out == "") and ell or (out .. ell)
    truncCache[key] = result
    return result
end

-- DFUI.MeasureWidth(text, font) — 测文本渲染像素宽（颜色码 |cff..|r 不计宽）。
-- 复用 TruncateToWidth 的测量 FontString。用于给 status 后缀预留宽度等。
function DFUI.MeasureWidth(text, font)
    if not text or text == "" then return 0 end
    local fs = dfuiGetMeasureFS(font)
    fs:SetText(text)
    return fs:GetStringWidth() or 0
end

-- ============================================================
-- DFUI.ApplyDiamondMetalBorder — DF 通用九宫格"金属边框 diamond metal"
-- 往现有 frame 贴一圈 DF 金属外框（4 角钻石 + 4 边金属条），对标 ApplyInnerFrame。
-- 素材：8 块原生 128×128 整图（media\tex\diamondmetal\frame_*），零大-atlas 切片。
-- 几何要点（已实测 alpha 包围盒，源自 uiframediamondmetal2x / vertical2x）：
--   · 角瓦片：L 形金属 + 钻石(尖伸到 row7/col6)，绘制为 cornerSize×cornerSize。
--   · 边瓦片：金属条厚 34/128、距外侧留 16/128 边距 → 边的"横轴"必须 = cornerSize，
--     仅拉伸长轴；金属条厚度内禀(随 cornerSize 等比)，方能与角无缝对齐。
--   · 默认 overhang = cornerSize/8 (=16/128)：金属外沿正好齐 frame 边界、钻石外凸(还原 DF)。
-- opts:
--   cornerSize (默认 64)      4 角定尺(正方)，控整体大小；素材 128 的 0.5x
--   edgeThickness (默认 cz)   边横轴尺寸；为无缝对齐应保持 = cornerSize，仅高级覆盖
--   tint (默认 {1,1,1,1})     染色；diamond metal 自带金属色默认不染
--   blendMode (默认 "BLEND")  深底提亮传 "ADD"(vertexColor 钳 1，提亮靠 ADD 不靠 tint>1)
--   drawLayer (默认 "OVERLAY")
--   levelOffset (默认 5)      borderFrame 层级 = frame 层级 + 此值
--   overhang (默认 cz/8)      角向 frame 外凸像素；边随角走，传 0 即齐平内贴
--   showBackground (默认关)   true 时给 frame 加深色底(挂 frame 背景层，不盖 border)
--   bgColor (默认暗蓝)        showBackground 的底色 {r,g,b,a}
--   name                      可选 borderFrame 全局名
-- 返回：borderFrame 挂 .corners={tl,tr,bl,br} / .edges={top,bot,left,right} / .bg(可选)
-- ============================================================
local DM_TEX = RIT_TEX .. "diamondmetal\\"

function DFUI.ApplyDiamondMetalBorder(frame, opts)
    opts = opts or {}
    local cz    = opts.cornerSize    or 64
    local et    = opts.edgeThickness or cz
    local tint  = opts.tint          or {1, 1, 1, 1}
    local blend = opts.blendMode     or "BLEND"
    local layer = opts.drawLayer     or "OVERLAY"
    local lvl   = opts.levelOffset   or 5
    local ov    = opts.overhang
    if ov == nil then ov = cz / 8 end
    local bgColor = opts.bgColor or {0.06, 0.06, 0.09, 0.90}

    local bf = CreateFrame("Frame", opts.name, frame)
    bf:SetAllPoints(frame)
    bf:SetFrameLevel(frame:GetFrameLevel() + lvl)

    if opts.showBackground then
        local bg = frame:CreateTexture(nil, "BACKGROUND")   -- 挂 frame 背景层，居 children 之下
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(frame)
        bg:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
        bf.bg = bg
    end

    local function newTex(file)
        local t = bf:CreateTexture(nil, layer)
        t:SetTexture(DM_TEX .. file)
        t:SetTexCoord(0, 1, 0, 1)        -- 原生整图整张贴(非天赋版补 POT 的 UV 切片)
        t:SetBlendMode(blend)
        t:SetVertexColor(tint[1], tint[2], tint[3], tint[4] or 1)
        return t
    end

    -- 4 角（带 overhang 外凸；各自定尺 cz×cz）
    local tl = newTex("frame_corner_tl"); tl:SetWidth(cz); tl:SetHeight(cz); tl:SetPoint("TOPLEFT",     bf, "TOPLEFT",     -ov,  ov)
    local tr = newTex("frame_corner_tr"); tr:SetWidth(cz); tr:SetHeight(cz); tr:SetPoint("TOPRIGHT",    bf, "TOPRIGHT",     ov,  ov)
    local bl = newTex("frame_corner_bl"); bl:SetWidth(cz); bl:SetHeight(cz); bl:SetPoint("BOTTOMLEFT",  bf, "BOTTOMLEFT",  -ov, -ov)
    local br = newTex("frame_corner_br"); br:SetWidth(cz); br:SetHeight(cz); br:SetPoint("BOTTOMRIGHT", bf, "BOTTOMRIGHT",  ov, -ov)
    bf.corners = {tl=tl, tr=tr, bl=bl, br=br}

    -- 上下边（角间横向拉伸，高 et=cz；顶/底对齐角）
    local top = newTex("frame_edge_top"); top:SetHeight(et)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0); top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
    local bot = newTex("frame_edge_bot"); bot:SetHeight(et)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)

    -- 左右边（角间纵向拉伸，宽 et=cz；左/右对齐角）
    local lft = newTex("frame_edge_left"); lft:SetWidth(et)
    lft:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0); lft:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
    local rgt = newTex("frame_edge_right"); rgt:SetWidth(et)
    rgt:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0); rgt:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
    bf.edges = {top=top, bot=bot, left=lft, right=rgt}

    return bf
end

-- ============================================================
-- DFUI.CreateDiamondMetalBorder — 建子 frame 再贴金属边框（对标 CreateRetailInset）
-- opts 透传给 ApplyDiamondMetalBorder，额外支持：
--   anchors {tlx,tly,brx,bry}  子 frame 相对 parent 的双锚定位(缺省 SetAllPoints)
--   followFrame / followFrames 跟随目标 frame 显隐(单个 / 多个互斥)
-- 返回 child frame；边框挂 child.border(.corners/.edges 在其上)。
-- ============================================================
function DFUI.CreateDiamondMetalBorder(parent, opts)
    opts = opts or {}
    local child = CreateFrame("Frame", opts.name, parent)
    local a = opts.anchors
    if a then
        child:SetPoint("TOPLEFT",     parent, "TOPLEFT",     a[1], a[2])
        child:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", a[3], a[4])
    else
        child:SetAllPoints(parent)
    end

    -- 浅拷贝 opts 去掉 name(避免与 child 重名)，转交 Apply
    local o2 = {}
    for k, v in pairs(opts) do o2[k] = v end
    o2.name = nil
    child.border = DFUI.ApplyDiamondMetalBorder(child, o2)

    -- 跟随显隐（可选）—— 复用 CreateRetailInset 同款逻辑
    local follows = opts.followFrames or (opts.followFrame and {opts.followFrame})
    if follows then
        local function checkVisible()
            for _, f in ipairs(follows) do
                if f and f:IsVisible() then child:Show(); return end
            end
            child:Hide()
        end
        checkVisible()
        for _, f in ipairs(follows) do
            if f then
                HookScript(f, "OnShow", checkVisible)
                HookScript(f, "OnHide", checkVisible)
            end
        end
    end

    return child
end

-- ============================================================
-- DFUI.CreateDiamondMetalHeader — DF 通用九宫格"金属标题座 header"
-- 水平 3-slice：左端帽(2钻石封左+上+下) + 中段tile(上下金属线+凹暗区,横向拉伸,承载标题) + 右端帽。
-- 默认骑在 parent 顶边居中(CENTER 锚 parent TOP)，可与 ApplyDiamondMetalBorder 组合：边框围一圈 + 标题座叠顶。
-- 素材：header_{left,tile,right}.tga，源 128×156(高非POT)补 POT 128×256 → SetTexCoord V 取 0..156/256。
-- opts:
--   width (默认 200)            标题座宽(由调用方按标题长度定)
--   height (默认 40)            标题座高
--   capWidth (默认 h*128/156)   端帽宽(保持钻石 aspect，勿令 2*capWidth>width)
--   text (默认无)               居中标题文字；返回的 .text 可后续 SetText 改
--   font (默认 GameFontNormalLarge) 字体对象名(字符串)或字体对象
--   textColor (默认 DF 暖金)     {r,g,b,a}
--   tint (默认 {1,1,1,1}) / blendMode("BLEND") / drawLayer("OVERLAY")
--   levelOffset (默认 6)        层级 = parent 层级 + 此值(比主边框 5 高一层叠顶部)
--   yOffset (默认 0)            垂直微调(默认 header 中心骑 parent 顶边)
--   name
-- 返回：header frame 挂 .left / .tile / .right / .text
-- ============================================================
local HDR_V = 156 / 256   -- 0.609375，header 内容高占补 POT(256) 的比例

function DFUI.CreateDiamondMetalHeader(parent, opts)
    opts = opts or {}
    local w     = opts.width      or 200
    local h     = opts.height     or 40
    local capW  = opts.capWidth   or (h * 128 / 156)
    local tint  = opts.tint       or {1, 1, 1, 1}
    local blend = opts.blendMode  or "BLEND"
    local layer = opts.drawLayer  or "OVERLAY"
    local lvl   = opts.levelOffset or 6
    local yoff  = opts.yOffset    or 0

    local hdr = CreateFrame("Frame", opts.name, parent)
    hdr:SetWidth(w)
    hdr:SetHeight(h)
    hdr:SetPoint("CENTER", parent, "TOP", 0, yoff)
    hdr:SetFrameLevel(parent:GetFrameLevel() + lvl)

    local function newTex(file)
        local t = hdr:CreateTexture(nil, layer)
        t:SetTexture(DM_TEX .. file)
        t:SetTexCoord(0, 1, 0, HDR_V)    -- 高补 POT(256)，取内容区前 156 行
        t:SetBlendMode(blend)
        t:SetVertexColor(tint[1], tint[2], tint[3], tint[4] or 1)
        return t
    end

    -- 中段先建(端帽覆盖其端部接缝)，横向拉伸
    local tile = newTex("header_tile")
    tile:SetPoint("TOPLEFT",     hdr, "TOPLEFT",      capW, 0)
    tile:SetPoint("BOTTOMRIGHT", hdr, "BOTTOMRIGHT", -capW, 0)

    local left = newTex("header_left"); left:SetWidth(capW)
    left:SetPoint("TOPLEFT",    hdr, "TOPLEFT",    0, 0)
    left:SetPoint("BOTTOMLEFT", hdr, "BOTTOMLEFT", 0, 0)

    local right = newTex("header_right"); right:SetWidth(capW)
    right:SetPoint("TOPRIGHT",    hdr, "TOPRIGHT",    0, 0)
    right:SetPoint("BOTTOMRIGHT", hdr, "BOTTOMRIGHT", 0, 0)

    hdr.left, hdr.tile, hdr.right = left, tile, right

    -- 内置居中标题文字（落在 tile 凹暗区）
    local fontObj = opts.font
    if type(fontObj) == "string" then fontObj = _G[fontObj] end
    local fs = hdr:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(fontObj or GameFontNormalLarge)
    local tc = opts.textColor or {0.95, 0.85, 0.55}
    fs:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
    fs:SetPoint("CENTER", hdr, "CENTER", 0, 0)
    if opts.text then fs:SetText(opts.text) end
    hdr.text = fs

    return hdr
end
