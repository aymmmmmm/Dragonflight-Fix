setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Mail", {
    enabled = {true},
})

DFUI:NewMod("Mail", 5, function()
    local regions = {MailFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and (string.find(texture, "UI%-ItemText") or string.find(texture, "UI%-Spellbook") or string.find(texture, "UI%-ClassTrainer")) then
                region:Hide()
            end
        end
    end

    MailFrameTab1:Hide()
    MailFrameTab2:Hide()
    InboxCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_MailBg", MailFrame, 384, 512, 1)
    customBg:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", MailFrame, "BOTTOMRIGHT", -32, 75)
    customBg.Bg:SetDrawLayer("BACKGROUND", -1)

    -- 邮件图标放入头像框
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and string.find(texture, "Mail%-Icon") then
                region:SetParent(customBg)
                region:SetDrawLayer("BORDER", 0)
                region:ClearAllPoints()
                region:SetPoint("CENTER", customBg, "TOPLEFT", 27, -23)
                region:SetWidth(54)
                region:SetHeight(54)
                break
            end
        end
    end

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(MailFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    -- frame level 由下方 ApplyMailLevels 统一管，避免两处真值源

    local tabInbox = customBg:AddTab("收件箱", function()
        MailFrameTab_OnClick(1)
    end, 70)

    local tabSend = customBg:AddTab("发信", function()
        MailFrameTab_OnClick(2)
    end, 70)

    -- ========================================================================
    -- vanilla 残留装饰清理（真值来自 patch-9.mpq 的 Interface\FrameXML\MailFrame.xml，
    -- Turtle 覆盖过该文件，实际生效的是 patch-9 那版）
    --
    -- 上面第 8-17 行的清扫只扫 MailFrame 一层，GetRegions() 不递归子 frame，所以这两组漏网：
    --   1) SendMailFrame BACKGROUND 层两条 UI-ClassTrainer-HorizontalBar（xml:514/526）
    --      —— 横贯发信页的分隔条。名字只有 SendMailHorizontalBarLeft，右半段是匿名 Texture，
    --      所以按贴图名匹配而不是 getglobal。
    --   2) SendMailScrollFrame ARTWORK 层两条 UI-Character-ScrollBar（xml:574/587，均匿名）
    --      —— 滚动条凹槽画在 ScrollFrame 上而不是 ScrollBar 上，questskin 的
    --      keepArrowsHideTrack 只清 ScrollBar 的 Top/Middle/Bottom+thumb，够不着这两条，
    --      表现就是换了 minimal 滑块但旧凹槽还在。
    --
    -- 必须按贴图名精确匹配，不能整帧全清：同在 BACKGROUND 层的
    -- StationeryBackgroundLeft/Right 是信纸背景（xml 无 file 属性，由 Lua 运行时贴），清了就真没背景了。
    -- ========================================================================
    DFUI.HidePanelTextures(SendMailFrame,       {match = "UI%-ClassTrainer"})
    DFUI.HidePanelTextures(SendMailScrollFrame, {match = "UI%-Character%-ScrollBar"})

    -- ========================================================================
    -- 帧层级重排（本次修复核心）
    -- 病根：customBg / InboxFrame / SendMailFrame 都是 MailFrame 的直接子 frame，
    -- 原来 customBg 不设 level，三者全落在 MailFrame+1 → 同(strata,level) tie。
    -- 1.12 同级跨 frame 绘制顺序随 Show/Hide 重排不稳 → 岩石底随机盖住发信页的
    -- 输入框和按钮，表现为"背景没有 / 发不了邮件"，且时好时坏（social.lua:260 同款坑）。
    -- 收件箱看不出来，是因为它的内容是 InboxFrameItem1..7 一堆 level 更高的 Button。
    --
    -- 目标序列：customBg=L+1（保持原值不动）/ MailFrame 其余子树=L+2 / 自制 tab+关闭=L+5
    -- 为什么不是把 customBg 沉到 L：MailFrame 自身纹理只按 3 个名字模式隐了一部分，没隐的
    -- 那些现在靠 customBg 更高一层压着才显示正常。沉下去就要赌父子同层的绘制次序，可能
    -- 反被没隐掉的 vanilla 图盖住 → 改为抬内容，不动已经正常的背景关系。
    -- ========================================================================

    -- 整棵子树按同一 delta 平移。1.12 SetFrameLevel 不递归子 frame，只抬父会让父子撞同层；
    -- 而把子控件统一压平到 base+1 又会毁掉 vanilla 自己的层次（如 SendMailScrollFrame 与其
    -- scrollchild SendMailBodyEditBox 会并成一层）→ 平移才能原样保留 vanilla 相对次序。
    local function ShiftSubtree(frame, delta, depth)
        if not frame or not frame.SetFrameLevel or depth > 8 then return end
        frame:SetFrameLevel(frame:GetFrameLevel() + delta)
        local kids = {frame:GetChildren()}
        for i = 1, table.getn(kids) do
            ShiftSubtree(kids[i], delta, depth + 1)
        end
    end

    -- 幂等：各层已在目标位时 delta=0 自然空转，可反复调用。
    -- 每次 OnShow 重算而不是登录时定一次：MailFrame 是 toplevel 面板，被抬升或被别的插件
    -- 改过 level 后能自愈，不用赌它一辈子不动。
    local function ApplyMailLevels()
        local base = MailFrame:GetFrameLevel()
        customBg:SetFrameLevel(base + 1)

        -- 遍历 MailFrame 全部子 frame 而不是只点名 InboxFrame/SendMailFrame：
        -- "发送/取消"这类按钮挂在谁名下（MailFrame 还是 SendMailFrame）无需假设，
        -- Turtle 魔改加的控件也一并覆盖 —— 不猜接口。
        local kids = {MailFrame:GetChildren()}
        for i = 1, table.getn(kids) do
            local kid = kids[i]
            if kid and kid ~= customBg and kid.GetFrameLevel then
                ShiftSubtree(kid, (base + 2) - kid:GetFrameLevel(), 1)
            end
        end

        -- customBg 的子(tab/关闭)默认只到 base+2，正好与内容层撞在一起 → 显式抬过
        tabInbox:SetFrameLevel(base + 5)
        tabSend:SetFrameLevel(base + 5)
        closeButton:SetFrameLevel(base + 5)
    end
    ApplyMailLevels()

    -- 发信正文滚动条换 DF minimal（与任务日志/训练师/社交/制造统一）。
    -- 必须在 ApplyMailLevels 之后：CreateRetailScrollbar 建条时把 parent:GetFrameLevel()+5
    -- 取成快照，先建条后抬层的话 mini 会停在旧基准上被 SendMailScrollFrame 盖住。
    DFUI.AttachMinimalScrolls(MailFrame, {
        {sf = "SendMailScrollFrame", sb = "SendMailScrollFrameScrollBar"},
    })

    CenterFrame(MailFrame)
    HookScript(MailFrame, "OnShow", function()
        customBg:Show()
        ApplyMailLevels()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("Mail", callbacks)
end)
