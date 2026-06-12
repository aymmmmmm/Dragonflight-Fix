----------------------------------------------------------------------
-- DFUI.Assist  --  Alt+点击物品链接转英文
-- 移植 Automatonex S_ItemLinktoenUS。Alt+左键点击装备/背包/商人/
-- 拾取/聊天里的物品 → 在聊天编辑框插入英文名链接。
--
-- 软依赖（用户已选）：英文名库来自 !Libs 的 LibStub("LibItem-enUS-1.0")。
-- 库缺失则该功能优雅降级（勾选时提示一次，不报错）。
--
-- 注意：DFUI 的 hooksecurefunc(name,func,append) 默认 append=nil 为
-- PRE-hook（先跑 func 再跑原版）；这里全部传 append=true 走 POST-hook，
-- 这样原版完成默认点击（如左键拾取物品到光标）后我们再插链接 + 清光标，
-- 避免物品卡在光标上。
----------------------------------------------------------------------

setfenv(1, DFUI:GetEnv())   -- 跑在 DFUI.env：hooksecurefunc 等 env 内助手才可见（assist 文件无此行会取到 nil）

local L = DFUI.Assist.L

local I          -- LibItem-enUS-1.0 实例
local warned = false

local function ensureLib()
    if I then return true end
    if not warned then
        DFUI.Assist.Print(L["linkNoItemDB"])
        warned = true
    end
    return false
end

local function altLeft(button)
    return ChatFrameEditBox and ChatFrameEditBox:IsVisible()
        and IsAltKeyDown() and button == "LeftButton"
end

-- 1.12 GetItemInfo 接受 item 链接字符串，**不接受裸数字 ID**，故先抠出
-- "item:..." 串再查
local function insertEnUS(link)
    if not link then return end
    if not ensureLib() then return end
    local _, _, itemstr = string.find(link, "(item:[%-%d:]+)")
    if not itemstr then return end
    local _, _, idStr = string.find(itemstr, "item:(%d+)")
    local id = tonumber(idStr)
    if not id then return end
    local enName = I.Item_enUS[id]
    if not enName then return end
    local _, _, quality = GetItemInfo(itemstr)
    local q = ITEM_QUALITY_COLORS[quality or 1] or ITEM_QUALITY_COLORS[1]
    ChatFrameEditBox:Insert(string.format("%s|H%s|h[%s]|h|r", q.hex, itemstr, enName))
    if CursorHasItem() then ClearCursor() end
end

DFUI.Assist:register({
    key = "linkItemEnUS",
    title = L["linkItemEnUS"],
    desc = L["linkItemEnUSDesc"],
    default = false,
    load = function(self)
        I = LibStub and LibStub("LibItem-enUS-1.0", true)

        hooksecurefunc("PaperDollItemSlotButton_OnClick", function(button)
            if not DFUI.Assist:IsEnabled("linkItemEnUS") then return end
            if altLeft(button) then
                insertEnUS(GetInventoryItemLink("player", this:GetID()))
            end
        end, true)

        hooksecurefunc("ContainerFrameItemButton_OnClick", function(button)
            if not DFUI.Assist:IsEnabled("linkItemEnUS") then return end
            if altLeft(button) then
                local parent = this:GetParent()
                insertEnUS(GetContainerItemLink(parent and parent:GetID(), this:GetID()))
            end
        end, true)

        hooksecurefunc("MerchantItemButton_OnClick", function(button)
            if not DFUI.Assist:IsEnabled("linkItemEnUS") then return end
            if altLeft(button) then
                insertEnUS(GetMerchantItemLink(this:GetID()))
            end
        end, true)

        hooksecurefunc("LootFrameItem_OnClick", function(button)
            if not DFUI.Assist:IsEnabled("linkItemEnUS") then return end
            if altLeft(button) then
                insertEnUS(GetLootSlotLink(this.slot))
            end
        end, true)

        hooksecurefunc("SetItemRef", function(link, text, button)
            if not DFUI.Assist:IsEnabled("linkItemEnUS") then return end
            if altLeft(button) and link and string.find(link, "^item:") then
                insertEnUS(link)
                if ItemRefTooltip and ItemRefTooltip:IsVisible() and ItemRefCloseButton then
                    ItemRefCloseButton:Click()
                end
            end
        end, true)
    end,
})
