-- ═══════════════════════════════════════════════════════════════
-- libhealth - 怪物血量估算库 (MobHealth3 风格,独立自管)
-- 算法:双轴累加(accDmg + accPerc),precision 阈值收敛误差
-- 数据源:UNIT_COMBAT.arg4 (精确数值) + CHAT_MSG_SPELL_* (兜底)
-- 独立 SavedVariables: DFUI_HealthDB
-- ═══════════════════════════════════════════════════════════════

DFUI = DFUI or {}
DFUI.libhealth = DFUI.libhealth or {}

local lib = DFUI.libhealth
lib.precision = 10   -- 累计百分比降达到该值才写入估算
lib.reqperc   = 10   -- 读取时要求累计百分比降至少这么大
lib.reqhit    = 2    -- 读取时要求采样次数至少这么多

-- 内存数据库(运行时操作的对象)
local mobdb = {}

-- 当前目标累计状态
local target       = nil   -- "Name:Level" 索引
local lastPerc     = 100   -- 上一次 UNIT_HEALTH 看到的血量百分比
local startPerc    = 100   -- 切目标时初始百分比
local recentDmg    = 0     -- UNIT_HEALTH 之间累加的伤害
local accDmg       = 0     -- 自切目标累计伤害(经过验证后才参与计算)
local accPerc      = 0     -- 自切目标累计百分比降
local locked       = {}    -- Beast Lore 已知真值的目标,不再估算

-- ═══════════════════════════════════════════════════════════════
-- 目标合法性检查
-- 排除:玩家、友方、死尸、玩家控制的兽/恶魔(宠物)
-- ═══════════════════════════════════════════════════════════════
local function IsValidEstimateTarget(unit)
    if not UnitExists(unit) then return false end
    if not UnitCanAttack("player", unit) then return false end
    if UnitIsDead(unit) then return false end
    if UnitIsFriend("player", unit) then return false end
    if UnitIsPlayer(unit) then return false end   -- 玩家血变化大,不可靠
    local ct = UnitCreatureType(unit)
    if (ct == "Beast" or ct == "Demon") and UnitPlayerControlled(unit) then
        return false   -- 玩家宠物,跳过
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- 启动迁移:从其他库的 cache 导入历史数据(per-entry 取最高可信)
-- ═══════════════════════════════════════════════════════════════
local function ImportFrom(src)
    if type(src) ~= "table" then return end
    for key, entry in pairs(src) do
        if type(entry) == "table" and entry[1] and entry[2] then
            local existing = mobdb[key]
            -- 没有,或新来的累计 perc 更高 → 覆盖
            if not existing or (entry[2] or 0) > (existing[2] or 0) then
                mobdb[key] = { entry[1], entry[2], entry[3] or 1 }
            end
        end
    end
end

local function ImportFromMH3()
    -- MobHealth3 格式不同:MH3Cache[key] = maxHP (单一数字)
    if type(GetMH3Cache) ~= "function" then return end
    local mh3 = GetMH3Cache()
    if type(mh3) ~= "table" then return end
    for key, maxHP in pairs(mh3) do
        if type(maxHP) == "number" and maxHP > 0 then
            local existing = mobdb[key]
            -- MH3 已经收敛过(它默认 precision=10%),给较高初始可信度
            if not existing then
                mobdb[key] = { maxHP, 100, 10 }
            end
        end
    end
end

local function PerformMigration()
    if DFUI_HealthDB._migrated then return end
    if ShaguTweaks_cache then ImportFrom(ShaguTweaks_cache["libhealth"]) end
    if pfUI_cache then ImportFrom(pfUI_cache["libhealth"]) end
    ImportFromMH3()
    DFUI_HealthDB._migrated = true
end

-- ═══════════════════════════════════════════════════════════════
-- 切换目标:flush 当前累计,重置状态
-- ═══════════════════════════════════════════════════════════════
local function OnTargetChanged()
    target = nil
    recentDmg, accDmg, accPerc = 0, 0, 0
    startPerc, lastPerc = 100, 100

    if not IsValidEstimateTarget("target") then return end
    local rawMax = UnitHealthMax("target")

    -- Beast Lore / 别的库接管 API:max 不是 100 → 信任原生
    if rawMax ~= 100 then
        if rawMax > 100 then
            local name, level = UnitName("target"), UnitLevel("target")
            if name and level then
                local key = string.format("%s:%d", name, level)
                mobdb[key] = { rawMax, 100, 999 }   -- 真值标记
                locked[key] = true
            end
        end
        return
    end

    local name, level = UnitName("target"), UnitLevel("target")
    if not name or not level then return end
    target = string.format("%s:%d", name, level)
    startPerc = UnitHealth("target") or 100
    lastPerc = startPerc
