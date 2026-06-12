----------------------------------------------------------------------
-- DFUI.Assist  --  辅助功能引擎（从独立插件 MiniAssist 并入 DFUI）
-- Lua 5.0 / WoW 1.12 (Turtle WoW)
--
-- 架构：register() 声明 + 运行时门控（读 DFUI 档案 DFUI:GetTempDB("Assist",key)
--   叠加运行时总开关 masterOn）。单 dispatch frame 统一 OnEvent/OnUpdate 分发，
--   load 回调在 PLAYER_LOGIN 建持久 UI。配置随 DFUI 档案存储。
----------------------------------------------------------------------

DFUI.Assist = {}
DFUI.Assist.modules = {}      -- key -> mod 表
DFUI.Assist.order   = {}      -- 注册顺序（配置面板按此排列）
DFUI.Assist.db      = nil     -- = DFUI.tempDB["Assist"]（NewMod 启动时绑定）

local dispatch     = CreateFrame("Frame", "DFUIAssistDispatch", UIParent)
local byEvent      = {}       -- EVENT -> { mod, mod, ... }
local onUpdateMods = {}       -- { mod, ... }
local loadMods     = {}       -- { mod, ... } 有 load 回调

----------------------------------------------------------------------
-- 键位绑定字符串（出现在 ESC→按键设置 "DFUI 辅助功能" 分组）
----------------------------------------------------------------------
do
    local loc = GetLocale()
    if loc == "zhCN" or loc == "zhTW" then
        BINDING_HEADER_DFUI_ASSIST       = "DFUI 辅助功能"
        BINDING_NAME_DFUI_ASSIST_CONFIG  = "打开辅助配置"
        BINDING_NAME_DFUI_ASSIST_TOGGLE  = "切换辅助总开关"
    else
        BINDING_HEADER_DFUI_ASSIST       = "DFUI Assist"
        BINDING_NAME_DFUI_ASSIST_CONFIG  = "Open Assist Config"
        BINDING_NAME_DFUI_ASSIST_TOGGLE  = "Toggle Assist Master"
    end
end

----------------------------------------------------------------------
-- 聊天输出
----------------------------------------------------------------------
function DFUI.Assist.Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66bbff[辅助]|r " .. tostring(msg))
    end
end

function DFUI.Assist.GetAccentHex()
    return "ffffd200"
end

----------------------------------------------------------------------
-- 警报：RaidWarning 文字 + 分级声音（安全模块共用）
----------------------------------------------------------------------
function DFUI.Assist.Alert(msg, r, g, b, sound)
    r = r or 1; g = g or 0.82; b = b or 0
    if RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, msg, { r = r, g = g, b = b })
    elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(msg, r, g, b, 1.0, UIERRORS_HOLD_TIME or 2.0)
    end
    if sound and PlaySound then
        if sound == "critical" then
            PlaySound("RaidWarning")
        elseif sound == "warning" then
            PlaySound("igQuestFailed")
        else
            PlaySound("igQuestLogAbandonQuest")
        end
    end
end

----------------------------------------------------------------------
-- 危险红屏脉冲：多来源引用计数，任一来源开启即显示
----------------------------------------------------------------------
local redOverlay
local redActive = false
local redElapsed = 0
local flashSources = {}

function DFUI.Assist.SetDangerFlash(source, on)
    if not source then return end
    if on then flashSources[source] = true else flashSources[source] = nil end

    local any = false
    for _ in pairs(flashSources) do any = true; break end
    redActive = any

    if any and not redOverlay then
        redOverlay = CreateFrame("Frame", "DFUIAssistDangerFlash", UIParent)
        redOverlay:SetAllPoints(UIParent)
        redOverlay:SetFrameStrata("FULLSCREEN_DIALOG")
        redOverlay:EnableMouse(false)
        local t = redOverlay:CreateTexture(nil, "BACKGROUND")
        t:SetAllPoints(redOverlay)
        t:SetTexture(1, 0, 0, 1)
        t:SetAlpha(0)
        redOverlay.tex = t
    end
    if redOverlay then
        if any then redOverlay:Show() else redOverlay:Hide() end
    end
end

----------------------------------------------------------------------
-- 开关读写（运行时门控：masterOn 总开关 + 各功能 key，读 DFUI 档案）
----------------------------------------------------------------------
function DFUI.Assist:IsEnabled(key)
    -- 实时读当前档案的 Assist 段（切换档案后自动跟随，不缓存指针）
    local db = DFUI.tempDB and DFUI.tempDB["Assist"]
    if not db then return false end
    if db.enabled == false then return false end   -- 模块在管理页被禁用
    if db.masterOn == false then return false end
    local v = db[key]
    if v == nil then return false end
    return v
end

function DFUI.Assist:SetEnabled(key, val)
    val = (val and true) or false
    DFUI:SetTempDB("Assist", key, val)
    if self.db then self.db[key] = val end
end

----------------------------------------------------------------------
-- 模块注册
--   mod = { key, title, desc, group, default,
--           events={EVENT=function(self) ... end}, onUpdate=fn, load=fn }
----------------------------------------------------------------------
function DFUI.Assist:register(mod)
    if not mod or not mod.key then return end
    if self.modules[mod.key] then return end

    self.modules[mod.key] = mod
    table.insert(self.order, mod.key)

    if mod.events then
        for ev in pairs(mod.events) do
            if not byEvent[ev] then
                byEvent[ev] = {}
                dispatch:RegisterEvent(ev)
            end
            table.insert(byEvent[ev], mod)
        end
    end
    if mod.onUpdate then table.insert(onUpdateMods, mod) end
    if mod.load then table.insert(loadMods, mod) end
