setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

local CLASS_ICON_COORDS = DFUI_CLASS_ICON_COORDS

-- 文案集中表（未来迁移到 locales/ 时按此 key 移植）
local L = {
    TITLE = "法术书",
    PASSIVE = "被动",
    RACIAL = "种族技能",
    PET = "宠物",
    SHOW_PASSIVE = "显示被动技能",
    SHOW_RANKS = "显示法术等级",
    MOUNT = "坐骑",
    COMPANION = "小伙伴",
    TOY = "玩具",
    ERR_PREFIX = "|cFFFF8800[DFUI 法术书]|r",
    ERR_PREFIX_RED = "|cFFFF0000[DFUI 法术书]|r",
    ERR_NO_RIGHT_TAB = " 服务端没有 %s SpellTab",
    ERR_RIGHT_TAB_FAIL = " 右侧 Tab 创建失败：",
    PAGE_FMT = "第 %d / %d 页",
}

-- Turtle WoW Tab 名称清理
local function CleanTurtleTabName(name)
    if not name then return name end
    local cleaned = string.gsub(name, '^[Zz]+(%u)', '%1')
    return cleaned
end

-- 翻页按钮工厂：vanilla 原生 UI-SpellbookIcon 三态贴图
local function CreatePageButton(parent, direction)
    -- direction: "prev" 或 "next"
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(32)
    btn:SetHeight(32)
    -- 半透明深色底框，做"嵌进去"反差让箭头浮起来
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(TEX .. "interface\\chat_btn_bg.blp")
    bg:SetAllPoints(btn)
    bg:SetVertexColor(0, 0, 0, 0.5)
    -- 1.12 vanilla 客户端原生带 UI-SpellbookIcon-{Prev,Next}Page-*.blp
    local cap = direction == "prev" and "Prev" or "Next"
    btn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. cap .. "Page-Up")
    btn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. cap .. "Page-Down")
    btn:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. cap .. "Page-Disabled")
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
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
    -- 1. 透明保活原生技能书：不 Hide，保留在 UIPanel 系统以参与 left 区互斥（与制造面板同机制）
    SoftHideFrame(SpellBookFrame)
    -- 清原生事件与 OnShow/OnHide：避免 vanilla 重复播放 igSpellBookOpen 及无谓的 SpellBookFrame_Update 开销
    SpellBookFrame:UnregisterAllEvents()
    SpellBookFrame:SetScript("OnShow", nil)
    SpellBookFrame:SetScript("OnHide", nil)

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
    local COLUMN_SPACING = 225           -- retail spellbookframe.xml: 第二列 x=225
    local ROW_SPACING = 72               -- 容器 60 高 + 行间隙 12

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
    title:SetText(L.TITLE)
    title:SetTextColor(0.96875, 0.8984375, 0.578125)
    title:SetPoint("TOP", spellbook, "TOP", 0, -6)

    -- 5. 关闭按钮
    local closeBtn = DFUI.CreateRedButton(spellbook, "close", function() HideUIPanel(SpellBookFrame) end)
    closeBtn:SetPoint("TOPRIGHT", spellbook, "TOPRIGHT", 0, -1)

    -- OnShow / OnHide 音效
    spellbook:SetScript("OnShow", function()
        spellbook:ClearAllPoints()
        spellbook:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
        PlaySound("igSpellBookOpen")
        if spellbook.RebuildActionBindMap then spellbook:RebuildActionBindMap() end
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

    -- 新学法术高亮：跨会话持久化 known/new 集合。knownSpells 首次为 nil（防止 NewMod 早期 API 未就绪），
    -- 由 UpdateSpellDisplay/SPELLS_CHANGED 首次触发时 lazy 建立 → 首次安装时所有 spell 都算"已知"不闪。
    local function BuildKnownSpellSet()
        local set = {}
        for tab = 1, GetNumSpellTabs() do
            local _, _, offset, num = GetSpellTabInfo(tab)
            if offset and num then
                for i = 1, num do
                    local n = GetSpellName(offset + i, BOOKTYPE_SPELL)
                    if n then set[n] = true end
                end
            end
        end
        return set
    end

    local knownSpells = DFUI:GetTempDB("SpellBook", "knownSpells")
    local newSpells = DFUI:GetTempDB("SpellBook", "newSpells") or {}

    -- 仅在法术 API 就绪（扫得到法术）时建立基线；空表/nil 都视为"未建立"。
    -- 关键：ADDON_LOADED 阶段 API 未就绪会建出空集基线，导致随后 SPELLS_CHANGED 把全部法术
    -- 误判为"新学"全部点亮。这里用 next() 判有效，未就绪直接 return 留待下次重试；
    -- 首次成功建立时顺带清空 newSpells（此前累积的都是误判残留，不可信）。
    local function EnsureBaseline()
        if knownSpells and next(knownSpells) then return end
        local set = BuildKnownSpellSet()
        if not set or not next(set) then return end
        knownSpells = set
        newSpells = {}
        DFUI:SetTempDB("SpellBook", "knownSpells", knownSpells)
        DFUI:SetTempDB("SpellBook", "newSpells", newSpells)
    end

    local function ClearNewSpellMark(spellName)
        if spellName and newSpells[spellName] then
            newSpells[spellName] = nil
            DFUI:SetTempDB("SpellBook", "newSpells", newSpells)
        end
    end

    -- 法术键位绑定提示：反查 ActionBar 60 个 slot 建立 spellName → 绑定键映射
    -- 性能策略：仅在法术书可见时响应 ACTIONBAR_SLOT_CHANGED / UPDATE_BINDINGS
    -- Tooltip 扫描走 libtipscan（与 IsSpellPassive 复用同一基础设施，避免手写 GameTooltip 状态管理）
    spellbook.actionBindMap = {}

    local SLOT_TO_BINDING = {}
    for i = 1, 12 do SLOT_TO_BINDING[i]      = "ACTIONBUTTON" .. i end          -- 主栏 1-12
    for i = 1, 12 do SLOT_TO_BINDING[i + 24] = "MULTIACTIONBAR3BUTTON" .. i end  -- 右栏1 slot 25-36
    for i = 1, 12 do SLOT_TO_BINDING[i + 36] = "MULTIACTIONBAR4BUTTON" .. i end  -- 右栏2 slot 37-48
    for i = 1, 12 do SLOT_TO_BINDING[i + 48] = "MULTIACTIONBAR2BUTTON" .. i end  -- 底栏2 slot 49-60
    for i = 1, 12 do SLOT_TO_BINDING[i + 72] = "MULTIACTIONBAR1BUTTON" .. i end  -- 底栏1 slot 73-84

    function spellbook:RebuildActionBindMap()
        for k in pairs(spellbook.actionBindMap) do spellbook.actionBindMap[k] = nil end
        local scanner = DFUI_Libs.libtipscan:GetScanner("SpellBookActionScan")
        for slot, binding in pairs(SLOT_TO_BINDING) do
            if HasAction(slot) then
                scanner:SetAction(slot)
                local spellName = scanner:GetLine(1)  -- 第一行 leftText 即 spell/item 名
                if spellName and spellName ~= "" then
                    local key1 = GetBindingKey(binding)
                    if key1 and key1 ~= "" then
                        if GetBindingText then key1 = GetBindingText(key1, "KEY_") end
                        -- 同名多绑只保留第一个找到的（vanilla 行为）
                        if not spellbook.actionBindMap[spellName] then
                            spellbook.actionBindMap[spellName] = key1
                        end
                    end
                end
            end
        end
    end

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
                            isPassive = IsSpellPassive(i, BOOKTYPE_PET)
                                or (spellRank and (string.find(spellRank, "Passive") or string.find(spellRank, "被动"))) and true or false,
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
                        isPassive = IsSpellPassive(spellIndex, BOOKTYPE_SPELL)
                            or (spellRank and (string.find(spellRank, "Passive") or string.find(spellRank, "被动"))) and true or false,
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
        iconBtn:SetWidth(48)
        iconBtn:SetHeight(48)
        iconBtn:SetPoint("LEFT", container, "LEFT", 5, 5)
        container.iconBtn = iconBtn

        iconBtn.cooldown = CreateFrame("Model", nil, iconBtn, "CooldownFrameTemplate")
        iconBtn.cooldown:SetAllPoints(iconBtn)

        local icon = iconBtn:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints(iconBtn)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        container.icon = icon

        -- retail Spellbook-SlotFrame：图标外框 atlas (0.00390625, 0.27734375, 0.44140625, 0.69531250) = 70×65 native
        -- 等比放大到 91×84 让内部坑位匹配 48×48 icon (retail 70×65 配 37×37，比例 1.892/1.757)
        local border = iconBtn:CreateTexture(nil, "ARTWORK")
        border:SetTexture(TEX .. "panels\\spellbook_parts.tga")
        border:SetTexCoord(0.00390625, 0.27734375, 0.44140625, 0.69531250)
        border:SetWidth(91)
        border:SetHeight(84)
        border:SetPoint("CENTER", iconBtn, "CENTER", 1, 0)
        container.border = border

        -- hover：脱离 widget HIGHLIGHT 图层（PUSHED 状态会自动隐藏 HIGHLIGHT 层，
        -- 被动按下时会闪烁），改用 OVERLAY 层 + OnEnter/OnLeave 手动驱动。
        -- 贴图：vanilla 1.12 客户端 MPQ 自带的 ButtonHilight-Square（蓝白软方框 halo，BLP1+alpha 原生支持）。
        -- SetAllPoints 跟 iconBtn 1:1：vanilla 设计 halo 边缘就在贴图边缘，按钮尺寸放大缩小都贴边。
        -- 不能用 retail 抠出来的同名 BLP——retail 重制成 DXT1 无 alpha BLP2，1.12 读不了。
        local highlight = iconBtn:CreateTexture(nil, "OVERLAY")
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetAllPoints(iconBtn)
        highlight:SetBlendMode("ADD")
        highlight:Hide()
        container.highlight = highlight

        -- 手动控制按下闪（OnMouseDown/Up 里 show/hide），不用 Button.PushedTexture
        local pushedFlash = iconBtn:CreateTexture(nil, "OVERLAY")
        pushedFlash:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        pushedFlash:SetAllPoints(iconBtn)
        pushedFlash:SetBlendMode("ADD")
        pushedFlash:Hide()
        container.pushedFlash = pushedFlash

        -- 新学法术金色 glow：frame 容器贴齐图标边缘，内叠多层 ButtonHilight-Square 染金增亮
        -- （叠层数控制亮度，frame 包让 Show/Hide 联动且层级在最上）
        local newGlow = CreateFrame("Frame", nil, iconBtn)
        newGlow:SetPoint("TOPLEFT", iconBtn, "TOPLEFT", -2, 2)          -- 四周外扩 2px，光圈比图标大一圈
        newGlow:SetPoint("BOTTOMRIGHT", iconBtn, "BOTTOMRIGHT", 2, -2)
        newGlow:SetFrameLevel(iconBtn:GetFrameLevel() + 5)
        for _ = 1, 3 do
            local g = newGlow:CreateTexture(nil, "OVERLAY")
            g:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
            g:SetAllPoints(newGlow)
            g:SetBlendMode("ADD")
            g:SetVertexColor(1, 0.82, 0)  -- 去蓝染金，与 hover 蓝白拉开区分
            g:SetAlpha(0.8)               -- 总亮度 ≈ 2.4 层，落在 2 层(暗)与 3 层(亮)之间；调此值控亮度
        end
        newGlow:Hide()
        container.newGlow = newGlow

        -- 键位绑定提示（右下角小字，描边方便在任意图标底色上可读）
        local bindKey = container:CreateFontString(nil, "OVERLAY")
        bindKey:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        bindKey:SetTextColor(1, 1, 0.6)
        bindKey:SetJustifyH("RIGHT")
        bindKey:SetPoint("BOTTOMRIGHT", iconBtn, "BOTTOMRIGHT", -1, 2)
        bindKey:Hide()
        container.bindKey = bindKey

        -- retail Spellbook-TextBackground：技能名/说明渐变浅黑遮罩，叠两层达到 retail 浓度
        -- atlas (0.31250, 0.96484, 0.37109, 0.52344) = 167×39，按 DF-Fix 图标 50×50 (retail 37×37) 比例放大
        for layer = 1, 2 do
            local textBg = container:CreateTexture(nil, "BACKGROUND")
            textBg:SetTexture(TEX .. "panels\\spellbook_parts.tga")
            textBg:SetTexCoord(0.31250, 0.96484, 0.37109, 0.52344)
            textBg:SetWidth(200)
            textBg:SetHeight(50)
            textBg:SetPoint("TOPLEFT", iconBtn, "TOPRIGHT", -4, -1)
            container["textBg" .. layer] = textBg
        end

        local name = container:CreateFontString(nil, "OVERLAY")
        name:SetFont("Fonts\\FRIZQT__.TTF", 14)
        name:SetPoint("LEFT", iconBtn, "RIGHT", 12, 8)
        name:SetPoint("RIGHT", container, "RIGHT", -5, 0)
        name:SetJustifyH("LEFT")
        name:SetTextColor(1.0, 0.82, 0)
        container.name = name

        local passive = container:CreateFontString(nil, "OVERLAY")
        passive:SetFont("Fonts\\FRIZQT__.TTF", 8)
        passive:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
        passive:SetText(L.PASSIVE)
        passive:SetTextColor(0.85, 0.70, 0.20)
        passive:Hide()
        container.passive = passive

        local racial = container:CreateFontString(nil, "OVERLAY")
        racial:SetFont("Fonts\\FRIZQT__.TTF", 8)
        racial:SetText(L.RACIAL)
        racial:SetTextColor(0.85, 0.70, 0.20)
        racial:Hide()
        container.racial = racial

        local rank = container:CreateFontString(nil, "OVERLAY")
        rank:SetFont("Fonts\\FRIZQT__.TTF", 8)
        rank:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
        rank:SetTextColor(0.85, 0.70, 0.20)
        rank:Hide()
        container.rank = rank

        iconBtn:SetScript("OnMouseDown", function()
            if container.isPassive then return end
            icon:ClearAllPoints()
            icon:SetWidth(49)
            icon:SetHeight(49)
            icon:SetPoint("CENTER", iconBtn, "CENTER", 1, -1)
            border:ClearAllPoints()
            border:SetPoint("CENTER", iconBtn, "CENTER", 2, -2)
            -- pushedFlash 用 SetAllPoints 常驻 iconBtn，只需 Show；不改锚点避免丢尺寸
            pushedFlash:Show()
        end)

        iconBtn:SetScript("OnMouseUp", function()
            -- 被动不响应：完全无视觉变化（边界态由 UpdateSpellDisplay 重画时归零兜底）
            if container.isPassive then return end
            icon:ClearAllPoints()
            icon:SetWidth(48)
            icon:SetHeight(48)
            icon:SetPoint("CENTER", iconBtn, "CENTER", 0, 0)
            border:ClearAllPoints()
            border:SetPoint("CENTER", iconBtn, "CENTER", 1, 0)
            pushedFlash:Hide()
        end)

        iconBtn:SetScript("OnClick", function()
            if container.isPassive then return end
            if container.spellIndex and container.bookType then
                CastSpell(container.spellIndex, container.bookType)
            end
            ClearNewSpellMark(container.spellName)
            if container.newGlow then container.newGlow:Hide() end
        end)

        iconBtn:SetScript("OnDragStart", function()
            if container.isPassive then return end
            if container.spellIndex and container.bookType then
                PickupSpell(container.spellIndex, container.bookType)
            end
        end)

        iconBtn:SetScript("OnEnter", function()
            highlight:Show()
            if container.spellIndex and container.bookType then
                GameTooltip:SetOwner(iconBtn, "ANCHOR_RIGHT")
                GameTooltip:SetSpell(container.spellIndex, container.bookType)
                GameTooltip:Show()
            end
            -- "查看即清"：鼠标悬停查看 tooltip 视为已知，下次打开不再高亮
            ClearNewSpellMark(container.spellName)
            if container.newGlow then container.newGlow:Hide() end
        end)

        iconBtn:SetScript("OnLeave", function()
            highlight:Hide()
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
        -- 首格 TOPLEFT(115, -75)，COLUMN_SPACING=225 / ROW_SPACING=72 容纳 60 高容器
        btn:SetPoint("TOPLEFT", spellbook, "TOPLEFT", 115 + col * COLUMN_SPACING, -75 - row * ROW_SPACING)
        table.insert(spellbook.spellButtons, btn)
    end

    -- 8. 翻页系统
    local pageText = spellbook:CreateFontString(nil, "OVERLAY", "GameFontBlack")
    pageText:SetTextColor(0.25, 0.12, 0)
    pageText:SetJustifyH("RIGHT")
    pageText:SetPoint("BOTTOMRIGHT", spellbook, "BOTTOMRIGHT", -110, 38)  -- retail 精确
    spellbook.pageText = pageText

    local prevBtn, nextBtn

    function spellbook:UpdateSpellDisplay()
        -- 建立 knownSpells 基线（仅 API 就绪时生效，未就绪留待 SPELLS_CHANGED 重试）
        EnsureBaseline()
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
                -- 重画前归零 icon/border 位置，兜底"按住时翻页/切过滤"的卡位
                btn.icon:ClearAllPoints()
                btn.icon:SetWidth(48)
                btn.icon:SetHeight(48)
                btn.icon:SetPoint("CENTER", btn.iconBtn, "CENTER", 0, 0)
                btn.border:ClearAllPoints()
                btn.border:SetPoint("CENTER", btn.iconBtn, "CENTER", 1, 0)
                btn.pushedFlash:Hide()
                btn.highlight:Hide()

                if spell.texture then btn.icon:SetTexture(spell.texture) end
                btn.name:SetText(spell.name or "")
                btn.spellIndex = spell.index
                btn.bookType = spellbook.bookType
                btn.spellName = spell.name

                -- 新学法术高亮：仅玩家法术（非宠物）按 name 比对 newSpells 集合
                if btn.newGlow then
                    if spellbook.bookType ~= BOOKTYPE_PET and spell.name and newSpells[spell.name] then
                        btn.newGlow:Show()
                    else
                        btn.newGlow:Hide()
                    end
                end

                -- 键位绑定提示（仅玩家法术，宠物动作另有 PetActionBar 不在反查范围）
                if btn.bindKey then
                    local k = spellbook.bookType ~= BOOKTYPE_PET and spell.name and spellbook.actionBindMap[spell.name]
                    if k then
                        btn.bindKey:SetText(k)
                        btn.bindKey:Show()
                    else
                        btn.bindKey:Hide()
                    end
                end

                local start, duration, enable = GetSpellCooldown(spell.index, spellbook.bookType)
                if btn.iconBtn.cooldown and start and duration and enable ~= nil then
                    CooldownFrame_SetTimer(btn.iconBtn.cooldown, start, duration, enable)
                end
                local lastAnchor = btn.name
                btn.isPassive = spell.isPassive
                if spell.isPassive then
                    btn.passive:Show()
                    lastAnchor = btn.passive
                else
                    btn.passive:Hide()
                end
                if spell.isRacial then
                    btn.racial:ClearAllPoints()
                    btn.racial:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -3)
                    btn.racial:Show()
                    lastAnchor = btn.racial
                else
                    btn.racial:Hide()
                end
                btn.rank:ClearAllPoints()
                btn.rank:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -3)
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

                btn:Show()
            else
                btn.spellIndex = nil
                btn.bookType = nil
                btn.isPassive = nil
                btn:Hide()
            end
        end

        pageText:SetText(string.format(L.PAGE_FMT, spellbook.currentPage, spellbook.maxPages))

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

        -- 隐藏没有数据的右侧 Tab，并把可见 Tab 紧凑重锚到 -90/-180/-270 槽位
        -- spellbook.rightTabs 创建顺序 = MOUNT/COMPANION/TOY，按 ipairs 遍历天然保持优先级
        if spellbook.rightTabs then
            local Y_SLOTS = { -90, -180, -270 }
            local visibleSlot = 0
            for i, t in ipairs(spellbook.rightTabs) do
                if spellbook.rightTabIndices[t.dfuiKind] then
                    visibleSlot = visibleSlot + 1
                    t:ClearAllPoints()
                    t:SetPoint("TOPLEFT", spellbook, "TOPRIGHT", 0, Y_SLOTS[visibleSlot])
                    t:Show()
                else
                    t:Hide()
                end
            end
        end

        local hasPetSpells, petToken = HasPetSpells()
        local petTabText = L.PET
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

    prevBtn = CreatePageButton(spellbook, "prev")
    prevBtn:SetPoint("BOTTOMRIGHT", spellbook, "BOTTOMRIGHT", -66, 26)  -- retail 精确
    prevBtn:SetScript("OnClick", function()
        if spellbook.currentPage > 1 then
            spellbook.currentPage = spellbook.currentPage - 1
            spellbook:UpdateSpellDisplay()
        end
    end)

    nextBtn = CreatePageButton(spellbook, "next")
    nextBtn:SetPoint("BOTTOMRIGHT", spellbook, "BOTTOMRIGHT", -31, 26)  -- retail 精确
    nextBtn:SetScript("OnClick", function()
        if spellbook.currentPage < spellbook.maxPages then
            spellbook.currentPage = spellbook.currentPage + 1
            spellbook:UpdateSpellDisplay()
        end
    end)

    -- 复选框创建（OnClick 翻转 boolean → 刷新，不依赖 GetChecked）
    local showPassiveCheckbox = CreateCheckbox(spellbook, L.SHOW_PASSIVE)
    showPassiveCheckbox:SetPoint("BOTTOMLEFT", spellbook, "BOTTOMLEFT", 15, 8)
    showPassiveCheckbox:SetFrameLevel(spellbook:GetFrameLevel() + 5)
    showPassiveCheckbox:SetChecked(filterShowPassive)
    showPassiveCheckbox:SetScript("OnClick", function()
        filterShowPassive = not filterShowPassive
        showPassiveCheckbox:SetChecked(filterShowPassive)
        DFUI:SetTempDB("SpellBook", "showPassive", filterShowPassive)
        PlaySound(filterShowPassive and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        spellbook.currentPage = 1
        spellbook:UpdateSpellDisplay()
    end)

    local showRanksCheckbox = CreateCheckbox(spellbook, L.SHOW_RANKS)
    showRanksCheckbox:SetPoint("LEFT", showPassiveCheckbox, "RIGHT", 100, 0)
    showRanksCheckbox:SetFrameLevel(spellbook:GetFrameLevel() + 5)
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
        if not text or text == "" then return nil end
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
            { text = L.MOUNT,     kind = "MOUNT",     y = -90  },
            { text = L.COMPANION, kind = "COMPANION", y = -180 },
            { text = L.TOY,       kind = "TOY",       y = -270 },
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
                        DEFAULT_CHAT_FRAME:AddMessage(L.ERR_PREFIX .. string.format(L.ERR_NO_RIGHT_TAB, spec.text))
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
        DEFAULT_CHAT_FRAME:AddMessage(L.ERR_PREFIX_RED .. L.ERR_RIGHT_TAB_FAIL .. tostring(err))
    end

    spellbook:CreateDynamicTabs()
    spellbook:UpdateSpellDisplay()
    spellbook:Hide()

    -- 10. 事件注册
    spellbook:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    spellbook:RegisterEvent("PET_BAR_UPDATE")
    spellbook:RegisterEvent("UNIT_PET")
    spellbook:RegisterEvent("SPELLS_CHANGED")
    spellbook:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    spellbook:RegisterEvent("UPDATE_BINDINGS")
    spellbook:SetScript("OnEvent", function()
        if event == "SPELL_UPDATE_COOLDOWN" then
            for i, btn in ipairs(spellbook.spellButtons) do
                if btn.spellIndex and btn:IsShown() and btn.bookType then
                    local start, duration, enable = GetSpellCooldown(btn.spellIndex, btn.bookType)
                    if btn.iconBtn.cooldown and start and duration and enable ~= nil then
                        CooldownFrame_SetTimer(btn.iconBtn.cooldown, start, duration, enable)
                    end
                end
            end
        elseif event == "SPELLS_CHANGED" then
            -- diff 出新学的 spell name 加入 newSpells；首次（基线尚未有效建立）只建立基线不闪
            if not (knownSpells and next(knownSpells)) then
                EnsureBaseline()
            else
                local currentSet = BuildKnownSpellSet()
                if next(currentSet) then  -- 仅 API 就绪时 diff，避免空集把全部误判为新学
                    for name in pairs(currentSet) do
                        if not knownSpells[name] then
                            newSpells[name] = true
                        end
                    end
                    knownSpells = currentSet
                    DFUI:SetTempDB("SpellBook", "knownSpells", knownSpells)
                    DFUI:SetTempDB("SpellBook", "newSpells", newSpells)
                end
            end
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
        elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" then
            -- 仅在法术书可见时重建键位映射，避免后台无谓 CPU 消耗
            if spellbook:IsShown() then
                spellbook:RebuildActionBindMap()
                spellbook:UpdateSpellDisplay()
            end
        end
    end)

    -- 11. 覆写全局 ToggleSpellBook：改走 vanilla ShowUIPanel/HideUIPanel，
    --     让透明保活的原生 SpellBookFrame 进入 left 区 UIPanel 互斥（与制造面板同机制）。
    local origToggleSpellBook = _G.ToggleSpellBook
    _G.ToggleSpellBook = function(bookType)
        if SpellBookFrame:IsShown() then
            HideUIPanel(SpellBookFrame)
        else
            -- 宠物技能入口：打开前先把可见 panel 预选到宠物 Tab
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
            ShowUIPanel(SpellBookFrame)
        end
    end

    -- 11b. 可见 panel 跟随原生 SpellBookFrame 显隐（覆盖 toggle / close / ESC / 互斥自动关闭所有路径）
    HookScript(SpellBookFrame, "OnShow", function() spellbook:Show() end)
    HookScript(SpellBookFrame, "OnHide", function() spellbook:Hide() end)

    -- 12. ESC 关闭：交由原生 SpellBookFrame（其 OnHide 已联动隐藏可见 panel）；
    --     防御性确保它仍注册于 UISpecialFrames，避免个别客户端移除导致 ESC 失效。
    local sbfRegistered = false
    for i = 1, table.getn(UISpecialFrames) do
        if UISpecialFrames[i] == "SpellBookFrame" then
            sbfRegistered = true
        end
    end
    if not sbfRegistered then
        table.insert(UISpecialFrames, "SpellBookFrame")
    end

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
