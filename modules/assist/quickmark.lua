----------------------------------------------------------------------
-- DFUI.Assist  --  Quick Mark Module (快速标记)
-- Double-click target frame → radial raid marker wheel
-- Lua 5.0 compatible  |  WoW 1.12 (Turtle WoW)
----------------------------------------------------------------------

local QM_RADIUS       = 62
local QM_ICON_SIZE    = 32
local QM_CENTER_SIZE  = 22
local QM_ANIM_DUR     = 0.30
local QM_DBLCLICK     = 0.35
local QM_FRAME_SIZE   = 190

local QM_NAMES = {
    "星星", "圆圈", "钻石", "三角",
    "月亮", "骷髅", "十字", "方块",
}

local QM_COLORS = {
    { 1.0, 0.82, 0.0  },  -- 1 Star
    { 1.0, 0.50, 0.0  },  -- 2 Circle
    { 0.8, 0.30, 1.0  },  -- 3 Diamond
    { 0.1, 0.90, 0.1  },  -- 4 Triangle
    { 0.7, 0.70, 0.9  },  -- 5 Moon
    { 1.0, 1.00, 1.0  },  -- 6 Skull
    { 1.0, 0.20, 0.2  },  -- 7 Cross
    { 0.2, 0.40, 1.0  },  -- 8 Square
}

-- Atlas texture: 4 columns x 2 rows grid
local QM_ATLAS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local QM_TEXCOORDS = {
    { 0.00, 0.25, 0.00, 0.25 },  -- 1 Star
    { 0.25, 0.50, 0.00, 0.25 },  -- 2 Circle
    { 0.50, 0.75, 0.00, 0.25 },  -- 3 Diamond
    { 0.75, 1.00, 0.00, 0.25 },  -- 4 Triangle
    { 0.00, 0.25, 0.25, 0.50 },  -- 5 Moon
    { 0.25, 0.50, 0.25, 0.50 },  -- 6 Skull
    { 0.50, 0.75, 0.25, 0.50 },  -- 7 Cross
    { 0.75, 1.00, 0.25, 0.50 },  -- 8 Square
}

----------------------------------------------------------------------
local qmMenu, qmBackdrop, qmCenterBtn
local qmBtns       = {}
local qmLastClick   = 0
local qmAnimTime    = 0
local qmAnimating   = false
local qmHooked      = false

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local function QM_Ease(t)
    return 1 - (1 - t) * (1 - t)
end

local function QM_SetMarker(idx)
    if not UnitExists("target") then return end
    if SetRaidTargetIcon then
        SetRaidTargetIcon("target", idx)
    elseif SetRaidTarget then
        SetRaidTarget("target", idx)
    end
end

local function QM_CurrentMarker()
    if not UnitExists("target") then return nil end
    if GetRaidTargetIndex then
        return GetRaidTargetIndex("target")
    end
    return nil
end

----------------------------------------------------------------------
-- Build Menu
----------------------------------------------------------------------

