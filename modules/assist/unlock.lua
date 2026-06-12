----------------------------------------------------------------------
-- DFUI.Assist  --  盗贼右键开锁
-- 移植 Automatonex Unlock（仅保留右键开锁，不做 TradeFrame 按钮）。
-- 盗贼右键背包中的锁定物品 → 自动施放“开锁”并作用到该物品。
--
-- 已知限制：Bagshui 接管默认背包后 ContainerFrameItemButton_OnClick
-- 可能不触发，届时仅默认背包可用（游戏内验证）。
----------------------------------------------------------------------

setfenv(1, DFUI:GetEnv())   -- 跑在 DFUI.env：hooksecurefunc 等 env 内助手才可见（assist 文件无此行会取到 nil）

local L = DFUI.Assist.L
local scanner = DFUI_Libs.libtipscan:GetScanner("DFUIAssistUnlock")
local _, playerClass = UnitClass("player")

-- 缓存“开锁/Pick Lock”法术索引（找不到则下次点击重试）
local pickIdx
local function getPickLock()
    if pickIdx then return pickIdx end
    local idx = DFUI_Libs.libspell:GetSpellIndex("开锁")
    if not idx then idx = DFUI_Libs.libspell:GetSpellIndex("Pick Lock") end
    pickIdx = idx
    return idx
end

DFUI.Assist:register({
    key = "autoUnlock",
    title = L["autoUnlock"],
    desc = L["autoUnlockDesc"],
    default = false,
    load = function(self)
        if playerClass ~= "ROGUE" then return end   -- 非盗贼不挂钩

        hooksecurefunc("ContainerFrameItemButton_OnClick", function(button)
            if not DFUI.Assist:IsEnabled("autoUnlock") then return end
            if button ~= "RightButton" then return end
            if BankFrame and BankFrame:IsVisible() then return end

            local btn = this
            if not btn or not btn.GetParent then return end
            local parent = btn:GetParent()
            local bag = parent and parent:GetID()
            local slot = btn:GetID()
            if not bag or not slot then return end

            scanner:SetBagItem(bag, slot)
            if scanner:FindText("Locked") or scanner:FindText("锁") then
                local idx = getPickLock()
                if idx then
                    CastSpell(idx, BOOKTYPE_SPELL)
                    PickupContainerItem(bag, slot)
                end
            end
        end, true)   -- POST-hook：原版默认点击先跑，再施开锁
    end,
})
