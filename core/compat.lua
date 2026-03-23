setfenv(1, DFRL:GetEnv())

local Setup = {
    fixed = {
        shaguCore = false,
        shaguExtras = false,
    },

    addons = {
        ["ShaguTweaks"] = "shagu",
        ["ShaguTweaks-extras"] = "shagu",
    },

    processed = {}
}

--=================
-- SHAGU
--=================
function Setup:ShaguCore()
    local T = ShaguTweaks.T
    ShaguTweaks.mods[T["Hide Errors"]].enable = function() end
    ShaguTweaks.mods[T["Darkened UI"]].enable = function() end
    ShaguTweaks.mods[T["Hide Gryphons"]].enable = function() end
    ShaguTweaks.mods[T["MiniMap Clock"]].enable = function() end
    ShaguTweaks.mods[T["MiniMap Tweaks"]].enable = function() end
    ShaguTweaks.mods[T["MiniMap Square"]].enable = function() end
    ShaguTweaks.mods[T["Movable Unit Frames"]].enable = function() end
    ShaguTweaks.mods[T["Real Health Numbers"]].enable = function() end
    ShaguTweaks.mods[T["Unit Frame Big Health"]].enable = function() end
    ShaguTweaks.mods[T["Reduced Actionbar Size"]].enable = function() end
    ShaguTweaks.mods[T["Unit Frame Class Colors"]].enable = function() end
    ShaguTweaks.mods[T["Unit Frame Health Colors"]].enable = function() end
    ShaguTweaks.mods[T["Unit Frame Class Portraits"]].enable = function() end
end

function Setup:ShaguExtras()
    local T = ShaguTweaks.T
    ShaguTweaks.mods[T["Show Bags"]].enable = function() end
    ShaguTweaks.mods[T["Show Micro Menu"]].enable = function() end
    ShaguTweaks.mods[T["Reagent Counter"]].enable = function() end
    ShaguTweaks.mods[T["Show Energy Ticks"]].enable = function() end
    ShaguTweaks.mods[T["Floating Actionbar"]].enable = function() end
    ShaguTweaks.mods[T["Dragonflight Gryphons"]].enable = function() end
    ShaguTweaks.mods[T["Center Vertical Actionbar"]].enable = function() end
end

function Setup:ShaguBagBorders()
    local mod = ShaguTweaks.mods[ShaguTweaks.T["Item Rarity Borders"]]
    if not mod then return end

    local orig = mod.enable
    mod.enable = function(self)
        orig(self)
        local skip = {
            "CharacterBag0Slot","CharacterBag1Slot",
            "CharacterBag2Slot","CharacterBag3Slot",
            "KeyRingButton"
        }
        for _, name in pairs(skip) do
            local btn = _G[name]
            if btn and btn.ShaguTweaks_border then
                btn.ShaguTweaks_border:Hide()
            end
        end
    end
end

function Setup:ShaguGUI()
    GameMenuButtonAdvancedOptions:Hide()
    GameMenuButtonAdvancedOptions:SetScript("OnClick", nil)
    AdvancedSettingsGUI:Hide()
    AdvancedSettingsGUI.Show = function() end
end

