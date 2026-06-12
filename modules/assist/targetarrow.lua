----------------------------------------------------------------------
-- DFUI.Assist  --  Target Arrow Marker (目标箭头标记)
-- 移植自 STargetMark：在当前目标的姓名板上方贴一个箭头标记。
-- 兼容原版姓名板（扫描 WorldFrame 子框 + Nameplate-Border 判定）
-- 与 pfUI / ShaguPlates 姓名板（pfNamePlateN.istarget）。
-- 单一自管 OnUpdate 驱动，0.05s 节流；功能关闭即隐藏全部箭头。
----------------------------------------------------------------------

local OFFSET_X   = 0
local OFFSET_Y   = 5
local ARROW_W    = 50
local ARROW_H    = 60   -- 原版 = SIZE + 10

local TEX_PATH   = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\assist\\"

-- 可选样式（第一项为默认，对应原版 STargetMark 的 Arrow2）
DFUI.Assist.TargetArrowStyles = {
    { name = "Arrow2",  zh = "红V双箭", en = "Red Chevron" },
    { name = "Arrow",   zh = "红色箭头", en = "Red Arrow" },
    { name = "Arrow16", zh = "红实心箭", en = "Solid Arrow" },
    { name = "Arrow4",  zh = "红色锥形", en = "Red Cone" },
    { name = "Arrow3",  zh = "绿色锥形", en = "Green Cone" },
    { name = "Arrow6",  zh = "蓝色V",   en = "Blue V" },
    { name = "Arrow13", zh = "紫色双箭", en = "Purple Chevron" },
    { name = "Arrow1",  zh = "红色准星", en = "Red Reticle" },
}

local arrows = {}   -- 已创建的箭头 texture 列表（用于换样式 / 一键隐藏）
local cache  = {}   -- 原版姓名板缓存
local prevCount   = 0
local timer       = 0
local UPDATE_STEP = 0.05
local wasEnabled  = nil
local driver                                   -- 驱动 frame（load 时建一次）

----------------------------------------------------------------------
-- 样式
----------------------------------------------------------------------
local function CurrentStyleName()
    local db = DFUI.Assist.db
    return (db and db.targetArrowStyle) or "Arrow2"
end

local function CurrentTexPath()
    return TEX_PATH .. CurrentStyleName()
end

function DFUI.Assist.GetTargetArrowStyleIndex()
    local cur = CurrentStyleName()
    local list = DFUI.Assist.TargetArrowStyles
    for i = 1, table.getn(list) do
        if list[i].name == cur then return i end
    end
    return 1
end

function DFUI.Assist.GetTargetArrowStyleLabel()
    local s = DFUI.Assist.TargetArrowStyles[DFUI.Assist.GetTargetArrowStyleIndex()]
    if not s then return "" end
    local loc = GetLocale()
    if loc == "zhCN" or loc == "zhTW" then return s.zh end
    return s.en
end

-- 重贴所有现存箭头的纹理（切换样式后调用）
local function ApplyStyle()
    local p = CurrentTexPath()
    for i = 1, table.getn(arrows) do
        arrows[i]:SetTexture(p)
    end
end
DFUI.Assist.ApplyTargetArrowStyle = ApplyStyle

-- 循环切换到下一个样式，写档案 + 即时重贴，返回新标签
function DFUI.Assist.CycleTargetArrowStyle()
    local list = DFUI.Assist.TargetArrowStyles
    local n    = table.getn(list)
    local idx  = math.mod(DFUI.Assist.GetTargetArrowStyleIndex(), n) + 1
    local name = list[idx].name
    DFUI:SetTempDB("Assist", "targetArrowStyle", name)
    if DFUI.Assist.db then DFUI.Assist.db.targetArrowStyle = name end
    ApplyStyle()
    return DFUI.Assist.GetTargetArrowStyleLabel()
end

----------------------------------------------------------------------
-- 箭头
----------------------------------------------------------------------
local function MakeArrow(parent)
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetTexture(CurrentTexPath())
    t:SetWidth(ARROW_W)
    t:SetHeight(ARROW_H)
    t:Hide()
    table.insert(arrows, t)
    return t
end

local function ArrowShow(namePlate)
    namePlate.Arrow:ClearAllPoints()
    namePlate.Arrow:SetPoint("BOTTOM", namePlate, "TOP", OFFSET_X, OFFSET_Y)
    namePlate.Arrow:Show()
end

local function HideAll()
    for i = 1, table.getn(arrows) do
        arrows[i]:Hide()
    end
end

local function IsNamePlateFrame(frame)
    if frame:GetObjectType() ~= "Button" then return false end
    local overlayRegion = frame:GetRegions()
    if not overlayRegion or overlayRegion:GetObjectType() ~= "Texture"
        or overlayRegion:GetTexture() ~= "Interface\\Tooltips\\Nameplate-Border" then
        return false
    end
    return true
end

----------------------------------------------------------------------
-- 驱动循环
----------------------------------------------------------------------
local function OnUpdate()
    timer = timer + arg1
    if timer < UPDATE_STEP then return end
    timer = 0

    if not DFUI.Assist:IsEnabled("uiTargetArrow") then
        if wasEnabled ~= false then HideAll(); wasEnabled = false end
        return
    end
    wasEnabled = true

    if (ShaguPlates and ShaguPlates.nameplates) or (pfUI and pfUI.nameplates) then
        -- pfUI / ShaguPlates 姓名板：直接读 istarget 标志
        local index = 1
        while getglobal("pfNamePlate" .. index) do
            local np = getglobal("pfNamePlate" .. index)
            if np.Arrow == nil then np.Arrow = MakeArrow(np.health) end
            if np.istarget then ArrowShow(np) else np.Arrow:Hide() end
            index = index + 1
        end
    else
        -- 原版姓名板：扫描 WorldFrame 新增子框，缓存命中的姓名板
        local parentCount = WorldFrame:GetNumChildren()
        if prevCount < parentCount then
            local frames = { WorldFrame:GetChildren() }
            for _, np in ipairs(frames) do
                if IsNamePlateFrame(np) and not cache[np] then cache[np] = np end
            end
            prevCount = parentCount
        end

        -- 清理已失效的姓名板，防 cache 无限增长
        for np in pairs(cache) do
            if not np:IsVisible() and not np.Arrow then cache[np] = nil end
        end

        for np in pairs(cache) do
            local HealthBar = np:GetChildren()
            if np.Arrow == nil then np.Arrow = MakeArrow(np) end
            -- 目标姓名板 alpha=1（原版高亮当前目标），其余淡出
            if UnitExists("target") and HealthBar:GetAlpha() == 1 then
                ArrowShow(np)
            else
                np.Arrow:Hide()
            end
        end
    end
end

----------------------------------------------------------------------
-- 注册：key=uiTargetArrow（load 建驱动 frame，OnUpdate 自门控）
----------------------------------------------------------------------
DFUI.Assist:register({
    key   = "uiTargetArrow",
    title = DFUI.Assist.L["uiTargetArrow"],
    desc  = DFUI.Assist.L["uiTargetArrowDesc"],
    default = false,
    load = function(self)
        if driver then return end
        driver = CreateFrame("Frame", "DFUIAssistTargetArrow", UIParent)
        driver:SetScript("OnUpdate", OnUpdate)
    end,
})
