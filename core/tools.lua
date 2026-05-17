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

-- 直接读 libhealth 的 cache(绕过库 reqhit/reqdmg 阈值)
-- 库自己的 GetUnitHealth 要求 hit>2 且 diff>10 才返回估算,对一击秒杀小怪过严
-- mobdb 写入无门槛(只要 dmg>0 and diff>0),所以读 cache 用更宽松阈值即可
local function GetEstimatedFromCache(unit, rawCur)
    local mobdb
    if ShaguTweaks_cache and ShaguTweaks_cache["libhealth"] then
        mobdb = ShaguTweaks_cache["libhealth"]
    elseif pfUI_cache and pfUI_cache["libhealth"] then
        mobdb = pfUI_cache["libhealth"]
    end
    if not mobdb then return nil end

    local name = UnitName(unit)
    local level = UnitLevel(unit)
    if not name or not level then return nil end

    local key = string.format("%s:%d", name, level)
    local entry = mobdb[key]
    if not entry or not entry[1] or not entry[2] then return nil end

    -- 3% 百分比降即认可,远低于库的 10%
    if entry[2] < 3 then return nil end

    local realMax = entry[1]
    return math.ceil(realMax / 100 * rawCur), realMax
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

    -- 3. max=100 (典型怪/友方玩家百分比模式) → 读 cache 估算
    if rawMax == 100 then
        local cur, max = GetEstimatedFromCache(unit, rawCur)
        if cur and max then
            return cur, max, "real"
        end
        return rawCur, rawMax, "percent"
    end

    -- 4. max≠100 且≠0:别的插件接管了 API 返回真值,直接信任
    return rawCur, rawMax, "real"
end

-- ═══════════════════════════════════════════════════════════════
-- Health Tracker
-- ShaguTweaks/pfUI libhealth 只监听 UNIT_COMBAT(主要近战物理),
-- 法术/远程伤害走 CHAT_MSG_SPELL_* 事件,libhealth 完全漏掉。
-- 后果:法师/术士/猎人/牧师等远程职业 → cache 永远是空的 → 怪物显示 100%
-- 本 tracker 补全法术伤害监听,直接写入 ShaguTweaks_cache["libhealth"](与库共享同表)
-- ═══════════════════════════════════════════════════════════════
do
    local tracker = CreateFrame("Frame")
    tracker.dmg = 0
    tracker.perc = 0
    tracker.target = nil

    -- 启发式:从战斗日志消息中提取最大数字作为伤害值
    -- 战斗日志格式因本地化(zhCN/enUS)而异,模板匹配维护成本太高;用最大数字启发式
    -- 误差来源:消息可能包含等级/技能ID等非伤害数字,但伤害通常是最大的那个
    local function ExtractDamage(msg)
        if not msg then return 0 end
        local damage = 0
        for n in string.gmatch(msg, "(%d+)") do
            local num = tonumber(n)
            if num and num > damage and num < 1000000 then
                damage = num
            end
        end
        return damage
    end

    tracker:RegisterEvent("PLAYER_TARGET_CHANGED")
    tracker:RegisterEvent("UNIT_HEALTH")
    -- 只监听法术/周期性伤害,UNIT_COMBAT 留给 libhealth 处理(避免重复计数)
    tracker:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
    tracker:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
    tracker:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
    tracker:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PET_DAMAGE")

    tracker:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            tracker.dmg = 0
            tracker.perc = UnitHealth("target") or 0
            if UnitName("target") and UnitLevel("target") and UnitHealthMax("target") == 100 then
                tracker.target = string.format("%s:%d", UnitName("target"), UnitLevel("target"))
            else
                tracker.target = nil
            end
        elseif tracker.target and event == "UNIT_HEALTH" and arg1 == "target" then
            local cur = UnitHealth("target")
            local diff = tracker.perc - cur
            if tracker.dmg > 0 and diff > 0 then
                ShaguTweaks_cache = ShaguTweaks_cache or {}
                ShaguTweaks_cache["libhealth"] = ShaguTweaks_cache["libhealth"] or {}
                local mobdb = ShaguTweaks_cache["libhealth"]
                mobdb[tracker.target] = mobdb[tracker.target] or {}
                local entry = mobdb[tracker.target]
                if not entry[2] or diff > entry[2] then
                    entry[1] = math.ceil(tracker.dmg / diff * 100)
                    entry[2] = diff
                    entry[3] = (entry[3] or 0) + 1
                end
            end
        elseif tracker.target then
            -- 战斗日志事件:arg1 是消息内容
            local damage = ExtractDamage(arg1)
            if damage > 0 then
                tracker.dmg = tracker.dmg + damage
            end
        end
    end)
end