local function QM_CreateMenu()
    if qmMenu then return end

    -- Full-screen click catcher
    qmBackdrop = getglobal("DFUIAssistQMBackdrop") or CreateFrame("Frame", "DFUIAssistQMBackdrop", UIParent)
    qmBackdrop:SetAllPoints(UIParent)
    qmBackdrop:SetFrameStrata("TOOLTIP")
    qmBackdrop:SetFrameLevel(90)
    qmBackdrop:EnableMouse(true)
    qmBackdrop:Hide()
    qmBackdrop:SetScript("OnMouseDown", function()
        if qmMenu then qmMenu:Hide() end
        this:Hide()
    end)

    -- Radial container
    qmMenu = getglobal("DFUIAssistQuickMarkMenu") or CreateFrame("Frame", "DFUIAssistQuickMarkMenu", qmBackdrop)
    qmMenu:SetWidth(QM_FRAME_SIZE)
    qmMenu:SetHeight(QM_FRAME_SIZE)
    qmMenu:SetFrameStrata("TOOLTIP")
    qmMenu:SetFrameLevel(92)
    qmMenu:EnableMouse(true)
    qmMenu:Hide()

    qmMenu:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    local at = SFrames and SFrames.ActiveTheme
    if at and at.panelBg then
        qmMenu:SetBackdropColor(at.panelBg[1], at.panelBg[2], at.panelBg[3], 0.92)
    else
        qmMenu:SetBackdropColor(0.08, 0.04, 0.06, 0.92)
    end
    if at and at.panelBorder then
        qmMenu:SetBackdropBorderColor(at.panelBorder[1], at.panelBorder[2], at.panelBorder[3], 0.85)
    else
        qmMenu:SetBackdropBorderColor(0.55, 0.30, 0.42, 0.85)
    end

    -- Title
    local title = qmMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("BOTTOM", qmMenu, "BOTTOM", 0, 6)
    title:SetText("|c" .. DFUI.Assist.GetAccentHex() .. "快速标记|r")
    qmMenu.titleText = title

    -- 8 marker buttons arranged in a circle (clockwise from top)
    for i = 1, 8 do
        local btn = CreateFrame("Button", nil, qmMenu)
        btn:SetWidth(QM_ICON_SIZE)
        btn:SetHeight(QM_ICON_SIZE)
        btn:SetFrameLevel(qmMenu:GetFrameLevel() + 3)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetTexture(QM_ATLAS)
        local tc = QM_TEXCOORDS[i]
        tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
        tex:SetAllPoints(btn)
        btn.iconTex = tex

        local glow = btn:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        glow:SetBlendMode("ADD")
        glow:SetWidth(QM_ICON_SIZE * 2)
        glow:SetHeight(QM_ICON_SIZE * 2)
        glow:SetPoint("CENTER", btn, "CENTER", 0, 0)
        glow:SetAlpha(0)
        btn.glowTex = glow

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture(1, 1, 1, 0.2)
        hl:SetAllPoints(btn)

        btn.markerIdx = i
        btn:RegisterForClicks("LeftButtonUp")

        btn:SetScript("OnClick", function()
            QM_SetMarker(this.markerIdx)
            qmMenu:Hide()
            qmBackdrop:Hide()
        end)

        btn:SetScript("OnEnter", function()
            local c = QM_COLORS[this.markerIdx]
            if c and this.glowTex then
                this.glowTex:SetVertexColor(c[1], c[2], c[3], 1)
                this.glowTex:SetAlpha(0.6)
            end
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:AddLine(QM_NAMES[this.markerIdx] or "标记", 1, 0.82, 0)
            GameTooltip:AddLine("点击设置标记", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)

        btn:SetScript("OnLeave", function()
            if this.glowTex then
                local cur = QM_CurrentMarker()
                if cur and cur == this.markerIdx then
                    this.glowTex:SetAlpha(0.35)
                else
                    this.glowTex:SetAlpha(0)
                end
            end
            GameTooltip:Hide()
        end)

        qmBtns[i] = btn
    end

    -- Center: clear marker
    qmCenterBtn = CreateFrame("Button", nil, qmMenu)
    qmCenterBtn:SetWidth(QM_CENTER_SIZE)
    qmCenterBtn:SetHeight(QM_CENTER_SIZE)
    qmCenterBtn:SetPoint("CENTER", qmMenu, "CENTER", 0, 0)
    qmCenterBtn:SetFrameLevel(qmMenu:GetFrameLevel() + 3)

    local clearTex = qmCenterBtn:CreateTexture(nil, "ARTWORK")
    clearTex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearTex:SetAllPoints(qmCenterBtn)
    qmCenterBtn.iconTex = clearTex

    local clearHl = qmCenterBtn:CreateTexture(nil, "HIGHLIGHT")
    clearHl:SetTexture(1, 1, 1, 0.25)
    clearHl:SetAllPoints(qmCenterBtn)

    qmCenterBtn:RegisterForClicks("LeftButtonUp")
    qmCenterBtn:SetScript("OnClick", function()
        QM_SetMarker(0)
        qmMenu:Hide()
        qmBackdrop:Hide()
    end)
    qmCenterBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:AddLine("清除标记", 1, 0.4, 0.4)
        GameTooltip:Show()
    end)
    qmCenterBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Spiral-out animation driven by OnUpdate
    -- Icons start at center and spiral outward clockwise from top
    qmMenu:SetScript("OnUpdate", function()
        if not qmAnimating then return end
        qmAnimTime = qmAnimTime + arg1
        local t = qmAnimTime / QM_ANIM_DUR
        if t >= 1 then
            t = 1
            qmAnimating = false
        end

        local e    = QM_Ease(t)
        local rad  = QM_RADIUS * e
        local spin = (1 - e) * 45
        local s    = 0.3 + 0.7 * e
        local a    = e
        local cx   = QM_FRAME_SIZE / 2
        local cy   = -QM_FRAME_SIZE / 2

        for i = 1, 8 do
            local btn = qmBtns[i]
            -- 90° = top, clockwise: subtract angle, spin rotates during anim
            local ang = math.rad(90 - (i - 1) * 45 - spin)
            local bx  = math.cos(ang) * rad
            local by  = math.sin(ang) * rad

            btn:ClearAllPoints()
            btn:SetPoint("CENTER", qmMenu, "TOPLEFT", cx + bx, cy + by)
            btn:SetWidth(QM_ICON_SIZE * s)
            btn:SetHeight(QM_ICON_SIZE * s)
            btn:SetAlpha(a)
        end

        qmCenterBtn:SetAlpha(a)
        qmCenterBtn:SetWidth(QM_CENTER_SIZE * s)
        qmCenterBtn:SetHeight(QM_CENTER_SIZE * s)
    end)

    -- Escape to close
    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "DFUIAssistQMBackdrop")
    end

    -- Close when target lost
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:SetScript("OnEvent", function()
        if qmMenu and qmMenu:IsShown() and not UnitExists("target") then
            qmMenu:Hide()
            if qmBackdrop then qmBackdrop:Hide() end
        end
    end)
