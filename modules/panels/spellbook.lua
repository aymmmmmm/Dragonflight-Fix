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

-- 右侧 Tab 名称匹配（坐骑/小伙伴/玩具）—— 全是 Turtle 服务端 SpellTab，内容由服务端提供
local RIGHT_TAB_KINDS = { "MOUNT", "COMPANION", "TOY" }
local function IsRightTabKind(name, kind)
    if not name then return false end
    if kind == "MOUNT"     then return string.find(name, "坐骑") or string.find(name, "坐騎") or string.find(name, "[Mm]ount") end
    if kind == "COMPANION" then return string.find(name, "小伙伴") or string.find(name, "小夥伴") or string.find(name, "[Cc]ompanion") end
    if kind == "TOY"       then return string.find(name, "玩具") or string.find(name, "[Tt]oy") end
end
local function IsRightSideTabName(name)
    for _, k in ipairs(RIGHT_TAB_KINDS) do
        if IsRightTabKind(name, k) then return true end
    end
end

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

    local BUTTONS_PER_PAGE = 12          -- 单页 6 行 × 2 列
    local COLUMN_SPACING = 220           -- 两列间距，容纳 200 宽容器
    local ROW_SPACING = 72               -- 行间距，需 ≥ 容器高 60 防止重叠

    local spellData = {}

    -- 2. 创建 PaperDollFrame 外框
    local spellbook = DFUI.CreatePaperDollFrame("DFUI_SpellBookFrame", UIParent, 550, 580, 1)
    spellbook:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
    spellbook:SetFrameStrata("MEDIUM")
    spellbook:SetFrameLevel(25)
    spellbook:EnableMouse(true)
    spellbook:SetMovable(true)
    spellbook:RegisterForDrag("LeftButton")
    spellbook:SetScript("OnDragStart", function() spellbook:StartMoving() end)
    spellbook:SetScript("OnDragStop", function() spellbook:StopMovingOrSizing() end)
    spellbook:SetScale(.9)

    -- 3. 页面纹理（retail DF 10.1 原版，两张拼接：Page1 主羊皮纸 + Page2 右侧条）
    -- retail spellbookframe.xml:669-678 精确锚点
    local mainPage = spellbook:CreateTexture(nil, "ARTWORK")
    mainPage:SetTexture(TEX .. "panels\\spellbook_retail_page1.tga")
    mainPage:SetPoint("TOPLEFT", spellbook, "TOPLEFT", 3, -25)  -- 7 → 3，往左拉伸 4
    mainPage:SetWidth(514)  -- 510 + 4，左缘左移 4，右缘不动
    mainPage:SetHeight(571)

    local rightStrip = spellbook:CreateTexture(nil, "ARTWORK")
    rightStrip:SetTexture(TEX .. "panels\\spellbook_retail_page2.tga")
    rightStrip:SetPoint("TOPLEFT", mainPage, "TOPRIGHT", 0, 0)  -- retail 精确：紧贴 page1 右侧
    rightStrip:SetWidth(45)  -- 47 - 2
    rightStrip:SetHeight(571)  -- 同步 mainPage 高度

    -- 4. 职业图标 + 标题
    local classIcon = spellbook:CreateTexture(nil, "OVERLAY")
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
    title:SetTextColor(0.96875, 0.8984375, 0.578125)
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

    -- 状态初始化
    spellbook.selectedTabIndex = 1
    spellbook.currentPage = 1
    spellbook.maxPages = 1
    spellbook.spellButtons = {}
    spellbook.bookType = BOOKTYPE_SPELL
    spellbook.petTab = nil

    -- IsSpellPassive：1.12 无原生 API，用 tooltip 扫描
    local function IsSpellPassive(spellIndex, bookType)
        if not spellIndex then return false end
        local scanner = DFUI_Libs.libtipscan:GetScanner("SpellPassive")
        if bookType == BOOKTYPE_PET then
            scanner:SetPetAction(spellIndex)
        else
            scanner:SetSpell(spellIndex, bookType or BOOKTYPE_SPELL)
        end
        if scanner:FindText("被动") then return true end
        if scanner:FindText("Passive") then return true end
        return false
    end

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
        container:SetWidth(200)
        container:SetHeight(60)

        local iconBtn = CreateFrame("Button", nil, container)
        iconBtn:SetWidth(50)
        iconBtn:SetHeight(50)
        iconBtn:SetPoint("LEFT", container, "LEFT", 5, 0)
        container.iconBtn = iconBtn

        iconBtn.cooldown = CreateFrame("Model", nil, iconBtn, "CooldownFrameTemplate")
        iconBtn.cooldown:SetAllPoints(iconBtn)

        local icon = iconBtn:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints(iconBtn)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        container.icon = icon

        local border = iconBtn:CreateTexture(nil, "ARTWORK")
        border:SetWidth(67)
        border:SetHeight(67)
        border:SetPoint("CENTER", iconBtn, "CENTER", -2, -1)
        container.border = border

        local highlight = iconBtn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture(TEX .. "panels\\spellbook_highlight.blp")
        highlight:SetWidth(67)
        highlight:SetHeight(67)
        highlight:SetPoint("CENTER", iconBtn, "CENTER", 0, 0)
        highlight:SetBlendMode("ADD")
        container.highlight = highlight

        local maxRankHighlight = iconBtn:CreateTexture(nil, "OVERLAY")
        maxRankHighlight:SetTexture(TEX .. "panels\\spellbook_highlight.blp")
        maxRankHighlight:SetWidth(80)
        maxRankHighlight:SetHeight(80)
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
        name:SetTextColor(0.25, 0.12, 0)
        container.name = name

        local passive = container:CreateFontString(nil, "OVERLAY")
        passive:SetFont("Fonts\\FRIZQT__.TTF", 9)
        passive:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, 0)
        passive:SetText("被动")
        passive:SetTextColor(0.25, 0.12, 0)
        passive:Hide()
        container.passive = passive

        local racial = container:CreateFontString(nil, "OVERLAY")
        racial:SetFont("Fonts\\FRIZQT__.TTF", 9)
        racial:SetText("种族技能")
        racial:SetTextColor(0.25, 0.12, 0)
        racial:Hide()
        container.racial = racial

        local rank = container:CreateFontString(nil, "OVERLAY")
        rank:SetFont("Fonts\\FRIZQT__.TTF", 9)
        rank:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, 0)
        rank:SetTextColor(0.25, 0.12, 0)
        rank:Hide()
        container.rank = rank

        iconBtn:SetScript("OnMouseDown", function()
            if container.isPassive then return end
            icon:ClearAllPoints()
            icon:SetWidth(51)
            icon:SetHeight(51)
            icon:SetPoint("CENTER", iconBtn, "CENTER", 2, -2)
            border:ClearAllPoints()
            border:SetPoint("CENTER", iconBtn, "CENTER", -1, -4)
        end)

        iconBtn:SetScript("OnMouseUp", function()
            -- 无条件重置，防止翻页/切过滤后 isPassive 改变导致卡住
            icon:ClearAllPoints()
            icon:SetWidth(50)
            icon:SetHeight(50)
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
        local row = math.floor((i - 1) / 2)
        local col = math.mod(i - 1, 2)
        -- col 0 at x=115, col 1 at x=335（COLUMN_SPACING=220）；首行 y=-75
        btn:SetPoint("TOPLEFT", spellbook, "TOPLEFT", 115 + col * COLUMN_SPACING, -75 - row * ROW_SPACING)
        table.insert(spellbook.spellButtons, btn)
    end

    -- 8. 翻页系统
    local pageText = spellbook:CreateFontString(nil, "OVERLAY")
    pageText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    pageText:SetTextColor(1, 0.82, 0)
    pageText:SetJustifyH("RIGHT")
    pageText:SetPoint("BOTTOMRIGHT", spellbook, "BOTTOMRIGHT", -110, 38)  -- retail 精确
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
                btn.name:SetText(spell.name or "")
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

        -- 重新构建右侧 Tab 索引映射（坐骑/小伙伴/玩具 → SpellTab index）
        spellbook.rightTabIndices = { MOUNT = nil, COMPANION = nil, TOY = nil }

        local numTabs = GetNumSpellTabs()
        local tabMapping = {}
        for tabIndex = 1, numTabs do
            local name, texture, offset, numSpells = GetSpellTabInfo(tabIndex)
            if numSpells and numSpells > 0 and name then
                -- 检查是否是右侧 Tab（坐骑/小伙伴/玩具）
                local rightKind = nil
                for _, k in ipairs(RIGHT_TAB_KINDS) do
                    if IsRightTabKind(name, k) then rightKind = k; break end
                end
                if rightKind then
                    spellbook.rightTabIndices[rightKind] = tabIndex
                else
                    -- 普通底部 Tab
                    name = CleanTurtleTabName(name)
                    name = string.gsub(name, " Combat", "")
                    local capturedIndex = tabIndex
                    local spacing = 2
                    if tabIndex == 2 then
                        spacing = 10
                    end
                    local tab = AcquireTab(name, function()
                        if spellbook.SelectRightTab then spellbook:SelectRightTab(nil) end
                        spellbook.bookType = BOOKTYPE_SPELL
                        spellbook.selectedTabIndex = capturedIndex
                        spellbook.currentPage = 1
                        spellbook:UpdateSpellDisplay()
                    end, 90, spacing)
                    tabMapping[capturedIndex] = tab
                end
            end
        end

        -- 隐藏没有数据的右侧 Tab
        if spellbook.rightTabs then
            for i, t in ipairs(spellbook.rightTabs) do
                if spellbook.rightTabIndices[t.dfuiKind] then
                    t:Show()
                else
                    t:Hide()
                end
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
            if spellbook.SelectRightTab then spellbook:SelectRightTab(nil) end
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
        elseif (prevBookType == BOOKTYPE_SPELL) and type(prevSelectedIndex) == "number" and not tabMapping[prevSelectedIndex] then
            -- 之前停在右侧 Tab（已被过滤出底部 Tab），bookType 仍是 BOOKTYPE_SPELL
            -- 检查 prevSelectedIndex 是否对应某个右侧 kind，并恢复右侧 Tab 视觉
            local prevName = GetSpellTabInfo(prevSelectedIndex)
            if prevName and spellbook.rightTabs then
                for _, k in ipairs(RIGHT_TAB_KINDS) do
                    if IsRightTabKind(prevName, k) and spellbook.rightTabIndices[k] then
                        spellbook.bookType = BOOKTYPE_SPELL
                        spellbook.selectedTabIndex = spellbook.rightTabIndices[k]
                        for ridx, rtab in ipairs(spellbook.rightTabs) do
                            if rtab.dfuiKind == k then
                                spellbook:SelectRightTab(ridx)
                                break
                            end
                        end
                        restored = true
                        break
                    end
                end
            end
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

    prevBtn = CreatePageButton(spellbook, 32, 32, "west")        -- retail 32x32
    prevBtn:SetPoint("BOTTOMRIGHT", spellbook, "BOTTOMRIGHT", -66, 26)  -- retail 精确
    prevBtn:SetScript("OnClick", function()
        if spellbook.currentPage > 1 then
            spellbook.currentPage = spellbook.currentPage - 1
            spellbook:UpdateSpellDisplay()
        end
    end)

    nextBtn = CreatePageButton(spellbook, 32, 32, "east")        -- retail 32x32
    nextBtn:SetPoint("BOTTOMRIGHT", spellbook, "BOTTOMRIGHT", -31, 26)  -- retail 精确
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

    -- 9b. 右侧收藏 Tab（坐骑/小伙伴/玩具）—— 复用底部金属 Tab 素材，旋转 90° 做成竖向
    spellbook.rightTabs = {}
    spellbook.selectedRightTab = nil

    function spellbook:SelectRightTab(idx)
        for i, t in ipairs(spellbook.rightTabs) do
            t:SetSelected(i == idx)
        end
        if idx then
            spellbook.selectedRightTab = spellbook.rightTabs[idx]
        else
            spellbook.selectedRightTab = nil
        end
    end

    -- 复用底部金属 Tab 素材，用 8-arg SetTexCoord 做 90° 旋转
    local tabsPath = TEX .. "interface\\uiframetabs.blp"

    local function CreateVerticalSideTab(text, kind)
        local tab = CreateFrame("Button", nil, spellbook)
        local TAB_W, TAB_H = 36, 90
        tab:SetWidth(TAB_W); tab:SetHeight(TAB_H)
        tab.dfuiKind = kind

        -- top-cap：横向 right 素材 + 90° CW + 180° = 90° CCW（用户调试结论）
        local topCap = tab:CreateTexture(nil, "BACKGROUND")
        topCap:SetTexture(tabsPath); topCap:SetWidth(TAB_W); topCap:SetHeight(36)
        topCap:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
        topCap:SetTexCoord(0.59375, 0.667969,  0.015625, 0.667969,  0.59375, 0.808594,  0.015625, 0.808594)

        -- bot-cap：横向 left 素材（圆角 BL）+ 90° CCW → 圆角落在 BR
        -- 8-arg: ULx ULy LLx LLy URx URy LRx LRy = uMax,vMin  uMin,vMin  uMax,vMax  uMin,vMax
        local botCap = tab:CreateTexture(nil, "BACKGROUND")
        botCap:SetTexture(tabsPath); botCap:SetWidth(TAB_W); botCap:SetHeight(36)
        botCap:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        botCap:SetTexCoord(0.5625, 0.816406,  0.015625, 0.816406,  0.5625, 0.957031,  0.015625, 0.957031)

        -- middle：竖向拉伸的中段（+ 180°）
        local midSeg = tab:CreateTexture(nil, "BACKGROUND")
        midSeg:SetTexture(tabsPath); midSeg:SetWidth(TAB_W)
        midSeg:SetPoint("TOPLEFT", topCap, "BOTTOMLEFT", 0, 0)
        midSeg:SetPoint("BOTTOMRIGHT", botCap, "TOPRIGHT", 0, 0)
        midSeg:SetTexCoord(0.015625, 0.175781,  0, 0.175781,  0.015625, 0.316406,  0, 0.316406)

        -- 选中态：宽度 +3 表现为右侧伸出（动画效果），相当于横向 Tab 的高度 +3
        local topCapSel = tab:CreateTexture(nil, "BACKGROUND")
        topCapSel:SetTexture(tabsPath); topCapSel:SetWidth(TAB_W + 3); topCapSel:SetHeight(36)
        topCapSel:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
        topCapSel:SetTexCoord(0.59375, 0.324219,  0.015625, 0.324219,  0.59375, 0.488281,  0.015625, 0.488281)
        topCapSel:Hide()

        local botCapSel = tab:CreateTexture(nil, "BACKGROUND")
        botCapSel:SetTexture(tabsPath); botCapSel:SetWidth(TAB_W + 3); botCapSel:SetHeight(36)
        botCapSel:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        botCapSel:SetTexCoord(0.5625, 0.496094,  0.015625, 0.496094,  0.5625, 0.660156,  0.015625, 0.660156)
        botCapSel:Hide()

        local midSegSel = tab:CreateTexture(nil, "BACKGROUND")
        midSegSel:SetTexture(tabsPath); midSegSel:SetWidth(TAB_W)
        midSegSel:SetPoint("TOPLEFT", topCapSel, "BOTTOMLEFT", 0, 0)
        midSegSel:SetPoint("BOTTOMRIGHT", botCapSel, "TOPRIGHT", 0, 0)
        midSegSel:SetTexCoord(0.015625, 0.00390625,  0, 0.00390625,  0.015625, 0.167969,  0, 0.167969)
        midSegSel:Hide()

        -- Hover 高亮（叠加同款顶/底 cap）
        local hlTop = tab:CreateTexture(nil, "HIGHLIGHT")
        hlTop:SetTexture(tabsPath); hlTop:SetWidth(TAB_W); hlTop:SetHeight(36)
        hlTop:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
        hlTop:SetTexCoord(0.59375, 0.667969,  0.015625, 0.667969,  0.59375, 0.808594,  0.015625, 0.808594)
        hlTop:SetBlendMode("ADD"); hlTop:SetAlpha(0.4)

        local hlBot = tab:CreateTexture(nil, "HIGHLIGHT")
        hlBot:SetTexture(tabsPath); hlBot:SetWidth(TAB_W); hlBot:SetHeight(36)
        hlBot:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        hlBot:SetTexCoord(0.5625, 0.816406,  0.015625, 0.816406,  0.5625, 0.957031,  0.015625, 0.957031)
        hlBot:SetBlendMode("ADD"); hlBot:SetAlpha(0.4)

        local hlMid = tab:CreateTexture(nil, "HIGHLIGHT")
        hlMid:SetTexture(tabsPath); hlMid:SetWidth(TAB_W)
        hlMid:SetPoint("TOPLEFT", hlTop, "BOTTOMLEFT", 0, 0)
        hlMid:SetPoint("BOTTOMRIGHT", hlBot, "TOPRIGHT", 0, 0)
        hlMid:SetTexCoord(0.015625, 0.175781,  0, 0.175781,  0.015625, 0.316406,  0, 0.316406)
        hlMid:SetBlendMode("ADD"); hlMid:SetAlpha(0.4)

        -- 竖排文字（按 UTF-8 切字符，加 \n 排成竖列）
        local label = tab:CreateFontString(nil, "BORDER", "GameFontNormalSmall")
        label:SetPoint("CENTER", tab, "CENTER", -3, 0)
        label:SetWidth(28)
        label:SetJustifyH("CENTER")

        local stacked = ""
        local i = 1
        while i <= string.len(text) do
            local b = string.byte(text, i)
            local clen = 1
            if b >= 240 then clen = 4
            elseif b >= 224 then clen = 3
            elseif b >= 192 then clen = 2
            end
            local ch = string.sub(text, i, i + clen - 1)
            if stacked == "" then stacked = ch else stacked = stacked .. "\n" .. ch end
            i = i + clen
        end
        label:SetText(stacked)
        label:SetTextColor(1, 0.82, 0)
        tab.Text = label

        function tab:SetSelected(selected)
            if selected then
                topCap:Hide(); midSeg:Hide(); botCap:Hide()
                topCapSel:Show(); midSegSel:Show(); botCapSel:Show()
                label:SetTextColor(1, 1, 1)
            else
                topCap:Show(); midSeg:Show(); botCap:Show()
                topCapSel:Hide(); midSegSel:Hide(); botCapSel:Hide()
                label:SetTextColor(1, 0.82, 0)
            end
        end
        tab:SetSelected(false)

        return tab
    end

    -- 右侧 Tab 创建包 pcall，万一某个 API 在 1.12 不可用，至少法术书本体能加载
    local ok, err = pcall(function()
        local rightTabSpecs = {
            { text = "坐骑",   kind = "MOUNT",     y = -90  },
            { text = "小伙伴", kind = "COMPANION", y = -180 },
            { text = "玩具",   kind = "TOY",       y = -270 },
        }
        for i, spec in ipairs(rightTabSpecs) do
            local tab = CreateVerticalSideTab(spec.text, spec.kind)
            tab:SetPoint("TOPLEFT", spellbook, "TOPRIGHT", 0, spec.y)

            local capturedIndex = i
            local capturedKind = spec.kind
            tab:SetScript("OnClick", function()
                local tabIdx = spellbook.rightTabIndices and spellbook.rightTabIndices[capturedKind]
                if not tabIdx then
                    if DEFAULT_CHAT_FRAME then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[DFUI 法术书]|r 服务端没有 " .. spec.text .. " SpellTab")
                    end
                    return
                end
                PlaySound("igCharacterInfoTab")
                if spellbook.selectedTab then
                    spellbook.selectedTab:SetSelected(false)
                    spellbook.selectedTab = nil
                end
                spellbook:SelectRightTab(capturedIndex)
                spellbook.bookType = BOOKTYPE_SPELL
                spellbook.selectedTabIndex = tabIdx
                spellbook.currentPage = 1
                spellbook:UpdateSpellDisplay()
            end)
            table.insert(spellbook.rightTabs, tab)
        end
    end)
    if not ok and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DFUI 法术书]|r 右侧 Tab 创建失败：" .. tostring(err))
    end

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

    -- 13. 调试 slash 命令：列出所有 SpellTab 名称，方便确认坐骑/小伙伴/玩具的实际 tab 名
    SLASH_DFSBTABS1 = "/dfsbtabs"
    SlashCmdList["DFSBTABS"] = function()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DFUI]|r SpellTabs (" .. GetNumSpellTabs() .. "):")
        for i = 1, GetNumSpellTabs() do
            local n, _, off, ns = GetSpellTabInfo(i)
            DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ": '" .. (n or "?") .. "' offset=" .. (off or 0) .. " count=" .. (ns or 0))
        end
    end

    local callbacks = {}
    DFUI:NewCallbacks("SpellBook", callbacks)
end)
