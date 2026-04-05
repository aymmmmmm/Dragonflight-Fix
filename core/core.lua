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

-- 同步所有档案的配置结构：合并新增项、清理废弃项、修正类型不匹配
-- 每次登录自动运行，幂等操作，无需手动改版本号
function DFUI:SyncProfiles()
    if not next(DFUI_PROFILES) then return 0, 0, 0 end

    local added, removed, fixed = 0, 0, 0

    for profileName, profileData in pairs(DFUI_PROFILES) do
        -- 1) 合并新增模块和新增配置项
        for mod, def in pairs(self.defaults) do
            if not profileData[mod] then
                profileData[mod] = {}
                added = added + 1
            end
            for key, val in pairs(def) do
                local defaultVal = val[1]
                local savedVal = profileData[mod][key]
                if savedVal == nil then
                    profileData[mod][key] = defaultVal
                    added = added + 1
                elseif defaultVal ~= nil and type(savedVal) ~= type(defaultVal) then
                    profileData[mod][key] = defaultVal
                    fixed = fixed + 1
                end
            end
        end

        -- 2) 清理已删除模块的残留数据
        local staleMods = {}
        for mod, _ in pairs(profileData) do
            if mod ~= "_FramePos" and not self.defaults[mod] then
                table.insert(staleMods, mod)
            end
        end
        for _, mod in ipairs(staleMods) do
            profileData[mod] = nil
            removed = removed + 1
        end

        -- 3) 清理已删除配置项的残留数据
        for mod, def in pairs(self.defaults) do
            if profileData[mod] then
                local staleKeys = {}
                for key, _ in pairs(profileData[mod]) do
                    if def[key] == nil then
                        table.insert(staleKeys, key)
                    end
                end
                for _, key in ipairs(staleKeys) do
                    profileData[mod][key] = nil
                    removed = removed + 1
                end
            end
        end
    end

    return added, removed, fixed
end

function DFUI:InitTempDB()
    -- 同步配置结构（自动检测变更，无需版本号）
    local added, removed, fixed = self:SyncProfiles()
    if added + removed + fixed > 0 then
        local msg = "|cff00ccff[DFUI]|r 配置已同步"
        if added > 0 then msg = msg .. "  |cff00ff00+" .. added .. " 新增|r" end
        if removed > 0 then msg = msg .. "  |cffff6600-" .. removed .. " 清理|r" end
        if fixed > 0 then msg = msg .. "  |cffffff00~" .. fixed .. " 修正|r" end
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end

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
        if mod == "_FramePos" then
            -- 恢复框架位置到 DFUI_FRAMEPOS
            DFUI_FRAMEPOS = {}
            for fname, pos in pairs(tbl) do
                DFUI_FRAMEPOS[fname] = {x = pos.x, y = pos.y}
            end
        elseif type(tbl) == "table" then
            self.tempDB[mod] = self.tempDB[mod] or {}
            for key, value in pairs(tbl) do
                self.tempDB[mod][key] = value
            end
        end
    end

    -- add missing defaults to tempDB
    for mod, def in pairs(self.defaults) do
        self.tempDB[mod] = self.tempDB[mod] or {}
        for key, val in pairs(def) do
            if self.tempDB[mod][key] == nil then
                self.tempDB[mod][key] = val[1]
            end
        end
    end
end

function DFUI:SetTempDB(mod, key, value)
    if not self.tempDB[mod] then
        self.tempDB[mod] = {}
    end
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
    if not self.tempDB[mod] then return nil end
    return self.tempDB[mod][key]
end

function DFUI:SaveTempDB()
    local char = UnitName("player")
    local cur = DFUI_CUR_PROFILE[char] or "Default"

    DFUI_PROFILES[cur] = self.tempDB

    -- 将框架位置嵌入档案
    if DFUI_FRAMEPOS and next(DFUI_FRAMEPOS) then
        DFUI_PROFILES[cur]["_FramePos"] = {}
        for name, pos in pairs(DFUI_FRAMEPOS) do
            DFUI_PROFILES[cur]["_FramePos"][name] = {x = pos.x, y = pos.y}
        end
    end

end

function DFUI:ResetDB()
    self.tempDB = {}
    DFUI_PROFILES = {}
    DFUI_DB_SETUP = {}
    DFUI_CUR_PROFILE = {}
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
    -- 恢复框架位置
    if self.RestoreFramePositions then
        self:RestoreFramePositions()
    end
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
        if mod == "_FramePos" then
            DFUI_FRAMEPOS = {}
            for fname, pos in pairs(data) do
                DFUI_FRAMEPOS[fname] = {x = pos.x, y = pos.y}
            end
        else
            self.tempDB[mod] = {}
            for key, value in pairs(data) do
                self.tempDB[mod][key] = value
            end
        end
    end
