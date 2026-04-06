-- paperdoll.lua — PaperDollFrame 工厂函数 + RedButton
-- 移植自 D3 ui-tools.lua，适配 DFUI

local TEX = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\"

-- RedButton 纹理坐标
local BUTTON_TEXCOORDS = {
    close = {
        normal = {0.152344, 0.292969, 0.0078125, 0.304688},
        pushed = {0.152344, 0.292969, 0.320312, 0.617188}
    },
    minimize = {
        normal = {0.00390625, 0.144531, 0.0078125, 0.304688},
        pushed = {0.00390625, 0.144531, 0.320312, 0.617188}
    },
    maximize = {
        normal = {0.300781, 0.441406, 0.0078125, 0.304688},
        pushed = {0.300781, 0.441406, 0.320312, 0.617188}
    },
    highlight = {0.449219, 0.589844, 0.0078125, 0.304688}
}

local redButtonTex = TEX .. "interface\\redbutton2x.BLP"

function DFUI.CreateRedButton(parent, buttonType, onClick)
    local coords = BUTTON_TEXCOORDS[buttonType]
    if not coords then return nil end

    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(21)
    button:SetHeight(21)
    button.currentType = buttonType

    local normal = button:CreateTexture(nil, "BORDER")
    normal:SetTexture(redButtonTex)
    normal:SetAllPoints(button)
    normal:SetTexCoord(coords.normal[1], coords.normal[2], coords.normal[3], coords.normal[4])
    button:SetNormalTexture(normal)
    button.normalTex = normal

    local pushed = button:CreateTexture(nil, "BORDER")
    pushed:SetTexture(redButtonTex)
    pushed:SetAllPoints(button)
    pushed:SetTexCoord(coords.pushed[1], coords.pushed[2], coords.pushed[3], coords.pushed[4])
    button:SetPushedTexture(pushed)
    button.pushedTex = pushed

    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture(redButtonTex)
    hl:SetAllPoints(button)
    hl:SetTexCoord(BUTTON_TEXCOORDS.highlight[1], BUTTON_TEXCOORDS.highlight[2], BUTTON_TEXCOORDS.highlight[3], BUTTON_TEXCOORDS.highlight[4])
    hl:SetBlendMode("ADD")
    button:SetHighlightTexture(hl)

    function button:SwitchType(newType)
        local c = BUTTON_TEXCOORDS[newType]
        if c then
            self.currentType = newType
            self.normalTex:SetTexCoord(c.normal[1], c.normal[2], c.normal[3], c.normal[4])
            self.pushedTex:SetTexCoord(c.pushed[1], c.pushed[2], c.pushed[3], c.pushed[4])
        end
    end

    if onClick then
        button:SetScript("OnClick", onClick)
    end

    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText("Close")
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

