-- ═══════════════════════════════════════════════════════════════
-- 职业配色方案模块
-- 提供 Vanilla / TBC / Dragonflight 三套职业颜色预设
-- 通过 DFUI.classColors / DFUI.powerColors 全局表供其他模块引用
-- ═══════════════════════════════════════════════════════════════

DFUI:NewDefaults("Colors", {
    enabled = {true},
    -- 配色方案选择
    colorScheme = {"Dragonflight", "dropdown", {"Vanilla", "TBC", "Dragonflight"}, nil, "配色方案", 1, "职业颜色预设", nil, nil},
    -- 职业颜色
    colorWarrior = {{0.78, 0.61, 0.43}, "colour", nil, nil, "职业颜色", 1, "战士", nil, nil},
    colorMage = {{0.25, 0.78, 0.92}, "colour", nil, nil, "职业颜色", 2, "法师", nil, nil},
    colorRogue = {{1, 0.96, 0.41}, "colour", nil, nil, "职业颜色", 3, "盗贼", nil, nil},
    colorDruid = {{1, 0.49, 0.04}, "colour", nil, nil, "职业颜色", 4, "德鲁伊", nil, nil},
    colorHunter = {{0.67, 0.83, 0.45}, "colour", nil, nil, "职业颜色", 5, "猎人", nil, nil},
    colorShaman = {{0.14, 0.35, 1.0}, "colour", nil, nil, "职业颜色", 6, "萨满", nil, nil},
    colorPriest = {{1, 1, 1}, "colour", nil, nil, "职业颜色", 7, "牧师", nil, nil},
    colorWarlock = {{0.53, 0.53, 0.93}, "colour", nil, nil, "职业颜色", 8, "术士", nil, nil},
    colorPaladin = {{0.96, 0.55, 0.73}, "colour", nil, nil, "职业颜色", 9, "圣骑士", nil, nil},
    -- 能量颜色
    colorMana = {{0.2, 0.4, 1}, "colour", nil, nil, "能量颜色", 1, "法力", nil, nil},
    colorRage = {{1, 0, 0}, "colour", nil, nil, "能量颜色", 2, "怒气", nil, nil},
    colorFocus = {{1, 0.5, 0.25}, "colour", nil, nil, "能量颜色", 3, "集中", nil, nil},
    colorEnergy = {{1, 1, 0}, "colour", nil, nil, "能量颜色", 4, "能量", nil, nil},
})

DFUI:NewMod("Colors", 1, function()
    local setup = DFUI.tempDB.Colors

    -- 初始化全局颜色表
    DFUI.classColors = DFUI.classColors or {}
    DFUI.powerColors = DFUI.powerColors or {}

    -- 配色方案预设数据
    local colorSchemes = {
        ['Vanilla'] = {
            colorWarrior  = {0.78, 0.61, 0.43},
            colorMage     = {0.41, 0.8, 0.94},
            colorRogue    = {1, 0.96, 0.41},
            colorDruid    = {1, 0.49, 0.04},
            colorHunter   = {0.67, 0.83, 0.45},
            colorShaman   = {0.96, 0.55, 0.73},  -- 与圣骑士相同
            colorPriest   = {1, 1, 1},
            colorWarlock  = {0.58, 0.51, 0.79},
            colorPaladin  = {0.96, 0.55, 0.73},
        },
        ['TBC'] = {
            colorWarrior  = {0.78, 0.61, 0.43},
            colorMage     = {0.41, 0.8, 0.94},
            colorRogue    = {1, 0.96, 0.41},
            colorDruid    = {1, 0.49, 0.04},
            colorHunter   = {0.67, 0.83, 0.45},
            colorShaman   = {0.0, 0.44, 0.87},
            colorPriest   = {1, 1, 1},
            colorWarlock  = {0.58, 0.51, 0.79},
            colorPaladin  = {0.96, 0.55, 0.73},
        },
        ['Dragonflight'] = {
            colorWarrior  = {0.78, 0.61, 0.43},
            colorMage     = {0.25, 0.78, 0.92},
            colorRogue    = {1, 0.96, 0.41},
            colorDruid    = {1, 0.49, 0.04},
            colorHunter   = {0.67, 0.83, 0.45},
            colorShaman   = {0.14, 0.35, 1.0},
            colorPriest   = {1, 1, 1},
            colorWarlock  = {0.53, 0.53, 0.93},
            colorPaladin  = {0.96, 0.55, 0.73},
        },
    }

    -- 配置键 → 职业 token 映射
    local keyToClass = {
        colorWarrior = 'WARRIOR', colorMage = 'MAGE', colorRogue = 'ROGUE',
        colorDruid = 'DRUID', colorHunter = 'HUNTER', colorShaman = 'SHAMAN',
        colorPriest = 'PRIEST', colorWarlock = 'WARLOCK', colorPaladin = 'PALADIN',
    }

    -- 从当前配置加载颜色到全局表
    local function LoadClassColors()
        for key, className in pairs(keyToClass) do
            local color = setup[key]
            if color then
                DFUI.classColors[className] = {r = color[1], g = color[2], b = color[3]}
            end
        end
    end

    local function LoadPowerColors()
        DFUI.powerColors[0] = setup.colorMana    -- 法力
        DFUI.powerColors[1] = setup.colorRage    -- 怒气
        DFUI.powerColors[2] = setup.colorFocus   -- 集中
        DFUI.powerColors[3] = setup.colorEnergy  -- 能量
    end

    -- 通知单位框架刷新颜色（通过 DFUI 回调系统）
    local function NotifyColorChange()
        DFUI:TriggerCallback("Colors_colorRefresh_changed", true)
    end

    -- 初始加载
    LoadClassColors()
    LoadPowerColors()

    -- 回调定义
    local callbacks = {}

    -- 配色方案切换：批量更新所有职业颜色
    callbacks.colorScheme = function(value)
        local scheme = colorSchemes[value]
        if not scheme then return end
        for key, color in pairs(scheme) do
            DFUI:SetTempDBNoCallback("Colors", key, color)
            local className = keyToClass[key]
            if className then
                DFUI.classColors[className] = {r = color[1], g = color[2], b = color[3]}
            end
        end
        NotifyColorChange()
    end

    -- 各职业颜色单独修改的回调
    -- Lua 5.0 (WoW 1.12) for-in 循环里所有 closure 共享同一个 upvalue slot；
    -- 用本地变量保证每个 closure 捕获到自己的 className。
    for key, className in pairs(keyToClass) do
        local _cn = className
        callbacks[key] = function(value)
            if not _cn or type(value) ~= "table" then return end
            DFUI.classColors[_cn] = {r = value[1], g = value[2], b = value[3]}
            NotifyColorChange()
        end
    end

    -- 能量颜色回调
    callbacks.colorMana = function(value) DFUI.powerColors[0] = value NotifyColorChange() end
    callbacks.colorRage = function(value) DFUI.powerColors[1] = value NotifyColorChange() end
    callbacks.colorFocus = function(value) DFUI.powerColors[2] = value NotifyColorChange() end
    callbacks.colorEnergy = function(value) DFUI.powerColors[3] = value NotifyColorChange() end

    DFUI:NewCallbacks("Colors", callbacks)
end)
