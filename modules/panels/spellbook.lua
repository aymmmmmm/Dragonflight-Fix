setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

local CLASS_ICON_COORDS = DFUI_CLASS_ICON_COORDS

-- Turtle WoW Tab 名称清理
local function CleanTurtleTabName(name)
    if not name then return name end
    local cleaned = string.gsub(name, '^[Zz]+(%u)', '%1')
    return cleaned
end

-- 翻页按钮工厂
local function CreatePageButton(parent, width, height, direction)
    width = width or 27
    height = height or 27
    direction = direction or "west"

    local normalPath = TEX .. "bags\\expand.tga"
    local bgPath = TEX .. "interface\\chat_btn_bg.blp"

    local coords = {
        east = {1, 0, 1, 1, 0, 0, 0, 1},
        west = {0, 1, 0, 0, 1, 1, 1, 0}
    }

    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetTexture(bgPath)
    bg:SetVertexColor(0, 0, 0, 0.5)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", btn)
    icon:SetWidth(width - 13)
    icon:SetHeight(height - 13)
    icon:SetTexture(normalPath)
    local c = coords[direction]
    icon:SetTexCoord(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8])

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture(normalPath)
    highlight:SetPoint("CENTER", btn)
    highlight:SetWidth(width - 13)
    highlight:SetHeight(height - 13)
    highlight:SetTexCoord(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8])
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0)

    btn:SetScript("OnEnter", function()
        highlight:SetAlpha(1)
    end)
    btn:SetScript("OnLeave", function()
        highlight:SetAlpha(0)
    end)

    return btn
end

local CreateCheckbox = CreatePanelCheckbox

DFUI:NewDefaults("SpellBook", {
    enabled = {true},
    showPassive = {true},
    showRanks = {false},
})

