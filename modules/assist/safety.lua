----------------------------------------------------------------------
-- DFUI.Assist  --  安全模块（呼吸 / 血量 / 精英目标 / 区域危险）
-- 逻辑参考 Hardcore.lua，但去掉 isHardcore 门控：改为每功能
-- 独立开关，任何角色都能用作安全提醒。UI 精简：共用 Core 红屏脉冲，
-- 呼吸沿用游戏原生 MirrorTimer 条，只追加阈值警报。
----------------------------------------------------------------------

local L = DFUI.Assist.L

----------------------------------------------------------------------
-- 区域推荐等级表（英文区域名，源自 Hardcore.lua HC_ZONE_LEVELS）
----------------------------------------------------------------------
-- 区域推荐等级表（中英双语 key，兼容中/英文客户端 GetZoneText）
local ZONE = {}
do
    local list = {
        { "Dun Morogh", "丹莫罗", 1, 12 },
        { "Elwynn Forest", "艾尔文森林", 1, 12 },
        { "Tirisfal Glades", "提瑞斯法林地", 1, 12 },
        { "Westfall", "西部荒野", 10, 20 },
        { "Loch Modan", "洛克莫丹", 10, 20 },
        { "Silverpine Forest", "银松森林", 10, 20 },
        { "Darkshore", "黑海岸", 10, 20 },
        { "Redridge Mountains", "赤脊山", 15, 25 },
        { "Duskwood", "暮色森林", 18, 30 },
        { "Hillsbrad Foothills", "希尔斯布莱德丘陵", 20, 30 },
        { "Wetlands", "湿地", 20, 30 },
        { "Ashenvale", "灰谷", 18, 30 },
        { "Stonetalon Mountains", "石爪山脉", 15, 27 },
        { "Thousand Needles", "千针石林", 25, 35 },
        { "Alterac Mountains", "奥特兰克山脉", 30, 40 },
        { "Arathi Highlands", "阿拉希高地", 30, 40 },
        { "Desolace", "凄凉之地", 30, 40 },
        { "Stranglethorn Vale", "荆棘谷", 30, 45 },
        { "Badlands", "荒芜之地", 35, 45 },
        { "Swamp of Sorrows", "悲伤沼泽", 35, 45 },
        { "Dustwallow Marsh", "尘泥沼泽", 35, 45 },
        { "The Hinterlands", "辛特兰", 40, 50 },
        { "Feralas", "菲拉斯", 40, 50 },
        { "Tanaris", "塔纳利斯", 40, 50 },
        { "Searing Gorge", "灼热峡谷", 43, 50 },
        { "Azshara", "艾萨拉", 45, 55 },
        { "Blasted Lands", "诅咒之地", 45, 55 },
        { "Un'Goro Crater", "安戈洛环形山", 48, 55 },
        { "Felwood", "费伍德森林", 48, 55 },
        { "Burning Steppes", "燃烧平原", 50, 58 },
        { "Western Plaguelands", "西部瘟疫之地", 51, 58 },
        { "Eastern Plaguelands", "东部瘟疫之地", 53, 60 },
        { "Winterspring", "冬泉谷", 53, 60 },
        { "Deadwind Pass", "逆风小径", 55, 60 },
        { "Silithus", "希利苏斯", 55, 60 },
        -- Kalimdor
        { "Durotar", "杜隆塔尔", 1, 12 },
        { "Mulgore", "莫高雷", 1, 12 },
        { "Teldrassil", "泰达希尔", 1, 12 },
        { "The Barrens", "贫瘠之地", 10, 25 },
    }
    for i = 1, table.getn(list) do
        local z = list[i]
        local info = { min = z[3], max = z[4] }
        ZONE[z[1]] = info
        ZONE[z[2]] = info
    end
end

----------------------------------------------------------------------
-- 血量报警：自身 40% 警告 / 25% 危急(持续红屏)
----------------------------------------------------------------------
local hp = { crit = false, last40 = 0 }

DFUI.Assist:register({
    key = "safeHealth",
    title = L["safeHealth"],
    desc = L["safeHealthDesc"],
    default = true,
    events = {
        UNIT_HEALTH = function(self)
            if arg1 ~= "player" then return end
            local cur = UnitHealth("player")
            local max = UnitHealthMax("player")
            if not max or max <= 0 then return end
            local pct = cur / max

            if pct > 0.40 then
                if hp.crit then hp.crit = false; DFUI.Assist.SetDangerFlash("health", false) end
            elseif pct <= 0.25 then
                if not hp.crit then
                    hp.crit = true
                    DFUI.Assist.Alert(L["aHP25"], 1, 0.1, 0.1, "critical")
                    DFUI.Assist.SetDangerFlash("health", true)
                end
            else
                -- 25% < pct <= 40%
                local now = GetTime()
                if now - hp.last40 > 5 then
                    hp.last40 = now
                    DFUI.Assist.Alert(L["aHP40"], 1, 0.2, 0.2, "warning")
                end
                if hp.crit then hp.crit = false; DFUI.Assist.SetDangerFlash("health", false) end
            end
        end,
        PLAYER_DEAD = function(self)
            hp.crit = false
            DFUI.Assist.SetDangerFlash("health", false)
        end,
    },
})

