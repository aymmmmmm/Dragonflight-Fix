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
--   sb:UpdateThumb(scrollOffset, maxOffset, visibleRows, totalRows)
-- ============================================================
local RSB_TEX       = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\"
local RSB_TRACK_TB  = RSB_TEX .. "panels\\df\\professions\\scroll_track_tb.tga"   -- 128×64
local RSB_TRACK_MID = RSB_TEX .. "interface\\minimalscrollbarvertical.tga"        -- 64×1024 (NEW)
local RSB_THUMB_TB  = RSB_TEX .. "panels\\df\\professions\\scroll_thumb_tb.tga"   -- 64×64
local RSB_THUMB_MID = RSB_TEX .. "panels\\df\\professions\\scroll_thumb_mid.tga"  -- 64×1024
local RSB_ARROW     = RSB_TEX .. "panels\\df\\professions\\uiactionbar_atlas.tga" -- 256×1024

local RSB_ATLAS = {
    ["track-top"]   = {21/128, 29/128, 39/64,    47/64,    RSB_TRACK_TB},
    ["track-mid"]   = {1/64,   9/64,   0,        1/1024,   RSB_TRACK_MID},
    ["track-bot"]   = {11/128, 19/128, 49/64,    57/64,    RSB_TRACK_TB},
    ["thumb-top"]   = {20/64,  28/64,  54/64,    62/64,    RSB_THUMB_TB},
    ["thumb-mid"]   = {31/64,  39/64,  100/1024, 600/1024, RSB_THUMB_MID}, -- 中间稳定段（避开 atlas 端部透明渐变）
    ["thumb-bot"]   = {39/64,  47/64,  31/64,    39/64,    RSB_THUMB_TB},
    -- normal 态用真 pageuparrow-up / pagedownarrow-up UV（disabled 态 alpha 仅 12% 几乎不可见）
    ["up-normal"]   = {200/256,217/256,458/1024, 472/1024, RSB_ARROW},
    ["up-hover"]    = {181/256,198/256,458/1024, 472/1024, RSB_ARROW},
    ["up-down"]     = {234/256,251/256,390/1024, 404/1024, RSB_ARROW},
    ["down-normal"] = {234/256,251/256,358/1024, 372/1024, RSB_ARROW},
    ["down-hover"]  = {234/256,251/256,337/1024, 351/1024, RSB_ARROW},
    ["down-down"]   = {234/256,251/256,321/1024, 335/1024, RSB_ARROW},
}

local function rsbApply(tex, key)
    local a = RSB_ATLAS[key]
    tex:SetTexture(a[5])
    tex:SetTexCoord(a[1], a[2], a[3], a[4])
end

