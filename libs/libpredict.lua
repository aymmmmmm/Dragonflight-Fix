-- ═══════════════════════════════════════════════════════════════
-- libpredict - 治疗预读库 (DFUI 移植版)
-- 来源: pfUI libs/libpredict.lua / credit to shagu
--
-- 机制: 缓存每个法术(按等级)上一次的实测治疗量; 施法开始时按缓存值
--       本地记账并广播。换装/加天赋会给缓存打脏标记, 下次施放重新学习。
--       好处是零维护, 自动适配 Turtle 改过的数值。
--
-- 协议: 兼容全服事实标准 HealComm (vanilla legacy 格式), prefix "HealComm"
--
-- 注意: 本版不做 HoT 追踪(DFUI 的 auras 模块已负责 buff 计时), 也不做
--       复活的 UI 显示, 但保留复活消息的接收记账以维持协议兼容。
-- ═══════════════════════════════════════════════════════════════
-- ⚠ 与其他 libs 一致, 本文件不做 setfenv, 直接跑在真正的 _G。
-- 这不是风格问题而是必需: 下面要替换 CastSpell/CastSpellByName/UseAction 三个
-- 全局函数, 若在 setfenv 环境里赋值, 只会写进 DFUI.env 表, 真正的全局函数
-- 根本不会被 hook 到, 施法记录会静默失效。
DFUI_Libs = DFUI_Libs or {}

-- 防重复加载 (1.12 /reload 不销毁 frame)
if DFUI_Libs.libpredict then return end

local heals, ress = {}, {}
local spell_queue = { "DUMMY", "DUMMYRank 9", "TARGET" }
local realm = GetRealmName()
local player = UnitName("player")
local cache = {}
local gear_string = ""

-- cmatch: 战斗日志格式串匹配, 把 %s/%d (含 %1$s 索引形式) 转成捕获组
-- 基于 libdebuff.lua:9, 但 %d 用 (%d+) 而不是 (.+):
-- 治疗量必须精确提取成数字, 用贪婪的 (.+) 在某些格式串下会把数字连同后缀一起吃进来。
-- (替换串里要写 "(%%d+)" 才能产出字面的 (%d+))
local function cmatch(str, pattern)
    if not str or not pattern then return end
    local pat = string.gsub(pattern, "%%%d?%$?s", "(.+)")
    pat = string.gsub(pat, "%%%d?%$?d", "(%%d+)")
    local a1, _, a3, a4, a5 = string.find(str, pat)
    if a1 then return a3, a4, a5 end
end

-- SplitMsg: 1.12 没有 strsplit, 这里做保留空段的精确切分
local function SplitMsg(str, sep)
    local out, pos = {}, 1
    while true do
        local s, e = string.find(str, sep, pos, true)
        if not s then
            table.insert(out, string.sub(str, pos))
            break
        end
        table.insert(out, string.sub(str, pos, s - 1))
        pos = e + 1
    end
    return out
end

-- 治疗祷言: 群疗, 需要对全小队分别记账
local PRAYER_OF_HEALING
do
    local locales = {
        ["deDE"] = "Gebet der Heilung",
        ["enUS"] = "Prayer of Healing",
        ["esES"] = "Rezo de curación",
        ["frFR"] = "Prière de soins",
        ["koKR"] = "치유의 기원",
        ["ruRU"] = "Молитва исцеления",
        ["zhCN"] = "治疗祷言",
    }
    PRAYER_OF_HEALING = locales[GetLocale()] or locales["enUS"]
end

local libpredict = CreateFrame("Frame", "DFUI_HealPredict", UIParent)

-- ═══ 接收端 ═══

libpredict:RegisterEvent("CHAT_MSG_ADDON")
libpredict:RegisterEvent("UNIT_HEALTH")
libpredict:SetScript("OnEvent", function()
    if event == "CHAT_MSG_ADDON" and (arg1 == "HealComm" or arg1 == "CTRA") then
        libpredict:ParseChatMessage(arg4, arg2, arg1)
    elseif event == "UNIT_HEALTH" then
        -- 复活目标活过来了就清掉复活记账
        local name = UnitName(arg1)
        if name and ress[name] and not UnitIsDeadOrGhost(arg1) then
            ress[name] = nil
        end
    end
end)

