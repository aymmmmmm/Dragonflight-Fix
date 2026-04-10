-- scrollbar.lua — 全局滚动条 & 箭头换肤
-- 风格：铸铁/青铜色调，匹配 Fix 的金属边框和岩石背景

setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Scrollbar", {
    enabled = {true, "checkbox", nil, nil, "面板美化", 18, "滚动条换肤", nil, nil},
})

DFUI:NewMod("Scrollbar", 6, function()
    local setup = DFUI.tempDB.Scrollbar
    if not setup.enabled then return end

    local WHITE8X8 = "Interface\\Buttons\\WHITE8X8"

    -- 色值体系：与 Fix 金属边框/岩石背景融合
    local BRONZE        = {0.45, 0.38, 0.28}  -- 青铜色（箭头/滑块正常态）
    local BRONZE_LIGHT  = {0.55, 0.47, 0.35}  -- 亮青铜（悬停/按下态）
    local BRONZE_DIM    = {0.25, 0.22, 0.16}  -- 暗青铜（禁用态）
    local TRACK_BG      = {0.06, 0.06, 0.06}  -- 轨道背景（近黑）
    local BORDER_WARM   = {0.35, 0.32, 0.28}  -- 暖棕边框（与称号下拉框一致）

    local trackBackdrop = {
        bgFile = WHITE8X8,
        edgeFile = WHITE8X8,
        edgeSize = 1,
    }

    -------------------------------------------------------
    -- 箭头按钮换肤
    -- 替换为 ChatIcon 下拉箭头纹理 + 青铜着色
    -------------------------------------------------------
    local ARROW_NORMAL   = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up"
    local ARROW_PUSHED   = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down"
    local ARROW_DISABLED = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled"
    local ARROW_HILIGHT  = "Interface\\Buttons\\UI-Common-MouseHilight"

    local function SkinArrowButton(button, direction)
        if not button or button._dfScrollSkinned then return end
        button._dfScrollSkinned = true

        button:SetWidth(24)
        button:SetHeight(24)

        -- 翻转坐标：up 箭头垂直翻转，down 箭头正常
        local L, R, T, B
        if direction == "up" then
            L, R, T, B = 0, 1, 1, 0
        else
            L, R, T, B = 0, 1, 0, 1
        end

        -- 替换纹理
        button:SetNormalTexture(ARROW_NORMAL)
        button:SetPushedTexture(ARROW_PUSHED)
        button:SetHighlightTexture(ARROW_HILIGHT)
        if button.SetDisabledTexture then
            button:SetDisabledTexture(ARROW_DISABLED)
        end

        -- 设置 TexCoord 和着色
        local normal = button:GetNormalTexture()
        local pushed = button:GetPushedTexture()
        local disabled = button:GetDisabledTexture()
        local highlight = button:GetHighlightTexture()

        if normal then
            normal:SetTexCoord(L, R, T, B)
        end
        if pushed then
            pushed:SetTexCoord(L, R, T, B)
        end
        if disabled then
            disabled:SetTexCoord(L, R, T, B)
        end
        if highlight then
            highlight:SetTexCoord(L, R, T, B)
        end
    end

    -------------------------------------------------------
    -- 滚动条换肤 (主函数)
    -------------------------------------------------------
    function DFUI.SkinScrollbar(scrollbar)
        if not scrollbar or scrollbar._dfScrollSkinned then return end
        scrollbar._dfScrollSkinned = true

        local name = scrollbar:GetName()
        if not name then return end

        local up = _G[name .. "ScrollUpButton"]
        local down = _G[name .. "ScrollDownButton"]
        local thumb = scrollbar:GetThumbTexture()

        -- 换肤箭头按钮（轨道和滑块保留暴雪原生样式）
        SkinArrowButton(up, "up")
        SkinArrowButton(down, "down")
    end

    -------------------------------------------------------
    -- 下拉框换肤
    -- 箭头保留原样（已由 BCS 等处理），只美化背景
    -------------------------------------------------------
    function DFUI.SkinDropDown(dropdown)
        if not dropdown or dropdown._dfScrollSkinned then return end
        dropdown._dfScrollSkinned = true

        local ddName = dropdown:GetName()

        -- 隐藏暴雪下拉框背景 (Left/Middle/Right)
        local left = ddName and _G[ddName .. "Left"]
        local middle = ddName and _G[ddName .. "Middle"]
        local right = ddName and _G[ddName .. "Right"]
        if left then left:Hide() end
        if middle then middle:Hide() end
        if right then right:Hide() end

        -- 暗色背景框（与称号下拉框一致的风格）
        local bg = CreateFrame("Frame", nil, dropdown)
        bg:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 16, 0)
        bg:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -16, 4)
        bg:SetFrameLevel(dropdown:GetFrameLevel())
        bg:SetBackdrop({
            bgFile = WHITE8X8,
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = {left = 2, right = 2, top = 2, bottom = 2},
        })
        bg:SetBackdropColor(0.06, 0.06, 0.06, 0.85)
        bg:SetBackdropBorderColor(BORDER_WARM[1], BORDER_WARM[2], BORDER_WARM[3], 0.7)
        dropdown._dfBg = bg
    end

    -------------------------------------------------------
    -- 翻页箭头换肤（金色着色原有纹理）
    -------------------------------------------------------
    function DFUI.SkinPageButton(button)
        if not button or button._dfScrollSkinned then return end
        button._dfScrollSkinned = true

        local normal = button:GetNormalTexture()
        local pushed = button:GetPushedTexture()
        local disabled = button:GetDisabledTexture()
        local highlight = button:GetHighlightTexture()

        if normal then normal:SetVertexColor(BRONZE_LIGHT[1], BRONZE_LIGHT[2], BRONZE_LIGHT[3], 0.9) end
        if pushed then pushed:SetVertexColor(BRONZE[1], BRONZE[2], BRONZE[3], 1.0) end
        if disabled then disabled:SetVertexColor(BRONZE_DIM[1], BRONZE_DIM[2], BRONZE_DIM[3], 0.5) end
        if highlight then highlight:SetVertexColor(BRONZE_LIGHT[1], BRONZE_LIGHT[2], BRONZE_LIGHT[3], 0.4) end
    end

    -------------------------------------------------------
    -- 批量应用目标列表
    -------------------------------------------------------
    local scrollbarTargets = {
        -- 角色面板
        "SkillListScrollFrameScrollBar",
        "ReputationListScrollFrameScrollBar",
        -- 任务日志
        "QuestLogListScrollFrameScrollBar",
        "QuestLogDetailScrollFrameScrollBar",
        -- 任务对话
        "QuestDetailScrollFrameScrollBar",
        "QuestRewardScrollFrameScrollBar",
        "QuestProgressScrollFrameScrollBar",
        "QuestGreetingScrollFrameScrollBar",
        -- NPC 对话
        "GossipGreetingScrollFrameScrollBar",
        -- 社交
        "FriendsFrameFriendsScrollFrameScrollBar",
        "FriendsFrameIgnoreScrollFrameScrollBar",
        "WhoListScrollFrameScrollBar",
        "GuildListScrollFrameScrollBar",
        "GuildInfoFrameScrollFrameScrollBar",
        "ChannelListScrollFrameScrollBar",
        "ChannelRosterScrollFrameScrollBar",
        -- 训练师
        "ClassTrainerListScrollFrameScrollBar",
        "ClassTrainerDetailScrollFrameScrollBar",
        -- 邮件
        "SendMailScrollFrameScrollBar",
        "OpenMailScrollFrameScrollBar",
        -- 帮助
        "HelpFrameOpenTicketScrollFrameScrollBar",
        -- 团队
        "RaidInfoScrollFrameScrollBar",
    }

    local dropdownTargets = {
        "PlayerStatFrameLeftDropDown",
        "PlayerStatFrameRightDropDown",
        "WhoFrameDropDown",
        "ClassTrainerFrameFilterDropDown",
    }

    local pageButtonTargets = {
        "MerchantPrevPageButton",
        "MerchantNextPageButton",
        "InboxPrevPageButton",
        "InboxNextPageButton",
    }

    -------------------------------------------------------
    -- 延迟应用
    -------------------------------------------------------
    local function ApplyAll()
        for _, sbName in ipairs(scrollbarTargets) do
            local frame = _G[sbName]
            if frame then DFUI.SkinScrollbar(frame) end
        end
        for _, ddName in ipairs(dropdownTargets) do
            local frame = _G[ddName]
            if frame then DFUI.SkinDropDown(frame) end
        end
        for _, pbName in ipairs(pageButtonTargets) do
            local frame = _G[pbName]
            if frame then DFUI.SkinPageButton(frame) end
        end
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")
        local elapsed = 0
        f:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            if elapsed < 0.5 then return end
            f:SetScript("OnUpdate", nil)
            ApplyAll()
        end)
    end)

    local addonFrame = CreateFrame("Frame")
    addonFrame:RegisterEvent("ADDON_LOADED")
    addonFrame:SetScript("OnEvent", function()
        local elapsed2 = 0
        local retry = CreateFrame("Frame")
        retry:SetScript("OnUpdate", function()
            elapsed2 = elapsed2 + arg1
            if elapsed2 < 0.2 then return end
            retry:SetScript("OnUpdate", nil)
            ApplyAll()
        end)
    end)
end)
