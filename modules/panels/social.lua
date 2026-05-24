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

    -- WhoFrameEditBox 在 vanilla 1.12 是裸 EditBox（无 InputBoxTemplate 继承，无 Layers 边框）
    -- 原本依赖 FriendsFrame 4 角 marble 衬底，DF UI 第 8-11 行 Hide 后变"可输入但无框体"
    -- 不动 EditBox parent/锚点，反向锚 backdrop 到 EditBox 自身（外扩 3px），自动跟随
    local whoSearchBg = CreateFrame("Frame", nil, WhoFrame)
    whoSearchBg:SetPoint("TOPLEFT",     WhoFrameEditBox, "TOPLEFT",     -3,  3)
    whoSearchBg:SetPoint("BOTTOMRIGHT", WhoFrameEditBox, "BOTTOMRIGHT",  3, -3)
    whoSearchBg:SetFrameStrata(WhoFrameEditBox:GetFrameStrata())  -- 跟随 EditBox 真实 strata（vanilla 1.12 未实测，retail XML 是 HIGH）
    WhoFrameEditBox:SetFrameLevel(whoSearchBg:GetFrameLevel() + 1)
    CreateInsetBackdrop(whoSearchBg, 0.85)

    -- 缩小 EditBox 高度 50%（32 → 16），宽度保持 vanilla 296；加放大镜图标 + "查找" 占位符
    WhoFrameEditBox:SetHeight(16)
    WhoFrameEditBox:SetTextInsets(20, 0, 0, 0)  -- 左缩进 20px 让位图标 + placeholder
    -- 整体上移 9px：基于 vanilla 原锚加偏移，不假设 vanilla 实际 y 值
    local _p, _rt, _rp, _x, _y = WhoFrameEditBox:GetPoint(1)
    WhoFrameEditBox:ClearAllPoints()
    WhoFrameEditBox:SetPoint(_p, _rt, _rp, _x, _y + 9)

    local whoSearchIcon = whoSearchBg:CreateTexture(nil, "OVERLAY")
    whoSearchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    whoSearchIcon:SetWidth(14); whoSearchIcon:SetHeight(14)
    whoSearchIcon:SetPoint("LEFT", whoSearchBg, "LEFT", 5, 0)
    whoSearchIcon:SetVertexColor(0.98, 0.91, 0.58)

    local whoSearchPlaceholder = whoSearchBg:CreateFontString(nil, "OVERLAY")
    whoSearchPlaceholder:SetFont("Fonts\\FRIZQT__.TTF", 13)
    whoSearchPlaceholder:SetPoint("LEFT", whoSearchBg, "LEFT", 24, 0)
    whoSearchPlaceholder:SetText("查找")
    whoSearchPlaceholder:SetTextColor(0.55, 0.50, 0.40)

    -- OnTextChanged 钩链：空文本显示 placeholder，否则隐藏；保留 vanilla 原 handler
    local function whoUpdatePlaceholder()
        if WhoFrameEditBox:GetText() == "" then
            whoSearchPlaceholder:Show()
        else
            whoSearchPlaceholder:Hide()
        end
    end
    whoUpdatePlaceholder()
    local prevOnTextChanged = WhoFrameEditBox:GetScript("OnTextChanged")
    WhoFrameEditBox:SetScript("OnTextChanged", function()
        if prevOnTextChanged then prevOnTextChanged() end
        whoUpdatePlaceholder()
    end)

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
    local MAX_ROWS = 18
    local function getSFHeight()
        local ih = friendsInset and friendsInset:GetHeight() or 0
        if ih > 8 then return ih - 8 end
        return 200
    end
    local function reanchorScrollFrames()
        local sfH = getSFHeight()
        if FriendsFrameFriendsScrollFrame then
            FriendsFrameFriendsScrollFrame:ClearAllPoints()
            FriendsFrameFriendsScrollFrame:SetPoint("TOPLEFT",  friendsInset, "TOPLEFT",  6,  -4)
            FriendsFrameFriendsScrollFrame:SetPoint("TOPRIGHT", friendsInset, "TOPRIGHT", -24, -4)
            FriendsFrameFriendsScrollFrame:SetHeight(sfH)
        end
        if FriendsFrameIgnoreScrollFrame then
            FriendsFrameIgnoreScrollFrame:ClearAllPoints()
            FriendsFrameIgnoreScrollFrame:SetPoint("TOPLEFT",  friendsInset, "TOPLEFT",  6,  -4)
            FriendsFrameIgnoreScrollFrame:SetPoint("TOPRIGHT", friendsInset, "TOPRIGHT", -24, -4)
            FriendsFrameIgnoreScrollFrame:SetHeight(sfH)
        end
        if FriendsFrameFriendButton1 then
            FriendsFrameFriendButton1:ClearAllPoints()
            FriendsFrameFriendButton1:SetPoint("TOPLEFT", FriendsFrameFriendsScrollFrame, "TOPLEFT", 0, 0)
        end
        if FriendsFrameIgnoreButton1 then
            FriendsFrameIgnoreButton1:ClearAllPoints()
            FriendsFrameIgnoreButton1:SetPoint("TOPLEFT", FriendsFrameIgnoreScrollFrame, "TOPLEFT", 0, 0)
        end
        -- Who / Guild SF 也对齐 inset（之前漏处理 → vanilla 默认 287/237 > inset 高度 → row 溢出 inset）
        if WhoListScrollFrame and whoInset then
            WhoListScrollFrame:ClearAllPoints()
            WhoListScrollFrame:SetPoint("TOPLEFT",  whoInset, "TOPLEFT",  6,  -4)
            WhoListScrollFrame:SetPoint("TOPRIGHT", whoInset, "TOPRIGHT", -24, -4)
            local whH = (whoInset:GetHeight() or 0) - 8
            if whH > 0 then WhoListScrollFrame:SetHeight(whH) end
        end
        if GuildListScrollFrame and guildInset then
            GuildListScrollFrame:ClearAllPoints()
            GuildListScrollFrame:SetPoint("TOPLEFT",  guildInset, "TOPLEFT",  6,  -4)
            GuildListScrollFrame:SetPoint("TOPRIGHT", guildInset, "TOPRIGHT", -24, -4)
            local ghH = (guildInset:GetHeight() or 0) - 8
            if ghH > 0 then GuildListScrollFrame:SetHeight(ghH) end
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
    -- 公会/好友/屏蔽/查找 tab 全部清掉 vanilla 滚动条（鼠标滚轮仍可滚动）
    local scrollBarsToNuke = {
        GuildListScrollFrameScrollBar,
        FriendsFrameFriendsScrollFrameScrollBar,
        FriendsFrameIgnoreScrollFrameScrollBar,
        WhoListScrollFrameScrollBar,
    }
    for i = 1, table.getn(scrollBarsToNuke) do
        local sb = scrollBarsToNuke[i]
        -- sb.GetScript 双重检查：vanilla 某些 ScrollBar 全局可能存在但不是真 frame（无 GetScript 方法）
        if sb and sb.GetScript then
            nukeScrollBar(sb)
            HookScript(sb, "OnShow", function()
                sb:Hide()
            end)
        end
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

    local guildTab
    customBg:AddTab("好友", function()
        hideDropDown()
        FriendsFrame.selectedTab = 1
        FriendsFrame_ShowSubFrame("FriendsListFrame")
        PanelTemplates_SetTab(FriendsFrame, 1)
        FriendsFrame_Update()
    end, 70)

    customBg:AddTab("查找", function()
        hideDropDown()
        FriendsFrame.selectedTab = 2
        FriendsFrame_ShowSubFrame("WhoFrame")
        PanelTemplates_SetTab(FriendsFrame, 2)
        FriendsFrame_Update()
    end, 60)

    guildTab = customBg:AddTab("公会", function()
        hideDropDown()
        FriendsFrame.selectedTab = 3
        FriendsFrame_ShowSubFrame("GuildFrame")
        PanelTemplates_SetTab(FriendsFrame, 3)
        FriendsFrame_Update()
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

            -- 用 DFUI.CreateSocialRow 工厂统一创建 row（hover/sel/click 内置）
            local function onFriendLeftClick(row)
                if not row.friendID then return end
                mySelectedFriendID = row.friendID
                FriendsFrame.selectedFriend = row.friendID  -- vanilla 同步（底部按钮 enable）
                FriendsList_Update()
                if FriendsFrame_Update then FriendsFrame_Update() end
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
            for i = 1, MAX_ROWS do
                DFUI.CreateSocialRow(sf, {
                    name       = "DFUI_FriendRow"..i,
                    frameLevel = sf:GetFrameLevel() + 10,
                    columns = {
                        -- 合并 status 到 zoneText 单字串（vanilla FRIENDS_LIST_TEMPLATE 同款设计）
                        -- 消除双 RIGHT 链错位风险，4 列：dot + title + lc + zoneText
                        { name="dot",      type="texture",    width=9, height=9,
                          anchor="LEFT", offsetX=4 },
                        { name="title",    type="fontstring", width=120,
                          font="GameFontNormalSmall", color="main",
                          anchor="LEFT", offsetX=5 },
                        { name="lc",       type="fontstring", width=70,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        { name="zoneText", type="fontstring", width=110,
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
                local h = sf:GetHeight()
                if not h or h <= 0 then visibleRows = 0; return false end
                visibleRows = math.floor(h / FIXED_ROW_H)
                if visibleRows > MAX_ROWS then visibleRows = MAX_ROWS end
                if visibleRows < 1 then visibleRows = 1 end
                for i = 1, MAX_ROWS do
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
                            row.lc:SetText(lcText)
                            if connected then
                                local dotKey
                                if status == CHAT_FLAG_AFK then dotKey = "afk"
                                elseif status == CHAT_FLAG_DND then dotKey = "dnd"
                                else dotKey = "online" end
                                row.dot:SetVertexColor(STATUS_DOT[dotKey][1], STATUS_DOT[dotKey][2], STATUS_DOT[dotKey][3])
                                row.title:SetTextColor(cr, cg, cb)
                                local lvl = tonumber(level)
                                local lc = lvl and GetDifficultyColor and GetDifficultyColor(lvl) or nil
                                if lc then row.lc:SetTextColor(lc.r, lc.g, lc.b) else row.lc:SetTextColor(1, 1, 1) end
                                -- zone + status 拼字串（vanilla FRIENDS_LIST_TEMPLATE 同款）
                                -- "凄凉之地"（无 AFK） / "凄凉之地 |cffffd000<AFK>|r"
                                local zoneStr = zone or ""
                                if status and status ~= "" then
                                    zoneStr = zoneStr .. " |cffffd000" .. status .. "|r"
                                end
                                row.zoneText:SetText(zoneStr)
                                row.zoneText:SetTextColor(1, 1, 1)
                            else
                                -- 离线：职业色 + alpha 0.5（与 ShaguTweaks 聊天插件风格一致）
                                row.dot:SetVertexColor(STATUS_DOT.offline[1], STATUS_DOT.offline[2], STATUS_DOT.offline[3])
                                row.title:SetTextColor(cr, cg, cb, 0.5)
                                row.lc:SetTextColor(cr, cg, cb, 0.5)
                                -- 离线 zoneText 显示 "<离线>" 标签（灰 + alpha，不染职业色）
                                row.zoneText:SetText(FRIENDS_LIST_OFFLINE or "<离线>")
                                row.zoneText:SetTextColor(0.5, 0.5, 0.5, 0.5)
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
            local WHO_ROWS = WHOS_TO_DISPLAY or 17

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
                b:SetAlpha(0); b:EnableMouse(false)
                local suffixes = {"Name", "Variable", "Class", "Level"}
                for j = 1, table.getn(suffixes) do
                    local fs = _G["WhoFrameButton"..i..suffixes[j]]
                    if fs then fs:SetAlpha(0); fs:SetText("") end
                end
            end
            for i = 1, WHO_ROWS do hideVanillaWhoBtn(i) end

            -- 独立跟踪用户实际点选的 Who 索引（避免 vanilla WhoList_Update 自动设 selectedWho）
            local mySelectedWhoIdx = nil

            local function onWhoLeftClick(row)
                if not row.whoIdx then return end
                mySelectedWhoIdx = row.whoIdx
                WhoFrame.selectedWho = row.whoIdx
                WhoFrame.selectedName = row.name
                if WhoList_Update then WhoList_Update() end
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

            for i = 1, WHO_ROWS do
                DFUI.CreateSocialRow(sfWho, {
                    name       = "DFUI_WhoRow"..i,
                    frameLevel = sfWho:GetFrameLevel() + 10,
                    columns = {
                        { name="title", type="fontstring", width=85,
                          font="GameFontNormalSmall", color="main",
                          anchor="LEFT", offsetX=8 },
                        { name="lvl",   type="fontstring", width=24,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        { name="class", type="fontstring", width=55,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        { name="zoneText", type="fontstring", width=100,
                          font="GameFontNormalSmall", color="next_",
                          anchor="RIGHT", offsetX=-8 },
                    },
                    onLeftClick   = onWhoLeftClick,
                    onRightClick  = onWhoRightClick,
                    onDoubleClick = function(row)
                        if row.name and ChatFrame_SendTell then ChatFrame_SendTell(row.name) end
                    end,
                    onWheel = function()
                        if WhoList_Update then WhoList_Update() end
                    end,
                })
            end

            local FIXED_ROW_H_WHO = 18
            local COLHDR_OFFSET_WHO = 24  -- 列头完全在 inset 顶部内侧，row1 起点下移 24px
            local visibleRowsWho = 0
            local function layoutWhoRows()
                local h = sfWho:GetHeight()
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
                        row:SetPoint("TOPLEFT",  sfWho, "TOPLEFT",  0, y)
                        row:SetPoint("TOPRIGHT", sfWho, "TOPRIGHT", 0, y)
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
                local off = (FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(sfWho)) or 0
                local numTotal = (GetNumWhoResults and GetNumWhoResults()) or 0
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
                            row.zoneText:SetText(zone or "")
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
                -- 覆盖 vanilla scrollbar maxV：vanilla WHOS_TO_DISPLAY=17，visibleRowsWho 实际可能 ≠ 17
                local sb = sfWho.GetName and getglobal(sfWho:GetName().."ScrollBar")
                if sb and sb.SetMinMaxValues then
                    local maxV = math.max(0, (numTotal - visibleRowsWho) * FIXED_ROW_H_WHO)
                    sb:SetMinMaxValues(0, maxV)
                end
            end

            if hooksecurefunc then hooksecurefunc("WhoList_Update", refreshWhoRows) end

            local refreshFrameWho = CreateFrame("Frame")
            refreshFrameWho:RegisterEvent("WHO_LIST_UPDATE")
            refreshFrameWho:SetScript("OnEvent", function() refreshWhoRows() end)

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
                    -- 列头 FontString 默认 CENTER 对齐 → 与 row 文字 LEFT 对齐错位
                    -- 改 LEFT 对齐 + 锚 header.LEFT + 4，与 row 内列起始 X 对齐
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
                WhoFrameColumnHeader4:SetWidth(55 + 4)
                WhoFrameColumnHeader2:ClearAllPoints()
                WhoFrameColumnHeader2:SetPoint("BOTTOMRIGHT", whoInset, "TOPRIGHT", -8, -24)
                WhoFrameColumnHeader2:SetWidth(100)
            end
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
            local GUILD_ROWS = GUILDMEMBERS_TO_DISPLAY or 17

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

            -- 独立跟踪用户实际点选的公会成员索引（避免 vanilla GuildStatus_Update 自动设 selection）
            local mySelectedGuildIdx = nil

            local function onGuildLeftClick(row)
                if not row.guildIdx then return end
                mySelectedGuildIdx = row.guildIdx
                if SetGuildRosterSelection then SetGuildRosterSelection(row.guildIdx) end
                if GuildStatus_Update then GuildStatus_Update() end
                if GuildFrame_Update then GuildFrame_Update() end
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

            for i = 1, GUILD_ROWS do
                DFUI.CreateSocialRow(sfGuild, {
                    name       = "DFUI_GuildRow"..i,
                    frameLevel = sfGuild:GetFrameLevel() + 10,
                    columns = {
                        { name="dot",      type="texture",    width=9, height=9,
                          anchor="LEFT", offsetX=4 },
                        { name="title",    type="fontstring", width=90,
                          font="GameFontNormalSmall", color="main",
                          anchor="LEFT", offsetX=5 },
                        { name="lvl",      type="fontstring", width=24,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        { name="class",    type="fontstring", width=55,
                          font="GameFontNormalSmall", color="next_",
                          anchor="LEFT", offsetX=4 },
                        { name="zoneText", type="fontstring", width=80,
                          font="GameFontNormalSmall", color="next_",
                          anchor="RIGHT", offsetX=-8 },
                    },
                    onLeftClick   = onGuildLeftClick,
                    onRightClick  = onGuildRightClick,
                    onDoubleClick = function(row)
                        if row.name and ChatFrame_SendTell then ChatFrame_SendTell(row.name) end
                    end,
                    onWheel = function()
                        if GuildStatus_Update then GuildStatus_Update() end
                    end,
                })
            end

            local FIXED_ROW_H_GUILD = 18
            local COLHDR_OFFSET_GUILD = 24  -- 列头完全在 inset 顶部内侧
            local visibleRowsGuild = 0
            local function layoutGuildRows()
                local h = sfGuild:GetHeight()
                if not h or h <= 0 then visibleRowsGuild = 0; return false end
                local availH = h - COLHDR_OFFSET_GUILD
                visibleRowsGuild = math.floor(availH / FIXED_ROW_H_GUILD)
                if visibleRowsGuild > GUILD_ROWS then visibleRowsGuild = GUILD_ROWS end
                if visibleRowsGuild < 1 then visibleRowsGuild = 1 end
                for i = 1, GUILD_ROWS do
                    local row = _G["DFUI_GuildRow"..i]
                    if i <= visibleRowsGuild then
                        local y = -((i - 1) * FIXED_ROW_H_GUILD + COLHDR_OFFSET_GUILD)
                        row:ClearAllPoints()
                        row:SetPoint("TOPLEFT",  sfGuild, "TOPLEFT",  0, y)
                        row:SetPoint("TOPRIGHT", sfGuild, "TOPRIGHT", 0, y)
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

            refreshGuildRows = function()
                for i = 1, GUILD_ROWS do hideVanillaGuildBtn(i) end
                if not layoutGuildRows() then return end
                local off = (FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(sfGuild)) or 0
                local numTotal = (GetNumGuildMembers and GetNumGuildMembers()) or 0
                for i = 1, visibleRowsGuild do
                    local row = _G["DFUI_GuildRow"..i]
                    local idx = off + i
                    if idx <= numTotal then
                        local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(idx)
                        if name then
                            row.guildIdx = idx
                            row.name = name
                            local cr, cg, cb = getGuildClassColor(class)
                            if online then
                                -- 在线状态点：根据 status 标记（AFK/DND）
                                if status == CHAT_FLAG_AFK then
                                    row.dot:SetVertexColor(1.00, 0.82, 0.00)
                                elseif status == CHAT_FLAG_DND then
                                    row.dot:SetVertexColor(0.85, 0.20, 0.20)
                                else
                                    row.dot:SetVertexColor(0.20, 0.85, 0.20)
                                end
                                row.title:SetText(name)
                                row.title:SetTextColor(cr, cg, cb)
                                row.lvl:SetText(level or "")
                                local lvl = tonumber(level)
                                local lc = lvl and GetDifficultyColor and GetDifficultyColor(lvl) or nil
                                if lc then row.lvl:SetTextColor(lc.r, lc.g, lc.b)
                                else row.lvl:SetTextColor(1, 1, 1) end
                                row.class:SetText(class or "")
                                row.class:SetTextColor(cr, cg, cb)
                                row.zoneText:SetText(zone or "")
                                row.zoneText:SetTextColor(1, 1, 1)
                            else
                                -- 离线：职业色 + alpha 0.5（与 ShaguTweaks 聊天/Guild 染色风格一致）
                                row.dot:SetVertexColor(0.45, 0.45, 0.45)
                                row.title:SetText(name); row.title:SetTextColor(cr, cg, cb, 0.5)
                                row.lvl:SetText(level or ""); row.lvl:SetTextColor(cr, cg, cb, 0.5)
                                row.class:SetText(class or ""); row.class:SetTextColor(cr, cg, cb, 0.5)
                                row.zoneText:SetText(zone or ""); row.zoneText:SetTextColor(cr, cg, cb, 0.5)
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
                -- 覆盖 vanilla scrollbar maxV：vanilla GUILDMEMBERS_TO_DISPLAY=17，visibleRowsGuild 实际可能 ≠ 17
                local sb = sfGuild.GetName and getglobal(sfGuild:GetName().."ScrollBar")
                if sb and sb.SetMinMaxValues then
                    local maxV = math.max(0, (numTotal - visibleRowsGuild) * FIXED_ROW_H_GUILD)
                    sb:SetMinMaxValues(0, maxV)
                end
            end

            if hooksecurefunc then hooksecurefunc("GuildStatus_Update", refreshGuildRows) end

            local refreshFrameGuild = CreateFrame("Frame")
            refreshFrameGuild:RegisterEvent("GUILD_ROSTER_UPDATE")
            refreshFrameGuild:SetScript("OnEvent", function() refreshGuildRows() end)

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
                -- 设计 B：列头跨越 inset 上边框（DF retail 风格）
                GuildFrameColumnHeader1:ClearAllPoints()
                GuildFrameColumnHeader1:SetPoint("BOTTOMLEFT", guildInset, "TOPLEFT", 18, -24)  -- X=18 让出 dot+title 起始
                GuildFrameColumnHeader1:SetWidth(90 + 5)
                GuildFrameColumnHeader3:ClearAllPoints()
                GuildFrameColumnHeader3:SetPoint("LEFT", GuildFrameColumnHeader1, "RIGHT", 0, 0)
                GuildFrameColumnHeader3:SetWidth(24 + 4)
                GuildFrameColumnHeader4:ClearAllPoints()
                GuildFrameColumnHeader4:SetPoint("LEFT", GuildFrameColumnHeader3, "RIGHT", 0, 0)
                GuildFrameColumnHeader4:SetWidth(55 + 4)
                GuildFrameColumnHeader2:ClearAllPoints()
                GuildFrameColumnHeader2:SetPoint("BOTTOMRIGHT", guildInset, "TOPRIGHT", -8, -24)
                GuildFrameColumnHeader2:SetWidth(100)
            end
        end
    end


    -- /reload 后首次 OnShow 时 inset/SF size 未 settle，需延迟一帧再 fit
    -- 1.12 OnUpdate handler 第一参是 elapsed 不是 self，用闭包引用 deferFitFrame
    local deferFitFrame = CreateFrame("Frame")
    local function deferFit()
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