end

----------------------------------------------------------------------
-- Show
----------------------------------------------------------------------

local function QM_Show()
    if not UnitExists("target") then return end
    if not DFUI.Assist:IsEnabled("uiQuickMark") then return end

    QM_CreateMenu()

    -- Position at cursor
    local curX, curY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    curX = curX / scale
    curY = curY / scale

    -- Clamp to screen edges
    local half = QM_FRAME_SIZE / 2
    local screenW = UIParent:GetWidth() or 1024
    local screenH = UIParent:GetHeight() or 768
    if curX - half < 0 then curX = half end
    if curX + half > screenW then curX = screenW - half end
    if curY - half < 0 then curY = half end
    if curY + half > screenH then curY = screenH - half end

    qmMenu:ClearAllPoints()
    qmMenu:SetPoint("CENTER", UIParent, "BOTTOMLEFT", curX, curY)

    -- Highlight active marker
    local cur = QM_CurrentMarker()
    for i = 1, 8 do
        local btn = qmBtns[i]
        if cur and cur == i then
            local c = QM_COLORS[i]
            btn.glowTex:SetVertexColor(c[1], c[2], c[3], 1)
            btn.glowTex:SetAlpha(0.35)
        else
            btn.glowTex:SetAlpha(0)
        end
    end

    -- Reset animation state: all icons at center
    qmAnimTime = 0
    qmAnimating = true
    local hf = QM_FRAME_SIZE / 2
    for i = 1, 8 do
        local btn = qmBtns[i]
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", qmMenu, "TOPLEFT", hf, -hf)
        btn:SetWidth(1)
        btn:SetHeight(1)
        btn:SetAlpha(0)
    end
    qmCenterBtn:SetAlpha(0)
    qmCenterBtn:SetWidth(1)
    qmCenterBtn:SetHeight(1)

    qmBackdrop:Show()
    qmMenu:Show()
end

----------------------------------------------------------------------
-- Hook Target Frame (SFramesTargetFrame or default TargetFrame)
----------------------------------------------------------------------

local function QM_FindTargetFrame()
    if SFrames and SFrames.Target and SFrames.Target.frame then
        return SFrames.Target.frame, "SFramesTargetFrame"
    end
    local sf = getglobal("SFramesTargetFrame")
    if sf then return sf, "SFramesTargetFrame" end
    if TargetFrame then return TargetFrame, "TargetFrame" end
    return nil, nil
end

local function QM_HookFrame(frame, frameName)
    if qmHooked then return end
    if not frame then return end

    local orig = frame:GetScript("OnClick")

    frame:SetScript("OnClick", function()
        if orig then orig() end

        if not DFUI.Assist:IsEnabled("uiQuickMark") then
            return
        end

        if arg1 == "LeftButton" then
            local now = GetTime()
            local delta = now - qmLastClick
            if delta < QM_DBLCLICK then
                qmLastClick = 0
                QM_Show()
            else
                qmLastClick = now
            end
        end
    end)

    qmHooked = true
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function DFUI.Assist.ToggleQuickMark()
    if not DFUI.Assist.db then return end
    DFUI.Assist.db.uiQuickMark = not DFUI.Assist.db.uiQuickMark
    if DFUI.Assist.db.uiQuickMark and not qmHooked then
        local frame, name = QM_FindTargetFrame()
        QM_HookFrame(frame, name)
    end
end

function DFUI.Assist.ShowQuickMarkMenu()
    QM_Show()
end

----------------------------------------------------------------------
-- Init (retry until target frame is found)
----------------------------------------------------------------------

local qmInit = CreateFrame("Frame")
qmInit:RegisterEvent("PLAYER_LOGIN")
qmInit:SetScript("OnEvent", function()
    local d = CreateFrame("Frame")
    d.elapsed = 0
    d.attempt = 0
    d:SetScript("OnUpdate", function()
        this.elapsed = this.elapsed + arg1
        if this.elapsed > 1 then
            this.elapsed = 0
            this.attempt = this.attempt + 1
            local frame, name = QM_FindTargetFrame()
            if frame then
                this:SetScript("OnUpdate", nil)
                this:Hide()
                QM_HookFrame(frame, name)
            elseif this.attempt >= 10 then
                this:SetScript("OnUpdate", nil)
                this:Hide()
            end
        end
    end)
end)

----------------------------------------------------------------------
-- DFUI.Assist 注册：key=uiQuickMark（逻辑自带 PLAYER_LOGIN 挂载，仅登记开关）
----------------------------------------------------------------------
DFUI.Assist:register({
    key = "uiQuickMark",
    title = DFUI.Assist.L["uiQuickMark"],
    desc = DFUI.Assist.L["uiQuickMarkDesc"],
    default = true,
})