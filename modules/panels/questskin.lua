-- questskin.lua — 接任务/闲聊面板共享换皮 helper
-- 完全照任务日志面板(questlog.lua)：青铜金属框 CreatePaperDollFrame + 岩石底 + 羊皮纸
--   + RetailInset 凹陷槽 + 头像金环 + 红关闭 + minimal 滚动条。三面板视觉统一。
-- 铁律：复用 questlog 现成工厂，零自创；reload 不销毁 frame，建素材必守护

setfenv(1, DFUI:GetEnv())

-- 纹理隐藏/羊皮纸/头像 复用 paperdoll.lua 工厂（DFUI.HidePanelTextures/CreateParchment/AttachPortrait）

-- 共通换皮，返回 customBg（caller 用来接 minimal 滚动条 / 定位底部按钮）
function DFUI.SkinQuestStyleFrame(frame, opts)
    if not frame then return nil end
    opts = opts or {}
    if frame._dfQuestSkinned then return frame.dfCustomBg end

    -- 1. 隐藏 vanilla 纹理 + 原生关闭按钮
    local panels = opts.panels or {frame}
    for i = 1, table.getn(panels) do
        DFUI.HidePanelTextures(panels[i], {match = opts.hideMatch or "Quest"})
    end
    local vClose = getglobal(frame:GetName() .. "CloseButton")
    if vClose then vClose:Hide() end

    -- 2. 青铜金属框 + 岩石底（frameStyle=1，同任务日志）
    local customBg = DFUI.CreatePaperDollFrame(opts.name, frame, opts.width or 384, opts.height or 384, 1)
    customBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 70)
    customBg:SetFrameLevel(frame:GetFrameLevel() - 1)
    frame.dfCustomBg = customBg
    HookScript(frame, "OnShow", function() customBg:Show() end)

    -- 3. 羊皮纸（复用工厂，默认裁底部黑边）；taxi 走 skipParchment 露航点地图
    if not opts.skipParchment then
        DFUI.CreateParchment(customBg, {6, -60, -24, 6})
    end

    -- 4. 凹陷槽（框住羊皮纸，bg 隐藏露羊皮纸）
    local inset = DFUI.CreateRetailInset(customBg, {
        name        = (opts.name or "DFUI_Quest") .. "Inset",
        anchors     = {6, -60, -24, 12},       -- 硬编码默认；taxi 的 inset 锚点由 ApplyTaxiTweaks 事后重锚
        levelOffset = opts.insetLevelOffset,   -- nil → CreateRetailInset 内 or 1，与不传等价；taxi 传 8 浮于地图上
        followFrame = frame,
    })
    if inset and inset.bg then inset.bg:Hide() end

    -- 5. 头像（复用工厂，青铜框当圆环）
    -- portraitUnit（如 taxi="player"）：单位头像填进工厂自有 portrait 槽，几何微调由调用方事后调（taxi ApplyTaxiTweaks）；
    -- 否则走原路径，把传入的 vanilla NPC 头像 opts.portrait 塞进圆环（quest/gossip）
    if opts.portraitUnit and customBg.portrait then
        SetPortraitTexture(customBg.portrait, opts.portraitUnit)
        customBg.portrait:SetWidth(60)
        customBg.portrait:SetHeight(60)
        DFUI.AttachPortrait(customBg, customBg.portrait)
    else
        DFUI.AttachPortrait(customBg, opts.portrait)
    end

    -- 6. NPC 名字居中顶部（金色）
    if opts.nameText then
        opts.nameText:SetParent(customBg)
        opts.nameText:SetDrawLayer("OVERLAY", 1)
        opts.nameText:ClearAllPoints()
        opts.nameText:SetPoint("TOP", customBg, "TOP", 0, -6)
        if opts.nameText.SetTextColor then opts.nameText:SetTextColor(1, 0.82, 0) end  -- taxi 的 TaxiMerchant 防御判空（实为 FontString，恒真）
    end

    -- 7. 红关闭
    local closeButton = DFUI.CreateRedButton(customBg, "close", opts.onClose or function() HideUIPanel(frame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 5)

    CenterFrame(frame)
    frame._dfQuestSkinned = true
    return customBg
end

-- minimal 滚动条接管一组普通 ScrollFrame（照 questlog 详情页范式）
-- specs = { {sf="ScrollFrameName", sb="...ScrollBar", xOffset=2}, ... }
local function keepArrowsHideTrack(sbName)
    local sbar = getglobal(sbName)
    if not sbar then return end
    sbar._dfScrollSkinned = true   -- 抢占，挡 scrollbar.lua 青铜换肤
    sbar:Show(); sbar:SetAlpha(1)
    local top = getglobal(sbName .. "Top")
    local mid = getglobal(sbName .. "Middle")
    local bot = getglobal(sbName .. "Bottom")
    if top and top.SetTexture then top:SetTexture(nil); top:Hide() end
    if mid and mid.SetTexture then mid:SetTexture(nil); mid:Hide() end
    if bot and bot.SetTexture then bot:SetTexture(nil); bot:Hide() end
    local thumb = sbar.GetThumbTexture and sbar:GetThumbTexture()
    if thumb then thumb:SetTexture(nil) end
    local up = getglobal(sbName .. "ScrollUpButton")
    local dn = getglobal(sbName .. "ScrollDownButton")
    if up then up._dfScrollSkinned = true; up:SetAlpha(0); up:EnableMouse(false) end
    if dn then dn._dfScrollSkinned = true; dn:SetAlpha(0); dn:EnableMouse(false) end
end

function DFUI.AttachMinimalScrolls(ownerFrame, specs)
    if ownerFrame._dfMinimalScrolls then return end   -- 守护：reload 不重建滚动条/OnUpdate frame
    ownerFrame._dfMinimalScrolls = true
    local minis = {}
    for i = 1, table.getn(specs) do
        local sf = getglobal(specs[i].sf)
        local sb = getglobal(specs[i].sb)
        if sf and sb then
            keepArrowsHideTrack(specs[i].sb)
            local sbName = specs[i].sb
            HookScript(sb, "OnShow", function() keepArrowsHideTrack(sbName) end)
            local thisSf = sf
            local function setScroll(v)
                local range = thisSf:GetVerticalScrollRange()
                if v < 0 then v = 0 elseif v > range then v = range end
                thisSf:SetVerticalScroll(v)
            end
            local mini = DFUI.CreateMinimalScrollbar(sf, sb, {
                xOffset = specs[i].xOffset or 2, scale = 0.8, topInset = 8, botInset = 8, gap = 7,
                onScrollDelta = function(d) setScroll(thisSf:GetVerticalScroll() + d * 24) end,
                onScrollAbs   = function(r) setScroll(r * thisSf:GetVerticalScrollRange()) end,
            })
            table.insert(minis, {sf = thisSf, mini = mini})
        end
    end

    if table.getn(minis) > 0 then
        local syncT = 0
        CreateFrame("Frame"):SetScript("OnUpdate", function()
            syncT = syncT + (arg1 or 0)
            if syncT < 0.1 then return end
            syncT = 0
            if not ownerFrame:IsVisible() then return end
            for i = 1, table.getn(minis) do
                local e = minis[i]
                if e.sf:IsVisible() then
                    -- 箭头+滑块常显（range=0 时滑块占满、箭头变暗，不整条隐藏）
                    e.mini:Show()
                    local range = e.sf:GetVerticalScrollRange()
                    local t, b = e.sf:GetTop(), e.sf:GetBottom()
                    local vis = (t and b and (t - b) > 0) and (t - b) or e.sf:GetHeight()
                    e.mini.UpdateThumb(e.sf:GetVerticalScroll(), range, vis, vis + range)
                else
                    e.mini:Hide()
                end
            end
        end)
    end
end