function DFUI.CreateRetailScrollbar(parent, listFrame, opts)
    opts = opts or {}
    local width   = opts.width   or 18
    local xOff    = opts.xOffset or 18
    local onDelta = opts.onScrollDelta or function() end
    local onAbs   = opts.onScrollAbs   or function() end

    local sb = CreateFrame("Frame", nil, parent)
    sb:SetWidth(width)
    sb:SetPoint("TOPRIGHT",    listFrame, "TOPRIGHT",    xOff, 0)
    sb:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", xOff, 0)
    sb:SetFrameLevel(parent:GetFrameLevel() + 5)

    -- 箭头按钮（3 态：normal/hover/down，用 3 个 BACKGROUND texture 切换 Show/Hide）
    local function makeArrowBtn(point, normKey, hovKey, dnKey)
        local btn = CreateFrame("Button", nil, sb)
        btn:SetWidth(width); btn:SetHeight(16)
        btn:SetPoint(point, sb, point, 0, 0)
        local function tex(key)
            -- ARTWORK 层（紫色调试证明 Button 内 BACKGROUND 不渲染）
            local t = btn:CreateTexture(nil, "ARTWORK")
            rsbApply(t, key)
            t:SetAllPoints(btn)
            -- DEBUG 红色
            t:SetVertexColor(1.0, 0.0, 0.0, 1.0)
            return t
        end
        local norm = tex(normKey)
        local hov  = tex(hovKey); hov:Hide()
        local dn   = tex(dnKey);  dn:Hide()
        btn:SetScript("OnEnter",     function() if not btn.pushed then norm:Hide(); hov:Show() end end)
        btn:SetScript("OnLeave",     function() if not btn.pushed then hov:Hide();  norm:Show() end end)
        btn:SetScript("OnMouseDown", function() btn.pushed = true;  norm:Hide(); hov:Hide(); dn:Show() end)
        btn:SetScript("OnMouseUp",   function() btn.pushed = false; dn:Hide(); norm:Show() end)
        return btn
    end
    local upBtn = makeArrowBtn("TOP",    "up-normal",   "up-hover",   "up-down")
    local dnBtn = makeArrowBtn("BOTTOM", "down-normal", "down-hover", "down-down")
    upBtn:SetScript("OnClick", function() onDelta(-1) end)
    dnBtn:SetScript("OnClick", function() onDelta(1)  end)

    -- track 容器
    local track = CreateFrame("Frame", nil, sb)
    track:SetWidth(12)
    track:SetPoint("TOP",    upBtn, "BOTTOM", 0, -2)
    track:SetPoint("BOTTOM", dnBtn, "TOP",    0,  2)
    track:SetPoint("LEFT",  sb, "LEFT",  3, 0)
    track:SetPoint("RIGHT", sb, "RIGHT", -3, 0)

    -- track 3-slice：暂时去掉，先调通 thumb + 箭头

    -- thumb 3-slice
    local thumb = CreateFrame("Frame", nil, track)
    thumb:EnableMouse(true)
    thumb:SetWidth(12)
    thumb:SetHeight(50)
    thumb:SetPoint("TOP", track, "TOP", 0, 0)
    -- thumb 只有上下两小块（atlas 真实 8×8，零拉伸保清晰），中间透出 inset 背景
    local thTop = thumb:CreateTexture(nil, "BACKGROUND"); rsbApply(thTop, "thumb-top")
    thTop:SetWidth(12); thTop:SetHeight(8); thTop:SetPoint("TOP", thumb, "TOP", 0, 0)
    local thBot = thumb:CreateTexture(nil, "BACKGROUND"); rsbApply(thBot, "thumb-bot")
    thBot:SetWidth(12); thBot:SetHeight(8); thBot:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)

    -- 拖动逻辑：OnMouseDown 启动 OnUpdate 跟随鼠标 y, OnMouseUp 停止
    thumb.dragging = false
    thumb:SetScript("OnMouseDown", function() thumb.dragging = true  end)
    thumb:SetScript("OnMouseUp",   function() thumb.dragging = false end)
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
        onAbs(ratio)
    end)

    sb.thumb = thumb
    sb.track = track
    sb.thTop = thTop
    sb.thBot = thBot
    sb.lastMaxOffset = 0

    -- 由滚动逻辑调用：同步 thumb 几何 + 缓存 lastMaxOffset（拖动时算 ratio→scrollOff 用）
    sb.UpdateThumb = function(scrollOff, maxOff, visRows, totalRows)
        sb.lastMaxOffset = maxOff or 0
        local trackH = track:GetHeight()
        if not trackH or trackH <= 0 then return end
        local thumbH = math.max(30, trackH * visRows / math.max(visRows, totalRows))
        if thumbH > trackH then thumbH = trackH end
        thumb:SetHeight(thumbH)
        -- thTop/thBot 固定 8 高（atlas 真实，零拉伸保清晰），中间空
        local thumbMaxY = trackH - thumbH
        local thumbY = (maxOff and maxOff > 0) and (thumbMaxY * scrollOff / maxOff) or 0
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -thumbY)
    end

    return sb
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
        if not p or not p.SetVerticalScroll then return end
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
        -- 调用 opts.onWheel 手动触发对应列表 *_Update（绕开 vanilla broken OnVerticalScroll）
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
