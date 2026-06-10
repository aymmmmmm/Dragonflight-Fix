----------------------------------------------------------------------
-- DFUI.Assist  --  自动 Roll（按物品品质分别设置）
-- START_LOOT_ROLL 的 arg1 = rollID，arg2 = 持续时间。部分服务器立即
-- roll 会失败，故入队列、延迟 ~0.3s 后再 RollOnLoot。
-- RollOnLoot(rollID, rollType)：0=放弃 / 1=需求 / 2=贪婪（与 DFUI
--   loot/roll.lua 一致）。
--
-- 每个品质独立模式（存 DFUI 档案 Assist 段）：
--   rollGray  灰白(quality<=1)  rollGreen 绿(2)  rollBlue 蓝(3)  rollEpic 紫橙(>=4)
--   模式值：0=放弃 / 1=需求 / 2=贪婪 / 3=不自动（跳过，留给玩家手点）
----------------------------------------------------------------------

local L = DFUI.Assist.L

local DELAY = 0.3
local pending = {}   -- { { id = rollID, t = GetTime(), roll = 0/1/2 }, ... }

-- 品质 -> 配置键
local function qualityKey(q)
    if q and q >= 4 then return "rollEpic" end
    if q == 3 then return "rollBlue" end
    if q == 2 then return "rollGreen" end
    return "rollGray"          -- 灰(0)/白(1) 及未知
end

-- 取某品质的模式（缺省贪婪）
local function modeForQuality(q)
    local m = DFUI:GetTempDB("Assist", qualityKey(q))
    if m == nil then m = 2 end
    return m
end

DFUI.Assist:register({
    key = "autoRoll",
    title = L["autoRoll"],
    desc = L["autoRollDesc"],
    default = false,
    events = {
        START_LOOT_ROLL = function(self)
            local id = arg1
            if not id then return end
            local _, _, _, quality = GetLootRollItemInfo(id)
            local m = modeForQuality(quality)
            if m == 3 then return end     -- 不自动：跳过，留给玩家
            table.insert(pending, { id = id, t = GetTime(), roll = m })
        end,
    },
    onUpdate = function(self, elapsed)
        if table.getn(pending) == 0 then return end
        local now = GetTime()
        local i = 1
        while i <= table.getn(pending) do
            local p = pending[i]
            if now - p.t >= DELAY then
                pcall(RollOnLoot, p.id, p.roll)
                table.remove(pending, i)
            else
                i = i + 1
            end
        end
    end,
})
