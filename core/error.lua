local error_counts = {}
local max_errors = 2

local function GetAddonName(msg)
    local start = string.find(msg, 'AddOns\\')
    if start then
        local path = string.sub(msg, start + 7)
        local end_pos = string.find(path, '\\')
        if end_pos then
            return string.sub(path, 1, end_pos - 1)
        end
    end
    return 'UNKNOWN'
end

local function FormatErrorMessage(addon, msg, throttled)
    if throttled then
        return '|cffff0000DFUI: Error: |cffffffff[|cffffffffSource: |cffff0000' .. addon .. '|cffffffff] : [|cffff0000ERROR SPAM THROTTLED|cffffffff]'
    else
        return '|cffff0000DFUI: Error: |cffffffff[|cffffffffSource: |cffff0000' .. addon .. '|cffffffff] : |cffffffff' .. (msg or 'nil')
    end
end

--=================
-- BUG 抓取缓冲（供"诊断"面板使用）
--=================
local MAX_ENTRIES = 50
local MAX_TEXT = 2048
local subscribers = {}
local toastFrame
local prefsDefaults = { autoToast = false, onlyDFUI = false }

DFUI = DFUI or {}
DFUI.errors = DFUI.errors or {}
DFUI.errors.list = {}
DFUI.errors.prefs = prefsDefaults

local function notifySubs()
    for i = 1, table.getn(subscribers) do
        local cb = subscribers[i]
        if cb then pcall(cb) end
    end
end

local function truncate(s, max)
    if not s then return "" end
    if string.len(s) <= max then return s end
    return string.sub(s, 1, max) .. "\n...[已截断]"
end

local function safeStack()
    if type(debugstack) == "function" then
        local ok, s = pcall(debugstack, 3)
        if ok and type(s) == "string" then return s end
    end
    return ""
end

local function timestamp()
    if type(date) == "function" then
        local ok, s = pcall(date, "%H:%M:%S")
        if ok and s then return s end
    end
    return string.format("%.1fs", GetTime())
end

local function showToast(addon)
    if not DFUI.errors.prefs.autoToast then return end
    if not toastFrame then
        toastFrame = CreateFrame("Frame", "DFUIBugToast", UIParent)
        toastFrame:SetWidth(360)
        toastFrame:SetHeight(50)
        toastFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        toastFrame:SetFrameStrata("HIGH")
        toastFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        toastFrame:SetBackdropColor(0, 0, 0, 0.8)
        toastFrame:SetBackdropBorderColor(1, 0.3, 0.3, 1)
        toastFrame.text = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        toastFrame.text:SetPoint("CENTER", toastFrame, "CENTER", 0, 0)
        toastFrame.text:SetTextColor(1, 0.82, 0)
        toastFrame:Hide()
    end
    toastFrame.text:SetText("|cffff5555新 Bug:|r " .. (addon or "?") .. "    输入 |cffffd100/dfbug|r 查看")
    toastFrame:SetAlpha(1)
    toastFrame:Show()
    toastFrame.expire = GetTime() + 3
    toastFrame:SetScript("OnUpdate", function()
        local left = this.expire - GetTime()
        if left <= 0 then
            this:Hide()
            this:SetScript("OnUpdate", nil)
        elseif left < 1 then
            this:SetAlpha(left)
        end
    end)
end

local function recordBug(addon, msg)
    msg = truncate(msg or "nil", MAX_TEXT)
    local list = DFUI.errors.list
    -- 同消息合并
    for i = 1, table.getn(list) do
        local b = list[i]
        if b.msg == msg then
            b.n = b.n + 1
            b.t = GetTime()
            b.date = timestamp()
            -- 移到末尾（最新）
            table.remove(list, i)
            table.insert(list, b)
            notifySubs()
            return
        end
    end
    -- 新条目
    table.insert(list, {
        t = GetTime(),
        date = timestamp(),
        n = 1,
        src = addon or "UNKNOWN",
        msg = msg,
        stack = truncate(safeStack(), MAX_TEXT),
    })
    -- 容量裁剪
    while table.getn(list) > MAX_ENTRIES do
        table.remove(list, 1)
    end
    notifySubs()
    showToast(addon)
end

function DFUI.errors.Subscribe(cb)
    table.insert(subscribers, cb)
end

function DFUI.errors.Clear()
    DFUI.errors.list = {}
    if DFUI_BUGS then DFUI_BUGS.entries = {} end
    notifySubs()
end

