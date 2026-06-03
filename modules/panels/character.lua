setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

DFUI:NewDefaults("Character", {
    enabled = {true},
    showItemRarity = {true, "checkbox", nil, nil, "面板美化", 1, "显示装备品质边框", nil, nil},
})

DFUI:NewMod("Character", 5, function()
    -- 通用：隐藏框架所有暴雪背景纹理，保留图标/按钮相关
    local function HideBlizzardTextures(frame)
        if not frame then return end
        local regions = {frame:GetRegions()}
        for i = 1, table.getn(regions) do
            local region = regions[i]
            if region:GetObjectType() == "Texture" then
                local name = region:GetName()
                local texture = region:GetTexture()
                local skip = false
                if name then
                    if string.find(name, "Icon") or string.find(name, "Portrait") or string.find(name, "Check") or string.find(name, "Highlight") then
                        skip = true
                    end
                end
                if texture and (string.find(texture, "Icon") or string.find(texture, "Portrait") or string.find(texture, "StatusBar")) then
                    skip = true
                end
                if not skip then
                    region:Hide()
                end
            end
        end
    end

    -- 隐藏子框体上的暴雪纹理
    local frames = {PaperDollFrame, PetPaperDollFrame, SkillFrame, ReputationFrame, HonorFrame}
    for _, frame in ipairs(frames) do
        if frame then
            local regions = {frame:GetRegions()}
            for i = 1, table.getn(regions) do
                local region = regions[i]
                if region:GetObjectType() == "Texture" then
                    local texture = region:GetTexture()
                    if texture and (string.find(texture, "UI%-Character%-") or string.find(texture, "PaperDoll")) then
                        region:Hide()
                    end
                end
            end
        end
    end

    -- 隐藏 CharacterFrame 自身的背景/边框纹理（用 SetAlpha(0) 防止 tab 切换时被 Show 恢复）
    local cfRegions = {CharacterFrame:GetRegions()}
    for i = 1, table.getn(cfRegions) do
        local region = cfRegions[i]
        if region:GetObjectType() == "Texture" then
            local name = region:GetName()
            if not (name and string.find(name, "Portrait")) then
                region:SetAlpha(0)
            end
        end
    end

    -- 通用隐藏：清除 SkillFrame / ReputationFrame 上不匹配特定模式的残余纹理
    HideBlizzardTextures(SkillFrame)
    HideBlizzardTextures(ReputationFrame)

    -- 彻底清掉 SkillFrame 原生滚动条（含轨道/边框/底纹/箭头/滑块），鼠标滚轮仍可滚
    local function NukeScrollBar(f)
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
            NukeScrollBar(children[i])
        end
    end

    -- 隐藏 vanilla 滚动条视觉（箭头/轨道/thumb），保留 frame；视觉由 DFUI.CreateMinimalScrollbar 接管
    local function KeepArrowsHideTrack(sbName)
        local sb = getglobal(sbName)
        if not sb then return end
        sb._dfScrollSkinned = true   -- 抢先占位，挡 scrollbar.lua 的 ChatIcon 换肤/青铜 thumb
        sb:Show(); sb:SetAlpha(1)
        local top = getglobal(sbName.."Top")
        local mid = getglobal(sbName.."Middle")
        local bot = getglobal(sbName.."Bottom")
        if top and top.SetTexture then top:SetTexture(nil); top:Hide() end
        if mid and mid.SetTexture then mid:SetTexture(nil); mid:Hide() end
        if bot and bot.SetTexture then bot:SetTexture(nil); bot:Hide() end
        local thumb = sb.GetThumbTexture and sb:GetThumbTexture()
        if thumb then thumb:SetTexture(nil) end
        -- 上下按钮隐藏（视觉改由 DFUI.CreateMinimalScrollbar 接管）；alpha0+EnableMouse(false) 保活，不 Hide frame
        local function hideArrow(btn)
            if not btn then return end
            btn._dfScrollSkinned = true
            btn:SetAlpha(0); btn:EnableMouse(false)
        end
        hideArrow(getglobal(sbName.."ScrollUpButton"))
        hideArrow(getglobal(sbName.."ScrollDownButton"))
    end

    -- 再扫一遍 SkillListScrollFrame 自身的装饰纹理（残留竖条/边框/小箭头来源）
    if SkillListScrollFrame then
        local regions = {SkillListScrollFrame:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                r:SetTexture(nil); r:Hide()
            end
        end
        -- nuke SkillListScrollFrame 上所有 child frame（除内容承载 ScrollChildFrame）
        local scrollChild = SkillListScrollFrame:GetScrollChild()
        local children = {SkillListScrollFrame:GetChildren()}
        local sb = SkillListScrollFrameScrollBar
        for i = 1, table.getn(children) do
            if children[i] ~= scrollChild and children[i] ~= sb then
                NukeScrollBar(children[i])
            end
        end
    end

    -- 强清 SkillFrame 自身所有 texture（绕过 HideBlizzardTextures 的过滤白名单）
    if SkillFrame then
        local regions = {SkillFrame:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                r:SetTexture(nil); r:Hide()
            end
        end
    end

    -- 清掉 SkillFrame 右侧另一个 ScrollFrame：SkillDetailScrollFrame（技能详情区）
    -- pfUI 已验证（_dev/pfUI-master/skins/blizzard/character.lua:301-303）
    if SkillDetailScrollFrame then
        local regions = {SkillDetailScrollFrame:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                r:SetTexture(nil); r:Hide()
            end
        end
        NukeScrollBar(SkillDetailScrollFrameScrollBar)
        if SkillDetailScrollChildFrame then
            SkillDetailScrollChildFrame:Hide()
        end
    end

    -- 声望 tab 对应：清掉 ReputationDetailFrame 装饰（pfUI character.lua:254 实证）
    if ReputationDetailFrame then
        local regions = {ReputationDetailFrame:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                r:SetTexture(nil); r:Hide()
            end
        end
        if not ReputationDetailFrame._dfSkinned then
            ReputationDetailFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 14,
                insets = {left = 4, right = 4, top = 4, bottom = 4},
            })
            ReputationDetailFrame:SetBackdropColor(0.06, 0.06, 0.06, 0.92)
            ReputationDetailFrame:SetBackdropBorderColor(0.45, 0.38, 0.28, 1)
            ReputationDetailFrame._dfSkinned = true
        end
    end

    -- 声望 tab 跟技能 tab 同等处理：清 ReputationListScrollFrame regions/children
    if ReputationListScrollFrame then
        local regions = {ReputationListScrollFrame:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                r:SetTexture(nil); r:Hide()
            end
        end
        local scrollChild = ReputationListScrollFrame:GetScrollChild()
        local children = {ReputationListScrollFrame:GetChildren()}
        local sb = ReputationListScrollFrameScrollBar
        for i = 1, table.getn(children) do
            if children[i] ~= scrollChild and children[i] ~= sb then
                NukeScrollBar(children[i])
            end
        end
    end

    -- 声望 tab 强清 ReputationFrame regions（绕过 HideBlizzardTextures 白名单过滤）
    if ReputationFrame then
        local regions = {ReputationFrame:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                r:SetTexture(nil); r:Hide()
            end
        end
    end

    CharacterFrameTab1:Hide()
    CharacterFrameTab2:Hide()
    CharacterFrameTab3:Hide()
    CharacterFrameTab4:Hide()
    CharacterFrameTab5:Hide()
    CharacterFrameCloseButton:Hide()
    PetPaperDollCloseButton:Hide()
    SkillFrameCancelButton:Hide()

    -- 荣誉/竞技场：隐藏暴雪纹理
    local function StripHonorAndArena()
        HideBlizzardTextures(HonorFrame)
        if ArenaFrame then
            HideBlizzardTextures(ArenaFrame)
            -- 美化团队按钮
            for i = 1, 3 do
                local team = getglobal("ArenaFrameTeam" .. i)
                if team and not team._dfSkinned then
                    team:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Buttons\\WHITE8X8",
                        edgeSize = 1,
                    })
                    team:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                    team:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
                    team._dfSkinned = true
                end
            end
        end
    end

    -- 技能 Tab："全部"区域 — 金属 Tab 风格
    -- SkillFrameExpandButtonFrame 是容器（含"全部"文字背景），CollapseAllButton 是里面的 +/- 箭头
    if SkillFrameExpandButtonFrame then
        SkillFrameExpandButtonFrame:DisableDrawLayer("BACKGROUND")

        local skillTabsPath = TEX .. "interface\\uiframetabs.blp"
        local anchor = SkillFrameExpandButtonFrame
        local sw = anchor:GetWidth() / 2
        local sh = 28

        local sLeft = anchor:CreateTexture(nil, "BACKGROUND")
        sLeft:SetTexture(skillTabsPath)
        sLeft:SetWidth(sw)
        sLeft:SetHeight(sh)
        sLeft:SetPoint("TOPLEFT", anchor, "TOPLEFT", -3, 4)
        sLeft:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)

        local sRight = anchor:CreateTexture(nil, "BACKGROUND")
        sRight:SetTexture(skillTabsPath)
        sRight:SetWidth(sw)
        sRight:SetHeight(sh)
        sRight:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 5, 4)
        sRight:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)

        local sMiddle = anchor:CreateTexture(nil, "BACKGROUND")
        sMiddle:SetTexture(skillTabsPath)
        sMiddle:SetHeight(sh)
        sMiddle:SetPoint("TOPLEFT", sLeft, "TOPRIGHT", 0, 0)
        sMiddle:SetPoint("TOPRIGHT", sRight, "TOPLEFT", 0, 0)
        sMiddle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
    end

    -- 称号下拉框（Turtle WoW 自定义：PaperDollFrameTitlesDropdown）
    local titlesDropdown = PaperDollFrameTitlesDropdown
    if titlesDropdown then
        -- 只隐藏暴雪背景纹理，不动位置、不动文字
        local regions = {titlesDropdown:GetRegions()}
        for i = 1, table.getn(regions) do
            local region = regions[i]
            if region:GetObjectType() == "Texture" then
                local name = region:GetName()
                -- 保留文字（FontString不会进这里）和箭头按钮纹理
                if not name or not string.find(name, "Button") then
                    region:SetTexture(nil)
                end
            end
        end

        -- 缩短宽度
        titlesDropdown:SetWidth(180)

        -- 重新定位箭头按钮到框体内
        local titleBtn = PaperDollFrameTitlesDropdownButton
        if titleBtn then
            titleBtn:ClearAllPoints()
            titleBtn:SetPoint("RIGHT", titlesDropdown, "RIGHT", -18, 2)
        end

        -- 重新定位称号文字到框体内
        local titleText = PaperDollFrameTitlesDropdownText
        if titleText then
            titleText:ClearAllPoints()
            titleText:SetPoint("LEFT", titlesDropdown, "LEFT", 24, 2)
            titleText:SetPoint("RIGHT", titleBtn or titlesDropdown, "LEFT", -4, 0)
        end

        -- 暗色背景框，和面板岩石背景融合
        local titleBg = CreateFrame("Frame", nil, titlesDropdown)
        titleBg:SetPoint("TOPLEFT", titlesDropdown, "TOPLEFT", 16, 0)
        titleBg:SetPoint("BOTTOMRIGHT", titlesDropdown, "BOTTOMRIGHT", -16, 4)
        titleBg:SetFrameLevel(titlesDropdown:GetFrameLevel())
        titleBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = {left = 2, right = 2, top = 2, bottom = 2},
        })
        titleBg:SetBackdropColor(0.06, 0.06, 0.06, 0.85)
        titleBg:SetBackdropBorderColor(0.35, 0.32, 0.28, 0.7)
    end

    _G.PetTab_Update = function() end

    local customBg = DFUI.CreatePaperDollFrame("DFUI_CharacterBg", CharacterFrame, 384, 512, 1)
    customBg:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -32, 75)
    customBg:SetFrameLevel(CharacterFrame:GetFrameLevel() + 1)
    customBg.Bg:SetDrawLayer("BACKGROUND", -1)

    CharacterFramePortrait:SetParent(customBg)
    CharacterFramePortrait:SetDrawLayer("BORDER", 0)

    local characterBg = customBg:CreateTexture(nil, "OVERLAY")
    characterBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    characterBg:SetPoint("TOPLEFT", customBg, "TOPLEFT", 55, -60)
    characterBg:SetPoint("BOTTOMRIGHT", customBg, "BOTTOMRIGHT", -55, 60)
    characterBg:SetVertexColor(0, 0, 0, 0.3)
    characterBg:Hide()

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(CharacterFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    -- 声望 Tab 凹陷容器（retail-style 9-slice + marble 底）
    local reputationInset = DFUI.CreateRetailInset(customBg, {
        name        = "DFUI_ReputationInset",
        anchors     = {3, -65, -6, 6},
        followFrame = ReputationFrame,
    })

    -- 技能 Tab 凹陷容器（留出顶部"全部"金属按钮 + 列标签）
    local skillInset = DFUI.CreateRetailInset(customBg, {
        name        = "DFUI_SkillInset",
        anchors     = {3, -65, -6, 6},
        followFrame = SkillFrame,
    })

    -- 荣誉 Tab 凹陷容器（留出子 Tab 区，跟随 HonorFrame 和 ArenaFrame 任一显示）
    -- 上边界 -55 → -85（向下挪 30px），给子 tab 区让出更多空间
    local honorInset = DFUI.CreateRetailInset(customBg, {
        name         = "DFUI_HonorInset",
        anchors      = {3, -85, -6, 6},
        followFrames = {HonorFrame, ArenaFrame},
    })

    -- 提升 HonorFrame / ArenaFrame FrameLevel 跨过 honorInset
    -- 让 vanilla 数据 FontString 浮在 honorInset (marble) 之上
    if HonorFrame then HonorFrame:SetFrameLevel(honorInset:GetFrameLevel() + 1) end
    if ArenaFrame then ArenaFrame:SetFrameLevel(honorInset:GetFrameLevel() + 1) end

    -- 声望 tab / 技能 tab：隐藏 vanilla 滚动条，下方加 DFUI.CreateMinimalScrollbar 接管视觉
    -- 鼠标滚轮仍能滚动列表（FauxScrollFrame 自带 OnMouseWheel，vanilla offset 链路保留）
    if ReputationListScrollFrame and ReputationListScrollFrameScrollBar then
        KeepArrowsHideTrack("ReputationListScrollFrameScrollBar")
        -- 持续压住轨道（引擎在 ScrollFrame OnShow 时会重 Show/恢复纹理），函数幂等
        HookScript(ReputationListScrollFrameScrollBar, "OnShow", function()
            KeepArrowsHideTrack("ReputationListScrollFrameScrollBar")
        end)
    end
    if SkillListScrollFrame and SkillListScrollFrameScrollBar then
        KeepArrowsHideTrack("SkillListScrollFrameScrollBar")
        HookScript(SkillListScrollFrameScrollBar, "OnShow", function()
            KeepArrowsHideTrack("SkillListScrollFrameScrollBar")
        end)
    end

    -- DF minimal 滚动条（参数同社交）。驱动/读取 vanilla offset 全走 scrollbar 的 Slider API
    -- (GetMinMaxValues/GetValue/SetValue)，**绝不 hook** SkillFrame_UpdateSkills/ReputationFrame_Update
    -- （它们含 FixSkillBarColors/进度条填充，往里塞东西会连累 → 上次破坏教训）；thumb 同步用独立节流 OnUpdate。
    local repSB, skillSB
    local function setFauxOffset(sbar, newOff, maxOff)
        if newOff < 0 then newOff = 0 elseif newOff > maxOff then newOff = maxOff end
        local lo, hi = sbar:GetMinMaxValues()
        sbar:SetValue((maxOff > 0) and (lo + newOff / maxOff * (hi - lo)) or lo)
    end
    local function fauxOffsetOf(sbar, maxOff)  -- 从 scrollbar 像素值反推行 offset(不依赖 FauxScrollFrame_GetOffset)
        local lo, hi = sbar:GetMinMaxValues()
        if hi <= lo or maxOff <= 0 then return 0 end
        local o = math.floor((sbar:GetValue() - lo) / (hi - lo) * maxOff + 0.5)
        if o < 0 then return 0 elseif o > maxOff then return maxOff end
        return o
    end
    if ReputationListScrollFrame and ReputationListScrollFrameScrollBar then
        repSB = DFUI.CreateMinimalScrollbar(ReputationListScrollFrame, ReputationListScrollFrameScrollBar, {
            xOffset = -3, scale = 0.8, arrowTopPad = 0, arrowBotPad = 0, topInset = 8, botInset = 8, gap = 7,
            onScrollDelta = function(d)
                local maxOff = math.max(0, GetNumFactions() - (NUM_FACTIONS_DISPLAYED or 15))
                setFauxOffset(ReputationListScrollFrameScrollBar, fauxOffsetOf(ReputationListScrollFrameScrollBar, maxOff) + d, maxOff)
            end,
            onScrollAbs = function(r)
                local maxOff = math.max(0, GetNumFactions() - (NUM_FACTIONS_DISPLAYED or 15))
                setFauxOffset(ReputationListScrollFrameScrollBar, math.floor(r * maxOff + 0.5), maxOff)
            end,
        })
    end
    if SkillListScrollFrame and SkillListScrollFrameScrollBar then
        skillSB = DFUI.CreateMinimalScrollbar(SkillListScrollFrame, SkillListScrollFrameScrollBar, {
            xOffset = -3, scale = 0.8, arrowTopPad = 0, arrowBotPad = 0, topInset = 8, botInset = 8, gap = 7,
            onScrollDelta = function(d)
                local maxOff = math.max(0, GetNumSkillLines() - (SKILLS_TO_DISPLAY or 15))
                setFauxOffset(SkillListScrollFrameScrollBar, fauxOffsetOf(SkillListScrollFrameScrollBar, maxOff) + d, maxOff)
            end,
            onScrollAbs = function(r)
                local maxOff = math.max(0, GetNumSkillLines() - (SKILLS_TO_DISPLAY or 15))
                setFauxOffset(SkillListScrollFrameScrollBar, math.floor(r * maxOff + 0.5), maxOff)
            end,
        })
    end
    if repSB or skillSB then  -- thumb 同步：独立节流 OnUpdate(0.1s)，读 scrollbar 反推 offset；不碰任何 vanilla update
        local syncT = 0
        CreateFrame("Frame"):SetScript("OnUpdate", function()
            syncT = syncT + (arg1 or 0)
            if syncT < 0.1 then return end
            syncT = 0
            if repSB and ReputationFrame and ReputationFrame:IsVisible() then
                local total = GetNumFactions(); local m = math.max(0, total - (NUM_FACTIONS_DISPLAYED or 15))
                repSB.UpdateThumb(fauxOffsetOf(ReputationListScrollFrameScrollBar, m), m, (NUM_FACTIONS_DISPLAYED or 15), total)
            end
            if skillSB and SkillFrame and SkillFrame:IsVisible() then
                local total = GetNumSkillLines(); local m = math.max(0, total - (SKILLS_TO_DISPLAY or 15))
                skillSB.UpdateThumb(fauxOffsetOf(SkillListScrollFrameScrollBar, m), m, (SKILLS_TO_DISPLAY or 15), total)
            end
        end)
    end

    -- 荣誉 Tab 状态 + 子 Tab 前向声明
    local honorTabActive = false
    local honorSubTab1, honorSubTab2

    -- 离开荣誉 Tab 时的清理
    local function LeaveHonorTab()
        honorTabActive = false
        if honorSubTab1 then honorSubTab1:Hide() end
        if honorSubTab2 then honorSubTab2:Hide() end
        if ArenaFrame then ArenaFrame:Hide() end
    end

    -- Tabs
    customBg:AddTab("角色", function()
        LeaveHonorTab()
        characterBg:Show()
        CharacterFrame_ShowSubFrame("PaperDollFrame")
        PanelTemplates_SetTab(CharacterFrame, 1)
    end, 70)

    local petTab = customBg:AddTab("宠物", function()
        LeaveHonorTab()
        characterBg:Hide()
        CharacterFrame_ShowSubFrame("PetPaperDollFrame")
        PanelTemplates_SetTab(CharacterFrame, 2)
    end, 55)

    customBg:AddTab("声望", function()
        LeaveHonorTab()
        characterBg:Hide()
        CharacterFrame_ShowSubFrame("ReputationFrame")
        PanelTemplates_SetTab(CharacterFrame, 3)
    end, 70)

    function customBg:UpdatePetTab()
        if HasPetUI() then
            petTab:Show()
        else
            petTab:Hide()
            if customBg.Tabs[3] then
                customBg.Tabs[3]:ClearAllPoints()
                customBg.Tabs[3]:SetPoint("BOTTOMLEFT", customBg.Tabs[1], "BOTTOMRIGHT", 4, 0)
            end
        end
        if HasPetUI() and customBg.Tabs[3] then
            customBg.Tabs[3]:ClearAllPoints()
            customBg.Tabs[3]:SetPoint("BOTTOMLEFT", petTab, "BOTTOMRIGHT", 4, 0)
        end
    end

    customBg:AddTab("技能", function()
        LeaveHonorTab()
        characterBg:Hide()
        CharacterFrame_ShowSubFrame("SkillFrame")
        PanelTemplates_SetTab(CharacterFrame, 4)
    end, 55)

    -- 荣誉 Tab：进入时默认显示荣誉子页
    customBg:AddTab("荣誉", function()
        characterBg:Hide()
        honorTabActive = true
        CharacterFrame_ShowSubFrame("HonorFrame")
        PanelTemplates_SetTab(CharacterFrame, 5)
        -- 默认显示荣誉子页
        if ArenaFrame then ArenaFrame:Hide() end
        HonorFrame:Show()
        if honorSubTab1 then
            honorSubTab1:SetSelected(true)
            honorSubTab1:Show()
        end
        if honorSubTab2 then
            honorSubTab2:SetSelected(false)
            honorSubTab2:Show()
        end
    end, 55)

    -- 隐藏暴雪原生子 Tab（HonorFrame + ArenaFrame 各有一组）
    local blizzTabs = {HonorFrameTab1, HonorFrameTab2, ArenaFrameTab1, ArenaFrameTab2}
    for _, tab in ipairs(blizzTabs) do
        if tab then
            tab:Hide()
            tab:SetScript("OnShow", function() this:Hide() end)
        end
    end

    -- 自定义荣誉/竞技场子 Tab（缩小版金属 Tab，与主 Tab 同风格）
    local tabsPath = TEX .. "interface\\uiframetabs.blp"
    local function CreateSubTab(parent, text, tabWidth)
        tabWidth = tabWidth or 55
        local tab = CreateFrame("Button", nil, parent)
        tab:SetWidth(tabWidth)
        tab:SetHeight(24)

        local edgeW = tabWidth / 2
        local h = 28

        -- 未选中态
        local left = tab:CreateTexture(nil, "BACKGROUND")
        left:SetTexture(tabsPath)
        left:SetWidth(edgeW)
        left:SetHeight(h)
        left:SetPoint("TOPLEFT", tab, "TOPLEFT", -3, 0)
        left:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)

        local right = tab:CreateTexture(nil, "BACKGROUND")
        right:SetTexture(tabsPath)
        right:SetWidth(edgeW)
        right:SetHeight(h)
        right:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 5, 0)
        right:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)

        local middle = tab:CreateTexture(nil, "BACKGROUND")
        middle:SetTexture(tabsPath)
        middle:SetHeight(h)
        middle:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
        middle:SetPoint("TOPRIGHT", right, "TOPLEFT", 0, 0)
        middle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)

        -- 选中态
        local selH = 30
        local leftSel = tab:CreateTexture(nil, "BACKGROUND")
        leftSel:SetTexture(tabsPath)
        leftSel:SetWidth(edgeW)
        leftSel:SetHeight(selH)
        leftSel:SetPoint("TOPLEFT", tab, "TOPLEFT", -1, 0)
        leftSel:SetTexCoord(0.015625, 0.5625, 0.496094, 0.660156)
        leftSel:Hide()

        local rightSel = tab:CreateTexture(nil, "BACKGROUND")
        rightSel:SetTexture(tabsPath)
        rightSel:SetWidth(edgeW)
        rightSel:SetHeight(selH)
        rightSel:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 6, 0)
        rightSel:SetTexCoord(0.015625, 0.59375, 0.324219, 0.488281)
        rightSel:Hide()

        local middleSel = tab:CreateTexture(nil, "BACKGROUND")
        middleSel:SetTexture(tabsPath)
        middleSel:SetHeight(selH)
        middleSel:SetPoint("TOPLEFT", leftSel, "TOPRIGHT", 0, 0)
        middleSel:SetPoint("TOPRIGHT", rightSel, "TOPLEFT", 0, 0)
        middleSel:SetTexCoord(0, 0.015625, 0.00390625, 0.167969)
        middleSel:Hide()

        -- 高亮（鼠标悬停）
        local hlLeft = tab:CreateTexture(nil, "HIGHLIGHT")
        hlLeft:SetTexture(tabsPath)
        hlLeft:SetWidth(edgeW)
        hlLeft:SetHeight(h)
        hlLeft:SetPoint("TOPLEFT", tab, "TOPLEFT", -3, 0)
        hlLeft:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
        hlLeft:SetBlendMode("ADD")
        hlLeft:SetAlpha(0.4)

        local hlRight = tab:CreateTexture(nil, "HIGHLIGHT")
        hlRight:SetTexture(tabsPath)
        hlRight:SetWidth(edgeW)
        hlRight:SetHeight(h)
        hlRight:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 5, 0)
        hlRight:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
        hlRight:SetBlendMode("ADD")
        hlRight:SetAlpha(0.4)

        local hlMiddle = tab:CreateTexture(nil, "HIGHLIGHT")
        hlMiddle:SetTexture(tabsPath)
        hlMiddle:SetHeight(h)
        hlMiddle:SetPoint("TOPLEFT", hlLeft, "TOPRIGHT", 0, 0)
        hlMiddle:SetPoint("TOPRIGHT", hlRight, "TOPLEFT", 0, 0)
        hlMiddle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
        hlMiddle:SetBlendMode("ADD")
        hlMiddle:SetAlpha(0.4)

        -- 文字
        local label = tab:CreateFontString(nil, "BORDER", "GameFontNormalSmall")
        label:SetPoint("CENTER", tab, "CENTER", 0, 2)
        label:SetText(text)
        tab._label = label

        function tab:SetSelected(selected)
            if selected then
                left:Hide(); right:Hide(); middle:Hide()
                leftSel:Show(); rightSel:Show(); middleSel:Show()
                hlLeft:SetHeight(selH); hlRight:SetHeight(selH); hlMiddle:SetHeight(selH)
                label:SetTextColor(1, 1, 1)
            else
                left:Show(); right:Show(); middle:Show()
                leftSel:Hide(); rightSel:Hide(); middleSel:Hide()
                hlLeft:SetHeight(h); hlRight:SetHeight(h); hlMiddle:SetHeight(h)
                label:SetTextColor(1, 0.82, 0)
            end
        end

        return tab
    end

    honorSubTab1 = CreateSubTab(customBg, "荣誉", 50)
    honorSubTab1:SetPoint("TOPLEFT", customBg, "TOPLEFT", 55, -28)
    honorSubTab1:SetFrameLevel(customBg:GetFrameLevel() + 2)
    honorSubTab1:SetSelected(true)

    honorSubTab2 = CreateSubTab(customBg, "竞技场", 55)
    honorSubTab2:SetPoint("LEFT", honorSubTab1, "RIGHT", 2, 0)
    honorSubTab2:SetFrameLevel(customBg:GetFrameLevel() + 2)

    -- 子 Tab 只在荣誉主 Tab 选中时显示
    honorSubTab1:Hide()
    honorSubTab2:Hide()

    local function ShowHonorSubTabs()
        honorSubTab1:Show()
        honorSubTab2:Show()
    end

    honorSubTab1:SetScript("OnClick", function()
        PlaySound("igCharacterInfoTab")
        if ArenaFrame then ArenaFrame:Hide() end
        HonorFrame:Show()
        honorSubTab1:SetSelected(true)
        honorSubTab2:SetSelected(false)
        ShowHonorSubTabs()
    end)

    honorSubTab2:SetScript("OnClick", function()
        PlaySound("igCharacterInfoTab")
        HonorFrame:Hide()
        if ArenaFrame then ArenaFrame:Show() end
        honorSubTab1:SetSelected(false)
        honorSubTab2:SetSelected(true)
        ShowHonorSubTabs()
    end)

    -- 荣誉纹理清理：首次显示时执行
    local honorSkinned = false
    HookScript(HonorFrame, "OnShow", function()
        if not honorSkinned then
            StripHonorAndArena()
            honorSkinned = true
        end
        if honorTabActive then
            ShowHonorSubTabs()
        end
    end)

    -- 竞技场首次显示时也清理纹理
    if ArenaFrame then
        HookScript(ArenaFrame, "OnShow", function()
            if not honorSkinned then
                StripHonorAndArena()
                honorSkinned = true
            end
            if honorTabActive then
                ShowHonorSubTabs()
            end
        end)
    end

    -- 宠物 Tab 动态
    customBg:RegisterEvent("PET_UI_UPDATE")
    customBg:RegisterEvent("PET_BAR_UPDATE")
    customBg:RegisterEvent("UNIT_PET")
    customBg:SetScript("OnEvent", function()
        if event == "PET_UI_UPDATE" or event == "PET_BAR_UPDATE" or (event == "UNIT_PET" and arg1 == "player") then
            customBg:UpdatePetTab()
        end
    end)
    customBg:UpdatePetTab()

    CenterFrame(CharacterFrame)
    HookScript(CharacterFrame, "OnShow", function()
        customBg:Show()
    end)

    -- ToggleCharacter Hook
    local originalToggleCharacter = _G.ToggleCharacter
    _G.ToggleCharacter = function(tab)
        originalToggleCharacter(tab)
        if CharacterFrame:IsVisible() and customBg.Tabs then
            local tabIndex = nil
            local hasPet = HasPetUI()

            if tab == "PaperDollFrame" then
                tabIndex = 1
            elseif tab == "PetPaperDollFrame" and hasPet then
                tabIndex = 2
            elseif tab == "ReputationFrame" then
                tabIndex = 3
            elseif tab == "SkillFrame" then
                tabIndex = 4
            elseif tab == "HonorFrame" then
                tabIndex = 5
            end

            local selectedTab = customBg.Tabs[tabIndex]
            if selectedTab then
                selectedTab:GetScript("OnClick")()
            end
        end
    end

    -- 装备品质边框
    local slots = {"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands", "Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard", "Ammo"}
    local slotButtons = {}

    for _, slot in ipairs(slots) do
        local button = getglobal("Character" .. slot .. "Slot")
        if button then
            table.insert(slotButtons, button)
            local icon = getglobal("Character" .. slot .. "SlotIconTexture")
            if icon then
                button.qualityBorder = CreateFrame("Frame", nil, button)
                button.qualityBorder:SetAllPoints(icon)
                button.qualityBorderTex = button.qualityBorder:CreateTexture(nil, "OVERLAY")
                button.qualityBorderTex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                button.qualityBorderTex:SetBlendMode("ADD")
                button.qualityBorderTex:SetPoint("TOPLEFT", button.qualityBorder, "TOPLEFT", -14, 14)
                button.qualityBorderTex:SetPoint("BOTTOMRIGHT", button.qualityBorder, "BOTTOMRIGHT", 14, -14)
                button.qualityBorder:Hide()
            end
        end
    end

    local function UpdateQualityBorders(enabled)
        local colors = {{0.62,0.62,0.62}, {1,1,1}, {0,1,0}, {0,0.44,0.87}, {0.64,0.21,0.93}, {1,0.5,0}}
        for _, button in pairs(slotButtons) do
            if button.qualityBorder then
                if enabled then
                    local quality = GetInventoryItemQuality("player", button:GetID())
                    if quality and quality > 1 then
                        local c = colors[quality + 1] or {1, 1, 1}
                        button.qualityBorderTex:SetVertexColor(c[1], c[2], c[3], 0.7)
                        button.qualityBorder:Show()
                    else
                        button.qualityBorder:Hide()
                    end
                else
                    button.qualityBorder:Hide()
                end
            end
        end
    end

    local inventoryFrame = CreateFrame("Frame")
    inventoryFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    inventoryFrame:SetScript("OnEvent", function()
        if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
            if DFUI.tempDB["Character"] and DFUI.tempDB["Character"]["showItemRarity"] then
                UpdateQualityBorders(true)
            end
        end
    end)

    -- ============================================================
    -- Retail 进度条 + 折叠按钮（声望条 / 技能条 / SkillTypeLabel）
    -- 素材：_html_dict atlas → media/tex/character/（A 方案独立切片 + B 方案 atlas 整图）
    -- 字典 UV 坐标：uiframebars.png (256×256)
    -- ============================================================
    local CHAR_TEX = TEX .. "character\\"
    -- A/B 切换：false=A 方案（独立 TGA 切片，SetTexture 直接引用）
    --          true =B 方案（atlas 整图 + SetTexCoord 切片）
    local BAR_USE_ATLAS = false

    -- texName 默认 fill-white.tga（声望条用，靠 vanilla SetStatusBarColor 按好感度染色）
    local function ApplyBarFill(bar, texName)
        texName = texName or "fill-white.tga"
        if BAR_USE_ATLAS then
            -- B 方案：tradeskill.lua:494-498 已验证模式
            -- 先 CreateTexture 设 TexCoord 锁定 atlas 子区域，再 SetStatusBarTexture(obj)
            local fill = bar:CreateTexture(nil, "ARTWORK")
            fill:SetTexture(CHAR_TEX .. "atlas-uiframebars.tga")
            fill:SetTexCoord(0, 1, 163/256, 180/256)  -- white 行 (y=163..180)
            bar:SetStatusBarTexture(fill)
        else
            -- A 方案：独立切片（256×16 POT）
            -- ⚠ 必须 POT：1.12 SetStatusBarTexture 对非 POT 文件静默拒绝、保留前一张纹理，
            --   曾经 256×17 → 永远退回 vanilla UI-Character-Skills-Bar（见 reference-wow112-tga-pot）
            bar:SetStatusBarTexture(CHAR_TEX .. texName)
        end
    end

    -- 声望进度条（ReputationBar1..N，FauxScrollFrame 复用）
    for i = 1, (NUM_FACTIONS_DISPLAYED or 15) do
        local bar = getglobal("ReputationBar" .. i)
        if bar and bar.SetStatusBarTexture then
            ApplyBarFill(bar)
            -- 保留 vanilla SetStatusBarColor —— ReputationFrame_Update 按好感度阶段染色
        end
    end

    -- 技能进度条（SkillRankFrame1..N）
    for i = 1, (SKILLS_TO_DISPLAY or 15) do
        local bar = getglobal("SkillRankFrame" .. i)
        if bar and bar.SetStatusBarTexture then
            -- 技能条：vanilla 不按状态染色（蓝色烤进原版纹理 UI-Character-Skills-Bar），
            -- 换白底 fill 会失色看不见 → 改用预上色 fill-blue + 复位 color(1,1,1) 让 DF 蓝如实显示
            ApplyBarFill(bar, "fill-blue.tga")
            bar:SetStatusBarColor(1, 1, 1, 1)   -- 4 参：必须带 alpha=1，否则顶不掉 vanilla 的 0.5 半透明
            -- SkillRankFrame{i}Border 在 1.12 vanilla 是 Frame（不是 Texture），无 SetTexture
            local border = getglobal("SkillRankFrame" .. i .. "Border")
            if border and border.Hide then border:Hide() end
        end
    end

    -- 技能条颜色修复（根因实证 2026-06-02）：vanilla SkillFrame_UpdateSkills 每次刷新会把技能条
    -- statusbarcolor 改成半透明蓝(0,0,1,0.5)，叠在深色 Solid 背景上 fill-blue 看不见（冷启动/滚动/
    -- 切tab 竞态，谁后跑谁赢→时好时坏）。post-hook 在 vanilla 之后用 4 参 (1,1,1,1) 顶回不透明。
    -- 按技能分组着色：护甲专精/职业技能/语言 → 灰(fill-white 银灰高光，与 fill-blue 同风格)，
    -- 其他(武器技能/副职业/…) → 蓝(fill-blue)。一律 4 参 (1,1,1,1) 顶掉 vanilla 半透明蓝。
    local SKILL_GRAY_TEX = CHAR_TEX .. "fill-white.tga"
    local SKILL_BLUE_TEX = CHAR_TEX .. "fill-blue.tga"
    local GRAY_HEADERS = { ["护甲专精"] = true, ["职业技能"] = true, ["语言"] = true }
    local function FixSkillBarColors()
        -- 建"技能行索引 → 所属分组名"映射（按当前展开后的列表）
        local headerOf, cur = {}, nil
        local numLines = GetNumSkillLines and GetNumSkillLines() or 0
        for idx = 1, numLines do
            local nm, isHeader = GetSkillLineInfo(idx)
            if isHeader then cur = nm else headerOf[idx] = cur end
        end
        local offset = 0
        if SkillListScrollFrame and FauxScrollFrame_GetOffset then
            offset = FauxScrollFrame_GetOffset(SkillListScrollFrame)
        end
        for i = 1, (SKILLS_TO_DISPLAY or 15) do
            local b = getglobal("SkillRankFrame" .. i)
            if b and b.SetStatusBarTexture then
                local hdr = headerOf[offset + i]
                if hdr and GRAY_HEADERS[hdr] then
                    b:SetStatusBarTexture(SKILL_GRAY_TEX)
                else
                    b:SetStatusBarTexture(SKILL_BLUE_TEX)
                end
                b:SetStatusBarColor(1, 1, 1, 1)
            end
        end
    end
    if type(SkillFrame_UpdateSkills) == "function" then
        local _origUpdateSkills = SkillFrame_UpdateSkills
        setglobal("SkillFrame_UpdateSkills", function(a1, a2, a3, a4, a5, a6, a7, a8, a9)
            _origUpdateSkills(a1, a2, a3, a4, a5, a6, a7, a8, a9)
            FixSkillBarColors()
        end)
    end

    -- SkillTypeLabel 折叠分组 header（清原生纹理 + 加 DF 深色底）
    for i = 1, (SKILLS_TO_DISPLAY or 15) do
        local header = getglobal("SkillTypeLabel" .. i)
        if header and not header._dfSkinned then
            local hr = {header:GetRegions()}
            for j = 1, table.getn(hr) do
                local r = hr[j]
                if r.GetObjectType and r:GetObjectType() == "Texture" then
                    local tex = r:GetTexture()
                    if not (tex and (string.find(tex, "PlusButton") or string.find(tex, "MinusButton"))) then
                        r:SetTexture(nil); r:Hide()
                    end
                end
            end
            local bg = header:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetVertexColor(0.10, 0.09, 0.07, 0.85)
            bg:SetPoint("TOPLEFT", header, "TOPLEFT", 0, -1)
            bg:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 1)
            header._dfSkinned = true
        end
    end

    local callbacks = {}
    callbacks.showItemRarity = function(value)
        UpdateQualityBorders(value)
    end
    DFUI:NewCallbacks("Character", callbacks)
end)
