-- ═══════════════════════════════════════════════════════════════
-- libabsorb - 护盾吸收量数据层 (DFUI)
--
-- 1.12 没有 UnitGetTotalAbsorbs, 服务端也不下发任何护盾剩余量。
-- 本库只做三件事, 全部是客户端推算:
--   1. 从 GlobalStrings 结构性地推导"打在你身上且带吸收量"的战斗日志模式
--   2. 刮 tooltip 拿护盾初始吸收量(通用规则, 不是白名单)
--   3. 实测校准: 护盾被打破时, 真实初始值 == 累计扣减量, 学下来覆盖估算
--
-- ⚠ 与其它 libs 一致, 本文件不做 setfenv, 直接跑在真正的 _G。
-- ═══════════════════════════════════════════════════════════════

local libabsorb = {}

local scanner = DFUI_Libs.libtipscan:GetScanner('libabsorb')

local zh = (GetLocale() == "zhCN")
-- tooltip / 战斗日志里判定"这是吸收"的关键词
local KEYWORDS = zh and {"吸收"} or {"absorb"}

-- ═══════════════════════════════════════════════════════════════
-- 一、吸收模式引擎
-- ═══════════════════════════════════════════════════════════════
--
-- 1.12 战斗日志的结构(已由 !Libs\ParserLib 与 ShaguDPS\parser-vanilla.lua 双向印证):
--
--   完整消息 = 基础串 + 若干"尾巴(trailer)"
--     "Wolf hits you for 50. (25 absorbed)"
--      └── COMBATHITOTHERSELF ──┘ └ ABSORB_TRAILER ┘
--
--   ⚠ 被吸收的数值【只存在于 ABSORB_TRAILER】, 基础串里没有。
--     ShaguDPS parser-vanilla.lua:418 正是先 gsub 掉 absorb/resist 尾巴再匹配基础串。
--     Nanami 试图从 COMBATHITSELFFILTERED 这类串里抠吸收量是走不通的
--     (ParserLib 全库无 FILTERED, 那些串在 1.12 根本不存在, 它的 TryAddGSPattern
--      遇 nil 静默跳过, 实际只剩裸正则回退在工作 —— 那正是它误判的根源)。
--
--   全局串命名 = <前缀><来源><目标>, 已由 ParserLib:1681-1695 的分类实证:
--     HitOtherSelf = {COMBATHITOTHERSELF, ...}   别人打我
--     HitSelf      = {COMBATHITSELFOTHER, ...}   我打别人
--   ⇒ 【目标是我 ⟺ 名字以 SELF 结尾】
--
-- 于是本引擎两步走:
--   步骤 1  ABSORB_TRAILER 抠数值 —— 唯一权威来源, 一条模式, 也是快速否决路径
--   步骤 2  剥掉所有尾巴后, 用"目标=我"的基础串确认这一下是打在我身上的
--
-- 步骤 2 让"怪打别人被吸收 500"这类日志在结构上就出不了数, 不需要脏兮兮的
-- 名字比对, 也不需要 Nanami 那种 `吸收了(%d+)` 裸回退。

local selfPatterns = {}  -- { {pat=, src=}, ... }  目标=我 且带伤害数值的基础串
local fullAbsorb = {}    -- { {pat=, src=}, ... }  目标=我 的"全部吸收"串(无数值)
local absorbTrailer = nil
local stripTrailers = {} -- 需要从消息里剥掉的尾巴模式
local built = false

