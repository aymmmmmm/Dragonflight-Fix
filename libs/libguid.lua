-- ═══════════════════════════════════════════════════════════════
-- libguid - GUID 追踪系统 (DFUI 移植版)
-- 为 WoW 1.12.1 提供伪 GUID 生成与追踪功能
-- 在 Turtle WoW 有 SuperWoW 时优先使用原生 UnitGUID
-- ═══════════════════════════════════════════════════════════════

local libguid = CreateFrame('Frame', 'DFUI_LibGUIDFrame', UIParent)

-- 正向映射: GUID -> 单位信息 { unit, name, level, class, subzone, time }
libguid.guidMap = {}
-- 反向映射: unit token -> GUID（仅维护最近的映射）
libguid.reverseMap = {}

-- GUID 有效期（秒），超过此时间的映射视为过期
local GUID_EXPIRY = 120
-- 清理定时器间隔（秒）
local CLEANUP_INTERVAL = 30
-- 清理计时器
local cleanupTimer = 0

-- 自增 ID，用于在同名同级单位间区分
local guidCounter = 0

-- 是否有原生 GUID 支持（Turtle WoW + SuperWoW）
local hasNativeGUID = false

-- ═══════════════════════════════════════════════════════════════
-- 初始化: 检测原生 GUID 能力
-- ═══════════════════════════════════════════════════════════════

local function DetectNativeGUID()
    -- Turtle WoW 服务器且有 SuperWoW 时可使用原生 UnitGUID
    local realmName = GetRealmName() or ''
    local isTurtle = string.find(string.lower(realmName), 'turtle')
    if isTurtle and type(UnitGUID) == 'function' then
        hasNativeGUID = true
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 伪 GUID 生成
-- 基于 名称 + 等级 + 职业 + 子区域 + 自增ID 生成唯一标识
-- 格式: "pGUID-名称-等级-职业-区域-计数器"
-- ═══════════════════════════════════════════════════════════════

local function GeneratePseudoGUID(unit)
    local name = UnitName(unit)
    if not name then return nil end

    local level = UnitLevel(unit) or 0
    local _, class = UnitClass(unit)
    class = class or 'UNKNOWN'
    local subzone = GetSubZoneText() or 'unknown'

    guidCounter = guidCounter + 1

    return 'pGUID-' .. name .. '-' .. level .. '-' .. class .. '-' .. subzone .. '-' .. guidCounter
end

-- ═══════════════════════════════════════════════════════════════
-- 核心映射维护
-- ═══════════════════════════════════════════════════════════════

-- 为指定单位创建或更新 GUID 映射
local function UpdateMapping(unit)
    if not UnitExists(unit) then return nil end

    local guid = nil

    if hasNativeGUID then
        guid = UnitGUID(unit)
    end

    if not guid then
        -- 降级: 生成伪 GUID
        local existingGUID = libguid.reverseMap[unit]
        if existingGUID and libguid.guidMap[existingGUID] then
            local existing = libguid.guidMap[existingGUID]
            local name = UnitName(unit)
            local level = UnitLevel(unit)
            -- 如果名称和等级匹配，复用现有 GUID
            if existing.name == name and existing.level == level then
                existing.time = GetTime()
                return existingGUID
            end
        end
        guid = GeneratePseudoGUID(unit)
    end

    if not guid then return nil end

    -- 存储正向映射
    local _, unitClass = UnitClass(unit)
    libguid.guidMap[guid] = {
        unit = unit,
        name = UnitName(unit),
        level = UnitLevel(unit) or 0,
        class = unitClass or 'UNKNOWN',
        subzone = GetSubZoneText() or 'unknown',
        time = GetTime(),
    }

    -- 存储反向映射
    libguid.reverseMap[unit] = guid

    return guid
end

-- 清理过期的 GUID 映射条目
local function CleanStaleEntries()
    local now = GetTime()
    local staleGuids = {}

    for guid, data in pairs(libguid.guidMap) do
        if now - data.time > GUID_EXPIRY then
            table.insert(staleGuids, guid)
        end
    end

    for i = 1, table.getn(staleGuids) do
        local guid = staleGuids[i]
        local data = libguid.guidMap[guid]
        if data and libguid.reverseMap[data.unit] == guid then
            libguid.reverseMap[data.unit] = nil
        end
        libguid.guidMap[guid] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 事件处理: 在目标切换和鼠标悬停时刷新映射
-- ═══════════════════════════════════════════════════════════════

libguid:RegisterEvent('PLAYER_TARGET_CHANGED')
libguid:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
libguid:RegisterEvent('PLAYER_ENTERING_WORLD')

libguid:SetScript('OnEvent', function()
    if event == 'PLAYER_ENTERING_WORLD' then
        DetectNativeGUID()
        return
    end

    if event == 'PLAYER_TARGET_CHANGED' then
        if UnitExists('target') then
            UpdateMapping('target')
        end
        return
    end

    if event == 'UPDATE_MOUSEOVER_UNIT' then
        if UnitExists('mouseover') then
            UpdateMapping('mouseover')
        end
        return
    end
end)

-- 定时清理: 每 30 秒清理一次过期映射
libguid:SetScript('OnUpdate', function()
    cleanupTimer = cleanupTimer + arg1
    if cleanupTimer >= CLEANUP_INTERVAL then
        cleanupTimer = 0
        CleanStaleEntries()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- 公共 API
-- ═══════════════════════════════════════════════════════════════

-- 获取指定单位的 GUID（如无则创建）
function libguid:GetGUID(unit)
    if not unit or not UnitExists(unit) then
        return nil
    end

    if hasNativeGUID then
        return UnitGUID(unit)
    end

    local existingGUID = self.reverseMap[unit]
    if existingGUID and self.guidMap[existingGUID] then
        local data = self.guidMap[existingGUID]
        local name = UnitName(unit)
        local level = UnitLevel(unit)
        if data.name == name and data.level == level then
            data.time = GetTime()
            return existingGUID
        end
    end

    return UpdateMapping(unit)
end

-- 根据 GUID 反查单位 token
function libguid:GetUnitByGUID(guid)
    if not guid then return nil end
    local data = self.guidMap[guid]
    if not data then return nil end
    return data.unit
end

-- 检查 GUID 是否仍然有效
function libguid:IsValidGUID(guid)
    if not guid then return false end
    local data = self.guidMap[guid]
    if not data then return false end
    if GetTime() - data.time > GUID_EXPIRY then return false end
    local unit = data.unit
    if not UnitExists(unit) then return false end
    if UnitName(unit) ~= data.name then return false end
    return true
end

-- 注册到 DFUI 库命名空间
DFUI_Libs = DFUI_Libs or {}
DFUI_Libs.libguid = libguid
