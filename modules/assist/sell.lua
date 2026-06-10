----------------------------------------------------------------------
-- DFUI.Assist  --  商人自动卖灰
-- 移植 Automatonex Sell（v1 只卖灰色，不做忽略/总卖列表）。
-- 开商人 → 收集所有灰色物品入队；onUpdate 节流逐件卖出（Turtle 上
-- 快速连卖会掉线，必须保留间隔）；关商人 → 报本次售卖收入。
----------------------------------------------------------------------

local L = DFUI.Assist.L

local SELL_INTERVAL = 0.15
local GRAY_HEX = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[0] and ITEM_QUALITY_COLORS[0].hex or "|cff9d9d9d"

local queue = {}
local timer = 0
local startMoney = 0

local function moneyStr(c)
    local g = math.floor(c / 10000)
    local s = math.floor(math.mod(c, 10000) / 100)
    local cp = math.mod(c, 100)
    local out = ""
    if g > 0 then out = out .. g .. "|cffffd700金|r" end
    if g > 0 or s > 0 then out = out .. s .. "|cffc7c7cf银|r" end
    out = out .. cp .. "|cffeda55f铜|r"
    return out
end

DFUI.Assist:register({
    key = "autoSell",
    title = L["autoSell"],
    desc = L["autoSellDesc"],
    default = false,
    events = {
        MERCHANT_SHOW = function(self)
            queue = {}
            timer = 0
            startMoney = GetMoney()
            for bag = 0, 4 do
                local n = GetContainerNumSlots(bag)
                if n and n > 0 then
                    for slot = 1, n do
                        local link = GetContainerItemLink(bag, slot)
                        if link and string.find(link, GRAY_HEX, 1, true) then
                            table.insert(queue, { bag, slot })
                        end
                    end
                end
            end
        end,
        MERCHANT_CLOSED = function(self)
            queue = {}
            local now = GetMoney()
            if now > startMoney then
                DFUI.Assist.Print(L["sellIncome"] .. " " .. moneyStr(now - startMoney))
            end
        end,
    },
    onUpdate = function(self, elapsed)
        if table.getn(queue) == 0 then return end
        if not (MerchantFrame and MerchantFrame:IsVisible()) then
            queue = {}
            return
        end
        timer = timer + elapsed
        if timer < SELL_INTERVAL then return end
        timer = 0
        local n = table.getn(queue)
        local item = queue[n]
        table.remove(queue, n)
        if item then
            -- 商人界面下 UseContainerItem 即为卖出
            UseContainerItem(item[1], item[2])
        end
    end,
})
