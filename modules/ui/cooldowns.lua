-- ═══════════════════════════════════════════════════════════════
-- 冷却时间数字显示模块
-- 在技能/物品冷却时显示倒计时数字
-- ═══════════════════════════════════════════════════════════════

DFRL:NewDefaults("Cooldowns", {
    enabled = {true},
    showText = {true, "checkbox", nil, nil, "通用", 1, "显示冷却数字", nil, nil},
    fontSize = {14, "slider", {8, 32}, nil, "通用", 2, "字号", nil, nil},
    minDuration = {1.5, "slider", {0, 5, 0.5}, nil, "通用", 3, "最小显示时长(秒)", nil, nil},
})

DFRL:NewMod("Cooldowns", 5, function()
    local setup = DFRL.tempDB.Cooldowns
    if not setup.showText then return end

    -- 所有已创建的冷却文字帧，用于回调统一控制
    local allCooldownTexts = {}

    -- 颜色阈值：根据剩余时间着色
    local function GetColor(remaining)
        if remaining < 10 then
            return 1, 0.1, 0.1      -- <10秒: 红色
        elseif remaining < 60 then
            return 1, 0.82, 0         -- <1分钟: 黄色
        elseif remaining < 300 then
            return 0.4, 1, 0.1        -- <5分钟: 绿色
        else
            return 0.6, 0.6, 0.6      -- 5分钟+: 灰色
        end
    end

    -- 格式化剩余时间为简短字符串
    local function FormatTime(seconds)
        if seconds >= 86400 then
            return string.format('%dd', seconds / 86400)
        elseif seconds >= 3600 then
            return string.format('%dh', seconds / 3600)
        elseif seconds >= 60 then
            return string.format('%dm', seconds / 60)
        elseif seconds < 1 then
            return string.format('%.1f', seconds)
        else
            return string.format('%d', seconds)
        end
    end

    -- OnUpdate 处理函数：每 0.1 秒更新一次冷却文字
    local function OnUpdate()
        if (this.tick or 0.1) > GetTime() then return end
        this.tick = GetTime() + 0.1

        -- 检查父级冷却帧是否仍在显示
        local parent = this:GetParent()
        if parent then
            local parentName = parent:GetName()
            if parentName and _G[parentName .. "Cooldown"] then
                if not _G[parentName .. "Cooldown"]:IsShown() then
                    this:Hide()
                    return
                end
            end
        end

        local remaining = this.duration - (GetTime() - this.start)
        if remaining >= 0 then
            local font = this.text:GetFont()
            if not font then
                this.text:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
            end
            this.text:SetText(FormatTime(remaining))
            local r, g, b = GetColor(remaining)
            this.text:SetTextColor(r, g, b)
        else
            this:Hide()
        end
    end

    -- 创建冷却文字帧（挂在冷却帧的父级上，避免被冷却动画遮挡）
    local function CreateCooldownText(cooldown)
        local frame = CreateFrame('Frame', nil, cooldown:GetParent())
        frame:SetAllPoints(cooldown)
        frame:SetFrameLevel(cooldown:GetParent():GetFrameLevel() + 2)
        frame.text = frame:CreateFontString(nil, 'OVERLAY')
        frame.text:SetFont('Fonts\\FRIZQT__.TTF', setup.fontSize or 14, 'OUTLINE')
        frame.text:SetPoint('CENTER', 0, 0)
        frame:SetScript('OnUpdate', OnUpdate)
        table.insert(allCooldownTexts, frame)
        return frame
    end

    -- Hook CooldownFrame_SetTimer：所有冷却动画触发时调用
    hooksecurefunc('CooldownFrame_SetTimer', function(cooldownFrame, start, duration, enable)
        -- 缩放冷却帧适配父级大小
        local parent = cooldownFrame.GetParent and cooldownFrame:GetParent()
        if parent and parent:GetWidth() / 36 > 0 then
            cooldownFrame:SetScale(parent:GetWidth() / 36)
            cooldownFrame:SetPoint('TOPLEFT', parent, 'TOPLEFT', -1, 1)
            cooldownFrame:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 1, -1)
        end

        if not setup.showText then
            if cooldownFrame.cdText then cooldownFrame.cdText:Hide() end
            return
        end

        local minDur = setup.minDuration or 1.5
        if start == 0 or duration == 0 or duration < minDur then
            if cooldownFrame.cdText then cooldownFrame.cdText:Hide() end
            return
        end

        if not cooldownFrame.cdText then
            cooldownFrame.cdText = CreateCooldownText(cooldownFrame)
        end
        cooldownFrame.cdText.start = start
        cooldownFrame.cdText.duration = duration
        cooldownFrame.cdText:Show()
    end)

    -- 回调：showText 切换时控制显示/隐藏
    local callbacks = {}
    callbacks.showText = function(value)
        for _, frame in pairs(allCooldownTexts) do
            if value then
                if frame.start and frame.duration then frame:Show() end
            else
                frame:Hide()
            end
        end
    end

    callbacks.fontSize = function(value)
        for _, frame in pairs(allCooldownTexts) do
            frame.text:SetFont('Fonts\\FRIZQT__.TTF', value, 'OUTLINE')
        end
    end

    callbacks.minDuration = function() end

    DFRL:NewCallbacks("Cooldowns", callbacks)
end)
