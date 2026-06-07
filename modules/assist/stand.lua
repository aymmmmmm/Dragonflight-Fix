----------------------------------------------------------------------
-- DFUI.Assist  --  自动站立
-- 操作因坐下而失败时自动起身。DoEmote("stand") 已站立时调用无副作用。
----------------------------------------------------------------------

local L = DFUI.Assist.L

-- 已知“需要站立”错误常量（运行时取值，缺失则忽略）
local standErrors = {}
local function add(s) if s and s ~= "" then standErrors[s] = true end end
add(SPELL_FAILED_NOT_STANDING)
add(ERR_CANTATTACK_NOTSTANDING)
add(ERR_LOOT_NOTSTANDING)

local function needStand(msg)
    if not msg then return false end
    if standErrors[msg] then return true end
    local lower = string.lower(msg)
    if string.find(lower, "sitting") or string.find(lower, "seated")
        or string.find(lower, "standing")
        or string.find(msg, "站立") or string.find(msg, "坐下") then
        return true
    end
    return false
end

DFUI.Assist:register({
    key = "autoStand",
    title = L["autoStand"],
    desc = L["autoStandDesc"],
    default = true,
    events = {
        UI_ERROR_MESSAGE = function(self)
            if needStand(arg1) then
                if UIErrorsFrame then UIErrorsFrame:Clear() end
                DoEmote("stand")
            end
        end,
    },
})
