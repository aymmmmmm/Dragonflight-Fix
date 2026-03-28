-- mainframe
DFUI = CreateFrame("Frame", nil, UIParent)

-- tables
DFUI_PROFILES = {}
DFUI_DB_SETUP = {}
DFUI_CUR_PROFILE = {}
DFUI_FRAMEPOS = {}

DFUI.env = {}
DFUI.tools = {}
DFUI.hooks = {}
DFUI.tempDB = {}
DFUI.modules = {}
DFUI.defaults = {}
DFUI.profiles = {}
DFUI.callbacks = {}
DFUI.performance = {}
DFUI.activeScripts = {}
DFUI.gui = {}

-- db version
DFUI.DBversion = "2.0"

-- boot flag
local boot = false

-- utility
function DFUI:GetInfoOrCons(type)
    local name = "Dragonflight-Fix"
    if type == "name" then
        return name
    elseif type == "version" then
        return GetAddOnMetadata(name, "Version")
    elseif type == "author" then
        return GetAddOnMetadata(name, "Author")
    elseif type == "path" then
        return "Interface\\AddOns\\" .. name .. "\\"
    elseif type == "media" then
        return "Interface\\AddOns\\" .. name .. "\\media\\"
    elseif type == "tex" then
        return "Interface\\AddOns\\" .. name .. "\\media\\tex\\"
    elseif type == "font" then
        return "Interface\\AddOns\\" .. name .. "\\media\\fnt\\"
    end
end

function DFUI:CheckAddon(name)
    if name == "ShaguTweaks" then
        self.addon1 = true
    elseif name == "ShaguTweaks-extras" then
        self.addon2 = true
    elseif name == "Bagshui" then
        self.addon3 = true
    elseif name == "Immersion" then
        self.addon4 = true
    end
end

function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100DFUI: |r".. tostring(msg))
end

-- 职业颜色工具：优先使用 DFUI.classColors，回退到 RAID_CLASS_COLORS
-- 返回 {r, g, b} 表或 nil
function DFUI:GetClassColor(class)
    if not class then return nil end
    local custom = self.classColors and self.classColors[class]
    if custom then return custom end
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        return RAID_CLASS_COLORS[class]
    end
    return nil
end

-- environment
function DFUI:GetEnv()
    self.env._G = getfenv(0)
    self.env.T = self.tools
    return self.env
end

setmetatable(DFUI.env, {__index = getfenv(0)})

-- modules
function DFUI:NewDefaults(mod, defaults)
    if not self.defaults[mod] then
        self.defaults[mod] = {}
    end

    for key, value in pairs(defaults) do
        self.defaults[mod][key] = value
    end
end

function DFUI:NewMod(name, prio, func)
    if self.modules[name] then return end
    self.modules[name] = {func = func, priority = prio}
end

function DFUI:RunMods()
    local list = {}
    for name, data in pairs(self.modules) do
        tinsert(list, {name = name, func = data.func, priority = data.priority})
    end

    table.sort(list, function(a, b) return a.priority < b.priority end)

    for i = 1, table.getn(list) do
        local name = list[i].name
        local func = list[i].func
		local enabled = self.tempDB[name] and self.tempDB[name].enabled
		if enabled == true then
            collectgarbage()
			local start = GetTime()
			local mem = gcinfo()
			setfenv(func, self:GetEnv())
			local success, err = pcall(func)
			if success then
				self.performance[name] = {
					time = GetTime() - start,
					memory = gcinfo() - mem
				}
			else
				geterrorhandler()(err)
			end
		end
	end
end

-- database
function DFUI:InitTempDB()
    self:VersionCheckDB()

    -- set default profile if none exists
    local char = UnitName("player")

    if not DFUI_CUR_PROFILE[char] then
        DFUI_CUR_PROFILE[char] = "Default"
    end

    local cur = DFUI_CUR_PROFILE[char]

    -- ensure profile exists
    if not DFUI_PROFILES[cur] then
        DFUI_PROFILES[cur] = {}
    end

    -- copy existing module settings from current profile
    for mod, tbl in pairs(DFUI_PROFILES[cur]) do
        if type(tbl) == "table" then
            self.tempDB[mod] = self.tempDB[mod] or {}
            for key, value in pairs(tbl) do
                self.tempDB[mod][key] = value
            end
        end
    end

    -- add missing defaults
    for mod, def in pairs(self.defaults) do
        self.tempDB[mod] = self.tempDB[mod] or {}
        for key, val in pairs(def) do
            if self.tempDB[mod][key] == nil then
                self.tempDB[mod][key] = val[1]
            end
        end
    end
end

function DFUI:VersionCheckDB()
    local oldVer = DFUI_DB_SETUP.version
    if oldVer == self.DBversion then return end

    -- 版本不匹配：合并新增默认值到现有数据，而非清空
    if oldVer and next(DFUI_PROFILES) then
        for profileName, profileData in pairs(DFUI_PROFILES) do
            for mod, def in pairs(self.defaults) do
                if not profileData[mod] then
                    profileData[mod] = {}
                end
                for key, val in pairs(def) do
                    if profileData[mod][key] == nil then
                        profileData[mod][key] = val[1]
                    end
                end
            end
        end
        print("配置已迁移至 v" .. self.DBversion)
    else
        -- 首次安装或无有效数据，清空重建
        DFUI_PROFILES = {}
        DFUI_CUR_PROFILE = {}
    end

    DFUI_DB_SETUP = {}
    DFUI_DB_SETUP.version = self.DBversion
