-- mainframe
DFRL = CreateFrame("Frame", nil, UIParent)

-- tables
DFRL_PROFILES = {}
DFRL_DB_SETUP = {}
DFRL_CUR_PROFILE = {}
DFRL_FRAMEPOS = {}

DFRL.env = {}
DFRL.tools = {}
DFRL.hooks = {}
DFRL.tempDB = {}
DFRL.modules = {}
DFRL.defaults = {}
DFRL.profiles = {}
DFRL.callbacks = {}
DFRL.performance = {}
DFRL.activeScripts = {}
DFRL.gui = {}

-- db version
DFRL.DBversion = "2.0"

-- boot flag
local boot = false

-- utility
function DFRL:GetInfoOrCons(type)
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

function DFRL:CheckAddon(name)
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
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100DFRL: |r".. tostring(msg))
end

-- 职业颜色工具：优先使用 DFRL.classColors，回退到 RAID_CLASS_COLORS
-- 返回 {r, g, b} 表或 nil
function DFRL:GetClassColor(class)
    if not class then return nil end
    local custom = self.classColors and self.classColors[class]
    if custom then return custom end
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        return RAID_CLASS_COLORS[class]
    end
    return nil
end

-- environment
function DFRL:GetEnv()
    self.env._G = getfenv(0)
    self.env.T = self.tools
    return self.env
end

setmetatable(DFRL.env, {__index = getfenv(0)})

-- modules
function DFRL:NewDefaults(mod, defaults)
    if not self.defaults[mod] then
        self.defaults[mod] = {}
    end

    for key, value in pairs(defaults) do
        self.defaults[mod][key] = value
    end
end

function DFRL:NewMod(name, prio, func)
    if self.modules[name] then return end
    self.modules[name] = {func = func, priority = prio}
end

function DFRL:RunMods()
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
function DFRL:InitTempDB()
    self:VersionCheckDB()

    -- set default profile if none exists
    local char = UnitName("player")

    if not DFRL_CUR_PROFILE[char] then
        DFRL_CUR_PROFILE[char] = "Default"
    end

    local cur = DFRL_CUR_PROFILE[char]

    -- ensure profile exists
    if not DFRL_PROFILES[cur] then
        DFRL_PROFILES[cur] = {}
    end

    -- copy existing module settings from current profile
    for mod, tbl in pairs(DFRL_PROFILES[cur]) do
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

function DFRL:VersionCheckDB()
    local oldVer = DFRL_DB_SETUP.version
    if oldVer == self.DBversion then return end

    -- 版本不匹配：合并新增默认值到现有数据，而非清空
    if oldVer and next(DFRL_PROFILES) then
        for profileName, profileData in pairs(DFRL_PROFILES) do
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
        DFRL_PROFILES = {}
        DFRL_CUR_PROFILE = {}
    end

    DFRL_DB_SETUP = {}
    DFRL_DB_SETUP.version = self.DBversion
end

function DFRL:SetTempDB(mod, key, value)
    self.tempDB[mod][key] = value
    local cb = mod .. "_" .. key .. "_changed"
    self:TriggerCallback(cb, value)
end

function DFRL:SetTempDBNoCallback(mod, key, value)
    if not self.tempDB[mod] then
        self.tempDB[mod] = {}
    end
    self.tempDB[mod][key] = value
end

function DFRL:GetTempValue(name, key)
    if not self.tempDB[name] then
        return nil
    end

    return self.tempDB[name][key]
end

function DFRL:GetTempDB(mod, key)
    return self.tempDB[mod][key]
end

function DFRL:SaveTempDB()
    local char = UnitName("player")
    local cur = DFRL_CUR_PROFILE[char] or "Default"

    DFRL_PROFILES[cur] = self.tempDB
    DFRL_DB_SETUP.version = self.DBversion
end

function DFRL:ResetDB()
    self.tempDB = {}
    DFRL_PROFILES = {}
    DFRL_DB_SETUP = {}
    DFRL_CUR_PROFILE = {}
    DFRL_DB_SETUP.version = self.DBversion
    ReloadUI()
end

-- profiles
function DFRL:CreateProfile(name)
    DFRL_PROFILES[name] = {}
    for mod, def in pairs(self.defaults) do
        DFRL_PROFILES[name][mod] = {}
        for key, value in pairs(def) do
            DFRL_PROFILES[name][mod][key] = value[1]
        end
    end
end

function DFRL:SwitchProfile(name)
    local char = UnitName("player")
    local old = DFRL_CUR_PROFILE[char]
    DFRL_PROFILES[old] = self.tempDB
    DFRL_CUR_PROFILE[char] = name
    self:LoadProfile(name)
end

function DFRL:CopyProfile(from, tbl)
    local src
    if tbl then
        src = tbl
    else
        src = DFRL_PROFILES[from]
    end
    self.tempDB = {}
    for mod, data in pairs(src) do
        self.tempDB[mod] = {}
        for key, value in pairs(data) do
            self.tempDB[mod][key] = value
        end
    end
end

function DFRL:LoadProfile(name)
    self.tempDB = {}
    for mod, data in pairs(DFRL_PROFILES[name]) do
        self.tempDB[mod] = {}
        for key, value in pairs(data) do
            self.tempDB[mod][key] = value
        end
    end
end

function DFRL:DeleteProfile(name)
    DFRL_PROFILES[name] = nil
end

-- callbacks
function DFRL:NewCallbacks(mod, callbacks)
    local count = 0
    for key, func in pairs(callbacks) do
        local cb = mod .. "_" .. key .. "_changed"

        self.callbacks[cb] = {}
        tinsert(self.callbacks[cb], func)

        self:TriggerCallback(cb, self.tempDB[mod][key])

        count = count + 1
    end
end

function DFRL:TriggerCallback(cb, value)
    for _, func in ipairs(self.callbacks[cb]) do
        func(value)
    end
end

function DFRL:TriggerAllCallbacks()
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
DFRL:RegisterEvent("ADDON_LOADED")
DFRL:RegisterEvent("PLAYER_LOGOUT")
DFRL:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        DFRL:CheckAddon(arg1)
    end
    if event == "ADDON_LOADED" and arg1 == "Dragonflight-Fix" then
        if boot then return end
        boot = true
        DFRL:InitTempDB()
        DFRL:RunMods()
        print("欢迎使用 |cffffd200Dragonflight:|r Fix。")
        print("Open menu via |cffddddddESC|r or |cffddddddSLASH DFRL|r.")
    end
    if event == "PLAYER_LOGOUT" then
        DFRL:SaveTempDB()
    end
end)
