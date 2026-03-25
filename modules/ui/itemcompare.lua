-- ═══════════════════════════════════════════════════════════════
-- 物品比较模块
-- 按住 Shift 悬停物品时，显示当前已装备同部位物品的对比
-- ═══════════════════════════════════════════════════════════════

DFRL:NewDefaults("ItemCompare", {
    enabled = {true},
    enableItemCompare = {true, "checkbox", nil, nil, "通用", 1, "Shift悬停物品时显示装备对比", nil, nil},
})

DFRL:NewMod("ItemCompare", 5, function()
    local setup = DFRL.tempDB.ItemCompare
    if not setup.enableItemCompare then return end

    -- 装备类型文本 → 装备槽映射（基于 Tooltip 行文本匹配）
    local slotTable = {
        ['Two-Hand'] = 'MainHandSlot',
        ['Shirt'] = 'ShirtSlot',
        ['Chest'] = 'ChestSlot',
        ['Back'] = 'BackSlot',
        ['Feet'] = 'FeetSlot',
        ['Finger'] = 'Finger0Slot',
        ['Hands'] = 'HandsSlot',
        ['Head'] = 'HeadSlot',
        ['Held In Off-hand'] = 'SecondaryHandSlot',
        ['Legs'] = 'LegsSlot',
        ['Neck'] = 'NeckSlot',
        ['Ranged'] = 'RangedSlot',
        ['Relic'] = 'RangedSlot',
        ['Robe'] = 'ChestSlot',
        ['Shield'] = 'SecondaryHandSlot',
        ['Shoulder'] = 'ShoulderSlot',
        ['Tabard'] = 'TabardSlot',
        ['Trinket'] = 'Trinket0Slot',
        ['Waist'] = 'WaistSlot',
        ['Main Hand'] = 'MainHandSlot',
        ['One-Hand'] = 'MainHandSlot',
        ['Off Hand'] = 'SecondaryHandSlot',
        ['Wrist'] = 'WristSlot',
        ['Wand'] = 'RangedSlot',
        ['Gun'] = 'RangedSlot',
        ['Projectile'] = 'AmmoSlot',
        ['Crossbow'] = 'RangedSlot',
        ['Thrown'] = 'RangedSlot',
    }

    -- 为对比提示框添加 "当前装备" 标题头
    local function AddHeader(tooltip)
        local name = tooltip:GetName()
        for i = tooltip:NumLines(), 1, -1 do
            local left = getglobal(name .. 'TextLeft' .. i)
            local right = getglobal(name .. 'TextRight' .. i)
            local leftBelow = getglobal(name .. 'TextLeft' .. (i + 1))
            local rightBelow = getglobal(name .. 'TextRight' .. (i + 1))

            if left and left:IsShown() then
                local text = left:GetText()
                local r, g, b = left:GetTextColor()
                if text and text ~= '' then
                    if tooltip:NumLines() < i + 1 then
                        tooltip:AddLine(text, r, g, b, true)
                    else
                        leftBelow:SetText(text)
                        leftBelow:SetTextColor(r, g, b)
                        leftBelow:Show()
                        left:Hide()
                    end
                end
            end

            if right and right:IsShown() then
                local text = right:GetText()
                local r, g, b = right:GetTextColor()
                if text and text ~= '' then
                    rightBelow:SetText(text)
                    rightBelow:SetTextColor(r, g, b)
                    rightBelow:Show()
                    right:Hide()
                end
            end
        end

        getglobal(name .. 'TextLeft1'):SetTextColor(0.5, 0.5, 0.5, 1)
        getglobal(name .. 'TextLeft1'):SetText('当前装备')
        getglobal(name .. 'TextLeft1'):Show()
        tooltip:Show()
    end

    -- 核心：检测 Shift 并显示对比 Tooltip
    local function ShowComparison()
        if not IsShiftKeyDown() then
            ShoppingTooltip1:Hide()
            return
        end

        for i = 1, GameTooltip:NumLines() do
            local line = getglobal('GameTooltipTextLeft' .. i)
            if line then
                local text = line:GetText()
                if text and slotTable[text] then
                    local slotID = GetInventorySlotInfo(slotTable[text])
                    local x = GetCursorPosition()
                    x = x / UIParent:GetEffectiveScale()
                    local anchorLeft = x < (GetScreenWidth() / 2)

                    ShoppingTooltip1:SetOwner(GameTooltip, 'ANCHOR_NONE')
                    ShoppingTooltip1:ClearAllPoints()
                    if anchorLeft then
                        ShoppingTooltip1:SetPoint('BOTTOMLEFT', GameTooltip, 'BOTTOMRIGHT', 0, 0)
                    else
                        ShoppingTooltip1:SetPoint('BOTTOMRIGHT', GameTooltip, 'BOTTOMLEFT', 0, 0)
                    end
                    ShoppingTooltip1:SetInventoryItem('player', slotID)
                    ShoppingTooltip1:Show()
                    AddHeader(ShoppingTooltip1)
                    return
                end
            end
        end
        ShoppingTooltip1:Hide()
    end

    -- 用 OnUpdate 定时检测（0.1秒间隔）
    local checker = CreateFrame('Frame')
    checker.elapsed = 0
    checker:SetScript('OnUpdate', function()
        this.elapsed = (this.elapsed or 0) + arg1
        if this.elapsed < 0.1 then return end
        this.elapsed = 0
        if GameTooltip:IsVisible() then
            ShowComparison()
        else
            ShoppingTooltip1:Hide()
        end
    end)

    -- 回调
    local callbacks = {}
    callbacks.enableItemCompare = function() end
    DFRL:NewCallbacks("ItemCompare", callbacks)
end)
