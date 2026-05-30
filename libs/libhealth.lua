-- ═══════════════════════════════════════════════════════════════
-- libhealth - 怪物血量估算库 (置信加权收敛版 v2)
-- 算法:全程累计 accDmg/accPerc,切目标 finalize 时按置信加权合并进 DB
--   - 保留:overkill 丢弃 / 回血 reset / round 取整 / 跳过无伤害窗口(抗组队偏小)
--   - 改掉旧"累计 10% 一锤定音、永不覆盖"——改为越打越准 + 跨击杀收敛 + 饱和上限
--   - 整次击杀级离群门控(仅在已有可信先验时启用,剔除组队污染的偏小估算)
--   - conf < REQ_CONF 时 GetUnitHealth 返回 found=false → UI 回退百分比,
--     绝不显示没把握的错绝对值
-- 数据源:仅 UNIT_COMBAT.arg4(近战/物理;法术/DoT 是否覆盖待真机确认)
-- 独立 SavedVariables: DFUI_HealthDB (schema v2: {est, conf, kills})
-- ═══════════════════════════════════════════════════════════════

DFUI = DFUI or {}
DFUI.libhealth = DFUI.libhealth or {}

local lib = DFUI.libhealth
lib.PRECISION  = 5        -- 单次击杀累计掉血 ≥ 该% 才允许 finalize 落地
lib.REQ_CONF   = 12       -- 读取要求 conf ≥ 该值才 found=true,否则回退百分比
lib.CONF_CAP   = 200      -- conf 饱和上限,保证 DB 始终可被新数据修正(防"打多了改不动")
lib.OUTLIER_LO = 0.55     -- 整次 fightEst < est*该值 → 组队污染偏小,拒绝合并
lib.OUTLIER_HI = 1.80     -- 整次 fightEst > est*该值 → 脏数据偏大,拒绝合并
lib.BEAST_CONF = 100000   -- Beast Lore 等真值标记 = 等价 locked,估算不可覆盖
lib.SEED_CONF  = 1        -- 迁移弱先验权重:远低于一次真实 finalize 的 w(数十~95),仅占位,真实数据一到即被冲掉
lib.MAX_FIGHT_W = 100     -- 单场合并权重上限:单怪满血至多掉 100%,>100 必是回血叠加,不应额外加权

local DB_VERSION = 2

-- 内存数据库(运行时操作的对象,PLAYER_ENTERING_WORLD 时指向 DFUI_HealthDB)
local mobdb = {}

-- 当前目标累计状态
local target    = nil   -- "Name:Level" 索引
local lastPerc  = 100   -- 最新 UNIT_HEALTH 看到的血量百分比(总跟最新值,供回血检测)
local commitPerc= 100   -- 上次"提交"伤害时的血量%基线(与 lastPerc 解耦,容忍事件乱序)
local recentDmg = 0     -- 两次提交之间累加的伤害
local accDmg    = 0     -- 自切目标累计伤害(仅计入"看到伤害"的窗口)
local accPerc   = 0     -- 自切目标累计百分比降(仅计入"看到伤害"的窗口)

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
-- 启动迁移 (→v2):旧 v1 条目 {maxHP,perc,hits} 与外部 cache 一律降级为弱先验
--   { maxHP, REQ_CONF-1, 0 } —— conf 故意低于阈值:默认显示%,
--   被真实游玩首次 finalize 即覆盖确认。旧 perc 是单窗口 diff,与新 conf 含义不同,
--   不能直接当置信,故不盲信也不硬删。
-- ═══════════════════════════════════════════════════════════════
local function SeedWeak(key, maxHP)
    if type(key) ~= "string" then return end
    if type(maxHP) ~= "number" or maxHP <= 0 then return end
    if not mobdb[key] then
        mobdb[key] = { maxHP, lib.SEED_CONF, 0 }
    end
end

local function ImportFrom(src)
    if type(src) ~= "table" then return end
    for key, entry in pairs(src) do
        if type(entry) == "number" then
            SeedWeak(key, entry)
        elseif type(entry) == "table" and entry[1] then
            SeedWeak(key, entry[1])
        end
    end
end