function libpredict:ParseComm(sender, msg)
    local msgtype, target, heal, time

    if msg == "Healstop" or msg == "GrpHealstop" then
        msgtype = "Stop"
    elseif msg == "Resurrection/stop/" then
        msgtype = "RessStop"
    elseif msg then
        local o = SplitMsg(msg, "/")
        if o and o[1] and o[2] then
            if o[1] == "GrpHealdelay" or o[1] == "Healdelay" then
                msgtype, time = "Delay", o[2]
            end

            if o[1] == "Resurrection" and o[2] ~= "" then
                msgtype, target = "Ress", o[2]
            end

            if o[1] == "Heal" and o[2] ~= "" then
                msgtype, target, heal, time = "Heal", o[2], o[3], o[4]
            end

            if o[1] == "GrpHeal" and o[2] ~= "" then
                msgtype, target, heal, time = "Heal", {}, o[2], o[3]
                for i = 4, 8 do
                    if o[i] and o[i] ~= "" then table.insert(target, o[i]) end
                end
            end

            -- Reju/Renew/Regr 是 HoT 消息, 本版不追踪 HoT, 忽略之
            -- (不能落到上面任何分支, 否则会被误当成直接治疗)
        end
    end

    return msgtype, target, heal, time
end

function libpredict:ParseChatMessage(sender, msg, comm)
    local msgtype, target, heal, time

    if comm == "HealComm" then
        msgtype, target, heal, time = libpredict:ParseComm(sender, msg)
    elseif comm == "CTRA" then
        local _, _, cmd, ctratarget = string.find(msg, "(%a+)%s?([^#]*)")
        if cmd and ctratarget and cmd == "RES" and ctratarget ~= "" and ctratarget ~= UNKNOWN then
            msgtype = "Ress"
            target = ctratarget
        end
    end

    if msgtype == "Stop" and sender then
        libpredict:HealStop(sender)
        return
    elseif (msgtype == "RessStop" or msg == "RESNO") and sender then
        libpredict:RessStop(sender)
        return
    elseif msgtype == "Delay" and time then
        libpredict:HealDelay(sender, time)
    elseif msgtype == "Heal" and target and heal and time then
        if type(target) == "table" then
            for _, name in pairs(target) do
                libpredict:Heal(sender, name, heal, time)
            end
        else
            libpredict:Heal(sender, target, heal, time)
        end
    elseif msgtype == "Ress" then
        libpredict:Ress(sender, target)
    end
end

-- ═══ 记账 API ═══

function libpredict:Heal(sender, target, amount, duration)
    if not sender or not target or not amount or not duration then return end
    amount = tonumber(amount)
    duration = tonumber(duration)
    if not amount or not duration then return end

    heals[target] = heals[target] or {}
    heals[target][sender] = { amount, duration / 1000 + GetTime() }

    -- 唤醒轮询器 (它在没有任何预读时会自己睡掉)
    if self.OnHealAdded then self.OnHealAdded() end
end

function libpredict:HealStop(sender)
    for target in pairs(heals) do
        if heals[target][sender] then heals[target][sender] = nil end
    end
end

function libpredict:HealDelay(sender, delay)
    delay = tonumber(delay)
    if not delay then return end
    delay = delay / 1000
    for target in pairs(heals) do
        local entry = heals[target][sender]
        if entry then entry[2] = entry[2] + delay end
    end
end

function libpredict:Ress(sender, target)
    if not sender or not target then return end
    ress[target] = ress[target] or {}
    ress[target][sender] = true
end

function libpredict:RessStop(sender)
    for target in pairs(ress) do
        if ress[target][sender] then ress[target][sender] = nil end
    end
end

-- ═══ 公共查询 API ═══
-- 注意: 内部按 UnitName 索引, 且顺手清理过期条目 —— 设计上就是给轮询用的

