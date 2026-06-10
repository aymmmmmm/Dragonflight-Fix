----------------------------------------------------------------------
-- DFUI.Assist  --  Locales (enUS / zhCN)
----------------------------------------------------------------------

local enUS = {
    ["panelTitle"]    = "Assist",
    ["close"]         = "Close",
    ["enabled"]       = "Enabled",
    ["masterOn"]      = "Assist Master Switch (enable checked)",

    -- group titles
    ["grpAuto"]       = "Automation",
    ["grpSafety"]     = "Safety",
    ["grpUI"]         = "Interface",
    ["grpLink"]       = "Links",

    -- automation
    ["autoQuestAccept"]    = "Auto Accept Quests",
    ["autoQuestAcceptDesc"]= "Automatically accept available quests at NPCs. Hold Alt to suspend.",
    ["autoQuestTurnin"]    = "Auto Turn-In Quests",
    ["autoQuestTurninDesc"]= "Automatically turn in completed quests. Multi-reward quests are left for you to pick. Hold Alt to suspend.",
    ["autoStand"]     = "Auto Stand",
    ["autoStandDesc"] = "Stand up automatically when an action requires standing.",
    ["autoBag"]       = "Auto Open Bags",
    ["autoBagDesc"]   = "Open bags at vendor / mailbox / trade, and close them afterwards.",
    ["autoBoP"]       = "Auto Confirm Bind-on-Pickup",
    ["autoBoPDesc"]   = "Automatically confirm the bind-on-pickup loot dialog.",
    ["autoAttack"]    = "Auto Attack (in combat only)",
    ["autoAttackDesc"]= "Start melee on an attackable target only while already in combat.",
    ["autoRoll"]      = "Auto Roll",
    ["autoRollDesc"]  = "Auto-roll on group loot; set a mode per item quality below.",
    ["autoRelease"]   = "Auto Release Spirit",
    ["autoReleaseDesc"]= "Release to graveyard after death (delayed). Off by default; unsafe for HC.",
    ["autoDismount"]  = "Auto Dismount / Unshift",
    ["autoDismountDesc"]= "Dismount and cancel druid/shaman/priest forms when casting or interacting requires it.",
    ["autoLearnReplace"]= "Auto Upgrade Action Bars",
    ["autoLearnReplaceDesc"]= "After learning a higher spell rank, replace the old rank on your action bars with the new one.",
    ["autoUnlock"]    = "Auto Lockpick (Rogue)",
    ["autoUnlockDesc"]= "Right-click a locked item in your bags to pick its lock. Rogue only.",
    ["autoSell"]      = "Auto Sell Grays",
    ["autoSellDesc"]  = "Sell all grey (junk) items at vendors. Throttled to avoid disconnects.",
    ["autoRepair"]    = "Auto Repair",
    ["autoRepairDesc"]= "Repair all gear at vendors and report the cost.",

    -- safety
    ["safeHealth"]    = "Low-Health Alert",
    ["safeHealthDesc"]= "Warn at 40% HP; flash + critical alarm at 25%.",
    ["safeBreath"]    = "Breath / Drowning Monitor",
    ["safeBreathDesc"]= "Warn when breath drops below half, critical alarm below a third.",
    ["safeElite"]     = "Elite Target Warning",
    ["safeEliteDesc"] = "Warn when targeting elite / rare / world-boss / skull units.",
    ["safeZone"]      = "Zone Danger Check",
    ["safeZoneDesc"]  = "Warn when entering a zone whose recommended level is above yours.",

    -- alert texts
    ["aHP40"]         = "|cffff4444[Safety] Health below 40%!|r",
    ["aHP25"]         = "|cffff0000[Safety] Health CRITICAL — below 25%!|r",
    ["aBreathHalf"]   = "|cffffcc00[Safety] Breath below half — surface!|r",
    ["aBreathCrit"]   = "|cffff3300[Safety] Breath CRITICAL — surface now!|r",
    ["aEliteFmt"]     = "|cffff6600[Safety] Target [%s] is %s — be careful!|r",
    ["aZoneFmt"]      = "|cffff8800[Safety] Zone [%s] is for level %d-%d, you're underleveled!|r",
    ["tagSkull"]      = "a Skull (??) mob",
    ["tagWorldboss"]  = "a World Boss",
    ["tagRareElite"]  = "Rare Elite",
    ["tagRare"]       = "Rare",
    ["tagElite"]      = "Elite",

    -- interface
    ["uiAttackBar"]   = "Attack Swing Timer",
    ["uiAttackBarDesc"]= "Main / off-hand + ranged swing timer bars. Hold Ctrl+Shift+Alt to move (layout mode).",
    ["uiQuickMark"]   = "Quick Mark",
    ["uiQuickMarkDesc"]= "Double-click the target frame to open a radial raid-marker wheel.",
    ["uiCombatAlert"] = "Combat Banner",
    ["uiCombatAlertDesc"]= "Show a fading banner at the top of the screen when entering / leaving combat.",
    ["combatEnter"]   = "Entering Combat",
    ["combatLeave"]   = "Leaving Combat",

    -- links
    ["linkItemEnUS"]  = "Alt-Click Item -> English",
    ["linkItemEnUSDesc"]= "Alt+Left-click an item (gear/bag/vendor/loot/chat) to insert its English-name link into chat.",
    ["linkPfQuest"]   = "Ctrl-Click Quest -> English",
    ["linkPfQuestDesc"]= "Ctrl+click a quest in the quest log to insert its English-name link into chat. Requires pfQuest.",

    -- messages
    ["learnReplaceFmt"]= "Slot #%s updated to %s (%s)",
    ["sellIncome"]    = "Sold junk for",
    ["repairCost"]    = "Repaired for",
    ["repairNoMoney"] = "|cffff0000Not enough money to repair!|r",
    ["linkNoItemDB"]  = "English item DB (!Libs) not loaded; this feature is unavailable.",
    ["linkNoPfQuest"] = "pfQuest data not found; English quest links are unavailable.",

    -- roll
    ["rollMode"]      = "Roll Mode",
    ["rollNeed"]      = "Need",
    ["rollGreed"]     = "Greed",
    ["rollPass"]      = "Pass",
    ["rollSkip"]      = "Manual",
    ["rollQGray"]     = "Junk",
    ["rollQGreen"]    = "Green",
    ["rollQBlue"]     = "Blue",
    ["rollQEpic"]     = "Epic+",
}

