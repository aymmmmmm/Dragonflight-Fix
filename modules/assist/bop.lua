----------------------------------------------------------------------
-- DFUI.Assist  --  自动确认绑定拾取（BoP）
-- LOOT_BIND_CONFIRM 的 arg1 = 战利品槽位。
----------------------------------------------------------------------

local L = DFUI.Assist.L

DFUI.Assist:register({
    key = "autoBoP",
    title = L["autoBoP"],
    desc = L["autoBoPDesc"],
    default = true,
    events = {
        LOOT_BIND_CONFIRM = function(self)
            local slot = arg1
            if slot then
                -- 1.12 无 ConfirmLootSlot(TBC+ API)：再次 LootSlot 即确认（同 loot.lua HandleBindConfirm）
                if ConfirmLootSlot then
                    ConfirmLootSlot(slot)
                else
                    LootSlot(slot)
                end
            end
            if StaticPopup_Hide then
                StaticPopup_Hide("LOOT_BIND")
            end
        end,
    },
})
