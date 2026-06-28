----------------------------------------------------------------------
-- DFUI.Assist  --  公会战斗播报（"吃席通报"）
-- 移植自 nanamiQT Hardcore.lua "Feature 8: Guild Combat Alert"。
-- 去掉 isHardcore 门控、剥离 mobAttackers/survSpellData 依赖：
--   危险血量(20%/10%) / 阵亡 / 脱险 自动往公会发段子式播报。
-- 单开关 guildCombatAlert 控整套；guildSimMode 开=只本地预览不发公会。
-- Lua 5.0 / WoW 1.12：用 table.getn，OnEvent 靠全局 event/arg1。
----------------------------------------------------------------------

local L = DFUI.Assist.L

----------------------------------------------------------------------
-- 播报模板（中文段子原汁原味来自 NQT；其余客户端用英文）
--   a20/a10/surv : string.format(t, 玩家名, 区域, 凶手, 血量整数%)
--   epitaph      : 阵亡墓志铭随机一条
--   deathHead    : (玩家名, 区域, 墓志铭)
--   deathStat    : (凶手, 战斗秒数, 最低血量整数%)
--   deathWarn    : (区域, 凶手)
----------------------------------------------------------------------
local T
do
    local loc = GetLocale()
    if loc == "zhCN" or loc == "zhTW" then
        T = {
            a20 = {
                "[HC] 救命！%s 在[%s]被[%s]追着锤！只剩%d%%血了！这怪是不是吃了炫迈停不下来！",
                "[HC] 紧急播报！%s 在[%s]正被[%s]花式暴打中！血量%d%%！麻烦哪位路过的大佬拉一手！",
                "[HC] 各位！%s 在[%s]翻车了！被[%s]打得只剩%d%%血！我觉得这波可能要寄！",
                "[HC] %s 在[%s]对[%s]说：你打我可以别打脸！然而现在只剩%d%%血了...",
                "[HC] 惊！%s 在[%s]遭遇[%s]！血量骤降至%d%%！本以为我能行，结果是我膨胀了！",
            },
            a10 = {
                "[HC] ...%s 在[%s]被[%s]打到只剩%d%%血了...如果我没了请帮我把号删了别让人看到装备...",
                "[HC] 告别了...%s 的硬核之旅恐怕要在[%s]终结于[%s]之手...%d%%血...风萧萧兮易水寒...",
                "[HC] %s 绝笔：我在[%s]面对[%s]仅剩%d%%血...练了这么久要白瞎了...出师未捷身先死...",
                "[HC] 别等我了...%s 在[%s]被[%s]锤到%d%%血...请帮我告诉新号的自己别再来这了...",
                "[HC] %s 在[%s]被[%s]按在地上摩擦...%d%%血...妈妈我想回家...",
            },
            surv = {
                "[HC] 就这？%s 在[%s]轻松拿捏[%s]！血量%d%%，硬核就是这么稳！",
                "[HC] %s 从[%s]归来！[%s]不过如此！血量%d%%，还能再战三百回合！",
                "[HC] 别慌，%s 已在[%s]优雅地解决了[%s]！血量%d%%，这才是硬核的正确打开方式！",
                "[HC] 小场面！%s 在[%s]遇到[%s]？血量%d%%，完全不慌！打完还顺便跳了个舞！",
                "[HC] %s 提醒各位：[%s]的[%s]就是个弟弟！血量%d%%，稳如泰山！",
            },
            epitaph = {
                "一路走好...你的传说将被铭记。",
                "又一位勇士倒下了...硬核之路从来不温柔。",
                "愿你在灵魂医者身边安息...哦等等，硬核没有复活。",
                "有些路，走着走着就没了。比如你的血条。",
                "你用生命证明了一件事：这个怪确实能打死人。",
            },
            deathHead   = "[HC] === %s 在[%s]阵亡了 === %s",
            deathStat   = "[HC] 凶手: [%s] | 战斗时长: %d秒 | 最低血量: %d%%",
            deathWarn   = "[HC] 提醒: [%s]的[%s]非常危险！请公会成员小心！",
            unknownMob  = "未知怪物",
            simPrefix   = "[公会模拟]",
        }
    else
        T = {
            a20 = {
                "[HC] HELP! %s is getting pummeled by [%s] in [%s] -- only %d%% HP left! Does this mob ever stop?!",
                "[HC] MAYDAY! %s is being beaten silly by [%s] in [%s]! %d%% HP! Any kind soul nearby, lend a hand!",
                "[HC] Folks! %s just wiped against [%s] in [%s] -- down to %d%% HP! This one might be over...",
                "[HC] %s tells [%s] in [%s]: hit me all you want, just not the face! ...and now it's %d%% HP.",
                "[HC] WHOA! %s ran into [%s] in [%s]! HP crashed to %d%%! Thought I had it -- I was wrong.",
            },
            a10 = {
                "[HC] ...%s is at %d%% HP vs [%s] in [%s]... if I don't make it, please delete the char so nobody sees the gear...",
                "[HC] Farewell... %s's hardcore run may end at the hands of [%s] in [%s]... %d%% HP... it's been an honor.",
                "[HC] %s's last words: %d%% HP against [%s] in [%s]... all that grind for nothing... gone too soon...",
                "[HC] Don't wait for me... %s hammered to %d%% by [%s] in [%s]... tell my next char never to come here...",
                "[HC] %s is face-down vs [%s] in [%s]... %d%% HP... mom, I want to go home...",
            },
            surv = {
                "[HC] That's it? %s handled [%s] in [%s] easy! %d%% HP -- this is how hardcore's done!",
                "[HC] %s returns from [%s]! [%s] was nothing! %d%% HP, ready for 300 more rounds!",
                "[HC] Relax, %s gracefully dealt with [%s] in [%s]! %d%% HP -- textbook hardcore!",
                "[HC] No big deal! %s met [%s] in [%s]? %d%% HP, didn't flinch -- did a /dance after!",
                "[HC] %s reminds everyone: [%s] in [%s] is a pushover! %d%% HP, steady as a rock!",
            },
            epitaph = {
                "Rest well... your legend will be remembered.",
                "Another hero falls... the hardcore road was never gentle.",
                "May you rest by the spirit healer... oh wait, no rez in hardcore.",
                "Some journeys just end. Like your health bar.",
                "You proved one thing with your life: yes, that mob can kill.",
            },
            deathHead   = "[HC] === %s has fallen in [%s] === %s",
            deathStat   = "[HC] Killer: [%s] | Fight: %ds | Lowest HP: %d%%",
            deathWarn   = "[HC] Heads up: [%s]'s [%s] is very dangerous -- guildies beware!",
            unknownMob  = "an unknown foe",
            simPrefix   = "[Guild Sim]",
        }
    end
