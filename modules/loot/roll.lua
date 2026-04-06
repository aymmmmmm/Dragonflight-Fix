-- Dragonflight-Fix Loot Roll Module
-- Called by loot.lua Init, not registered as a separate DFUI module.
-- Roll settings (roll_rarity_timer) are in DFUI:NewDefaults("Loot", ...).

DFUI.InitLootRoll = function()
    ---------------------------------------------------------------------------
    -- Constants
    ---------------------------------------------------------------------------
    local MAX_ROLLS = 4
    local ROLL_WIDTH = 330
    local ROLL_HEIGHT = 104
    local ROLL_SPACING = 8
    local ICON_SIZE = 40
    local BUTTON_SIZE = 26
    local FONT_PATH = DFUI:GetInfoOrCons("font") .. "BigNoodleTitling.ttf"

    local BACKDROP_MAIN = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    }

    local BACKDROP_ICON = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
    }
    local BORDER_TEXTURE = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\actionbars\\border.blp"

    local BACKDROP_TIMER = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    }

    ---------------------------------------------------------------------------
    -- State
    ---------------------------------------------------------------------------
    local rollFrames = {}
    local rollCache = {}

    ---------------------------------------------------------------------------
    -- Chat message pattern matching (for roll tracking)
    ---------------------------------------------------------------------------
    -- Simplify WoW format patterns: collapse item link into single %s
    local ITEM_LINK_PAT = "%%s|Hitem:%%d:%%d:%%d:%%d|h%[%%s%]|h%%s"
    local PAT_GREED  = string.gsub(LOOT_ROLL_GREED  or "", ITEM_LINK_PAT, "%%s")
    local PAT_NEED   = string.gsub(LOOT_ROLL_NEED   or "", ITEM_LINK_PAT, "%%s")
    local PAT_PASSED = string.gsub(LOOT_ROLL_PASSED or "", ITEM_LINK_PAT, "%%s")

    -- Convert WoW format string to Lua pattern: %s → (.+), %d → (%d+), escape specials
    local function SimplifyPattern(pat)
        local ret = pat
        ret = string.gsub(ret, "([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
        ret = string.gsub(ret, "%%s", "(.+)")
        ret = string.gsub(ret, "%%d", "(%%d+)")
        return ret
    end

    local RE_GREED  = SimplifyPattern(PAT_GREED)
    local RE_NEED   = SimplifyPattern(PAT_NEED)
    local RE_PASSED = SimplifyPattern(PAT_PASSED)

    -- Blacklist: filter non-player names like "You" / "everyone"
    local rollBlacklist = {}
    if YOU then rollBlacklist[YOU] = true end
    if LOOT_ROLL_ALL_PASSED and PAT_PASSED ~= "" then
        local _, _, everyoneStr = string.find(
            LOOT_ROLL_ALL_PASSED or "", SimplifyPattern(PAT_PASSED))
        if everyoneStr then rollBlacklist[everyoneStr] = true end
    end

    ---------------------------------------------------------------------------
    -- Helpers
    ---------------------------------------------------------------------------
    local function GetDB(key)
        return DFUI:GetTempDB("Loot", key)
    end

    local function SafeQualityColor(quality)
        return ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[0]
    end

    -- Refresh count text on all visible roll frames matching an item
    local function RefreshCounts(itemname)
        if not itemname then return end
        local data = rollCache[itemname]
        local cNeed  = data and table.getn(data.NEED) or 0
        local cGreed = data and table.getn(data.GREED) or 0
        local cPass  = data and table.getn(data.PASS) or 0

        for i = 1, MAX_ROLLS do
            if rollFrames[i] and rollFrames[i]:IsShown()
               and rollFrames[i].itemname == itemname then
                rollFrames[i].needBtn.count:SetText(cNeed > 0 and cNeed or "")
                rollFrames[i].greedBtn.count:SetText(cGreed > 0 and cGreed or "")
                rollFrames[i].passBtn.count:SetText(cPass > 0 and cPass or "")
            end
        end
    end

    -- Add a player's roll choice to the cache
    local function AddCache(itemHyperlink, playerName, rollType)
        -- blacklist filter
        if rollBlacklist[playerName] then return end

        -- extract item name from hyperlink
        local _, _, itemLink = string.find(itemHyperlink, "(item:%d+:%d+:%d+:%d+)")
        local itemname = itemLink and GetItemInfo(itemLink)
        if not itemname then return end

        -- expire old data (60 seconds)
        if rollCache[itemname] and rollCache[itemname].TIMESTAMP < GetTime() - 60 then
            rollCache[itemname] = nil
        end

        -- init table
        if not rollCache[itemname] then
            rollCache[itemname] = {
                NEED = {}, GREED = {}, PASS = {},
                TIMESTAMP = GetTime()
            }
        end

        -- deduplicate
        local list = rollCache[itemname][rollType]
        for i = 1, table.getn(list) do
            if list[i] == playerName then return end
        end

        table.insert(list, playerName)
        RefreshCounts(itemname)
    end

    ---------------------------------------------------------------------------
    -- CreateRollButton
    ---------------------------------------------------------------------------
    local function CreateRollButton(parent, normalTex, highlightTex, onClick, tooltipText, rollType)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetWidth(BUTTON_SIZE)
        btn:SetHeight(BUTTON_SIZE)
        btn:SetNormalTexture(normalTex)
        btn:SetHighlightTexture(highlightTex)
        btn:SetScript("OnClick", onClick)
        btn.rollType = rollType

        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText or "")
            -- show player list from cache
            local frame = this:GetParent()
            if frame.itemname and this.rollType and rollCache[frame.itemname] then
                local players = rollCache[frame.itemname][this.rollType]
                if players then
                    for i = 1, table.getn(players) do
                        GameTooltip:AddLine(players[i])
                    end
                end
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- count overlay
        btn.count = btn:CreateFontString(nil, "OVERLAY")
        btn.count:SetFont(FONT_PATH, 12, "OUTLINE")
        btn.count:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.count:SetTextColor(1, 1, 1, 1)
        btn.count:SetText("")

        return btn
    end

    ---------------------------------------------------------------------------
    -- CreateRollFrame
    ---------------------------------------------------------------------------
    local function CreateRollFrame(id)
        local frame = CreateFrame("Frame", "DFUIRollFrame" .. id, UIParent)
        frame:SetWidth(ROLL_WIDTH)
        frame:SetHeight(ROLL_HEIGHT)
        frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(12)

        frame:SetBackdrop(BACKDROP_MAIN)
        frame:SetBackdropColor(0.04, 0.04, 0.04, 0.88)
        frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

        DFUI.tools.GradientLine(frame, "TOP", -1, 2)
        DFUI.tools.GradientLine(frame, "BOTTOM", 1, 2)

        local innerShadow = frame:CreateTexture(nil, "ARTWORK")
        innerShadow:SetTexture("Interface\\Buttons\\WHITE8X8")
        innerShadow:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
        innerShadow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
        innerShadow:SetHeight(8)
        innerShadow:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.3)

        local iconShadow = frame:CreateTexture(nil, "ARTWORK")
        iconShadow:SetTexture("Interface\\Buttons\\WHITE8X8")
        iconShadow:SetVertexColor(0, 0, 0, 0.6)
        iconShadow:SetWidth(ICON_SIZE + 6)
        iconShadow:SetHeight(ICON_SIZE + 6)
        iconShadow:SetPoint("TOPLEFT", frame, "TOPLEFT", 14 - 3, -(14 - 3))

        frame.iconFrame = CreateFrame("Frame", nil, frame)
        frame.iconFrame:SetWidth(ICON_SIZE)
        frame.iconFrame:SetHeight(ICON_SIZE)
        frame.iconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
        frame.iconFrame:SetBackdrop(BACKDROP_ICON)
        frame.iconFrame:SetBackdropColor(0, 0, 0, 0.8)
        frame.iconFrame:EnableMouse(false)

        frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetTexCoord(.07, .93, .07, .93)
        frame.icon:SetAllPoints(frame.iconFrame)

        -- Dragonflight-style border overlay (same as action bar icons)
        frame.iconBorder = frame:CreateTexture(nil, "OVERLAY")
        frame.iconBorder:SetTexture(BORDER_TEXTURE)
        frame.iconBorder:SetWidth(ICON_SIZE + 5)
        frame.iconBorder:SetHeight(ICON_SIZE + 5)
        frame.iconBorder:SetPoint("CENTER", frame.iconFrame, "CENTER", 0, 0)
        frame.iconBorder:SetVertexColor(0.4, 0.4, 0.4, 1)

        frame.iconBtn = CreateFrame("Button", nil, frame)
        frame.iconBtn:SetWidth(ICON_SIZE)
        frame.iconBtn:SetHeight(ICON_SIZE)
        frame.iconBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
        frame.iconBtn:SetScript("OnEnter", function()
            if not frame.rollID then return end
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetLootRollItem(frame.rollID)
        end)
        frame.iconBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        frame.iconBtn:SetScript("OnClick", function()
            if not frame.rollID then return end
            if IsControlKeyDown() then
                DressUpItemLink(GetLootRollItemLink(frame.rollID))
            elseif IsShiftKeyDown() then
                if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                    ChatFrameEditBox:Insert(GetLootRollItemLink(frame.rollID))
                end
            end
        end)

        frame.bindText = frame:CreateFontString(nil, "OVERLAY")
        frame.bindText:SetFont(FONT_PATH, 11, "OUTLINE")
        frame.bindText:SetJustifyH("LEFT")

        frame.itemName = frame:CreateFontString(nil, "OVERLAY")
        frame.itemName:SetFont(FONT_PATH, 14, "OUTLINE")
        frame.itemName:SetJustifyH("LEFT")
        frame.itemName:SetPoint("TOPLEFT", frame.iconFrame, "TOPRIGHT", 10, -2)
        frame.itemName:SetPoint("RIGHT", frame, "RIGHT", -24, 0)

        frame.timerFrame = CreateFrame("Frame", nil, frame)
        frame.timerFrame:SetPoint("TOPLEFT", frame.bindText, "BOTTOMLEFT", 0, -8)
        frame.timerFrame:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
        frame.timerFrame:SetHeight(10)
        frame.timerFrame:SetBackdrop(BACKDROP_TIMER)
        frame.timerFrame:SetBackdropColor(0, 0, 0, 0.6)
        frame.timerFrame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.6)
        frame.timerFrame:EnableMouse(false)

        frame.timer = CreateFrame("StatusBar", nil, frame.timerFrame)
        frame.timer:SetPoint("TOPLEFT", frame.timerFrame, "TOPLEFT", 2, -2)
        frame.timer:SetPoint("BOTTOMRIGHT", frame.timerFrame, "BOTTOMRIGHT", -2, 2)
        frame.timer:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        frame.timer:SetStatusBarColor(0.8, 0.8, 0.8, 0.8)
        frame.timer:SetMinMaxValues(0, 1)

        frame.timer:SetScript("OnUpdate", function()
            if not frame.rollID then return end
            local left = GetLootRollTimeLeft(frame.rollID)
            local _, max = this:GetMinMaxValues()
            if left < 0 or left > max then left = 0 end
            this:SetValue(left)
        end)

        -- Buttons positioned independently (pfUI approach)
        -- Each has its own Y offset to compensate for inconsistent texture padding
        local btnLeft = ICON_SIZE + 22
        local btnSpacing = BUTTON_SIZE + 6

        frame.needBtn = CreateRollButton(frame,
            "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
            "Interface\\Buttons\\UI-GroupLoot-Dice-Highlight",
            function() RollOnLoot(frame.rollID, 1) end,
            NEED or "Need", "NEED")
        frame.needBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", btnLeft, 10)

        frame.greedBtn = CreateRollButton(frame,
            "Interface\\Buttons\\UI-GroupLoot-Coin-Up",
            "Interface\\Buttons\\UI-GroupLoot-Coin-Highlight",
            function() RollOnLoot(frame.rollID, 2) end,
            GREED or "Greed", "GREED")
        frame.greedBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", btnLeft + btnSpacing, 9)

        frame.passBtn = CreateRollButton(frame,
            "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
            "Interface\\Buttons\\UI-GroupLoot-Coin-Highlight",
            function() RollOnLoot(frame.rollID, 0) end,
            PASS or "Pass", "PASS")
        frame.passBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", btnLeft + btnSpacing * 2, 12)

        frame.bindText:SetPoint("TOPLEFT", frame.itemName, "BOTTOMLEFT", 0, -4)

        -- Close button — DFUI red button style, pass and hide
        frame.closeBtn = DFUI.CreateRedButton(frame, "close", function()
            if frame.rollID then
                RollOnLoot(frame.rollID, 0)  -- pass
            end
            frame:Hide()
            frame.rollID = nil
            frame.itemname = nil
        end)
        frame.closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
        frame.closeBtn:SetWidth(18)
        frame.closeBtn:SetHeight(18)

        return frame
    end

    ---------------------------------------------------------------------------
    -- UpdateRollFrame
    ---------------------------------------------------------------------------
    local function UpdateRollFrame(frame)
        local texture, name, count, quality, bop = GetLootRollItemInfo(frame.rollID)
        local color = SafeQualityColor(quality)

        frame.itemname = name  -- cache key for roll tracking
        frame.icon:SetTexture(texture)
        frame.iconBorder:SetVertexColor(color.r, color.g, color.b, 1)

        local displayName = name
        if count and count > 1 then
            displayName = count .. "x " .. name
        end
        frame.itemName:SetText(displayName)
        frame.itemName:SetTextColor(color.r, color.g, color.b)
        frame:SetBackdropBorderColor(color.r, color.g, color.b, 0.6)

        frame.timer:SetMinMaxValues(0, frame.rollTime)
        frame.timer:SetValue(frame.rollTime)

        if GetDB("roll_rarity_timer") then
            frame.timer:SetStatusBarColor(color.r, color.g, color.b, 0.8)
        else
            frame.timer:SetStatusBarColor(0.8, 0.8, 0.8, 0.8)
        end

        if bop then
            frame.bindText:SetText("拾取绑定")
            frame.bindText:SetTextColor(1, 0.3, 0.3, 1)
        else
            frame.bindText:SetText("装备绑定")
            frame.bindText:SetTextColor(0.3, 1, 0.3, 1)
        end

        frame.needBtn:Enable()
        frame.greedBtn:Enable()
        frame.passBtn:Enable()

        -- init roll tracking counts from cache
        local data = rollCache[name]
        local cNeed  = data and table.getn(data.NEED) or 0
        local cGreed = data and table.getn(data.GREED) or 0
        local cPass  = data and table.getn(data.PASS) or 0
        frame.needBtn.count:SetText(cNeed > 0 and cNeed or "")
        frame.greedBtn.count:SetText(cGreed > 0 and cGreed or "")
        frame.passBtn.count:SetText(cPass > 0 and cPass or "")

        frame:Show()
    end

    ---------------------------------------------------------------------------
    -- OnCancelRoll
    ---------------------------------------------------------------------------
    local function OnCancelRoll(rollID)
        for i = 1, MAX_ROLLS do
            if rollFrames[i] and rollFrames[i].rollID == rollID then
                rollFrames[i]:Hide()
                rollFrames[i].rollID = nil
                rollFrames[i].itemname = nil
                return
            end
        end
    end

    ---------------------------------------------------------------------------
    -- OnStartRoll (shared handler)
    ---------------------------------------------------------------------------
    local function OnStartRoll(id, rollTime)
        for i = 1, MAX_ROLLS do
            if rollFrames[i] and not rollFrames[i]:IsShown() then
                rollFrames[i].rollID = id
                rollFrames[i].rollTime = rollTime
                UpdateRollFrame(rollFrames[i])
                return
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Setup
    ---------------------------------------------------------------------------
    local anchor = CreateFrame("Frame", "DFUIRollAnchor", UIParent)
    anchor:SetWidth(ROLL_WIDTH)
    anchor:SetHeight(ROLL_HEIGHT)
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    DFUI.rollAnchor = anchor

    for i = 1, MAX_ROLLS do
        rollFrames[i] = CreateRollFrame(i)
        rollFrames[i]:SetPoint("TOP", anchor, "TOP",
            0, -(i - 1) * (ROLL_HEIGHT + ROLL_SPACING))
        rollFrames[i]:Hide()
    end

    -- Replace global function (pfUI approach) — handles START_LOOT_ROLL
    _G.GroupLootFrame_OpenNewFrame = function(id, rollTime)
        -- clear cache when all roll frames are hidden (new round)
        local anyVisible = false
        for i = 1, MAX_ROLLS do
            if rollFrames[i] and rollFrames[i]:IsShown() then
                anyVisible = true
                break
            end
        end
        if not anyVisible then rollCache = {} end

        OnStartRoll(id, rollTime)
    end

    -- CANCEL_LOOT_ROLL event handler
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CANCEL_LOOT_ROLL")
    eventFrame:SetScript("OnEvent", function()
        if event == "CANCEL_LOOT_ROLL" then
            OnCancelRoll(arg1)
        end
    end)

    -- CHAT_MSG_LOOT listener for roll tracking
    local rollScanner = CreateFrame("Frame")
    rollScanner:RegisterEvent("CHAT_MSG_LOOT")
    rollScanner:SetScript("OnEvent", function()
        local player, item

        _, _, player, item = string.find(arg1, RE_NEED)
        if player and item then
            AddCache(item, player, "NEED")
            return
        end

        _, _, player, item = string.find(arg1, RE_GREED)
        if player and item then
            AddCache(item, player, "GREED")
            return
        end

        _, _, player, item = string.find(arg1, RE_PASSED)
        if player and item then
            AddCache(item, player, "PASS")
            return
        end
    end)

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[DFUI]|r LootRoll 模块已加载")
end
