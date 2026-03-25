DFRL:NewDefaults("Chat", {
    enabled = {true},
    showButtons = {true, "checkbox", nil, nil, "外观", 1, "显示或隐藏聊天按钮", "BUG: 暴雪高亮在错误位置闪烁 - 即将修复", nil},
    chatDarkMode = {0, "slider", {0, 1}, "showButtons", "外观", 2, "调整深色模式强度", nil, nil},
    chatColor = {{1, 1, 1}, "colour", nil, "showButtons", "外观", 3, "更改聊天颜色", nil, nil},
    blizzardButtons = {false, "checkbox", nil, "showButtons", "聊天基础", 4, "使用暴雪原版聊天按钮", nil, nil},
    fadeChat = {false, "checkbox", nil, nil, "聊天基础", 5, "10秒后淡出聊天文字", nil, nil},
    chatTimestamps = {false, "checkbox", nil, nil, "聊天增强", 1, "显示时间戳", nil, nil},
    chatTimestampColor = {{0.41, 0.8, 0.94}, "colour", nil, "chatTimestamps", "聊天增强", 2, "时间戳颜色", nil, nil},
    chatURLDetect = {true, "checkbox", nil, nil, "聊天增强", 3, "URL检测(可点击链接)", nil, nil},
    chatURLColor = {{1, 0.3, 0.3}, "colour", nil, "chatURLDetect", "聊天增强", 4, "URL链接颜色", nil, nil},
    chatAbbreviate = {false, "checkbox", nil, nil, "聊天增强", 5, "频道名缩写(G/P/R等)", nil, nil},
})