end

----------------------------------------------------------------------
-- 运行时状态
----------------------------------------------------------------------
local S = {
    combatStartTime  = 0,
    combatMinHP      = 1.0,
    combatZone       = "",
    combatTargetName = "",
    alert20Fired     = false,
    alert10Fired     = false,
    deathProcessed   = false,
    queue            = {},
    queueTimer       = 0,
}

----------------------------------------------------------------------
-- 工具
----------------------------------------------------------------------
local function PickRandom(t)
    local n = table.getn(t)
    if n == 0 then return "" end
    return t[math.random(1, n)]
end

local function CurZone()
    return (S.combatZone ~= "" and S.combatZone) or (GetZoneText() or "?")
end

local function GetMob()
    if UnitExists("target") and UnitCanAttack("player", "target") then
        local n = UnitName("target")
        if n and n ~= "" then return n end
    end
    if S.combatTargetName ~= "" then return S.combatTargetName end
    return T.unknownMob
end

local function PlayerPctInt()
    local hp = UnitHealth("player") or 0
    local mx = UnitHealthMax("player") or 1
    if mx <= 0 then mx = 1 end
    local p = math.floor((hp / mx) * 100)
    if p < 1 then p = 1 end
    return p
end

----------------------------------------------------------------------
-- 发送：sim 模式本地预览 / 真发公会（转义 % 与 |，无公会静默）
----------------------------------------------------------------------
local function Send(msg)
    if not msg then return end
    if DFUI.Assist:IsEnabled("guildSimMode") then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffFFD100" .. T.simPrefix .. "|r " .. msg)
        end
        return
    end
    if not IsInGuild() then return end
    local safe = string.gsub(msg, "%%", "％")
    safe = string.gsub(safe, "|", "")
    SendChatMessage(safe, "GUILD")
end

local function Queue(msg)
    if not S.queue[1] then S.queueTimer = 1.5 end   -- 队列空时立即放行第一条
    table.insert(S.queue, msg)
end

----------------------------------------------------------------------
-- 各类播报生成
----------------------------------------------------------------------
local function FireAlert20()
    local mob = GetMob()
    S.combatTargetName = mob
    Queue(string.format(PickRandom(T.a20), UnitName("player") or "?", CurZone(), mob, PlayerPctInt()))
end

local function FireAlert10()
    local mob = GetMob()
    S.combatTargetName = mob
    Queue(string.format(PickRandom(T.a10), UnitName("player") or "?", CurZone(), mob, PlayerPctInt()))
end

local function FireSurvive()
    local mob = (S.combatTargetName ~= "" and S.combatTargetName) or GetMob()
    Queue(string.format(PickRandom(T.surv), UnitName("player") or "?", CurZone(), mob, PlayerPctInt()))
end