function libpredict:UnitGetIncomingHeals(unit)
    if not unit or not UnitName(unit) then return 0 end
    if UnitIsDeadOrGhost(unit) then return 0 end
    local name = UnitName(unit)

    local sumheal = 0
    if not heals[name] then return sumheal end

    local now = GetTime()
    for sender, entry in pairs(heals[name]) do
        if entry[2] <= now then
            heals[name][sender] = nil
        else
            sumheal = sumheal + entry[1]
        end
    end
    return sumheal
end

function libpredict:UnitHasIncomingResurrection(unit)
    if not unit or not UnitName(unit) then return nil end
    local name = UnitName(unit)
    if not ress[name] then return nil end

    for _, val in pairs(ress[name]) do
        if val == true then return true end
    end
    return nil
end

-- Sweep: 真删过期条目并清掉空壳表, 让 HasAny 可信
-- (pfUI 原版的 events 表只是把时间戳清空, 从不真删 heals 条目, 是无效代码)
function libpredict:Sweep()
    local now = GetTime()
    for name, senders in pairs(heals) do
        local any = false
        for s, rec in pairs(senders) do
            if rec[2] <= now then
                senders[s] = nil
            else
                any = true
            end
        end
        if not any then heals[name] = nil end
    end
end

-- 还有没有任何预读在途 —— 轮询器靠它决定是否休眠
function libpredict:HasAny()
    return next(heals) ~= nil
end

-- ═══ 治疗量缓存 (实测学习) ═══

local function UpdateCache(spell, heal, crit)
    heal = heal and tonumber(heal)
    if not spell or not heal then return end

    if not cache[spell] or cache[spell][2] then
        -- 技能或装备变过, 先把当前测到的值存下来
        cache[spell] = cache[spell] or {}
        cache[spell][1] = crit and heal * 2 / 3 or heal
        cache[spell][2] = crit
    elseif not crit and cache[spell][1] < heal then
        -- 保留能拿到的最好的一次非暴击值
        cache[spell][1] = heal
        cache[spell][2] = nil
    end
end

local resetcache = CreateFrame("Frame")
resetcache:RegisterEvent("PLAYER_ENTERING_WORLD")
resetcache:RegisterEvent("LEARNED_SPELL_IN_TAB")
resetcache:RegisterEvent("CHARACTER_POINTS_CHANGED")
resetcache:RegisterEvent("UNIT_INVENTORY_CHANGED")
resetcache:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        -- 此时 UnitName/GetRealmName 才保证可用, 刷新一次
        realm = GetRealmName()
        player = UnitName("player")

        -- setfenv 模块的 SavedVariable 必须经 _G 读写, 否则不落盘
        _G.DFUI_PredictDB = _G.DFUI_PredictDB or {}
        _G.DFUI_PredictDB[realm] = _G.DFUI_PredictDB[realm] or {}
        _G.DFUI_PredictDB[realm][player] = _G.DFUI_PredictDB[realm][player] or {}
        _G.DFUI_PredictDB[realm][player].heals = _G.DFUI_PredictDB[realm][player].heals or {}
        cache = _G.DFUI_PredictDB[realm][player].heals
    end

    -- 原版 pfUI 这里写成 `event == "X" or "Y"` (后半恒真), 是个 bug, 这里修正
    if event == "UNIT_INVENTORY_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        if arg1 and arg1 ~= "player" then return end

        local gear = ""
        for id = 1, 18 do
            gear = gear .. (GetInventoryItemLink("player", id) or "")
        end

        -- 装备没真的变就别清缓存
        if gear == gear_string then return end
        gear_string = gear
    end

    -- 给所有缓存打脏标记, 下次施放时重新学习
    for k in pairs(cache) do
        if type(cache[k]) ~= "table" then
            cache[k] = { cache[k] }
        end
        cache[k][2] = true
    end
end)

-- ═══ 发送端 ═══

libpredict.sender = CreateFrame("Frame", "DFUI_HealPredictSender", UIParent)
libpredict.sender.enabled = true

local BG_ZONES = {
    ["Warsong Gulch"] = true, ["Arathi Basin"] = true, ["Alterac Valley"] = true,
    ["战歌峡谷"] = true, ["阿拉希盆地"] = true, ["奥特兰克山谷"] = true,
}