end

function DFUI:SetTempDB(mod, key, value)
    self.tempDB[mod][key] = value
    local cb = mod .. "_" .. key .. "_changed"
    self:TriggerCallback(cb, value)
end

function DFUI:SetTempDBNoCallback(mod, key, value)
    if not self.tempDB[mod] then
        self.tempDB[mod] = {}
    end
    self.tempDB[mod][key] = value
end

function DFUI:GetTempValue(name, key)
    if not self.tempDB[name] then
        return nil
    end

    return self.tempDB[name][key]
end

function DFUI:GetTempDB(mod, key)
    return self.tempDB[mod][key]
end

function DFUI:SaveTempDB()
    local char = UnitName("player")
    local cur = DFUI_CUR_PROFILE[char] or "Default"

    DFUI_PROFILES[cur] = self.tempDB
    DFUI_DB_SETUP.version = self.DBversion
end

function DFUI:ResetDB()
    self.tempDB = {}
    DFUI_PROFILES = {}
    DFUI_DB_SETUP = {}
    DFUI_CUR_PROFILE = {}
    DFUI_DB_SETUP.version = self.DBversion
    ReloadUI()
end

-- profiles
function DFUI:CreateProfile(name)
    DFUI_PROFILES[name] = {}
    for mod, def in pairs(self.defaults) do
        DFUI_PROFILES[name][mod] = {}
        for key, value in pairs(def) do
            DFUI_PROFILES[name][mod][key] = value[1]
        end
    end
end

function DFUI:SwitchProfile(name)
    local char = UnitName("player")
    local old = DFUI_CUR_PROFILE[char]
    DFUI_PROFILES[old] = self.tempDB
    DFUI_CUR_PROFILE[char] = name
    self:LoadProfile(name)
end

function DFUI:CopyProfile(from, tbl)
    local src
    if tbl then
        src = tbl
    else
        src = DFUI_PROFILES[from]
    end
    self.tempDB = {}
    for mod, data in pairs(src) do
        self.tempDB[mod] = {}
        for key, value in pairs(data) do
            self.tempDB[mod][key] = value
        end
    end
end

function DFUI:LoadProfile(name)
    self.tempDB = {}
    for mod, data in pairs(DFUI_PROFILES[name]) do
        self.tempDB[mod] = {}
        for key, value in pairs(data) do
            self.tempDB[mod][key] = value
        end
    end
end

function DFUI:DeleteProfile(name)
    DFUI_PROFILES[name] = nil
end

-- callbacks
function DFUI:NewCallbacks(mod, callbacks)
    local count = 0
    for key, func in pairs(callbacks) do
        local cb = mod .. "_" .. key .. "_changed"

        self.callbacks[cb] = {}
        tinsert(self.callbacks[cb], func)

        self:TriggerCallback(cb, self.tempDB[mod][key])

        count = count + 1
    end
end

function DFUI:TriggerCallback(cb, value)
    for _, func in ipairs(self.callbacks[cb]) do
        func(value)
    end
end

function DFUI:TriggerAllCallbacks()
    for cb, callbacks in pairs(self.callbacks) do
        local name = string.gsub(cb, "_changed$", "")
        local pos = string.find(name, "_[^_]*$")
        local mod = string.sub(name, 1, pos - 1)
        local key = string.sub(name, pos + 1)
        local value = self.tempDB[mod] and self.tempDB[mod][key]

        for _, func in ipairs(callbacks) do
            func(value)
        end
    end
end

-- init handler
DFUI:RegisterEvent("ADDON_LOADED")
DFUI:RegisterEvent("PLAYER_LOGOUT")
DFUI:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        DFUI:CheckAddon(arg1)
    end
    if event == "ADDON_LOADED" and arg1 == "Dragonflight-Fix" then
        if boot then return end
        boot = true

        -- migrate old saved variables to DFUI (one-time)
        -- only migrate when DFUI has no data; prefer DFF (newer) over DFRL (older)
        local function migrate(new, old)
            if old and next(old) and not next(new) then
                for k, v in pairs(old) do new[k] = v end
            end
        end
        migrate(DFUI_PROFILES, DFF_PROFILES or DFRL_PROFILES)
        migrate(DFUI_DB_SETUP, DFF_DB_SETUP or DFRL_DB_SETUP)
        migrate(DFUI_CUR_PROFILE, DFF_CUR_PROFILE or DFRL_CUR_PROFILE)
        migrate(DFUI_FRAMEPOS, DFF_FRAMEPOS or DFRL_FRAMEPOS)
        DFF_PROFILES = nil; DFF_DB_SETUP = nil; DFF_CUR_PROFILE = nil; DFF_FRAMEPOS = nil
        DFRL_PROFILES = nil; DFRL_DB_SETUP = nil; DFRL_CUR_PROFILE = nil; DFRL_FRAMEPOS = nil

        DFUI:InitTempDB()
        DFUI:RunMods()
        print("欢迎使用 |cffffd200Dragonflight:|r Fix。")
        print("Open menu via |cffddddddESC|r or |cffddddddSLASH DFUI|r.")
    end
    if event == "PLAYER_LOGOUT" then
        DFUI:SaveTempDB()
    end
end)
