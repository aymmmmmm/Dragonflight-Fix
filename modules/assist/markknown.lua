----------------------------------------------------------------------
-- DFUI.Assist  --  已学物品标记（商人 / 拍卖行）
-- 移植 Automatonex S_AlreadyKnown。
-- 已学会的配方/图纸（tooltip 含 ITEM_SPELL_KNOWN）→ 整个物品按钮染绿；
-- 商人处库存为 0 时颜色减半（阴影）；任务物品（ITEM_BIND_QUEST）染黄。
-- 复用 libtipscan 扫描器判定，不另建 tooltip。
----------------------------------------------------------------------

local L = DFUI.Assist.L

local COLOR = { r = 0.1, g = 1.0, b = 0.1 }

local scanner = DFUI_Libs.libtipscan:GetScanner("DFUIAssistMarkKnown")

-- 取 itemLink 中的 item:id:... 段喂给 SetHyperlink（整条彩色链接不被接受）
local function itemString(itemLink)
    if not itemLink then return end
    return gsub(itemLink, ".*(item:%d+:%d+:%d+:%d+).*", "%1", 1)
end

local function tooltipHas(itemLink, marker)
    local item = itemString(itemLink)
    if not item then return end
    scanner:SetHyperlink(item)
    return scanner:FindText(marker, true) ~= nil
end

local function IsAlreadyKnown(itemLink)
    return tooltipHas(itemLink, ITEM_SPELL_KNOWN)
end

local function IsQuest(itemLink)
    return tooltipHas(itemLink, ITEM_BIND_QUEST)
end

DFUI.Assist:register({
    key = "uiMarkKnown",
    title = L["uiMarkKnown"],
    desc = L["uiMarkKnownDesc"],
    default = false,
    load = function(self)
        -- 商人：原版 MerchantFrame_Update 每次重绘会把按钮 vertexColor 复位为白，
        -- 故 POST-hook 重新染色（仅在功能开启时）
        if MerchantFrame_Update then
            hooksecurefunc("MerchantFrame_Update", function()
                if not DFUI.Assist:IsEnabled("uiMarkKnown") then return end
                local numItems = GetMerchantNumItems()
                for i = 1, MERCHANT_ITEMS_PER_PAGE do
                    local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
                    if index > numItems then break end

                    local merchantButton = _G['MerchantItem' .. i]
                    local itemButton = _G['MerchantItem' .. i .. 'ItemButton']
                    if itemButton and itemButton:IsShown() then
                        local _, _, _, _, numAvailable, isUsable = GetMerchantItemInfo(index)
                        local link = GetMerchantItemLink(index)
                        if isUsable and IsAlreadyKnown(link) then
                            local r, g, b = COLOR.r, COLOR.g, COLOR.b
                            if numAvailable == 0 then
                                r, g, b = r * 0.5, g * 0.5, b * 0.5
                            end
                            SetItemButtonNameFrameVertexColor(merchantButton, r, g, b)
                            SetItemButtonSlotVertexColor(merchantButton, r, g, b)
                            SetItemButtonTextureVertexColor(itemButton, r, g, b)
                            SetItemButtonNormalTextureVertexColor(itemButton, r, g, b)
                        elseif isUsable and IsQuest(link) then
                            SetItemButtonNameFrameVertexColor(merchantButton, 1, 1, 0)
                            SetItemButtonSlotVertexColor(merchantButton, 1, 1, 0)
                            SetItemButtonTextureVertexColor(itemButton, 1, 1, 0)
                            SetItemButtonNormalTextureVertexColor(itemButton, 1, 1, 0)
                        end
                    end
                end
            end, true)
        end

        -- 拍卖行：1.12 vanilla 的 AuctionFrameBrowse_Update 直接存在于 FrameXML，
        -- 若为按需加载（部分客户端）则改挂 AuctionFrame_LoadUI 后再挂
        local function hookBrowse()
            if not AuctionFrameBrowse_Update then return end
            hooksecurefunc("AuctionFrameBrowse_Update", function()
                if not DFUI.Assist:IsEnabled("uiMarkKnown") then return end
                local numItems = GetNumAuctionItems('list')
                local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
                for i = 1, NUM_BROWSE_TO_DISPLAY do
                    local index = offset + i
                    if index > numItems then break end
                    local texture = _G['BrowseButton' .. i .. 'ItemIconTexture']
                    if texture and texture:IsShown() then
                        local _, _, _, _, canUse = GetAuctionItemInfo('list', index)
                        if canUse and IsAlreadyKnown(GetAuctionItemLink('list', index)) then
                            texture:SetVertexColor(COLOR.r, COLOR.g, COLOR.b)
                        end
                    end
                end
            end, true)
        end

        if AuctionFrameBrowse_Update then
            hookBrowse()
        elseif AuctionFrame_LoadUI then
            hooksecurefunc("AuctionFrame_LoadUI", hookBrowse, true)
        end
    end,
})