libpredict.sender.SendHealCommMsg = function(self, msg)
    -- 三档互斥: 同一条消息只投递一次。原版 pfUI 无条件同时发 RAID+BATTLEGROUND,
    -- 会让战场里的人收到两份、重复计数。
    if BG_ZONES[GetRealZoneText() or ""] then
        SendAddonMessage("HealComm", msg, "BATTLEGROUND")
    elseif GetNumRaidMembers() > 0 then
        SendAddonMessage("HealComm", msg, "RAID")
    elseif GetNumPartyMembers() > 0 then
        -- 现存实现(pfUI/ShaguTweaks/EGD/HealComm)都漏了 PARTY 这一档,
        -- 导致 5 人小队里预读根本发不出去
        SendAddonMessage("HealComm", msg, "PARTY")
    end
end

-- 施法入口 hook: 记录"正在施放哪个法术、对谁"
-- 用直接替换全局函数的范式(同 libdebuff.lua:284), 不用 DFUI 环境里的 hooksecurefunc
local function QueueSpell(effect, rank, target)
    if not effect then return end
    spell_queue[1] = effect
    spell_queue[2] = effect .. (rank or "")
    spell_queue[3] = target
end

local function DefaultTarget()
    return UnitName("target") and UnitCanAssist("player", "target") and UnitName("target")
        or UnitName("player")
end

local origCastSpell = CastSpell
CastSpell = function(id, bookType)
    origCastSpell(id, bookType)
    if not libpredict.sender.enabled then return end
    local effect, rank = DFUI_Libs.libspell:GetSpellInfo(id, bookType)
    QueueSpell(effect, rank, DefaultTarget())
end

local origCastSpellByName = CastSpellByName
CastSpellByName = function(spellName, target)
    origCastSpellByName(spellName, target)
    if not libpredict.sender.enabled then return end
    local effect, rank = DFUI_Libs.libspell:GetSpellInfo(spellName)

    -- target 参数可能是 unitID 字符串, 也可能是 true/1 表示自己
    local resolved
    if target and type(target) == "string" then
        resolved = UnitName(target)
    elseif target == true or target == 1 then
        resolved = UnitName("player")
    end

    QueueSpell(effect, rank, resolved or DefaultTarget())
end

local scanner = DFUI_Libs.libtipscan:GetScanner("prediction")
local origUseAction = UseAction
UseAction = function(slot, target, selfcast)
    origUseAction(slot, target, selfcast)
    if not libpredict.sender.enabled then return end
    if GetActionText(slot) or not IsCurrentAction(slot) then return end
    scanner:SetAction(slot)
    local effect, rank = scanner:GetLine(1)
    QueueSpell(effect, rank, selfcast and UnitName("player") or DefaultTarget())
end

libpredict.sender:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
libpredict.sender:RegisterEvent("SPELLCAST_START")
libpredict.sender:RegisterEvent("SPELLCAST_STOP")
libpredict.sender:RegisterEvent("SPELLCAST_FAILED")
libpredict.sender:RegisterEvent("SPELLCAST_INTERRUPTED")
libpredict.sender:RegisterEvent("SPELLCAST_DELAYED")

