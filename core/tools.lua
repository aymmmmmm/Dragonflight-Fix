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
