DFRL:NewDefaults("Tooltip", {
    enabled = {true},
    toolTipMouse = {false, "checkbox", nil, nil, "功能调整", 1, "在光标上方显示提示信息", nil, nil},
    toolTipX = {0, "slider", {-400, 200, 15}, nil, "功能调整", 2, "调整提示信息的X偏移", nil, nil},
    toolTipY = {0, "slider", {-200, 200, 15}, nil, "功能调整", 3, "调整提示信息的Y偏移", nil, nil},
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

    -- execute  callbacks
    DFRL:NewCallbacks("Tooltip", callbacks)
end)
