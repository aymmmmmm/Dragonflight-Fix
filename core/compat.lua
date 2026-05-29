setfenv(1, DFUI:GetEnv())

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
    -- 禁用 ShaguTweaks 冷却数字和 Debuff 计时，由 Dragonflight-Fix 的模块替代
    if ShaguTweaks.mods[T["Cooldown Numbers"]] then
        ShaguTweaks.mods[T["Cooldown Numbers"]].enable = function() end
    end
    if ShaguTweaks.mods[T["Debuff Timer"]] then
        ShaguTweaks.mods[T["Debuff Timer"]].enable = function() end
    end
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
    -- These globals come from ShaguTweaks "Advanced Options"; absent if disabled or on 1.17.
    if GameMenuButtonAdvancedOptions then
        GameMenuButtonAdvancedOptions:Hide()
        GameMenuButtonAdvancedOptions:SetScript("OnClick", nil)
    end
    if AdvancedSettingsGUI then
        AdvancedSettingsGUI:Hide()
        AdvancedSettingsGUI.Show = function() end
    end
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
    if not DFUI.addon1 then return end

    if not self.fixed.shaguCore then
        self:ShaguCore()
        self:ShaguBagBorders()
        self:ShaguGUI()
        self.fixed.shaguCore = true
    end

    if DFUI.addon2 and not self.fixed.shaguExtras then
        self:ShaguExtras()
        self.fixed.shaguExtras = true
    end

    if ShaguTweaks_config then
        if not DFUI.gui.shaguCore then
            DFUI.gui.shaguCoreData = self:ShaguMetaData().core
            DFUI.gui.shaguCore = true
        end

        if DFUI.addon2 and not DFUI.gui.shaguExtras then
            DFUI.gui.shaguExtrasData = self:ShaguMetaData().extras
            DFUI.gui.shaguExtras = true
        end
    else
        local waitFrame = CreateFrame("Frame")
        waitFrame.elapsed = 0
        waitFrame:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + arg1
            if ShaguTweaks_config or this.elapsed > 2 then
                this:SetScript("OnUpdate", nil)
                if ShaguTweaks_config then
                    if not DFUI.gui.shaguCore then
                        DFUI.gui.shaguCoreData = Setup:ShaguMetaData().core
                        DFUI.gui.shaguCore = true
                    end

                    if DFUI.addon2 and not DFUI.gui.shaguExtras then
                        DFUI.gui.shaguExtrasData = Setup:ShaguMetaData().extras
                        DFUI.gui.shaguExtras = true
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

    if DFUI.addon1 and ShaguTweaks then
        self:ApplyShagu()
        self.processed["ShaguTweaks"] = true
        self:CheckComplete(f)
    end
end

Setup:Init()

