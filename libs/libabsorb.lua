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
-- → best(number|nil), sawKeyword(bool)
-- ⚠ 第二个返回值不是装饰: "命中了吸收关键词但行内没数字" 与 "根本不是护盾"
--   都返回 best=nil, 不区分开就无法判断该不该为这个 buff 付更贵的取值代价
--   (开法术 ID tooltip), 也无法告诉用户"这确实是个盾, 只是读不出数"。
local function ScrapeLoaded()
    local best, saw = nil, false
    for line = 1, 12 do
        local text = scanner:GetLine(line)
        if text and HasKeyword(text) then
            saw = true
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
    return best, saw
end

-- 玩家身上第 uiIdx 个 buff 的 tooltip → name, absorb, sawKeyword
--   absorb=nil 且 sawKeyword=false → 不是吸收盾
--   absorb=nil 且 sawKeyword=true  → 是吸收盾, 但 tooltip 里没有可用数字
--                                     (调用方据此决定是否走更贵的法术 ID 路径)
function libabsorb:ScanBuff(uiIdx)
    scanner:SetUnitBuff("player", uiIdx)
    local name = scanner:GetLine(1)
    if not name then return nil end
    if _G.DFUI_ShieldExclude and _G.DFUI_ShieldExclude[name] then
        return name, nil, false
    end
    return name, ScrapeLoaded()
end

-- 诊断用: 逐行取出某个 buff 的 tooltip 原文。
-- 刮取失败时, 这是唯一能看清"客户端到底给了什么"的手段 ——
-- 没有 SuperWoW 时别人给你上的盾只剩 buff tooltip 一条路(见 GetInitial 的注释),
-- 所以必须能把这条路的原始输入摊开来验。
-- → lines(table), n(number)
function libabsorb:DumpBuff(uiIdx)
    scanner:SetUnitBuff("player", uiIdx)
    local out, n = {}, 0
    for line = 1, 12 do
        local l, r = scanner:GetLine(line)
        if l or r then
            n = n + 1
            out[n] = (l or "") .. (r and ("  |cff888888<右> " .. r .. "|r") or "")
        end
    end
    return out, n
end

-- ── SuperWoW: 从光环本身反查法术 ID ──
-- 这是打通"别人给你上的盾"的关键: 光环自带法术 ID, 法术 ID 唯一确定等级,
-- 与施法者是谁、与你自己会不会这个法术都无关。
-- 没有 SuperWoW 时返回 nil, 整条路径静默失效, 级联退回原样。
-- ⚠ GetPlayerBuffID 只服务【玩家自己】; 本机 SuperWoW 1.5 没有 GetUnitField
--   (已核 SuperWoWhook.dll 符号表), 所以别人身上的光环拿不到法术 ID。
-- ⚠ 入参按 GetPlayerBuffTexture/GetPlayerBuffTimeLeft 同款语义传 GetPlayerBuff
--   的返回值。SuperWoW 文档只写了 "buffindex", 这一条没有逐字确认。
--
-- ⚠⚠ 这里【曾经】加过一道"用 SpellInfo 反查法术名, 与 buff 名不符就返回 nil"的
--    校验, 结果把整条路掐死了 —— 那个相等假设本身同样没被验证过, 而它一旦不成立,
--    第 2、3 两级取值会【同时】失效, 级联直接掉回"放弃追踪"。
--    该校验也没有实际收益: spellId 就是从【这个光环自己】身上取的, 而 libtipscan
--    的 SetHyperlink 包装层会先 ClearLines(libtipscan.lua:137-141), 读到别的法术
--    数据的路径根本不存在。别再加回来。
--    真要看 ID 反查出来的名字对不对, /dfshield scan 会把它打出来。
function libabsorb:AuraSpellID(bIdx)
    if not bIdx or bIdx < 0 then return nil end
    if type(_G.GetPlayerBuffID) ~= "function" then return nil end
    local id = _G.GetPlayerBuffID(bIdx)
    if type(id) ~= "number" or id <= 0 then return nil end
    return id
end

-- 法术 ID → 等级序号(10 表示 Rank 10 / 等级 10)。非 SuperWoW 环境返回 nil
function libabsorb:SpellRankNum(spellId)
    if not spellId or type(_G.SpellInfo) ~= "function" then return nil end
    local _, rankStr = _G.SpellInfo(spellId)
    if not rankStr then return nil end
    -- 与 libs/libspell.lua:25 同款: 等级序号在串尾("等级 10" / "Rank 10")
    local _, _, num = string.find(rankStr, "(%d+)%s*$")
    return tonumber(num)
end

