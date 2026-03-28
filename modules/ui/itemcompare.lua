-- ═══════════════════════════════════════════════════════════════
-- 物品比较模块
-- 按住 Shift 悬停物品时，显示当前已装备同部位物品的对比
-- ═══════════════════════════════════════════════════════════════

DFUI:NewDefaults("ItemCompare", {
    enabled = {true},
    enableItemCompare = {true, "checkbox", nil, nil, "通用", 1, "Shift悬停物品时显示装备对比", nil, nil},
})

DFUI:NewMod("ItemCompare", 5, function()
    local setup = DFUI.tempDB.ItemCompare
    if not setup.enableItemCompare then return end

    -- 为缺失的本地化全局变量补充多语言映射（Wand/Gun/Crossbow/Thrown/Projectile）
    local localeExtras = {
        ["deDE"] = { INVTYPE_WAND = "Zauberstab", INVTYPE_THROWN = "Wurfwaffe", INVTYPE_GUN = "Schusswaffe", INVTYPE_CROSSBOW = "Armbrust", INVTYPE_PROJECTILE = "Projektil" },
        ["enUS"] = { INVTYPE_WAND = "Wand", INVTYPE_THROWN = "Thrown", INVTYPE_GUN = "Gun", INVTYPE_CROSSBOW = "Crossbow", INVTYPE_PROJECTILE = "Projectile" },
        ["esES"] = { INVTYPE_WAND = "Varita", INVTYPE_THROWN = "Arma arrojadiza", INVTYPE_GUN = "Arma de fuego", INVTYPE_CROSSBOW = "Ballesta", INVTYPE_PROJECTILE = "Proyectil" },
        ["frFR"] = { INVTYPE_WAND = "Baguette", INVTYPE_THROWN = "Armes de jet", INVTYPE_GUN = "Arme \195\160 feu", INVTYPE_CROSSBOW = "Arbal\195\168te", INVTYPE_PROJECTILE = "Projectile" },
        ["koKR"] = { INVTYPE_WAND = "\235\167\136\235\178\149\235\180\137", INVTYPE_THROWN = "\237\136\172\236\178\153 \235\172\180\234\184\176", INVTYPE_GUN = "\236\180\157", INVTYPE_CROSSBOW = "\236\132\157\234\182\129", INVTYPE_PROJECTILE = "\237\136\172\236\130\172\236\178\180" },
        ["ruRU"] = { INVTYPE_WAND = "\208\150\208\181\208\183\208\187", INVTYPE_THROWN = "\208\156\208\181\209\130\208\176\209\130\208\181\208\187\209\140\208\189\208\190\208\181", INVTYPE_GUN = "\208\158\208\179\208\189\208\181\209\129\209\130\209\128\208\181\208\187\209\140\208\189\208\190\208\181", INVTYPE_CROSSBOW = "\208\144\209\128\208\177\208\176\208\187\208\181\209\130", INVTYPE_PROJECTILE = "\208\145\208\190\208\181\208\191\209\128\208\184\208\191\208\176\209\129\209\139" },
        ["zhCN"] = { INVTYPE_WAND = "\233\173\148\230\157\150", INVTYPE_THROWN = "\230\138\149\230\142\183\230\173\166\229\153\168", INVTYPE_GUN = "\230\158\170\230\162\176", INVTYPE_CROSSBOW = "\229\188\169", INVTYPE_PROJECTILE = "\229\188\185\232\141\175" },
    }
    local extras = localeExtras[GetLocale()] or localeExtras["enUS"]
    for key, value in pairs(extras) do
        if not _G[key] then setglobal(key, value) end
    end

    -- 使用 WoW 本地化全局变量构建槽位映射（自动适配所有语言）
    local INVTYPE_WEAPON_OTHER = INVTYPE_WEAPON .. "_other"
    local INVTYPE_FINGER_OTHER = INVTYPE_FINGER .. "_other"
    local INVTYPE_TRINKET_OTHER = INVTYPE_TRINKET .. "_other"

    local slotTable = {
        [INVTYPE_2HWEAPON]       = 'MainHandSlot',
        [INVTYPE_BODY]           = 'ShirtSlot',
        [INVTYPE_CHEST]          = 'ChestSlot',
        [INVTYPE_CLOAK]          = 'BackSlot',
        [INVTYPE_FEET]           = 'FeetSlot',
        [INVTYPE_FINGER]         = 'Finger0Slot',
        [INVTYPE_FINGER_OTHER]   = 'Finger1Slot',
        [INVTYPE_HAND]           = 'HandsSlot',
        [INVTYPE_HEAD]           = 'HeadSlot',
        [INVTYPE_HOLDABLE]       = 'SecondaryHandSlot',
        [INVTYPE_LEGS]           = 'LegsSlot',
        [INVTYPE_NECK]           = 'NeckSlot',
        [INVTYPE_RANGED]         = 'RangedSlot',
        [INVTYPE_RELIC]          = 'RangedSlot',
        [INVTYPE_ROBE]           = 'ChestSlot',
        [INVTYPE_SHIELD]         = 'SecondaryHandSlot',
        [INVTYPE_SHOULDER]       = 'ShoulderSlot',
        [INVTYPE_TABARD]         = 'TabardSlot',
        [INVTYPE_TRINKET]        = 'Trinket0Slot',
        [INVTYPE_TRINKET_OTHER]  = 'Trinket1Slot',
        [INVTYPE_WAIST]          = 'WaistSlot',
        [INVTYPE_WEAPON]         = 'MainHandSlot',
        [INVTYPE_WEAPON_OTHER]   = 'SecondaryHandSlot',
        [INVTYPE_WEAPONMAINHAND] = 'MainHandSlot',
        [INVTYPE_WEAPONOFFHAND]  = 'SecondaryHandSlot',
        [INVTYPE_WRIST]          = 'WristSlot',
        [INVTYPE_WAND]           = 'RangedSlot',
        [INVTYPE_GUN]            = 'RangedSlot',
        [INVTYPE_PROJECTILE]     = 'AmmoSlot',
        [INVTYPE_CROSSBOW]       = 'RangedSlot',
        [INVTYPE_THROWN]         = 'RangedSlot',
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
        getglobal(name .. 'TextLeft1'):SetText(CURRENTLY_EQUIPPED or '当前装备')
        getglobal(name .. 'TextLeft1'):Show()
        tooltip:Show()
    end

    ShoppingTooltip1:SetClampedToScreen(true)
    ShoppingTooltip2:SetClampedToScreen(true)

    -- 核心：检测 Shift 并显示对比 Tooltip
    local function ShowComparison()
        if not IsShiftKeyDown() then
            ShoppingTooltip1:Hide()
            ShoppingTooltip2:Hide()
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
                    local anchor = anchorLeft and 'BOTTOMLEFT' or 'BOTTOMRIGHT'
                    local relative = anchorLeft and 'BOTTOMRIGHT' or 'BOTTOMLEFT'

                    -- 第一个对比框
                    ShoppingTooltip1:SetOwner(GameTooltip, 'ANCHOR_NONE')
                    ShoppingTooltip1:ClearAllPoints()
                    ShoppingTooltip1:SetPoint(anchor, GameTooltip, relative, 0, 0)
                    ShoppingTooltip1:SetInventoryItem('player', slotID)
                    ShoppingTooltip1:Show()
                    AddHeader(ShoppingTooltip1)

                    -- 第二个对比框（戒指/饰品/单手武器的另一个槽位）
                    if slotTable[text .. '_other'] then
                        local slotID2 = GetInventorySlotInfo(slotTable[text .. '_other'])
                        ShoppingTooltip2:SetOwner(GameTooltip, 'ANCHOR_NONE')
                        ShoppingTooltip2:ClearAllPoints()
                        ShoppingTooltip2:SetPoint(anchor, ShoppingTooltip1, relative, 0, 0)
                        ShoppingTooltip2:SetInventoryItem('player', slotID2)
                        ShoppingTooltip2:Show()
                        AddHeader(ShoppingTooltip2)
                    else
                        ShoppingTooltip2:Hide()
                    end
                    return
                end
            end
        end
        ShoppingTooltip1:Hide()
        ShoppingTooltip2:Hide()
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
            ShoppingTooltip2:Hide()
        end
    end)

    -- 回调
    local callbacks = {}
    callbacks.enableItemCompare = function() end
    DFUI:NewCallbacks("ItemCompare", callbacks)
end)