DFRL:NewMod("Chat", 1, function()
    local Setup = {
        tex = DFRL:GetInfoOrCons("tex"),
    }

    function Setup:ChatFrame()
        ChatFrame1Tab:SetClampedToScreen(true)
    end

    Setup:ChatFrame()

    -- 对按钮的 normal/pushed 纹理统一着色
    local function ColorButtonTextures(button, r, g, b)
        if not button then return end
        local normal = button:GetNormalTexture()
        if normal then normal:SetVertexColor(r, g, b) end
        local pushed = button:GetPushedTexture()
        if pushed then pushed:SetVertexColor(r, g, b) end
    end

    -- 统一着色所有聊天 UI 元素（标签页 + 按钮）
    local function ApplyChatButtonColor(r, g, b)
        for i = 1, 5 do
            local tabLeft = _G["ChatFrame"..i.."TabLeft"]
            local tabMiddle = _G["ChatFrame"..i.."TabMiddle"]
            local tabRight = _G["ChatFrame"..i.."TabRight"]
            if tabLeft then tabLeft:SetVertexColor(r, g, b) end
            if tabMiddle then tabMiddle:SetVertexColor(r, g, b) end
            if tabRight then tabRight:SetVertexColor(r, g, b) end

            ColorButtonTextures(_G["ChatFrame"..i.."UpButton"], r, g, b)
            ColorButtonTextures(_G["ChatFrame"..i.."DownButton"], r, g, b)
            ColorButtonTextures(_G["ChatFrame"..i.."BottomButton"], r, g, b)
        end
        ColorButtonTextures(ChatFrameMenuButton, r, g, b)
    end

    local callbacks = {}

    callbacks.chatDarkMode = function(value)
        local intensity = DFRL:GetTempDB("Chat", "chatDarkMode")
        local chatColor = DFRL:GetTempDB("Chat", "chatColor")
        local r, g, b = chatColor[1] * (1 - intensity), chatColor[2] * (1 - intensity), chatColor[3] * (1 - intensity)
        if not value then r, g, b = 1, 1, 1 end
        ApplyChatButtonColor(r, g, b)
    end

    callbacks.chatColor = function(value)
        local intensity = DFRL:GetTempDB("Chat", "chatDarkMode")
        local r, g, b = value[1] * (1 - intensity), value[2] * (1 - intensity), value[3] * (1 - intensity)
        ApplyChatButtonColor(r, g, b)
    end

    callbacks.showButtons = function(value)
        if ChatFrameMenuButton then
            if value then
                ChatFrameMenuButton:Show()
            else
                ChatFrameMenuButton:Hide()
            end
        end

        for i = 1, 5 do
            local upButton = _G["ChatFrame"..i.."UpButton"]
            local downButton = _G["ChatFrame"..i.."DownButton"]
            local bottomButton = _G["ChatFrame"..i.."BottomButton"]

            if upButton then
                if value then
                    upButton:Show()
                else
                    upButton:Hide()
                end
            end

            if downButton then
                if value then
                    downButton:Show()
                else
                    downButton:Hide()
                end
            end

            if bottomButton then
                if value then
                    bottomButton:Show()
                else
                    bottomButton:Hide()
                end
            end
        end
    end

    callbacks.blizzardButtons = function(value)
        local buttonScale = 0.8

        if value then
            if ChatFrameMenuButton then
                ChatFrameMenuButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Up")
                ChatFrameMenuButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                ChatFrameMenuButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Down")
                ChatFrameMenuButton:SetScale(buttonScale)
            end

            for i = 1, 5 do
                local upButton = _G["ChatFrame"..i.."UpButton"]
                local downButton = _G["ChatFrame"..i.."DownButton"]
                local bottomButton = _G["ChatFrame"..i.."BottomButton"]

                if upButton then
                    upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
                    upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                    upButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
                    upButton:SetScale(buttonScale)
                end

                if downButton then
                    downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
                    downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                    downButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
                    downButton:SetScale(buttonScale)
                end

                if bottomButton then
                    bottomButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollEnd-Up")
                    bottomButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                    bottomButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollEnd-Down")
                    bottomButton:SetScale(buttonScale)
                end
            end
        else
            local menuTexture = Setup.tex.."chat\\chat_menu"
            local upTexture = Setup.tex .. "chat\\chat_up"
            local downTexture = Setup.tex .. "chat\\chat_down"
            local downFullTexture = Setup.tex .. "chat\\chat_down_full"

            if ChatFrameMenuButton then
                ChatFrameMenuButton:SetNormalTexture(menuTexture)
                ChatFrameMenuButton:SetHighlightTexture(menuTexture)
                ChatFrameMenuButton:SetPushedTexture(menuTexture)
                ChatFrameMenuButton:SetScale(buttonScale)
            end

            for i = 1, 5 do
                local upButton = _G["ChatFrame"..i.."UpButton"]
                local downButton = _G["ChatFrame"..i.."DownButton"]
                local bottomButton = _G["ChatFrame"..i.."BottomButton"]

                if upButton then
                    upButton:SetNormalTexture(upTexture)
                    upButton:SetHighlightTexture(upTexture)
                    upButton:SetPushedTexture(upTexture)
                    upButton:SetScale(buttonScale)
                end

                if downButton then
                    downButton:SetNormalTexture(downTexture)
                    downButton:SetHighlightTexture(downTexture)
                    downButton:SetPushedTexture(downTexture)
                    downButton:SetScale(buttonScale)
                end

                if bottomButton then
                    bottomButton:SetNormalTexture(downFullTexture)
                    bottomButton:SetHighlightTexture(downFullTexture)
                    bottomButton:SetPushedTexture(downFullTexture)
                    bottomButton:SetScale(buttonScale)
                end
            end
        end

        callbacks.chatDarkMode(DFRL:GetTempDB("Chat", "chatDarkMode"))
    end

    callbacks.fadeChat = function(value)
        for i = 1, NUM_CHAT_WINDOWS do
            local f = _G["ChatFrame"..i]
            if value then
                f:SetFadeDuration(0.1)
                f:SetTimeVisible(10)
            else
                f:SetFadeDuration(3)
                f:SetTimeVisible(180)
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- 聊天增强功能：URL检测、时间戳、频道缩写
    -- ═══════════════════════════════════════════════════════════════

    local chatSetup = DFRL.tempDB.Chat

    -- AddMessage Hook 系统：过滤器链
    local chatFilters = {}
    local origAddMessages = {}

    local function RebuildAddMessageHooks()
        for i = 1, NUM_CHAT_WINDOWS do
            local frame = _G['ChatFrame' .. i]
            if frame then
                if not origAddMessages[frame] then
                    origAddMessages[frame] = frame.AddMessage
                end
                frame.AddMessage = function(self, text, r, g, b, id, hold)
                    if text then
                        for _, func in pairs(chatFilters) do
                            text = func(text) or text
                        end
                    end
                    origAddMessages[self](self, text, r, g, b, id, hold)
                end
            end
        end
    end

    -- URL 检测引擎（移植自 DF3）
    local urlPatterns = {
        {rx = ' (www%d-)%.([_A-Za-z0-9-]+)%.(%S+)%s?', fm = '%s.%s.%s'},
        {rx = ' (%a+)://(%S+)%s?', fm = '%s://%s'},
        {rx = ' ([_A-Za-z0-9-%.:]+)@([_A-Za-z0-9-]+)(%.)([_A-Za-z0-9-]+%.?[_A-Za-z0-9-]*)%s?', fm = '%s@%s%s%s'},
        {rx = ' (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?', fm = '%s.%s.%s.%s:%s'},
        {rx = ' (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?', fm = '%s.%s.%s.%s'},
        {rx = ' (%a+)%.(%a+)/(%S+)%s?', fm = '%s.%s/%s'},
        {rx = ' ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%:([_0-9-]+)%s?', fm = '%s.%s.%s:%s'},
        {rx = ' ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%s?', fm = '%s.%s.%s'},
    }

    local function FormatURLLink(fmt, ...)
        if not fmt then return end
        local url = string.format(fmt, unpack(arg))
        local urlColor = chatSetup.chatURLColor or {1, 0.3, 0.3}
        local hex = string.format('|cff%02x%02x%02x', urlColor[1] * 255, urlColor[2] * 255, urlColor[3] * 255)
        return ' ' .. hex .. '|Hurl:' .. url .. '|h[' .. url .. ']|h|r '
    end

    local function HandleURLs(text)
        for _, pat in ipairs(urlPatterns) do
            text = string.gsub(text, pat.rx, function(a1, a2, a3, a4, a5)
                return FormatURLLink(pat.fm, a1, a2, a3, a4, a5)
            end)
        end
        return text
    end

    -- SetItemRef Hook：处理 url: 链接点击
    local origSetItemRef = _G.SetItemRef
    _G.SetItemRef = function(link, text, button)
        if string.sub(link, 1, 4) == 'url:' then
            local url = string.sub(link, 5)
            -- 创建复制弹窗
            if not DFRL_URLCopyDialog then
                local f = CreateFrame('Frame', 'DFRL_URLCopyDialog', UIParent)
                f:SetWidth(350)
                f:SetHeight(80)
                f:SetPoint('CENTER')
                f:SetBackdrop({bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background', edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border', tile = true, tileSize = 32, edgeSize = 32, insets = {left = 11, right = 12, top = 12, bottom = 11}})
                f:SetFrameStrata('DIALOG')
                f:EnableMouse(true)
                f:SetMovable(true)
                f:RegisterForDrag('LeftButton')
                f:SetScript('OnDragStart', function() this:StartMoving() end)
                f:SetScript('OnDragStop', function() this:StopMovingOrSizing() end)
                f:Hide()
                local title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
                title:SetPoint('TOP', 0, -16)
                title:SetText('按 Ctrl+C 复制链接')
                local eb = CreateFrame('EditBox', 'DFRL_URLCopyEditBox', f, 'InputBoxTemplate')
                eb:SetWidth(310)
                eb:SetHeight(20)
                eb:SetPoint('BOTTOM', 0, 18)
                eb:SetAutoFocus(true)
                eb:SetScript('OnEscapePressed', function() f:Hide() end)
                f.editBox = eb
            end
            DFRL_URLCopyDialog.editBox:SetText(url)
            DFRL_URLCopyDialog.editBox:HighlightText()
            DFRL_URLCopyDialog:Show()
            return
        end
        origSetItemRef(link, text, button)
    end

    -- 频道缩写系统
    local channelOriginals = {}

    local function AbbreviateChannels()
        local left = '|r['
        local right = ']|r'
        local fmt = ' %s|r: '
        channelOriginals.CHAT_GUILD_GET = _G.CHAT_GUILD_GET
        channelOriginals.CHAT_OFFICER_GET = _G.CHAT_OFFICER_GET
        channelOriginals.CHAT_PARTY_GET = _G.CHAT_PARTY_GET
        channelOriginals.CHAT_RAID_GET = _G.CHAT_RAID_GET
        channelOriginals.CHAT_RAID_LEADER_GET = _G.CHAT_RAID_LEADER_GET
        channelOriginals.CHAT_RAID_WARNING_GET = _G.CHAT_RAID_WARNING_GET
        channelOriginals.CHAT_BATTLEGROUND_GET = _G.CHAT_BATTLEGROUND_GET
        channelOriginals.CHAT_BATTLEGROUND_LEADER_GET = _G.CHAT_BATTLEGROUND_LEADER_GET
        channelOriginals.CHAT_SAY_GET = _G.CHAT_SAY_GET
        channelOriginals.CHAT_YELL_GET = _G.CHAT_YELL_GET
        channelOriginals.CHAT_WHISPER_GET = _G.CHAT_WHISPER_GET
        channelOriginals.CHAT_WHISPER_INFORM_GET = _G.CHAT_WHISPER_INFORM_GET
        _G.CHAT_GUILD_GET = left .. 'G' .. right .. fmt
        _G.CHAT_OFFICER_GET = left .. 'O' .. right .. fmt
        _G.CHAT_PARTY_GET = left .. 'P' .. right .. fmt
        _G.CHAT_RAID_GET = left .. 'R' .. right .. fmt
        _G.CHAT_RAID_LEADER_GET = left .. 'RL' .. right .. fmt
        _G.CHAT_RAID_WARNING_GET = left .. 'RW' .. right .. fmt
        _G.CHAT_BATTLEGROUND_GET = left .. 'BG' .. right .. fmt
        _G.CHAT_BATTLEGROUND_LEADER_GET = left .. 'BL' .. right .. fmt
        _G.CHAT_SAY_GET = left .. 'S' .. right .. fmt
        _G.CHAT_YELL_GET = left .. 'Y' .. right .. fmt
        _G.CHAT_WHISPER_GET = left .. 'W' .. right .. fmt
        _G.CHAT_WHISPER_INFORM_GET = left .. 'W' .. right .. fmt
    end

    local function RestoreChannels()
        for k, v in pairs(channelOriginals) do
            _G[k] = v
        end
    end

    -- 构建 AddMessage Hook
    RebuildAddMessageHooks()

    -- 时间戳
    callbacks.chatTimestamps = function(value)
        if value then
            chatFilters['timestamp'] = function(text)
                local tsColor = chatSetup.chatTimestampColor or {0.41, 0.8, 0.94}
                local hex = string.format('|cff%02x%02x%02x', tsColor[1] * 255, tsColor[2] * 255, tsColor[3] * 255)
                return hex .. '[' .. date('%H:%M') .. ']|r ' .. text
            end
        else
            chatFilters['timestamp'] = nil
        end
    end

    callbacks.chatTimestampColor = function()
        -- 重新应用时间戳过滤器以更新颜色
        if chatSetup.chatTimestamps then
            callbacks.chatTimestamps(true)
        end
    end

    -- URL 检测
    callbacks.chatURLDetect = function(value)
        if value then
            chatFilters['urls'] = function(text)
                return HandleURLs(text)
            end
        else
            chatFilters['urls'] = nil
        end
    end

    callbacks.chatURLColor = function()
        -- 颜色变更时无需重建，FormatURLLink 每次读取最新值
    end

    -- 频道缩写
    callbacks.chatAbbreviate = function(value)
        if value then
            AbbreviateChannels()
        else
            RestoreChannels()
        end
    end

    -- execute callbacks
    DFRL:NewCallbacks("Chat", callbacks)
end)
