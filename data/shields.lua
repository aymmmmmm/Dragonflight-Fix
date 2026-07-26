-- ═══════════════════════════════════════════════════════════════
-- 护盾(吸收类光环)富化数据
--
-- ⚠ 这张表【不是】识别护盾的白名单。
--    识别走 libs/libabsorb.lua 的通用规则(刮 buff tooltip, 命中"吸收 N 点"即认定),
--    这样任何护盾都能追踪 —— 包括别的牧师给你上的真言术：盾、防护药水、
--    Turtle 自定义法术、装备触发盾。
--    本表只做【富化】: 学派限定、天赋加成来源、数值兜底、法力护盾的耗蓝换算。
--    查不到的护盾一样能追踪, 只是不套天赋修正。
--
-- ⚠ ranks 里的数值是 vanilla 1.12 参考值, 【未在 Turtle 1.18 上逐条核对】。
--    取值优先级(见 libabsorb:GetInitial)是:
--       实测校准值 > 自己法术书 tooltip > buff tooltip > 本表 > 放弃追踪
--    也就是说本表只在【前三条全部落空】时才生效 —— 主要是"别人给你上的盾
--    而你自己没学过这个法术"的场景。查不到就放弃追踪, 绝不猜一个数糊弄。
--    游戏内用 /dfshield ranks 打印"本表 vs 法术书 tooltip"对照来修正本表。
-- ═══════════════════════════════════════════════════════════════

local zh = (GetLocale() == "zhCN")

-- 学派词: 用于"防护 XX 结界"这类只吃单一学派的盾。
-- 与战斗日志/tooltip 里出现的学派名一致。
DFUI_ShieldSchoolWords = zh and {
    fire = "火焰", frost = "冰霜", shadow = "暗影",
    nature = "自然", arcane = "奥术", holy = "神圣",
} or {
    fire = "Fire", frost = "Frost", shadow = "Shadow",
    nature = "Nature", arcane = "Arcane", holy = "Holy",
}

local W = DFUI_ShieldSchoolWords

-- 富化表: [本地化法术名] = { ... }
--   ranks   逐等级基础吸收量(不含天赋/法强)。缺省 = 无兜底数据
--   schools nil = 全学派吸收; {[学派词]=true} = 只吃这些学派
--   talents 加法叠加的天赋加成来源。percentIndex = 该天赋描述里第几个 "N%"
--   mana    法力护盾专用: 每吸收 1 点伤害消耗的法力, 及减耗天赋
DFUI_ShieldSpells = {}

if zh then
    DFUI_ShieldSpells["真言术：盾"] = {
        ranks = {44, 88, 158, 234, 301, 381, 484, 605, 763, 942},
        talents = {
            -- talents_desc.lua:488-490  "使你的真言术：盾所吸收的伤害量提高5%/10%/15%"
            { name = "强化真言术：盾", percentIndex = 1 },
            -- talents_desc.lua:504-508  描述里【第 1 个 % 是暴击率, 第 2 个才是护盾】
            -- "使你的法术伤害和攻击性法术的致命一击几率提高1%, 并且使你的真言术：盾所吸收的伤害量提高4%"
            { name = "意志之力", percentIndex = 2 },
        },
    }
    DFUI_ShieldSpells["寒冰护体"] = {
        -- talents_desc.lua:105 证实 Turtle 的等级 1 仍是 438
        ranks = {438, 549, 674},
    }
    DFUI_ShieldSpells["法力护盾"] = {
        ranks = {120, 210, 340, 500, 700, 920},
        -- vanilla: 每吸收 1 点伤害耗 2 点法力
        -- talents_desc.lua:133-134  强化法力护盾 减耗 13%/25% (Turtle 值, 非 vanilla 的 10%/20%)
        mana = { perPoint = 2, talent = { name = "强化法力护盾", percentIndex = 1 } },
    }
    DFUI_ShieldSpells["防护火焰结界"] = { ranks = {165, 340, 605, 950}, schools = { [W.fire] = true } }
    DFUI_ShieldSpells["防护冰霜结界"] = { ranks = {165, 340, 605, 950}, schools = { [W.frost] = true } }
    DFUI_ShieldSpells["防护暗影结界"] = { ranks = {290, 435, 605, 815}, schools = { [W.shadow] = true } }
    DFUI_ShieldSpells["牺牲"] = { ranks = {305, 435, 610, 815, 1050, 1305} }   -- 术士虚空行者给主人的盾
else
    DFUI_ShieldSpells["Power Word: Shield"] = {
        ranks = {44, 88, 158, 234, 301, 381, 484, 605, 763, 942},
        talents = {
            { name = "Improved Power Word: Shield", percentIndex = 1 },
            { name = "Force of Will", percentIndex = 2 },
        },
    }
    DFUI_ShieldSpells["Ice Barrier"] = { ranks = {438, 549, 674} }
    DFUI_ShieldSpells["Mana Shield"] = {
        ranks = {120, 210, 340, 500, 700, 920},
        mana = { perPoint = 2, talent = { name = "Improved Mana Shield", percentIndex = 1 } },
    }
    DFUI_ShieldSpells["Fire Ward"]   = { ranks = {165, 340, 605, 950}, schools = { [W.fire] = true } }
    DFUI_ShieldSpells["Frost Ward"]  = { ranks = {165, 340, 605, 950}, schools = { [W.frost] = true } }
    DFUI_ShieldSpells["Shadow Ward"] = { ranks = {290, 435, 605, 815}, schools = { [W.shadow] = true } }
    DFUI_ShieldSpells["Sacrifice"]   = { ranks = {305, 435, 610, 815, 1050, 1305} }
end

-- 明确【不是】吸收盾, 即使 tooltip 里出现"吸收"字样也不进队列:
--   牺牲祝福 = 伤害转移给圣骑士, 不是 school absorb
--   圣盾术/圣佑术/寒冰屏障 = 免疫, 不是有限吸收量
--   冰甲术/恶魔护甲/石肤图腾 = 护甲/减伤, 不是吸收
-- 这些法术的 tooltip 本身通常不含"吸收 N 点"模式, 但列出来做保险。
DFUI_ShieldExclude = {}
local excl = zh
    and {"牺牲祝福", "圣盾术", "圣佑术", "寒冰屏障", "冰甲术", "霜甲术",
         "恶魔护甲", "恶魔皮肤", "石肤图腾", "石肤", "法术反射", "偏斜"}
    or  {"Blessing of Sacrifice", "Divine Shield", "Divine Protection", "Ice Block",
         "Frost Armor", "Ice Armor", "Demon Armor", "Demon Skin", "Stoneskin Totem",
         "Stoneskin", "Spell Reflection", "Deflection"}
for i = 1, table.getn(excl) do DFUI_ShieldExclude[excl[i]] = true end