end

----------------------------------------------------------------------
-- 事件分发
----------------------------------------------------------------------
local loaded = false
dispatch:RegisterEvent("PLAYER_LOGIN")
dispatch:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" and not loaded then
        loaded = true
        -- 模块被禁用则不建持久 UI（避免访问未绑定的 db）
        local adb = DFUI.tempDB and DFUI.tempDB["Assist"]
        if adb and adb.enabled ~= false then
            for i = 1, table.getn(loadMods) do
                loadMods[i].load(loadMods[i])
            end
        end
    end

    local list = byEvent[event]
    if not list then return end
    for i = 1, table.getn(list) do
        local m = list[i]
        if DFUI.Assist:IsEnabled(m.key) then
            m.events[event](m)
        end
    end
end)

dispatch:SetScript("OnUpdate", function()
    local elapsed = arg1

    -- 红屏来源对应功能被关闭则即时撤销，防取消功能后红屏残留
    if redActive then
        if flashSources["health"] and not DFUI.Assist:IsEnabled("safeHealth") then
            DFUI.Assist.SetDangerFlash("health", false)
        end
        if flashSources["breath"] and not DFUI.Assist:IsEnabled("safeBreath") then
            DFUI.Assist.SetDangerFlash("breath", false)
        end
    end

    if redActive and redOverlay and redOverlay.tex then
        redElapsed = redElapsed + elapsed
        local pulse = 0.08 + 0.16 * (0.5 + 0.5 * math.sin(redElapsed * 4))
        redOverlay.tex:SetAlpha(pulse)
    end

    local n = table.getn(onUpdateMods)
    if n > 0 then
        for i = 1, n do
            local m = onUpdateMods[i]
            if DFUI.Assist:IsEnabled(m.key) then
                m.onUpdate(m, elapsed)
            end
        end
    end
end)

----------------------------------------------------------------------
-- 键位/面板入口
----------------------------------------------------------------------
function DFUI.Assist.OpenConfig()
    local B = DFUI.gui and DFUI.gui.Base
    if not B then return end
    if B.mainFrame then B.mainFrame:Show() end
    if B.titleFrame then B.titleFrame:Show() end
    if B.SelectTab then B:SelectTab(DFUI.Assist.tabIndex or 17) end
end

function DFUI.Assist.ToggleMaster()
    local self = DFUI.Assist
    if not self.db then return end
    local cur = self.db.masterOn
    if cur == false then cur = true else cur = false end
    DFUI:SetTempDB("Assist", "masterOn", cur)
    self.db.masterOn = cur
    DFUI.Assist.Alert(cur and "辅助总开关：开（已勾选功能生效）" or "辅助总开关：关（全部暂停）",
        1, 0.82, 0, cur and "warning" or nil)
end

----------------------------------------------------------------------
-- DFUI 模块注册：默认配置 + 启动入口
----------------------------------------------------------------------
DFUI:NewDefaults("Assist", {
    enabled    = { true },   -- DFUI 模块总启停（模块管理页，重载生效）
    masterOn   = { true },   -- 运行时总开关（键位/面板即时切换）
    -- 自动化（默认全部关闭，用户在配置页勾选才开启）
    autoQuestAccept  = { false },
    autoQuestTurnin  = { false },
    autoStand        = { false },
    autoBag          = { false },
    autoBoP          = { false },
    autoAttack       = { false },
    autoRoll         = { false },
    autoRelease      = { false },
    autoDismount     = { false },
    autoLearnReplace = { false },
    autoUnlock       = { false },
    autoSell         = { false },
    autoRepair       = { false },
    -- 安全（默认关闭）
    safeHealth  = { false },
    safeBreath  = { false },
    safeElite   = { false },
    safeZone    = { false },
    -- 界面（默认关闭）
    uiAttackBar  = { false },
    uiQuickMark  = { false },
    uiCombatAlert = { false },
    uiMarkKnown   = { false },
    uiTargetArrow = { false },
    targetArrowStyle = { "Arrow2" },   -- 目标箭头样式（文件名，见 targetarrow.lua）
    uiMobInfo    = { false },
    -- 链接（默认关闭）
    linkItemEnUS = { false },
    linkPfQuest  = { false },
    -- 数据：自动 Roll 按品质分别设（0放弃/1需求/2贪婪/3不自动）
    rollGray    = { 2 },     -- 灰白：贪婪
    rollGreen   = { 2 },     -- 绿：贪婪
    rollBlue    = { 2 },     -- 蓝：贪婪
    rollEpic    = { 3 },     -- 紫橙：不自动（贵重物默认留给玩家手点）
    assistMigrated = { false },   -- 一次性重置标志（测试阶段：首次加载强制全关）
})

DFUI:NewMod("Assist", 20, function()
    -- 绑定运行时配置表（= 当前档案的 Assist 段）
    DFUI.Assist.db = DFUI.tempDB["Assist"]

    -- 测试阶段：首次加载把所有辅助功能强制重置为关闭（只跑一次，不影响之后手动勾选）
    local db = DFUI.Assist.db
    if db and not db.assistMigrated then
        local keys = {
            "autoQuestAccept", "autoQuestTurnin", "autoStand", "autoBag", "autoBoP", "autoAttack", "autoRoll", "autoRelease",
            "safeHealth", "safeBreath", "safeElite", "safeZone", "uiAttackBar", "uiQuickMark",
        }
        for i = 1, table.getn(keys) do
            db[keys[i]] = false
        end
        db.assistMigrated = true
    end
end)