local function EscapeLiteral(s)
    return (string.gsub(s, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

-- GlobalString 格式串 → Lua 模式。
-- 支持 %s/%d 与本地化的 %1$s/%2$d 两种写法(libdebuff.lua:7-15 同款处理)。
-- captureNums=false 时数字占位符不建捕获组, 只用于"是否命中"判定。
local function ToPattern(fmt, captureNums)
    local pat = ""
    local i, n = 1, string.len(fmt)
    local nd = 0
    while i <= n do
        if string.sub(fmt, i, i + 1) == "%%" then
            pat = pat .. "%%"                     -- 格式串里的 %% = 一个字面 %
            i = i + 2
        else
            local _, e, _, kind = string.find(fmt, "^%%(%d*)%$?([ds])", i)
            if e then
                if kind == "d" then
                    nd = nd + 1
                    pat = pat .. (captureNums and "(%d+)" or "%d+")
                else
                    pat = pat .. ".-"             -- 名字不需要捕获, 少建组少出错
                end
                i = e + 1
            else
                pat = pat .. EscapeLiteral(string.sub(fmt, i, i))
                i = i + 1
            end
        end
    end
    return pat, nd
end

local function HasKeyword(s)
    local low = string.lower(s)
    for k = 1, table.getn(KEYWORDS) do
        if string.find(low, KEYWORDS[k], 1, true) then return true end
    end
    return false
end

-- GlobalStrings 都是全大写名 + 含占位符; 加这两条免得把插件自己的全局串卷进来
local function LooksLikeGlobalString(name, value)
    if string.find(name, "%l") then return false end
    return string.find(value, "%", 1, true) and true or false
end

function libabsorb:BuildPatterns()
    if built then return end
    built = true
    selfPatterns, fullAbsorb, stripTrailers = {}, {}, {}

    -- ── 尾巴 ──
    local tnames = {"ABSORB_TRAILER", "RESIST_TRAILER", "BLOCK_TRAILER",
                    "VULNERABLE_TRAILER", "CRUSHING_TRAILER", "GLANCING_TRAILER"}
    for i = 1, table.getn(tnames) do
        local v = _G[tnames[i]]
        if type(v) == "string" and string.len(v) > 0 then
            local pat = ToPattern(v, false)
            table.insert(stripTrailers, pat)
            if tnames[i] == "ABSORB_TRAILER" then
                absorbTrailer = ToPattern(v, true)
            end
        end
    end
    -- 客户端缺 ABSORB_TRAILER 时的窄回退(仍然锚定括号, 不裸抓数字)
    if not absorbTrailer then
        absorbTrailer = zh and "（吸收了(%d+)点）" or "%((%d+) absorbed%)"
        table.insert(stripTrailers, zh and "（吸收了%d+点）" or " %(%d+ absorbed%)")
    end

    -- ── 基础串 ──
    for name, value in pairs(_G) do
        if type(name) == "string" and type(value) == "string"
            and string.len(value) > 0 and string.find(name, "SELF$")
            and LooksLikeGlobalString(name, value) then

            local pat, nd = ToPattern(value, false)
            pat = "^" .. pat .. "$"
            if nd > 0 then
                -- 带伤害数值 = 真的挨了打, 吸收量由尾巴给
                table.insert(selfPatterns, {pat = pat, src = name, fmt = value})
            elseif HasKeyword(value) then
                -- 无数值但说了"吸收" = 完全吸收, 客户端拿不到具体数
                table.insert(fullAbsorb, {pat = pat, src = name, fmt = value})
            end
        end
    end

    -- 具体优先: 串越长越具体, 首个命中即返回(不累加)
    local function bylen(a, b)
        local la, lb = string.len(a.pat), string.len(b.pat)
        if la ~= lb then return la > lb end
        return a.src < b.src
    end
    table.sort(selfPatterns, bylen)
    table.sort(fullAbsorb, bylen)
end

-- 学派: 不依赖捕获位置(各串占位符顺序不一), 直接在消息里找已知学派词。
-- 唯一命中才返回; 含糊或没有就 nil(nil = 物理/未知, 只有全学派盾能吃)。
local function DetectSchool(msg)
    local words = _G.DFUI_ShieldSchoolWords
    if not words then return nil end
    local found = nil
    for _, w in pairs(words) do
        if string.find(msg, w, 1, true) then
            if found and found ~= w then return nil end
            found = w
        end
    end
    return found
end

local function StripTrailers(msg)
    for i = 1, table.getn(stripTrailers) do
        msg = string.gsub(msg, stripTrailers[i], "")
    end
    return msg
end

local function MatchSelf(list, msg)
    for i = 1, table.getn(list) do
        if string.find(msg, list[i].pat) then return list[i].src end
    end
    return nil
end

-- → amount(number|nil), school(string|nil), src(string|nil)
--   amount 有值            → 可精确扣减
--   amount=nil 且 src 有值 → 确实被吸收了但客户端拿不到数字(完全吸收), 只置 uncertain
--   全 nil                 → 与护盾无关
function libabsorb:Parse(msg)
    if not msg then return nil end
    if not built then self:BuildPatterns() end

    -- 步骤 1: 没有吸收尾巴的消息占绝大多数, 一条模式先否决掉, 便宜
    local _, _, num = string.find(msg, absorbTrailer)
    local amount = tonumber(num)

    if amount and amount > 0 then
        -- 步骤 2: 剥尾巴后确认这一下是打在我身上的
        local src = MatchSelf(selfPatterns, StripTrailers(msg))
        if src then return amount, DetectSchool(msg), src end
        return nil                        -- 打在别人身上, 不关我事
    end

    -- 完全吸收: 无数值
    local src = MatchSelf(fullAbsorb, msg)
    if src then return nil, DetectSchool(msg), src end

    return nil
end

function libabsorb:GetPatterns()
    if not built then self:BuildPatterns() end
    return selfPatterns, fullAbsorb, absorbTrailer
end

-- ═══════════════════════════════════════════════════════════════
-- 二、tooltip 刮吸收量
-- ═══════════════════════════════════════════════════════════════

-- 在已填充的 scanner 里找含吸收关键词的行, 取该行最大的数
-- ("吸收438点伤害, 并使冰霜伤害提高10%" → 438)
local function ScrapeLoaded()
    local best = nil
    for line = 1, 12 do
        local text = scanner:GetLine(line)
        if text and HasKeyword(text) then
            local init = 1
            while true do
                local _, e, num = string.find(text, "(%d+)", init)
                if not num then break end
                local v = tonumber(num)
                if v and v > 0 and (not best or v > best) then best = v end
                init = e + 1
            end
        end
    end
    return best
end

-- 玩家身上第 uiIdx 个 buff 的 tooltip → name, absorb
-- absorb 为 nil 表示"这不是吸收盾"
function libabsorb:ScanBuff(uiIdx)
    scanner:SetUnitBuff("player", uiIdx)
    local name = scanner:GetLine(1)
    if not name then return nil end
    if _G.DFUI_ShieldExclude and _G.DFUI_ShieldExclude[name] then return name, nil end
    return name, ScrapeLoaded()
end

-- 自己法术书里该法术(指定等级, 默认最高)的基础吸收量
function libabsorb:ScanSpellbook(name, rankStr)
    local lib = DFUI_Libs and DFUI_Libs.libspell
    if not lib then return nil end
    local id, bookType = lib:GetSpellIndex(name, rankStr)
    if not id then return nil end
    scanner:SetSpell(id, bookType)
    return ScrapeLoaded()
end

-- 该法术在自己法术书里 → 认为是自己施放的, 才套自己的天赋。
-- 1.12 无 SuperWoW 时拿不到施法者, 这是唯一诚实的启发式:
-- 别人给你上的盾只用基础值, 既不套你的天赋(错)也不编造对方的(更错)。
function libabsorb:IsLikelySelfCast(name)
    local lib = DFUI_Libs and DFUI_Libs.libspell
    if not lib then return false end
    return lib:GetSpellIndex(name) and true or false
end

-- ═══════════════════════════════════════════════════════════════
-- 三、天赋加成
-- ═══════════════════════════════════════════════════════════════

-- 返回加成百分比之和(加法叠加), 如 35 表示 +35%
function libabsorb:TalentPercent(name)
    local def = _G.DFUI_ShieldSpells and _G.DFUI_ShieldSpells[name]
    if not def or not def.talents then return 0 end
    if not DFUI.GetTalentBonusPercent then return 0 end
    local sum = 0
    for i = 1, table.getn(def.talents) do
        local t = def.talents[i]
        sum = sum + DFUI.GetTalentBonusPercent(t.name, t.percentIndex)
    end
    return sum
end

-- 法力护盾: 每吸收 1 点伤害消耗多少法力(已计入减耗天赋)。非法力护盾返回 nil
function libabsorb:ManaPerPoint(name)
    local def = _G.DFUI_ShieldSpells and _G.DFUI_ShieldSpells[name]
    if not def or not def.mana then return nil end
    local per = def.mana.perPoint or 2
    local t = def.mana.talent
    if t and DFUI.GetTalentBonusPercent then
        local pct = DFUI.GetTalentBonusPercent(t.name, t.percentIndex)
        if pct > 0 then per = per * (1 - pct / 100) end
    end
    if per <= 0 then return nil end
    return per
end

function libabsorb:SchoolsOf(name)
    local def = _G.DFUI_ShieldSpells and _G.DFUI_ShieldSpells[name]
    return def and def.schools or nil
end

-- ═══════════════════════════════════════════════════════════════
-- 四、实测校准存储 (_G.DFUI_ShieldDB)
-- ═══════════════════════════════════════════════════════════════

local db = nil                -- 当前角色的 { learned = {}, }
local gearString = nil

local function DBKey(name, rankStr)
    return name .. "#" .. (rankStr or "?")
end

function libabsorb:GetLearned(name, rankStr)
    if not db then return nil end
    local e = db.learned[DBKey(name, rankStr)]
    if not e then return nil end
    -- e = {value, dirty}
    if e[2] then return nil end
    return e[1]
end

-- 护盾被打破时调用: 真实初始值 == 累计扣减量。
-- 这一招把法强、套装、Turtle 改数值全部吃进去 —— 1.12 拿不到法强接口,
-- 这是唯一能把数值做准的路径。
function libabsorb:Learn(name, rankStr, value)
    if not db or not value or value <= 0 then return end
    db.learned[DBKey(name, rankStr)] = {value, nil}
end

function libabsorb:ForgetAll()
    if db then db.learned = {} end
end

function libabsorb:DumpLearned()
    return db and db.learned or {}
end

-- ═══════════════════════════════════════════════════════════════
-- 五、初始吸收量四层级联
-- ═══════════════════════════════════════════════════════════════
--
--   1 实测校准值   已含法强/天赋/套装 → 直接用, 不再叠加修正
--   2 buff tooltip 当前身上这个盾的真实等级基础值(不含天赋, 见 auras.lua:815 注释)
--   3 法术书       buff tooltip 刮不到时, 用自己会的最高等级
--   4 静态兜底表   自己没学过该法术时的最后手段
--   5 放弃         宁可不追踪, 也不编一个数
--
-- 返回 amount(number|nil), source(string)
function libabsorb:GetInitial(name, uiIdx, tipAbsorb)
    if not name then return nil, "none" end

    local lib = DFUI_Libs and DFUI_Libs.libspell
    local rankStr = lib and lib:GetSpellMaxRank(name) or nil

    -- 1) 校准值: 已经是实测真值, 不套任何修正
    local learned = self:GetLearned(name, rankStr)
    if learned then return learned, "cal" end

    local base, source = nil, nil

    -- 2) buff tooltip (调用方通常已经刮过, 直接复用, 免得再开一次 tooltip)
    if tipAbsorb and tipAbsorb > 0 then
        base, source = tipAbsorb, "tip"
    end

    -- 3) 自己法术书
    if not base then
        local v = self:ScanSpellbook(name, rankStr)
        if v and v > 0 then base, source = v, "book" end
    end

    -- 4) 静态兜底表
    if not base then
        local def = _G.DFUI_ShieldSpells and _G.DFUI_ShieldSpells[name]
        if def and def.ranks then
            local n = table.getn(def.ranks)
            local _, rankNum = nil, nil
            if lib then _, rankNum = lib:GetSpellMaxRank(name) end
            local idx = rankNum
            if not idx or idx <= 0 or idx > n then idx = n end
            if def.ranks[idx] then base, source = def.ranks[idx], "tbl" end
        end
    end

    -- 5) 认不出就不追踪
    if not base then return nil, "none" end

    -- 天赋修正: tooltip/表值都不含天赋, 只有能确定是自己施放时才敢套
    if self:IsLikelySelfCast(name) then
        local pct = self:TalentPercent(name)
        if pct > 0 then base = math.floor(base * (1 + pct / 100)) end
    end

    return base, source