function Setup:ShaguMetaData()
    return {
        core = {
            ["Auto Dismount"]            = {true, "checkbox", nil, nil, "自动化", 1, "施法时自动下坐骑", nil, nil},
            ["Auto Stance"]              = {true, "checkbox", nil, nil, "自动化", 2, "战斗中自动切换所需姿态", nil, nil},
            ["Enemy Castbars"]           = {true, "checkbox", nil, nil, "施法条和姓名板", 3, "显示敌方目标施法条", nil, nil},
            ["Nameplate Castbar"]        = {true, "checkbox", nil, nil, "施法条和姓名板", 4, "在姓名板上显示施法条", nil, nil},
            ["Nameplate Scale"]          = {true, "checkbox", nil, nil, "施法条和姓名板", 5, "姓名板跟随UI缩放设置", nil, nil},
            ["Chat Hyperlinks"]          = {true, "checkbox", nil, nil, "聊天", 6, "聊天中启用可点击物品链接", nil, nil},
            ["Chat Tweaks"]              = {true, "checkbox", nil, nil, "聊天", 7, "改善聊天窗口行为和易用性", nil, nil},
            ["Social Colors"]            = {true, "checkbox", nil, nil, "聊天", 8, "在社交列表中显示职业颜色", nil, nil},
            ["Blue Shaman Class Colors"] = {true, "checkbox", nil, nil, "颜色", 9, "萨满职业颜色改为蓝色", nil, nil},
            ["Nameplate Class Colors"]   = {true, "checkbox", nil, nil, "颜色", 10, "姓名板使用职业颜色", nil, nil},
            ["WorldMap Class Colors"]    = {true, "checkbox", nil, nil, "颜色", 11, "地图图标使用职业颜色", nil, nil},
            ["Cooldown Numbers"]         = {true, "checkbox", nil, nil, "战斗", 12, "在冷却中显示数字计时", nil, nil},
            ["Debuff Timer"]             = {true, "checkbox", nil, nil, "战斗", 13, "显示Debuff持续时间", nil, nil},
            ["Super WoW Compatibility"]  = {true, "checkbox", nil, nil, "兼容性", 14, "支持SuperWoW客户端补丁", nil, nil},
            ["Turtle WoW Compatibility"] = {true, "checkbox", nil, nil, "兼容性", 15, "支持乌龟服自定义内容", nil, nil},
            ["Equip Compare"]            = {true, "checkbox", nil, nil, "提示框", 16, "提示框中直接比较装备", nil, nil},
            ["Item Rarity Borders"]      = {true, "checkbox", nil, nil, "提示框", 17, "按物品品质显示边框颜色", nil, nil},
            ["Tooltip Details"]          = {true, "checkbox", nil, nil, "提示框", 18, "提示框中添加额外详情", nil, nil},
            ["Sell Junk"]                = {true, "checkbox", nil, nil, "商人", 19, "自动出售所有灰色物品", nil, nil},
            ["Vendor Values"]            = {true, "checkbox", nil, nil, "商人", 20, "提示框中显示商人售价", nil, nil},
            ["WorldMap Coordinates"]     = {true, "checkbox", nil, nil, "世界地图", 21, "显示鼠标/玩家坐标", nil, nil},
            ["WorldMap Window"]          = {true, "checkbox", nil, nil, "世界地图", 22, "世界地图改为可移动窗口", nil, nil},
        },
        extras = {
            ["Bag Item Click"]           = {true, "checkbox", nil, nil, "背包", 1, "右键点击背包物品快速操作", nil, nil},
            ["Bag Search Bar"]           = {true, "checkbox", nil, nil, "背包", 2, "在背包中添加搜索栏", nil, nil},
            ["Center Text Input Box"]    = {true, "checkbox", nil, nil, "聊天", 3, "聊天输入框居中显示", nil, nil},
            ["Chat History"]             = {true, "checkbox", nil, nil, "聊天", 4, "保存聊天记录并在登录时恢复", nil, nil},
            ["Chat Timestamps"]          = {true, "checkbox", nil, nil, "聊天", 5, "为聊天消息添加时间戳", nil, nil},
            ["Enable Text Shadow"]       = {true, "checkbox", nil, nil, "聊天", 6, "启用聊天文字阴影", nil, nil},
            ["Macro Icons"]              = {true, "checkbox", nil, nil, "宏", 7, "检测宏中的技能并显示图标", nil, nil},
            ["Macro Tweaks"]             = {true, "checkbox", nil, nil, "宏", 8, "宏易用性改进", nil, nil},
            ["Enable Raid Frames"]       = {true, "checkbox", nil, nil, "团队", 9, "启用自定义团队框架", nil, nil},
            ["Hide Party Frames"]        = {true, "checkbox", nil, nil, "团队", 10, "团队时隐藏默认队伍框架", nil, nil},
            ["Show Dispel Indicators"]   = {true, "checkbox", nil, nil, "团队", 11, "显示可驱散Debuff指示器", nil, nil},
            ["Use As Party Frames"]      = {true, "checkbox", nil, nil, "团队", 12, "普通小队也使用团队框架", nil, nil},
            ["Show Group Headers"]       = {true, "checkbox", nil, nil, "团队", 13, "显示团队分组标题", nil, nil},
            ["Show Healing Predictions"] = {true, "checkbox", nil, nil, "团队", 14, "显示治疗预测", nil, nil},
            ["Show Combat Feedback"]     = {true, "checkbox", nil, nil, "团队", 15, "血量条上显示战斗反馈", nil, nil},
            ["Show Aggro Indicators"]    = {true, "checkbox", nil, nil, "团队", 16, "显示仇恨指示器", nil, nil},
            ["Use Compact Layout"]       = {true, "checkbox", nil, nil, "团队", 17, "使用紧凑布局", nil, nil},
            -- ["Show Energy Ticks"]        = {true, "checkbox", nil, nil, "tweaks", 18, "Show energy ticks for the rogue or druid class", nil, nil},
            ["Reveal World Map"]         = {true, "checkbox", nil, nil, "世界地图", 19, "显示未探索的地图区域", nil, nil},
        }
    }