----------------------------------------------------------------------
-- 呼吸 / 溺水监控：原生 MirrorTimer + 50% 警告 / 33% 危急(红屏)
----------------------------------------------------------------------
local br = { active = false, val = 0, max = 1, scale = -1, elapsed = 0, half = false, crit = false, critT = 0 }

DFUI.Assist:register({
    key = "safeBreath",
    title = L["safeBreath"],
    desc = L["safeBreathDesc"],
    default = true,
    events = {
        MIRROR_TIMER_START = function(self)
            if arg1 == "BREATH" then
                br.active = true
                br.val = arg2 or 0
                br.max = arg3 or 1
                br.scale = arg4 or -1
                br.half = false
                br.crit = false
                br.critT = 0
                br.elapsed = 0
            end
        end,
        MIRROR_TIMER_STOP = function(self)
            if arg1 == "BREATH" then
                br.active = false
                DFUI.Assist.SetDangerFlash("breath", false)
            end
        end,
    },
    onUpdate = function(self, dt)
        if not br.active then return end
        br.elapsed = br.elapsed + dt
        if br.elapsed < 0.1 then return end
        br.elapsed = 0

        br.val = br.val + (br.scale * 100)
        if br.val < 0 then br.val = 0 end
        if br.val > br.max then br.val = br.max end
        local pct = br.val / br.max

        if pct < 0.33 then
            if not br.crit then
                br.crit = true
                DFUI.Assist.Alert(L["aBreathCrit"], 1, 0.3, 0, "critical")
                DFUI.Assist.SetDangerFlash("breath", true)
            end
            br.critT = br.critT + 0.1
            if br.critT >= 2 then
                br.critT = 0
                if PlaySound then PlaySound("RaidWarning") end
            end
        elseif pct < 0.5 then
            if not br.half then
                br.half = true
                DFUI.Assist.Alert(L["aBreathHalf"], 1, 0.8, 0, "warning")
            end
            DFUI.Assist.SetDangerFlash("breath", false)
        else
            DFUI.Assist.SetDangerFlash("breath", false)
        end
    end,
})

----------------------------------------------------------------------
-- 精英 / 骷髅目标警告
----------------------------------------------------------------------
local lastElite = 0

DFUI.Assist:register({
    key = "safeElite",
    title = L["safeElite"],
    desc = L["safeEliteDesc"],
    default = true,
    events = {
        PLAYER_TARGET_CHANGED = function(self)
            if not UnitExists("target") then return end
            if not UnitCanAttack("player", "target") then return end

            local cls = UnitClassification("target")
            local lvl = UnitLevel("target")
            local skull = (lvl == -1)
            local dangerous = (cls == "elite" or cls == "worldboss"
                or cls == "rareelite" or cls == "rare")

            if skull or dangerous then
                local now = GetTime()
                if now - lastElite > 10 then
                    lastElite = now
                    local tag
                    if skull then tag = L["tagSkull"]
                    elseif cls == "worldboss" then tag = L["tagWorldboss"]
                    elseif cls == "rareelite" then tag = L["tagRareElite"]
                    elseif cls == "rare" then tag = L["tagRare"]
                    else tag = L["tagElite"] end
                    DFUI.Assist.Alert(
                        string.format(L["aEliteFmt"], UnitName("target") or "?", tag),
                        1, 0.5, 0, "warning")
                end
            end
        end,
    },
})

----------------------------------------------------------------------
-- 区域危险等级检查
----------------------------------------------------------------------
local lastZone = ""
local lastZoneAlert = 0

local function CheckZone()
    local zone = GetZoneText()
    if not zone or zone == "" or zone == lastZone then return end
    lastZone = zone

    local info = ZONE[zone]
    if not info then return end

    local lvl = UnitLevel("player") or 0
    if lvl < info.min then
        local now = GetTime()
        if now - lastZoneAlert < 10 then return end
        lastZoneAlert = now
        DFUI.Assist.Alert(
            string.format(L["aZoneFmt"], zone, info.min, info.max),
            1, 0.5, 0, "warning")
    end
end

DFUI.Assist:register({
    key = "safeZone",
    title = L["safeZone"],
    desc = L["safeZoneDesc"],
    default = true,
    events = {
        ZONE_CHANGED_NEW_AREA = function(self) CheckZone() end,
        ZONE_CHANGED          = function(self) CheckZone() end,
        PLAYER_ENTERING_WORLD = function(self) CheckZone() end,
    },
})