-- 法术 ID → 该法术自身 tooltip 的吸收量。
-- enchant: 是 1.12 原生就认的超链接类型(AtlasLoot/Core/AtlasLoot.lua:1149 同款用法),
-- 拿到的是客户端 Spell.dbc 里【这一级】的原值, 对任何施法者都成立。
-- ⚠ 同 AuraSpellID: 【不要】拿 buff 名去比对这里第一行的法术名。
--   spellId 就是从这个光环身上取的, 而 SetHyperlink 的包装层会先 ClearLines
--   (libtipscan.lua:137-141) —— 链接不被识别时 tooltip 是空的(下面 first 为 nil
--   就退出了), 不存在"读到别的法术"这种情况。加名字相等校验只会在本地化/格式
--   有一丁点差异时把这一级白白掐掉, 已经踩过一次。
function libabsorb:ScanSpellID(spellId)
    if not spellId then return nil end
    scanner:SetHyperlink("enchant:" .. spellId)
    if not scanner:GetLine(1) then return nil end   -- 链接没渲染出来
    return ScrapeLoaded()
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

local db = nil                -- 当前角色的 { learned = {}, keyver = N }
local gearString = nil

-- key 用【这个盾自己的基准吸收值】, 不用施法者等级, 更不用"我自己法术书的最高等级"。
--
-- ⚠ 曾经用 rankStr(= 我自己会的最高等级) 当 key, 那是个严重缺陷:
--   别人给你上的 Rank 10 盾破了, 校准值会存到【你自己 Rank 4】的条目下,
--   之后你自己放的盾永远读出那个高值, 而且跟着 SavedVariable 跨会话生效。
--   基准值(未含天赋, 直接来自 tooltip)唯一标识"这个盾是哪一级", 天然隔离。
local KEYVER = 2

local function DBKey(name, base)
    return name .. "#" .. tostring(base)
end

function libabsorb:GetLearned(key)
    if not db or not key then return nil end
    local e = db.learned[key]
    if not e then return nil end
    -- e = {value, dirty}
    if e[2] then return nil end
    return e[1]
end

-- 护盾被打破时调用: 真实初始值 == 累计扣减量。
-- 这一招把法强、套装、Turtle 改数值全部吃进去 —— 1.12 拿不到法强接口,
-- 这是唯一能把数值做准的路径。
-- ⚠ 调用方(shield.lua:Retire)负责把关: 记账脏了 / 涨幅离谱的一律不许学进来。
function libabsorb:Learn(key, value)
    if not db or not key or not value or value <= 0 then return end
    db.learned[key] = {value, nil}
end

function libabsorb:ForgetAll()
    if db then db.learned = {} end
end

function libabsorb:DumpLearned()
    return db and db.learned or {}
end

