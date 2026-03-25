DFRL:NewDefaults("Tooltip", {
    enabled = {true},
    toolTipMouse = {false, "checkbox", nil, nil, "功能调整", 1, "在光标上方显示提示信息", nil, nil},
    toolTipX = {0, "slider", {-400, 200, 15}, nil, "功能调整", 2, "调整提示信息的X偏移", nil, nil},
    toolTipY = {0, "slider", {-200, 200, 15}, nil, "功能调整", 3, "调整提示信息的Y偏移", nil, nil},
    showTargetTarget = {true, "checkbox", nil, nil, "增强信息", 1, "显示目标的目标", nil, nil},
    showDistance = {true, "checkbox", nil, nil, "增强信息", 2, "显示距离(需要UnitXP)", nil, nil},
})

DFRL:NewMod("Tooltip", 1, function()
    local Setup = {
        xOffset = 0,
        yOffset = 0
    }

    -- callbacks
    local callbacks = {}

    callbacks.toolTipMouse = function(value)
        if value then
            GameTooltip:SetScript("OnUpdate", function()
                if GameTooltip:IsShown() then
                    local x, y = GetCursorPosition()
                    local scale = GameTooltip:GetEffectiveScale()
                    GameTooltip:ClearAllPoints()
                    GameTooltip:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", (x / scale) + Setup.xOffset, (y / scale) + Setup.yOffset)
                end
            end)
        else
            GameTooltip:SetScript("OnUpdate", nil)
        end
    end

    callbacks.toolTipX = function(value)
        Setup.xOffset = value
    end

    callbacks.toolTipY = function(value)
        Setup.yOffset = value
    end

    -- Hook default anchor to support X/Y offset without mouse follow
    local origSetDefaultAnchor = _G.GameTooltip_SetDefaultAnchor
    _G.GameTooltip_SetDefaultAnchor = function(tooltip, parent)
        origSetDefaultAnchor(tooltip, parent)
        if not DFRL:GetTempDB("Tooltip", "toolTipMouse") then
            local point, relativeTo, relativePoint, x, y = tooltip:GetPoint()
            if point then
                tooltip:SetPoint(point, relativeTo, relativePoint, x + Setup.xOffset, y + Setup.yOffset)
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- 增强信息：目标的目标、距离显示
    -- ═══════════════════════════════════════════════════════════════

    local setup = DFRL.tempDB.Tooltip
    local hasUnitXP = (UnitXP ~= nil)

    -- 职业颜色辅助
    local function GetClassColorHex(unit)
        if not UnitIsPlayer(unit) then return 'ffffff' end
        local _, class = UnitClass(unit)
        local c = DFRL:GetClassColor(class)
        if c then
            return string.format('%02x%02x%02x', c.r * 255, c.g * 255, c.b * 255)
        end
        return 'ffffff'
    end

    -- Hook GameTooltip 的 OnTooltipSetUnit 来追加信息
    local origOnShow = GameTooltip:GetScript('OnShow')
    GameTooltip:SetScript('OnShow', function()
        if origOnShow then origOnShow() end

        -- 获取当前 Tooltip 对应的单位
        local _, unit = GameTooltip:GetUnit()
        if not unit then return end

        -- 显示目标的目标
        if setup.showTargetTarget and UnitExists(unit .. 'target') then
            local targetName = UnitName(unit .. 'target')
            if targetName then
                local hex = GetClassColorHex(unit .. 'target')
                GameTooltip:AddLine('目标: |cff' .. hex .. targetName .. '|r', 0.8, 0.8, 0.8)
            end
        end

        -- 显示距离（需要 UnitXP 扩展）
        if hasUnitXP and setup.showDistance and unit ~= 'player' then
            local dist = UnitXP('distanceBetween', 'player', unit)
            if dist and type(dist) == 'number' then
                GameTooltip:AddLine(string.format('距离: %.1f 码', dist), 0.6, 0.8, 1.0)
            end
        end

        GameTooltip:Show()
    end)

    callbacks.showTargetTarget = function() end
    callbacks.showDistance = function() end

    -- execute callbacks
    DFRL:NewCallbacks("Tooltip", callbacks)
end)