end

-- ═══════════════════════════════════════════════════════════════
-- 累加伤害到 recentDmg(UNIT_HEALTH 触发时整合到 accDmg)
-- ═══════════════════════════════════════════════════════════════
local function AddDamage(dmg)
    if target and dmg and dmg > 0 and dmg < 1000000 then
        recentDmg = recentDmg + dmg
    end
end

-- 启发式:从战斗日志文本提取伤害数字(兜底,仅 UNIT_COMBAT 没触发的法术 dot)
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

-- ═══════════════════════════════════════════════════════════════
-- UNIT_HEALTH:核心计算时机
-- ═══════════════════════════════════════════════════════════════
local function OnTargetHealth()
    if not target or locked[target] then return end
    local cur = UnitHealth("target")
    if not cur or cur == 0 then return end   -- 死或无数据

    -- Healed:目标回血了,reset 累计避免污染
    if cur > lastPerc then
        recentDmg = 0
        lastPerc = cur
        startPerc = cur
        return
    end

    if cur == lastPerc then return end   -- 没掉血,不算

    local diff = lastPerc - cur
    if recentDmg > 0 and diff > 0 then
        accDmg  = accDmg  + recentDmg
        accPerc = accPerc + diff
        recentDmg = 0
        lastPerc = cur

        -- 达到 precision → 写入估算
        if accPerc >= lib.precision then
            mobdb[target] = mobdb[target] or {}
            local entry = mobdb[target]
            entry[1] = math.floor(accDmg / accPerc * 100 + 0.5)
            entry[2] = accPerc
            entry[3] = (entry[3] or 0) + 1
        end
    else
        -- 有 diff 但没记到伤害(可能被吸收/格挡漏算),只推进 lastPerc
        lastPerc = cur
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 事件分发
-- ═══════════════════════════════════════════════════════════════
local frame = CreateFrame("Frame", "DFUI_LibHealthFrame", UIParent)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_COMBAT")
frame:RegisterEvent("UNIT_HEALTH")
-- 法术/远程兜底(UNIT_COMBAT 在 1.12 vanilla 偶有遗漏的 dot)
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PET_DAMAGE")

frame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        DFUI_HealthDB = DFUI_HealthDB or {}
        mobdb = DFUI_HealthDB
        PerformMigration()
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        OnTargetChanged()
        return
    end

    if event == "UNIT_COMBAT" and arg1 == "target" and target then
        -- arg2: 动作类型 (WOUND/HEAL/MISS/PARRY/...) arg4: 伤害数值
        if arg2 == "HEAL" then return end
        AddDamage(arg4)
        return
    end

    if event == "UNIT_HEALTH" and arg1 == "target" then
        OnTargetHealth()
        return
    end

    -- 战斗日志兜底:仅当 target 已设定且数据合理时累加
    if target and string.sub(event, 1, 14) == "CHAT_MSG_SPELL" then
        local d = ExtractDamage(arg1)
        -- 加严过滤:伤害必须 > 5 避免抓到等级/技能 ID 等小数字
        if d > 5 then AddDamage(d) end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- 对外 API
-- ═══════════════════════════════════════════════════════════════
function lib:GetUnitHealth(unit)
    if not UnitExists(unit) then return 0, 0, false end
    local cur = UnitHealth(unit)
    local max = UnitHealthMax(unit)

    -- 其他插件接管了 API(SuperWoW 不接管,但 Decursive/某些插件会)
    if max > 100 then return cur, max, true end
    if max < 100 and max > 0 then return cur, max, true end
    if max == 0 then return 0, 0, false end

    -- max == 100 → 走估算
    local name, level = UnitName(unit), UnitLevel(unit)
    if not name or not level then return cur, max, false end

    local key = string.format("%s:%d", name, level)
    local entry = mobdb[key]
    if entry and entry[1] and entry[2]
       and entry[2] >= self.reqperc
       and (entry[3] or 0) >= self.reqhit then
        local realMax = entry[1]
        return math.ceil(realMax / 100 * cur), realMax, true
    end

    return cur, max, false
end

-- 仅供调试/测试
function lib:GetDB() return mobdb end
function lib:ResetDB()
    for k in pairs(mobdb) do mobdb[k] = nil end
    mobdb._migrated = nil
    locked = {}
end
