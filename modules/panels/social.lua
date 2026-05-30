setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Social", {
    enabled = {true},
})

-- DF Retail InsetFrame nineslice（复制自 tradeskill.lua:146-211，保持单文件零跨依赖）
local SOCIAL_PROF_TEX     = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\panels\\df\\professions\\"
local UIFRAME_CORNER_TEX  = SOCIAL_PROF_TEX .. "uiframe_corner.tga"
local UIFRAME_V_TEX       = SOCIAL_PROF_TEX .. "uiframe_v.tga"
local UIFRAME_H_TEX       = SOCIAL_PROF_TEX .. "uiframe_h.tga"
local UI_TC_CTL = {97/128, 103/128, 71/128, 77/128}
local UI_TC_CTR = {105/128, 111/128, 71/128, 77/128}
local UI_TC_CBL = {81/128, 87/128, 71/128, 77/128}
local UI_TC_CBR = {89/128, 95/128, 71/128, 77/128}
local UI_TC_L   = {31/64, 34/64, 0, 1}
local UI_TC_R   = {36/64, 39/64, 0, 1}
local UI_TC_T   = {0, 1, 116/128, 119/128}
local UI_TC_B   = {0, 1, 111/128, 114/128}

local function CreateInsetBackdrop(frame, bgAlpha)
    if bgAlpha and bgAlpha > 0 then
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(frame)
        bg:SetVertexColor(0, 0, 0, bgAlpha)
    end
    local CSZ, EW = 5, 2
    local function corner(point, tc, oy)
        local c = frame:CreateTexture(nil, "BORDER")
        c:SetTexture(UIFRAME_CORNER_TEX)
        c:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
        c:SetWidth(CSZ); c:SetHeight(CSZ)
        c:SetPoint(point, frame, point, 0, oy or 0)
        return c
    end
    local cTL = corner("TOPLEFT",     UI_TC_CTL)
    local cTR = corner("TOPRIGHT",    UI_TC_CTR)
    local cBL = corner("BOTTOMLEFT",  UI_TC_CBL, -1)
    local cBR = corner("BOTTOMRIGHT", UI_TC_CBR, -1)
    local T = frame:CreateTexture(nil, "BORDER")
    T:SetTexture(UIFRAME_H_TEX); T:SetTexCoord(UI_TC_T[1], UI_TC_T[2], UI_TC_T[3], UI_TC_T[4])
    T:SetPoint("TOPLEFT", cTL, "TOPRIGHT", 0, 0)
    T:SetPoint("TOPRIGHT", cTR, "TOPLEFT", 0, 0)
    T:SetHeight(EW)
    local B = frame:CreateTexture(nil, "BORDER")
    B:SetTexture(UIFRAME_H_TEX); B:SetTexCoord(UI_TC_B[1], UI_TC_B[2], UI_TC_B[3], UI_TC_B[4])
    B:SetPoint("BOTTOMLEFT", cBL, "BOTTOMRIGHT", 0, 0)
    B:SetPoint("BOTTOMRIGHT", cBR, "BOTTOMLEFT", 0, 0)
    B:SetHeight(EW)
    local L = frame:CreateTexture(nil, "BORDER")
    L:SetTexture(UIFRAME_V_TEX); L:SetTexCoord(UI_TC_L[1], UI_TC_L[2], UI_TC_L[3], UI_TC_L[4])
    L:SetPoint("TOPLEFT", cTL, "BOTTOMLEFT", 0, 0)
    L:SetPoint("BOTTOMLEFT", cBL, "TOPLEFT", 0, 0)
    L:SetWidth(EW)
    local R = frame:CreateTexture(nil, "BORDER")
    R:SetTexture(UIFRAME_V_TEX); R:SetTexCoord(UI_TC_R[1], UI_TC_R[2], UI_TC_R[3], UI_TC_R[4])
    R:SetPoint("TOPRIGHT", cTR, "BOTTOMRIGHT", 0, 0)
    R:SetPoint("BOTTOMRIGHT", cBR, "TOPRIGHT", 0, 0)
    R:SetWidth(EW)
end

