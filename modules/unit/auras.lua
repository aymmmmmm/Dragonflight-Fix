DFUI:NewDefaults("Auras", {
    enabled = {true},
    -- Buff Bar (top-right player buffs) - category index 1 so it appears first
    buffBarMode = {"Buff Bar", "dropdown", {"Default", "Buff Bar", "Disabled"}, nil, "增益栏", 1, "玩家增益显示", nil, nil},
    buffBarShowBuffs = {true, "checkbox", nil, nil, "增益栏", 2, "显示增益", nil, nil},
    buffBarShowDebuffs = {true, "checkbox", nil, nil, "增益栏", 3, "显示减益", nil, nil},
    buffBarShowWeapons = {true, "checkbox", nil, nil, "增益栏", 4, "显示武器附魔", nil, nil},
    buffBarSize = {25, "slider", {16, 50, 1}, nil, "增益栏", 5, "图标大小", nil, nil},
    buffBarPerRow = {8, "slider", {4, 16, 1}, nil, "增益栏", 6, "每行图标数", nil, nil},
    buffBarSpacing = {5, "slider", {0, 20, 1}, nil, "增益栏", 7, "图标间距", nil, nil},
    buffBarFrameSpacing = {15, "slider", {0, 50, 1}, nil, "增益栏", 8, "分区间距", nil, nil},
    buffBarTimerInside = {false, "checkbox", nil, nil, "增益栏", 9, "计时器显示在图标内", nil, nil},
    buffBarTimerFontSize = {10, "slider", {6, 20, 1}, nil, "增益栏", 10, "计时器字号", nil, nil},
    buffBarTimerStyle = {"White + Red", "dropdown", {"Gold", "White + Red"}, nil, "增益栏", 11, "计时器颜色风格", nil, nil},
    buffBarSortOrder = {"Default", "dropdown", {"Default", "Duration ascending", "Duration descending"}, nil, "增益栏", 12, "排序方式", nil, nil},
    buffBarShowSpiral = {true, "checkbox", nil, nil, "增益栏", 13, "显示减益旋转动画", nil, nil},
    -- 玩家（默认隐藏单位框架上的增益/减益）
    playerBuffs = {false, "checkbox", nil, nil, "玩家", 1, "显示增益", nil, nil},
    playerDebuffs = {false, "checkbox", nil, nil, "玩家", 2, "显示减益", nil, nil},
    playerShowBuffTimer = {true, "checkbox", nil, "playerBuffs", "玩家", 3, "显示增益计时器", nil, nil},
    playerShowDebuffTimer = {true, "checkbox", nil, "playerDebuffs", "玩家", 4, "显示减益计时器", nil, nil},
    playerShowSpiral = {true, "checkbox", nil, nil, "玩家", 5, "显示减益旋转动画", nil, nil},
    playerAuraSize = {20, "slider", {10, 30, 1}, nil, "玩家", 6, "图标大小", nil, nil},
    playerAuraSpacing = {2, "slider", {0, 6, 1}, nil, "玩家", 7, "图标间距", nil, nil},
    playerAurasPerRow = {5, "slider", {3, 8, 1}, nil, "玩家", 8, "每行图标数", nil, nil},
    playerGrowRight = {true, "checkbox", nil, nil, "玩家", 9, "图标向右增长", nil, nil},
    playerTimerFontSize = {12, "slider", {6, 20, 1}, nil, "玩家", 10, "计时器字号", nil, nil},
    playerTimerStyle = {"White + Red", "dropdown", {"Gold", "White + Red"}, nil, "玩家", 11, "计时器颜色风格", nil, nil},
    playerAuraX = {100, "slider", {-200, 200, 1}, nil, "玩家", 12, "光环X偏移", nil, nil},
    playerAuraY = {-68, "slider", {-200, 200, 1}, nil, "玩家", 13, "光环Y偏移", nil, nil},
    -- 目标
    targetBuffs = {true, "checkbox", nil, nil, "目标", 1, "显示增益", nil, nil},
    targetDebuffs = {true, "checkbox", nil, nil, "目标", 2, "显示减益", nil, nil},
    targetShowBuffTimer = {true, "checkbox", nil, "targetBuffs", "目标", 3, "显示增益计时器", nil, nil},
    targetShowDebuffTimer = {true, "checkbox", nil, "targetDebuffs", "目标", 4, "显示减益计时器", nil, nil},
    targetShowSpiral = {true, "checkbox", nil, nil, "目标", 5, "显示减益旋转动画", nil, nil},
    targetAuraSize = {20, "slider", {10, 30, 1}, nil, "目标", 6, "图标大小", nil, nil},
    targetAuraSpacing = {2, "slider", {0, 6, 1}, nil, "目标", 7, "图标间距", nil, nil},
    targetAurasPerRow = {5, "slider", {3, 8, 1}, nil, "目标", 8, "每行图标数", nil, nil},
    targetGrowRight = {false, "checkbox", nil, nil, "目标", 9, "图标向右增长", nil, nil},
    targetTimerFontSize = {12, "slider", {6, 20, 1}, nil, "目标", 10, "计时器字号", nil, nil},
    targetTimerStyle = {"White + Red", "dropdown", {"Gold", "White + Red"}, nil, "目标", 11, "计时器颜色风格", nil, nil},
    targetAuraX = {-100, "slider", {-200, 200, 1}, nil, "目标", 12, "光环X偏移", nil, nil},
    targetAuraY = {-68, "slider", {-200, 200, 1}, nil, "目标", 13, "光环Y偏移", nil, nil},
    -- 宠物
    petBuffs = {true, "checkbox", nil, nil, "宠物", 1, "显示增益", nil, nil},
    petDebuffs = {true, "checkbox", nil, nil, "宠物", 2, "显示减益", nil, nil},
    petShowBuffTimer = {true, "checkbox", nil, "petBuffs", "宠物", 3, "显示增益计时器", nil, nil},
    petShowDebuffTimer = {true, "checkbox", nil, "petDebuffs", "宠物", 4, "显示减益计时器", nil, nil},
    petShowSpiral = {true, "checkbox", nil, nil, "宠物", 5, "显示减益旋转动画", nil, nil},
    petAuraSize = {20, "slider", {10, 30, 1}, nil, "宠物", 6, "图标大小", nil, nil},
    petAuraSpacing = {2, "slider", {0, 6, 1}, nil, "宠物", 7, "图标间距", nil, nil},
    petAurasPerRow = {5, "slider", {3, 8, 1}, nil, "宠物", 8, "每行图标数", nil, nil},
    petGrowRight = {true, "checkbox", nil, nil, "宠物", 9, "图标向右增长", nil, nil},
    petTimerFontSize = {12, "slider", {6, 20, 1}, nil, "宠物", 10, "计时器字号", nil, nil},
    petTimerStyle = {"White + Red", "dropdown", {"Gold", "White + Red"}, nil, "宠物", 11, "计时器颜色风格", nil, nil},
    petAuraX = {30, "slider", {-200, 200, 1}, nil, "宠物", 12, "光环X偏移", nil, nil},
    petAuraY = {-2, "slider", {-200, 200, 1}, nil, "宠物", 13, "光环Y偏移", nil, nil},
    -- 队伍
    partyBuffs = {true, "checkbox", nil, nil, "队伍", 1, "显示增益", nil, nil},
    partyDebuffs = {true, "checkbox", nil, nil, "队伍", 2, "显示减益", nil, nil},
    partyShowBuffTimer = {true, "checkbox", nil, "partyBuffs", "队伍", 3, "显示增益计时器", nil, nil},
    partyShowDebuffTimer = {true, "checkbox", nil, "partyDebuffs", "队伍", 4, "显示减益计时器", nil, nil},
    partyShowSpiral = {true, "checkbox", nil, nil, "队伍", 5, "显示减益旋转动画", nil, nil},
    partyAuraSize = {20, "slider", {10, 30, 1}, nil, "队伍", 6, "图标大小", nil, nil},
    partyAuraSpacing = {2, "slider", {0, 6, 1}, nil, "队伍", 7, "图标间距", nil, nil},
    partyAurasPerRow = {5, "slider", {3, 8, 1}, nil, "队伍", 8, "每行图标数", nil, nil},
    partyGrowRight = {true, "checkbox", nil, nil, "队伍", 9, "图标向右增长", nil, nil},
    partyTimerFontSize = {12, "slider", {6, 20, 1}, nil, "队伍", 10, "计时器字号", nil, nil},
    partyTimerStyle = {"White + Red", "dropdown", {"Gold", "White + Red"}, nil, "队伍", 11, "计时器颜色风格", nil, nil},
    partyAuraX = {30, "slider", {-200, 200, 1}, nil, "队伍", 12, "光环X偏移", nil, nil},
    partyAuraY = {-2, "slider", {-200, 200, 1}, nil, "队伍", 13, "光环Y偏移", nil, nil},
})