-- ═══════════════════════════════════════════════════════════════
-- 五、初始吸收量级联
-- ═══════════════════════════════════════════════════════════════
--
--   先求【基准值】(不含天赋, 唯一标识这个盾是哪一级):
--     1 buff tooltip   当前身上这个盾按【施法者等级】的基础值 —— 首选且免费,
--                      调用方通常已经刮过(见 core/tools.lua:207 注释:
--                      1.12 tooltip 数值来自本地 Spell.dbc, 天赋/法强都不反映)
--     2 法术ID tooltip 用光环自带的法术 ID 开 enchant: 链接, 直接读 Spell.dbc 原值
--     3 法术ID → 等级  第 2 级打不开时, 用 ID 换出精确等级去查静态表
--     4 自己法术书     以上都没有时, 退而用自己会的最高等级
--     5 静态兜底表     自己没学过该法术时的最后手段, 且【必须能确定等级】
--     6 放弃           宁可不追踪, 也不编一个数
--
--   ⚠ 为什么必须有 2/3 两级: 4/5 两级【都只查自己的法术书】。"别人给你上的盾、
--     而你自己没学过这个法术"(非牧师吃真言术：盾)时它们全是空的, 整条级联只剩
--     ① 一根独木桥 —— 一旦 buff tooltip 刮不到数字就直接放弃, 而调用方那边是
--     静默跳过。这正是"小队/团队里被牧师套盾却什么都看不到"的结构性来路。
--     spellId 由调用方经 AuraSpellID(GetPlayerBuffID) 取得, 与施法者是谁无关,
--     所以 2/3 两级对任何人施放的盾都成立。没有 SuperWoW 时 spellId 为 nil,
--     这两级自动跳过, 行为与从前完全一致。
--
--   foreign: 调用方确证"这盾是别人放的"(UNIT_CASTEVENT 捕获到)。只影响两件事 ——
--     不套自己的天赋、不许进校准学习库(后者由调用方处理)。取不到时为 nil,
--     退回原来的 IsLikelySelfCast 启发式。
--
--   再用基准值当 key 查校准库:
--     命中 → 实测真值(已含法强/天赋/套装), 直接用, 不再叠加任何修正
--     未命中 → 基准值套天赋修正
--
-- 返回 amount(number|nil), source(string), key(string|nil), estimate(number|nil)
--   key      交给调用方存在护盾对象上, 破盾校准时原样传回 Learn, 保证存取同一条目
--   estimate 【不含校准】的纯估算值(基准值套天赋)。调用方拿它当校准护栏的锚点 ——
--            锚在 amount 上会出事: cal 命中时 amount 就是上次学到的值, 护栏基准
--            会跟着水涨船高, 一轮学高一点, 逐轮爬升
function libabsorb:GetInitial(name, uiIdx, tipAbsorb, spellId, foreign)
    if not name then return nil, "none" end

    local lib = DFUI_Libs and DFUI_Libs.libspell
    local base, source = nil, nil

    -- 1) buff tooltip (调用方通常已经刮过, 直接复用, 免得再开一次 tooltip)
    if tipAbsorb and tipAbsorb > 0 then
        base, source = tipAbsorb, "tip"
    end

    -- 2) 法术 ID 自己的 tooltip —— 对任何施法者都成立, 不看自己的法术书
    if not base and spellId then
        local v = self:ScanSpellID(spellId)
        if v and v > 0 then base, source = v, "sid" end
    end

    -- 3) 法术 ID → 精确等级 → 静态表
    if not base and spellId then
        local def = _G.DFUI_ShieldSpells and _G.DFUI_ShieldSpells[name]
        if def and def.ranks then
            local rankNum = self:SpellRankNum(spellId)
            if rankNum and rankNum > 0 and def.ranks[rankNum] then
                base, source = def.ranks[rankNum], "sid#"
            end
        end
    end

    -- 4) 自己法术书
    if not base then
        local rankStr = lib and lib:GetSpellMaxRank(name) or nil
        local v = self:ScanSpellbook(name, rankStr)
        if v and v > 0 then base, source = v, "book" end
    end

    -- 5) 静态兜底表 + 自己会的最高等级。
    -- ⚠ 等级拿不到就【放弃】, 绝不退回表尾(那是满级值: 942/920/950),
    --   低等级角色会被喂一个高出真值几倍的数, 与本文件开头的原则直接冲突。
    -- ⚠ 这一级的等级来自【自己的】法术书, 只在自施场景下正确 —— 所以 source
    --   必须与 sid# 区分开, /dfshield 的"来源"列一眼就能看出这个数可不可信。
    if not base then
        local def = _G.DFUI_ShieldSpells and _G.DFUI_ShieldSpells[name]
        if def and def.ranks then
            local _, rankNum = nil, nil
            if lib then _, rankNum = lib:GetSpellMaxRank(name) end
            if rankNum and rankNum > 0 and def.ranks[rankNum] then
                base, source = def.ranks[rankNum], "tbl"
            end
        end
    end

    -- 6) 认不出就不追踪
    if not base then return nil, "none" end

    -- key 取【未含天赋的基准值】: 它唯一标识 spell rank, 且不随加点变化
    local key = DBKey(name, base)

    -- 天赋修正: tooltip/表值都不含天赋, 只有能确定是自己施放时才敢套。
    -- ⚠ foreign 是【确证他人施放】的硬信号(捕获到了对方的施法事件), 一旦成立就
    --   绝不套自己的天赋 —— 哪怕自己也会这个法术(牧师吃另一个牧师的盾)。
    --   IsLikelySelfCast 那条"法术书里有 = 自己放的"启发式在这种场合正好会误判。
    if not foreign and self:IsLikelySelfCast(name) then
        local pct = self:TalentPercent(name)
        if pct > 0 then base = math.floor(base * (1 + pct / 100)) end
    end
    -- 至此 base = 不含校准的纯估算值, 无论下面走不走校准都原样交出去当护栏锚点

    -- 校准值: 已经是实测真值(含法强/天赋/套装), 直接用, 不再叠加任何修正。
    -- ⚠ 但【他人施放的盾不许读校准库】。校准库里存的是"我自己"打破这个等级的盾时
    --   量出来的真值, 里面含的是我的法强/天赋/套装; key 只按基准值(等级)生成,
    --   所以牧师甲的 R10 盾会命中我自己 R10 的学习值。那是拿我的装备去替别人报数,
    --   与本文件"绝不编一个数"的原则同性质。
    --   调用方那边 tainted 挡的是【写】, 这里挡的是【读】—— 两边都要挡住。
    if not foreign then
        local learned = self:GetLearned(key)
        if learned then return learned, "cal", key, base end
    end

    return base, source, key, base
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
        -- key 格式换代(等级串 → 基准吸收值)。旧条目既匹配不上, 又可能是老缺陷
        -- 留下的虚高脏值(别人的高等级盾记到了自己等级名下), 一次性清干净。
        if db.keyver ~= KEYVER then
            db.learned = {}
            db.keyver = KEYVER
        end
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
