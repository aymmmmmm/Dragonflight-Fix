-- Dragonflight-Fix Loot Roll Module
-- Called by loot.lua Init, not registered as a separate DFUI module.
-- Roll settings (roll_rarity_timer) are in DFUI:NewDefaults("Loot", ...).

DFUI.InitLootRoll = function()
    ---------------------------------------------------------------------------
    -- Constants
    ---------------------------------------------------------------------------
    local MAX_ROLLS = 4
    local ROLL_WIDTH = 320
    local ROLL_HEIGHT = 82
    local ROLL_SPACING = 8
    local ICON_SIZE = 36
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
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    }

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

    ---------------------------------------------------------------------------
    -- Helpers
    ---------------------------------------------------------------------------
    local function GetDB(key)
        return DFUI:GetTempDB("Loot", key)
    end

    local function SafeQualityColor(quality)
        return ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[0]
    end

    local function DisableAllButtons(frame)
        frame.needBtn:Disable()
        frame.greedBtn:Disable()
        frame.passBtn:Disable()
    end

    ---------------------------------------------------------------------------
    -- CreateRollButton
    ---------------------------------------------------------------------------
    local function CreateRollButton(parent, normalTex, highlightTex, onClick, tooltipText)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetWidth(BUTTON_SIZE)
        btn:SetHeight(BUTTON_SIZE)
        btn:SetNormalTexture(normalTex)
        btn:SetHighlightTexture(highlightTex)
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText or "")
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
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
        iconShadow:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 - 3, -(6 - 3))

        frame.iconFrame = CreateFrame("Frame", nil, frame)
        frame.iconFrame:SetWidth(ICON_SIZE)
        frame.iconFrame:SetHeight(ICON_SIZE)
        frame.iconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -6)
        frame.iconFrame:SetBackdrop(BACKDROP_ICON)
        frame.iconFrame:SetBackdropColor(0, 0, 0, 0.8)
        frame.iconFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        frame.iconFrame:EnableMouse(false)

        frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetTexCoord(.07, .93, .07, .93)
        frame.icon:SetPoint("TOPLEFT", frame.iconFrame, "TOPLEFT", 2, -2)
        frame.icon:SetPoint("BOTTOMRIGHT", frame.iconFrame, "BOTTOMRIGHT", -2, 2)

        local iconGloss = frame.iconFrame:CreateTexture(nil, "OVERLAY")
        iconGloss:SetTexture("Interface\\Buttons\\WHITE8X8")
        iconGloss:SetPoint("TOPLEFT", frame.iconFrame, "TOPLEFT", 2, -2)
        iconGloss:SetPoint("RIGHT", frame.iconFrame, "RIGHT", -2, 0)
        iconGloss:SetHeight(ICON_SIZE / 3)
        iconGloss:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.08)

        frame.iconBtn = CreateFrame("Button", nil, frame)
        frame.iconBtn:SetWidth(ICON_SIZE)
        frame.iconBtn:SetHeight(ICON_SIZE)
        frame.iconBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -6)
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
        frame.bindText:SetJustifyH("RIGHT")

        frame.itemName = frame:CreateFontString(nil, "OVERLAY")
        frame.itemName:SetFont(FONT_PATH, 14, "OUTLINE")
        frame.itemName:SetJustifyH("LEFT")
        frame.itemName:SetPoint("TOPLEFT", frame.iconFrame, "TOPRIGHT", 8, -1)
        frame.itemName:SetPoint("RIGHT", frame, "RIGHT", -50, 0)

        frame.timerFrame = CreateFrame("Frame", nil, frame)
        frame.timerFrame:SetPoint("BOTTOMLEFT", frame.iconFrame, "BOTTOMRIGHT", 8, 2)
        frame.timerFrame:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
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

        -- Buttons positioned independently from icon RIGHT (pfUI approach)
        -- Each has its own Y offset to compensate for inconsistent texture padding
        local btnLeft = ICON_SIZE + 18
        local btnSpacing = BUTTON_SIZE + 4

        frame.needBtn = CreateRollButton(frame,
            "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
            "Interface\\Buttons\\UI-GroupLoot-Dice-Highlight",
            function() RollOnLoot(frame.rollID, 1); DisableAllButtons(frame) end,
            NEED or "Need")
        frame.needBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", btnLeft, 9)

        frame.greedBtn = CreateRollButton(frame,
            "Interface\\Buttons\\UI-GroupLoot-Coin-Up",
            "Interface\\Buttons\\UI-GroupLoot-Coin-Highlight",
            function() RollOnLoot(frame.rollID, 2); DisableAllButtons(frame) end,
            GREED or "Greed")
        frame.greedBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", btnLeft + btnSpacing, 8)

        frame.passBtn = CreateRollButton(frame,
            "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
            "Interface\\Buttons\\UI-GroupLoot-Coin-Highlight",
            function() RollOnLoot(frame.rollID, 0); DisableAllButtons(frame) end,
            PASS or "Pass")
        frame.passBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", btnLeft + btnSpacing * 2, 10)

        frame.bindText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -8)

        return frame
    end

    ---------------------------------------------------------------------------
    -- UpdateRollFrame
    ---------------------------------------------------------------------------
    local function UpdateRollFrame(frame)
        local texture, name, count, quality, bop = GetLootRollItemInfo(frame.rollID)
        local color = SafeQualityColor(quality)

        frame.icon:SetTexture(texture)
        frame.iconFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)

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
            frame.bindText:SetText("BoP")
            frame.bindText:SetTextColor(1, 0.3, 0.3, 1)
        else
            frame.bindText:SetText("BoE")
            frame.bindText:SetTextColor(0.3, 1, 0.3, 1)
        end

        frame.needBtn:Enable()
        frame.greedBtn:Enable()
        frame.passBtn:Enable()
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

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[DFUI]|r LootRoll 模块已加载")
end