DFUI:NewMod("SpellBook", 5, function()
    -- 1. 禁用原生技能书
    KillFrame(SpellBookFrame)

    -- 显式隐藏原生法术书子元素，防止残留纹理
    for i = 1, 8 do
        local tab = getglobal("SpellBookSkillLineTab" .. i)
        if tab then tab:Hide() end
    end
    for i = 1, 3 do
        local tab = getglobal("SpellBookFrameTabButton" .. i)
        if tab then tab:Hide() end
    end
    if SpellBookTitleText then SpellBookTitleText:Hide() end
    if SpellBookPageText then SpellBookPageText:Hide() end

    local BUTTONS_PER_PAGE = 28
    local COLUMN_SPACING = 165
    local ROW_SPACING = 58

    local spellData = {}

    -- 2. 创建 PaperDollFrame 外框
    local spellbook = DFUI.CreatePaperDollFrame("DFUI_SpellBookFrame", UIParent, 750, 530, 1)
    spellbook:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
    spellbook:SetFrameStrata("MEDIUM")
    spellbook:SetFrameLevel(25)
    spellbook:EnableMouse(true)
    spellbook:SetMovable(true)
    spellbook:RegisterForDrag("LeftButton")
    spellbook:SetScript("OnDragStart", function() spellbook:StartMoving() end)
    spellbook:SetScript("OnDragStop", function() spellbook:StopMovingOrSizing() end)
    spellbook:SetScale(.9)

    -- 3. 页面纹理
    local leftPage = spellbook:CreateTexture(nil, "ARTWORK")
    leftPage:SetTexture(TEX .. "panels\\spellbook_right_page.blp")
    leftPage:SetPoint("TOPLEFT", spellbook, "TOPLEFT", 10, -60)
    leftPage:SetPoint("BOTTOM", spellbook, "BOTTOM", -5, 10)
    leftPage:SetWidth(365)

    local rightPage = spellbook:CreateTexture(nil, "ARTWORK")
    rightPage:SetTexture(TEX .. "panels\\spellbook_left_page.blp")
    rightPage:SetPoint("TOPRIGHT", spellbook, "TOPRIGHT", -10, -60)
    rightPage:SetPoint("BOTTOM", spellbook, "BOTTOM", 5, 10)
    rightPage:SetWidth(365)

    local topWood = spellbook:CreateTexture(nil, "BORDER")
    topWood:SetTexture(TEX .. "panels\\spellbook_top_wood.blp")
    topWood:SetPoint("TOP", spellbook, "TOP", 0, -20)
    topWood:SetWidth(730)
    topWood:SetHeight(64)

    -- 4. 职业图标 + 标题
    local classIcon = spellbook:CreateTexture(nil, "ARTWORK")
    classIcon:SetTexture(TEX .. "ui\\UI-Classes-Circles.tga")
    local _, playerClass = UnitClass("player")
    local coords = CLASS_ICON_COORDS[playerClass]
    if coords then
        classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end
    classIcon:SetPoint("TOPLEFT", spellbook, "TOPLEFT", 0, 3)
    classIcon:SetWidth(52)
    classIcon:SetHeight(52)

    local title = spellbook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText("法术书")
    title:SetTextColor(0.95, 0.90, 0.80)
    title:SetPoint("TOP", spellbook, "TOP", 0, -6)

    -- 5. 关闭按钮
    local closeBtn = DFUI.CreateRedButton(spellbook, "close", function() spellbook:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", spellbook, "TOPRIGHT", 0, -1)

    -- OnShow / OnHide 音效
    spellbook:SetScript("OnShow", function()
        spellbook:ClearAllPoints()
        spellbook:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
        PlaySound("igSpellBookOpen")
        spellbook:UpdateSpellDisplay()
    end)
    spellbook:SetScript("OnHide", function()
        PlaySound("igSpellBookClose")
    end)

    -- 滚轮翻页
    spellbook:EnableMouseWheel(true)
    spellbook:SetScript("OnMouseWheel", function()
        if arg1 > 0 then
            if spellbook.currentPage > 1 then
                spellbook.currentPage = spellbook.currentPage - 1
                spellbook:UpdateSpellDisplay()
            end
        elseif arg1 < 0 then
            if spellbook.currentPage < spellbook.maxPages then
                spellbook.currentPage = spellbook.currentPage + 1
                spellbook:UpdateSpellDisplay()
            end
        end
    end)

    -- 6. 过滤状态（用 boolean 变量，不依赖 widget GetChecked）
    local filterShowPassive = DFUI:GetTempDB("SpellBook", "showPassive")
    if filterShowPassive == nil then filterShowPassive = true end
    local filterShowRanks = DFUI:GetTempDB("SpellBook", "showRanks")
    if filterShowRanks == nil then filterShowRanks = false end

    -- 书签
    local bookmark = spellbook:CreateTexture(nil, "OVERLAY")
    bookmark:SetTexture(TEX .. "panels\\spellbook_bookmark.blp")
    bookmark:SetPoint("TOPRIGHT", leftPage, "TOPRIGHT", 45, 0)
    bookmark:SetWidth(50)
    bookmark:SetHeight(500)

    -- 状态初始化
    spellbook.selectedTabIndex = 1
    spellbook.currentPage = 1
    spellbook.maxPages = 1
    spellbook.spellButtons = {}
    spellbook.bookType = BOOKTYPE_SPELL
    spellbook.petTab = nil

    -- 收集技能数据
    function spellbook:CollectSpells(tabIndex, bookType)
        spellData = {}
        bookType = bookType or BOOKTYPE_SPELL

        if bookType == BOOKTYPE_PET then
            local hasPetSpells, petToken = HasPetSpells()
            if hasPetSpells then
                for i = 1, hasPetSpells do
                    local spellName, spellRank = GetSpellName(i, BOOKTYPE_PET)
                    if spellName then
                        table.insert(spellData, {
                            index = i,
                            name = spellName,
                            rank = spellRank,
                            variant = nil,
                            variantRank = 0,
                            texture = GetSpellTexture(i, BOOKTYPE_PET),
                            isPassive = IsSpellPassive(i, BOOKTYPE_PET),
                            isRacial = false,
                            tabIndex = tabIndex
                        })
                    end
                end
            end
        elseif tabIndex then
            local name, texture, offset, numSpells = GetSpellTabInfo(tabIndex)
            for i = 1, numSpells do
                local spellIndex = offset + i
                local spellName, spellRank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
                if spellName then
                    local variant = nil
                    local cleanName = spellName
                    local variantStart, variantEnd = string.find(spellName, "%((.-)%)")
                    if variantStart then
                        variant = string.sub(spellName, variantStart + 1, variantEnd - 1)
                        cleanName = string.sub(spellName, 1, variantStart - 1)
                        -- 去除尾部空白
                        cleanName = string.gsub(cleanName, "%s+$", "")
                    end
                    local variantRank = 3
                    if variant == "Minor" then
                        variantRank = 1
                    elseif variant == "Lesser" then
                        variantRank = 2
                    elseif variant == "Greater" then
                        variantRank = 4
                    elseif variant == "Major" then
                        variantRank = 5
                    end
                    local isRacial = spellRank and string.find(spellRank, "Racial")
                    table.insert(spellData, {
                        index = spellIndex,
                        name = cleanName,
                        rank = spellRank,
                        variant = variant,
                        variantRank = variantRank,
                        texture = GetSpellTexture(spellIndex, BOOKTYPE_SPELL),
                        isPassive = IsSpellPassive(spellIndex, BOOKTYPE_SPELL),
                        isRacial = isRacial,
                        tabIndex = tabIndex
                    })
                end
            end
        end
    end

    -- 7. 创建技能按钮
    function spellbook:CreateSpellButton(parent)
        local container = CreateFrame("Frame", nil, parent)
        container:SetWidth(160)
        container:SetHeight(42)

        local iconBtn = CreateFrame("Button", nil, container)
        iconBtn:SetWidth(35)
        iconBtn:SetHeight(35)
        iconBtn:SetPoint("LEFT", container, "LEFT", 5, 0)
        container.iconBtn = iconBtn

        iconBtn.cooldown = CreateFrame("Model", nil, iconBtn, "CooldownFrameTemplate")
        iconBtn.cooldown:SetAllPoints(iconBtn)

        local icon = iconBtn:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints(iconBtn)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        container.icon = icon

        local border = iconBtn:CreateTexture(nil, "ARTWORK")
        border:SetWidth(48)
        border:SetHeight(48)
        border:SetPoint("CENTER", iconBtn, "CENTER", -2, -1)
        container.border = border

        local highlight = iconBtn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture(TEX .. "panels\\spellbook_highlight.blp")
        highlight:SetWidth(47)
        highlight:SetHeight(47)
        highlight:SetPoint("CENTER", iconBtn, "CENTER", 0, 0)
        highlight:SetBlendMode("ADD")
        container.highlight = highlight

        local maxRankHighlight = iconBtn:CreateTexture(nil, "OVERLAY")
        maxRankHighlight:SetTexture(TEX .. "panels\\spellbook_highlight.blp")
        maxRankHighlight:SetWidth(57)
        maxRankHighlight:SetHeight(57)
        maxRankHighlight:SetPoint("CENTER", iconBtn, "CENTER", 0, 0)
        maxRankHighlight:SetBlendMode("ADD")
        maxRankHighlight:SetAlpha(.3)
        maxRankHighlight:Hide()
        container.maxRankHighlight = maxRankHighlight

        local name = container:CreateFontString(nil, "OVERLAY")
        name:SetFont("Fonts\\FRIZQT__.TTF", 11)
        name:SetPoint("LEFT", iconBtn, "RIGHT", 5, 0)
        name:SetPoint("RIGHT", container, "RIGHT", -5, 0)
        name:SetJustifyH("LEFT")
        name:SetTextColor(0.15, 0.10, 0.05)
        container.name = name

        local passive = container:CreateFontString(nil, "OVERLAY")
        passive:SetFont("Fonts\\FRIZQT__.TTF", 9)
        passive:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, 0)
        passive:SetText("被动")
        passive:SetTextColor(0.15, 0.10, 0.05)
        passive:Hide()
        container.passive = passive

        local racial = container:CreateFontString(nil, "OVERLAY")
        racial:SetFont("Fonts\\FRIZQT__.TTF", 9)
        racial:SetText("种族技能")
        racial:SetTextColor(0.15, 0.10, 0.05)
        racial:Hide()
        container.racial = racial

        local rank = container:CreateFontString(nil, "OVERLAY")
        rank:SetFont("Fonts\\FRIZQT__.TTF", 9)
        rank:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, 0)
        rank:SetTextColor(0.15, 0.10, 0.05)
        rank:Hide()
        container.rank = rank

        iconBtn:SetScript("OnMouseDown", function()
            if container.isPassive then return end
            icon:ClearAllPoints()
            icon:SetWidth(36)
            icon:SetHeight(36)
            icon:SetPoint("CENTER", iconBtn, "CENTER", 2, -2)
            border:ClearAllPoints()
            border:SetPoint("CENTER", iconBtn, "CENTER", -1, -4)
        end)

        iconBtn:SetScript("OnMouseUp", function()
            -- 无条件重置，防止翻页/切过滤后 isPassive 改变导致卡住
            icon:ClearAllPoints()
            icon:SetWidth(36)
            icon:SetHeight(36)
            icon:SetPoint("CENTER", iconBtn, "CENTER", 0, 0)
            border:ClearAllPoints()
            border:SetPoint("CENTER", iconBtn, "CENTER", -3, -2)
        end)

        iconBtn:SetScript("OnClick", function()
            if container.isPassive then return end
            if container.spellIndex and container.bookType then
                CastSpell(container.spellIndex, container.bookType)
            end
        end)

        iconBtn:SetScript("OnDragStart", function()
            if container.isPassive then return end
            if container.spellIndex and container.bookType then
                PickupSpell(container.spellIndex, container.bookType)
            end
        end)

        iconBtn:SetScript("OnEnter", function()
            if container.spellIndex and container.bookType then
                GameTooltip:SetOwner(iconBtn, "ANCHOR_RIGHT")
                GameTooltip:SetSpell(container.spellIndex, container.bookType)
                GameTooltip:Show()
            end
        end)

        iconBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        iconBtn:RegisterForClicks("LeftButtonUp")
        iconBtn:RegisterForDrag("LeftButton")

        return container
    end

    for i = 1, BUTTONS_PER_PAGE do
        local btn = spellbook:CreateSpellButton(spellbook)

        if i <= 14 then
            local leftRow = math.floor((i - 1) / 2)
            local leftCol = math.mod(i - 1, 2)
            btn:SetPoint("TOPLEFT", leftPage, "TOPLEFT", 50 + leftCol * COLUMN_SPACING, -20 - leftRow * ROW_SPACING)
        else
            local rightRow = math.floor((i - 15) / 2)
            local rightCol = math.mod(i - 15, 2)
            btn:SetPoint("TOPLEFT", rightPage, "TOPLEFT", 50 + rightCol * COLUMN_SPACING, -20 - rightRow * ROW_SPACING)
        end

        table.insert(spellbook.spellButtons, btn)
    end

    -- 8. 翻页系统
    local pageText = spellbook:CreateFontString(nil, "OVERLAY")
    pageText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    pageText:SetTextColor(0.78, 0.57, 0.16)
    pageText:SetJustifyH("RIGHT")
    pageText:SetPoint("BOTTOMRIGHT", rightPage, "BOTTOMRIGHT", -100, 18)
    spellbook.pageText = pageText

    local prevBtn, nextBtn

    function spellbook:UpdateSpellDisplay()
        spellbook:CollectSpells(spellbook.selectedTabIndex, spellbook.bookType)

        local filteredSpells = {}
        for i, spell in ipairs(spellData) do
            if filterShowPassive or not spell.isPassive then
                table.insert(filteredSpells, spell)
            end
        end

        local maxRanks = {}
        for i, spell in ipairs(filteredSpells) do
            -- 不同变体视为不同法术，用 name+variant 作为去重键
            local dedupeKey = spell.name .. "\001" .. (spell.variant or "")
            if not maxRanks[dedupeKey] or spell.index > maxRanks[dedupeKey].index then
                maxRanks[dedupeKey] = spell
            end
        end

        if not filterShowRanks then
            filteredSpells = {}
            for key, spell in pairs(maxRanks) do
                table.insert(filteredSpells, spell)
            end
            table.sort(filteredSpells, function(a, b) return a.index < b.index end)
        end

        spellbook.maxPages = math.ceil(table.getn(filteredSpells) / BUTTONS_PER_PAGE)
        if spellbook.maxPages < 1 then spellbook.maxPages = 1 end
        if spellbook.currentPage > spellbook.maxPages then
            spellbook.currentPage = spellbook.maxPages
        end

        local startIndex = (spellbook.currentPage - 1) * BUTTONS_PER_PAGE + 1
        for i, btn in ipairs(spellbook.spellButtons) do
            local spell = filteredSpells[startIndex + i - 1]
            if spell then
                if spell.texture then btn.icon:SetTexture(spell.texture) end
                btn.name:SetText(spell.name)
                btn.spellIndex = spell.index
                btn.bookType = spellbook.bookType

                local start, duration, enable = GetSpellCooldown(spell.index, spellbook.bookType)
                if btn.iconBtn.cooldown and start and duration then
                    CooldownFrame_SetTimer(btn.iconBtn.cooldown, start, duration, enable)
                end
                local lastAnchor = btn.name
                btn.isPassive = spell.isPassive
                if spell.isPassive then
                    btn.passive:Show()
                    lastAnchor = btn.passive
                    btn.border:SetTexture(TEX .. "panels\\spellbook_passives_border.blp")
                else
                    btn.passive:Hide()
                    btn.border:SetTexture(TEX .. "panels\\spellbook_actives_border.blp")
                end
                if spell.isRacial then
                    btn.racial:ClearAllPoints()
                    btn.racial:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, 0)
                    btn.racial:Show()
                    lastAnchor = btn.racial
                else
                    btn.racial:Hide()
                end
                btn.rank:ClearAllPoints()
                btn.rank:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, 0)
                if spell.isPassive then
                    btn.rank:Hide()
                elseif spell.variant then
                    btn.rank:SetText(spell.variant)
                    btn.rank:Show()
                elseif spell.rank and spell.rank ~= "" and spell.rank ~= "Passive" and spell.rank ~= "Racial" and spell.rank ~= "Racial Passive" then
                    btn.rank:SetText(spell.rank)
                    btn.rank:Show()
                else
                    btn.rank:Hide()
                end

                if spellbook.bookType == BOOKTYPE_SPELL and type(spellbook.selectedTabIndex) == "number" then
                    local tabName = GetSpellTabInfo(spellbook.selectedTabIndex)
                    local isGeneralTab = tabName and string.find(tabName, "General")
                    local dedupeKey = spell.name .. "\001" .. (spell.variant or "")
                    if filterShowRanks and maxRanks[dedupeKey] and maxRanks[dedupeKey].index == spell.index and not isGeneralTab then
                        btn.maxRankHighlight:Show()
                    else
                        btn.maxRankHighlight:Hide()
                    end
                else
                    btn.maxRankHighlight:Hide()
                end

                btn:Show()
            else
                btn.spellIndex = nil
                btn.bookType = nil
                btn.isPassive = nil
                btn:Hide()
            end
        end

        pageText:SetText("第 " .. spellbook.currentPage .. " / " .. spellbook.maxPages .. " 页")

        if spellbook.currentPage <= 1 then
            prevBtn:Disable()
        else
            prevBtn:Enable()
        end

        if spellbook.currentPage >= spellbook.maxPages then
            nextBtn:Disable()
        else
            nextBtn:Enable()
        end
    end

    -- 9. 动态 Tab 系统（池化复用，避免帧泄漏）
    local tabPool = {}
    local tabPoolSize = 0

    local function ReuseTab(tab, text, onClick, spacing)
        -- 更新文本
        tab.Text:SetText(text)
        -- 重新绑定点击回调（闭包需要重新设置）
        tab:SetScript("OnClick", function()
            PlaySound("igCharacterInfoTab")
            if spellbook.selectedTab then
                spellbook.selectedTab:SetSelected(false)
            end
            tab:SetSelected(true)
            spellbook.selectedTab = tab
            if onClick then onClick() end
        end)
        -- 重新定位
        tab:ClearAllPoints()
        local numTabs = table.getn(spellbook.Tabs)
        if numTabs == 0 then
            tab:SetPoint("BOTTOMLEFT", spellbook, "BOTTOMLEFT", 8, -30)
        else
            tab:SetPoint("BOTTOMLEFT", spellbook.Tabs[numTabs], "BOTTOMRIGHT", (spacing or 4), 0)
        end
        tab:SetSelected(false)
        tab:Show()
        table.insert(spellbook.Tabs, tab)
        return tab
    end

    local function AcquireTab(text, onClick, tabWidth, spacing)
        tabPoolSize = tabPoolSize + 1
        local tab = tabPool[tabPoolSize]
        if tab then
            return ReuseTab(tab, text, onClick, spacing)
        else
            tab = spellbook:AddTab(text, onClick, tabWidth, spacing)
            tabPool[tabPoolSize] = tab
            return tab
        end
    end

    local function ReleaseAllTabs()
        for i = 1, tabPoolSize do
            tabPool[i]:SetSelected(false)
            tabPool[i]:Hide()
        end
        spellbook.Tabs = {}
        spellbook.selectedTab = nil
        tabPoolSize = 0
    end

    function spellbook:CreateDynamicTabs()
        local prevSelectedIndex = spellbook.selectedTabIndex
        local prevBookType = spellbook.bookType

        ReleaseAllTabs()

        local numTabs = GetNumSpellTabs()
        local tabMapping = {}
        for tabIndex = 1, numTabs do
            local name, texture, offset, numSpells = GetSpellTabInfo(tabIndex)
            if numSpells > 0 then
                name = CleanTurtleTabName(name)
                name = string.gsub(name, " Combat", "")
                local capturedIndex = tabIndex
                local spacing = 2
                if tabIndex == 2 then
                    spacing = 10
                end
                local tab = AcquireTab(name, function()
                    spellbook.bookType = BOOKTYPE_SPELL
                    spellbook.selectedTabIndex = capturedIndex
                    spellbook.currentPage = 1
                    spellbook:UpdateSpellDisplay()
                end, 90, spacing)
                tabMapping[capturedIndex] = tab
            end
        end

        local hasPetSpells, petToken = HasPetSpells()
        local petTabText = "宠物"
        if petToken then
            local petTypeName = getglobal("PET_TYPE_" .. petToken)
            if petTypeName then
                petTabText = petTypeName
            end
        end

        spellbook.petTab = AcquireTab(petTabText, function()
            spellbook.bookType = BOOKTYPE_PET
            spellbook.selectedTabIndex = "pet"
            spellbook.currentPage = 1
            spellbook:UpdateSpellDisplay()
        end, 50, 10)

        spellbook:UpdatePetTab()

        -- 恢复之前选中的标签页，找不到则回退到第一个
        local restored = false
        if prevBookType == BOOKTYPE_PET and spellbook.petTab:IsShown() then
            spellbook.petTab:SetSelected(true)
            spellbook.selectedTab = spellbook.petTab
            spellbook.bookType = BOOKTYPE_PET
            spellbook.selectedTabIndex = "pet"
            restored = true
        elseif prevBookType == BOOKTYPE_SPELL and type(prevSelectedIndex) == "number" and tabMapping[prevSelectedIndex] then
            tabMapping[prevSelectedIndex]:SetSelected(true)
            spellbook.selectedTab = tabMapping[prevSelectedIndex]
            spellbook.bookType = BOOKTYPE_SPELL
            spellbook.selectedTabIndex = prevSelectedIndex
            restored = true
        end

        if not restored and spellbook.Tabs[1] then
            spellbook.Tabs[1]:SetSelected(true)
            spellbook.selectedTab = spellbook.Tabs[1]
            spellbook.selectedTabIndex = 1
            spellbook.bookType = BOOKTYPE_SPELL
        end
    end

    function spellbook:UpdatePetTab()
        if not spellbook.petTab then return end
        local hasPet, token = HasPetSpells()
        if hasPet then
            if token then
                local petTypeName = getglobal("PET_TYPE_" .. token)
                if petTypeName and spellbook.petTab.Text then
                    spellbook.petTab.Text:SetText(petTypeName)
                end
            end
            spellbook.petTab:Show()
        else
            spellbook.petTab:Hide()
            -- 如果当前正在查看宠物标签，切回第一个法术标签
            if spellbook.bookType == BOOKTYPE_PET and spellbook.Tabs[1] then
                spellbook.Tabs[1]:SetSelected(true)
                spellbook.selectedTab = spellbook.Tabs[1]
                spellbook.selectedTabIndex = 1
                spellbook.bookType = BOOKTYPE_SPELL
                spellbook.currentPage = 1
            end
        end
    end

    prevBtn = CreatePageButton(spellbook, 27, 27, "west")
    prevBtn:SetPoint("BOTTOMRIGHT", rightPage, "BOTTOMRIGHT", -60, 10)
    prevBtn:SetScript("OnClick", function()
        if spellbook.currentPage > 1 then
            spellbook.currentPage = spellbook.currentPage - 1
            spellbook:UpdateSpellDisplay()
        end
    end)

    nextBtn = CreatePageButton(spellbook, 27, 27, "east")
    nextBtn:SetPoint("BOTTOMRIGHT", rightPage, "BOTTOMRIGHT", -20, 10)
    nextBtn:SetScript("OnClick", function()
        if spellbook.currentPage < spellbook.maxPages then
            spellbook.currentPage = spellbook.currentPage + 1
            spellbook:UpdateSpellDisplay()
        end
    end)

    -- 复选框创建（OnClick 翻转 boolean → 刷新，不依赖 GetChecked）
    local showPassiveCheckbox = CreateCheckbox(spellbook, "显示被动技能")
    showPassiveCheckbox:SetPoint("BOTTOMLEFT", spellbook, "BOTTOMLEFT", 15, 8)
    showPassiveCheckbox:SetFrameLevel(spellbook:GetFrameLevel() + 10)
    showPassiveCheckbox:SetChecked(filterShowPassive)
    showPassiveCheckbox:SetScript("OnClick", function()
        filterShowPassive = not filterShowPassive
        showPassiveCheckbox:SetChecked(filterShowPassive)
        DFUI:SetTempDB("SpellBook", "showPassive", filterShowPassive)
        PlaySound(filterShowPassive and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        spellbook.currentPage = 1
        spellbook:UpdateSpellDisplay()
    end)

    local showRanksCheckbox = CreateCheckbox(spellbook, "显示法术等级")
    showRanksCheckbox:SetPoint("LEFT", showPassiveCheckbox, "RIGHT", 100, 0)
    showRanksCheckbox:SetFrameLevel(spellbook:GetFrameLevel() + 10)
    showRanksCheckbox:SetChecked(filterShowRanks)
    showRanksCheckbox:SetScript("OnClick", function()
        filterShowRanks = not filterShowRanks
        showRanksCheckbox:SetChecked(filterShowRanks)
        DFUI:SetTempDB("SpellBook", "showRanks", filterShowRanks)
        PlaySound(filterShowRanks and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        spellbook.currentPage = 1
        spellbook:UpdateSpellDisplay()
    end)

    spellbook:CreateDynamicTabs()
    spellbook:UpdateSpellDisplay()
    spellbook:Hide()

    -- 10. 事件注册
    spellbook:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    spellbook:RegisterEvent("PET_BAR_UPDATE")
    spellbook:RegisterEvent("UNIT_PET")
    spellbook:RegisterEvent("SPELLS_CHANGED")
    spellbook:SetScript("OnEvent", function()
        if event == "SPELL_UPDATE_COOLDOWN" then
            for i, btn in ipairs(spellbook.spellButtons) do
                if btn.spellIndex and btn:IsShown() and btn.bookType then
                    local start, duration, enable = GetSpellCooldown(btn.spellIndex, btn.bookType)
                    if btn.iconBtn.cooldown then
                        CooldownFrame_SetTimer(btn.iconBtn.cooldown, start, duration, enable)
                    end
                end
            end
        elseif event == "SPELLS_CHANGED" then
            spellbook:CreateDynamicTabs()
            if spellbook:IsShown() then
                spellbook:UpdateSpellDisplay()
            end
        elseif event == "PET_BAR_UPDATE" or (event == "UNIT_PET" and arg1 == "player") then
            if spellbook.UpdatePetTab then
                spellbook:UpdatePetTab()
            end
            if spellbook.bookType == BOOKTYPE_PET and spellbook:IsShown() then
                spellbook:UpdateSpellDisplay()
            end
        end
    end)

    -- 11. 覆写全局 ToggleSpellBook
    _G.ToggleSpellBook = function(bookType)
        if spellbook:IsShown() then
            spellbook:Hide()
        else
            if bookType == BOOKTYPE_PET and spellbook.petTab and spellbook.petTab:IsShown() then
                if spellbook.selectedTab then
                    spellbook.selectedTab:SetSelected(false)
                end
                spellbook.petTab:SetSelected(true)
                spellbook.selectedTab = spellbook.petTab
                spellbook.bookType = BOOKTYPE_PET
                spellbook.selectedTabIndex = "pet"
                spellbook.currentPage = 1
            end
            spellbook:Show()
        end
    end

    -- 12. ESC 关闭
    table.insert(UISpecialFrames, spellbook:GetName())

    local callbacks = {}
    DFUI:NewCallbacks("SpellBook", callbacks)
end)