local function ImportFromMH3()
    -- MobHealth3 格式:MH3Cache[key] = maxHP (单一数字)
    if type(GetMH3Cache) ~= "function" then return end
    local mh3 = GetMH3Cache()
    if type(mh3) ~= "table" then return end
    for key, maxHP in pairs(mh3) do
        SeedWeak(key, maxHP)
    end
end

local function PerformMigration()
    if mobdb._ver and mobdb._ver >= DB_VERSION then return end

    -- 1. 现存条目(v1 残留)一律降级为弱先验(Beast 真值除外)
    for key, entry in pairs(mobdb) do
        if type(key) == "string" and string.sub(key, 1, 1) ~= "_"
           and type(entry) == "table" and entry[1] then
            if (entry[2] or 0) ~= lib.BEAST_CONF then
                entry[2] = lib.SEED_CONF
                entry[3] = 0
            end
        end
    end

    -- 2. 从其他库 cache 导入历史 maxHP(弱先验,不覆盖已存在)
    if ShaguTweaks_cache then ImportFrom(ShaguTweaks_cache["libhealth"]) end
    if pfUI_cache then ImportFrom(pfUI_cache["libhealth"]) end
    ImportFromMH3()

    mobdb._migrated = true
    mobdb._ver = DB_VERSION
end

-- ═══════════════════════════════════════════════════════════════
-- finalize:把当前目标这一场累计的干净数据按置信加权合并进 DB
-- 时机 = 切目标(含目标死亡后框架清空触发的 PLAYER_TARGET_CHANGED),
--        同时覆盖"打死"与"中途换目标"。战斗中不写 DB → 显示恒定不跳变。
-- ═══════════════════════════════════════════════════════════════
local function FinalizeCurrentFight()
    if not target then return end
    if accPerc < lib.PRECISION or accDmg <= 0 then return end   -- 数据太少 → 丢弃,不污染

    local fightEst = math.floor(accDmg / accPerc * 100 + 0.5)   -- round,不是 ceil(抗偏大)
    if fightEst <= 0 then return end

    local e = mobdb[target]
    if e and e[2] and e[2] >= lib.BEAST_CONF then return end     -- 真值不可被估算覆盖

    -- 单场权重封顶:回血/自愈怪会让 accPerc 远超 100,不能让一场嘈杂数据以超大权重压过历史先验
    local w = math.min(accPerc, lib.MAX_FIGHT_W)

    if not e then
        -- bootstrap:首次无先验,直接采纳,离群门控不启用
        mobdb[target] = { fightEst, math.min(w, lib.CONF_CAP), 1 }
    else
        local est, conf = e[1], e[2] or 0
        if conf >= lib.REQ_CONF then                            -- 离群门控仅在有可信先验时启用
            if fightEst < est * lib.OUTLIER_LO or fightEst > est * lib.OUTLIER_HI then
                return                                          -- 组队污染/脏数据,拒绝合并
            end
        end
        local newEst  = math.floor((est * conf + fightEst * w) / (conf + w) + 0.5)
        local newConf = math.min(conf + w, lib.CONF_CAP)
        mobdb[target] = { newEst, newConf, (e[3] or 0) + 1 }
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 切换目标:先 finalize 上个目标,再重置累计状态
-- ═══════════════════════════════════════════════════════════════
local function OnTargetChanged()
    FinalizeCurrentFight()

    target = nil
    recentDmg, accDmg, accPerc = 0, 0, 0
    lastPerc, commitPerc = 100, 100

    if not IsValidEstimateTarget("target") then return end

    -- ?? 怪(UnitLevel 返回 -1)不学习:同名不同真实等级会塌进 "Name:-1" 一桶污染估值
    local name, level = UnitName("target"), UnitLevel("target")
    if not name or not level or level <= 0 then return end

    local rawMax = UnitHealthMax("target")

    -- Beast Lore / 别的库接管 API:max 不是 100 → 信任原生(真值由 GetUnitRealHealth 分支4直显,无需入库)
    if rawMax ~= 100 then
        if rawMax > 100 then
            mobdb[string.format("%s:%d", name, level)] = { rawMax, lib.BEAST_CONF, 999 }
        end
        return
    end

    target = string.format("%s:%d", name, level)
    lastPerc = UnitHealth("target") or 100   -- 开局可能 <100%(低血怪),只累加后续掉血,无妨
    commitPerc = lastPerc
