----------------------------------------------------------------------
-- DFUI.Assist  --  Mob Attributes Tooltip (怪物属性提示)
-- 移植自 Automatonex Tooltip.lua（showResistance + showDamageAndSpeed）。
-- 鼠标悬停敌对/中立单位时，在 GameTooltip 追加：
--   护甲 / 火·冰·自然·暗·奥术抗性 / 伤害范围 / 攻击速度
-- 数据由服务器（Turtle）暴露；玩家单位不显示伤害与攻速。
-- 事件驱动（UPDATE_MOUSEOVER_UNIT），开关门控由 Assist 引擎统一处理。
----------------------------------------------------------------------

local L = DFUI.Assist.L

-- 抗性元素短名（按客户端语言）
local loc = GetLocale()
local ELE = (loc == "zhCN" or loc == "zhTW")
    and { fire = "火", frost = "冰", nature = "自", shadow = "暗", arcane = "奥" }
    or  { fire = "Fire", frost = "Frost", nature = "Nat", shadow = "Shad", arcane = "Arc" }

-- UnitResistance 索引：1神圣 2火 3自然 4冰霜 5暗影 6奥术（与原版一致）
local function IsHostileOrNeutral(unit)
    local reaction = UnitReaction("player", unit)
    return reaction and reaction <= 4   -- 4 及以下=中立或敌对
end

local function AddResistLines(unit)
    local fire   = UnitResistance(unit, 2) or 0
    local nature = UnitResistance(unit, 3) or 0
    local frost  = UnitResistance(unit, 4) or 0
    local shadow = UnitResistance(unit, 5) or 0
    local arcane = UnitResistance(unit, 6) or 0
    local armor  = UnitArmor(unit) or 0

    local parts = {}
    if fire   ~= 0 then table.insert(parts, "|cffFF0000" .. ELE.fire   .. fire   .. "|r") end
    if frost  ~= 0 then table.insert(parts, "|cff4AE8F5" .. ELE.frost  .. frost  .. "|r") end
    if nature ~= 0 then table.insert(parts, "|cff00FF00" .. ELE.nature .. nature .. "|r") end
    if shadow ~= 0 then table.insert(parts, "|cffFF00FF" .. ELE.shadow .. shadow .. "|r") end
    if arcane ~= 0 then table.insert(parts, "|cffCC66FF" .. ELE.arcane .. arcane .. "|r") end
    if table.getn(parts) > 0 then
        GameTooltip:AddLine(L["tipResist"] .. " " .. table.concat(parts, " "), 1, 1, 1)
    end

    if armor ~= 0 then
        GameTooltip:AddLine(L["tipArmor"] .. " " .. armor, 0.85, 0.85, 0.85)
    end
end

local function AddDamageLines(unit)
    if UnitIsPlayer(unit) then return end   -- 仅怪物，玩家伤害不可知
    local minDmg, maxDmg = UnitDamage(unit)
    local speed = UnitAttackSpeed(unit)
    if minDmg and maxDmg and maxDmg > 0 then
        GameTooltip:AddLine(string.format("%s %d - %d", L["tipDamage"], minDmg, maxDmg), 1, 0.82, 0)
    end
    if speed and speed > 0 then
        GameTooltip:AddLine(string.format("%s %.2f", L["tipSpeed"], speed), 1, 0.82, 0)
    end
end

----------------------------------------------------------------------
-- 注册：key=uiMobInfo（事件驱动，引擎按 IsEnabled 门控后才回调）
----------------------------------------------------------------------
DFUI.Assist:register({
    key   = "uiMobInfo",
    title = L["uiMobInfo"],
    desc  = L["uiMobInfoDesc"],
    default = false,
    events = {
        UPDATE_MOUSEOVER_UNIT = function(self)
            local unit = "mouseover"
            if not UnitExists(unit) then return end
            if not IsHostileOrNeutral(unit) then return end
            AddResistLines(unit)
            AddDamageLines(unit)
            GameTooltip:Show()
        end,
    },
})