end

function Setup:ApplyShagu()
    if not DFRL.addon1 then return end

    if not self.fixed.shaguCore then
        self:ShaguCore()
        self:ShaguBagBorders()
        self:ShaguGUI()
        self.fixed.shaguCore = true
    end

    if DFRL.addon2 and not self.fixed.shaguExtras then
        self:ShaguExtras()
        self.fixed.shaguExtras = true
    end

    if ShaguTweaks_config then
        if not DFRL.gui.shaguCore then
            DFRL.gui.shaguCoreData = self:ShaguMetaData().core
            DFRL.gui.shaguCore = true
        end

        if DFRL.addon2 and not DFRL.gui.shaguExtras then
            DFRL.gui.shaguExtrasData = self:ShaguMetaData().extras
            DFRL.gui.shaguExtras = true
        end
    else
        local waitFrame = CreateFrame("Frame")
        waitFrame.elapsed = 0
        waitFrame:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + arg1
            if ShaguTweaks_config or this.elapsed > 2 then
                this:SetScript("OnUpdate", nil)
                if ShaguTweaks_config then
                    if not DFRL.gui.shaguCore then
                        DFRL.gui.shaguCoreData = Setup:ShaguMetaData().core
                        DFRL.gui.shaguCore = true
                    end

                    if DFRL.addon2 and not DFRL.gui.shaguExtras then
                        DFRL.gui.shaguExtrasData = Setup:ShaguMetaData().extras
                        DFRL.gui.shaguExtras = true
                    end
                end
            end
        end)
    end
end

--=================
-- MORE LATER
--=================

--=================
-- INIT
--=================

function Setup:HandleAddon(name)
    if name == "ShaguTweaks" and not (ShaguTweaks and ShaguTweaks.T and ShaguTweaks.mods) then
        return
    end

    local addonType = self.addons[name]
    if addonType == "shagu" then
        self:ApplyShagu()
    end

    self.processed[name] = true
end

function Setup:CheckComplete(f)
    for name, _ in pairs(self.addons) do
        if not self.processed[name] then
            return false
        end
    end
    f:UnregisterEvent("ADDON_LOADED")
    return true
end

function Setup:Init()

    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function()
        if event == "ADDON_LOADED" and self.addons[arg1] then
            self:HandleAddon(arg1)
            self:CheckComplete(f)
        end
    end)

    if DFRL.addon1 and ShaguTweaks then
        self:ApplyShagu()
        self.processed["ShaguTweaks"] = true
        self:CheckComplete(f)
    end
end

Setup:Init()
