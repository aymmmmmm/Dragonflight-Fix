----------------------------------------------------------------------
-- DFUI.Assist  --  自动打开背包
-- 商人/邮箱/交易时开包，关闭对话后收回（仅收回我们打开的）。
-- 用 IsBagOpen + ToggleBag（确保态），避免 OpenAllBags 的 toggle 坑。
----------------------------------------------------------------------

local L = DFUI.Assist.L

local opened = {}   -- [bagIndex] = true 表示这次是我们打开的

local function openBags()
    for i = 0, 4 do
        if not IsBagOpen(i) then
            ToggleBag(i)
            opened[i] = true
        end
    end
end

local function closeBags()
    for i = 0, 4 do
        if opened[i] and IsBagOpen(i) then
            ToggleBag(i)
        end
        opened[i] = nil
    end
end

DFUI.Assist:register({
    key = "autoBag",
    title = L["autoBag"],
    desc = L["autoBagDesc"],
    default = true,
    events = {
        MERCHANT_SHOW   = function(self) openBags() end,
        MERCHANT_CLOSED = function(self) closeBags() end,
        MAIL_SHOW       = function(self) openBags() end,
        MAIL_CLOSED     = function(self) closeBags() end,
        TRADE_SHOW      = function(self) openBags() end,
        TRADE_CLOSED    = function(self) closeBags() end,
    },
})