DFUI:NewMod("Social", 5, function()
    -- 包装 _G.UnitPopup_OnUpdate 加 nil unit 守卫
    -- 根因 1：vanilla UnitPopup_OnUpdate 内部 CheckInteractDistance(unit,...)，unit=nil 时报 Usage 错
    -- 根因 2：setfenv 后 `UnitPopup_OnUpdate = X` 只写到 DFUI.env 不写 _G（metatable 无 __newindex）
    --        必须显式 _G.UnitPopup_OnUpdate = X 才能替换 vanilla 全局函数
    if _G and _G.UnitPopup_OnUpdate then
        local _origOnUpdate = _G.UnitPopup_OnUpdate
        _G.UnitPopup_OnUpdate = function(elapsed)
            local menuName = UIDROPDOWNMENU_OPEN_MENU
            local menu = menuName and getglobal and getglobal(menuName)
            if not (menu and menu.unit) then return end  -- 无 unit 跳过距离检查
            _origOnUpdate(elapsed)
        end
        -- 把已注册的 OnUpdate handler 替换为新版（DropDownList1/2 之前可能引用旧 _origOnUpdate）
        if DropDownList1 and DropDownList1:GetScript("OnUpdate") == _origOnUpdate then
            DropDownList1:SetScript("OnUpdate", _G.UnitPopup_OnUpdate)
        end
        if DropDownList2 and DropDownList2:GetScript("OnUpdate") == _origOnUpdate then
            DropDownList2:SetScript("OnUpdate", _G.UnitPopup_OnUpdate)
        end
    end

    FriendsFrameTopLeft:Hide()
    FriendsFrameTopRight:Hide()
    FriendsFrameBottomLeft:Hide()
    FriendsFrameBottomRight:Hide()

    FriendsFrameTab1:Hide()
    FriendsFrameTab2:Hide()
    FriendsFrameTab3:Hide()
    FriendsFrameTab4:Hide()
    FriendsFrameCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_FriendsBg", FriendsFrame, 384, 512, 1)
    customBg:SetPoint("TOPLEFT", FriendsFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", FriendsFrame, "BOTTOMRIGHT", -32, 75)
    customBg:SetFrameLevel(FriendsFrame:GetFrameLevel() + 1)
    customBg.Bg:SetDrawLayer("BACKGROUND", -1)

    -- 保留滚动图标
    local regions = {FriendsFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and string.find(texture, "FriendsFrameScrollIcon") then
                region:SetParent(customBg)
                region:SetDrawLayer("BORDER", 0)
                break
            end
        end
    end

    local title = customBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", customBg, "TOP", 0, -6)
    title:SetText("社交")

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(FriendsFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    -- vanilla 1.12 屏蔽模式可能切到独立 IgnoreListFrame，FriendsListFrame 会被 Hide
    -- followFrames 同时跟随两者；IgnoreListFrame 若不存在则只跟 FriendsListFrame（nil 守卫）
    local friendsInset = DFUI.CreateRetailInset(customBg, {
        name         = "DFUI_FriendsInset",
        anchors      = {3, -78, -6, 80},    -- 底部留 80px 与 查找/公会 tab 的 inset 底对齐
        followFrames = IgnoreListFrame and {FriendsListFrame, IgnoreListFrame} or {FriendsListFrame},
    })

    local whoInset = DFUI.CreateRetailInset(customBg, {
        name        = "DFUI_WhoInset",
        anchors     = {3, -58, -6, 80},     -- 底部留 80px 给 vanilla EditBox（姓名搜索框）
        followFrame = WhoFrame,
    })

    -- who 搜索结果路由进 UI 列表：DFUI 全程不调 SetWhoToUI(1)，SendWho 结果默认漏进聊天框，
    -- 导致 GetNumWhoResults/GetWhoInfo 不更新、自建查找列表搜名字无结果（留空时是面板首开 vanilla
    -- OnShow 偶发 SetWhoToUI(1) 残留的旧缓存）。借 DFUI 自定义 hooksecurefunc 默认 new-before-old
    -- 顺序（core/tools.lua:121-124），在真正 SendWho 执行前置 SetWhoToUI(1)，结果即进 UI 数据源。
    if hooksecurefunc and not DFUI._whoSetUIHooked then
        DFUI._whoSetUIHooked = true
        hooksecurefunc("SendWho", function(q)
            if SetWhoToUI then SetWhoToUI(1) end
        end)
    end

    -- who 查询防抖：Turtle 服务器对连续 who 有冷却，连点 SendWho 会反复重置冷却 → "等多久都查不到"。
    -- 客户端记录上次发送时间，冷却窗口内拦下并提示剩余秒数，避免重置 + 给反馈。
    -- DFUI_WHO_CD 全局可调（/script DFUI_WHO_CD=8）以匹配服务器实际冷却。
    DFUI_WHO_CD = DFUI_WHO_CD or 5
    local dfuiLastWho = -999
    local function dfuiTryWho(text)
        local now = GetTime and GetTime() or 0
        local cd = DFUI_WHO_CD or 5
        local elapsed = now - dfuiLastWho
        if elapsed < cd then return end  -- 冷却窗口内静默拦下（防连点重置服务器冷却），不提示
        dfuiLastWho = now
        if SetWhoToUI then SetWhoToUI(1) end
        if SendWho then SendWho(text) end
    end

    -- 自建 who 搜索框：彻底脱离 vanilla WhoFrameEditBox，挂 whoInset 下方预留区，
    -- 自己发起 SendWho、结果填 whoInset 上的 DFUI_WhoRow（自己查自己显示）。
    -- 1.12 SendWho 透传输入串，原生支持 n-名字 / z-区域 / c-职业 / g-公会 / 数字=等级 筛选语法。
    -- 统计行「找到N人（显示M人）」：复用 vanilla WhoFrameTotals（WhoList_Update 自动 SetText），
    -- 学列头只重锚不 SetParent（parent 仍 WhoFrame、随其可见），放 whoInset 底边外侧第一行。
    if WhoFrameTotals then
        WhoFrameTotals:ClearAllPoints()
        WhoFrameTotals:SetPoint("TOP", whoInset, "BOTTOM", 0, -5)
        WhoFrameTotals:SetTextColor(1, 1, 1)
    end

    local whoSearch = CreateFrame("EditBox", "DFUI_WhoSearchBox", whoInset)
    whoSearch:SetHeight(16)
    whoSearch:SetPoint("TOPLEFT",  whoInset, "BOTTOMLEFT",  6, -24)
    whoSearch:SetPoint("TOPRIGHT", whoInset, "BOTTOMRIGHT", -6, -24)
    whoSearch:SetAutoFocus(false)
    whoSearch:SetFontObject(GameFontHighlightSmall)
    whoSearch:SetTextColor(1, 1, 1)  -- 输入文字纯白，与列表区(zoneText)文字颜色一致
    whoSearch:SetTextInsets(20, 4, 0, 0)  -- 左缩进 20px 让位图标 + placeholder

    local whoSearchBg = CreateFrame("Frame", nil, whoInset)
    whoSearchBg:SetPoint("TOPLEFT",     whoSearch, "TOPLEFT",     -3,  3)
    whoSearchBg:SetPoint("BOTTOMRIGHT", whoSearch, "BOTTOMRIGHT",  3, -3)
    whoSearchBg:SetFrameLevel(whoInset:GetFrameLevel())
    whoSearch:SetFrameLevel(whoSearchBg:GetFrameLevel() + 1)
    CreateInsetBackdrop(whoSearchBg, 0.85)

    local whoSearchIcon = whoSearchBg:CreateTexture(nil, "OVERLAY")
    whoSearchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    whoSearchIcon:SetWidth(14); whoSearchIcon:SetHeight(14)
    whoSearchIcon:SetPoint("LEFT", whoSearchBg, "LEFT", 5, 0)
    whoSearchIcon:SetVertexColor(0.98, 0.91, 0.58)

    local whoSearchPlaceholder = whoSearchBg:CreateFontString(nil, "OVERLAY")
    whoSearchPlaceholder:SetFont("Fonts\\FRIZQT__.TTF", 13)
    whoSearchPlaceholder:SetPoint("LEFT", whoSearchBg, "LEFT", 24, 0)
    whoSearchPlaceholder:SetText("查找")
    whoSearchPlaceholder:SetTextColor(1, 1, 1)

    local function whoUpdatePlaceholder()
        if whoSearch:GetText() == "" then whoSearchPlaceholder:Show() else whoSearchPlaceholder:Hide() end
    end
    whoUpdatePlaceholder()
    whoSearch:SetScript("OnTextChanged", whoUpdatePlaceholder)
    whoSearch:SetScript("OnEscapePressed", function() whoSearch:ClearFocus() end)
    whoSearch:SetScript("OnEnterPressed", function()
        dfuiTryWho(whoSearch:GetText())
        whoSearch:ClearFocus()
    end)

    -- vanilla 搜索框彻底隐藏（WhoFrame 仍透明保活当数据载体）
    if WhoFrameEditBox then WhoFrameEditBox:Hide() end

    -- 取消 vanilla WhoFrame 其余可见功能按钮（底部"添加好友/组队"等），避免遮挡/冲突自制 UI。
    -- 不硬编码按钮名（客户端无 FrameXML 源码）：运行时遍历 WhoFrame 直接子 Button，排除要保留重锚的
    -- 列头（WhoFrameColumnHeader*）。用 alpha0+EnableMouse(false)：持久不可见且不拦鼠标，vanilla 即便
    -- 重新 Show 也不改 alpha。这些功能已由自制 row 右键菜单覆盖（密语/组队/加好友/屏蔽）。
    if WhoFrame and WhoFrame.GetChildren then
        local kids = { WhoFrame:GetChildren() }
        for i = 1, table.getn(kids) do
            local c = kids[i]
            if c and c.GetObjectType and c:GetObjectType() == "Button" then
                local n = c.GetName and c:GetName()
                if not (n and string.find(n, "ColumnHeader", 1, true)) then
                    c:Hide(); c:SetAlpha(0)
                    if c.EnableMouse then c:EnableMouse(false) end
                end
            end
        end
    end

    local guildInset = DFUI.CreateRetailInset(customBg, {
        name        = "DFUI_GuildInset",
        anchors     = {6, -58, -9, 98},     -- 左右各比原 {3,-6} 多收 3px；底部再上移 18px (80→98)
        followFrame = GuildFrame,
    })

    -- 公会 MOTD 框补凹陷边框 + 黑底：不调任何 EditBox 方法，避免破坏 vanilla 按钮点击功能
    -- backdrop parent 跟随 GuildFrameNotesText 的真实父链；FrameLevel 默认（同级 DrawLayer 决定）
    -- bgAlpha=0.85：与查找框搜索框同款黑底，BACKGROUND 层不挡 vanilla 文字（OVERLAY/ARTWORK）
    if GuildFrameNotesText then
        -- 仅画边框线条无黑底（bgAlpha=0），左右外扩 5px、上边框上移 18px；零调用 EditBox 任何方法
        local guildMotdBg = CreateFrame("Frame", nil, GuildFrame)
        guildMotdBg:SetPoint("TOPLEFT",     GuildFrameNotesText, "TOPLEFT",     -5, 18)
        guildMotdBg:SetPoint("BOTTOMRIGHT", GuildFrameNotesText, "BOTTOMRIGHT",  5,  0)
        CreateInsetBackdrop(guildMotdBg, 0)
    end

    -- Guild 列表 vanilla button 由下方 DFUI_GuildRow 系统接管（参考 FriendRow 模式）
    -- 不再 reanchor vanilla GuildFrameButton 子元素（被自建 row 取代）

    local raidInset = DFUI.CreateRetailInset(customBg, {
        name        = "DFUI_RaidInset",
        anchors     = {3, -58, -6, 6},
        followFrame = RaidFrame,
    })

    -- 好友 Tab 内"好友列表 / 屏蔽列表"子切换按钮
    -- vanilla 1.12 共 4 个 ToggleTab，分别在好友/屏蔽两个 ScrollFrame 上方：
    --   FriendsFrameToggleTab1(好友/selected) FriendsFrameToggleTab2(屏蔽/unselected) — 好友模式
    --   IgnoreFrameToggleTab1(好友/unselected) IgnoreFrameToggleTab2(屏蔽/selected) — 屏蔽模式
    -- vanilla 自带切换 + 两组互斥显隐，仅做视觉 skin，每组选中态固定
    local subTabTex = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\interface\\uiframetabs.blp"
    local function skinSubTab(tab, tabWidth, defaultSelected)
        -- 关键：清除 Button 内置状态纹理（NormalTexture/PushedTexture/HighlightTexture/DisabledTexture）
        -- GetRegions 不包含这些，vanilla 它们在 ARTWORK 层会盖住 DF BACKGROUND 纹理（pfUI 同样做法）
        if tab.SetNormalTexture    then tab:SetNormalTexture(nil)    end
        if tab.SetPushedTexture    then tab:SetPushedTexture(nil)    end
        if tab.SetDisabledTexture  then tab:SetDisabledTexture(nil)  end
        if tab.SetHighlightTexture then tab:SetHighlightTexture(nil) end

        local regions = {tab:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                r:SetTexture(nil)
            end
        end

        tab:SetWidth(tabWidth)
        tab:SetHeight(28)
        local normH, selH = 28, 31
        local edgeWidth = tabWidth / 2

        -- 9 个纹理 TexCoord 上下翻转（top/bottom 交换），让 tab 圆弧朝下贴 inset 顶
        local left = tab:CreateTexture(nil, "BACKGROUND")
        left:SetTexture(subTabTex); left:SetWidth(edgeWidth); left:SetHeight(normH)
        left:SetPoint("TOPLEFT", tab, "TOPLEFT", -3, 0)
        left:SetTexCoord(0.015625, 0.5625, 0.957031, 0.816406)

        local right = tab:CreateTexture(nil, "BACKGROUND")
        right:SetTexture(subTabTex); right:SetWidth(edgeWidth); right:SetHeight(normH)
        right:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 7, 0)
        right:SetTexCoord(0.015625, 0.59375, 0.808594, 0.667969)

        local middle = tab:CreateTexture(nil, "BACKGROUND")
        middle:SetTexture(subTabTex); middle:SetWidth(1); middle:SetHeight(normH)
        middle:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
        middle:SetPoint("TOPRIGHT", right, "TOPLEFT", 0, 0)
        middle:SetTexCoord(0, 0.015625, 0.316406, 0.175781)

        -- selected 纹理用 BOTTOMLEFT 锚，多出的 3px 向上突出（DF retail 标签栏样式）
        -- 子 Tab 底部贴 inset 顶，向上突出避免选中态探入 inset 内
        local leftSel = tab:CreateTexture(nil, "BACKGROUND")
        leftSel:SetTexture(subTabTex); leftSel:SetWidth(edgeWidth); leftSel:SetHeight(selH)
        leftSel:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", -1, 0)
        leftSel:SetTexCoord(0.015625, 0.5625, 0.660156, 0.496094)
        leftSel:Hide()

        local rightSel = tab:CreateTexture(nil, "BACKGROUND")
        rightSel:SetTexture(subTabTex); rightSel:SetWidth(edgeWidth); rightSel:SetHeight(selH)
        rightSel:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 8, 0)
        rightSel:SetTexCoord(0.015625, 0.59375, 0.488281, 0.324219)
        rightSel:Hide()

        local middleSel = tab:CreateTexture(nil, "BACKGROUND")
        middleSel:SetTexture(subTabTex); middleSel:SetWidth(1); middleSel:SetHeight(selH)
        middleSel:SetPoint("BOTTOMLEFT", leftSel, "BOTTOMRIGHT", 0, 0)
        middleSel:SetPoint("BOTTOMRIGHT", rightSel, "BOTTOMLEFT", 0, 0)
        middleSel:SetTexCoord(0, 0.015625, 0.167969, 0.00390625)
        middleSel:Hide()

        local hlLeft = tab:CreateTexture(nil, "HIGHLIGHT")
        hlLeft:SetTexture(subTabTex); hlLeft:SetWidth(edgeWidth); hlLeft:SetHeight(normH)
        hlLeft:SetPoint("TOPLEFT", tab, "TOPLEFT", -3, 0)
        hlLeft:SetTexCoord(0.015625, 0.5625, 0.957031, 0.816406)
        hlLeft:SetBlendMode("ADD"); hlLeft:SetAlpha(0.4)

        local hlRight = tab:CreateTexture(nil, "HIGHLIGHT")
        hlRight:SetTexture(subTabTex); hlRight:SetWidth(edgeWidth); hlRight:SetHeight(normH)
        hlRight:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 7, 0)
        hlRight:SetTexCoord(0.015625, 0.59375, 0.808594, 0.667969)
        hlRight:SetBlendMode("ADD"); hlRight:SetAlpha(0.4)

        local hlMiddle = tab:CreateTexture(nil, "HIGHLIGHT")
        hlMiddle:SetTexture(subTabTex); hlMiddle:SetWidth(1); hlMiddle:SetHeight(normH)
        hlMiddle:SetPoint("TOPLEFT", hlLeft, "TOPRIGHT", 0, 0)
        hlMiddle:SetPoint("TOPRIGHT", hlRight, "TOPLEFT", 0, 0)
        hlMiddle:SetTexCoord(0, 0.015625, 0.316406, 0.175781)
        hlMiddle:SetBlendMode("ADD"); hlMiddle:SetAlpha(0.4)

        local label = tab:GetFontString()
        if label then
            label:ClearAllPoints()
            label:SetPoint("CENTER", tab, "CENTER", 0, -1)
        end

        tab.dfSetSelected = function(selected)
            if selected then
                left:Hide(); right:Hide(); middle:Hide()
                leftSel:Show(); rightSel:Show(); middleSel:Show()
                if label then label:SetTextColor(1, 1, 1) end
            else
                left:Show(); right:Show(); middle:Show()
                leftSel:Hide(); rightSel:Hide(); middleSel:Hide()
                if label then label:SetTextColor(1, 0.82, 0) end
            end
        end

        -- 初始选中态由调用方指定（每组角色固定，不需 OnClick hook 切换）
        tab.dfSetSelected(defaultSelected)
    end

    -- 4 个 ToggleTab 一并 skin（vanilla 自动管理 FriendsFrame 组 vs IgnoreFrame 组的互斥显隐）
    skinSubTab(FriendsFrameToggleTab1, 70, true)    -- 好友模式: "好友" 始终 selected
    skinSubTab(FriendsFrameToggleTab2, 70, false)   -- 好友模式: "屏蔽" 始终 unselected
    skinSubTab(IgnoreFrameToggleTab1,  70, false)   -- 屏蔽模式: "好友" 始终 unselected
    skinSubTab(IgnoreFrameToggleTab2,  70, true)    -- 屏蔽模式: "屏蔽" 始终 selected

    -- 4 个 ToggleTab 完全在 inset 之上，底部紧贴 inset 顶（DF retail 标签栏样式）
    FriendsFrameToggleTab1:ClearAllPoints()
    FriendsFrameToggleTab1:SetPoint("BOTTOMLEFT", friendsInset, "TOPLEFT", 8, 0)
    FriendsFrameToggleTab2:ClearAllPoints()
    FriendsFrameToggleTab2:SetPoint("BOTTOMLEFT", FriendsFrameToggleTab1, "BOTTOMRIGHT", 4, 0)
    IgnoreFrameToggleTab1:ClearAllPoints()
    IgnoreFrameToggleTab1:SetPoint("BOTTOMLEFT", friendsInset, "TOPLEFT", 8, 0)
    IgnoreFrameToggleTab2:ClearAllPoints()
    IgnoreFrameToggleTab2:SetPoint("BOTTOMLEFT", IgnoreFrameToggleTab1, "BOTTOMRIGHT", 4, 0)

    -- 提到 inset 之上
    FriendsFrameToggleTab1:SetFrameLevel(customBg:GetFrameLevel() + 2)
    FriendsFrameToggleTab2:SetFrameLevel(customBg:GetFrameLevel() + 2)
    IgnoreFrameToggleTab1:SetFrameLevel(customBg:GetFrameLevel() + 2)
    IgnoreFrameToggleTab2:SetFrameLevel(customBg:GetFrameLevel() + 2)

    -- SubTab（好友/屏蔽）切换时也隐藏 dropdown，避免右键菜单残留
    local function _subTabHideDD() if HideDropDownMenu then HideDropDownMenu(1) end end
    HookScript(FriendsFrameToggleTab1, "OnClick", _subTabHideDD)
    HookScript(FriendsFrameToggleTab2, "OnClick", _subTabHideDD)
    HookScript(IgnoreFrameToggleTab1,  "OnClick", _subTabHideDD)
    HookScript(IgnoreFrameToggleTab2,  "OnClick", _subTabHideDD)

    -- 好友/屏蔽 ScrollFrame + 第一行 Button 重锚到 inset 内部
    -- vanilla 1.12 FriendButton1/IgnoreButton1 直接锚 FriendsFrame.TOPLEFT (23, -76)，不是 ScrollFrame 的子
    -- 后续 ButtonN 锚 Button(N-1)，重锚 Button1 即整列跟随
    -- 函数化，OnShow hook 里反复调用，防 vanilla FriendsFrame_Update 还原
    -- 1.12 ScrollFrame 不会因 SetPoint 双锚自动重算 size，必须显式 SetHeight
    -- SF.h 动态 = inset.h - 8（顶 4 + 底 4 padding），10 行 × (SF.h/10) 铺满 SF
    -- 提到 18（>vanilla FRIENDS_TO_DISPLAY=10）让 visibleRows 上限 ≥ 15，填满 inset
    -- vanilla GetFriendInfo(i) 接受 i > 10（FRIENDS_TO_DISPLAY 仅控制 vanilla button 数量）
    local MAX_ROWS = 18       -- 屏蔽列表 fitButtons 拉伸填充用的按钮数（除数，勿与好友行混用）
    local FRIEND_ROWS = 24    -- 好友自建行 frame 数：建足量，实际显示由 floor(sf高/18) 决定，自动填满 inset
    -- 1.12 GetHeight 对"双锚无 SetHeight"的 frame 返回脏值（实测 inset 真高 267 却报 221，差 46px）
    -- 必须用 GetTop-GetBottom 取真实高度（reference-wow112-frame-size-pitfalls）
    local function insetTrueH(f)
        if not f then return 0 end
        local t, b = f:GetTop(), f:GetBottom()
        if t and b then return t - b end
        return f:GetHeight() or 0
    end
    local function getSFHeight()
        local ih = insetTrueH(friendsInset)
        if ih > 8 then return ih - 8 end
        return 200
    end
    -- 治本：4 个 sf 全部双锚 TL+BR 跟随 inset，sf.height 由 1.12 reflow 自动算
    -- 旧端：vanilla XML 给 sf 设过的 SetHeight 被双锚 override，行为等价
    -- 新端：脱离 GetTop/GetBottom 依赖（inset Hide 时全 nil），不会再 0 高度
    local function reanchorScrollFrames()
        if FriendsFrameFriendsScrollFrame then
            FriendsFrameFriendsScrollFrame:ClearAllPoints()
            FriendsFrameFriendsScrollFrame:SetPoint("TOPLEFT",     friendsInset, "TOPLEFT",      6, -4)
            FriendsFrameFriendsScrollFrame:SetPoint("BOTTOMRIGHT", friendsInset, "BOTTOMRIGHT", -24,  4)
        end
        if FriendsFrameIgnoreScrollFrame then
            FriendsFrameIgnoreScrollFrame:ClearAllPoints()
            FriendsFrameIgnoreScrollFrame:SetPoint("TOPLEFT",     friendsInset, "TOPLEFT",      6, -4)
            FriendsFrameIgnoreScrollFrame:SetPoint("BOTTOMRIGHT", friendsInset, "BOTTOMRIGHT", -24,  4)
        end
        -- vanilla button 链锚保留（DFUI row 系统不依赖，留给共存插件 / fallback 路径）
        if FriendsFrameFriendButton1 then
            FriendsFrameFriendButton1:ClearAllPoints()
            FriendsFrameFriendButton1:SetPoint("TOPLEFT", FriendsFrameFriendsScrollFrame, "TOPLEFT", 0, 0)
        end
        if FriendsFrameIgnoreButton1 then
            FriendsFrameIgnoreButton1:ClearAllPoints()
            FriendsFrameIgnoreButton1:SetPoint("TOPLEFT", FriendsFrameIgnoreScrollFrame, "TOPLEFT", 0, 0)
        end
        if WhoListScrollFrame and whoInset then
            WhoListScrollFrame:ClearAllPoints()
            WhoListScrollFrame:SetPoint("TOPLEFT",     whoInset, "TOPLEFT",      6, -4)
            WhoListScrollFrame:SetPoint("BOTTOMRIGHT", whoInset, "BOTTOMRIGHT", -24,  4)
        end
        if GuildListScrollFrame and guildInset then
            GuildListScrollFrame:ClearAllPoints()
            GuildListScrollFrame:SetPoint("TOPLEFT",     guildInset, "TOPLEFT",      6,  -4)
            -- 底部 BR y=22 (4 base + 18 留给 GuildFramePlayerStatusDropDown)，避免末行与按钮重叠
            GuildListScrollFrame:SetPoint("BOTTOMRIGHT", guildInset, "BOTTOMRIGHT", -24, 22)
        end
    end
    reanchorScrollFrames()

    -- 好友 tab 底部 4 个按钮（添加好友/发送消息/删除好友/组队邀请）位置偏移
    local function shiftFrameUp(frame, dy)
        if not frame or not frame.GetNumPoints then return end
        local pts = {}
        for i = 1, frame:GetNumPoints() do
            pts[i] = {frame:GetPoint(i)}
        end
        frame:ClearAllPoints()
        for i = 1, table.getn(pts) do
            local p = pts[i]
            frame:SetPoint(p[1], p[2], p[3], p[4] or 0, (p[5] or 0) + dy)
        end
    end
    local function shiftFrameRight(frame, dx)
        if not frame or not frame.GetNumPoints then return end
        local pts = {}
        for i = 1, frame:GetNumPoints() do
            pts[i] = {frame:GetPoint(i)}
        end
        frame:ClearAllPoints()
        for i = 1, table.getn(pts) do
            local p = pts[i]
            frame:SetPoint(p[1], p[2], p[3], (p[4] or 0) + dx, p[5] or 0)
        end
    end
    -- 4 个按钮缩到 88%（vanilla 模板 9-slice 横向被拉伸严重），字体缩 90%
    local fourBtns = {
        FriendsFrameAddFriendButton, FriendsFrameRemoveFriendButton,
        FriendsFrameSendMessageButton, FriendsFrameGroupInviteButton,
    }
    for i = 1, table.getn(fourBtns) do
        local b = fourBtns[i]
        if b then
            b:SetWidth(b:GetWidth() * 0.88)
            b:SetHeight(b:GetHeight() * 0.88)
            local fs = b:GetFontString()
            if fs then
                local fpath, fsize, fflags = fs:GetFont()
                if fsize then fs:SetFont(fpath, fsize * 0.9, fflags) end
            end
        end
    end

    -- 整组右移 15px：AddFriend 加 X；vanilla 锚链让 RemoveFriend/SendMessage/GroupInvite 都跟随
    -- detachRightColumn 在 OnShow 锁定时已含此偏移，AddFriend 后续若再动 X 不会影响右列
    shiftFrameRight(FriendsFrameAddFriendButton, 15)

    -- 左列：AddFriend 独立锚 FriendsFrame，RemoveFriend 锚 AddFriend.BOTTOM 自动跟随
    shiftFrameUp(FriendsFrameAddFriendButton,    8)
    shiftFrameUp(FriendsFrameRemoveFriendButton, 5)
    -- 右列：vanilla 锚 SendMessage -> AddFriend.RIGHT (66, 5)，SendMessage 顶比 AddFriend 顶高 5px
    -- 净 dy = 1：SendMessage 顶 = AddFriend 顶 - 2（比左列下 2px）
    shiftFrameUp(FriendsFrameSendMessageButton,  1)
    shiftFrameUp(FriendsFrameGroupInviteButton,  5)

    -- 右列与 AddFriend 解耦：once，第一次 OnShow 时把 SendMessage 锚链打散
    -- SendMessage 改锚 FriendsFrame.TOPLEFT 绝对坐标，GroupInvite 仍锚 SendMessage.BOTTOM 跟随
    -- 解耦后调 shiftFrameUp(FriendsFrameSendMessageButton, dy) 即可独立控制右列
    -- 锁定的相对 FriendsFrame 坐标（once 计算，后续反复 set 同值确保 vanilla 还原也被覆盖）
    local lockedSendX, lockedSendY
    local function detachRightColumn()
        local btn = FriendsFrameSendMessageButton
        if not btn then return end
        if not lockedSendX then
            local L, T = btn:GetLeft(), btn:GetTop()
            local fL, fT = FriendsFrame:GetLeft(), FriendsFrame:GetTop()
            if not (L and T and fL and fT) then return end
            lockedSendX, lockedSendY = L - fL, T - fT
        end
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", FriendsFrame, "TOPLEFT", lockedSendX, lockedSendY)
    end

    -- 屏蔽 tab 底部 2 按钮（屏蔽玩家/取消屏蔽）：第一个 shiftFrameUp，第二个强制锚到它确保水平对齐
    shiftFrameUp(FriendsFrameIgnorePlayerButton, 5)
    if FriendsFrameStopIgnoreButton then
        FriendsFrameStopIgnoreButton:ClearAllPoints()
        FriendsFrameStopIgnoreButton:SetPoint("LEFT", FriendsFrameIgnorePlayerButton, "RIGHT", 4, 0)
    end

    -- 公会 tab 彻底清掉 vanilla 滚动条（轨道/边框/底纹/箭头/滑块）；鼠标滚轮仍可滚动
    -- 递归遍历所有 regions/children，texture 全清、frame 全 hide+alpha=0；HookScript 持续压住 OnShow
    local function nukeScrollBar(f)
        if not f then return end
        f:Hide()
        f:SetAlpha(0)
        local regions = {f:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r.SetTexture then r:SetTexture(nil) end
            if r.Hide then r:Hide() end
        end
        local children = {f:GetChildren()}
        for i = 1, table.getn(children) do
            nukeScrollBar(children[i])
        end
    end
    -- 公会/好友/屏蔽/查找 tab：保留 vanilla 原生上下箭头（亮金本色 24×24），隐藏轨道/thumb
    -- （与角色面板技能/声望页一致；鼠标滚轮仍可滚动）
    local function keepGoldArrows(sbName)
        local sb = getglobal(sbName)
        if not sb then return end
        sb._dfScrollSkinned = true   -- 抢先占位，挡 scrollbar.lua 的 SkinScrollbar
        sb:Show(); sb:SetAlpha(1)
        local top = getglobal(sbName.."Top")
        local mid = getglobal(sbName.."Middle")
        local bot = getglobal(sbName.."Bottom")
        if top and top.SetTexture then top:SetTexture(nil); top:Hide() end
        if mid and mid.SetTexture then mid:SetTexture(nil); mid:Hide() end
        if bot and bot.SetTexture then bot:SetTexture(nil); bot:Hide() end
        local thumb = sb.GetThumbTexture and sb:GetThumbTexture()
        if thumb then thumb:SetTexture(nil) end
        local function goldArrow(btn, isUp)
            if not btn then return end
            btn._dfScrollSkinned = true
            btn:SetWidth(24); btn:SetHeight(24)
            btn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
            btn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
            btn:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            local L, R, T, B = 0, 1, 0, 1
            if isUp then T, B = 1, 0 end   -- 上箭头垂直翻转
            local function setc(t) if t then t:SetTexCoord(L, R, T, B) end end
            setc(btn:GetNormalTexture());   setc(btn:GetPushedTexture())
            setc(btn:GetDisabledTexture()); setc(btn:GetHighlightTexture())
        end
        goldArrow(getglobal(sbName.."ScrollUpButton"),   true)
        goldArrow(getglobal(sbName.."ScrollDownButton"), false)
    end
    local scrollBarNames = {
        "GuildListScrollFrameScrollBar",
        "FriendsFrameFriendsScrollFrameScrollBar",
        "FriendsFrameIgnoreScrollFrameScrollBar",
        "WhoListScrollFrameScrollBar",
    }
    for i = 1, table.getn(scrollBarNames) do
        local nm = scrollBarNames[i]
        local sb = getglobal(nm)
        if sb and sb.GetScript then
            keepGoldArrows(nm)
            HookScript(sb, "OnShow", function()
                keepGoldArrows(nm)
            end)
        end
    end

    -- who 全自制：列表挂 whoInset，上下箭头（vanilla 默认锚 WhoListScrollFrame 右、超出 whoInset 外侧）
    -- 重锚到 whoInset 右内侧、再内 1px；hook scrollbar OnShow 防 vanilla 布局重置
    if whoInset then
        local function reanchorWhoArrows()
            local up   = getglobal("WhoListScrollFrameScrollBarScrollUpButton")
            local down = getglobal("WhoListScrollFrameScrollBarScrollDownButton")
            if up   then up:ClearAllPoints();   up:SetPoint("TOPRIGHT",     whoInset, "TOPRIGHT",     1, -1) end
            if down then down:ClearAllPoints(); down:SetPoint("BOTTOMRIGHT", whoInset, "BOTTOMRIGHT", 1,  1) end
        end
        reanchorWhoArrows()
        local whoSB = getglobal("WhoListScrollFrameScrollBar")
        if whoSB then HookScript(whoSB, "OnShow", reanchorWhoArrows) end
    end

    -- 好友/屏蔽列表滚动箭头同样重锚到 friendsInset 右内侧（与查找 who 完全相同的偏移）
    if friendsInset then
        local function reanchorFriendArrows(sbName)
            local up   = getglobal(sbName.."ScrollUpButton")
            local down = getglobal(sbName.."ScrollDownButton")
            if up   then up:ClearAllPoints();   up:SetPoint("TOPRIGHT",     friendsInset, "TOPRIGHT",     1, -1) end
            if down then down:ClearAllPoints(); down:SetPoint("BOTTOMRIGHT", friendsInset, "BOTTOMRIGHT", 1,  1) end
        end
        local fSBs = { "FriendsFrameFriendsScrollFrameScrollBar", "FriendsFrameIgnoreScrollFrameScrollBar" }
        for fi = 1, table.getn(fSBs) do
            local nm = fSBs[fi]
            reanchorFriendArrows(nm)
            local sb = getglobal(nm)
            if sb then HookScript(sb, "OnShow", function() reanchorFriendArrows(nm) end) end
        end
    end

    -- 公会列表滚动箭头同样重锚到 guildInset 右内侧（与查找/好友相同偏移）
    if guildInset then
        local function reanchorGuildArrows()
            local up   = getglobal("GuildListScrollFrameScrollBarScrollUpButton")
            local down = getglobal("GuildListScrollFrameScrollBarScrollDownButton")
            if up   then up:ClearAllPoints();   up:SetPoint("TOPRIGHT",     guildInset, "TOPRIGHT",     1, -1) end
            if down then down:ClearAllPoints(); down:SetPoint("BOTTOMRIGHT", guildInset, "BOTTOMRIGHT", 1,  1) end
        end
        reanchorGuildArrows()
        local guildSB = getglobal("GuildListScrollFrameScrollBar")
        if guildSB then HookScript(guildSB, "OnShow", reanchorGuildArrows) end
    end

    -- ScrollFrame 自身的边框/凹槽纹理（不在 ScrollBar 子树中），单独清掉
    local function nukeScrollFrameRegions(sf)
        if not sf then return end
        local regions = {sf:GetRegions()}
        for j = 1, table.getn(regions) do
            local r = regions[j]
            if r.SetTexture then r:SetTexture(nil) end
            if r.Hide then r:Hide() end
        end
    end
    nukeScrollFrameRegions(FriendsFrameFriendsScrollFrame)
    nukeScrollFrameRegions(FriendsFrameIgnoreScrollFrame)
    nukeScrollFrameRegions(WhoListScrollFrame)
    nukeScrollFrameRegions(GuildListScrollFrame)


    -- 不主动管理 ToggleTab 显隐，让 vanilla 自己处理（pfUI 简单模式）
    -- 不 hook OnClick，每组选中态固定 dfSetSelected 一次到位
    -- 如有切换显示问题，待 dump 命令数据出来后定向修复

    -- Tab 切换前先隐藏 dropdown，避免菜单残留在屏幕上
    local function hideDropDown()
        if HideDropDownMenu then HideDropDownMenu(1) end
    end

    -- forward declare：deferFit 在 mod load 末尾才赋值，但 Tab callback 闭包需先捕获 upvalue
    -- 用 if deferFit then 守卫，避免 mod load 期间被 vanilla ToggleFriendsFrame 触发时 deferFit 还 nil
    local deferFit

    local guildTab
    customBg:AddTab("好友", function()
        hideDropDown()
        FriendsFrame.selectedTab = 1
        FriendsFrame_ShowSubFrame("FriendsListFrame")
        PanelTemplates_SetTab(FriendsFrame, 1)
        FriendsFrame_Update()
        -- 覆盖"重复点同一 Tab，inset 已 Show 不再触发 OnShow"路径
        if deferFit then deferFit() end
    end, 70)

    customBg:AddTab("查找", function()
        hideDropDown()
        FriendsFrame.selectedTab = 2
        FriendsFrame_ShowSubFrame("WhoFrame")
        PanelTemplates_SetTab(FriendsFrame, 2)
        FriendsFrame_Update()
        if deferFit then deferFit() end
    end, 60)

    guildTab = customBg:AddTab("公会", function()
        hideDropDown()
        FriendsFrame.selectedTab = 3
        FriendsFrame_ShowSubFrame("GuildFrame")
        PanelTemplates_SetTab(FriendsFrame, 3)
        FriendsFrame_Update()
        if deferFit then deferFit() end
    end, 60)

    local function UpdateGuildTab()
        if IsInGuild() then
            guildTab:Enable()
        else
            guildTab:Disable()
        end
    end
    UpdateGuildTab()

    -- 公会 Tab 禁用时降级到好友 Tab，防止脚本调用绕过 EnableMouse(0)
    local function safeTabClick(tabIndex)
        if tabIndex == 3 and not IsInGuild() then tabIndex = 1 end
        local selectedTab = customBg.Tabs[tabIndex]
        if selectedTab then selectedTab:GetScript("OnClick")() end
    end

    -- 公会名册更新时实时同步 Tab 禁用态（面板打开期间入退会场景）
    local guildEventFrame = CreateFrame("Frame")
    guildEventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    guildEventFrame:SetScript("OnEvent", UpdateGuildTab)

    -- 让 9 行 FriendButton/IgnoreButton 总高 = ScrollFrame 高度（铺满 inset 且不超出）
    -- vanilla 链锚 B(i)->B(i-1).BOTTOM 在 1.12 中段有未知 spacing 偏差（dump 实测 14px 累计漂移）
    -- 解法：每个 button 独立锚 SF.TOPLEFT 偏 (0, -(i-1)*rowH)，彻底绕开 vanilla 链锚行为
    local function fitButtons(sf, prefix, maxDisplay)
        if not sf then return end
        local h = sf:GetHeight()
        if not h or h <= 0 then return end
        local rowH = h / MAX_ROWS
        -- 不 SetWidth：vanilla Button 内嵌纹理不随 frame.W 缩放，会导致纹理与子元素错位
        -- 同文件 GuildHeader 处理已踩坑（reference-vanilla-button-setwidth-pitfall）
        for i = 1, MAX_ROWS do
            local b = _G[prefix..i]
            if b then
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", sf, "TOPLEFT", 0, -(i - 1) * rowH)
                b:SetHeight(rowH)
            end
        end
        for i = MAX_ROWS + 1, (maxDisplay or 15) do
            local b = _G[prefix..i]
            if b then b:Hide() end
        end
    end
    local function fitButtonHeights()
        -- FriendButton 已由下方自建 DFUI_FriendRow 系统接管，vanilla button 全 Hide
        -- 这里只 fit IgnoreButton（屏蔽列表单行结构，21.4px 不堆叠）
        fitButtons(FriendsFrameIgnoreScrollFrame,  "FriendsFrameIgnoreButton",  IGNORES_TO_DISPLAY)
    end
    -- 用事件驱动 fitButtonHeights，避开 hook _G.FriendsFrame_Update
    -- prior addon 可能已 hook 该函数且写法依赖 self 在 1.12 是 nil 报错，无法控制
    local fitEventFrame = CreateFrame("Frame")
    fitEventFrame:RegisterEvent("IGNORELIST_UPDATE")
    fitEventFrame:SetScript("OnEvent", function()
        fitButtonHeights()
    end)

    -- inset OnShow 触发刷新的通用 helper（治本兜底，覆盖 hook 失效 / Tab 切换错失 OnShow 的路径）
    -- 一帧延迟让双锚 sf 完成 reflow，闭包内 IsShown + sf 双守卫防 race
    local function deferOneFrame(fn)
        local f = CreateFrame("Frame")
        f:SetScript("OnUpdate", function() f:SetScript("OnUpdate", nil); fn() end)
    end
    local function safeRefresh(inset, sf, refresh)
        if not (inset and inset:IsShown() and sf and refresh) then return end
        refresh()
    end

    -- ============================================================
    -- 自建好友 row 系统（替换 vanilla FriendsFrameFriendButton1..10）
    -- 根因：vanilla 双行 FontString 在 21.4px row 高内必然垂直堆叠
    -- 设计：单行 layout，复用 vanilla FriendsDropDown / FauxScrollFrame / FriendsList_Update
    -- ============================================================
    local refreshFriendRows  -- forward decl，deferFit 内调
    do
        local sf = FriendsFrameFriendsScrollFrame
        if sf then
            -- vanilla button 改用 SetAlpha(0) 隐形 + EnableMouse(false)：保留 vanilla 状态机
            -- vanilla FriendsList_Update 会循环 button:Show()，Hide 会被反复 Show 回来
            -- SetAlpha(0) 让 vanilla 怎么 Show 都视觉透明；子 FontString 也单独 alpha=0 + 清空文本
            -- pfUI 等成熟插件用同样手法
            local function hideVanillaButton(i)
                local b = _G["FriendsFrameFriendButton"..i]
                if not b then return end
                b:SetAlpha(0)
                b:EnableMouse(false)
                local suffixes = {"ButtonTextName", "ButtonTextNameLocation", "ButtonTextLocation", "ButtonTextInfo"}
                for j = 1, table.getn(suffixes) do
                    local fs = _G["FriendsFrameFriendButton"..i..suffixes[j]]
                    if fs then fs:SetAlpha(0); fs:SetText("") end
                end
            end
            for i = 1, (FRIENDS_TO_DISPLAY or 10) do
                hideVanillaButton(i)
            end

            -- class loc 名 → token 反查（GetFriendInfo 返回 localized class，如 "战士"）
            -- 优先用 LOCALIZED_CLASS_NAMES_MALE（vanilla 1.12 可能不存在），fallback 硬编码 zhCN/enUS
            local CLASS_TOKEN_BY_LOC = {
                -- zhCN（vanilla 1.12）
                ["战士"]="WARRIOR", ["法师"]="MAGE", ["猎人"]="HUNTER", ["盗贼"]="ROGUE",
                ["牧师"]="PRIEST", ["术士"]="WARLOCK", ["萨满祭司"]="SHAMAN",
                ["德鲁伊"]="DRUID", ["圣骑士"]="PALADIN",
                -- enUS 兜底
                ["Warrior"]="WARRIOR", ["Mage"]="MAGE", ["Hunter"]="HUNTER", ["Rogue"]="ROGUE",
                ["Priest"]="PRIEST", ["Warlock"]="WARLOCK", ["Shaman"]="SHAMAN",
                ["Druid"]="DRUID", ["Paladin"]="PALADIN",
            }
            if LOCALIZED_CLASS_NAMES_MALE then
                for token, locName in pairs(LOCALIZED_CLASS_NAMES_MALE) do
                    CLASS_TOKEN_BY_LOC[locName] = token
                end
            end
            if LOCALIZED_CLASS_NAMES_FEMALE then
                for token, locName in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
                    CLASS_TOKEN_BY_LOC[locName] = token
                end
            end
            local function getClassColor(class)
                if not class then return 1, 1, 1 end
                local token = CLASS_TOKEN_BY_LOC[class] or class
                local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
                if c then return c.r, c.g, c.b end
                return 1, 1, 1
            end

            local STATUS_DOT = {
                online  = {0.20, 0.85, 0.20},
                offline = {0.45, 0.45, 0.45},
                afk     = {1.00, 0.82, 0.00},
                dnd     = {0.85, 0.20, 0.20},
            }

            -- name → class 缓存：vanilla GetFriendInfo 离线时 class 可能为 nil
            -- 在线时记录，离线时查回 → 离线行仍能显示职业色（与 ShaguTweaks 行为一致）
            local friendClassCache = {}

            -- 我们独立跟踪用户实际点选的好友 ID（不依赖 vanilla selectedFriend）
            -- 根因：vanilla FriendsList_Update 自动设 selectedFriend=1（默认选第一个），
            -- 导致 row 1 自动锁选中。改用 mySelectedFriendID 我们自己管理。
            local mySelectedFriendID = nil
            local mySelectedFriendName = nil
            local updateFriendButtons  -- forward decl：底部四按钮 enable 联动，按钮创建后赋值

            -- 用 DFUI.CreateSocialRow 工厂统一创建 row（hover/sel/click 内置）
            local function onFriendLeftClick(row)
                if not row.friendID then return end
                mySelectedFriendID = row.friendID
                mySelectedFriendName = row.name
                FriendsFrame.selectedFriend = row.friendID  -- vanilla 同步（底部按钮 enable）
                FriendsList_Update()
                if FriendsFrame_Update then FriendsFrame_Update() end
                if updateFriendButtons then updateFriendButtons() end
            end
            local function onFriendRightClick(row)
                if not row.friendID then return end
                FriendsFrame.selectedFriend = row.friendID
                if FriendsFrame_Update then FriendsFrame_Update() end
                -- 自定义 dropdown（不调 UnitPopup_ShowMenu，避免 CheckInteractDistance nil unit 报错）
                FriendsDropDown.displayMode = "MENU"
                FriendsDropDown.initialize = function()
                    local info
                    info = {}; info.text = WHISPER or "悄悄话"; info.notCheckable = 1
                    info.func = function() if row.name then ChatFrame_SendTell(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = PARTY_INVITE or "邀请加入队伍"; info.notCheckable = 1
                    info.func = function() if row.name and InviteUnit then InviteUnit(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = IGNORE_PLAYER or "屏蔽玩家"; info.notCheckable = 1
                    info.func = function() if row.name and AddIgnore then AddIgnore(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = REMOVE_FRIEND or "移除好友"; info.notCheckable = 1
                    info.func = function() if row.name and RemoveFriend then RemoveFriend(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = CANCEL or "取消"; info.notCheckable = 1
                    info.func = function() end
                    UIDropDownMenu_AddButton(info)
                end
                ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
            end
            for i = 1, FRIEND_ROWS do
                DFUI.CreateSocialRow(sf, {
                    name       = "DFUI_FriendRow"..i,
                    frameLevel = sf:GetFrameLevel() + 10,
                    columns = {
                        -- 去掉状态点（dot），title.offsetX=18 保持原 title 起始 X
                        -- （之前 dot 占 4+9=13，title offsetX=5 → 18）
                        -- 列宽收窄让三框不相交：title 框[4,100] / lc 框[104,192] /
                        -- zoneText 框[201,293]，lc 与 zone 间留 9px。配合 refreshFriendRows
                        -- 里的 DFUI.TruncateToWidth 像素截断，文本不溢出各自框、永不重叠。
                        { name="title",    type="fontstring", width=96,
                          font="GameFontNormalSmall", color="main",
                          anchor="LEFT", offsetX=4 },
                        { name="lc",       type="fontstring", width=88,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        -- 地区左锚填充[196,293]：左对齐紧跟 lc，宽填到行右；status 独立右锚。
                        -- 无 status 时地区可用满整框；有 status 时按 status 实宽动态截断(见 refresh)。
                        { name="zoneText", type="fontstring", width=97,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        -- status(<暂离>/<勿扰>)：无固定宽(自适应文本)，右锚贴行右、右对齐独立显示
                        { name="status",   type="fontstring",
                          font="GameFontNormalSmall", color="next_",
                          anchor="RIGHT", offsetX=-8 },
                    },
                    onLeftClick   = onFriendLeftClick,
                    onRightClick  = onFriendRightClick,
                    onDoubleClick = function(row)
                        if row.name and ChatFrame_SendTell then ChatFrame_SendTell(row.name) end
                    end,
                    onWheel = function()
                        if FriendsList_Update then FriendsList_Update() end
                    end,
                })
            end

            -- 行高固定 20px（三 tab 一致），行数自适应 SF.h
            local FIXED_ROW_H = 18
            local visibleRows = 0
            local function layoutRows()
                -- 1.12 GetHeight 在双锚未完全 reflow 时返回脏值，GetTop-GetBottom 才准
                -- 参考 [reference-wow112-frame-size-pitfalls]，fallback GetHeight 覆盖极短窗口
                local t, b = sf:GetTop(), sf:GetBottom()
                local h = (t and b and (t-b) > 0) and (t-b) or sf:GetHeight()
                if not h or h <= 0 then visibleRows = 0; return false end
                visibleRows = math.floor(h / FIXED_ROW_H)
                if visibleRows > FRIEND_ROWS then visibleRows = FRIEND_ROWS end
                if visibleRows < 1 then visibleRows = 1 end
                for i = 1, FRIEND_ROWS do
                    local row = _G["DFUI_FriendRow"..i]
                    if i <= visibleRows then
                        row:ClearAllPoints()
                        row:SetPoint("TOPLEFT",  sf, "TOPLEFT",  0, -(i - 1) * FIXED_ROW_H)
                        row:SetPoint("TOPRIGHT", sf, "TOPRIGHT", 0, -(i - 1) * FIXED_ROW_H)
                        row:SetHeight(FIXED_ROW_H)
                    else
                        row:Hide()
                    end
                end
                return true
            end

            refreshFriendRows = function()
                -- vanilla FriendsList_Update 每次会 SetText 子 FontString + button:Show()
                -- 我们用 SetAlpha(0) 让按钮视觉透明，但 SetText 后字串还在；需每次清空 text + alpha 兜底
                for i = 1, MAX_ROWS do hideVanillaButton(i) end
                if not layoutRows() then return end
                local off = (FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(sf)) or 0
                local numTotal = (GetNumFriends and GetNumFriends()) or 0
                for i = 1, visibleRows do
                    local row = _G["DFUI_FriendRow"..i]
                    local idx = off + i
                    if idx <= numTotal then
                        local name, level, class, zone, connected, status = GetFriendInfo(idx)
                        if name then
                            row.friendID = idx
                            row.name = name
                            -- 缓存职业（在线时记录，离线 class=nil 时回退缓存）
                            if class and class ~= "" then
                                friendClassCache[name] = class
                            elseif friendClassCache[name] then
                                class = friendClassCache[name]
                            end
                            local lvlStr = level and level ~= 0 and ("Lv"..level) or ""
                            local lcText = lvlStr ~= "" and class and (lvlStr.." "..class) or lvlStr
                            local cr, cg, cb = getClassColor(class)
                            row.title:SetText(name)
                            row.lc:SetText(DFUI.TruncateToWidth(lcText, 86))  -- lc 框 88 − 2px padding
                            if connected then
                                row.title:SetTextColor(cr, cg, cb)
                                local lvl = tonumber(level)
                                local lc = lvl and GetDifficultyColor and GetDifficultyColor(lvl) or nil
                                if lc then row.lc:SetTextColor(lc.r, lc.g, lc.b) else row.lc:SetTextColor(1, 1, 1) end
                                -- 地区左锚 + status 右锚独立：量 status 实宽给地区留右侧空间再截断。
                                -- 无 status 时地区用满 95px(框97−2)；有 status 留 6px 间隔，整行单行。
                                local hasStatus = status and status ~= ""
                                local statusW = hasStatus and (DFUI.MeasureWidth(status) or 0) or 0
                                local zoneBudget = hasStatus and (97 - statusW - 6) or 95
                                if zoneBudget < 16 then zoneBudget = 16 end
                                row.zoneText:SetText(DFUI.TruncateToWidth(zone or "", zoneBudget))
                                row.zoneText:SetTextColor(1, 1, 1)
                                if hasStatus then
                                    row.status:SetText(status)
                                    row.status:SetTextColor(1.00, 0.82, 0.00)  -- 黄：AFK/DND 标记
                                else
                                    row.status:SetText("")
                                end
                            else
                                -- 离线：职业色 + alpha 0.5（与 ShaguTweaks 聊天插件风格一致）
                                row.title:SetTextColor(cr, cg, cb, 0.5)
                                row.lc:SetTextColor(cr, cg, cb, 0.5)
                                -- 离线 zoneText 显示 "<离线>" 标签（灰 + alpha，不染职业色）
                                row.zoneText:SetText(FRIENDS_LIST_OFFLINE or "<离线>")
                                row.zoneText:SetTextColor(0.5, 0.5, 0.5, 0.5)
                                row.status:SetText("")  -- 离线无 status
                            end
                            row:SetSelected(mySelectedFriendID == idx)
                            row:Show()
                        else
                            row.friendID = nil
                            row:Hide()
                        end
                    else
                        row.friendID = nil
                        row:Hide()
                    end
                end
                -- 覆盖 vanilla scrollbar maxV：vanilla FauxScrollFrame_Update 用 FRIENDS_TO_DISPLAY=10
                -- × itemHeight=16 计算；我们 visibleRows × FIXED_ROW_H 才对应实际显示行
                local sb = sf.GetName and getglobal(sf:GetName().."ScrollBar")
                if sb and sb.SetMinMaxValues then
                    local maxV = math.max(0, (numTotal - visibleRows) * FIXED_ROW_H)
                    sb:SetMinMaxValues(0, maxV)
                end
            end

            -- hook vanilla FriendsList_Update：FauxScrollFrame 滚动 / 数据变化都会触发
            -- 与 ShaguTweaks 共存（它 hook 同函数改 vanilla button 文字，对已 hide 的 button 无视觉影响）
            if hooksecurefunc then hooksecurefunc("FriendsList_Update", refreshFriendRows) end

            -- 数据变化兜底（vanilla 大多走 FriendsList_Update，但事件直接触发也安全）
            local refreshFrame = CreateFrame("Frame")
            refreshFrame:RegisterEvent("FRIENDLIST_UPDATE")
            refreshFrame:SetScript("OnEvent", function() refreshFriendRows() end)

            -- 治本兜底：inset OnShow 时延迟一帧刷新（覆盖 hook 静默失败 / Tab callback 重复 Show 不触发 OnShow）
            HookScript(friendsInset, "OnShow", function()
                deferOneFrame(function() safeRefresh(friendsInset, sf, refreshFriendRows) end)
            end)

            -- 隐藏 vanilla 底部四按钮（自制替换）：alpha0+EnableMouse(false) 持久，Hide 加固
            local vBtns = { FriendsFrameAddFriendButton, FriendsFrameSendMessageButton, FriendsFrameRemoveFriendButton, FriendsFrameGroupInviteButton }
            for vi = 1, table.getn(vBtns) do
                local vb = vBtns[vi]
                if vb then vb:SetAlpha(0); vb:EnableMouse(false); vb:Hide() end
            end

            -- 自制底部四按钮（两排两列）。容器 fBtnHolder 跟 FriendsListFrame 显隐（屏蔽/其他 tab 不显示好友按钮）
            local fBtnHolder = CreateFrame("Frame", nil, friendsInset)
            fBtnHolder:SetAllPoints(friendsInset)
            local fBtnAdd = DFUI.CreateActionButton(fBtnHolder, 110, "添加好友", function()
                if StaticPopup_Show then StaticPopup_Show("ADD_FRIEND") end
            end, 22)
            fBtnAdd:SetPoint("TOPLEFT", friendsInset, "BOTTOMLEFT", 27, -10)
            local fBtnSend = DFUI.CreateActionButton(fBtnHolder, 110, "发送信息", function()
                if mySelectedFriendName and ChatFrame_SendTell then ChatFrame_SendTell(mySelectedFriendName) end
            end, 22)
            fBtnSend:SetPoint("TOPLEFT", friendsInset, "BOTTOMLEFT", 189, -10)  -- 右列独立锚，与左列均匀对称（左/中/右间距≈52）
            local fBtnRemove = DFUI.CreateActionButton(fBtnHolder, 110, "删除好友", function()
                if mySelectedFriendName and RemoveFriend then RemoveFriend(mySelectedFriendName) end
            end, 22)
            fBtnRemove:SetPoint("TOPLEFT", fBtnAdd, "BOTTOMLEFT", 0, -6)
            local fBtnInvite = DFUI.CreateActionButton(fBtnHolder, 110, "组队邀请", function()
                if mySelectedFriendName then
                    if InviteUnit then InviteUnit(mySelectedFriendName)
                    elseif InviteByName then InviteByName(mySelectedFriendName) end
                end
            end, 22)
            fBtnInvite:SetPoint("TOPLEFT", fBtnSend, "BOTTOMLEFT", 0, -6)

            -- 选中联动：未选好友时 发送/删除/组队 禁用（添加常亮）
            updateFriendButtons = function()
                local on = mySelectedFriendName ~= nil
                fBtnSend:SetEnabledDF(on)
                fBtnRemove:SetEnabledDF(on)
                fBtnInvite:SetEnabledDF(on)
            end
            updateFriendButtons()

            -- 好友按钮只在好友 tab（FriendsListFrame）显示，屏蔽/其他 tab 隐藏
            if FriendsListFrame then
                HookScript(FriendsListFrame, "OnShow", function() fBtnHolder:Show() end)
                HookScript(FriendsListFrame, "OnHide", function() fBtnHolder:Hide() end)
                if not FriendsListFrame:IsShown() then fBtnHolder:Hide() end
            end
        end
    end

    -- ============================================================
    -- 自建 Who row 系统（DFUI_WhoRow1..17）—— 同 FriendRow 思路
    -- vanilla WhoFrameButton SetAlpha(0) + 清子 FontString，工厂创建紧凑单行 row
    -- ============================================================
    local refreshWhoRows
    do
        local sfWho = WhoListScrollFrame
        if sfWho then
            local WHO_ROWS = 24  -- 建足量 frame，实际显示由 floor(sf高/18) 决定，自动填满 inset（解耦 vanilla WHOS_TO_DISPLAY）

            -- class loc 名 → token 反查（GetWhoInfo 返回 localized class，如 "战士"）
            -- 优先用 LOCALIZED_CLASS_NAMES_MALE（vanilla 1.12 可能不存在），fallback hardcoded zhCN/enUS
            -- 与聊天窗口职业色（ShaguTweaks RAID_CLASS_COLORS[L["class"][class]]）颜色源一致
            local WHO_CLASS_TOKEN = {
                ["战士"]="WARRIOR", ["法师"]="MAGE", ["猎人"]="HUNTER", ["盗贼"]="ROGUE",
                ["牧师"]="PRIEST", ["术士"]="WARLOCK", ["萨满祭司"]="SHAMAN",
                ["德鲁伊"]="DRUID", ["圣骑士"]="PALADIN",
                ["Warrior"]="WARRIOR", ["Mage"]="MAGE", ["Hunter"]="HUNTER", ["Rogue"]="ROGUE",
                ["Priest"]="PRIEST", ["Warlock"]="WARLOCK", ["Shaman"]="SHAMAN",
                ["Druid"]="DRUID", ["Paladin"]="PALADIN",
            }
            if LOCALIZED_CLASS_NAMES_MALE then
                for token, locName in pairs(LOCALIZED_CLASS_NAMES_MALE) do
                    WHO_CLASS_TOKEN[locName] = token
                end
            end
            local function getWhoClassColor(class)
                if not class then return 0.94, 0.75, 0.38 end
                local token = WHO_CLASS_TOKEN[class] or class
                local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
                if c then return c.r, c.g, c.b end
                return 0.94, 0.75, 0.38
            end

            local function hideVanillaWhoBtn(i)
                local b = _G["WhoFrameButton"..i]
                if not b then return end
                b:SetAlpha(0); b:Hide(); b:EnableMouse(false)
                local suffixes = {"Name", "Variable", "Class", "Level"}
                for j = 1, table.getn(suffixes) do
                    local fs = _G["WhoFrameButton"..i..suffixes[j]]
                    if fs then fs:SetAlpha(0); fs:SetText("") end
                end
            end
            for i = 1, WHO_ROWS do hideVanillaWhoBtn(i) end

            -- 独立跟踪用户实际点选的 Who 索引/名字（避免 vanilla WhoList_Update 自动设 selectedWho）
            local mySelectedWhoIdx = nil
            local mySelectedWhoName = nil
            local updateWhoButtons  -- forward decl：底部按钮 enable 联动，按钮创建后赋值
            local whoSortType = "zone"  -- 第4列分类：zone/guild/race（下拉切换，替代 vanilla WhoFrameDropDown）
            local WHO_SORT_LABEL = { zone = "地区", guild = "公会", race = "种族" }

            local function onWhoLeftClick(row)
                if not row.whoIdx then return end
                mySelectedWhoIdx = row.whoIdx
                mySelectedWhoName = row.name
                WhoFrame.selectedWho = row.whoIdx
                WhoFrame.selectedName = row.name
                if WhoList_Update then WhoList_Update() end
                if updateWhoButtons then updateWhoButtons() end
            end
            local function onWhoRightClick(row)
                if not row.whoIdx then return end
                WhoFrame.selectedWho = row.whoIdx
                WhoFrame.selectedName = row.name
                if WhoList_Update then WhoList_Update() end
                -- 自定义 dropdown：Who 列表玩家可能不是好友，菜单加"添加好友"
                FriendsDropDown.displayMode = "MENU"
                FriendsDropDown.initialize = function()
                    local info
                    info = {}; info.text = WHISPER or "悄悄话"; info.notCheckable = 1
                    info.func = function() if row.name then ChatFrame_SendTell(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = PARTY_INVITE or "邀请加入队伍"; info.notCheckable = 1
                    info.func = function() if row.name and InviteUnit then InviteUnit(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = ADD_FRIEND or "添加好友"; info.notCheckable = 1
                    info.func = function() if row.name and AddFriend then AddFriend(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = IGNORE_PLAYER or "屏蔽玩家"; info.notCheckable = 1
                    info.func = function() if row.name and AddIgnore then AddIgnore(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = CANCEL or "取消"; info.notCheckable = 1
                    info.func = function() end
                    UIDropDownMenu_AddButton(info)
                end
                ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
            end

            -- 全自制 who：行挂 whoInset（脱离 vanilla WhoListScrollFrame，免被 FauxScrollFrame_Update 连带 Hide）
            -- visibleRowsWho/whoOffset 提到行创建前声明，供 onWheel 闭包捕获
            local visibleRowsWho = 0
            local whoOffset = 0
            for i = 1, WHO_ROWS do
                DFUI.CreateSocialRow(whoInset, {
                    name       = "DFUI_WhoRow"..i,
                    frameLevel = whoInset:GetFrameLevel() + 10,
                    columns = {
                        { name="title", type="fontstring", width=85,
                          font="GameFontNormalSmall", color="main",
                          anchor="LEFT", offsetX=8 },
                        { name="lvl",   type="fontstring", width=24,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        { name="class", type="fontstring", width=78,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        -- 收窄(120→86)让 zone 框[213,299]不压 class 框[125,203]；
                        -- justifyH="LEFT" 与前三列一致左对齐排表格，溢出由 TruncateToWidth 截断
                        { name="zoneText", type="fontstring", width=86,
                          font="GameFontNormalSmall", color="next_",
                          anchor="RIGHT", justifyH="LEFT", offsetX=-8 },
                    },
                    onLeftClick   = onWhoLeftClick,
                    onRightClick  = onWhoRightClick,
                    onDoubleClick = function(row)
                        if row.name and ChatFrame_SendTell then ChatFrame_SendTell(row.name) end
                    end,
                    onWheel = function()
                        -- 自管翻页：arg1=1 上滚（offset 减）/ -1 下滚（offset 加）
                        local numTotal = (GetNumWhoResults and GetNumWhoResults()) or 0
                        local maxOff = math.max(0, numTotal - visibleRowsWho)
                        whoOffset = whoOffset - (arg1 or 0)
                        if whoOffset < 0 then whoOffset = 0 elseif whoOffset > maxOff then whoOffset = maxOff end
                        refreshWhoRows()
                    end,
                })
            end

            local FIXED_ROW_H_WHO = 18
            local COLHDR_OFFSET_WHO = 24  -- 列头完全在 inset 顶部内侧，row1 起点下移 24px
            local function layoutWhoRows()
                -- 基准换 whoInset（DFUI 自有容器，几何可控）：GetTop-GetBottom 优先，GetHeight fallback
                local t, b = whoInset:GetTop(), whoInset:GetBottom()
                local h = (t and b and (t-b) > 0) and (t-b) or whoInset:GetHeight()
                if not h or h <= 0 then visibleRowsWho = 0; return false end
                local availH = h - COLHDR_OFFSET_WHO
                visibleRowsWho = math.floor(availH / FIXED_ROW_H_WHO)
                if visibleRowsWho > WHO_ROWS then visibleRowsWho = WHO_ROWS end
                if visibleRowsWho < 1 then visibleRowsWho = 1 end
                for i = 1, WHO_ROWS do
                    local row = _G["DFUI_WhoRow"..i]
                    if i <= visibleRowsWho then
                        local y = -((i - 1) * FIXED_ROW_H_WHO + COLHDR_OFFSET_WHO)
                        row:ClearAllPoints()
                        row:SetPoint("TOPLEFT",  whoInset, "TOPLEFT",  0, y)
                        row:SetPoint("TOPRIGHT", whoInset, "TOPRIGHT", -24, y)  -- 右留 24px 给 vanilla scrollbar 金箭头，列表/zoneText 不压箭头
                        row:SetHeight(FIXED_ROW_H_WHO)
                    else
                        row:Hide()
                    end
                end
                return true
            end

            refreshWhoRows = function()
                for i = 1, WHO_ROWS do hideVanillaWhoBtn(i) end
                if not layoutWhoRows() then return end
                local off = whoOffset
                local numTotal = (GetNumWhoResults and GetNumWhoResults()) or 0
                -- 自管 offset：新查询结果骤减时旧偏移越界 → 钳回合法范围；结果 ≤ 可见行数时 maxOff=0 回到顶部
                local maxOff = math.max(0, numTotal - visibleRowsWho)
                if off > maxOff then off = maxOff end
                whoOffset = off
                for i = 1, visibleRowsWho do
                    local row = _G["DFUI_WhoRow"..i]
                    local idx = off + i
                    if idx <= numTotal then
                        local name, guild, level, race, class, zone = GetWhoInfo(idx)
                        if name then
                            row.whoIdx = idx
                            row.name = name
                            row.title:SetText(name)
                            local cr, cg, cb = getWhoClassColor(class)
                            row.title:SetTextColor(cr, cg, cb)
                            row.lvl:SetText(level or "")
                            local lvl = tonumber(level)
                            local lc = lvl and GetDifficultyColor and GetDifficultyColor(lvl) or nil
                            if lc then row.lvl:SetTextColor(lc.r, lc.g, lc.b)
                            else row.lvl:SetTextColor(1, 1, 1) end
                            row.class:SetText(class or "")
                            row.class:SetTextColor(cr, cg, cb)
                            local whoVar = (whoSortType == "guild" and guild) or (whoSortType == "race" and race) or zone
                            row.zoneText:SetText(DFUI.TruncateToWidth(whoVar or "", 84))  -- 84 = zone 框 86 − 2px
                            row.zoneText:SetTextColor(1, 1, 1)
                            row:SetSelected(mySelectedWhoIdx == idx)
                            row:Show()
                        else
                            row.whoIdx = nil; row:Hide()
                        end
                    else
                        row.whoIdx = nil; row:Hide()
                    end
                end
                -- 第4列列头文字跟当前分类（防 WhoFrame OnShow 重置 vanilla 列头）
                if WhoFrameColumnHeader2 and WhoFrameColumnHeader2.GetFontString then
                    local h2fs = WhoFrameColumnHeader2:GetFontString()
                    if h2fs then h2fs:SetText(WHO_SORT_LABEL[whoSortType] or "地区") end
                end
            end

            -- vanilla WhoList_Update 会 Show/SetText 原生 WhoFrameButton；必须让 DFUI 的
            -- hideVanillaWhoBtn 在它之后收尾，否则有查询时 vanilla 残留文字会盖住自制列表
            -- （空查询走 OnShow 不经 WhoList_Update 所以正常）。故 append=true（old-before-new）。
            if hooksecurefunc then hooksecurefunc("WhoList_Update", refreshWhoRows, true) end

            local refreshFrameWho = CreateFrame("Frame")
            refreshFrameWho:RegisterEvent("WHO_LIST_UPDATE")
            refreshFrameWho:SetScript("OnEvent", function()
                -- 新查询结果到达：清旧选中（与 vanilla WhoList_SetSelectedButton(nil) 一致，防加好友/组队误指旧人）
                mySelectedWhoIdx = nil; mySelectedWhoName = nil
                if updateWhoButtons then updateWhoButtons() end
                refreshWhoRows()
            end)

            -- 治本兜底：whoInset OnShow 时延迟一帧刷新
            HookScript(whoInset, "OnShow", function()
                deferOneFrame(function() safeRefresh(whoInset, whoInset, refreshWhoRows) end)
            end)

            -- 重锚 WhoFrameColumnHeader1..4 到 whoInset 内 + 列宽匹配 row 列布局
            -- vanilla 4 列默认顺序: Header1=Name / Header2=Variable / Header3=Level / Header4=Class
            -- 我们 row 视觉顺序: title(85) lvl(24) class(55) zoneText(RIGHT,100)
            -- 列头按视觉顺序锚: Header1(Name→title, w=85) → Header3(Level→lvl, w=28) → Header4(Class→class, w=59) → Header2(Variable→zone, w=104)
            if WhoFrameColumnHeader1 then
                local function nukeHdr(h)
                    if not h then return end
                    if h.SetNormalTexture then h:SetNormalTexture(nil) end
                    local rs = {h:GetRegions()}
                    for k = 1, table.getn(rs) do
                        local r = rs[k]
                        if r.GetObjectType and r:GetObjectType() == "Texture" then r:SetTexture(nil) end
                    end
                    -- 列头 FontString 左对齐（与 row 文字对齐）；第4列单独居中见下
                    local fs = h.GetFontString and h:GetFontString()
                    if fs then
                        fs:ClearAllPoints()
                        fs:SetPoint("LEFT", h, "LEFT", 4, 0)
                        fs:SetJustifyH("LEFT")
                    end
                end
                nukeHdr(WhoFrameColumnHeader1); nukeHdr(WhoFrameColumnHeader2)
                nukeHdr(WhoFrameColumnHeader3); nukeHdr(WhoFrameColumnHeader4)
                -- 列头 BOTTOM 锚 whoInset.TOP 上方 1px（紧贴 inset 上边外侧，不超出过多）
                -- 之前锚 sfWho.TOP+2 会让列头底距 inset.TOP -2px（即列头本体 22px 超 inset 上边框）
                -- 设计 B：列头跨越 inset 上边框（DF retail 风格）
                -- BOTTOM 在 inset.TOP 下方 12px，列头本体（24px 高）中心穿过边框线
                WhoFrameColumnHeader1:ClearAllPoints()
                WhoFrameColumnHeader1:SetPoint("BOTTOMLEFT", whoInset, "TOPLEFT", 4, -24)
                WhoFrameColumnHeader1:SetWidth(85 + 8)
                WhoFrameColumnHeader3:ClearAllPoints()
                WhoFrameColumnHeader3:SetPoint("LEFT", WhoFrameColumnHeader1, "RIGHT", 0, 0)
                WhoFrameColumnHeader3:SetWidth(24 + 4)
                WhoFrameColumnHeader4:ClearAllPoints()
                WhoFrameColumnHeader4:SetPoint("LEFT", WhoFrameColumnHeader3, "RIGHT", 0, 0)
                WhoFrameColumnHeader4:SetWidth(78 + 4)
                WhoFrameColumnHeader2:ClearAllPoints()
                WhoFrameColumnHeader2:SetPoint("BOTTOMRIGHT", whoInset, "TOPRIGHT", -20, -24)
                WhoFrameColumnHeader2:SetWidth(120)
                -- 第4列单独居中 + 右侧金箭头（同滚动条风格）作下拉指示
                local h2fs = WhoFrameColumnHeader2.GetFontString and WhoFrameColumnHeader2:GetFontString()
                if h2fs then
                    h2fs:ClearAllPoints()
                    h2fs:SetPoint("CENTER", WhoFrameColumnHeader2, "CENTER", 0, 0)
                    h2fs:SetJustifyH("CENTER")
                end
                if WhoFrameColumnHeader2.SetHighlightTexture then WhoFrameColumnHeader2:SetHighlightTexture(nil) end
                local h2arrow = WhoFrameColumnHeader2:CreateTexture(nil, "OVERLAY")
                h2arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")  -- 确定存在的金箭头素材（同右侧滚动条）；highlight 已清，静态不闪
                h2arrow:SetWidth(20); h2arrow:SetHeight(20)
                h2arrow:SetPoint("RIGHT", WhoFrameColumnHeader2, "RIGHT", -2, 0)
                h2arrow:SetVertexColor(0.98, 0.91, 0.58)
                -- 箭头按下动画：点列头时切按下纹理 + 下移 1px，松开还原（h2arrow 非 Button 无内置态）
                WhoFrameColumnHeader2:SetScript("OnMouseDown", function()
                    h2arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
                    h2arrow:ClearAllPoints(); h2arrow:SetPoint("RIGHT", WhoFrameColumnHeader2, "RIGHT", -2, -1)
                end)
                WhoFrameColumnHeader2:SetScript("OnMouseUp", function()
                    h2arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
                    h2arrow:ClearAllPoints(); h2arrow:SetPoint("RIGHT", WhoFrameColumnHeader2, "RIGHT", -2, 0)
                end)

                -- 第4列分类下拉：地区/公会/种族（替代 vanilla WhoFrameDropDown）
                -- 列头作触发器，点击弹 FriendsDropDown（同右键菜单 API）；选中 → 设 whoSortType + SortWho 排序 + 刷新
                WhoFrameColumnHeader2:SetScript("OnClick", function()
                    FriendsDropDown.displayMode = "MENU"
                    FriendsDropDown.initialize = function()
                        local opts = { {t="地区",v="zone"}, {t="公会",v="guild"}, {t="种族",v="race"} }
                        for i = 1, table.getn(opts) do
                            local o = opts[i]
                            local info = {}
                            info.text = o.t
                            info.checked = (whoSortType == o.v)
                            info.func = function()
                                whoSortType = o.v
                                if SortWho then SortWho(o.v) end  -- 服务器按该列重排
                                refreshWhoRows()                  -- 即时切第4列显示 + 更新列头文字
                            end
                            UIDropDownMenu_AddButton(info)
                        end
                    end
                    ToggleDropDownMenu(1, nil, FriendsDropDown, "WhoFrameColumnHeader2", 0, 0)
                end)

                -- 隐藏 vanilla WhoFrameDropDown（Header2 的子 Frame、UIDropDownMenu）：它盖在列头上拦截鼠标，
                -- 导致上面的 OnClick 收不到点击 + 显示出 vanilla 灰下拉。alpha0+EnableMouse(false) 持久解除拦截。
                if WhoFrameDropDown then
                    WhoFrameDropDown:Hide(); WhoFrameDropDown:SetAlpha(0); WhoFrameDropDown:EnableMouse(false)
                end
                if WhoFrameDropDownButton then
                    WhoFrameDropDownButton:Hide(); WhoFrameDropDownButton:EnableMouse(false)
                end
            end

            -- 自建底部三按钮：刷新 / 添加好友 / 组队要求（替代 vanilla WhoFrameWhoButton/AddFriend/GroupInvite）
            -- 加好友/组队作用于选中行(mySelectedWhoName)，未选中时禁用；刷新用搜索框内容重发 SendWho。
            local whoBtnRefresh = DFUI.CreateActionButton(whoInset, 68, "刷新", function()
                dfuiTryWho(whoSearch:GetText())
            end, 22)
            -- 三按钮整体水平居中于 whoSearch：总宽 68+6+99+6+99=278，刷新中心偏移 -(278/2-68/2)=-105
            whoBtnRefresh:SetPoint("TOP", whoSearch, "BOTTOM", -105, -10)

            local whoBtnAdd = DFUI.CreateActionButton(whoInset, 99, "添加好友", function()
                if mySelectedWhoName and AddFriend then AddFriend(mySelectedWhoName) end
            end, 22)
            whoBtnAdd:SetPoint("LEFT", whoBtnRefresh, "RIGHT", 6, 0)

            local whoBtnInvite = DFUI.CreateActionButton(whoInset, 99, "组队邀请", function()
                if mySelectedWhoName then
                    if InviteUnit then InviteUnit(mySelectedWhoName)
                    elseif InviteByName then InviteByName(mySelectedWhoName) end
                end
            end, 22)
            whoBtnInvite:SetPoint("LEFT", whoBtnAdd, "RIGHT", 6, 0)

            -- 选中联动：未选中行时加好友/组队禁用（刷新始终可用）
            updateWhoButtons = function()
                local on = mySelectedWhoName ~= nil
                whoBtnAdd:SetEnabledDF(on)
                whoBtnInvite:SetEnabledDF(on)
            end
            updateWhoButtons()
        end
    end

    -- ============================================================
    -- 自建 Guild row 系统（DFUI_GuildRow1..GUILDMEMBERS_TO_DISPLAY）
    -- vanilla GuildFrameButton SetAlpha(0)，工厂创建 5 列单行 row
    -- ============================================================
    local refreshGuildRows
    do
        local sfGuild = GuildListScrollFrame
        if sfGuild then
            local GUILD_ROWS = 24  -- 建足量 frame，实际显示由 floor(sf高/18) 决定，自动填满 inset（解耦 vanilla GUILDMEMBERS_TO_DISPLAY）

            local function hideVanillaGuildBtn(i)
                local b = _G["GuildFrameButton"..i]
                if not b then return end
                b:SetAlpha(0); b:EnableMouse(false)
                local suffixes = {"Name", "Level", "Class", "Zone"}
                for j = 1, table.getn(suffixes) do
                    local fs = _G["GuildFrameButton"..i..suffixes[j]]
                    if fs then fs:SetAlpha(0); fs:SetText("") end
                end
            end
            for i = 1, GUILD_ROWS do hideVanillaGuildBtn(i) end

            -- roster 含离线成员：否则 GetNumGuildMembers()/列表只有在线 → "总人数"实为在线数。
            -- 设标志(持久) + 下方 OnShow 调 GuildRoster() 拉取；client 端再用 guildShowOffline 过滤显示。
            if SetGuildRosterShowOffline then SetGuildRosterShowOffline(1) end

            -- 独立跟踪用户实际点选的公会成员索引（避免 vanilla GuildStatus_Update 自动设 selection）
            local mySelectedGuildIdx = nil

            local function onGuildLeftClick(row)
                if not row.guildIdx then return end
                mySelectedGuildIdx = row.guildIdx
                if SetGuildRosterSelection then SetGuildRosterSelection(row.guildIdx) end
                if GuildStatus_Update then GuildStatus_Update() end
                if GuildFrame_Update then GuildFrame_Update() end
                -- vanilla GuildFrameButton OnClick 内会调 GuildMemberDetailFrame:Show()
                -- 我们 hide vanilla button 后这条路径丢失，手动补上（vanilla 自带 OnShow 填充数据）
                if GuildMemberDetailFrame then GuildMemberDetailFrame:Show() end
            end
            local function onGuildRightClick(row)
                if not row.guildIdx then return end
                if SetGuildRosterSelection then SetGuildRosterSelection(row.guildIdx) end
                if GuildStatus_Update then GuildStatus_Update() end
                if GuildFrame_Update then GuildFrame_Update() end
                -- 自定义 dropdown：公会成员
                FriendsDropDown.displayMode = "MENU"
                FriendsDropDown.initialize = function()
                    local info
                    info = {}; info.text = WHISPER or "悄悄话"; info.notCheckable = 1
                    info.func = function() if row.name then ChatFrame_SendTell(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = PARTY_INVITE or "邀请加入队伍"; info.notCheckable = 1
                    info.func = function() if row.name and InviteUnit then InviteUnit(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = IGNORE_PLAYER or "屏蔽玩家"; info.notCheckable = 1
                    info.func = function() if row.name and AddIgnore then AddIgnore(row.name) end end
                    UIDropDownMenu_AddButton(info)
                    info = {}; info.text = CANCEL or "取消"; info.notCheckable = 1
                    info.func = function() end
                    UIDropDownMenu_AddButton(info)
                end
                ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
            end

            -- 全自制 guild：行挂 guildInset（脱离 vanilla GuildListScrollFrame，免被 FauxScrollFrame_Update 连带 Hide）
            -- visibleRowsGuild/guildOffset/guildSearchText 提到行创建前声明，供 onWheel 闭包/搜索框捕获
            local visibleRowsGuild = 0
            local guildOffset = 0
            local guildSearchText = ""
            local guildNumShown = 0  -- 过滤后成员数（refreshGuildRows 维护，onWheel 算 maxOff）
            local guildShowOffline = true  -- 显示离线成员开关（默认显示；接管 vanilla GuildFrameLFGButton）
            local updateGuildButtons  -- forward decl：底部三按钮 enable 镜像，按钮创建后赋值
            -- 底部「成员 N  在线 M」统计（玩家状态那行右侧），refreshGuildRows 实时更新
            -- 全局名便于运行时诊断/精调位置；锚 guildInset 右下（消除 dropdown 是否存在的分支歧义）
            local guildTotalsText = guildInset:CreateFontString("DFUI_GuildTotalsText", "OVERLAY", "GameFontNormalSmall")
            guildTotalsText:SetPoint("BOTTOMRIGHT", guildInset, "BOTTOMRIGHT", -204, 10)  -- 右下基准 -24,4 → 往左180、往上6
            guildTotalsText:SetJustifyH("RIGHT")
            guildTotalsText:SetTextColor(1, 1, 1)  -- base 白；标签金/数字白由内联颜色码控制
            for i = 1, GUILD_ROWS do
                DFUI.CreateSocialRow(guildInset, {
                    name       = "DFUI_GuildRow"..i,
                    frameLevel = guildInset:GetFrameLevel() + 10,
                    columns = {
                        -- 去掉状态点（dot），回收左侧死区：title.offsetX 18→4
                        { name="title",    type="fontstring", width=90,
                          font="GameFontNormalSmall", color="main",
                          anchor="LEFT", offsetX=4 },
                        { name="lvl",      type="fontstring", width=24,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        { name="class",    type="fontstring", width=78,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        -- 收窄(112→80)让 zone 框[213,293]不压 class 框[126,204]；
                        -- justifyH="LEFT" 与前三列一致左对齐排表格，溢出由 TruncateToWidth 截断
                        { name="zoneText", type="fontstring", width=80,
                          font="GameFontNormalSmall", color="next_",
                          anchor="RIGHT", justifyH="LEFT", offsetX=-8 },
                    },
                    onLeftClick   = onGuildLeftClick,
                    onRightClick  = onGuildRightClick,
                    onDoubleClick = function(row)
                        if row.name and ChatFrame_SendTell then ChatFrame_SendTell(row.name) end
                    end,
                    onWheel = function()
                        -- 自管翻页：arg1=1 上滚（offset 减）/ -1 下滚（offset 加）
                        local maxOff = math.max(0, guildNumShown - visibleRowsGuild)
                        guildOffset = guildOffset - (arg1 or 0)
                        if guildOffset < 0 then guildOffset = 0 elseif guildOffset > maxOff then guildOffset = maxOff end
                        refreshGuildRows()
                    end,
                })
            end

            local FIXED_ROW_H_GUILD = 18
            local COLHDR_OFFSET_GUILD = 24  -- 列头完全在 inset 顶部内侧
            local function layoutGuildRows()
                -- 基准换 guildInset（DFUI 自有容器）：GetTop-GetBottom 优先，GetHeight fallback
                local t, b = guildInset:GetTop(), guildInset:GetBottom()
                local h = (t and b and (t-b) > 0) and (t-b) or guildInset:GetHeight()
                if not h or h <= 0 then visibleRowsGuild = 0; return false end
                -- 底部再留一行高(18px)给 GuildFramePlayerStatusDropDown（玩家状态按钮），
                -- 避免末行盖住它（与 GuildListScrollFrame 的 18px 预留一致）。减整一行高 → 正好少显示一行
                local availH = h - COLHDR_OFFSET_GUILD - FIXED_ROW_H_GUILD
                visibleRowsGuild = math.floor(availH / FIXED_ROW_H_GUILD)
                if visibleRowsGuild > GUILD_ROWS then visibleRowsGuild = GUILD_ROWS end
                if visibleRowsGuild < 1 then visibleRowsGuild = 1 end
                for i = 1, GUILD_ROWS do
                    local row = _G["DFUI_GuildRow"..i]
                    if i <= visibleRowsGuild then
                        local y = -((i - 1) * FIXED_ROW_H_GUILD + COLHDR_OFFSET_GUILD)
                        row:ClearAllPoints()
                        row:SetPoint("TOPLEFT",  guildInset, "TOPLEFT",  0, y)
                        row:SetPoint("TOPRIGHT", guildInset, "TOPRIGHT", -24, y)  -- 右留 24px 给金箭头
                        row:SetHeight(FIXED_ROW_H_GUILD)
                    else
                        row:Hide()
                    end
                end
                return true
            end

            -- class loc → token 反查（与 FriendRow 共用思路，独立小表）
            local GUILD_CLASS_TOKEN = {
                ["战士"]="WARRIOR", ["法师"]="MAGE", ["猎人"]="HUNTER", ["盗贼"]="ROGUE",
                ["牧师"]="PRIEST", ["术士"]="WARLOCK", ["萨满祭司"]="SHAMAN",
                ["德鲁伊"]="DRUID", ["圣骑士"]="PALADIN",
                ["Warrior"]="WARRIOR", ["Mage"]="MAGE", ["Hunter"]="HUNTER", ["Rogue"]="ROGUE",
                ["Priest"]="PRIEST", ["Warlock"]="WARLOCK", ["Shaman"]="SHAMAN",
                ["Druid"]="DRUID", ["Paladin"]="PALADIN",
            }
            if LOCALIZED_CLASS_NAMES_MALE then
                for token, locName in pairs(LOCALIZED_CLASS_NAMES_MALE) do
                    GUILD_CLASS_TOKEN[locName] = token
                end
            end
            local function getGuildClassColor(class)
                if not class then return 0.94, 0.75, 0.38 end
                local token = GUILD_CLASS_TOKEN[class] or class
                local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
                if c then return c.r, c.g, c.b end
                return 0.94, 0.75, 0.38
            end

            -- 公会列表两 mode：玩家状态(职业/区域) ↔ 公会状态(注释/最后上线)
            -- vanilla 用两个互斥子 Frame：GuildPlayerStatusFrame / GuildStatusFrame，后者 IsShown 即公会状态
            local function isGuildStatusMode()
                return (GuildStatusFrame and GuildStatusFrame:IsShown()) and true or false
            end
            -- 「最后上线」中文格式化（retail 的 RecentTimeDate 在 1.12 不存在，自己写）
            local function guildLastOnlineText(idx)
                if not GetGuildRosterLastOnline then return "" end
                local y, mo, d, h = GetGuildRosterLastOnline(idx)
                y = y or 0; mo = mo or 0; d = d or 0; h = h or 0
                if y > 0 then return y.." 年前"
                elseif mo > 0 then return mo.." 个月前"
                elseif d > 0 then return d.." 天前"
                elseif h > 0 then return h.." 小时前"
                else return "刚刚" end
            end
            -- 压制整套 vanilla 公会状态视图 GuildStatusFrame：SetAlpha(0) 的 effective alpha 连其
            -- ~17 个子(列表 button + 自带列头)一并透明，保留 IsShown 作 mode 信号；EnableMouse(false)
            -- (含子)防透明子拦鼠标。自建 row 独立显示、接管公会状态数据。
            local function suppressGuildStatusFrame()
                if not GuildStatusFrame then return end
                GuildStatusFrame:SetAlpha(0)
                GuildStatusFrame:EnableMouse(false)
                local kids = { GuildStatusFrame:GetChildren() }
                for j = 1, table.getn(kids) do
                    if kids[j].EnableMouse then kids[j]:EnableMouse(false) end
                end
            end

            refreshGuildRows = function()
                for i = 1, GUILD_ROWS do hideVanillaGuildBtn(i) end
                suppressGuildStatusFrame()
                if not layoutGuildRows() then return end
                local gMode = isGuildStatusMode()
                -- 仅名字客户端过滤：构建匹配成员的原始 roster idx 名单（空搜索=全部）
                local filtered = {}
                local total = (GetNumGuildMembers and GetNumGuildMembers()) or 0
                local q = (guildSearchText ~= "" and string.lower(guildSearchText)) or nil
                local numOnline = 0
                for gi = 1, total do
                    local nm, _, _, _, _, _, _, _, onl = GetGuildRosterInfo(gi)
                    if onl then numOnline = numOnline + 1 end  -- 在线数：不受搜索/显示离线过滤影响
                    if nm and (guildShowOffline or onl) and (not q or string.find(string.lower(nm), q, 1, true)) then
                        table.insert(filtered, gi)
                    end
                end
                guildNumShown = table.getn(filtered)
                if guildTotalsText then
                    -- 标签金(ffffd100=NORMAL_FONT_COLOR，与"玩家状态"同款) + 数字白(与地区列一致)
                    guildTotalsText:SetText(string.format("|cffffd100成员|r |cffffffff%d|r  |cffffd100在线|r |cffffffff%d|r", total, numOnline))
                end
                local off = guildOffset
                local maxOff = math.max(0, guildNumShown - visibleRowsGuild)
                if off > maxOff then off = maxOff end
                guildOffset = off
                for i = 1, visibleRowsGuild do
                    local row = _G["DFUI_GuildRow"..i]
                    local fidx = off + i
                    if fidx <= guildNumShown then
                        local idx = filtered[fidx]  -- 原始 roster idx（点选/详情用对索引）
                        local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(idx)
                        if name then
                            row.guildIdx = idx
                            row.name = name
                            local cr, cg, cb = getGuildClassColor(class)
                            if online then
                                row.title:SetText(name)
                                row.title:SetTextColor(cr, cg, cb)
                                row.lvl:SetText(level or "")
                                local lvl = tonumber(level)
                                local lc = lvl and GetDifficultyColor and GetDifficultyColor(lvl) or nil
                                if lc then row.lvl:SetTextColor(lc.r, lc.g, lc.b)
                                else row.lvl:SetTextColor(1, 1, 1) end
                                if gMode then
                                    row.class:SetText(DFUI.TruncateToWidth(note or "", 76))
                                    row.class:SetTextColor(0.82, 0.82, 0.82)  -- 注释灰白
                                    row.zoneText:SetText("在线")
                                    row.zoneText:SetTextColor(0.1, 1, 0.1)    -- 在线绿
                                else
                                    row.class:SetText(class or "")
                                    row.class:SetTextColor(cr, cg, cb)
                                    row.zoneText:SetText(DFUI.TruncateToWidth(zone or "", 78))  -- 78 = zone 框 80 − 2px
                                    row.zoneText:SetTextColor(1, 1, 1)
                                end
                            else
                                -- 离线：职业色 + alpha 0.5（与 ShaguTweaks 聊天/Guild 染色风格一致）
                                row.title:SetText(name); row.title:SetTextColor(cr, cg, cb, 0.5)
                                row.lvl:SetText(level or ""); row.lvl:SetTextColor(cr, cg, cb, 0.5)
                                if gMode then
                                    row.class:SetText(DFUI.TruncateToWidth(note or "", 76)); row.class:SetTextColor(cr, cg, cb, 0.5)
                                    row.zoneText:SetText(guildLastOnlineText(idx)); row.zoneText:SetTextColor(cr, cg, cb, 0.5)
                                else
                                    row.class:SetText(class or ""); row.class:SetTextColor(cr, cg, cb, 0.5)
                                    row.zoneText:SetText(DFUI.TruncateToWidth(zone or "", 78)); row.zoneText:SetTextColor(cr, cg, cb, 0.5)
                                end
                            end
                            row:SetSelected(mySelectedGuildIdx == idx)
                            row:Show()
                        else
                            row.guildIdx = nil; row:Hide()
                        end
                    else
                        row.guildIdx = nil; row:Hide()
                    end
                end
                -- 列头第3/4列随 mode：玩家「职业/区域」↔ 公会「注释/最后上线」（Header4=col3, Header2=col4）
                if GuildFrameColumnHeader4 and GuildFrameColumnHeader4.GetFontString then
                    local fs4 = GuildFrameColumnHeader4:GetFontString(); if fs4 then fs4:SetText(gMode and "注释" or "职业") end
                end
                if GuildFrameColumnHeader2 and GuildFrameColumnHeader2.GetFontString then
                    local fs2 = GuildFrameColumnHeader2:GetFontString(); if fs2 then fs2:SetText(gMode and "最后上线" or "区域") end
                end
                if updateGuildButtons then updateGuildButtons() end
            end

            if hooksecurefunc then hooksecurefunc("GuildStatus_Update", refreshGuildRows) end

            -- 切 mode = vanilla 切换 GuildPlayerStatusFrame/GuildStatusFrame 显隐 → 两者 OnShow 都刷新自建列表+列头
            if GuildStatusFrame then
                HookScript(GuildStatusFrame, "OnShow", function() guildOffset = 0; refreshGuildRows() end)
            end
            if GuildPlayerStatusFrame then
                HookScript(GuildPlayerStatusFrame, "OnShow", function() guildOffset = 0; refreshGuildRows() end)
            end

            local refreshFrameGuild = CreateFrame("Frame")
            refreshFrameGuild:RegisterEvent("GUILD_ROSTER_UPDATE")
            refreshFrameGuild:SetScript("OnEvent", function() refreshGuildRows() end)

            -- 治本兜底：guildInset OnShow 时延迟一帧刷新
            HookScript(guildInset, "OnShow", function()
                if SetGuildRosterShowOffline then SetGuildRosterShowOffline(1) end  -- 防 vanilla dropdown 改回
                if GuildRoster then GuildRoster() end  -- 拉取含离线的最新 roster（服务器节流安全）
                deferOneFrame(function() safeRefresh(guildInset, sfGuild, refreshGuildRows) end)
            end)

            -- 重锚 GuildFrameColumnHeader1..4 到 guildInset 内 + 列宽匹配 row
            -- 视觉顺序: Header1=Name(95) → Header3=Level(28) → Header4=Class(59) → Header2=Zone(108 RIGHT)
            if GuildFrameColumnHeader1 then
                local function nukeHdr(h)
                    if not h then return end
                    if h.SetNormalTexture then h:SetNormalTexture(nil) end
                    local rs = {h:GetRegions()}
                    for k = 1, table.getn(rs) do
                        local r = rs[k]
                        if r.GetObjectType and r:GetObjectType() == "Texture" then r:SetTexture(nil) end
                    end
                    -- 列头 FontString 默认 CENTER → 改 LEFT 对齐与 row 文字一致
                    local fs = h.GetFontString and h:GetFontString()
                    if fs then
                        fs:ClearAllPoints()
                        fs:SetPoint("LEFT", h, "LEFT", 4, 0)
                        fs:SetJustifyH("LEFT")
                    end
                end
                nukeHdr(GuildFrameColumnHeader1); nukeHdr(GuildFrameColumnHeader2)
                nukeHdr(GuildFrameColumnHeader3); nukeHdr(GuildFrameColumnHeader4)
                -- 列头 parent=GuildPlayerStatusFrame，公会状态时会随之隐藏 → reparent guildInset 独立显示
                GuildFrameColumnHeader1:SetParent(guildInset); GuildFrameColumnHeader2:SetParent(guildInset)
                GuildFrameColumnHeader3:SetParent(guildInset); GuildFrameColumnHeader4:SetParent(guildInset)
                -- 设计 B：列头跨越 inset 上边框（DF retail 风格）
                GuildFrameColumnHeader1:ClearAllPoints()
                GuildFrameColumnHeader1:SetPoint("BOTTOMLEFT", guildInset, "TOPLEFT", 4, -24)  -- 回收 dot 死区，与 row title offsetX=4 对齐
                GuildFrameColumnHeader1:SetWidth(90 + 5)
                GuildFrameColumnHeader3:ClearAllPoints()
                GuildFrameColumnHeader3:SetPoint("LEFT", GuildFrameColumnHeader1, "RIGHT", 0, 0)
                GuildFrameColumnHeader3:SetWidth(24 + 4)
                GuildFrameColumnHeader4:ClearAllPoints()
                GuildFrameColumnHeader4:SetPoint("LEFT", GuildFrameColumnHeader3, "RIGHT", 0, 0)
                GuildFrameColumnHeader4:SetWidth(78 + 4)
                GuildFrameColumnHeader2:ClearAllPoints()
                GuildFrameColumnHeader2:SetPoint("BOTTOMRIGHT", guildInset, "TOPRIGHT", -8, -24)
                GuildFrameColumnHeader2:SetWidth(112)
            end

            -- 自建公会搜索框：客户端按名字即时过滤成员（无防抖——本地 roster 数据不涉网络）
            -- 放到 vanilla(Turtle) GuildFrameSearchBox 的原位/大小（左上角），并隐藏 vanilla 那个
            local guildSearch = CreateFrame("EditBox", "DFUI_GuildSearchBox", guildInset)
            if GuildFrameSearchBox then
                guildSearch:SetAllPoints(GuildFrameSearchBox)
                GuildFrameSearchBox:SetAlpha(0); GuildFrameSearchBox:EnableMouse(false); GuildFrameSearchBox:Hide()
            else
                guildSearch:SetHeight(16)
                guildSearch:SetPoint("TOPLEFT",  guildInset, "BOTTOMLEFT",  6, -12)
                guildSearch:SetPoint("TOPRIGHT", guildInset, "BOTTOMRIGHT", -6, -12)
            end
            guildSearch:SetAutoFocus(false)
            guildSearch:SetFontObject(GameFontHighlightSmall)
            guildSearch:SetTextColor(1, 1, 1)
            guildSearch:SetTextInsets(20, 4, 0, 0)

            local guildSearchBg = CreateFrame("Frame", nil, guildInset)
            guildSearchBg:SetPoint("TOPLEFT",     guildSearch, "TOPLEFT",     -3,  1)  -- 整体下移2px与显示离线框齐平
            guildSearchBg:SetPoint("BOTTOMRIGHT", guildSearch, "BOTTOMRIGHT",  3, -5)  -- 保持高度26
            guildSearchBg:SetFrameLevel(guildInset:GetFrameLevel())
            guildSearch:SetFrameLevel(guildSearchBg:GetFrameLevel() + 1)
            CreateInsetBackdrop(guildSearchBg, 0.85)  -- DFUI 黑底+细边框

            local guildSearchIcon = guildSearchBg:CreateTexture(nil, "OVERLAY")
            guildSearchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
            guildSearchIcon:SetWidth(14); guildSearchIcon:SetHeight(14)
            guildSearchIcon:SetPoint("LEFT", guildSearchBg, "LEFT", 5, 0)
            guildSearchIcon:SetVertexColor(0.98, 0.91, 0.58)

            local guildSearchPlaceholder = guildSearchBg:CreateFontString(nil, "OVERLAY")
            guildSearchPlaceholder:SetFont("Fonts\\FRIZQT__.TTF", 13)
            guildSearchPlaceholder:SetPoint("LEFT", guildSearchBg, "LEFT", 24, 0)
            guildSearchPlaceholder:SetText("搜索成员")
            guildSearchPlaceholder:SetTextColor(1, 1, 1)

            local function guildUpdatePlaceholder()
                if guildSearch:GetText() == "" then guildSearchPlaceholder:Show() else guildSearchPlaceholder:Hide() end
            end
            guildUpdatePlaceholder()
            guildSearch:SetScript("OnTextChanged", function()
                guildUpdatePlaceholder()
                guildSearchText = guildSearch:GetText() or ""
                guildOffset = 0  -- 新过滤回到顶部
                refreshGuildRows()
            end)
            guildSearch:SetScript("OnEscapePressed", function() guildSearch:ClearFocus() end)

            -- 「显示离线」复用 vanilla GuildFrameLFGButton（Turtle 的勾选框，不隐藏、不自制）：
            -- hook 它的点击 + 读勾选态控制自建列表。勾选=含离线、不勾=只在线。
            if GuildFrameLFGButton then
                -- 去掉外层同名容器上「显示离线成员」背后那条框
                -- （Turtle 复用职业训练师 UI-ClassTrainer-FilterBorder 纹理拼成，与轻量复选框风格不符）
                local lfgC = GuildFrameLFGButton:GetParent()
                if lfgC then
                    local lfgText
                    local rs = { lfgC:GetRegions() }
                    for i = 1, table.getn(rs) do
                        local x = rs[i]
                        local ot = x.GetObjectType and x:GetObjectType()
                        if ot == "Texture" and x:GetTexture()
                           and string.find(x:GetTexture(), "FilterBorder") then
                            x:Hide()  -- 清掉 Turtle 的职业训练师过滤边框
                        elseif ot == "FontString" and x:GetText()
                           and string.find(x:GetText(), "离线") then
                            lfgText = x  -- 「显示离线成员」文字，用作框的右边界
                        end
                    end
                    -- 直接锚到「勾选框 GuildFrameLFGButton + 文字」，把这两者框住
                    -- 上/下/左 = 勾选框；右 = 文字右缘（找不到文字则按估算宽度兜底）
                    local function anchorLfg(obj)
                        -- 只用 TOPLEFT 单锚 + 宽高，避免 TOPLEFT/BOTTOM/RIGHT 三点水平过约束把框拉歪
                        obj:SetPoint("TOPLEFT", GuildFrameLFGButton, "TOPLEFT", -93, 3)
                        obj:SetHeight(26)  -- 固定 26（=搜索框框 20+6）；1.12 初始化时 GetHeight 会返回错值，不能用
                        local bl = GuildFrameLFGButton:GetLeft()
                        local tr = lfgText and lfgText:GetRight()
                        if bl and tr and tr > bl then
                            obj:SetWidth(tr - bl + 7)   -- 勾选框左 → 文字右
                        else
                            obj:SetWidth(118)           -- 兜底估算宽
                        end
                    end
                    -- 黑底画在 lfgC 的 BACKGROUND 层（文字天然在其上、不被盖）
                    local lfgBgTex = lfgC:CreateTexture(nil, "BACKGROUND")
                    lfgBgTex:SetTexture("Interface\\Buttons\\WHITE8X8")
                    lfgBgTex:SetVertexColor(0, 0, 0, 0.85)
                    anchorLfg(lfgBgTex)
                    -- 细边框用子框（BORDER 在四周、不盖文字）
                    local lfgBg = CreateFrame("Frame", nil, lfgC)
                    anchorLfg(lfgBg)
                    CreateInsetBackdrop(lfgBg, 0)
                end
                if GuildFrameLFGButton.GetChecked then
                    guildShowOffline = GuildFrameLFGButton:GetChecked() and true or false  -- 初始同步 vanilla 态
                end
                HookScript(GuildFrameLFGButton, "OnClick", function()
                    guildShowOffline = GuildFrameLFGButton:GetChecked() and true or false
                    guildOffset = 0
                    refreshGuildRows()
                end)
            end

            -- 自建底部三按钮（公会信息/添加成员/公会控制）：DF 红金属风格，与好友/查找统一。
            -- 替代裸露的 vanilla 三按钮——vanilla 保留功能(透明+禁鼠标，不 Hide 以保 :Click 与 enable 态)，
            -- 自制按钮转发 vanilla:Click() 复用原逻辑；enable 镜像 vanilla 权限态。
            if GuildFrameGuildInformationButton and GuildFrameAddMemberButton and GuildFrameControlButton then
                local gVanilla = { GuildFrameGuildInformationButton, GuildFrameAddMemberButton, GuildFrameControlButton }
                for i = 1, table.getn(gVanilla) do
                    gVanilla[i]:SetAlpha(0); gVanilla[i]:EnableMouse(false)
                end
                local function clickVanilla(b) if b and b.Click then b:Click() end end
                -- 锚到 vanilla 三按钮原位+原尺寸：SetAllPoints 跟随（vanilla 即便后续重定位也同步）。
                -- 创建宽度随意(100)，SetAllPoints 双锚会覆盖为 vanilla 实际位置与尺寸。
                local gBtnInfo = DFUI.CreateActionButton(guildInset, 100,
                    (GuildFrameGuildInformationButton:GetText() or "公会信息"),
                    function() clickVanilla(GuildFrameGuildInformationButton) end, 22)
                gBtnInfo:SetAllPoints(GuildFrameGuildInformationButton)
                local gBtnAdd = DFUI.CreateActionButton(guildInset, 100,
                    (GuildFrameAddMemberButton:GetText() or "添加成员"),
                    function() clickVanilla(GuildFrameAddMemberButton) end, 22)
                gBtnAdd:SetAllPoints(GuildFrameAddMemberButton)
                local gBtnControl = DFUI.CreateActionButton(guildInset, 100,
                    (GuildFrameControlButton:GetText() or "公会控制"),
                    function() clickVanilla(GuildFrameControlButton) end, 22)
                gBtnControl:SetAllPoints(GuildFrameControlButton)

                -- enable 镜像 vanilla 权限态（添加成员/公会控制按权限启用，公会信息一般常亮）
                local function vEnabled(b)
                    if not (b and b.IsEnabled) then return false end
                    local v = b:IsEnabled()
                    return (v == 1) or (v == true)
                end
                updateGuildButtons = function()
                    gBtnInfo:SetEnabledDF(vEnabled(GuildFrameGuildInformationButton))
                    gBtnAdd:SetEnabledDF(vEnabled(GuildFrameAddMemberButton))
                    gBtnControl:SetEnabledDF(vEnabled(GuildFrameControlButton))
                end
                updateGuildButtons()
            end
        end
    end


    -- /reload 后首次 OnShow 时 inset/SF size 未 settle，需延迟一帧再 fit
    -- 1.12 OnUpdate handler 第一参是 elapsed 不是 self，用闭包引用 deferFitFrame
    -- deferFit 已在 Tab callback 之前 forward declare 为 local，此处赋值
    local deferFitFrame = CreateFrame("Frame")
    deferFit = function()
        deferFitFrame:SetScript("OnUpdate", function()
            deferFitFrame:SetScript("OnUpdate", nil)
            reanchorScrollFrames()
            fitButtonHeights()
            if refreshFriendRows then refreshFriendRows() end
            if refreshWhoRows then refreshWhoRows() end
            if refreshGuildRows then refreshGuildRows() end
        end)
    end

    CenterFrame(FriendsFrame)
    HookScript(FriendsFrame, "OnShow", function()
        customBg:Show()
        UpdateGuildTab()
        safeTabClick(FriendsFrame.selectedTab or 1)
        reanchorScrollFrames()
        detachRightColumn()
        deferFit()
    end)

    customBg:AddTab("团队", function()
        hideDropDown()
        FriendsFrame.selectedTab = 4
        FriendsFrame_ShowSubFrame("RaidFrame")
        PanelTemplates_SetTab(FriendsFrame, 4)
        FriendsFrame_Update()
    end, 60)

    local originalToggleFriendsFrame = _G.ToggleFriendsFrame
    _G.ToggleFriendsFrame = function(tab)
        local wasVisible = FriendsFrame:IsVisible()
        originalToggleFriendsFrame(tab)
        -- 首次打开走 OnShow hook；只有"已可见状态切 Tab"才在此手动触发，避免双重 OnClick
        if wasVisible and FriendsFrame:IsVisible() and customBg.Tabs then
            safeTabClick(tab or 1)
        end
    end

    local callbacks = {}
    DFUI:NewCallbacks("Social", callbacks)
end)
