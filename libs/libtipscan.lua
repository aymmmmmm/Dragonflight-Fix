-- ═══════════════════════════════════════════════════════════════
-- libtipscan - 隐藏 Tooltip 扫描器 (DFUI 移植版)
-- 来源: Dragonflight3 / credit to shagu v1.0
-- 提供隐藏式 GameTooltip 扫描，用于提取法术/物品信息
-- ═══════════════════════════════════════════════════════════════

local scanner = {}
local libtipscan = {}

local SET_METHODS = {
    'SetBagItem', 'SetAction', 'SetAuctionItem', 'SetAuctionSellItem', 'SetBuybackItem',
    'SetCraftItem', 'SetCraftSpell', 'SetHyperlink', 'SetInboxItem', 'SetInventoryItem',
    'SetLootItem', 'SetLootRollItem', 'SetMerchantItem', 'SetPetAction', 'SetPlayerBuff',
    'SetQuestItem', 'SetQuestLogItem', 'SetQuestRewardSpell', 'SetSendMailItem', 'SetShapeshift',
    'SetSpell', 'SetTalent', 'SetTrackingSpell', 'SetTradePlayerItem', 'SetTradeSkillItem', 'SetTradeTargetItem',
    'SetTrainerService', 'SetUnit', 'SetUnitBuff', 'SetUnitDebuff'
}

local function isEmpty(s)
    return not s or s == ""
end

local function round(x, n)
    n = n or 0
    local mult = 10 ^ n
    return math.floor(x * mult + 0.5) / mult
end

function scanner:GetText()
    local name = self:GetName()
    local result = {}
    for i = 1, self:NumLines() do
        local leftName = name .. 'TextLeft' .. i
        local rightName = name .. 'TextRight' .. i
        local left = _G[leftName]
        local right = _G[rightName]
        local leftText = left and left:IsVisible() and left:GetText()
        local rightText = right and right:IsVisible() and right:GetText()
        leftText = not isEmpty(leftText) and leftText or nil
        rightText = not isEmpty(rightText) and rightText or nil
        if leftText or rightText then
            result[i] = {leftText, rightText}
        end
    end
    return result
end

function scanner:FindText(pattern, exact)
    local name = self:GetName()
    for i = 1, self:NumLines() do
        local leftName = name .. 'TextLeft' .. i
        local rightName = name .. 'TextRight' .. i
        local left = _G[leftName]
        local right = _G[rightName]
        local leftText = left and left:IsVisible() and left:GetText()
        local rightText = right and right:IsVisible() and right:GetText()

        if exact then
            if (leftText and leftText == pattern) or (rightText and rightText == pattern) then
                return i, pattern
            end
        else
            if leftText then
                local found, _, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10 = string.find(leftText, pattern)
                if found then
                    return i, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10
                end
            end
            if rightText then
                local found, _, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10 = string.find(rightText, pattern)
                if found then
                    return i, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10
                end
            end
        end
    end
end

function scanner:GetLine(lineNum)
    local name = self:GetName()
    if lineNum <= self:NumLines() then
        local leftName = name .. 'TextLeft' .. lineNum
        local rightName = name .. 'TextRight' .. lineNum
        local left = _G[leftName]
        local right = _G[rightName]
        local leftText = left and left:IsVisible() and left:GetText()
        local rightText = right and right:IsVisible() and right:GetText()
        if leftText or rightText then
            return leftText, rightText
        end
    end
end

function scanner:FindColor(r, g, b)
    local name = self:GetName()
    if type(r) == 'table' then
        r, g, b = r.r or r[1], r.g or r[2], r.b or r[3]
    end
    for i = 1, self:NumLines() do
        local leftName = name .. 'TextLeft' .. i
        local rightName = name .. 'TextRight' .. i
        local left = _G[leftName]
        local right = _G[rightName]

        if left and left:IsVisible() then
            local lr, lg, lb = left:GetTextColor()
            lr, lg, lb = round(lr, 1), round(lg, 1), round(lb, 1)
            if lr == r and lg == g and lb == b then
                return i
            end
        end

        if right and right:IsVisible() then
            local rr, rg, rb = right:GetTextColor()
            rr, rg, rb = round(rr, 1), round(rg, 1), round(rb, 1)
            if rr == r and rg == g and rb == b then
                return i
            end
        end
    end
end

libtipscan.registry = setmetatable({}, {
    __index = function(t, name)
        local tooltip = CreateFrame('GameTooltip', 'DFUI_Scan' .. name, nil, 'GameTooltipTemplate')
        tooltip:SetOwner(WorldFrame, 'ANCHOR_NONE')
        tooltip:SetScript('OnHide', function()
            this:SetOwner(WorldFrame, 'ANCHOR_NONE')
        end)

        for key, method in pairs(scanner) do
            tooltip[key] = method
        end

        for _, methodName in ipairs(SET_METHODS) do
            local original = tooltip[methodName]
            tooltip[methodName] = function(self, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
                self:ClearLines()
                self:SetOwner(WorldFrame, 'ANCHOR_NONE')
                return original(self, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            end
        end

        rawset(t, name, tooltip)
        return tooltip
    end
})

function libtipscan:GetScanner(name)
    local tooltip = self.registry[name]
    tooltip:ClearLines()
    return tooltip
end

function libtipscan:List()
    for name, _ in pairs(self.registry) do
        DEFAULT_CHAT_FRAME:AddMessage(name)
    end
end

DFUI_Libs = DFUI_Libs or {}
DFUI_Libs.libtipscan = libtipscan