end

-- ═══════════════════════════════════════════════════════════════
-- 累加伤害到 recentDmg(UNIT_HEALTH 触发时整合到 accDmg)
-- ═══════════════════════════════════════════════════════════════
local function AddDamage(dmg)
    if target and dmg and dmg > 0 and dmg < 1000000 then
        recentDmg = recentDmg + dmg
    end
end

-- ═══════════════════════════════════════════════════════════════
-- UNIT_HEALTH:累加配对窗口(看到伤害的窗口才计),不在此写 DB
-- ═══════════════════════════════════════════════════════════════
local function OnTargetHealth()
    if not target then return end
    local e = mobdb[target]
    if e and e[2] and e[2] >= lib.BEAST_CONF then return end    -- 真值锁定,不再估算

    local cur = UnitHealth("target")
    if not cur then return end
    if cur == 0 then
        -- 目标死亡:丢弃 overkill 帧本身,但立即 finalize 本场(不再等切目标),再停累计。
        -- 这样"打死怪→不切目标直接登出"也不丢数据;后续 PLAYER_TARGET_CHANGED 因 target=nil 不重复合并。
        FinalizeCurrentFight()
        target = nil
        return
    end

    -- Healed:目标回血了,丢弃未提交的挂起跌幅并重设基线,保留已采纳的 accDmg/accPerc 前缀
    if cur > lastPerc then
        recentDmg = 0
        lastPerc = cur
        commitPerc = cur
        return
    end

    if cur == lastPerc then return end   -- 没掉血,不算

    -- 下降:仅在看到伤害时提交,用 commitPerc 算"自上次提交以来的完整跌幅"。
    -- 这样 UNIT_HEALTH 先于 UNIT_COMBAT 到达(1.12 混合乱序)时,晚到的伤害仍与其完整%配对,
    -- 不会像旧版那样把该%丢弃(那会吃掉 accPerc → accDmg/accPerc 被抬高 → solo 高估)。
    if recentDmg > 0 then
        accDmg  = accDmg  + recentDmg
        accPerc = accPerc + (commitPerc - cur)
        recentDmg = 0
        commitPerc = cur
    end
    lastPerc = cur   -- 总是推进(供回血检测);未见伤害的跌幅留在 commitPerc 挂起,不丢
end

-- ═══════════════════════════════════════════════════════════════
-- 事件分发
-- ═══════════════════════════════════════════════════════════════
local frame = CreateFrame("Frame", "DFUI_LibHealthFrame", UIParent)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_COMBAT")
frame:RegisterEvent("UNIT_HEALTH")

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
    if not name or not level or level <= 0 then return cur, max, false end   -- ?? 怪不给绝对值,回退%

    local entry = mobdb[string.format("%s:%d", name, level)]
    if entry and entry[1] and entry[2] and entry[2] >= self.REQ_CONF then
        return math.ceil(entry[1] / 100 * cur), entry[1], true
    end

    return cur, max, false   -- conf 不足 → UI 显示百分号
end

-- 仅供调试/测试
function lib:GetDB() return mobdb end
function lib:ResetDB()
    for k in pairs(mobdb) do mobdb[k] = nil end
    -- 标记已迁移当前版本:/dfhp reset 后重进世界不再从 ShaguTweaks/pfUI/MH3 cache 重新导入污染弱先验
    mobdb._migrated = true
    mobdb._ver = DB_VERSION
end

-- ═══════════════════════════════════════════════════════════════
-- 调试/手动维护命令:组队污染或数据异常时可手动清库
--   /dfhp        查看已学习怪物数
--   /dfhp reset  清空估算库
-- ═══════════════════════════════════════════════════════════════
SLASH_DFHP1 = "/dfhp"
SlashCmdList["DFHP"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "reset" then
        lib:ResetDB()
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99DFUI libhealth|r: 血量估算库已清空。")
    else
        local n = 0
        for k, v in pairs(mobdb) do
            if type(k) == "string" and string.sub(k, 1, 1) ~= "_" and type(v) == "table" then
                n = n + 1
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99DFUI libhealth|r: 已学习 " .. n .. " 个怪物。输入 /dfhp reset 清空。")
    end
end