libpredict.sender:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SPELL_SELF_BUFF" then
        -- 从战斗日志回填真实治疗量
        local spell, _, heal = cmatch(arg1, HEALEDSELFOTHER)   -- 你的 %s 治疗 %s %d 点
        if spell and heal then
            if spell == spell_queue[1] then UpdateCache(spell_queue[2], heal) end
            return
        end

        local spell2, heal2 = cmatch(arg1, HEALEDSELFSELF)     -- 你的 %s 治疗你 %d 点
        if spell2 and heal2 then
            if spell2 == spell_queue[1] then UpdateCache(spell_queue[2], heal2) end
            return
        end

        local spell3, _, heal3 = cmatch(arg1, HEALEDCRITSELFOTHER)
        if spell3 and heal3 then
            if spell3 == spell_queue[1] then UpdateCache(spell_queue[2], heal3, true) end
            return
        end

        local spell4, heal4 = cmatch(arg1, HEALEDCRITSELFSELF)
        if spell4 and heal4 then
            if spell4 == spell_queue[1] then UpdateCache(spell_queue[2], heal4, true) end
            return
        end

    elseif event == "SPELLCAST_START" then
        local spell, casttime = arg1, arg2
        if spell_queue[1] ~= spell or not cache[spell_queue[2]] then return end

        local amount = math.floor(cache[spell_queue[2]][1] or 0)
        if amount <= 0 then return end

        local target = spell_queue[3]

        if spell == PRAYER_OF_HEALING then
            -- 群疗: 对射程内的每个小队成员各记一笔
            target = player
            for i = 1, 4 do
                local unit = "party" .. i
                if UnitExists(unit) and CheckInteractDistance(unit, 4) then
                    local pname = UnitName(unit)
                    if pname then
                        libpredict:Heal(player, pname, amount, casttime)
                        libpredict.sender:SendHealCommMsg("Heal/" .. pname .. "/" .. amount .. "/" .. casttime .. "/")
                    end
                end
            end
        end

        if target then
            libpredict:Heal(player, target, amount, casttime)
            libpredict.sender:SendHealCommMsg("Heal/" .. target .. "/" .. amount .. "/" .. casttime .. "/")
            libpredict.sender.healing = true
        end

    elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        if libpredict.sender.healing then
            libpredict:HealStop(player)
            -- 注意: 协议里停止消息是 "Healstop"(小写 s)。pfUI 发的是 "HealStop",
            -- 与它自己的解析端不一致, 别人收不到 —— 这里按协议标准发。
            libpredict.sender:SendHealCommMsg("Healstop")
            libpredict.sender.healing = nil
        end

    elseif event == "SPELLCAST_DELAYED" then
        if libpredict.sender.healing then
            libpredict:HealDelay(player, arg1)
            libpredict.sender:SendHealCommMsg("Healdelay/" .. arg1 .. "/")
        end

    elseif event == "SPELLCAST_STOP" then
        -- 施法结束, 治疗已落地, 停止预读
        libpredict:HealStop(player)
        libpredict.sender.healing = nil
    end
end)

-- ═══ 发送端仲裁 ═══
-- 客户端里可能已经有别的插件在广播 HealComm 消息(!Libs 的 HealComm-1.0 几乎恒在)。
-- 重复广播会让别人的客户端重复计数, 所以检测到就退化成"纯接收 + 绘制"。

function libpredict:ArbitrateSender()
    local other =
        (AceLibrary and AceLibrary.HasInstance and AceLibrary:HasInstance("HealComm-1.0") and "HealComm-1.0")
        or (ShaguTweaks and ShaguTweaks.libpredict and "ShaguTweaks")
        or (pfUI and pfUI.api and pfUI.api.libpredict and "pfUI")
        or (EGD_LibPredict and "EGD")

    if not other then return nil end

    self.sender:UnregisterAllEvents()
    self.sender.enabled = nil

    -- 单人时 SendAddonMessage 到 RAID/PARTY 不会发出去, 自己也收不到,
    -- 所以要把对方的消息回环给自己解析, 否则独自一人时看不到自己的预读。
    -- (组队/团队时自己能收到自己的广播, 不需要回环)
    if other == "HealComm-1.0" and AceLibrary then
        local HealComm = AceLibrary("HealComm-1.0")
        if HealComm and HealComm.SendAddonMessage and not HealComm.dfuiLoopback then
            local origSend = HealComm.SendAddonMessage
            HealComm.SendAddonMessage = function(hcSelf, msg)
                if not UnitInRaid("player") and GetNumPartyMembers() < 1 then
                    libpredict:ParseChatMessage(UnitName("player"), msg, "HealComm")
                end
                return origSend(hcSelf, msg)
            end
            HealComm.dfuiLoopback = true
        end
    end

    return other
end

local arbiter = CreateFrame("Frame")
arbiter:RegisterEvent("PLAYER_LOGIN")
arbiter:SetScript("OnEvent", function()
    libpredict.activeSender = libpredict:ArbitrateSender()
    arbiter:UnregisterAllEvents()
end)

DFUI_Libs.libpredict = libpredict
