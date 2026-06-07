----------------------------------------------------------------------
-- DFUI.Assist  --  自动 Roll（简化版）
-- START_LOOT_ROLL 的 arg1 = rollID。部分服务器立即 roll 会失败，
-- 故入队列、延迟 ~0.3s 后再 RollOnLoot。
-- 模式存 DFUI.Assist.db.rollMode： 0=放弃 / 1=需求 / 2=贪婪（默认贪婪）。
----------------------------------------------------------------------

local L = DFUI.Assist.L

local DELAY = 0.3
local pending = {}   -- { { id=rollID, t=GetTime() }, ... }

DFUI.Assist:register({
    key = "autoRoll",
    title = L["autoRoll"],
    desc = L["autoRollDesc"],
    default = false,
    events = {
        START_LOOT_ROLL = function(self)
            if arg1 then
                table.insert(pending, { id = arg1, t = GetTime() })
            end
        end,
    },
    onUpdate = function(self, elapsed)
        if table.getn(pending) == 0 then return end
        local now = GetTime()
        local mode = (DFUI.Assist.db and DFUI.Assist.db.rollMode) or 2
        local i = 1
        while i <= table.getn(pending) do
            local p = pending[i]
            if now - p.t >= DELAY then
                -- RollOnLoot(rollID, rollType): 0=pass 1=need 2=greed
                pcall(RollOnLoot, p.id, mode)
                table.remove(pending, i)
            else
                i = i + 1
            end
        end
    end,
})