function DFUI.errors.GetFiltered(onlyDFUI)
    if not onlyDFUI then return DFUI.errors.list end
    local out = {}
    local list = DFUI.errors.list
    for i = 1, table.getn(list) do
        if list[i].src == "Dragonflight-Fix" or list[i].src == "DFUI" then
            table.insert(out, list[i])
        end
    end
    return out
end

-- 直接写入测试条目，绕过 seterrorhandler 链
function DFUI.errors.TestRecord(src, msg)
    recordBug(src or "DFUI-Test", msg or ("DFUI 自检测试条目 " .. GetTime()))
end

-- 返回当前注册的 seterrorhandler，让诊断面板判断是否被劫持
function DFUI.errors.GetHandler()
    return geterrorhandler and geterrorhandler() or nil
end

function DFUI.errors.Reclaim()
    if DFUI.errors._handler then
        seterrorhandler(DFUI.errors._handler)
    end
end

local function ErrorHandler(msg)
    local addon = GetAddonName(msg)

    if not error_counts[msg] then
        error_counts[msg] = 1
        DEFAULT_CHAT_FRAME:AddMessage(FormatErrorMessage(addon, msg, false))
    else
        error_counts[msg] = error_counts[msg] + 1
        if error_counts[msg] <= max_errors then
            DEFAULT_CHAT_FRAME:AddMessage(FormatErrorMessage(addon, msg, false))
        elseif error_counts[msg] == max_errors + 1 then
            DEFAULT_CHAT_FRAME:AddMessage(FormatErrorMessage(addon, msg, true))
        end
    end

    -- 捕获到缓冲（聊天节流不影响这里）
    pcall(recordBug, addon, msg)
end

seterrorhandler(ErrorHandler)
DFUI.errors._handler = ErrorHandler

local restored = false
local function restoreFromSV()
    if restored then return end
    if type(DFUI_BUGS) ~= "table" then DFUI_BUGS = {} end
    if type(DFUI_BUGS.entries) ~= "table" then DFUI_BUGS.entries = {} end
    if type(DFUI_BUGS.prefs) ~= "table" then DFUI_BUGS.prefs = {} end
    for k, v in pairs(prefsDefaults) do
        if DFUI_BUGS.prefs[k] == nil then DFUI_BUGS.prefs[k] = v end
    end
    DFUI.errors.prefs = DFUI_BUGS.prefs
    -- 恢复历史条目（放在最前），再附加本会话已收到的
    local session = DFUI.errors.list
    DFUI.errors.list = {}
    for i = 1, table.getn(DFUI_BUGS.entries) do
        table.insert(DFUI.errors.list, DFUI_BUGS.entries[i])
    end
    for i = 1, table.getn(session) do
        table.insert(DFUI.errors.list, session[i])
    end
    while table.getn(DFUI.errors.list) > MAX_ENTRIES do
        table.remove(DFUI.errors.list, 1)
    end
    restored = true
    notifySubs()
end

DFUI.errors.RestoreFromSV = restoreFromSV

local f = CreateFrame'Frame'
f:RegisterEvent'ADDON_LOADED'
f:RegisterEvent'VARIABLES_LOADED'
f:RegisterEvent'PLAYER_LOGIN'
f:RegisterEvent'PLAYER_ENTERING_WORLD'
f:RegisterEvent'PLAYER_LOGOUT'
f:SetScript('OnEvent', function()
    if event == "ADDON_LOADED" then
        if arg1 and string.lower(arg1) == "dragonflight-fix" then
            restoreFromSV()
        end
        seterrorhandler(ErrorHandler)
    elseif event == "VARIABLES_LOADED" then
        restoreFromSV()
        seterrorhandler(ErrorHandler)
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- 在所有插件加载完成后再次抢回错误处理器
        seterrorhandler(ErrorHandler)
    elseif event == "PLAYER_LOGOUT" then
        if type(DFUI_BUGS) ~= "table" then DFUI_BUGS = {} end
        DFUI_BUGS.entries = DFUI.errors.list
        DFUI_BUGS.prefs = DFUI.errors.prefs
    end
end)

-- /dfbug：打开主面板并切到诊断 Tab
_G["SLASH_DFBUG1"] = "/dfbug"
_G.SlashCmdList["DFBUG"] = function()
    local Base = DFUI and DFUI.gui and DFUI.gui.Base
    if not Base or not Base.mainFrame then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000DFUI: 主面板尚未初始化|r")
        return
    end
    if not Base.mainFrame:IsShown() then
        Base.mainFrame:Show()
    end
    -- 诊断 Tab 是 tabs 表最末一项
    local lastTab = table.getn(Base.tabs)
    for i = 1, lastTab do
        if Base.tabs[i] == "诊断" then
            Base:SelectTab(i)
            return
        end
    end
end