DFUI:NewMod("Auras", 2, function()
    -- requires SuperWoW for UNIT_AURA event and GUID-based debuff tracking

    local DEBUFF_COLORS = {
        none    = {0.8, 0.0, 0.0},
        Magic   = {0.2, 0.6, 1.0},
        Disease = {0.6, 0.4, 0.0},
        Poison  = {0.0, 0.6, 0.0},
        Curse   = {0.6, 0.0, 1.0},
    }

    -- Per-unit appearance getters
    local function GetAuraSize(prefix)
        return DFUI:GetTempDB("Auras", prefix .. "AuraSize") or 20
    end
    local function GetAuraSpacing(prefix)
        return DFUI:GetTempDB("Auras", prefix .. "AuraSpacing") or 2
    end
    local function GetAurasPerRow(prefix)
        return DFUI:GetTempDB("Auras", prefix .. "AurasPerRow") or 5
    end

    -- reference to libdebuff (loaded via libs/libdebuff.lua)
    local libdebuff = DFUI_Libs and DFUI_Libs.libdebuff

    -------------------------------------------------------------------
    -- Buff duration tracking (SuperWoW + Nampower)
    -------------------------------------------------------------------

    -- Duration tracking: [targetGuid] = { [spellId] = { start, duration } }
    local auraDurations = {}

    -- Max duration cache: [normalizedTexture] = maxSeenTimeLeft (pfUI-style)
    -- Naturally converges to total buff duration over time
    local maxdurations = {}

    -- Learned durations from Nampower AURA_CAST events: [spellName] = durationSec
    local learnedDurations = {}

    -- Normalize texture path for reliable comparison
    -- Strips "Interface\Icons\" prefix and lowercases
    local function NormalizeTexture(tex)
        if not tex then return nil end
        tex = string.lower(tex)
        tex = string.gsub(tex, "^interface[/\\]+icons[/\\]+", "")
        return tex
    end

    -- Spell icon cache
    local iconCache = {}
    local function CachedGetSpellIcon(spellId)
        if not spellId or spellId <= 0 then return nil end
        if iconCache[spellId] then return iconCache[spellId] end
        if GetSpellRecField and GetSpellIconTexture then
            local iconId = GetSpellRecField(spellId, "spellIconID")
            if iconId and type(iconId) == "number" and iconId > 0 then
                local tex = GetSpellIconTexture(iconId)
                if tex then
                    if not string.find(tex, "\\") then
                        tex = "Interface\\Icons\\" .. tex
                    end
                    iconCache[spellId] = tex
                    return tex
                end
            end
        end
        return nil
    end

    -- Spell name cache
    local nameCache = {}
    local function CachedGetSpellName(spellId)
        if not spellId or spellId <= 0 then return nil end
        if nameCache[spellId] then return nameCache[spellId] end
        if SpellInfo then
            local name = SpellInfo(spellId)
            if name then nameCache[spellId] = name end
            return name
        end
        return nil
    end

    -- Common buff durations (libdebuff only covers debuffs)
    local buffDurations = {
        -- ═══════════════════════════════════════
        -- Priest
        -- ═══════════════════════════════════════
        ["Power Word: Fortitude"] = 1800,
        ["Prayer of Fortitude"] = 3600,
        ["Power Word: Shield"] = 30,
        ["Divine Spirit"] = 1800,
        ["Prayer of Spirit"] = 3600,
        ["Shadow Protection"] = 600,
        ["Prayer of Shadow Protection"] = 1200,
        ["Inner Fire"] = 600,
        ["Renew"] = 15,
        ["Fear Ward"] = 600,
        ["Inspiration"] = 15,
        ["Lightwell Renew"] = 6,
        ["Abolish Disease"] = 20,
        ["Elune's Grace"] = 15,
        -- ═══════════════════════════════════════
        -- Druid
        -- ═══════════════════════════════════════
        ["Mark of the Wild"] = 1800,
        ["Gift of the Wild"] = 3600,
        ["Thorns"] = 600,
        ["Rejuvenation"] = 12,
        ["Regrowth"] = 21,
        ["Innervate"] = 20,
        ["Barkskin"] = 15,
        ["Abolish Poison"] = 8,
        ["Frenzied Regeneration"] = 10,
        -- ═══════════════════════════════════════
        -- Mage
        -- ═══════════════════════════════════════
        ["Arcane Intellect"] = 1800,
        ["Arcane Brilliance"] = 3600,
        ["Ice Armor"] = 1800,
        ["Frost Armor"] = 1800,
        ["Mage Armor"] = 1800,
        ["Ice Barrier"] = 60,
        ["Dampen Magic"] = 600,
        ["Amplify Magic"] = 600,
        ["Arcane Power"] = 15,
        ["Combustion"] = 0,
        ["Fire Ward"] = 30,
        ["Frost Ward"] = 30,
        ["Mana Shield"] = 60,
        ["Evocation"] = 8,
        -- ═══════════════════════════════════════
        -- Paladin
        -- ═══════════════════════════════════════
        ["Blessing of Might"] = 300,
        ["Blessing of Wisdom"] = 300,
        ["Blessing of Kings"] = 300,
        ["Blessing of Salvation"] = 300,
        ["Blessing of Light"] = 300,
        ["Blessing of Sanctuary"] = 300,
        ["Blessing of Protection"] = 10,
        ["Blessing of Freedom"] = 16,
        ["Blessing of Sacrifice"] = 30,
        ["Greater Blessing of Might"] = 900,
        ["Greater Blessing of Wisdom"] = 900,
        ["Greater Blessing of Kings"] = 900,
        ["Greater Blessing of Salvation"] = 900,
        ["Greater Blessing of Light"] = 900,
        ["Greater Blessing of Sanctuary"] = 900,
        ["Divine Shield"] = 12,
        ["Divine Protection"] = 8,
        ["Holy Shield"] = 10,
        ["Avenging Wrath"] = 20,
        ["Devotion Aura"] = 0,
        ["Retribution Aura"] = 0,
        ["Concentration Aura"] = 0,
        ["Sanctity Aura"] = 0,
        -- ═══════════════════════════════════════
        -- Warlock
        -- ═══════════════════════════════════════
        ["Demon Armor"] = 1800,
        ["Demon Skin"] = 1800,
        ["Unending Breath"] = 600,
        ["Shadow Ward"] = 30,
        ["Sacrifice"] = 30,
        ["Fel Domination"] = 15,
        ["Soulstone Resurrection"] = 1800,
        ["Soul Link"] = 0,
        ["Life Tap"] = 0,
        -- ═══════════════════════════════════════
        -- Warrior
        -- ═══════════════════════════════════════
        ["Battle Shout"] = 120,
        ["Shield Wall"] = 10,
        ["Last Stand"] = 20,
        ["Berserker Rage"] = 10,
        ["Recklessness"] = 15,
        ["Retaliation"] = 15,
        ["Bloodrage"] = 10,
        ["Death Wish"] = 30,
        ["Enrage"] = 12,
        ["Shield Block"] = 5,
        ["Bloodthirst"] = 8,
        -- ═══════════════════════════════════════
        -- Hunter
        -- ═══════════════════════════════════════
        ["Rapid Fire"] = 15,
        ["Bestial Wrath"] = 18,
        ["Mend Pet"] = 15,
        ["Quick Shots"] = 12,
        ["Trueshot Aura"] = 0,
        ["Aspect of the Hawk"] = 0,
        ["Aspect of the Monkey"] = 0,
        ["Aspect of the Cheetah"] = 0,
        ["Aspect of the Pack"] = 0,
        ["Aspect of the Wild"] = 0,
        ["Spirit Bond"] = 0,
        ["Deterrence"] = 10,
        -- ═══════════════════════════════════════
        -- Rogue
        -- ═══════════════════════════════════════
        ["Evasion"] = 15,
        ["Sprint"] = 15,
        ["Blade Flurry"] = 15,
        ["Adrenaline Rush"] = 15,
        ["Vanish"] = 10,
        ["Slice and Dice"] = 21,
        -- ═══════════════════════════════════════
        -- Shaman
        -- ═══════════════════════════════════════
        ["Lightning Shield"] = 600,
        ["Water Shield"] = 600,
        ["Windfury Totem"] = 0,
        ["Strength of Earth Totem"] = 0,
        ["Grace of Air Totem"] = 0,
        ["Mana Spring Totem"] = 0,
        ["Mana Tide Totem"] = 12,
        ["Nature's Swiftness"] = 0,
        -- ═══════════════════════════════════════
        -- Consumables / Elixirs
        -- ═══════════════════════════════════════
        ["Flask of the Titans"] = 7200,
        ["Flask of Supreme Power"] = 7200,
        ["Flask of Distilled Wisdom"] = 7200,
        ["Flask of Chromatic Resistance"] = 7200,
        ["Greater Arcane Elixir"] = 3600,
        ["Elixir of the Mongoose"] = 3600,
        ["Elixir of Greater Firepower"] = 3600,
        ["Elixir of Brute Force"] = 3600,
        ["Elixir of the Giants"] = 3600,
        ["Elixir of Frost Power"] = 3600,
        ["Elixir of Shadow Power"] = 3600,
        ["Elixir of Greater Agility"] = 3600,
        ["Elixir of the Sages"] = 3600,
        ["Elixir of Greater Intellect"] = 3600,
        ["Elixir of Superior Defense"] = 3600,
        ["Elixir of Fortitude"] = 3600,
        ["Winterfall Firewater"] = 1200,
        ["Juju Power"] = 1800,
        ["Juju Might"] = 600,
        ["Juju Flurry"] = 20,
        ["R.O.I.D.S."] = 3600,
        ["Ground Scorpok Assay"] = 3600,
        ["Lung Juice Cocktail"] = 3600,
        ["Cerebral Cortex Compound"] = 3600,
        ["Gizzard Gum"] = 3600,
        ["Blessed Sunfruit"] = 3600,
        ["Blessed Sunfruit Juice"] = 3600,
        ["Dirge's Kickin' Chimaerok Chops"] = 3600,
        ["Runn Tum Tuber Surprise"] = 600,
        ["Mana Regeneration"] = 1800,
        ["Well Fed"] = 900,
        ["Food"] = 900,
        ["Drink"] = 900,
        -- ═══════════════════════════════════════
        -- World Buffs
        -- ═══════════════════════════════════════
        ["Spirit of Zanza"] = 7200,
        ["Rallying Cry of the Dragonslayer"] = 7200,
        ["Songflower Serenade"] = 3600,
        ["Fengus' Ferocity"] = 7200,
        ["Mol'dar's Moxie"] = 7200,
        ["Slip'kik's Savvy"] = 7200,
        ["Warchief's Blessing"] = 3600,
        ["Sayge's Dark Fortune of Damage"] = 7200,
        ["Sayge's Dark Fortune of Intelligence"] = 7200,
        ["Sayge's Dark Fortune of Spirit"] = 7200,
        ["Sayge's Dark Fortune of Stamina"] = 7200,
        ["Sayge's Dark Fortune of Strength"] = 7200,
        ["Sayge's Dark Fortune of Agility"] = 7200,
        ["Sayge's Dark Fortune of Armor"] = 7200,
        ["Sayge's Dark Fortune of Resistance"] = 7200,
    }

    -- 中文客户端：添加中文 buff 名称及持续时间（来源：Babble-Spell-2.2 + ShaguPlates locales_zhCN）
    if GetLocale() == "zhCN" then
        -- ═══ 永久光环（duration = 0）═══
        -- 圣骑士
        buffDurations["虔诚光环"] = 0
        buffDurations["惩罚光环"] = 0
        buffDurations["专注光环"] = 0
        buffDurations["圣洁光环"] = 0
        -- 术士
        buffDurations["灵魂联结"] = 0       -- Soul Link / Spirit Bond
        buffDurations["生命分流"] = 0
        -- 猎人
        buffDurations["强击光环"] = 0
        buffDurations["雄鹰守护"] = 0
        buffDurations["灵猴守护"] = 0
        buffDurations["猎豹守护"] = 0
        buffDurations["豹群守护"] = 0
        buffDurations["野性守护"] = 0
        -- 萨满
        buffDurations["风怒图腾"] = 0
        buffDurations["大地之力图腾"] = 0
        buffDurations["风之优雅图腾"] = 0
        buffDurations["法力之泉图腾"] = 0
        buffDurations["自然迅捷"] = 0
        -- 法师
        buffDurations["燃烧"] = 0
        -- ═══ 有持续时间的 buff ═══
        -- 牧师
        buffDurations["真言术：韧"] = 1800
        buffDurations["坚韧祷言"] = 3600
        buffDurations["真言术：盾"] = 30
        buffDurations["神圣之灵"] = 1800
        buffDurations["精神祷言"] = 3600
        buffDurations["防护暗影"] = 600
        buffDurations["暗影防护祷言"] = 1200
        buffDurations["心灵之火"] = 600
        buffDurations["恢复"] = 15
        buffDurations["防护恐惧结界"] = 600
        buffDurations["灵感"] = 15
        buffDurations["驱除疾病"] = 20
        buffDurations["艾露恩的赐福"] = 15
        -- 德鲁伊
        buffDurations["野性印记"] = 1800
        buffDurations["野性赐福"] = 3600
        buffDurations["荆棘"] = 600
        buffDurations["回春术"] = 12
        buffDurations["愈合"] = 21
        buffDurations["激活"] = 20
        buffDurations["树皮术"] = 15
        buffDurations["驱毒术"] = 8
        buffDurations["狂暴回复"] = 10
        -- 法师
        buffDurations["奥术智慧"] = 1800
        buffDurations["奥术光辉"] = 3600
        buffDurations["冰甲术"] = 1800
        buffDurations["霜甲术"] = 1800
        buffDurations["魔甲术"] = 1800
        buffDurations["寒冰护体"] = 60
        buffDurations["魔法抑制"] = 600
        buffDurations["魔法增效"] = 600
        buffDurations["奥术强化"] = 15
        buffDurations["防护火焰结界"] = 30
        buffDurations["防护冰霜结界"] = 30
        buffDurations["法力护盾"] = 60
        buffDurations["唤醒"] = 8
        -- 圣骑士
        buffDurations["力量祝福"] = 300
        buffDurations["智慧祝福"] = 300
        buffDurations["王者祝福"] = 300
        buffDurations["拯救祝福"] = 300
        buffDurations["光明祝福"] = 300
        buffDurations["庇护祝福"] = 300
        buffDurations["保护祝福"] = 10
        buffDurations["自由祝福"] = 16
        buffDurations["牺牲祝福"] = 30
        buffDurations["强效力量祝福"] = 900
        buffDurations["强效智慧祝福"] = 900
        buffDurations["强效王者祝福"] = 900
        buffDurations["强效拯救祝福"] = 900
        buffDurations["强效光明祝福"] = 900
        buffDurations["强效庇护祝福"] = 900
        buffDurations["圣盾术"] = 12
        buffDurations["圣佑术"] = 8
        buffDurations["神圣之盾"] = 10
        buffDurations["复仇之怒"] = 20
        -- 术士
        buffDurations["恶魔护甲"] = 1800
        buffDurations["恶魔皮肤"] = 1800
        buffDurations["魔息术"] = 600
        buffDurations["防护暗影结界"] = 30
        buffDurations["牺牲"] = 30
        buffDurations["恶魔支配"] = 15
        buffDurations["灵魂石复活"] = 1800
        -- 战士
        buffDurations["战斗怒吼"] = 120
        buffDurations["盾墙"] = 10
        buffDurations["破釜沉舟"] = 20
        buffDurations["狂暴之怒"] = 10
        buffDurations["鲁莽"] = 15
        buffDurations["反击风暴"] = 15
        buffDurations["血性狂暴"] = 10
        buffDurations["死亡之愿"] = 30
        buffDurations["激怒"] = 12
        buffDurations["盾牌格挡"] = 5
        buffDurations["嗜血"] = 8
        -- 猎人
        buffDurations["急速射击"] = 15
        buffDurations["狂野怒火"] = 18
        buffDurations["治疗宠物"] = 15
        buffDurations["快速射击"] = 12
        buffDurations["威慑"] = 10
        -- 盗贼
        buffDurations["闪避"] = 15
        buffDurations["疾跑"] = 15
        buffDurations["剑刃乱舞"] = 15
        buffDurations["冲动"] = 15
        buffDurations["消失"] = 10
        buffDurations["切割"] = 21
        -- 萨满
        buffDurations["闪电之盾"] = 600
        buffDurations["水盾"] = 600
        buffDurations["法力之潮图腾"] = 12
    end

    -- Threshold: any timeleft >= 24h is treated as a permanent aura (no timer)
    local PERMANENT_THRESHOLD = 86400

    -- Find the GetPlayerBuff index that matches a given texture from UnitBuff
    -- UnitBuff and GetPlayerBuff may NOT enumerate in the same order on Turtle WoW
    local function FindPlayerBuffIndex(texture, filter)
        if not texture then return nil end
        for idx = 0, 31 do
            local bIdx = GetPlayerBuff(idx, filter)
            if bIdx < 0 then return nil end
            if GetPlayerBuffTexture(bIdx) == texture then
                return bIdx
            end
        end
        return nil
    end

    -- Check if a player buff index corresponds to a permanent aura (buffDurations == 0)
    local function IsPermanentPlayerBuff(buffIndex)
        local scanner = DFUI_Libs and DFUI_Libs.libtipscan and DFUI_Libs.libtipscan:GetScanner("aura_timer")
        if scanner then
            scanner:SetPlayerBuff(buffIndex)
            local name = scanner:GetLine(1)
            if name and buffDurations[name] ~= nil and buffDurations[name] == 0 then
                return true
            end
        end
        return false
    end

    -- Look up duration by spell name (debuff table first, then buff table)
    local function LookupDuration(name)
        if not name then return nil end
        -- 永久/光环类法术（buffDurations 明确标记为 0）：绝不显示计时器
        if buffDurations[name] ~= nil and buffDurations[name] == 0 then
            return nil
        end
        -- 优先使用 Nampower 学习到的精确持续时间
        if learnedDurations[name] and learnedDurations[name] > 0 then
            return learnedDurations[name]
        end
        if libdebuff then
            local dur = libdebuff:GetDuration(name, nil)
            if dur and dur > 0 then return dur end
        end
        local dur = buffDurations[name]
        if dur and dur > 0 then return dur end
        return nil
    end

    -- Record a duration for a spell on a target
    local function TrackDuration(targetGuid, spellId, durationSec)
        if not targetGuid or not spellId or not durationSec or durationSec <= 0 then return end
        if not auraDurations[targetGuid] then auraDurations[targetGuid] = {} end
        local data = {
            start = GetTime(),
            duration = durationSec,
        }
        auraDurations[targetGuid][spellId] = data
        -- Also store by normalized texture as fallback key (in case BuildTexToSpellMap fails)
        local tex = CachedGetSpellIcon(spellId)
        if tex then
            auraDurations[targetGuid]["tex:" .. NormalizeTexture(tex)] = data
        end
    end

    -- Get tracked duration for a spell
    local function GetTrackedDuration(guid, spellId)
        if not guid or not spellId then return nil, nil end
        if auraDurations[guid] and auraDurations[guid][spellId] then
            local data = auraDurations[guid][spellId]
            local remaining = (data.start + data.duration) - GetTime()
            if remaining > 0 then
                return data.duration, remaining
            else
                auraDurations[guid][spellId] = nil
            end
        end
        return nil, nil
    end

    -- Build texture->spellId map from GetUnitField for a unit's auras
    local function BuildTexToSpellMap(guid)
        local map = {}
        if not guid then return map end
        if not GetUnitField then return map end
        local auras = GetUnitField(guid, "aura")
        if not auras then return map end
        for slot = 1, 48 do
            local spellId = auras[slot]
            if spellId and spellId > 0 then
                local tex = CachedGetSpellIcon(spellId)
                if tex then
                    map[NormalizeTexture(tex)] = spellId
                end
            end
        end
        return map
    end

    -- Time formatter: style = "Gold" (solid gold text) or "White + Red" (white number, red suffix)
    -- Long durations (>= 1h) show only hours (ceil) to fit small icons
    local function FormatTime(remaining, style, compact)
        local d = "d"
        local h = "h"
        local m = "m"
        local s = "s"
        if style and style ~= "Gold" then
            d = "|cffff0000d|r"
            h = "|cffff0000h|r"
            m = "|cffff0000m|r"
            s = "|cffff0000s|r"
        end

        if compact then
            -- 框体小图标：单单位紧凑显示
            if remaining >= 86400 then
                return math.floor(remaining / 86400) .. d
            elseif remaining >= 3600 then
                return math.ceil(remaining / 3600) .. h
            elseif remaining >= 60 then
                return math.ceil(remaining / 60) .. m
            else
                return tostring(math.floor(remaining))
            end
        end

        -- Buff Bar 大图标：时钟格式
        if remaining >= 86400 then
            return math.floor(remaining / 86400) .. d
        elseif remaining >= 3600 then
            local hours = math.floor(remaining / 3600)
            local mins = math.floor((remaining - hours * 3600) / 60)
            return string.format("%02d:%02d", hours, mins)
        elseif remaining >= 60 then
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining - mins * 60)
            return string.format("%02d:%02d", mins, secs)
        else
            return tostring(math.floor(remaining))
        end
    end

    -- Get timer style setting for a given prefix (player/target/pet/party)
    local function GetTimerStyle(prefix)
        return DFUI:GetTempDB("Auras", prefix .. "TimerStyle") or "White + Red"
    end

    local function GetTimerFontSize(prefix)
        return DFUI:GetTempDB("Auras", prefix .. "TimerFontSize") or 8
    end

    -- Apply timer color based on style
    local function ApplyTimerColor(fontString, style)
        if style == "Gold" then
            fontString:SetTextColor(1.0, 0.82, 0)
        else
            fontString:SetTextColor(1, 1, 1)
        end
    end

    -------------------------------------------------------------------
    -- Event tracking for buff/debuff durations (UNIT_CASTEVENT + Nampower)
    -------------------------------------------------------------------

    local castTracker = CreateFrame("Frame")
    castTracker:RegisterEvent("UNIT_CASTEVENT")
    castTracker:SetScript("OnEvent", function()
        local casterGuid = arg1
        local targetGuid = arg2
        local eventType = arg3
        local spellId = arg4

        if eventType == "CAST" and targetGuid and targetGuid ~= "" and spellId then
            local name = CachedGetSpellName(spellId)
            local dur = LookupDuration(name)
            if dur then
                TrackDuration(targetGuid, spellId, dur)
            end
            -- 桥接到 libdebuff（像 pfUI 一样，增强 debuff 计时覆盖）
            if libdebuff and name and dur then
                local libguid = DFUI_Libs and DFUI_Libs.libguid
                if libguid and libguid.guidMap then
                    local gdata = libguid.guidMap[targetGuid]
                    if gdata and gdata.name then
                        libdebuff:AddEffect(gdata.name, gdata.level or 0, name, dur, nil, targetGuid)
                    end
                end
            end
        end
    end)

    -- Nampower AURA_CAST events (exact duration in ms)
    pcall(function()
        local nampowerTracker = CreateFrame("Frame")
        nampowerTracker:RegisterEvent("AURA_CAST_ON_SELF")
        nampowerTracker:RegisterEvent("AURA_CAST_ON_OTHER")
        nampowerTracker:SetScript("OnEvent", function()
            local spellId = arg1
            local casterGuid = arg2
            local targetGuid = arg3
            local durationMs = arg8

            if not targetGuid or targetGuid == "" then
                targetGuid = casterGuid
            end

            if targetGuid and spellId and durationMs and type(durationMs) == "number" and durationMs > 0 and durationMs < PERMANENT_THRESHOLD * 1000 then
                local name = CachedGetSpellName(spellId)
                -- 跳过永久/光环类法术（buffDurations 明确标记为 0）
                local isPermanent = name and buffDurations[name] ~= nil and buffDurations[name] == 0
                if not isPermanent then
                    TrackDuration(targetGuid, spellId, durationMs / 1000)
                    if name then
                        learnedDurations[name] = durationMs / 1000
                        -- 桥接到 libdebuff（精确 ms 数据，比 pfUI 更强）
                        if libdebuff then
                            local libguid = DFUI_Libs and DFUI_Libs.libguid
                            if libguid and libguid.guidMap then
                                local gdata = libguid.guidMap[targetGuid]
                                if gdata and gdata.name then
                                    libdebuff:AddEffect(gdata.name, gdata.level or 0, name, durationMs / 1000, nil, targetGuid)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)

    -- Aura snapshots table (declared early so cleanup can reference it)
    local auraSnapshots = {}  -- [guid] = { [spellId] = true, ... }

    -- Periodic cleanup of expired durations (every 60s)
    local cleanupTick = 0
    castTracker:SetScript("OnUpdate", function()
        if cleanupTick > GetTime() then return end
        cleanupTick = GetTime() + 60
        local now = GetTime()
        for guid, spells in pairs(auraDurations) do
            local empty = true
            for spellId, data in pairs(spells) do
                if data.start + data.duration < now then
                    spells[spellId] = nil
                else
                    empty = false
                end
            end
            if empty then
                auraDurations[guid] = nil
                auraSnapshots[guid] = nil
            end
        end
    end)

    -------------------------------------------------------------------
    -- Aura snapshot diffing (detect new auras on non-player units)
    -------------------------------------------------------------------

    -- Texture-based snapshots for units (fallback when GetUnitField unavailable)
    local textureSnapshots = {}  -- [unit] = { [normalizedTex] = true, ... }

    -- Seed snapshot for a unit (pure snapshot, no timer creation)
    -- Only records current aura state for diff detection by SnapshotAndDetectNewAuras
    local function SeedSnapshot(guid, unit)
        -- SpellId-based snapshot (requires GetUnitField / SuperWoW)
        if guid and GetUnitField then
            local auras = GetUnitField(guid, "aura")
            if auras then
                local snap = {}
                for slot = 1, 48 do
                    local spellId = auras[slot]
                    if spellId and spellId > 0 then
                        snap[spellId] = true
                    end
                end
                auraSnapshots[guid] = snap
            end
        end
        -- Texture-based snapshot (always works, as fallback)
        if unit then
            local texSnap = {}
            for i = 1, 16 do
                local tex = UnitBuff(unit, i)
                if tex then texSnap[NormalizeTexture(tex)] = true end
            end
            for i = 1, 16 do
                local tex = UnitDebuff(unit, i)
                if tex then texSnap[NormalizeTexture(tex)] = true end
            end
            textureSnapshots[unit] = texSnap
        end
    end

    -- Detect newly appeared auras and start timers for them
    local function SnapshotAndDetectNewAuras(guid, unit)
        if not guid then return end

        -- === SpellId-based detection (GetUnitField available) ===
        if GetUnitField then
            local auras = GetUnitField(guid, "aura")
            if auras then
                local oldSnap = auraSnapshots[guid] or {}
                local newSnap = {}
                for slot = 1, 48 do
                    local spellId = auras[slot]
                    if spellId and spellId > 0 then
                        newSnap[spellId] = true
                        if not oldSnap[spellId] then
                            if not (auraDurations[guid] and auraDurations[guid][spellId]) then
                                local name = CachedGetSpellName(spellId)
                                local dur = LookupDuration(name)
                                if dur and dur > 0 then
                                    TrackDuration(guid, spellId, dur)
                                end
                            end
                        end
                    end
                end
                auraSnapshots[guid] = newSnap
            end
        end

        -- === Texture-based detection (always works as fallback) ===
        if unit then
            local oldTexSnap = textureSnapshots[unit] or {}
            local newTexSnap = {}
            -- Scan buffs
            for i = 1, 16 do
                local tex = UnitBuff(unit, i)
                if not tex then break end
                local normTex = NormalizeTexture(tex)
                newTexSnap[normTex] = true
                if not oldTexSnap[normTex] then
                    -- New buff appeared — try to find duration by tooltip name
                    local texKey = "tex:" .. normTex
                    if not (auraDurations[guid] and auraDurations[guid][texKey]) then
                        local tipScanner = DFUI_Libs and DFUI_Libs.libtipscan and DFUI_Libs.libtipscan:GetScanner("aura_snap")
                        if tipScanner then
                            tipScanner:SetUnitBuff(unit, i)
                            local name = tipScanner:GetLine(1)
                            if name and name ~= "" then
                                local dur = LookupDuration(name)
                                if dur and dur > 0 then
                                    if not auraDurations[guid] then auraDurations[guid] = {} end
                                    local d = { start = GetTime(), duration = dur }
                                    auraDurations[guid][texKey] = d
                                end
                            end
                        end
                    end
                end
            end
            -- Scan debuffs
            for i = 1, 16 do
                local tex = UnitDebuff(unit, i)
                if not tex then break end
                local normTex = NormalizeTexture(tex)
                newTexSnap[normTex] = true
                if not oldTexSnap[normTex] then
                    local texKey = "tex:" .. normTex
                    if not (auraDurations[guid] and auraDurations[guid][texKey]) then
                        local tipScanner = DFUI_Libs and DFUI_Libs.libtipscan and DFUI_Libs.libtipscan:GetScanner("aura_snap")
                        if tipScanner then
                            tipScanner:SetUnitDebuff(unit, i)
                            local name = tipScanner:GetLine(1)
                            if name and name ~= "" then
                                local dur = LookupDuration(name)
                                if dur and dur > 0 then
                                    if not auraDurations[guid] then auraDurations[guid] = {} end
                                    local d = { start = GetTime(), duration = dur }
                                    auraDurations[guid][texKey] = d
                                end
                            end
                        end
                    end
                end
            end
            textureSnapshots[unit] = newTexSnap
        end
    end

    -------------------------------------------------------------------
    -- Unit data
    -------------------------------------------------------------------

    local unitData = {
        player = { buffs = {}, debuffs = {}, unit = "player" },
        target = { buffs = {}, debuffs = {}, unit = "target" },
        pet    = { buffs = {}, debuffs = {}, unit = "pet" },
    }
    local partyData = {}
    for i = 1, 4 do
        partyData[i] = { buffs = {}, debuffs = {}, unit = "party" .. i }
    end

    -------------------------------------------------------------------
    -- Hide default Blizzard target buff/debuff frames
    -------------------------------------------------------------------

    local function HideBlizzardTargetAuras()
        -- Turtle 客户端把 TargetFrameBuff/Debuff 扩展到了 32 个槽（vanilla 只有 16）。
        -- 不隐藏 17-32 会在目标框下方留下 8+ 个空白框。
        for i = 1, 32 do
            local buff = _G["TargetFrameBuff" .. i]
            if buff then
                buff:Hide()
                buff:SetScript("OnShow", function() this:Hide() end)
            end
            local debuff = _G["TargetFrameDebuff" .. i]
            if debuff then
                debuff:Hide()
                debuff:SetScript("OnShow", function() this:Hide() end)
                -- 隐藏 ShaguTweaks Debuff Timer 创建的 cooldown + readable 文字
                if debuff.cd then
                    debuff.cd:Hide()
                    if debuff.cd.readable then debuff.cd.readable:Hide() end
                end
            end
        end
    end

    HideBlizzardTargetAuras()

    -- also hook TargetFrame_UpdateAuras to keep them hidden
    if _G.TargetFrame_UpdateAuras then
        local origTargetFrame_UpdateAuras = _G.TargetFrame_UpdateAuras
        _G.TargetFrame_UpdateAuras = function(a1, a2, a3, a4, a5)
            origTargetFrame_UpdateAuras(a1, a2, a3, a4, a5)
            HideBlizzardTargetAuras()
        end
    end

    -- 彻底禁用暴雪原生 debuff 按钮更新（同时切断 ShaguTweaks Debuff Timer 的 hook 链）
    if _G.TargetDebuffButton_Update then
        _G.TargetDebuffButton_Update = function() end
    end

    -------------------------------------------------------------------
    -- Hide default Blizzard party buff tooltip & icons
    -------------------------------------------------------------------

    -- Suppress the party member buff tooltip that appears on hover
    if PartyMemberBuffTooltip then
        PartyMemberBuffTooltip:Hide()
        PartyMemberBuffTooltip.Show = function(self) self:Hide() end
    end

    -- Disable the default party buff refresh (creates default buff icons on party frames)
    if RefreshBuffs then
        RefreshBuffs = function() end
    end

    -- Hide default party member buff/debuff frames
    local function HideBlizzardPartyAuras()
        for p = 1, 4 do
            for i = 1, 4 do
                local buff = _G["PartyMemberFrame" .. p .. "Buff" .. i]
                if buff then
                    buff:Hide()
                    buff:SetScript("OnShow", function() this:Hide() end)
                end
            end
            for i = 1, 4 do
                local debuff = _G["PartyMemberFrame" .. p .. "Debuff" .. i]
                if debuff then
                    debuff:Hide()
                    debuff:SetScript("OnShow", function() this:Hide() end)
                end
            end
        end
    end

    HideBlizzardPartyAuras()

    -- Hide default pet buff/debuff frames
    local function HideBlizzardPetAuras()
        for i = 1, 4 do
            local buff = _G["PetFrameBuff" .. i]
            if buff then
                buff:Hide()
                buff:SetScript("OnShow", function() this:Hide() end)
            end
            local debuff = _G["PetFrameDebuff" .. i]
            if debuff then
                debuff:Hide()
                debuff:SetScript("OnShow", function() this:Hide() end)
            end
        end
    end

    HideBlizzardPetAuras()

    -- Re-hide after Blizzard updates party frames
    if _G.PartyMemberFrame_UpdateMember then
        local origPartyUpdate = _G.PartyMemberFrame_UpdateMember
        _G.PartyMemberFrame_UpdateMember = function(a1, a2, a3, a4, a5)
            origPartyUpdate(a1, a2, a3, a4, a5)
            HideBlizzardPartyAuras()
        end
    end

    if _G.PetFrame_Update then
        local origPetUpdate = _G.PetFrame_Update
        _G.PetFrame_Update = function(a1, a2, a3, a4, a5)
            origPetUpdate(a1, a2, a3, a4, a5)
            HideBlizzardPetAuras()
        end
    end

    -------------------------------------------------------------------
    -- Button creation
    -------------------------------------------------------------------

    -- create a high-level container for aura buttons so they render above pet/party frames
    local function CreateAuraContainer(parent, name)
        local container = CreateFrame("Frame", name, parent)
        container:SetAllPoints(parent)
        container:SetFrameStrata("MEDIUM")
        container:SetFrameLevel(10)
        return container
    end

    -- Aura anchor: positioned relative to parent unit frame, offset via settings sliders
    local function CreateAuraAnchor(parent, name, xOffset, yOffset, anchorPoint, relPoint)
        local anchor = CreateFrame("Frame", name, UIParent)
        anchor:SetWidth(16)
        anchor:SetHeight(16)
        anchor:SetFrameStrata("MEDIUM")
        anchor:SetFrameLevel(10)
        anchor:SetPoint(anchorPoint, parent, relPoint, xOffset, yOffset)
        return anchor
    end

    local function RepositionAnchor(anchor, parent, anchorPoint, relPoint, xOffset, yOffset)
        anchor:ClearAllPoints()
        anchor:SetPoint(anchorPoint, parent, relPoint, xOffset, yOffset)
    end

    -- 从设置读取偏移值
    local pAX = DFUI:GetTempDB("Auras", "playerAuraX") or 100
    local pAY = DFUI:GetTempDB("Auras", "playerAuraY") or -68
    local tAX = DFUI:GetTempDB("Auras", "targetAuraX") or -100
    local tAY = DFUI:GetTempDB("Auras", "targetAuraY") or -68
    local petAX = DFUI:GetTempDB("Auras", "petAuraX") or 30
    local petAY = DFUI:GetTempDB("Auras", "petAuraY") or -2
    local parAX = DFUI:GetTempDB("Auras", "partyAuraX") or 30
    local parAY = DFUI:GetTempDB("Auras", "partyAuraY") or -2

    local playerAnchor = CreateAuraAnchor(PlayerFrame, "DFUI_AuraAnchor_Player", pAX, pAY, "TOPLEFT", "TOPLEFT")
    local targetAnchor = CreateAuraAnchor(TargetFrame, "DFUI_AuraAnchor_Target", tAX, tAY, "TOPRIGHT", "TOPRIGHT")
    local petAnchor = CreateAuraAnchor(PetFrame, "DFUI_AuraAnchor_Pet", petAX, petAY, "TOPLEFT", "BOTTOMLEFT")
    local partyAnchors = {}
    for i = 1, 4 do
        local pf = _G["PartyMemberFrame" .. i]
        if pf then
            partyAnchors[i] = CreateAuraAnchor(pf, "DFUI_AuraAnchor_Party" .. i, parAX, parAY, "TOPLEFT", "BOTTOMLEFT")
        end
    end

    -- containers for aura buttons (parented to UIParent so strata works)
    local playerAuraContainer = CreateAuraContainer(UIParent, "DFUI_PlayerAuras")
    local targetAuraContainer = CreateAuraContainer(UIParent, "DFUI_TargetAuras")
    local petAuraContainer = CreateAuraContainer(UIParent, "DFUI_PetAuras")
    local partyAuraContainers = {}
    for i = 1, 4 do
        local pf = _G["PartyMemberFrame" .. i]
        if pf then
            partyAuraContainers[i] = CreateAuraContainer(UIParent, "DFUI_PartyAuras" .. i)
        end
    end

    local function CreateAuraButton(parent, unit, index, isDebuff)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetWidth(20)
        btn:SetHeight(20)
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints(btn)
        if isDebuff then
            btn.border = btn:CreateTexture(nil, "OVERLAY")
            btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
            btn.border:SetAllPoints(btn)
            btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
        end
        btn.cooldown = CreateFrame("Model", nil, btn, "CooldownFrameTemplate")
        btn.cooldown:SetAllPoints(btn)
        btn.cooldown.noCooldownCount = true
        btn.cooldown:Hide()
        btn.timer = btn:CreateFontString(nil, "OVERLAY")
        btn.timer:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        btn.timer:SetTextColor(1, 1, 1)
        btn.timer:SetPoint("BOTTOM", btn, "BOTTOM", 0, -2)
        btn.timer:SetJustifyH("CENTER")
        btn.timer:Hide()
        if isDebuff then
            btn.count = btn:CreateFontString(nil, "OVERLAY")
            btn.count:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
            btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            btn.count:Hide()
            btn.debuffIndex = index
        else
            btn.buffIndex = index
        end
        btn.parentUnit = unit
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            if isDebuff then
                GameTooltip:SetUnitDebuff(this.parentUnit, this.debuffIndex)
            else
                GameTooltip:SetUnitBuff(this.parentUnit, this.buffIndex)
            end
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        btn:Hide()
        return btn
    end

    local function CreateAuraRow(parent, unit, isDebuff)
        local btns = {}
        for i = 1, 16 do
            btns[i] = CreateAuraButton(parent, unit, i, isDebuff)
        end
        return btns
    end

    -------------------------------------------------------------------
    -- Layout helpers (compact - no gaps between visible icons)
    -------------------------------------------------------------------

    local function LayoutAuras(buttons, anchor, anchorPoint, relPoint, xOff, yOff, growRight, iconSize, iconSpacing, perRow, extraRowOffset)
        local step = iconSize + iconSpacing
        local visCount = 0
        for i = 1, 16 do
            if buttons[i]:IsShown() then
                local row = math.floor(visCount / perRow) + (extraRowOffset or 0)
                local col = math.mod(visCount, perRow)
                local colOff = growRight and (col * step) or (-col * step)
                buttons[i]:ClearAllPoints()
                buttons[i]:SetPoint(anchorPoint, anchor, relPoint, colOff + xOff, -row * step + yOff)
                visCount = visCount + 1
            end
        end
        return visCount
    end

    -------------------------------------------------------------------
    -- Update functions
    -------------------------------------------------------------------

    local function UpdateBuffs(data, anchor, anchorPoint, relPoint, xOff, yOff, growRight, showTimer, iconSize, iconSpacing, perRow, timerStyle, timerFontSize)
        local visible = 0
        local guid = nil
        local texToSpell = {}
        timerStyle = timerStyle or "White + Red"
        timerFontSize = timerFontSize or 12

        -- Build texture-to-spellId map if we need timers
        if showTimer then
            if data.unit == "player" then
                local _, g = UnitExists("player")
                guid = g
            elseif data.unit == "target" then
                local _, g = UnitExists("target")
                guid = g
            elseif data.unit == "pet" then
                local _, g = UnitExists("pet")
                guid = g
            elseif string.find(data.unit, "party") then
                local _, g = UnitExists(data.unit)
                guid = g
            end
            if guid then
                texToSpell = BuildTexToSpellMap(guid)
            end
        end

        for i = 1, 16 do
            local texture = UnitBuff(data.unit, i)
            if texture then
                -- 检测 buff 变化，清除残留计时器
                local oldTex = data.buffs[i].icon:GetTexture()
                if oldTex and oldTex ~= texture then
                    data.buffs[i].timerStart = nil
                    data.buffs[i].timerDuration = nil
                end
                data.buffs[i].icon:SetTexture(texture)
                data.buffs[i]:SetWidth(iconSize)
                data.buffs[i]:SetHeight(iconSize)
                data.buffs[i].timer:SetFont("Fonts\\FRIZQT__.TTF", timerFontSize, "OUTLINE")
                ApplyTimerColor(data.buffs[i].timer, timerStyle)

                -- Buff timer resolution cascade
                if showTimer then
                    local duration, timeleft = nil, nil

                    -- Check if this buff is a permanent aura (should never show timer)
                    local isPermanentBuff = false
                    local playerBIdx = nil
                    local tipScanner = DFUI_Libs and DFUI_Libs.libtipscan and DFUI_Libs.libtipscan:GetScanner("aura_timer")
                    if tipScanner then
                        if data.unit == "player" then
                            -- Match by texture instead of assuming i-1 index alignment
                            playerBIdx = FindPlayerBuffIndex(texture, "HELPFUL")
                            if playerBIdx and playerBIdx >= 0 then
                                tipScanner:SetPlayerBuff(playerBIdx)
                            end
                        else
                            tipScanner:SetUnitBuff(data.unit, i)
                        end
                        local buffName = tipScanner:GetLine(1)
                        if buffName and buffDurations[buffName] ~= nil and buffDurations[buffName] == 0 then
                            isPermanentBuff = true
                        end
                    end

                    if not isPermanentBuff then
                    -- 1) Player PRIMARY: GetPlayerBuffTimeLeft via texture-matched index
                    if data.unit == "player" and GetPlayerBuffTimeLeft then
                        local bIdx = playerBIdx or FindPlayerBuffIndex(texture, "HELPFUL")
                        if bIdx and bIdx >= 0 then
                            local tl = GetPlayerBuffTimeLeft(bIdx)
                            if tl and tl > 0 and tl < PERMANENT_THRESHOLD then
                                timeleft = tl
                                -- maxdurations 缓存：记录该纹理最大 timeleft，收敛到真实总持续时间
                                local normTex = NormalizeTexture(texture)
                                if normTex then
                                    if not maxdurations[normTex] or maxdurations[normTex] < tl then
                                        maxdurations[normTex] = tl
                                    end
                                    duration = maxdurations[normTex]
                                else
                                    duration = tl
                                end
                            end
                        end
                    end

                    -- 2) GUID-based tracking (UNIT_CASTEVENT / Nampower)
                    if not timeleft and guid then
                        local spellId = texToSpell[NormalizeTexture(texture)]
                        duration, timeleft = GetTrackedDuration(guid, spellId)
                        if not timeleft then
                            duration, timeleft = GetTrackedDuration(guid, "tex:" .. NormalizeTexture(texture))
                        end
                    end

                    -- 3) Pet fallback: tooltip scan + LookupDuration
                    --    宠物 buff 来源明确（玩家施放），start=GetTime() 基本准确
                    if not timeleft and data.unit == "pet" and not data.buffs[i].timerStart then
                        local scanner = DFUI_Libs and DFUI_Libs.libtipscan and DFUI_Libs.libtipscan:GetScanner("aura_timer")
                        if scanner then
                            scanner:SetUnitBuff(data.unit, i)
                            local bname = scanner:GetLine(1)
                            if bname and bname ~= "" then
                                local dur = LookupDuration(bname)
                                if dur and dur > 0 then
                                    timeleft = dur
                                    duration = dur
                                end
                            end
                        end
                    end
                    end -- isPermanentBuff

                    if duration and timeleft and timeleft > 0 then
                        data.buffs[i].timer:SetText(FormatTime(timeleft, timerStyle, true))
                        data.buffs[i].timer:Show()
                        data.buffs[i].timerStart = GetTime() + timeleft - duration
                        data.buffs[i].timerDuration = duration
                        data.buffs[i].timerStyle = timerStyle
                    else
                        if not data.buffs[i].timerStart then
                            data.buffs[i].timer:Hide()
                        end
                    end
                else
                    data.buffs[i].timer:Hide()
                    data.buffs[i].timerStart = nil
                    data.buffs[i].timerDuration = nil
                end
                if data.buffs[i].cooldown then data.buffs[i].cooldown:Hide() end

                data.buffs[i]:Show()
                visible = visible + 1
            else
                data.buffs[i]:Hide()
                data.buffs[i].timer:Hide()
                data.buffs[i].timerStart = nil
                data.buffs[i].timerDuration = nil
            end
        end
        if visible > 0 then
            LayoutAuras(data.buffs, anchor, anchorPoint, relPoint, xOff, yOff, growRight, iconSize, iconSpacing, perRow)
        end
        return visible
    end

    local function UpdateDebuffs(data, anchor, anchorPoint, relPoint, xOff, yOff, growRight, extraRowOffset, showTimer, iconSize, iconSpacing, perRow, timerStyle, timerFontSize, showSpiral)
        if showTimer == nil then showTimer = true end
        extraRowOffset = extraRowOffset or 0
        timerStyle = timerStyle or "White + Red"
        timerFontSize = timerFontSize or 12

        local guid = nil
        local texToSpell = {}

        -- Build texture-to-spellId map for debuff timers too
        if showTimer then
            if data.unit == "player" then
                local _, g = UnitExists("player")
                guid = g
            elseif data.unit == "target" then
                local _, g = UnitExists("target")
                guid = g
            elseif data.unit == "pet" then
                local _, g = UnitExists("pet")
                guid = g
            elseif string.find(data.unit, "party") then
                local _, g = UnitExists(data.unit)
                guid = g
            end
            if guid then
                texToSpell = BuildTexToSpellMap(guid)
            end
        end

        for i = 1, 16 do
            local texture, stacks, debuffType = UnitDebuff(data.unit, i)
            if texture then
                -- 检测 debuff 变化，清除残留计时器
                local oldTex = data.debuffs[i].icon:GetTexture()
                if oldTex and oldTex ~= texture then
                    data.debuffs[i].timerStart = nil
                    data.debuffs[i].timerDuration = nil
                end
                data.debuffs[i].icon:SetTexture(texture)
                data.debuffs[i]:SetWidth(iconSize)
                data.debuffs[i]:SetHeight(iconSize)
                -- debuff type border color
                local color = DEBUFF_COLORS[debuffType] or DEBUFF_COLORS.none
                data.debuffs[i].border:SetVertexColor(color[1], color[2], color[3])
                -- stack count
                if stacks and stacks > 1 then
                    data.debuffs[i].count:SetText(stacks)
                    data.debuffs[i].count:SetTextColor(0, 1, 0)
                    data.debuffs[i].count:Show()
                else
                    data.debuffs[i].count:Hide()
                end
                data.debuffs[i].timer:SetFont("Fonts\\FRIZQT__.TTF", timerFontSize, "OUTLINE")
                ApplyTimerColor(data.debuffs[i].timer, timerStyle)
                -- debuff timer: try auraDurations first (GUID-based), fall back to libdebuff
                if showTimer then
                    local duration, timeleft = nil, nil

                    -- 1) Player PRIMARY: GetPlayerBuffTimeLeft via texture-matched index
                    if data.unit == "player" and GetPlayerBuffTimeLeft then
                        local bIdx = FindPlayerBuffIndex(texture, "HARMFUL")
                        if bIdx and bIdx >= 0 then
                            local tl = GetPlayerBuffTimeLeft(bIdx)
                            if tl and tl > 0 and tl < PERMANENT_THRESHOLD then
                                timeleft = tl
                                -- maxdurations 缓存：记录该纹理最大 timeleft，收敛到真实总持续时间
                                local normTex = NormalizeTexture(texture)
                                if normTex then
                                    if not maxdurations[normTex] or maxdurations[normTex] < tl then
                                        maxdurations[normTex] = tl
                                    end
                                    duration = maxdurations[normTex]
                                else
                                    duration = tl
                                end
                            end
                        end
                    end

                    -- 2) GUID-based tracking (UNIT_CASTEVENT / Nampower)
                    if not timeleft and guid then
                        local spellId = texToSpell[NormalizeTexture(texture)]
                        duration, timeleft = GetTrackedDuration(guid, spellId)
                        if not timeleft then
                            duration, timeleft = GetTrackedDuration(guid, "tex:" .. NormalizeTexture(texture))
                        end
                    end

                    -- 3) libdebuff name-based tracking (player/pet only)
                    if not timeleft and libdebuff and (data.unit == "player" or data.unit == "pet") then
                        local _, _, _, _, _, dur, tl = libdebuff:UnitDebuff(data.unit, i)
                        if tl and tl > 0 then
                            duration = dur
                            timeleft = tl
                        end
                    end

                    -- 4) Pet fallback: tooltip scan + LookupDuration
                    if not timeleft and data.unit == "pet" and not data.debuffs[i].timerStart then
                        local scanner = DFUI_Libs and DFUI_Libs.libtipscan and DFUI_Libs.libtipscan:GetScanner("aura_timer")
                        if scanner then
                            scanner:SetUnitDebuff(data.unit, i)
                            local dname = scanner:GetLine(1)
                            if dname and dname ~= "" then
                                local dur = LookupDuration(dname)
                                if dur and dur > 0 then
                                    timeleft = dur
                                    duration = dur
                                end
                            end
                        end
                    end

                    if duration and timeleft and timeleft > 0 then
                        data.debuffs[i].timer:SetText(FormatTime(timeleft, timerStyle, true))
                        data.debuffs[i].timer:Show()
                        data.debuffs[i].timerStart = GetTime() + timeleft - duration
                        data.debuffs[i].timerDuration = duration
                        data.debuffs[i].timerStyle = timerStyle
                    else
                        if not data.debuffs[i].timerStart then
                            data.debuffs[i].timer:Hide()
                        end
                    end
                    if data.debuffs[i].cooldown then
                        if showSpiral and duration and timeleft and timeleft > 0 then
                            local start = GetTime() + timeleft - duration
                            CooldownFrame_SetTimer(data.debuffs[i].cooldown, start, duration, 1)
                        else
                            data.debuffs[i].cooldown:Hide()
                        end
                    end
                else
                    data.debuffs[i].timer:Hide()
                    data.debuffs[i].timerStart = nil
                    data.debuffs[i].timerDuration = nil
                    if data.debuffs[i].cooldown then data.debuffs[i].cooldown:Hide() end
                end
                data.debuffs[i]:Show()
            else
                data.debuffs[i]:Hide()
                data.debuffs[i].timer:Hide()
                data.debuffs[i].timerStart = nil
                data.debuffs[i].timerDuration = nil
            end
        end
        LayoutAuras(data.debuffs, anchor, anchorPoint, relPoint, xOff, yOff, growRight, iconSize, iconSpacing, perRow, extraRowOffset)
    end

    local function CountVisibleBuffRows(data, perRow)
        if not data.buffs then return 0 end
        local count = 0
        for i = 1, 16 do
            if data.buffs[i] and data.buffs[i]:IsShown() then
                count = count + 1
            end
        end
        if count == 0 then return 0 end
        return math.floor((count - 1) / perRow) + 1
    end

    -------------------------------------------------------------------
    -- Create aura buttons (parented to high-level containers)
    -------------------------------------------------------------------

    unitData.player.buffs = CreateAuraRow(playerAuraContainer, "player", false)
    unitData.player.debuffs = CreateAuraRow(playerAuraContainer, "player", true)

    unitData.target.buffs = CreateAuraRow(targetAuraContainer, "target", false)
    unitData.target.debuffs = CreateAuraRow(targetAuraContainer, "target", true)

    unitData.pet.buffs = CreateAuraRow(petAuraContainer, "pet", false)
    unitData.pet.debuffs = CreateAuraRow(petAuraContainer, "pet", true)

    for i = 1, 4 do
        if partyAuraContainers[i] then
            partyData[i].buffs = CreateAuraRow(partyAuraContainers[i], "party" .. i, false)
            partyData[i].debuffs = CreateAuraRow(partyAuraContainers[i], "party" .. i, true)
        end
    end

    -------------------------------------------------------------------
    -- Per-frame update functions
    -------------------------------------------------------------------

    local function UpdatePlayerAuras()
        local showBuffs = DFUI:GetTempDB("Auras", "playerBuffs")
        local showDebuffs = DFUI:GetTempDB("Auras", "playerDebuffs")
        local showBuffTimer = DFUI:GetTempDB("Auras", "playerShowBuffTimer")
        local showDebuffTimer = DFUI:GetTempDB("Auras", "playerShowDebuffTimer")
        local growRight = DFUI:GetTempDB("Auras", "playerGrowRight")
        if growRight == nil then growRight = true end
        local showSpiral = DFUI:GetTempDB("Auras", "playerShowSpiral")
        if showSpiral == nil then showSpiral = true end
        local sz = GetAuraSize("player")
        local sp = GetAuraSpacing("player")
        local pr = GetAurasPerRow("player")
        local step = sz + sp
        local tStyle = GetTimerStyle("player")
        local tSize = GetTimerFontSize("player")

        if showBuffs then
            UpdateBuffs(unitData.player, playerAnchor, "TOPLEFT", "TOPLEFT", 0, 0, growRight, showBuffTimer, sz, sp, pr, tStyle, tSize)
        else
            for i = 1, 16 do unitData.player.buffs[i]:Hide() end
        end

        local buffRows = showBuffs and CountVisibleBuffRows(unitData.player, pr) or 0

        if showDebuffs then
            UpdateDebuffs(unitData.player, playerAnchor, "TOPLEFT", "TOPLEFT", 0, -buffRows * step, growRight, 0, showDebuffTimer, sz, sp, pr, tStyle, tSize, showSpiral)
        else
            for i = 1, 16 do unitData.player.debuffs[i]:Hide() end
        end
    end

    local function UpdateTargetAuras()
        local showBuffs = DFUI:GetTempDB("Auras", "targetBuffs")
        local showDebuffs = DFUI:GetTempDB("Auras", "targetDebuffs")
        local showBuffTimer = DFUI:GetTempDB("Auras", "targetShowBuffTimer")
        local showDebuffTimer = DFUI:GetTempDB("Auras", "targetShowDebuffTimer")
        local growRight = DFUI:GetTempDB("Auras", "targetGrowRight")
        if growRight == nil then growRight = false end
        local showSpiral = DFUI:GetTempDB("Auras", "targetShowSpiral")
        if showSpiral == nil then showSpiral = true end
        local sz = GetAuraSize("target")
        local sp = GetAuraSpacing("target")
        local pr = GetAurasPerRow("target")
        local step = sz + sp
        local tStyle = GetTimerStyle("target")
        local tSize = GetTimerFontSize("target")

        if showBuffs then
            UpdateBuffs(unitData.target, targetAnchor, "TOPRIGHT", "TOPRIGHT", 0, 0, growRight, showBuffTimer, sz, sp, pr, tStyle, tSize)
        else
            for i = 1, 16 do unitData.target.buffs[i]:Hide() end
        end

        local buffRows = showBuffs and CountVisibleBuffRows(unitData.target, pr) or 0

        if showDebuffs then
            UpdateDebuffs(unitData.target, targetAnchor, "TOPRIGHT", "TOPRIGHT", 0, -buffRows * step, growRight, 0, showDebuffTimer, sz, sp, pr, tStyle, tSize, showSpiral)
        else
            for i = 1, 16 do unitData.target.debuffs[i]:Hide() end
        end

        HideBlizzardTargetAuras()
    end

    local function UpdatePetAuras()
        local showBuffs = DFUI:GetTempDB("Auras", "petBuffs")
        local showDebuffs = DFUI:GetTempDB("Auras", "petDebuffs")
        local showBuffTimer = DFUI:GetTempDB("Auras", "petShowBuffTimer")
        local showDebuffTimer = DFUI:GetTempDB("Auras", "petShowDebuffTimer")
        local growRight = DFUI:GetTempDB("Auras", "petGrowRight")
        if growRight == nil then growRight = true end
        local showSpiral = DFUI:GetTempDB("Auras", "petShowSpiral")
        if showSpiral == nil then showSpiral = true end
        local sz = GetAuraSize("pet")
        local sp = GetAuraSpacing("pet")
        local pr = GetAurasPerRow("pet")
        local step = sz + sp
        local tStyle = GetTimerStyle("pet")
        local tSize = GetTimerFontSize("pet")

        if showBuffs and UnitExists("pet") then
            UpdateBuffs(unitData.pet, petAnchor, "TOPLEFT", "TOPLEFT", 0, 0, growRight, showBuffTimer, sz, sp, pr, tStyle, tSize)
        else
            for i = 1, 16 do unitData.pet.buffs[i]:Hide() end
        end

        local buffRows = showBuffs and CountVisibleBuffRows(unitData.pet, pr) or 0

        if showDebuffs and UnitExists("pet") then
            UpdateDebuffs(unitData.pet, petAnchor, "TOPLEFT", "TOPLEFT", 0, -buffRows * step, growRight, 0, showDebuffTimer, sz, sp, pr, tStyle, tSize, showSpiral)
        else
            for i = 1, 16 do unitData.pet.debuffs[i]:Hide() end
        end
        HideBlizzardPetAuras()
    end

    local function UpdatePartyAuras()
        -- 团队中不显示小队光环（由团队框架接管）
        if GetNumRaidMembers() > 0 then
            for idx = 1, 4 do
                for i = 1, 16 do
                    if partyData[idx].buffs[i] then partyData[idx].buffs[i]:Hide() end
                    if partyData[idx].debuffs[i] then partyData[idx].debuffs[i]:Hide() end
                end
            end
            HideBlizzardPartyAuras()
            return
        end

        local showBuffs = DFUI:GetTempDB("Auras", "partyBuffs")
        local showDebuffs = DFUI:GetTempDB("Auras", "partyDebuffs")
        local showBuffTimer = DFUI:GetTempDB("Auras", "partyShowBuffTimer")
        local showDebuffTimer = DFUI:GetTempDB("Auras", "partyShowDebuffTimer")
        local growRight = DFUI:GetTempDB("Auras", "partyGrowRight")
        if growRight == nil then growRight = true end
        local showSpiral = DFUI:GetTempDB("Auras", "partyShowSpiral")
        if showSpiral == nil then showSpiral = true end
        local sz = GetAuraSize("party")
        local sp = GetAuraSpacing("party")
        local pr = GetAurasPerRow("party")
        local step = sz + sp
        local tStyle = GetTimerStyle("party")
        local tSize = GetTimerFontSize("party")

        for idx = 1, 4 do
            if not partyAnchors[idx] then break end

            if showBuffs and UnitExists("party" .. idx) then
                UpdateBuffs(partyData[idx], partyAnchors[idx], "TOPLEFT", "TOPLEFT", 0, 0, growRight, showBuffTimer, sz, sp, pr, tStyle, tSize)
            else
                for i = 1, 16 do
                    if partyData[idx].buffs[i] then partyData[idx].buffs[i]:Hide() end
                end
            end

            local buffRows = showBuffs and CountVisibleBuffRows(partyData[idx], pr) or 0

            if showDebuffs and UnitExists("party" .. idx) then
                UpdateDebuffs(partyData[idx], partyAnchors[idx], "TOPLEFT", "TOPLEFT", 0, -buffRows * step, growRight, 0, showDebuffTimer, sz, sp, pr, tStyle, tSize, showSpiral)
            else
                for i = 1, 16 do
                    if partyData[idx].debuffs[i] then partyData[idx].debuffs[i]:Hide() end
                end
            end
        end
        HideBlizzardPartyAuras()
    end

    local function UpdateAllAuras()
        UpdatePlayerAuras()
        UpdateTargetAuras()
        UpdatePetAuras()
        UpdatePartyAuras()
    end

    -------------------------------------------------------------------
    -- Timer refresh via OnUpdate (timers tick down continuously)
    -------------------------------------------------------------------

    -- Helper: tick down timers on a set of buttons
    local function RefreshTimers(buttons, count, unit, isDebuff)
        for i = 1, (count or 16) do
            local btn = buttons[i]
            if btn and btn:IsShown() then
                -- 如果还没有 timerStart，尝试从 libdebuff 补充（仅 player/pet）
                if not btn.timerStart and isDebuff and libdebuff and (unit == "player" or unit == "pet") then
                    local _, _, _, _, _, dur, tl = libdebuff:UnitDebuff(unit, i)
                    if tl and tl > 0 then
                        btn.timerStart = GetTime() + tl - dur
                        btn.timerDuration = dur
                        btn.timerStyle = btn.timerStyle or GetTimerStyle("target")
                    end
                end

                -- Fallback for player buffs/debuffs: use GetPlayerBuffTimeLeft via texture-matched index
                if not btn.timerStart and unit == "player" and GetPlayerBuffTimeLeft then
                    local filter = isDebuff and "HARMFUL" or "HELPFUL"
                    local tex = btn.icon and btn.icon:GetTexture()
                    local bIdx = FindPlayerBuffIndex(tex, filter)
                    if bIdx and bIdx >= 0 and not IsPermanentPlayerBuff(bIdx) then
                        local tl = GetPlayerBuffTimeLeft(bIdx)
                        if tl and tl > 0 and tl < PERMANENT_THRESHOLD then
                            -- maxdurations 缓存获取真实总持续时间
                            local normTex = tex and NormalizeTexture(tex)
                            local dur = tl
                            if normTex then
                                if not maxdurations[normTex] or maxdurations[normTex] < tl then
                                    maxdurations[normTex] = tl
                                end
                                dur = maxdurations[normTex]
                            end
                            btn.timerStart = GetTime() + tl - dur
                            btn.timerDuration = dur
                            btn.timerStyle = btn.timerStyle or GetTimerStyle("player")
                        end
                    end
                end

                if btn.timerDuration and btn.timerStart then
                    local remaining = btn.timerDuration - (GetTime() - btn.timerStart)
                    if remaining > 0 then
                        local newText = FormatTime(remaining, btn.timerStyle, true)
                        if btn._lastTimerText ~= newText then
                            btn.timer:SetText(newText)
                            btn._lastTimerText = newText
                        end
                        btn.timer:Show()
                    else
                        btn.timer:SetText("")
                        btn._lastTimerText = nil
                        btn.timer:Hide()
                        btn.timerStart = nil
                        btn.timerDuration = nil
                    end
                end
            end
        end
    end

    -- Cache timer settings to avoid repeated GetTempDB calls in OnUpdate
    local timerSettings = {
        playerBuffTimer = false, playerBuffs = false,
        playerDebuffTimer = false, playerDebuffs = false,
        targetBuffTimer = false, targetBuffs = false,
        targetDebuffTimer = false, targetDebuffs = false,
        petBuffTimer = false, petBuffs = false,
        petDebuffTimer = false, petDebuffs = false,
        partyBuffTimer = false, partyBuffs = false,
        partyDebuffTimer = false, partyDebuffs = false,
    }
    local function RefreshTimerSettings()
        timerSettings.playerBuffTimer = DFUI:GetTempDB("Auras", "playerShowBuffTimer")
        timerSettings.playerBuffs = DFUI:GetTempDB("Auras", "playerBuffs")
        timerSettings.playerDebuffTimer = DFUI:GetTempDB("Auras", "playerShowDebuffTimer")
        timerSettings.playerDebuffs = DFUI:GetTempDB("Auras", "playerDebuffs")
        timerSettings.targetBuffTimer = DFUI:GetTempDB("Auras", "targetShowBuffTimer")
        timerSettings.targetBuffs = DFUI:GetTempDB("Auras", "targetBuffs")
        timerSettings.targetDebuffTimer = DFUI:GetTempDB("Auras", "targetShowDebuffTimer")
        timerSettings.targetDebuffs = DFUI:GetTempDB("Auras", "targetDebuffs")
        timerSettings.petBuffTimer = DFUI:GetTempDB("Auras", "petShowBuffTimer")
        timerSettings.petBuffs = DFUI:GetTempDB("Auras", "petBuffs")
        timerSettings.petDebuffTimer = DFUI:GetTempDB("Auras", "petShowDebuffTimer")
        timerSettings.petDebuffs = DFUI:GetTempDB("Auras", "petDebuffs")
        timerSettings.partyBuffTimer = DFUI:GetTempDB("Auras", "partyShowBuffTimer")
        timerSettings.partyBuffs = DFUI:GetTempDB("Auras", "partyBuffs")
        timerSettings.partyDebuffTimer = DFUI:GetTempDB("Auras", "partyShowDebuffTimer")
        timerSettings.partyDebuffs = DFUI:GetTempDB("Auras", "partyDebuffs")
    end
    RefreshTimerSettings()

    local timerFrame = CreateFrame("Frame")
    timerFrame.elapsed = 0
    timerFrame.settingsElapsed = 0
    timerFrame:SetScript("OnUpdate", function()
        timerFrame.elapsed = timerFrame.elapsed + arg1
        if timerFrame.elapsed < 0.1 then return end
        timerFrame.elapsed = 0

        -- Refresh cached settings every ~2 seconds
        timerFrame.settingsElapsed = timerFrame.settingsElapsed + 0.1
        if timerFrame.settingsElapsed >= 2 then
            RefreshTimerSettings()
            timerFrame.settingsElapsed = 0
        end

        local ts = timerSettings
        -- Player
        if ts.playerBuffTimer and ts.playerBuffs then
            RefreshTimers(unitData.player.buffs, 16, "player", false)
        end
        if ts.playerDebuffTimer and ts.playerDebuffs then
            RefreshTimers(unitData.player.debuffs, 16, "player", true)
        end
        -- Target
        if UnitExists("target") then
            if ts.targetBuffTimer and ts.targetBuffs then
                RefreshTimers(unitData.target.buffs, 16, "target", false)
            end
            if ts.targetDebuffTimer and ts.targetDebuffs then
                RefreshTimers(unitData.target.debuffs, 16, "target", true)
            end
        end
        -- Pet
        if UnitExists("pet") then
            if ts.petBuffTimer and ts.petBuffs then
                RefreshTimers(unitData.pet.buffs, 16, "pet", false)
            end
            if ts.petDebuffTimer and ts.petDebuffs then
                RefreshTimers(unitData.pet.debuffs, 16, "pet", true)
            end
        end
        -- Party
        for idx = 1, 4 do
            if UnitExists("party" .. idx) then
                if ts.partyBuffTimer and ts.partyBuffs then
                    RefreshTimers(partyData[idx].buffs, 16, "party" .. idx, false)
                end
                if ts.partyDebuffTimer and ts.partyDebuffs then
                    RefreshTimers(partyData[idx].debuffs, 16, "party" .. idx, true)
                end
            end
        end
    end)

    -------------------------------------------------------------------
    -- Event handling (requires SuperWoW for UNIT_AURA)
    -------------------------------------------------------------------

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("UNIT_PET")
    eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")

    eventFrame:SetScript("OnEvent", function()
        if event == "UNIT_AURA" then
            if arg1 == "player" then
                UpdatePlayerAuras()
            elseif arg1 == "target" then
                local _, g = UnitExists("target")
                if g then SnapshotAndDetectNewAuras(g, "target") end
                UpdateTargetAuras()
            elseif arg1 == "pet" then
                local _, g = UnitExists("pet")
                if g then SnapshotAndDetectNewAuras(g, "pet") end
                UpdatePetAuras()
            elseif arg1 and string.find(arg1, "party") then
                local _, g = UnitExists(arg1)
                if g then SnapshotAndDetectNewAuras(g, arg1) end
                UpdatePartyAuras()
            end
        elseif event == "PLAYER_AURAS_CHANGED" then
            UpdatePlayerAuras()
        elseif event == "PLAYER_TARGET_CHANGED" then
            local _, g = UnitExists("target")
            if g then SeedSnapshot(g, "target") end
            UpdateTargetAuras()
        elseif event == "PLAYER_ENTERING_WORLD" then
            local _, pg = UnitExists("player")
            if pg then SeedSnapshot(pg, "player") end
            local _, tg = UnitExists("target")
            if tg then SeedSnapshot(tg, "target") end
            if UnitExists("pet") then
                local _, petg = UnitExists("pet")
                if petg then SeedSnapshot(petg, "pet") end
            end
            for i = 1, 4 do
                if UnitExists("party" .. i) then
                    local _, pag = UnitExists("party" .. i)
                    if pag then SeedSnapshot(pag, "party" .. i) end
                end
            end
            UpdateAllAuras()
        elseif event == "UNIT_PET" then
            if UnitExists("pet") then
                local _, g = UnitExists("pet")
                if g then SeedSnapshot(g, "pet") end
            end
            UpdatePetAuras()
        elseif event == "PARTY_MEMBERS_CHANGED" then
            for i = 1, 4 do
                if UnitExists("party" .. i) then
                    local _, g = UnitExists("party" .. i)
                    if g then SeedSnapshot(g, "party" .. i) end
                end
            end
            UpdatePartyAuras()
        elseif event == "RAID_ROSTER_UPDATE" then
            UpdatePartyAuras()
        end
    end)

    -------------------------------------------------------------------
    -- Buff Bar (top-right player buffs/debuffs/weapons, replaces Blizzard BuffFrame)
    -------------------------------------------------------------------

    local buffBar = {}
    buffBar.buffFrame = nil
    buffBar.debuffFrame = nil
    buffBar.weaponFrame = nil
    buffBar.active = false

    -- DEBUFF_COLORS_BB removed (merged into DEBUFF_COLORS)

    local function BB_GetSetting(key)
        return DFUI:GetTempDB("Auras", key)
    end

    -- BB_FormatTime / BB_FormatTimeHHMM removed (redundant wrappers)

    local function BB_CreateButton(parent, name, id, buffFilter)
        local size = BB_GetSetting("buffBarSize") or 25
        local btn = CreateFrame("Button", name, parent)
        btn:SetWidth(size)
        btn:SetHeight(size)
        btn:SetID(id)
        btn.buffFilter = buffFilter

        btn.icon = btn:CreateTexture(nil, "BORDER")
        btn.icon:SetAllPoints(btn)

        btn.border = btn:CreateTexture(nil, "OVERLAY")
        btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        btn.border:SetWidth(size)
        btn.border:SetHeight(size)
        btn.border:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
        btn.border:Hide()

        btn.cooldown = CreateFrame("Model", nil, btn, "CooldownFrameTemplate")
        btn.cooldown:SetAllPoints(btn)
        btn.cooldown.noCooldownCount = true
        btn.cooldown:Hide()

        btn.count = btn:CreateFontString(nil, "OVERLAY")
        btn.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        btn.count:SetTextColor(1, 1, 1, 1)

        btn.duration = btn:CreateFontString(nil, "OVERLAY")
        btn.duration:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        btn.duration:SetTextColor(1, 1, 1, 1)

        return btn
    end

    local function BB_UpdateTimerPosition(btn)
        local inside = BB_GetSetting("buffBarTimerInside")
        btn.duration:ClearAllPoints()
        if inside then
            btn.duration:SetPoint("CENTER", btn, "CENTER", 0, 0)
        else
            btn.duration:SetPoint("TOP", btn, "BOTTOM", 0, 0)
        end
    end

    local function BB_UpdateIcon(btn)
        local frame = btn:GetParent()
        local sortedIndex = frame.sortedIndices and frame.sortedIndices[btn:GetID()] or btn:GetID()
        local buffIndex = GetPlayerBuff(sortedIndex, btn.buffFilter)
        btn.buffIndex = buffIndex
        if buffIndex >= 0 then
            local texture = GetPlayerBuffTexture(buffIndex)
            -- 图标变化时更新永久 buff 缓存
            local oldTex = btn.icon:GetTexture()
            if oldTex ~= texture then
                btn.isPermanent = IsPermanentPlayerBuff(buffIndex)
            end
            btn.icon:SetTexture(texture)
            btn:Show()
        else
            btn.isPermanent = nil
            btn:Hide()
        end
    end

    local function BB_UpdateBorder(btn)
        if btn.buffFilter == "HARMFUL" then
            if btn.buffIndex and btn.buffIndex >= 0 then
                local debuffType = GetPlayerBuffDispelType(btn.buffIndex)
                local color = DEBUFF_COLORS[debuffType] or DEBUFF_COLORS.none
                btn.border:SetVertexColor(color[1], color[2], color[3])
                btn.border:Show()
            else
                btn.border:Hide()
            end
        end
    end

    local function BB_UpdateCount(btn)
        if btn.buffIndex and btn.buffIndex >= 0 then
            local count = GetPlayerBuffApplications(btn.buffIndex)
            if count > 1 then
                btn.count:SetText(count)
                btn.count:Show()
            else
                btn.count:Hide()
            end
        else
            btn.count:Hide()
        end
    end

    local function BB_UpdateDuration(btn)
        if btn.buffIndex and btn.buffIndex >= 0 then
            if btn.isPermanent then
                btn.duration:Hide()
                if btn.cooldown then btn.cooldown:Hide() end
                btn.cdTotalDur = nil
                return
            end
            local timeLeft = GetPlayerBuffTimeLeft(btn.buffIndex)
            if timeLeft and timeLeft > 0 and timeLeft < PERMANENT_THRESHOLD then
                local style = BB_GetSetting("buffBarTimerStyle") or "White + Red"
                local fontSize = BB_GetSetting("buffBarTimerFontSize") or 10
                btn.duration:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
                ApplyTimerColor(btn.duration, style)
                btn.duration:SetText(FormatTime(timeLeft, style))
                btn.duration:Show()
                -- Spiral only for debuffs (HARMFUL), not buffs
                if btn.buffFilter == "HARMFUL" then
                    local showSpiral = BB_GetSetting("buffBarShowSpiral")
                    if showSpiral == nil then showSpiral = true end
                    if btn.cooldown then
                        if showSpiral then
                            if not btn.cdTotalDur or btn.cdTotalDur < timeLeft then
                                btn.cdTotalDur = timeLeft
                            end
                            local start = GetTime() + timeLeft - btn.cdTotalDur
                            CooldownFrame_SetTimer(btn.cooldown, start, btn.cdTotalDur, 1)
                        else
                            btn.cooldown:Hide()
                            btn.cdTotalDur = nil
                        end
                    end
                elseif btn.cooldown then
                    btn.cooldown:Hide()
                end
            else
                btn.duration:Hide()
                if btn.cooldown then btn.cooldown:Hide() end
                btn.cdTotalDur = nil
            end
        else
            btn.duration:Hide()
            if btn.cooldown then btn.cooldown:Hide() end
            btn.cdTotalDur = nil
        end
    end

    local function BB_UpdateButton(btn)
        BB_UpdateIcon(btn)
        BB_UpdateBorder(btn)
        BB_UpdateCount(btn)
        BB_UpdateDuration(btn)
        BB_UpdateTimerPosition(btn)
    end

    local function BB_UpdateWeaponButton(btn)
        local mh, mhtime, mhcharge, oh, ohtime, ohcharge = GetWeaponEnchantInfo()
        local id = btn:GetID()
        -- Icon
        local hasEnchant = (id == 1 and mh) or (id == 2 and oh)
        if hasEnchant then
            local slot = id == 1 and 16 or 17
            btn.icon:SetTexture(GetInventoryItemTexture("player", slot))
            btn:Show()
        else
            btn:Hide()
            btn.duration:Hide()
            btn.count:Hide()
            return
        end
        -- Count
        local count = (id == 1 and mhcharge) or (id == 2 and ohcharge) or 0
        if count > 1 then
            btn.count:SetText(count)
            btn.count:Show()
        else
            btn.count:Hide()
        end
        -- Duration
        local timeLeft = 0
        if id == 1 and mhtime then timeLeft = mhtime / 1000
        elseif id == 2 and ohtime then timeLeft = ohtime / 1000 end
        if timeLeft > 0 then
            local style = BB_GetSetting("buffBarTimerStyle") or "White + Red"
            local fontSize = BB_GetSetting("buffBarTimerFontSize") or 10
            btn.duration:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
            ApplyTimerColor(btn.duration, style)
            btn.duration:SetText(FormatTime(timeLeft, style))
            btn.duration:Show()
        else
            btn.duration:Hide()
        end
        BB_UpdateTimerPosition(btn)
    end

    local function BB_SortButtons(frame)
        local sortOrder = BB_GetSetting("buffBarSortOrder") or "Default"
        if sortOrder == "Default" then
            frame.sortedIndices = nil
            return
        end
        local buffData = {}
        local idx = 0
        while true do
            local buffIndex = GetPlayerBuff(idx, frame.buffFilter)
            if buffIndex < 0 then break end
            local timeLeft = GetPlayerBuffTimeLeft(buffIndex) or 0
            table.insert(buffData, {index = idx, timeLeft = timeLeft})
            idx = idx + 1
        end
        table.sort(buffData, function(a, b)
            if sortOrder == "Duration ascending" then
                return a.timeLeft < b.timeLeft
            else
                return a.timeLeft > b.timeLeft
            end
        end)
        frame.sortedIndices = {}
        for i = 1, table.getn(buffData) do
            frame.sortedIndices[i - 1] = buffData[i].index
        end
    end

    local function BB_UpdateLayout(frame, buttons, perRow)
        local total = table.getn(buttons)
        local cols = perRow
        local rows = math.ceil(total / cols)
        local size = BB_GetSetting("buffBarSize") or 25
        local gap = BB_GetSetting("buffBarSpacing") or 5

        local slotIndex = 1
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                if slotIndex <= total then
                    local btn = buttons[slotIndex]
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(col * (size + gap)), -(row * (size + gap)))
                    btn:SetWidth(size)
                    btn:SetHeight(size)
                    btn.border:SetWidth(size)
                    btn.border:SetHeight(size)
                    slotIndex = slotIndex + 1
                end
            end
        end

        frame:SetWidth(cols * size + (cols - 1) * gap)
        frame:SetHeight(rows * size + (rows - 1) * gap)
    end

    local function BB_CreateBuffFrame(name, count, buffFilter, perRow)
        local frame = CreateFrame("Frame", name, UIParent)
        frame.buttons = {}
        frame.buffFilter = buffFilter
        frame:SetFrameStrata("LOW")

        for i = 1, count do
            local btn = BB_CreateButton(frame, name .. i, i - 1, buffFilter)
            btn:RegisterForClicks("RightButtonUp")
            btn:SetScript("OnClick", function()
                if this.buffIndex and this.buffIndex >= 0 then
                    CancelPlayerBuff(this.buffIndex)
                end
            end)
            btn:SetScript("OnEnter", function()
                if this.buffIndex and this.buffIndex >= 0 then
                    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
                    GameTooltip:SetPlayerBuff(this.buffIndex)
                    GameTooltip:Show()
                end
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            BB_UpdateButton(btn)
            frame.buttons[i] = btn
        end

        frame.tick = 0
        frame:SetScript("OnUpdate", function()
            if not frame:IsShown() then return end
            if frame.tick > GetTime() then return else frame.tick = GetTime() + 0.1 end
            BB_SortButtons(frame)
            for _, btn in pairs(frame.buttons) do
                BB_UpdateButton(btn)
            end
        end)

        BB_SortButtons(frame)
        BB_UpdateLayout(frame, frame.buttons, perRow)

        return frame
    end

    local function BB_CreateWeaponFrame(name, perRow)
        local frame = CreateFrame("Frame", name, UIParent)
        frame.buttons = {}
        frame:SetFrameStrata("LOW")

        for i = 1, 2 do
            local btn = BB_CreateButton(frame, name .. i, i, nil)
            btn:RegisterForClicks("RightButtonUp")
            btn:SetScript("OnClick", function()
                if CancelItemTempEnchantment then
                    CancelItemTempEnchantment(this:GetID())
                end
            end)
            btn:SetScript("OnEnter", function()
                local slot = this:GetID() == 1 and 16 or 17
                GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetInventoryItem("player", slot)
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            BB_UpdateWeaponButton(btn)
            frame.buttons[i] = btn
        end

        frame.tick = 0
        frame:SetScript("OnUpdate", function()
            if not frame:IsShown() then return end
            if frame.tick > GetTime() then return else frame.tick = GetTime() + 0.1 end
            for _, btn in pairs(frame.buttons) do
                BB_UpdateWeaponButton(btn)
            end
        end)

        BB_UpdateLayout(frame, frame.buttons, perRow)

        return frame
    end

    -- Buff bar frames use DFUI's Ctrl+Alt+Shift drag system via frames.lua
    -- (added to framesToMakeMovable list there)

    local function BB_Init()
        if buffBar.active then return end

        local mode = BB_GetSetting("buffBarMode") or "Buff Bar"
        if mode == "Default" then
            -- Restore default BuffFrame
            if BuffFrame then
                BuffFrame:Show()
                BuffFrame:SetAlpha(1)
            end
            if TemporaryEnchantFrame then
                TemporaryEnchantFrame:Show()
                TemporaryEnchantFrame:SetAlpha(1)
            end
            return
        elseif mode == "Disabled" then
            -- Kill Blizzard's and don't create ours
            if BuffFrame then
                BuffFrame:Hide()
                BuffFrame:UnregisterAllEvents()
            end
            if TemporaryEnchantFrame then
                TemporaryEnchantFrame:Hide()
                TemporaryEnchantFrame:UnregisterAllEvents()
            end
            return
        end

        -- mode == "Buff Bar": kill defaults and create custom
        if BuffFrame then
            BuffFrame:Hide()
            BuffFrame:UnregisterAllEvents()
            BuffFrame:SetScript("OnUpdate", nil)
            BuffFrame:SetScript("OnEvent", nil)
            BuffFrame:SetScript("OnShow", function() this:Hide() end)
        end
        if TemporaryEnchantFrame then
            TemporaryEnchantFrame:Hide()
            TemporaryEnchantFrame:UnregisterAllEvents()
            TemporaryEnchantFrame:SetScript("OnUpdate", nil)
            TemporaryEnchantFrame:SetScript("OnShow", function() this:Hide() end)
        end

        local perRow = BB_GetSetting("buffBarPerRow") or 8
        local frameSpacing = BB_GetSetting("buffBarFrameSpacing") or 15

        buffBar.buffFrame = BB_CreateBuffFrame("DFUI_BuffBar_Buffs", 16, "HELPFUL", perRow)
        buffBar.buffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -255, -20)

        buffBar.debuffFrame = BB_CreateBuffFrame("DFUI_BuffBar_Debuffs", 16, "HARMFUL", perRow)
        buffBar.debuffFrame:SetPoint("TOPRIGHT", buffBar.buffFrame, "BOTTOMRIGHT", 0, -frameSpacing)

        buffBar.weaponFrame = BB_CreateWeaponFrame("DFUI_BuffBar_Weapons", 2)
        buffBar.weaponFrame:SetPoint("TOPRIGHT", buffBar.debuffFrame, "BOTTOMRIGHT", 0, -frameSpacing)

        if not (BB_GetSetting("buffBarShowBuffs") == true or BB_GetSetting("buffBarShowBuffs") == nil) then
            buffBar.buffFrame:Hide()
        end
        if not BB_GetSetting("buffBarShowDebuffs") then
            buffBar.debuffFrame:Hide()
        end
        if not BB_GetSetting("buffBarShowWeapons") then
            buffBar.weaponFrame:Hide()
        end

        buffBar.active = true
    end

    local function BB_Refresh()
        if not buffBar.active then return end
        local perRow = BB_GetSetting("buffBarPerRow") or 8

        if buffBar.buffFrame then
            BB_UpdateLayout(buffBar.buffFrame, buffBar.buffFrame.buttons, perRow)
            for _, btn in pairs(buffBar.buffFrame.buttons) do BB_UpdateButton(btn) end
        end
        if buffBar.debuffFrame then
            BB_UpdateLayout(buffBar.debuffFrame, buffBar.debuffFrame.buttons, perRow)
            for _, btn in pairs(buffBar.debuffFrame.buttons) do BB_UpdateButton(btn) end
        end
        if buffBar.weaponFrame then
            BB_UpdateLayout(buffBar.weaponFrame, buffBar.weaponFrame.buttons, 2)
            for _, btn in pairs(buffBar.weaponFrame.buttons) do BB_UpdateWeaponButton(btn) end
        end

        -- Update section spacing
        local frameSpacing = BB_GetSetting("buffBarFrameSpacing") or 15
        if buffBar.debuffFrame then
            buffBar.debuffFrame:ClearAllPoints()
            buffBar.debuffFrame:SetPoint("TOPRIGHT", buffBar.buffFrame, "BOTTOMRIGHT", 0, -frameSpacing)
        end
        if buffBar.weaponFrame then
            buffBar.weaponFrame:ClearAllPoints()
            buffBar.weaponFrame:SetPoint("TOPRIGHT", buffBar.debuffFrame, "BOTTOMRIGHT", 0, -frameSpacing)
        end
    end

    -- Initialize buff bar on login
    BB_Init()

    -------------------------------------------------------------------
    -- Callbacks for config changes
    -------------------------------------------------------------------

    local callbacks = {}

    -- Player callbacks
    callbacks.playerBuffs = function() RefreshTimerSettings() UpdatePlayerAuras() end
    callbacks.playerDebuffs = function() RefreshTimerSettings() UpdatePlayerAuras() end
    callbacks.playerShowBuffTimer = function() RefreshTimerSettings() UpdatePlayerAuras() end
    callbacks.playerShowDebuffTimer = function() RefreshTimerSettings() UpdatePlayerAuras() end
    callbacks.playerAuraSize = function() UpdatePlayerAuras() end
    callbacks.playerAuraSpacing = function() UpdatePlayerAuras() end
    callbacks.playerAurasPerRow = function() UpdatePlayerAuras() end
    callbacks.playerGrowRight = function() UpdatePlayerAuras() end
    callbacks.playerTimerFontSize = function() UpdatePlayerAuras() end
    callbacks.playerTimerStyle = function() UpdatePlayerAuras() end
    -- Target callbacks
    callbacks.targetBuffs = function() RefreshTimerSettings() UpdateTargetAuras() end
    callbacks.targetDebuffs = function() RefreshTimerSettings() UpdateTargetAuras() end
    callbacks.targetShowBuffTimer = function() RefreshTimerSettings() UpdateTargetAuras() end
    callbacks.targetShowDebuffTimer = function() RefreshTimerSettings() UpdateTargetAuras() end
    callbacks.targetAuraSize = function() UpdateTargetAuras() end
    callbacks.targetAuraSpacing = function() UpdateTargetAuras() end
    callbacks.targetAurasPerRow = function() UpdateTargetAuras() end
    callbacks.targetGrowRight = function() UpdateTargetAuras() end
    callbacks.targetTimerFontSize = function() UpdateTargetAuras() end
    callbacks.targetTimerStyle = function() UpdateTargetAuras() end
    -- Pet callbacks
    callbacks.petBuffs = function() RefreshTimerSettings() UpdatePetAuras() end
    callbacks.petDebuffs = function() RefreshTimerSettings() UpdatePetAuras() end
    callbacks.petShowBuffTimer = function() RefreshTimerSettings() UpdatePetAuras() end
    callbacks.petShowDebuffTimer = function() RefreshTimerSettings() UpdatePetAuras() end
    callbacks.petAuraSize = function() UpdatePetAuras() end
    callbacks.petAuraSpacing = function() UpdatePetAuras() end
    callbacks.petAurasPerRow = function() UpdatePetAuras() end
    callbacks.petGrowRight = function() UpdatePetAuras() end
    callbacks.petTimerFontSize = function() UpdatePetAuras() end
    callbacks.petTimerStyle = function() UpdatePetAuras() end
    -- Party callbacks
    callbacks.partyBuffs = function() RefreshTimerSettings() UpdatePartyAuras() end
    callbacks.partyDebuffs = function() RefreshTimerSettings() UpdatePartyAuras() end
    callbacks.partyShowBuffTimer = function() RefreshTimerSettings() UpdatePartyAuras() end
    callbacks.partyShowDebuffTimer = function() RefreshTimerSettings() UpdatePartyAuras() end
    callbacks.partyAuraSize = function() UpdatePartyAuras() end
    callbacks.partyAuraSpacing = function() UpdatePartyAuras() end
    callbacks.partyAurasPerRow = function() UpdatePartyAuras() end
    callbacks.partyGrowRight = function() UpdatePartyAuras() end
    callbacks.partyTimerFontSize = function() UpdatePartyAuras() end
    callbacks.partyTimerStyle = function() UpdatePartyAuras() end
    -- Buff Bar callbacks
    callbacks.buffBarShowBuffs = function(val)
        if buffBar.buffFrame then
            if val then buffBar.buffFrame:Show() else buffBar.buffFrame:Hide() end
        end
    end
    callbacks.buffBarShowDebuffs = function(val)
        if buffBar.debuffFrame then
            if val then buffBar.debuffFrame:Show() else buffBar.debuffFrame:Hide() end
        end
    end
    callbacks.buffBarShowWeapons = function(val)
        if buffBar.weaponFrame then
            if val then buffBar.weaponFrame:Show() else buffBar.weaponFrame:Hide() end
        end
    end
    callbacks.buffBarSize = function() BB_Refresh() end
    callbacks.buffBarPerRow = function() BB_Refresh() end
    callbacks.buffBarSpacing = function() BB_Refresh() end
    callbacks.buffBarFrameSpacing = function() BB_Refresh() end
    callbacks.buffBarTimerInside = function() BB_Refresh() end
    callbacks.buffBarTimerFontSize = function() BB_Refresh() end
    callbacks.buffBarTimerStyle = function() BB_Refresh() end
    callbacks.buffBarSortOrder = function() BB_Refresh() end
    callbacks.buffBarShowSpiral = function() BB_Refresh() end
    -- Spiral callbacks
    callbacks.playerShowSpiral = function() UpdatePlayerAuras() end
    callbacks.targetShowSpiral = function() UpdateTargetAuras() end
    callbacks.petShowSpiral = function() UpdatePetAuras() end
    callbacks.partyShowSpiral = function() UpdatePartyAuras() end

    -- 光环位置偏移 callbacks
    callbacks.playerAuraX = function(v) RepositionAnchor(playerAnchor, PlayerFrame, "TOPLEFT", "TOPLEFT", v, DFUI:GetTempDB("Auras", "playerAuraY") or -68) end
    callbacks.playerAuraY = function(v) RepositionAnchor(playerAnchor, PlayerFrame, "TOPLEFT", "TOPLEFT", DFUI:GetTempDB("Auras", "playerAuraX") or 100, v) end
    callbacks.targetAuraX = function(v) RepositionAnchor(targetAnchor, TargetFrame, "TOPRIGHT", "TOPRIGHT", v, DFUI:GetTempDB("Auras", "targetAuraY") or -68) end
    callbacks.targetAuraY = function(v) RepositionAnchor(targetAnchor, TargetFrame, "TOPRIGHT", "TOPRIGHT", DFUI:GetTempDB("Auras", "targetAuraX") or -100, v) end
    callbacks.petAuraX = function(v) RepositionAnchor(petAnchor, PetFrame, "TOPLEFT", "BOTTOMLEFT", v, DFUI:GetTempDB("Auras", "petAuraY") or -2) end
    callbacks.petAuraY = function(v) RepositionAnchor(petAnchor, PetFrame, "TOPLEFT", "BOTTOMLEFT", DFUI:GetTempDB("Auras", "petAuraX") or 30, v) end
    callbacks.partyAuraX = function(v)
        local y = DFUI:GetTempDB("Auras", "partyAuraY") or -2
        for i = 1, 4 do
            local pf = _G["PartyMemberFrame" .. i]
            if pf and partyAnchors[i] then RepositionAnchor(partyAnchors[i], pf, "TOPLEFT", "BOTTOMLEFT", v, y) end
        end
    end
    callbacks.partyAuraY = function(v)
        local x = DFUI:GetTempDB("Auras", "partyAuraX") or 30
        for i = 1, 4 do
            local pf = _G["PartyMemberFrame" .. i]
            if pf and partyAnchors[i] then RepositionAnchor(partyAnchors[i], pf, "TOPLEFT", "BOTTOMLEFT", x, v) end
        end
    end

    DFUI:NewCallbacks("Auras", callbacks)
end)
