setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

local DF_GOLD = {1.00, 0.82, 0.00}        -- 标题金
local SLOT    = TEX .. "panels\\df\\professions\\slot_blue.tga"  -- DF 图标边框（复用专业槽位素材）
local NAME_GUTTER_X = 22                   -- 技能行名字左缘距"行左缘"的留白(留出 header 的 +/− 折叠按钮位;调大=名字更靠右)

DFUI:NewDefaults("Trainer", {
    enabled = {true},
})

DFUI:NewMod("Trainer", 5, function()
    -- ====== 滚动条遥控辅助（照搬 questlog.lua 范式：隐藏 vanilla 箭头/轨道，minimal 滑块驱动 vanilla offset）======
    local function KeepArrowsHideTrack(sbName)
        local sbar = getglobal(sbName)
        if not sbar then return end
        sbar._dfScrollSkinned = true          -- 抢占，挡 scrollbar.lua 青铜换肤
        sbar:Show(); sbar:SetAlpha(1)
        local top = getglobal(sbName .. "Top")
        local mid = getglobal(sbName .. "Middle")
        local bot = getglobal(sbName .. "Bottom")
        if top and top.SetTexture then top:SetTexture(nil); top:Hide() end
        if mid and mid.SetTexture then mid:SetTexture(nil); mid:Hide() end
        if bot and bot.SetTexture then bot:SetTexture(nil); bot:Hide() end
        local thumb = sbar.GetThumbTexture and sbar:GetThumbTexture()
        if thumb then thumb:SetTexture(nil) end
        local function hideArrow(btn)
            if not btn then return end
            btn._dfScrollSkinned = true
            btn:SetAlpha(0); btn:EnableMouse(false)
        end
        hideArrow(getglobal(sbName .. "ScrollUpButton"))
        hideArrow(getglobal(sbName .. "ScrollDownButton"))
    end

    -- FauxScrollFrame 列表：走 vanilla scrollbar Slider API 驱动 offset（SetValue 触发列表刷新）
    local function setFauxOffset(sbar, newOff, maxOff)
        if newOff < 0 then newOff = 0 elseif newOff > maxOff then newOff = maxOff end
        local lo, hi = sbar:GetMinMaxValues()
        sbar:SetValue((maxOff > 0) and (lo + newOff / maxOff * (hi - lo)) or lo)
    end
    local function fauxOffsetOf(sbar, maxOff)
        local lo, hi = sbar:GetMinMaxValues()
        if hi <= lo or maxOff <= 0 then return 0 end
        local o = math.floor((sbar:GetValue() - lo) / (hi - lo) * maxOff + 0.5)
        if o < 0 then return 0 elseif o > maxOff then return maxOff end
        return o
    end

    -- 列表行换皮：hover/选中共用长条行高亮 UI-QuestLogTitleHighlight(ADD 金，同制造面板行) —— vanilla 选中靠 LockHighlight 常驻显示
    local function SkinRow(btn)
        if not btn or btn._dfRowSkinned then return end
        btn._dfRowSkinned = true
        btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
        local hl = btn:GetHighlightTexture()
        if hl then
            hl:SetBlendMode("ADD")
            hl:SetAllPoints(btn)
            hl:SetVertexColor(1.0, 0.82, 0.0, 0.45)
        end
    end

    -- strip 一个 frame 的直属装饰纹理（只动 Texture，不碰 FontString/子 frame）
    local function StripRegionTextures(f)
        if not f then return end
        local regions = {f:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                r:SetTexture(nil); r:Hide()
            end
        end
    end

    local function SkinClassTrainerFrame()
        -- 守护用 frame 字段(跨 reload 持久)而非模块 local(reload 重置)，否则 reload 叠加重复 customBg/凹陷/滑块 + 累积 OnUpdate frame
        if not ClassTrainerFrame or ClassTrainerFrame._dfTrainerSkinned then return end
        ClassTrainerFrame._dfTrainerSkinned = true

        -- 1. 隐藏 vanilla ClassTrainer 专属背景纹理（精准按纹理名，避开头像 ClassTrainerFramePortrait 等动态 region）
        local regions = {ClassTrainerFrame:GetRegions()}
        for i = 1, table.getn(regions) do
            local region = regions[i]
            if region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                if texture and string.find(texture, "ClassTrainer") then
                    region:Hide()
                end
            end
        end
        if ClassTrainerFrameCloseButton then ClassTrainerFrameCloseButton:Hide() end

        -- 2. DF 金属外框（CreatePaperDollFrame frameStyle=1）
        --    锚点对齐 SkinQuestStyleFrame 标准(闲聊/社交等)：TOPLEFT(12,-12) / 右边距 -32，
        --    使训练师框宽与其它 384 宽面板一致(ClassTrainerFrame 同为 vanilla 384)；底距保持 60 不动底部按钮布局。
        local customBg = DFUI.CreatePaperDollFrame("DFUI_TrainerBg", ClassTrainerFrame, 384, 512, 1)
        customBg:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 12, -12)
        customBg:SetPoint("BOTTOMRIGHT", ClassTrainerFrame, "BOTTOMRIGHT", -32, 60)
        customBg:SetFrameLevel(ClassTrainerFrame:GetFrameLevel() - 1)

        -- 3. NPC 元素（对齐闲聊/接任务 SkinQuestStyleFrame 风格）：头像 reparent 进金属头像孔 + NPC 名居中金色
        DFUI.AttachPortrait(customBg, ClassTrainerFramePortrait)
        if ClassTrainerNameText then
            ClassTrainerNameText:SetParent(customBg)
            ClassTrainerNameText:SetDrawLayer("OVERLAY", 1)
            ClassTrainerNameText:ClearAllPoints()
            ClassTrainerNameText:SetPoint("TOP", customBg, "TOP", 0, -6)
            if ClassTrainerNameText.SetTextColor then ClassTrainerNameText:SetTextColor(1, 0.82, 0) end
        end
        -- 问候语跟随 NPC 名下方居中限宽（去木纹后否则停 vanilla 旧位置会穿进凹陷区）
        if ClassTrainerGreetingText then
            ClassTrainerGreetingText:SetParent(customBg)
            ClassTrainerGreetingText:SetDrawLayer("OVERLAY", 1)
            ClassTrainerGreetingText:ClearAllPoints()
            ClassTrainerGreetingText:SetPoint("TOP", ClassTrainerNameText, "BOTTOM", 0, -4)
            if ClassTrainerGreetingText.SetWidth then ClassTrainerGreetingText:SetWidth(customBg:GetWidth() - 80) end
            if ClassTrainerGreetingText.SetJustifyH then ClassTrainerGreetingText:SetJustifyH("CENTER") end
        end

        -- 5. 凹陷区（CreateRetailInset）—— 上=技能列表区(marble 填充), 下=详情区(不填充)。
        --    parent=customBg + levelOffset=0 → inset.level = customBg.level(=ClassTrainerFrame-1) < 列表行/详情(挂 ClassTrainerFrame)，凹陷底沉底。
        --    左/顶/底跟 vanilla ScrollFrame(自适应真实列表/详情)，右缘锚 customBg 内沿铺满。
        local listInset = DFUI.CreateRetailInset(customBg, {
            name = "DFUI_TrainerListInset", levelOffset = 0,   -- 用工厂默认 marble 底填充(不再覆盖成岩石)
        })
        listInset:ClearAllPoints()
        listInset:SetPoint("TOPLEFT", ClassTrainerListScrollFrame, "TOPLEFT", -4, 4)
        listInset:SetPoint("BOTTOM",  ClassTrainerListScrollFrame, "BOTTOM", 0, -4)
        listInset:SetPoint("RIGHT",   customBg, "RIGHT", -9, 0)  -- 右铺满到金属框内沿(列表靠左,右侧 marble 填满)
        listInset:Show()

        local detailInset = DFUI.CreateRetailInset(customBg, {
            name = "DFUI_TrainerDetailInset", levelOffset = 0,
        })
        detailInset:ClearAllPoints()
        detailInset:SetPoint("TOPLEFT", ClassTrainerDetailScrollFrame, "TOPLEFT", -4, 4)
        detailInset:SetPoint("BOTTOM",  ClassTrainerDetailScrollFrame, "BOTTOM", 0, -4)
        detailInset:SetPoint("RIGHT",   customBg, "RIGHT", -9, 0)
        detailInset.bg:Hide()   -- 下面详情区不填充(只留凹陷边框，不铺 marble)
        detailInset:Show()

        -- 6. 按钮重定位 + DF 红色关闭按钮
        if ClassTrainerTrainButton then
            ClassTrainerTrainButton:ClearAllPoints()
            ClassTrainerTrainButton:SetPoint("BOTTOMRIGHT", customBg, "BOTTOMRIGHT", -90, 5)
        end
        if ClassTrainerCancelButton then
            ClassTrainerCancelButton:ClearAllPoints()
            ClassTrainerCancelButton:SetPoint("BOTTOMRIGHT", customBg, "BOTTOMRIGHT", -10, 5)
        end
        if ClassTrainerMoneyFrame then
            ClassTrainerMoneyFrame:ClearAllPoints()
            ClassTrainerMoneyFrame:SetPoint("RIGHT", ClassTrainerTrainButton, "LEFT", -10, 1)
        end

        local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(ClassTrainerFrame) end)
        closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

        -- 7. 滚动条改 DF minimal 滑块（遥控 vanilla scrollbar；列表=FauxScrollFrame, 详情=ScrollFrame）
        StripRegionTextures(ClassTrainerListScrollFrame)
        StripRegionTextures(ClassTrainerDetailScrollFrame)

        local listSB, detailSB
        if ClassTrainerListScrollFrame and ClassTrainerListScrollFrameScrollBar then
            KeepArrowsHideTrack("ClassTrainerListScrollFrameScrollBar")
            HookScript(ClassTrainerListScrollFrameScrollBar, "OnShow", function()
                KeepArrowsHideTrack("ClassTrainerListScrollFrameScrollBar")
            end)
            listSB = DFUI.CreateMinimalScrollbar(ClassTrainerListScrollFrame, ClassTrainerListScrollFrameScrollBar, {
                xOffset = 2, scale = 0.8, arrowTopPad = 0, arrowBotPad = 0, topInset = 4, botInset = 4, gap = 7,
                onScrollDelta = function(d)
                    local m = math.max(0, GetNumTrainerServices() - CLASS_TRAINER_SKILLS_DISPLAYED)
                    setFauxOffset(ClassTrainerListScrollFrameScrollBar, fauxOffsetOf(ClassTrainerListScrollFrameScrollBar, m) + d, m)
                end,
                onScrollAbs = function(r)
                    local m = math.max(0, GetNumTrainerServices() - CLASS_TRAINER_SKILLS_DISPLAYED)
                    setFauxOffset(ClassTrainerListScrollFrameScrollBar, math.floor(r * m + 0.5), m)
                end,
            })
        end

        if ClassTrainerDetailScrollFrame and ClassTrainerDetailScrollFrameScrollBar then
            KeepArrowsHideTrack("ClassTrainerDetailScrollFrameScrollBar")
            HookScript(ClassTrainerDetailScrollFrameScrollBar, "OnShow", function()
                KeepArrowsHideTrack("ClassTrainerDetailScrollFrameScrollBar")
            end)
            local function setDetailScroll(v)
                local sf = ClassTrainerDetailScrollFrame
                local range = sf:GetVerticalScrollRange()
                if v < 0 then v = 0 elseif v > range then v = range end
                sf:SetVerticalScroll(v)
            end
            detailSB = DFUI.CreateMinimalScrollbar(ClassTrainerDetailScrollFrame, ClassTrainerDetailScrollFrameScrollBar, {
                xOffset = 2, scale = 0.8, arrowTopPad = 0, arrowBotPad = 0, topInset = 4, botInset = 4, gap = 7,
                onScrollDelta = function(d)
                    setDetailScroll(ClassTrainerDetailScrollFrame:GetVerticalScroll() + d * 24)
                end,
                onScrollAbs = function(r)
                    setDetailScroll(r * ClassTrainerDetailScrollFrame:GetVerticalScrollRange())
                end,
            })
        end

        -- 技能列表对齐：用户实测 header 行(如"武器")+技能行(如"冲锋")的"名字"偏右、离 +/− 折叠按钮太远。
        -- 把每行名字 FontString 的左缘重锚到「行左缘 + NAME_GUTTER_X」，对齐到边框内容左侧。
        -- ⚠ 只重锚名字 FontString，绝不动行 button / +/− 折叠按钮(它锚点本来是对的)。
        -- 绝对锚=天然幂等(每次设同一位置)，挂 OnShow + 0.1s OnUpdate 防 Turtle 刷新复位。
        local function ShiftRow(btn)
            if not btn or not btn:IsVisible() then return end      -- 行有数据才处理
            local regions = {btn:GetRegions()}
            for i = 1, table.getn(regions) do
                local r = regions[i]
                if r.GetObjectType and r:GetObjectType() == "FontString" then
                    r:ClearAllPoints()
                    r:SetPoint("LEFT", btn, "LEFT", NAME_GUTTER_X, 0)  -- 左对齐行左缘+留白，竖直居中
                end
            end
        end
        local function ShiftAllRows()
            for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
                ShiftRow(getglobal("ClassTrainerSkill" .. i))
            end
        end

        -- thumb 同步：独立节流 OnUpdate(0.1s)，读 vanilla 状态反推，不碰任何 update 链路
        if listSB or detailSB then
            local syncT = 0
            CreateFrame("Frame"):SetScript("OnUpdate", function()
                syncT = syncT + (arg1 or 0)
                if syncT < 0.1 then return end
                syncT = 0
                if not ClassTrainerFrame:IsVisible() then return end
                ShiftAllRows()
                if listSB then
                    local total = GetNumTrainerServices()
                    local m = math.max(0, total - CLASS_TRAINER_SKILLS_DISPLAYED)
                    if m <= 0 then
                        listSB:Hide()
                    else
                        listSB:Show()
                        listSB.UpdateThumb(fauxOffsetOf(ClassTrainerListScrollFrameScrollBar, m), m, CLASS_TRAINER_SKILLS_DISPLAYED, total)
                    end
                end
                if detailSB then
                    local sf = ClassTrainerDetailScrollFrame
                    local range = sf:GetVerticalScrollRange()
                    if range <= 0 then
                        detailSB:Hide()
                    else
                        detailSB:Show()
                        local t, b = sf:GetTop(), sf:GetBottom()
                        local vis = (t and b and (t - b) > 0) and (t - b) or sf:GetHeight()
                        detailSB.UpdateThumb(sf:GetVerticalScroll(), range, vis, vis + range)
                    end
                end
            end)
        end

        -- 8. 列表行换皮（hover/选中高亮；不改行数/位置/category 着色）
        for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
            SkinRow(getglobal("ClassTrainerSkill" .. i))
        end

        -- 9. 详情区换皮：图标加 DF 边框 + 标题转金（不 reparent，保留 ScrollFrame 滚动）
        if ClassTrainerSkillIcon and not ClassTrainerSkillIcon._dfBorder then
            local b = ClassTrainerSkillIcon:CreateTexture(nil, "OVERLAY")
            b:SetTexture(SLOT)
            b:SetTexCoord(12/64, 51/64, 12/64, 51/64)
            b:SetPoint("TOPLEFT", ClassTrainerSkillIcon, "TOPLEFT", -4, 4)
            b:SetPoint("BOTTOMRIGHT", ClassTrainerSkillIcon, "BOTTOMRIGHT", 4, -4)
            ClassTrainerSkillIcon._dfBorder = b
        end
        if ClassTrainerSkillName and ClassTrainerSkillName.SetTextColor then
            ClassTrainerSkillName:SetTextColor(DF_GOLD[1], DF_GOLD[2], DF_GOLD[3])
        end

        CenterFrame(ClassTrainerFrame)
        HookScript(ClassTrainerFrame, "OnShow", function()
            customBg:Show()
            ShiftAllRows()
        end)
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function()
        if arg1 == "Blizzard_TrainerUI" then
            SkinClassTrainerFrame()
        end
    end)

    if ClassTrainerFrame then
        SkinClassTrainerFrame()
    end

    -- 诊断：开训练师面板后 /trdump [行号]，dump 该行(默认1)的真实结构——
    --   regions(FontString 名字/Texture) 各自 类型/文字/锚点/左缘 + 子 frame(如 +/− 折叠按钮) 左缘，
    --   用来精确量"名字 vs +/−"间距、确认名字是不是 button 的 FontString region。
    -- ⚠ setfenv 模块必须用 _G 注册斜杠命令(裸写 SLASH_xxx 落 DFUI env 表→_G 读不到→命令失效)，照 trainerdata.lua 范式
    _G.SLASH_DFTRDUMP1 = "/trdump"
    _G.SlashCmdList["DFTRDUMP"] = function(msg)
        local function p(s) DEFAULT_CHAT_FRAME:AddMessage(s) end
        local function n(v) return v and string.format("%.0f", v) or "?" end
        local function pt(o)
            if not o or not o.GetPoint then return "-" end
            local a, rel, rp, x, y = o:GetPoint(1)
            if not a then return "no-point" end
            local rn = (rel and rel.GetName and rel:GetName()) or "parent"
            return a .. ">" .. tostring(rn) .. "." .. tostring(rp) .. "(" .. n(x) .. "," .. n(y) .. ")"
        end
        local idx = tonumber(msg) or 1
        local btn = getglobal("ClassTrainerSkill" .. idx)
        if not btn then p("ClassTrainerSkill" .. idx .. " 不存在(先开训练师面板)"); return end
        p("== ClassTrainerSkill" .. idx .. " vis=" .. tostring(btn:IsVisible())
          .. " L=" .. n(btn:GetLeft()) .. " w=" .. n(btn:GetWidth())
          .. " 锚=" .. pt(btn) .. " text=" .. tostring(btn.GetText and btn:GetText()) .. " ==")
        local rs = {btn:GetRegions()}
        for i = 1, table.getn(rs) do
            local r = rs[i]
            local ot = (r.GetObjectType and r:GetObjectType()) or "?"
            local extra = ""
            if ot == "FontString" and r.GetText then extra = " '" .. tostring(r:GetText()) .. "'"
            elseif ot == "Texture" and r.GetTexture then extra = " " .. tostring(r:GetTexture()) end
            p("  reg[" .. i .. "] " .. ot .. " L=" .. n(r:GetLeft()) .. " " .. pt(r) .. extra)
        end
        local ks = {btn:GetChildren()}
        for i = 1, table.getn(ks) do
            local c = ks[i]
            p("  kid[" .. i .. "] " .. ((c.GetObjectType and c:GetObjectType()) or "?")
              .. " " .. tostring((c.GetName and c:GetName()) or "?")
              .. " L=" .. n(c:GetLeft()) .. " " .. pt(c))
        end
    end

    local callbacks = {}
    DFUI:NewCallbacks("Trainer", callbacks)
end)