local zhCN = {
    ["panelTitle"]    = "辅助功能",
    ["masterOn"]      = "辅助总开关（启用已勾选的功能）",
    ["close"]         = "关闭",
    ["enabled"]       = "启用",

    -- group titles
    ["grpAuto"]       = "自动化",
    ["grpSafety"]     = "安全模块",
    ["grpUI"]         = "界面",
    ["grpLink"]       = "链接",

    -- automation
    ["autoQuestAccept"]    = "自动接受任务",
    ["autoQuestAcceptDesc"]= "在 NPC 处自动接受可接任务。按住 Alt 暂停。",
    ["autoQuestTurnin"]    = "自动交还任务",
    ["autoQuestTurninDesc"]= "在 NPC 处自动交还已完成任务。多奖励任务保留给你手选。按住 Alt 暂停。",
    ["autoStand"]     = "自动站立",
    ["autoStandDesc"] = "操作需要站立时自动起身。",
    ["autoBag"]       = "自动打开背包",
    ["autoBagDesc"]   = "商人/邮箱/交易时自动开包，关闭对话后收回。",
    ["autoBoP"]       = "自动确认绑定拾取",
    ["autoBoPDesc"]   = "自动确认拾取绑定（BoP）弹窗。",
    ["autoAttack"]    = "自动攻击（仅战斗中）",
    ["autoAttackDesc"]= "仅在自己已处于战斗中、且有可攻击目标时开启普攻。",
    ["autoRoll"]      = "自动 Roll",
    ["autoRollDesc"]  = "团队拾取时按下方各品质设定自动 Roll。",
    ["autoRelease"]   = "自动释放灵魂（回尸）",
    ["autoReleaseDesc"]= "死亡后延迟回尸。默认关闭；硬核角色请勿开启。",
    ["autoDismount"]  = "自动下马/解形态",
    ["autoDismountDesc"]= "施法或交互需要时自动下马，并解除德鲁伊/萨满/牧师形态。",
    ["autoLearnReplace"]= "动作条自动升级",
    ["autoLearnReplaceDesc"]= "学到更高等级法术后，把动作条上的旧等级自动替换为新学的最高等级。",
    ["autoUnlock"]    = "自动开锁（盗贼）",
    ["autoUnlockDesc"]= "右键背包中的锁定物品即可开锁。仅盗贼可用。",
    ["autoSell"]      = "自动卖灰",
    ["autoSellDesc"]  = "在商人处自动卖出所有灰色（垃圾）物品。已加节流防掉线。",
    ["autoRepair"]    = "自动修理",
    ["autoRepairDesc"]= "在商人处自动修理全部装备并报花费。",

    -- safety
    ["safeHealth"]    = "血量报警",
    ["safeHealthDesc"]= "血量 40% 警告；25% 红屏 + 危急警报。",
    ["safeBreath"]    = "呼吸/溺水监控",
    ["safeBreathDesc"]= "呼吸不足一半时警告，不足三分之一时红屏危急警报。",
    ["safeElite"]     = "精英目标警告",
    ["safeEliteDesc"] = "选中精英/稀有/世界Boss/骷髅目标时警告。",
    ["safeZone"]      = "区域危险检查",
    ["safeZoneDesc"]  = "进入推荐等级高于自身的区域时警告。",

    -- alert texts
    ["aHP40"]         = "|cffff4444[安全] 血量低于 40%！注意安全！|r",
    ["aHP25"]         = "|cffff0000[安全] 血量危急！低于 25%！|r",
    ["aBreathHalf"]   = "|cffffcc00[安全] 呼吸不足一半！注意上浮！|r",
    ["aBreathCrit"]   = "|cffff3300[安全] 呼吸危急！快上浮！|r",
    ["aEliteFmt"]     = "|cffff6600[安全] 目标 [%s] 为%s，注意安全！|r",
    ["aZoneFmt"]      = "|cffff8800[安全] 当前区域 [%s] 推荐等级 %d-%d，你的等级偏低！|r",
    ["tagSkull"]      = "骷髅级",
    ["tagWorldboss"]  = "世界Boss",
    ["tagRareElite"]  = "稀有精英",
    ["tagRare"]       = "稀有",
    ["tagElite"]      = "精英",

    -- interface
    ["uiAttackBar"]   = "攻击计时条",
    ["uiAttackBarDesc"]= "主手/副手 + 远程挥击计时条。按住 Ctrl+Shift+Alt 进布局模式拖动。",
    ["uiQuickMark"]   = "快速标记",
    ["uiQuickMarkDesc"]= "双击目标框打开径向团队标记轮盘。",
    ["uiCombatAlert"] = "进战/脱战横幅",
    ["uiCombatAlertDesc"]= "进入/离开战斗时在屏幕顶部弹出淡入淡出横幅提示。",
    ["combatEnter"]   = "进入战斗",
    ["combatLeave"]   = "离开战斗",

    -- links
    ["linkItemEnUS"]  = "Alt+点击物品转英文",
    ["linkItemEnUSDesc"]= "Alt+左键点击物品（装备/背包/商人/拾取/聊天）→ 在聊天框插入英文名链接。",
    ["linkPfQuest"]   = "Ctrl+点击任务转英文",
    ["linkPfQuestDesc"]= "在任务日志里 Ctrl+点击任务 → 在聊天框插入英文名任务链接。需 pfQuest。",

    -- messages
    ["learnReplaceFmt"]= "编号 #%s 按钮已更新为 %s（%s）",
    ["sellIncome"]    = "本次售卖收入",
    ["repairCost"]    = "修理花费",
    ["repairNoMoney"] = "|cffff0000没有足够的资金修理！|r",
    ["linkNoItemDB"]  = "英文物品库（!Libs）未加载，该功能不可用。",
    ["linkNoPfQuest"] = "未找到 pfQuest 数据，英文任务链接不可用。",

    -- roll
    ["rollMode"]      = "Roll 模式",
    ["rollNeed"]      = "需求",
    ["rollGreed"]     = "贪婪",
    ["rollPass"]      = "放弃",
    ["rollSkip"]      = "不自动",
    ["rollQGray"]     = "灰白",
    ["rollQGreen"]    = "绿",
    ["rollQBlue"]     = "蓝",
    ["rollQEpic"]     = "紫橙",
}

local loc = GetLocale()
local L = enUS
if loc == "zhCN" or loc == "zhTW" then
    L = zhCN
end

-- 缺失键回退英文，再回退键名本身
setmetatable(L, { __index = function(_, k)
    if enUS[k] ~= nil then return enUS[k] end
    return tostring(k)
end })

DFUI.Assist.L = L
