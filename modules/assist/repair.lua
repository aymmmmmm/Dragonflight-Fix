----------------------------------------------------------------------
-- DFUI.Assist  --  商人自动修理
-- 移植 Automatonex Repair。可修理的商人处自动全修，聊天报花费；
-- 钱不够则提示。
----------------------------------------------------------------------

local L = DFUI.Assist.L

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
    key = "autoRepair",
    title = L["autoRepair"],
    desc = L["autoRepairDesc"],
    default = false,
    events = {
        MERCHANT_SHOW = function(self)
            if not CanMerchantRepair() then return end
            local cost, canRepair = GetRepairAllCost()
            if not canRepair or not cost or cost <= 0 then return end
            if GetMoney() < cost then
                DFUI.Assist.Print(L["repairNoMoney"])
                return
            end
            RepairAllItems()
            DFUI.Assist.Print(L["repairCost"] .. " " .. moneyStr(cost))
        end,
    },
})