--=================
-- VANILLA 1.17 FRAMEXML PATCHES
-- 1.17 客户端降级后部分 FrameXML 全局未初始化 / 内置 addon 行为异常。
-- DFUI.env 的 metatable 没有 __newindex，必须显式 _G.XXX 写全局。
--=================
do
    -- 当前生效的 patch-9（最高优先级，覆盖 patch-8/patch/interface）UIDropDownMenu 的模板
    -- 静态建有限个按钮（$parentButtonN，实测约 38，随 patch 版本浮动），且无 CreateFrames
    -- 不能动态扩建。Atlas（Atlas.lua:35）却把全局 UIDROPDOWNMENU_MAXBUTTONS 顶到 48 且不还原，
    -- 48 > 静态按钮数，于是任何
    --   `for i=1,MAXBUTTONS do _G["DropDownList"..lvl.."Button"..i]:XXX() end`
    -- 循环跑到第一个不存在的按钮时即 nil → 崩（隐藏循环 :44 的 button:Hide()、
    -- ClearAll:760 的 button:UnlockHighlight()）。任何把上限顶过静态按钮数的插件同理。
    --
    -- 修复：进 Initialize/Refresh/ClearAll 前，把上限临时钳到“所有 level 实际连续按钮数的最小值”
    -- （运行时实测，不硬编码——按钮数随 patch 变；隐藏循环遍历所有 level，取最小才对每个都安全），
    -- pcall 兜底，调用后立即还原。⚠️ 但 OnShow 等 XML 内联脚本绑在 frame 上、frame:Show() 时 C 层
    -- 直接触发，没有全局函数可 hook，临时钳位够不着（本次 DropDownList1:OnShow:4 即此）→ 见下方 ddlPin，
    -- 改在 PLAYER_LOGIN 把 MAXBUTTONS **永久**钳到实测真值。永久钳安全（旧注释"会污染分页"判断有误）：
    -- 第 39+ 号按钮本就不存在、48 是虚高错值，Atlas 33≤真值不受影响，Bagshui 按真值分页（多翻页不填 nil）。
    if _G.UIDROPDOWNMENU_OPEN_MENU == nil then
        _G.UIDROPDOWNMENU_OPEN_MENU = ""
    end

    local function ddlGetLevels()
        local n = _G.UIDROPDOWNMENU_MAXLEVELS
        if type(n) == "number" and n >= 1 then return n end
        return 3
    end

    -- 所有“已存在 level”的最小连续按钮数（遇第一个不存在的即停）—— 隐藏循环遍历所有 level，取最小才对每个都安全
    local function ddlSafeMax(cap)
        local minCount = nil
        for level = 1, ddlGetLevels() do
            if _G["DropDownList" .. level] then
                local c = 0
                for j = 1, cap do
                    if _G["DropDownList" .. level .. "Button" .. j] then c = j else break end
                end
                if minCount == nil or c < minCount then minCount = c end
            end
        end
        return minCount
    end

    local function ddlGuardBefore()
        if _G.UIDROPDOWNMENU_OPEN_MENU == nil then
            _G.UIDROPDOWNMENU_OPEN_MENU = ""
        end
        local savedMax = _G.UIDROPDOWNMENU_MAXBUTTONS
        if type(savedMax) == "number" and savedMax > 1 then
            local safe = ddlSafeMax(savedMax)
            if safe and safe >= 1 and safe < savedMax then
                _G.UIDROPDOWNMENU_MAXBUTTONS = safe
            end
        end
        return savedMax
    end

    if type(_G.UIDropDownMenu_Initialize) == "function" then
        local _origInit = _G.UIDropDownMenu_Initialize
        _G.UIDropDownMenu_Initialize = function(frame, initFunc, displayMode, level)
            local savedMax = ddlGuardBefore()
            local ok, err = pcall(_origInit, frame, initFunc, displayMode, level)
            _G.UIDROPDOWNMENU_MAXBUTTONS = savedMax
            if not ok then
                return nil, err
            end
        end
    end

    -- Refresh 内部也有 1..MAXBUTTONS 循环（如 UIOptionsFrameTargetofTargetDropDown 的 OnLoad）；
    -- 第三参 dropdownLevel 透传以兼容带该参的版本。
    if type(_G.UIDropDownMenu_Refresh) == "function" then
        local _origRefresh = _G.UIDropDownMenu_Refresh
        _G.UIDropDownMenu_Refresh = function(frame, useValue, dropdownLevel)
            local savedMax = ddlGuardBefore()
            local ok, err = pcall(_origRefresh, frame, useValue, dropdownLevel)
            _G.UIDROPDOWNMENU_MAXBUTTONS = savedMax
            if not ok then return nil, err end
        end
    end

    -- ClearAll 内部同样有 1..MAXBUTTONS 静态循环（line 758: button:UnlockHighlight()）；
    -- WorldMap 的 SetMapToCurrentZone → WorldMap_UpdateZoneDropDownText 会直接调它，
    -- 绕过 Initialize/Refresh，故 Atlas 顶到 48 时第 39+ 个按钮 nil 崩。同样钳位兜底。
    if type(_G.UIDropDownMenu_ClearAll) == "function" then
        local _origClearAll = _G.UIDropDownMenu_ClearAll
        _G.UIDropDownMenu_ClearAll = function(frame)
            local savedMax = ddlGuardBefore()
            local ok, err = pcall(_origClearAll, frame)
            _G.UIDROPDOWNMENU_MAXBUTTONS = savedMax
            if not ok then return nil, err end
        end
    end

    -- 治本：OnShow 等 XML 内联脚本（frame:Show() 时 C 层触发，无全局函数可 hook）够不着上面的
    -- 临时钳位——右键头像 BCS ToggleDropDownMenu → DropDownList1:Show → OnShow:4
    -- `_G[..Button..i]:SetWidth` 撞 nil 即此；GetSelectedID(:466) 等也未 hook。故按 ddlSafeMax
    -- 实测真值把 MAXBUTTONS **永久**钳定，一次兜住全部入口（Initialize/Refresh/ClearAll/
    -- GetSelectedID/OnShow 内联脚本）。幂等：钳到真值后 real<cur 不再成立，重入不会误降。
    local function ddlPinNow()
        local cur = _G.UIDROPDOWNMENU_MAXBUTTONS
        if type(cur) == "number" and cur > 1 then
            local real = ddlSafeMax(cur)
            if real and real >= 1 and real < cur then
                _G.UIDROPDOWNMENU_MAXBUTTONS = real
            end
        end
    end

    -- (a) 文件级立即钳一次：Atlas(A) 必早于 Dragonflight-Fix(D) 加载，此刻 48 已就位，
    --     DropDownList1/2/3 及其按钮（FrameXML 早于所有 addon 创建）已存在，ddlSafeMax 可立即测真值。
    --     不依赖任何事件——避免 /reload 不触发 PLAYER_LOGIN 导致 reload 后停在 48 的缺口。
    ddlPinNow()

    -- (b) PLAYER_ENTERING_WORLD（登录与 /reload 都触发）再钳一次作防御：
    --     防某插件在 DF-Fix 文件级之后再把上限顶高。
    local ddlPin = CreateFrame("Frame")
    ddlPin:RegisterEvent("PLAYER_ENTERING_WORLD")
    ddlPin:SetScript("OnEvent", ddlPinNow)

    -- (4) Turtle_ShopUI patch-Z 滞后服务器：
    --   - Shop_ProcessEntries:285 调 SetHyperlink，但服务器返回了 patch-Z 不认识的新链接类型 → Unknown link type
    --   - Shop_ProcessCategories:159 在某 nil 字段上做数字比较
    -- pcall 包裹避免刷屏。商城功能本来就因为版本不匹配半残，这里只是止血。
    for _, fn in pairs({"Shop_ProcessEntries", "Shop_ProcessCategories"}) do
        if type(_G[fn]) == "function" then
            local _orig = _G[fn]
            _G[fn] = function(a, b, c, d, e, f, g, h)
                pcall(_orig, a, b, c, d, e, f, g, h)
            end
        end
    end

    -- (2) 内置 HardcoreTooltips (patch-7.mpq) 在 1.17 下:
    -- TargetFrameDebuff17+ 的 OnEnter 调用 HardcoreTooltips:SetUnitDebuff(命名空间方法)，
    -- 进而触发 vanilla TargetFrame.lua:56 nil 比较。
    -- 多时机 hook 按钮 OnEnter，防止被后加载的 addon 覆盖。
    local function patchAuraButtons()
        for i = 1, 32 do
            local debuffBtn = _G["TargetFrameDebuff" .. i]
            if debuffBtn and not debuffBtn._dfui_patched then
                local oldScript = debuffBtn:GetScript("OnEnter")
                debuffBtn:SetScript("OnEnter", function()
                    local idx = this and this:GetID()
                    if not idx or not UnitDebuff("target", idx) then return end
                    if oldScript then oldScript() end
                end)
                debuffBtn._dfui_patched = true
            end
            local buffBtn = _G["TargetFrameBuff" .. i]
            if buffBtn and not buffBtn._dfui_patched then
                local oldScript = buffBtn:GetScript("OnEnter")
                buffBtn:SetScript("OnEnter", function()
                    local idx = this and this:GetID()
                    if not idx or not UnitBuff("target", idx) then return end
                    if oldScript then oldScript() end
                end)
                buffBtn._dfui_patched = true
            end
        end
    end

    local vc = CreateFrame("Frame")
    vc:RegisterEvent("PLAYER_LOGIN")
    vc:RegisterEvent("PLAYER_ENTERING_WORLD")
    vc:RegisterEvent("PLAYER_TARGET_CHANGED")
    vc:SetScript("OnEvent", patchAuraButtons)
    -- 立即尝试一次（按钮在 FrameXML 加载阶段就已创建）
    patchAuraButtons()

    -- (3) 兜底：全局 SetUnitDebuff 加 nil 守卫
    if type(_G.SetUnitDebuff) == "function" then
        local _orig = _G.SetUnitDebuff
        _G.SetUnitDebuff = function(unit, index)
            if not unit or not index then return end
            if not UnitDebuff(unit, index) then return end
            return _orig(unit, index)
        end
    end
end
