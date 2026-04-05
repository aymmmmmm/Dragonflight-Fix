-- 档案序列化/反序列化
-- 用于跨账号导入/导出配置

-- 序列化单个值为字符串
local function SerializeValue(val)
    local t = type(val)
    if t == "boolean" then
        return val and "T" or "F"
    elseif t == "number" then
        -- 保留合理精度，去除尾部零
        local s = string.format("%.4f", val)
        s = string.gsub(s, "%.?0+$", "")
        return s
    elseif t == "string" then
        -- 转义特殊字符
        local escaped = string.gsub(val, "([\"\\~,;{}=])", "\\%1")
        return "\"" .. escaped .. "\""
    elseif t == "table" then
        -- 检测是否为数组（连续整数键从1开始）
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
            -- 数组: {v1;v2;v3}
            local parts = {}
            for i = 1, maxn do
                table.insert(parts, SerializeValue(val[i]))
            end
            return "{" .. table.concat(parts, ";") .. "}"
        else
            -- 字典: {k1=v1;k2=v2}（用于嵌套的 _FramePos 等）
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

-- 计算简单校验和
local function Checksum(str)
    local sum = 0
    for i = 1, string.len(str) do
        sum = sum + string.byte(str, i)
    end
    return math.mod(sum, 65536)
end

-- 序列化档案
-- profileName: 档案名，从 DFUI_PROFILES[name] 读取数据
-- 返回字符串
function DFUI:SerializeProfile(profileName)
    local profile = DFUI_PROFILES[profileName]
    if not profile then return nil end

    local modules = {}

    -- 收集模块名并排序，保证输出稳定
    local modNames = {}
    for mod in pairs(profile) do
        table.insert(modNames, mod)
    end
    table.sort(modNames)

    for _, mod in ipairs(modNames) do
        local data = profile[mod]
        if type(data) == "table" then
            local kvPairs = {}

            -- 收集键名并排序
            local keys = {}
            for k in pairs(data) do
                table.insert(keys, k)
            end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

            for _, key in ipairs(keys) do
                local val = data[key]
                table.insert(kvPairs, tostring(key) .. "=" .. SerializeValue(val))
            end

            table.insert(modules, mod .. ":" .. table.concat(kvPairs, ","))
        end
    end

    local body = table.concat(modules, "~")
    local checksum = Checksum(body)
    return "DFUI1#" .. checksum .. "~" .. body
end

-- 解析单个值字符串
local function DeserializeValue(str)
    if not str or str == "" or str == "nil" then
        return nil
    end

    -- 布尔
    if str == "T" then return true end
    if str == "F" then return false end

    -- 字符串（带引号）
    if string.sub(str, 1, 1) == "\"" and string.sub(str, -1) == "\"" then
        local inner = string.sub(str, 2, -2)
        -- 反转义
        inner = string.gsub(inner, "\\(.)", "%1")
        return inner
    end

    -- 数字
    local num = tonumber(str)
    if num then return num end

    -- 表 {v1;v2;v3} 或 {k1=v1;k2=v2}
    if string.sub(str, 1, 1) == "{" and string.sub(str, -1) == "}" then
        local inner = string.sub(str, 2, -2)
        if inner == "" then return {} end

        local result = {}
        local isDict = false

        -- 分割（需要处理嵌套大括号）
        local parts = {}
        local depth = 0
        local current = ""
        for i = 1, string.len(inner) do
            local c = string.sub(inner, i, i)
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

        -- 检查第一个元素是否包含 = 判断是数组还是字典
        if string.find(parts[1], "=") then
            isDict = true
        end

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
            for i, part in ipairs(parts) do
                result[i] = DeserializeValue(part)
            end
        end

        return result
    end

    -- 回退: 作为字符串返回
    return str
end

-- 在顶层分割模块段（处理嵌套大括号）
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
            -- 转义字符：追加反斜杠和下一个字符，跳过下一个字符
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

-- 反序列化档案字符串
-- 返回 table 或 nil, errorMessage
function DFUI:DeserializeProfile(str)
    if not str or str == "" then
        return nil, "空字符串"
    end

    -- 去除首尾空白和换行
    str = string.gsub(str, "^%s+", "")
    str = string.gsub(str, "%s+$", "")
    str = string.gsub(str, "\n", "")
    str = string.gsub(str, "\r", "")

    -- 兼容旧 | 格式：自动转换为 ~，修复 WoW |r 颜色码损坏
    local isLegacy = false
    if string.find(str, "|") and not string.find(str, "~") then
        str = string.gsub(str, "|", "~")
        -- 修复 |RangeIndicator 被 WoW 当作 |r 吃掉的损坏
        str = string.gsub(str, "angeIndicator:", "~RangeIndicator:")
        isLegacy = true
    end

    -- 检查头部
    if string.sub(str, 1, 5) ~= "DFUI1" then
        return nil, "无效格式：缺少 DFUI1 头部"
    end

    -- 解析校验和: DFUI1#checksum~body...
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

    -- 解析模块
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