end

-- ═══════════════════════════════════════════════════════════════
-- 六、生命周期
-- ═══════════════════════════════════════════════════════════════

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("LEARNED_SPELL_IN_TAB")
f:RegisterEvent("CHARACTER_POINTS_CHANGED")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        -- setfenv 与否都写 _G, 保证 SavedVariable 真正落盘
        local realm = GetRealmName()
        local player = UnitName("player")
        _G.DFUI_ShieldDB = _G.DFUI_ShieldDB or {}
        _G.DFUI_ShieldDB[realm] = _G.DFUI_ShieldDB[realm] or {}
        _G.DFUI_ShieldDB[realm][player] = _G.DFUI_ShieldDB[realm][player] or {}
        db = _G.DFUI_ShieldDB[realm][player]
        db.learned = db.learned or {}
        libabsorb:BuildPatterns()
    end

    -- 装备/天赋变了, 校准值失效。装备走内容比对, 免得每次背包动一下就清。
    if event == "UNIT_INVENTORY_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        if arg1 and arg1 ~= "player" then return end
        local gear = ""
        for id = 1, 18 do
            gear = gear .. (GetInventoryItemLink("player", id) or "")
        end
        if gear == gearString then return end
        gearString = gear
    end

    if db and db.learned then
        for k in pairs(db.learned) do
            db.learned[k][2] = true      -- 打脏, 下次破盾重新学
        end
    end
end)

DFUI_Libs = DFUI_Libs or {}
DFUI_Libs.libabsorb = libabsorb
