----------------------------------------------------------------------
-- DFUI.Assist  --  进战/脱战横幅
-- 移植 S_AlertCombat。进入战斗顶部弹红字"进入战斗"横幅，离开战斗弹
-- 绿字"离开战斗"，5 秒淡入淡出。横幅底图 CombatBG.tga 顶点染黄。
----------------------------------------------------------------------

local L = DFUI.Assist.L
local TEX = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\ui\\CombatBG.tga"

local banner

local function build()
    if banner then return end
    banner = CreateFrame("Frame", "DFUIAssistCombatAlert", UIParent)
    banner:Hide()
    banner:SetWidth(200)
    banner:SetHeight(70)
    banner:SetPoint("TOP", UIParent, "TOP", 0, -170)
    banner:SetFrameStrata("HIGH")

    local bg = banner:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(TEX)
    bg:SetAllPoints(banner)
    bg:SetVertexColor(1, 1, 0, 0.6)
    banner.bg = bg

    local text = banner:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetFont(STANDARD_TEXT_FONT, 20)
    text:SetPoint("CENTER", banner, "CENTER", 0, 2.5)
    banner.text = text

    banner.timer = 0
    banner.total = 5

    banner:SetScript("OnShow", function()
        this.timer = 0
        this.total = 5
    end)

    banner:SetScript("OnUpdate", function()
        this.timer = this.timer + arg1
        if this.timer > this.total then this:Hide(); return end
        if this.timer <= 0.5 then
            this:SetAlpha(this.timer * 2)
        elseif this.timer > 2 then
            this:SetAlpha(1 - this.timer / this.total)
        else
            this:SetAlpha(1)
        end
    end)
end

local function flash(msg, r, g, b)
    if not banner then return end
    banner.text:SetText(msg)
    banner.text:SetTextColor(r, g, b)
    banner.timer = 0
    banner.total = 5
    banner:Show()
end

DFUI.Assist:register({
    key = "uiCombatAlert",
    title = L["uiCombatAlert"],
    desc = L["uiCombatAlertDesc"],
    default = false,
    load = function(self)
        build()
    end,
    events = {
        PLAYER_REGEN_DISABLED = function(self)
            flash(L["combatEnter"], 1, 0, 0)
        end,
        PLAYER_REGEN_ENABLED = function(self)
            flash(L["combatLeave"], 0, 1, 0)
        end,
    },
})
