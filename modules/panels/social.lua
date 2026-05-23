setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Social", {
    enabled = {true},
})

DFUI:NewMod("Social", 5, function()
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
        anchors      = {3, -78, -6, 6},     -- 顶部再下移让出 ToggleTab1/2 子切换按钮空间
        followFrames = IgnoreListFrame and {FriendsListFrame, IgnoreListFrame} or {FriendsListFrame},
    })

    local whoInset = DFUI.CreateRetailInset(customBg, {
        name        = "DFUI_WhoInset",
        anchors     = {3, -58, -6, 80},     -- 底部留 80px 给 vanilla EditBox（姓名搜索框）
        followFrame = WhoFrame,
    })

    local guildInset = DFUI.CreateRetailInset(customBg, {
        name        = "DFUI_GuildInset",
        anchors     = {3, -58, -6, 80},     -- 底部留 80px 给 vanilla MOTD 公告编辑框 + 公会信息
        followFrame = GuildFrame,
    })

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

    -- 好友 tab 底部 4 个按钮（添加好友/发送消息/删除好友/组队邀请）上移 5px
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
    shiftFrameUp(FriendsFrameAddFriendButton,    5)
    shiftFrameUp(FriendsFrameSendMessageButton,  5)
    shiftFrameUp(FriendsFrameRemoveFriendButton, 5)
    shiftFrameUp(FriendsFrameGroupInviteButton,  5)

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
    if GuildListScrollFrameScrollBar then
        nukeScrollBar(GuildListScrollFrameScrollBar)
        HookScript(GuildListScrollFrameScrollBar, "OnShow", function()
            GuildListScrollFrameScrollBar:Hide()
        end)
    end


    -- 不主动管理 ToggleTab 显隐，让 vanilla 自己处理（pfUI 简单模式）
    -- 不 hook OnClick，每组选中态固定 dfSetSelected 一次到位
    -- 如有切换显示问题，待 dump 命令数据出来后定向修复

    local guildTab
    customBg:AddTab("好友", function()
        FriendsFrame.selectedTab = 1
        FriendsFrame_ShowSubFrame("FriendsListFrame")
        PanelTemplates_SetTab(FriendsFrame, 1)
        FriendsFrame_Update()
    end, 70)

    customBg:AddTab("查找", function()
        FriendsFrame.selectedTab = 2
        FriendsFrame_ShowSubFrame("WhoFrame")
        PanelTemplates_SetTab(FriendsFrame, 2)
        FriendsFrame_Update()
    end, 60)

    guildTab = customBg:AddTab("公会", function()
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

    CenterFrame(FriendsFrame)
    HookScript(FriendsFrame, "OnShow", function()
        customBg:Show()
        UpdateGuildTab()
        safeTabClick(FriendsFrame.selectedTab or 1)
    end)

    customBg:AddTab("团队", function()
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