local function FireDeath()
    local mob = GetMob()
    local dur = 0
    if S.combatStartTime > 0 then dur = math.floor(GetTime() - S.combatStartTime) end
    local minPct = math.floor((S.combatMinHP or 0) * 100)
    Queue(string.format(T.deathHead, UnitName("player") or "?", CurZone(), PickRandom(T.epitaph)))
    Queue(string.format(T.deathStat, mob, dur, minPct))
    Queue(string.format(T.deathWarn, CurZone(), mob))
end

----------------------------------------------------------------------
-- 主模块：危险血量 / 阵亡 / 脱险 + 1.5s 限流队列
----------------------------------------------------------------------
DFUI.Assist:register({
    key   = "guildCombatAlert",
    title = L["guildCombatAlert"],
    desc  = L["guildCombatAlertDesc"],
    default = false,
    events = {
        -- 开战：重置全部一次性标志，记录区域与初始目标
        PLAYER_REGEN_DISABLED = function(self)
            S.combatStartTime = GetTime()
            S.alert20Fired    = false
            S.alert10Fired    = false
            S.deathProcessed  = false
            S.combatMinHP     = 1.0
            S.combatZone      = GetZoneText() or "?"
            if UnitExists("target") and UnitCanAttack("player", "target") then
                S.combatTargetName = UnitName("target") or ""
            else
                S.combatTargetName = ""
            end
        end,
        -- 战斗中血量穿过 20% / 10% 各触发一次，实时记录最低血
        UNIT_HEALTH = function(self)
            if arg1 ~= "player" then return end
            if S.combatStartTime <= 0 then return end
            local hp = UnitHealth("player") or 0
            local mx = UnitHealthMax("player") or 1
            if mx <= 0 then return end
            local pct = hp / mx
            if pct <= 0 then return end
            if pct < S.combatMinHP then S.combatMinHP = pct end
            if pct <= 0.20 and not S.alert20Fired then
                S.alert20Fired = true
                FireAlert20()
            end
            if pct <= 0.10 and not S.alert10Fired then
                S.alert10Fired = true
                FireAlert10()
            end
        end,
        -- 脱战：曾低于 20%、没死、且回血 >80% → 凡尔赛脱险播报，再清战斗计时
        PLAYER_REGEN_ENABLED = function(self)
            if S.alert20Fired and not S.deathProcessed and not UnitIsDeadOrGhost("player") then
                local hp = UnitHealth("player") or 0
                local mx = UnitHealthMax("player") or 1
                if mx > 0 and (hp / mx) > 0.80 then
                    FireSurvive()
                end
            end
            S.combatStartTime = 0
        end,
        -- 阵亡：PLAYER_DEAD 先于脱战触发，故此时 combatStartTime 仍有效
        PLAYER_DEAD = function(self)
            if not S.deathProcessed then
                S.deathProcessed = true
                FireDeath()
            end
        end,
    },
    onUpdate = function(self, dt)
        if not S.queue[1] then return end
        S.queueTimer = S.queueTimer + (dt or 0)
        if S.queueTimer >= 1.5 then
            S.queueTimer = 0
            local msg = S.queue[1]
            table.remove(S.queue, 1)
            Send(msg)
        end
    end,
})

----------------------------------------------------------------------
-- 模拟模式纯开关（无事件，仅供 Send 读 IsEnabled 判断）
----------------------------------------------------------------------
DFUI.Assist:register({
    key   = "guildSimMode",
    title = L["guildSimMode"],
    desc  = L["guildSimModeDesc"],
    default = false,
})

----------------------------------------------------------------------
-- 测试命令：/dfgb 把四类样例丢进队列，配合模拟模式在聊天框预览
----------------------------------------------------------------------
_G["SLASH_DFGB1"] = "/dfgb"
_G.SlashCmdList["DFGB"] = function()
    if not DFUI.Assist:IsEnabled("guildCombatAlert") then
        DFUI.Assist.Print(L["gbTestOff"])
        return
    end
    -- 暂存真实战斗状态，跑完即恢复：避免战斗中测试污染最低血/计时/凶手追踪。
    -- Fire 函数同步 string.format 把文本固化入队，故恢复 S 不影响已入队消息。
    local oStart, oMin, oZone, oMob = S.combatStartTime, S.combatMinHP, S.combatZone, S.combatTargetName
    S.combatStartTime = GetTime() - 12   -- 假装打了 12 秒
    S.combatMinHP     = 0.07
    S.combatZone      = GetZoneText() or "?"
    FireAlert20()
    FireAlert10()
    FireDeath()
    FireSurvive()
    S.combatStartTime, S.combatMinHP, S.combatZone, S.combatTargetName = oStart, oMin, oZone, oMob
    DFUI.Assist.Print(L["gbTestOn"])
end