-- PaperDollFrame 工厂
-- frameStyle: 1 = 带头像金属框, 2 = 无头像金属框, 3 = 备用金属纹理
function DFUI.CreatePaperDollFrame(name, parent, width, height, frameStyle)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetWidth(width)
    frame:SetHeight(height)

    local metalTex = frameStyle == 3 and "UIFrameMetal2x2" or "UIFrameMetal2x"
    local metalHorizTex = frameStyle == 3 and "UIFrameMetalHorizontal2x2" or "UIFrameMetalHorizontal2x"
    local metalPath = TEX .. "interface\\" .. metalTex .. ".blp"
    local horizPath = TEX .. "interface\\" .. metalHorizTex .. ".BLP"
    local vertPath = TEX .. "interface\\UIFrameMetalVertical2x.BLP"
    local rockPath = TEX .. "interface\\UI-Background-Rock.blp"
    local tabsPath = TEX .. "interface\\uiframetabs.blp"

    -- 背景
    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetDrawLayer("BACKGROUND", -2)
    bgTexture:SetTexture(rockPath)
    bgTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -21)
    bgTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    frame.Bg = bgTexture

    -- 左上角 75x75
    local topLeft = frame:CreateTexture(nil, "OVERLAY")
    topLeft:SetTexture(metalPath)
    topLeft:SetWidth(75)
    topLeft:SetHeight(75)
    topLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", -13, 16)

    if frameStyle == 1 then
        topLeft:SetTexCoord(0.00195312, 0.294922, 0.298828, 0.591797)
        local portrait = frame:CreateTexture(nil, "OVERLAY")
        portrait:SetWidth(54)
        portrait:SetHeight(54)
        portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 4)
        frame.portrait = portrait
    else
        topLeft:SetTexCoord(0.00195312, 0.294922, 0.00195312, 0.294922)
    end

    -- 右上角 75x75
    local topRight = frame:CreateTexture(nil, "ARTWORK")
    topRight:SetTexture(metalPath)
    topRight:SetWidth(75)
    topRight:SetHeight(75)
    topRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 16)
    topRight:SetTexCoord(0.298828, 0.591797, 0.00195312, 0.294922)

    -- 左下角 32x32
    local bottomLeft = frame:CreateTexture(nil, "ARTWORK")
    bottomLeft:SetTexture(metalPath)
    bottomLeft:SetWidth(32)
    bottomLeft:SetHeight(32)
    bottomLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -13, -3)
    bottomLeft:SetTexCoord(0.298828, 0.423828, 0.298828, 0.423828)

    -- 右下角 32x32
    local bottomRight = frame:CreateTexture(nil, "ARTWORK")
    bottomRight:SetTexture(metalPath)
    bottomRight:SetWidth(32)
    bottomRight:SetHeight(32)
    bottomRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -3)
    bottomRight:SetTexCoord(0.427734, 0.552734, 0.298828, 0.423828)

    -- 顶边
    local topEdge = frame:CreateTexture(nil, "ARTWORK")
    topEdge:SetTexture(horizPath)
    topEdge:SetWidth(32)
    topEdge:SetHeight(75)
    topEdge:SetPoint("TOPLEFT", topLeft, "TOPRIGHT", 0, 0)
    topEdge:SetPoint("TOPRIGHT", topRight, "TOPLEFT", 0, 0)
    topEdge:SetTexCoord(0.0, 1.0, 0.00390625, 0.589844)

    -- 底边
    local bottomEdge = frame:CreateTexture(nil, "ARTWORK")
    bottomEdge:SetTexture(horizPath)
    bottomEdge:SetWidth(32)
    bottomEdge:SetHeight(32)
    bottomEdge:SetPoint("BOTTOMLEFT", bottomLeft, "BOTTOMRIGHT", 0, 0)
    bottomEdge:SetPoint("BOTTOMRIGHT", bottomRight, "BOTTOMLEFT", 0, 0)
    bottomEdge:SetTexCoord(0.0, 0.5, 0.597656, 0.847656)

    -- 左边
    local leftEdge = frame:CreateTexture(nil, "ARTWORK")
    leftEdge:SetTexture(vertPath)
    leftEdge:SetWidth(75)
    leftEdge:SetHeight(8)
    leftEdge:SetPoint("TOPLEFT", topLeft, "BOTTOMLEFT", 0, 0)
    leftEdge:SetPoint("BOTTOMLEFT", bottomLeft, "TOPLEFT", 0, 0)
    leftEdge:SetTexCoord(0.00195312, 0.294922, 0.0, 1.0)

    -- 右边
    local rightEdge = frame:CreateTexture(nil, "ARTWORK")
    rightEdge:SetTexture(vertPath)
    rightEdge:SetWidth(75)
    rightEdge:SetHeight(8)
    rightEdge:SetPoint("TOPLEFT", topRight, "BOTTOMLEFT", 0, 0)
    rightEdge:SetPoint("BOTTOMLEFT", bottomRight, "TOPLEFT", 0, 0)
    rightEdge:SetTexCoord(0.298828, 0.591797, 0.0, 1.0)

    frame.edges = {topLeft, topRight, bottomLeft, bottomRight, topEdge, bottomEdge, leftEdge, rightEdge}

    -- Tab 系统
    frame.Tabs = {}
    frame.selectedTab = nil

    function frame:AddTab(text, onClick, tabWidth, spacing)
        local tab = CreateFrame("Button", nil, frame)
        tab:SetWidth(tabWidth or 70)
        tab:SetHeight(32)

        -- 未选中态
        local left = tab:CreateTexture(nil, "BACKGROUND")
        left:SetTexture(tabsPath)
        left:SetWidth(35)
        left:SetHeight(36)
        left:SetPoint("TOPLEFT", tab, "TOPLEFT", -3, 0)
        left:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
        tab.Left = left

        local right = tab:CreateTexture(nil, "BACKGROUND")
        right:SetTexture(tabsPath)
        right:SetWidth(37)
        right:SetHeight(36)
        right:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 7, 0)
        right:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
        tab.Right = right

        local middle = tab:CreateTexture(nil, "BACKGROUND")
        middle:SetTexture(tabsPath)
        middle:SetWidth(1)
        middle:SetHeight(36)
        middle:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
        middle:SetPoint("TOPRIGHT", right, "TOPLEFT", 0, 0)
        middle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
        tab.Middle = middle

        -- 选中态（高度 39px，比普通态 36px 略高）
        local selHeight = 39
        local leftSel = tab:CreateTexture(nil, "BACKGROUND")
        leftSel:SetTexture(tabsPath)
        leftSel:SetWidth(35)
        leftSel:SetHeight(selHeight)
        leftSel:SetPoint("TOPLEFT", tab, "TOPLEFT", -1, 0)
        leftSel:SetTexCoord(0.015625, 0.5625, 0.496094, 0.660156)
        leftSel:Hide()

        local rightSel = tab:CreateTexture(nil, "BACKGROUND")
        rightSel:SetTexture(tabsPath)
        rightSel:SetWidth(37)
        rightSel:SetHeight(selHeight)
        rightSel:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 8, 0)
        rightSel:SetTexCoord(0.015625, 0.59375, 0.324219, 0.488281)
        rightSel:Hide()

        local middleSel = tab:CreateTexture(nil, "BACKGROUND")
        middleSel:SetTexture(tabsPath)
        middleSel:SetWidth(1)
        middleSel:SetHeight(selHeight)
        middleSel:SetPoint("TOPLEFT", leftSel, "TOPRIGHT", 0, 0)
        middleSel:SetPoint("TOPRIGHT", rightSel, "TOPLEFT", 0, 0)
        middleSel:SetTexCoord(0, 0.015625, 0.00390625, 0.167969)
        middleSel:Hide()

        -- 高亮
        local hlLeft = tab:CreateTexture(nil, "HIGHLIGHT")
        hlLeft:SetTexture(tabsPath)
        hlLeft:SetWidth(35)
        hlLeft:SetHeight(36)
        hlLeft:SetPoint("TOPLEFT", tab, "TOPLEFT", -3, 0)
        hlLeft:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
        hlLeft:SetBlendMode("ADD")
        hlLeft:SetAlpha(0.4)

        local hlRight = tab:CreateTexture(nil, "HIGHLIGHT")
        hlRight:SetTexture(tabsPath)
        hlRight:SetWidth(37)
        hlRight:SetHeight(36)
        hlRight:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 7, 0)
        hlRight:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
        hlRight:SetBlendMode("ADD")
        hlRight:SetAlpha(0.4)

        local hlMiddle = tab:CreateTexture(nil, "HIGHLIGHT")
        hlMiddle:SetTexture(tabsPath)
        hlMiddle:SetWidth(1)
        hlMiddle:SetHeight(36)
        hlMiddle:SetPoint("TOPLEFT", hlLeft, "TOPRIGHT", 0, 0)
        hlMiddle:SetPoint("TOPRIGHT", hlRight, "TOPLEFT", 0, 0)
        hlMiddle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
        hlMiddle:SetBlendMode("ADD")
        hlMiddle:SetAlpha(0.4)

        -- 文字
        local label = tab:CreateFontString(nil, "BORDER", "GameFontNormalSmall")
        label:SetPoint("CENTER", tab, "CENTER", 0, 2)
        label:SetText(text)
        tab.Text = label

        -- 自动宽度
        if not tabWidth then
            local textWidth = label:GetStringWidth()
            local finalTabWidth = textWidth + 50
            tab:SetWidth(finalTabWidth)
        end

        -- 边缘宽度跟随 tab
        local edgeWidth = tab:GetWidth() / 2
        left:SetWidth(edgeWidth)
        right:SetWidth(edgeWidth)
        leftSel:SetWidth(edgeWidth)
        rightSel:SetWidth(edgeWidth)
        hlLeft:SetWidth(edgeWidth)
        hlRight:SetWidth(edgeWidth)

        function tab:SetSelected(selected)
            if selected then
                left:Hide()
                right:Hide()
                middle:Hide()
                leftSel:Show()
                rightSel:Show()
                middleSel:Show()
                hlLeft:SetHeight(selHeight)
                hlRight:SetHeight(selHeight)
                hlMiddle:SetHeight(selHeight)
                label:SetTextColor(1, 1, 1)
            else
                left:Show()
                right:Show()
                middle:Show()
                leftSel:Hide()
                rightSel:Hide()
                middleSel:Hide()
                hlLeft:SetHeight(36)
                hlRight:SetHeight(36)
                hlMiddle:SetHeight(36)
                label:SetTextColor(1, 0.82, 0)
            end
        end

        function tab:Enable()
            left:SetVertexColor(1, 1, 1)
            right:SetVertexColor(1, 1, 1)
            middle:SetVertexColor(1, 1, 1)
            leftSel:SetVertexColor(1, 1, 1)
            rightSel:SetVertexColor(1, 1, 1)
            middleSel:SetVertexColor(1, 1, 1)
            label:SetTextColor(1, 0.82, 0)
            tab:EnableMouse(1)
        end

        function tab:Disable()
            left:SetVertexColor(0.5, 0.5, 0.5)
            right:SetVertexColor(0.5, 0.5, 0.5)
            middle:SetVertexColor(0.5, 0.5, 0.5)
            leftSel:SetVertexColor(0.5, 0.5, 0.5)
            rightSel:SetVertexColor(0.5, 0.5, 0.5)
            middleSel:SetVertexColor(0.5, 0.5, 0.5)
            label:SetTextColor(0.5, 0.5, 0.5)
            tab:EnableMouse(0)
        end

        -- 定位
        local numTabs = table.getn(frame.Tabs)
        if numTabs == 0 then
            tab:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, -30)
        else
            tab:SetPoint("BOTTOMLEFT", frame.Tabs[numTabs], "BOTTOMRIGHT", (spacing or 4), 0)
        end

        -- 点击处理
        tab:SetScript("OnClick", function()
            PlaySound("igCharacterInfoTab")
            if frame.selectedTab then
                frame.selectedTab:SetSelected(false)
            end
            tab:SetSelected(true)
            frame.selectedTab = tab
            if onClick then onClick() end
        end)

        table.insert(frame.Tabs, tab)

        -- 自动选中第一个
        if numTabs == 0 then
            tab:SetSelected(true)
            frame.selectedTab = tab
        end

        return tab
    end

    return frame
end