end

function DFUI:LoadProfile(name)
    self.tempDB = {}
    for mod, data in pairs(DFUI_PROFILES[name]) do
        if mod == "_FramePos" then
            -- 恢复框架位置
            DFUI_FRAMEPOS = {}
            for fname, pos in pairs(data) do
                DFUI_FRAMEPOS[fname] = {x = pos.x, y = pos.y}
            end
        else
            self.tempDB[mod] = {}
            for key, value in pairs(data) do
                self.tempDB[mod][key] = value
            end
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

        self:TriggerCallback(cb, self.tempDB[mod] and self.tempDB[mod][key])

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

-- 档案序列化/反序列化（用于跨账号导入/导出配置）
do
    local function SerializeValue(val)
        local t = type(val)
        if t == "boolean" then
            return val and "T" or "F"
        elseif t == "number" then
            local s = string.format("%.4f", val)
            s = string.gsub(s, "%.?0+$", "")
            return s
        elseif t == "string" then
            local escaped = string.gsub(val, "([\"\\~,;{}=])", "\\%1")
            return "\"" .. escaped .. "\""
        elseif t == "table" then
            local isArray = true
            local maxn = 0
            for k, _ in pairs(val) do
                if type(k) == "number" and k == math.floor(k) and k > 0 then
                    if k > maxn then maxn = k end
                else
                    isArray = false
                    break
                end
            end
            if isArray and maxn > 0 then
                local parts = {}
                for i = 1, maxn do
                    table.insert(parts, SerializeValue(val[i]))
                end
                return "{" .. table.concat(parts, ";") .. "}"
            else
                local parts = {}
                for k, v in pairs(val) do
                    table.insert(parts, tostring(k) .. "=" .. SerializeValue(v))
                end
                table.sort(parts)
                return "{" .. table.concat(parts, ";") .. "}"
            end
        end
        return "nil"
    end

    local function Checksum(str)
        local sum = 0
        for i = 1, string.len(str) do
            sum = sum + string.byte(str, i)
        end
        return math.mod(sum, 65536)
    end

    local function SplitTopLevel(str, sep)
        local parts = {}
        local depth = 0
        local inQuote = false
        local current = ""
        local len = string.len(str)
        local i = 1
        while i <= len do
            local c = string.sub(str, i, i)
            if c == "\\" and inQuote then
                current = current .. c
                if i < len then
                    i = i + 1
                    current = current .. string.sub(str, i, i)
                end
            elseif c == "\"" then
                inQuote = not inQuote
                current = current .. c
            elseif not inQuote then
                if c == "{" then
                    depth = depth + 1
                    current = current .. c
                elseif c == "}" then
                    depth = depth - 1
                    current = current .. c
                elseif c == sep and depth == 0 then
                    table.insert(parts, current)
                    current = ""
                else
                    current = current .. c
                end
            else
                current = current .. c
            end
            i = i + 1
        end
        if current ~= "" then
            table.insert(parts, current)
        end
        return parts
    end

    local function DeserializeValue(str)
        if not str or str == "" or str == "nil" then return nil end
        if str == "T" then return true end
        if str == "F" then return false end
        if string.sub(str, 1, 1) == "\"" and string.sub(str, -1) == "\"" then
            local inner = string.sub(str, 2, -2)
            inner = string.gsub(inner, "\\(.)", "%1")
            return inner
        end
        local num = tonumber(str)
        if num then return num end
        if string.sub(str, 1, 1) == "{" and string.sub(str, -1) == "}" then
            local inner = string.sub(str, 2, -2)
            if inner == "" then return {} end
            local result = {}
            local parts = {}
            local depth = 0
            local current = ""
            for ci = 1, string.len(inner) do
                local c = string.sub(inner, ci, ci)
                if c == "{" then
                    depth = depth + 1
                    current = current .. c
                elseif c == "}" then
                    depth = depth - 1
                    current = current .. c
                elseif c == ";" and depth == 0 then
                    table.insert(parts, current)
                    current = ""
                else
                    current = current .. c
                end
            end
            if current ~= "" then
                table.insert(parts, current)
            end
            local isDict = string.find(parts[1], "=")
            if isDict then
                for _, part in ipairs(parts) do
                    local eqPos = string.find(part, "=")
                    if eqPos then
                        local k = string.sub(part, 1, eqPos - 1)
                        local v = string.sub(part, eqPos + 1)
                        result[k] = DeserializeValue(v)
                    end
                end
            else
                for idx, part in ipairs(parts) do
                    result[idx] = DeserializeValue(part)
                end
            end
            return result
        end
        return str
    end

    function DFUI:SerializeProfile(profileName)
        local profile = DFUI_PROFILES[profileName]
        if not profile then return nil end
        local modules = {}
        local modNames = {}
        for mod in pairs(profile) do
            table.insert(modNames, mod)
        end
        table.sort(modNames)
        for _, mod in ipairs(modNames) do
            local data = profile[mod]
            if type(data) == "table" then
                local kvPairs = {}
                local keys = {}
                for k in pairs(data) do
                    table.insert(keys, k)
                end
                table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
                for _, key in ipairs(keys) do
                    table.insert(kvPairs, tostring(key) .. "=" .. SerializeValue(data[key]))
                end
                table.insert(modules, mod .. ":" .. table.concat(kvPairs, ","))
            end
        end
        local body = table.concat(modules, "~")
        local checksum = Checksum(body)
        return "DFUI1#" .. checksum .. "~" .. body
    end

    function DFUI:DeserializeProfile(str)
        if not str or str == "" then
            return nil, "空字符串"
        end
        str = string.gsub(str, "^%s+", "")
        str = string.gsub(str, "%s+$", "")
        str = string.gsub(str, "\n", "")
        str = string.gsub(str, "\r", "")
        -- 兼容旧 | 格式
        local isLegacy = false
        if string.find(str, "|") and not string.find(str, "~") then
            str = string.gsub(str, "|", "~")
            str = string.gsub(str, "angeIndicator:", "~RangeIndicator:")
            isLegacy = true
        end
        if string.sub(str, 1, 5) ~= "DFUI1" then
            return nil, "无效格式：缺少 DFUI1 头部"
        end
        local hashPos = string.find(str, "#")
        if not hashPos then
            return nil, "无效格式：缺少校验和"
        end
        local afterHash = string.sub(str, hashPos + 1)
        local firstTilde = string.find(afterHash, "~")
        if not firstTilde then
            return nil, "无效格式：缺少数据"
        end
        local checksumStr = string.sub(afterHash, 1, firstTilde - 1)
        local body = string.sub(afterHash, firstTilde + 1)
        local expectedChecksum = tonumber(checksumStr)
        if not expectedChecksum then
            return nil, "无效校验和"
        end
        local actualChecksum = Checksum(body)
        if not isLegacy and actualChecksum ~= expectedChecksum then
            return nil, "校验和不匹配（数据可能被截断或损坏）"
        end
        local result = {}
        local moduleParts = SplitTopLevel(body, "~")
        for _, modStr in ipairs(moduleParts) do
            local colonPos = string.find(modStr, ":")
            if colonPos then
                local modName = string.sub(modStr, 1, colonPos - 1)
                local kvStr = string.sub(modStr, colonPos + 1)
                result[modName] = {}
                local kvParts = SplitTopLevel(kvStr, ",")
                for _, kv in ipairs(kvParts) do
                    local eqPos = string.find(kv, "=")
                    if eqPos then
                        local key = string.sub(kv, 1, eqPos - 1)
                        local valStr = string.sub(kv, eqPos + 1)
                        result[modName][key] = DeserializeValue(valStr)
                    end
                end
            end
        end
        return result
    end
end

-- init handler
DFUI:RegisterEvent("ADDON_LOADED")
DFUI:RegisterEvent("PLAYER_LOGOUT")
DFUI:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        DFUI:CheckAddon(arg1)
    end
    if event == "ADDON_LOADED" and string.lower(arg1) == "dragonflight-fix" then
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

        -- Detect addons that loaded before us (alphabetically earlier)
        for _, name in ipairs({"Bagshui", "ShaguTweaks", "ShaguTweaks-extras"}) do
            if IsAddOnLoaded(name) then DFUI:CheckAddon(name) end
        end

        DFUI:InitTempDB()
        DFUI:RunMods()
        print("欢迎使用 |cffffd200Dragonflight:|r Fix。")
        print("Open menu via |cffddddddESC|r or |cffddddddSLASH DFUI|r.")
    end
    if event == "PLAYER_LOGOUT" then
        DFUI:SaveTempDB()
    end
end)
