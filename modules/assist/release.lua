----------------------------------------------------------------------
-- DFUI.Assist  --  自动释放灵魂（回尸）
-- 默认关闭。死亡后延迟回尸，给“被复活”留窗口；已被复活则不回尸。
-- 硬核角色请勿开启。
----------------------------------------------------------------------

local L = DFUI.Assist.L

local DELAY = 2.0
local pendingAt = nil

DFUI.Assist:register({
    key = "autoRelease",
    title = L["autoRelease"],
    desc = L["autoReleaseDesc"],
    default = false,
    events = {
        PLAYER_DEAD = function(self)
            pendingAt = GetTime()
        end,
    },
    onUpdate = function(self, elapsed)
        if not pendingAt then return end
        if GetTime() - pendingAt < DELAY then return end
        pendingAt = nil
        -- 死亡且尚未变成鬼魂才回尸；被复活则 UnitIsDeadOrGhost 为 false
        if UnitIsDeadOrGhost("player") and not UnitIsGhost("player") then
            RepopMe()
        end
    end,
})
