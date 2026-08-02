DFUI:NewDefaults("Frames", {
    enabled = {true},
})

DFUI:NewMod("Frames", 2, function()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")

        local framesToMakeMovable = {
            PlayerFrame,
            TargetFrame,
            TargetofTargetFrame,
            PartyMemberFrame1,
            PartyMemberFrame2,
            PartyMemberFrame3,
            PartyMemberFrame4,
            DFUI.mainBar,
            MultiBarBottomLeft,
            MultiBarBottomRight,
            MultiBarLeft,
            MultiBarRight,
            PetFrame,
            DFUI.newPetBar,
            DFUI.newShapeshiftBar,
            DFUI.xpBar,
            DFUI.repBar,
            DFUI.castbar,
            MainMenuBarBackpackButton,
            DFUI.microMenuContainer,
            DFUI.netStatsFrame,
            Minimap,
            DFUI.topPanel,
            DFUI.questframe,
            BuffButton0,
            BuffButton8,
            TempEnchant1,
            BuffButton16,
            -- BuffButton32 conditionally appended below (Turtle 1.18 only).
            QuestTimerFrame,

            -- 3rd party
            DFUI.PWB_Panel,

            -- loot module
            DFUI.lootFrame,
        }

        -- orbs + track button
        local orbHP = _G["DFUI_HealthOrb"]
        local orbMP = _G["DFUI_ManaOrb"]
        local trackBtn = _G["DFUI_TrackBtn"]
        if orbHP then table.insert(framesToMakeMovable, orbHP) end
        if orbMP then table.insert(framesToMakeMovable, orbMP) end
        if trackBtn then table.insert(framesToMakeMovable, trackBtn) end
        -- BuffButton32 is a Turtle 1.18 extension (扩展 buff 槽); absent on 1.17.
        if BuffButton32 then table.insert(framesToMakeMovable, BuffButton32) end

        -- 辅助功能·攻击计时条主框（副手/远程相对主框锚定，随主框一起移动）
        local atkBar = _G["DFUIAssistAttackBar"]
        if atkBar then table.insert(framesToMakeMovable, atkBar) end

        -- 拾取投骰锚点（在 PLAYER_LOGIN 建，早于本 handler；同攻击条走 _G 条件 insert）
        local rollAnc = _G["DFUIRollAnchor"]
        if rollAnc then table.insert(framesToMakeMovable, rollAnc) end

        -- 焦点框体（focus.lua 模块体=ADDON_LOADED 建，早于本 handler）
        local focusF = _G["DFUIFocusFrame"]
        if focusF then table.insert(framesToMakeMovable, focusF) end


        -- 把 frame 四边从"自身坐标系"换算到 UIParent 坐标系。
        -- frame:GetLeft() 等返回的是 frame 自身坐标系的值（已除以 frame:GetEffectiveScale()），
        -- 凡是 SetScale 过的 frame（PlayerFrame/动作条/宠物条…几乎全都有）必须乘
        -- fs/us 换算。屏幕尺寸一律用 GetFinalScreenSize()——UIParent:GetWidth/
        -- GetHeight 在本客户端恒返回未缩放基准值(1365x768)，是说谎 API，禁止使用。
        local function GetBoundsInUIParent(frame)
            local l, r = frame:GetLeft(), frame:GetRight()
            local t, b = frame:GetTop(), frame:GetBottom()
            -- 布局还没算出来就别存，免得把 nil 写进档案
            if not l or not r or not t or not b then return nil end

            local fs = frame:GetEffectiveScale()
            local us = UIParent:GetEffectiveScale()
            local s = 1
            if fs and us and us > 0 then s = fs / us end

            return l * s, r * s, t * s, b * s
        end

        -- 屏幕横竖各分三段，按 frame 中心落点选九宫格里最贴切的那个锚点：
        -- 贴边的存边距（换屏幕尺寸后仍贴同一条边，不会被顶出去），
        -- 居中的存"相对屏幕中心的偏移"（动作条这类东西换分辨率后仍然居中）。
        -- 入参必须全是 UIParent 坐标系的量，换算由调用方负责。
        local function ComputeAnchor(l, r, t, b, sw, sh)
            local cx, cy = (l + r) / 2, (t + b) / 2

            local hSide, vSide
            if cx < sw / 3 then hSide = "LEFT"
            elseif cx > sw * 2 / 3 then hSide = "RIGHT"
            else hSide = "" end

            if cy < sh / 3 then vSide = "BOTTOM"
            elseif cy > sh * 2 / 3 then vSide = "TOP"
            else vSide = "" end

            local point = vSide .. hSide
            if point == "" then point = "CENTER" end

            local ox, oy
            if hSide == "LEFT" then ox = l
            elseif hSide == "RIGHT" then ox = r - sw
            else ox = cx - sw / 2 end

            if vSide == "BOTTOM" then oy = b
            elseif vSide == "TOP" then oy = t - sh
            else oy = cy - sh / 2 end

            return point, ox, oy
        end

        -- 屏幕终态尺寸直接由 CVar 推导（引擎最终要应用的权威值，与引擎当下状态无关）：
        --   sh = 768/uiScale，sw = 768*(gxResolution 宽高比)/uiScale
        local function GetFinalScreenSize()
            local scale = 1
            if GetCVar("useUiScale") == "1" then
                scale = tonumber(GetCVar("uiScale")) or 1
                -- 引擎对 uiScale 的钳制范围
                if scale < 0.64 then scale = 0.64 elseif scale > 1 then scale = 1 end
            end
            local aspect = 4 / 3
            local res = GetCVar("gxResolution")
            if res then
                local _, _, rw, rh = string.find(res, "(%d+)x(%d+)")
                rw, rh = tonumber(rw), tonumber(rh)
                if rw and rh and rh > 0 then aspect = rw / rh end
            end
            return 768 * aspect / scale, 768 / scale
        end

        -- 取证日志：只记 TrackBtn 的写入和所有被拒的保存（带调用栈），落在角色级
        -- DFUI_FRAMEPOS["__poslog"] 随存档持久化，用于事后定位异常写入者
        local function LogPosEvent(tag, name, l, t)
            local log = DFUI_FRAMEPOS["__poslog"]
            if not log then log = {}; DFUI_FRAMEPOS["__poslog"] = log end
            table.insert(log, string.format("%s %s gt=%.1f sw=%.1f sh=%.1f l=%.2f t=%.2f | %s",
                tag, name, GetTime(), UIParent:GetWidth(), UIParent:GetHeight(),
                l or -1, t or -1, debugstack(3, 5, 0) or "?"))
            while table.getn(log) > 15 do table.remove(log, 1) end
        end

        local function SaveFramePosition(frame)
            local name = frame:GetName()
            if not name then return end

            local l, r, t, b = GetBoundsInUIParent(frame)
            if not l then return end

            local sw, sh = GetFinalScreenSize()

            -- ⭐ UIParent:GetWidth/GetHeight 在本客户端恒返回未缩放基准值
            -- （1365x768，取证日志实测），与真实坐标广度 base/uiScale=1569x883
            -- 永远差一个 uiScale——绝不能参与锚点计算或用作校验基准
            -- （历次"整体偏移"与"拖动保存被拒"的总根源）。
            -- 写入闸门只做结果自检：玩家不可能把 frame 拖到完全屏幕外，
            -- 算出整盒在屏外 = 读到了脏矩形（历史毒值 t=923.9 正是这形状），弃存。
            if b >= sh or t <= 0 or l >= sw or r <= 0 then
                LogPosEvent("save-REJECT", name, l, t)
                return
            end

            local point, ox, oy = ComputeAnchor(l, r, t, b, sw, sh)
            if name == "DFUI_TrackBtn" then LogPosEvent("save", name, l, t) end
            DFUI_FRAMEPOS[name] = { point = point, ox = ox, oy = oy }
        end

        -- 旧格式 → 新格式迁移。
        -- ⭐ 根治思路（前两版教训）：登录期 uiScale 生效晚于 PEW 且非原子——scale
        -- 属性、UIParent 矩形、GetScreenWidth 各自何时更新无从验证，任何"检测已
        -- settle 再迁移"的窗口方案都是在猜引擎内部时序（第一版直接读→写坏 17 条；
        -- 第二版恒等式检测→settle 后永不通过→静默放弃）。
        -- 所以彻底不读引擎当下状态：屏幕终态尺寸直接由 CVar 推导——
        --   sh = 768/uiScale，sw = 768*(gxResolution 宽高比)/uiScale
        -- CVar 是引擎最终要应用的权威值（sh=882.76 已与游戏内实测吻合），何时应用
        -- 与我们无关；ApplyFramePos 的偏移换算 us/fs=1/c 同样与 uiScale 无关，
        -- 锚点数据在引擎 rescale 后自动重算落位。于是迁移是纯代数，登录时同步
        -- 执行即可，不存在时序窗口。
        local function MeasureFrameUI(frame)
            -- c = frame 相对 UIParent 的缩放比。fs/us 里 uiScale 被约掉，
            -- 只剩自身 SetScale 链，所以任何时刻读都正确
            local fs = frame:GetEffectiveScale()
            local us = UIParent:GetEffectiveScale()
            local c = 1
            if fs and us and us > 0 then c = fs / us end

            -- 尺寸与位置无关，优先用已解算边距（GetHeight 在双锚 frame 上不可靠）
            local w, h
            local gl, gr = frame:GetLeft(), frame:GetRight()
            local gt, gb = frame:GetTop(), frame:GetBottom()
            if gl and gr then w = gr - gl else w = frame:GetWidth() end
            if gt and gb then h = gt - gb else h = frame:GetHeight() end
            if not w or w <= 0 then w = 20 end
            if not h or h <= 0 then h = 20 end

            return c, w * c, h * c
        end

        -- 统一落位：钳"整个在屏幕外"的回屏内 → 算锚点 → 写表 → 应用。
        -- 入参全部为 UIParent 终态坐标系（l=左边缘，t=上边缘）。
        local function ClampAndStore(frame, name, l, t, w, h, tag)
            local sw, sh = GetFinalScreenSize()

            -- 只救"整个 frame 都在屏幕外"的：还露着一部分的一律不动，
            -- 免得把特意贴边摆的东西挪走
            if t - h >= sh then t = sh                 -- 整个在屏幕上方
            elseif t <= 0 then t = h end               -- 整个在屏幕下方
            if l >= sw then l = sw - w                 -- 整个在屏幕右侧
            elseif l + w <= 0 then l = 0 end           -- 整个在屏幕左侧

            local point, ox, oy = ComputeAnchor(l, l + w, t, t - h, sw, sh)
            local newPos = { point = point, ox = ox, oy = oy }
            if name == "DFUI_TrackBtn" then LogPosEvent(tag, name, l, t) end
            DFUI_FRAMEPOS[name] = newPos
            DFUI:ApplyFramePos(frame, newPos)
        end

        local function MigrateLegacyPos(frame, name, pos)
            local c, w, h = MeasureFrameUI(frame)
            -- 旧格式 x=左边缘 y=上边缘（frame 坐标系）→ 乘 c 到 UIParent 坐标系
            ClampAndStore(frame, name, pos.x * c, pos.y * c, w, h, "migrate")
        end

        -- 读取自愈：新格式条目若整个盒子都在屏幕外（历史毒值/换分辨率极端情况），
        -- 用同一套 CVar 代数钳回屏内；正常条目原样应用、不改写数据。
        local function ApplyModernPos(frame, name, pos)
            local c, w, h = MeasureFrameUI(frame)
            local sw, sh = GetFinalScreenSize()
            local p = pos.point

            local l, t
            if string.find(p, "LEFT") then l = pos.ox
            elseif string.find(p, "RIGHT") then l = sw + pos.ox - w
            else l = sw / 2 + pos.ox - w / 2 end

            if string.find(p, "TOP") then t = sh + pos.oy
            elseif string.find(p, "BOTTOM") then t = pos.oy + h
            else t = sh / 2 + pos.oy + h / 2 end

            if t - h >= sh or t <= 0 or l >= sw or l + w <= 0 then
                ClampAndStore(frame, name, l, t, w, h, "sanitize")
            else
                DFUI:ApplyFramePos(frame, pos)
            end
        end

        local function RestoreFramePositions()
            if not DFUI_FRAMEPOS then return end

            for name, pos in pairs(DFUI_FRAMEPOS) do
                -- 跳过光环锚点（由 auras.lua 的滑块控制位置）
                if string.find(name, "DFUI_AuraAnchor_") then
                    DFUI_FRAMEPOS[name] = nil
                else
                    local frame = _G[name]
                    if frame then
                        if pos.point then
                            -- 新格式：锚到就近的屏幕角，屏幕尺寸变了也自动跟着走；
                            -- 内含"整盒在屏幕外→钳回"自愈
                            ApplyModernPos(frame, name, pos)
                        elseif pos.x and pos.y then
                            -- 旧格式绝对像素：纯代数换算成新格式（终态尺寸来自
                            -- CVar，不读引擎当下状态，任何时刻执行结果相同）
                            MigrateLegacyPos(frame, name, pos)
                        end
                    end
                end
            end
        end

        -- 暴露给外部调用（档案切换时恢复位置）
        function DFUI:RestoreFramePositions()
            RestoreFramePositions()
        end

        -- grid
        local grid = CreateFrame("Frame", nil, UIParent)
        grid:SetAllPoints(UIParent)
        grid:Hide()

        -- grid lines
        local size = 1
        local line = {}

        local width = GetScreenWidth()
        local height = GetScreenHeight()

        local ratio = width / GetScreenHeight()
        local rheight = GetScreenHeight() * ratio

        local wStep = width / 64
        local hStep = rheight / 64

        -- vertical lines
        for i = 0, 64 do
            if i == 64 / 2 then
                line = grid:CreateTexture(nil, 'BORDER')
                line:SetTexture(.8, .6, 0)
            else
                line = grid:CreateTexture(nil, 'BACKGROUND')
                line:SetTexture(0, 0, 0, .2)
            end
            line:SetPoint("TOPLEFT", grid, "TOPLEFT", i*wStep - (size/2), 0)
            line:SetPoint('BOTTOMRIGHT', grid, 'BOTTOMLEFT', i*wStep + (size/2), 0)
        end

        -- horizontal lines
        for i = 1, floor(height/hStep) do
            if i == floor(height/hStep / 2) then
                line = grid:CreateTexture(nil, 'BORDER')
                line:SetTexture(.8, .6, 0)
            else
                line = grid:CreateTexture(nil, 'BACKGROUND')
                line:SetTexture(0, 0, 0, .2)
            end
            line:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(i*hStep) + (size/2))
            line:SetPoint('BOTTOMRIGHT', grid, 'TOPRIGHT', 0, -(i*hStep + size/2))
        end

        local flag -- flag to hide/show certain elements like castbar etc.
        local function MakeFrameMovable(frame)
            if not frame then return end
            if frame._dfMovableInit then return end  -- 防重复接入（reload/主动接入双触发）
            frame._dfMovableInit = true

            frame:EnableMouse(true)
            frame:SetMovable(true)
            -- ⭐ 位置唯一权威是 DFUI_FRAMEPOS。StartMoving 会给具名 frame 打上引擎
            -- UserPlaced 标记 → 引擎把位置写进 layout-cache.txt 并在登录时晚于插件
            -- 重放，覆盖我们的落位（TrackBtn 长期屏幕外就是被这个缓存反复劫持）。
            -- 这里与每次 StopMovingOrSizing 后都清标记，另有 PLAYER_LOGOUT 兜底清扫。
            frame:SetUserPlaced(false)

            local overlay = CreateFrame("Frame", nil, frame)
            overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", -10, 10)
            overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 10, -10)
            overlay:SetFrameStrata("TOOLTIP")
            overlay:SetFrameLevel(100)
            overlay:SetToplevel(true)
            overlay:EnableMouse(true)
            overlay:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 32,
                edgeSize = 16,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            overlay:SetBackdropColor(1, 0.82, 0, 0.5)
            overlay:SetBackdropBorderColor(1, 0.82, 0, 1)
            overlay:Hide()

            -- overlay drags the frame
            overlay:SetScript("OnMouseDown", function()
                frame:StartMoving()
            end)

            overlay:SetScript("OnMouseUp", function()
                local frameName = frame:GetName()

                -- set the actionbars movable to false
                if frameName == "MultiBarBottomLeft" or frameName == "MultiBarBottomRight" then
                    DFUI:SetTempDBNoCallback("actionbars", "movable", false)
                end
                frame:StopMovingOrSizing()
                frame:SetUserPlaced(false)
                SaveFramePosition(frame)
            end)

            local function CreateDirectionButton(dir, xOffset, yOffset, text)
                local button = CreateFrame("Button", nil, overlay, "UIPanelButtonTemplate")
                button:SetWidth(14)
                button:SetHeight(14)
                button:SetPoint(dir, overlay, dir, 0, 0)
                button:SetText(text)
                button:GetNormalTexture():SetVertexColor(0, 0, 0)
                button:GetHighlightTexture():SetVertexColor(0.3, 0.3, 0.3)
                button:GetPushedTexture():SetVertexColor(0.2, 0.2, 0.2)
                button:SetScript("OnClick", function()
                    frame:ClearAllPoints()
                    local x, y = frame:GetLeft() + xOffset, frame:GetTop() + yOffset
                    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
                    SaveFramePosition(frame)
                end)
                return button
            end

            CreateDirectionButton("TOP", 0, 1, "U")
            CreateDirectionButton("LEFT", -1, 0, "L")
            CreateDirectionButton("RIGHT", 1, 0, "R")
            CreateDirectionButton("BOTTOM", 0, -1, "D")

            -- overlay visibility
            local controlFrame = CreateFrame("Frame")
            controlFrame:SetScript("OnUpdate", function()
                if (this.tick or 0) > GetTime() then return end
                this.tick = GetTime() + 0.1

                if IsControlKeyDown() and IsShiftKeyDown() and IsAltKeyDown() then
                    flag = true
                    DFUI.activeScripts["FrameControlScript"] = true

                    if DFUI.castbar then
                        DFUI.castbar:Show()
                        DFUI.castbar.bar:Hide() -- bug fix
                    end

                    -- 攻击计时条平时隐藏，布局模式下临时显示以便拖动
                    if DFUI.Assist and DFUI.Assist.AttackBarFrame then
                        DFUI.Assist.AttackBarFrame:Show()
                    end

                    -- 拾取面板平时隐藏，布局模式下显示示例框以便拖动定位
                    if DFUI.ShowRollPreview then DFUI.ShowRollPreview() end

                    -- 焦点框平时无焦点则隐藏，布局模式下显示预览框以便拖动定位
                    if DFUI.ShowFocusPreview then DFUI.ShowFocusPreview() end

                    FramerateLabel:Show()

                    if DFUI.netStatsFrame then
                        DFUI.netStatsFrame:Show()
                    end

                    -- BuffButton8:Show() -- doesnt work yet
                    -- TargetUnit("player")
                    -- TargetFrame:Show()

                    overlay:Show()
                    grid:Show()
                else
                    if flag == true then
                        -- ClearTarget()
                        -- TargetFrame:Hide()
                        if DFUI.castbar then
                            DFUI.castbar.bar:Show()
                            DFUI.castbar:Hide()
                        end

                        -- 退出布局模式：非战斗时把攻击条收回隐藏
                        if DFUI.Assist and DFUI.Assist.AttackBarFrame
                           and not UnitAffectingCombat("player") then
                            DFUI.Assist.AttackBarFrame:Hide()
                        end

                        -- 退出布局模式：收回拾取面板示例框
                        if DFUI.HideRollPreview then DFUI.HideRollPreview() end

                        -- 退出布局模式：收回焦点预览框
                        if DFUI.HideFocusPreview then DFUI.HideFocusPreview() end

                        FramerateLabel:Hide()

                        if DFUI.netStatsFrame then
                            DFUI.netStatsFrame:Hide()
                        end
                        -- BuffButton8:Hide()

                        -- false to prevent from hiding again
                        flag = false
                    end
                    overlay:Hide()
                    grid:Hide()
                    frame:StopMovingOrSizing()
                    DFUI.activeScripts["FrameControlScript"] = false
                end
            end)

            frame:SetScript("OnDragStart", function()
                if IsControlKeyDown() and IsShiftKeyDown() and IsAltKeyDown() then
                    frame:StartMoving()
                end
            end)

            frame:SetScript("OnDragStop", function()
                frame:StopMovingOrSizing()
                frame:SetUserPlaced(false)
                SaveFramePosition(frame)
            end)
        end

        -- make frames from list movable
        for i = 1, table.getn(framesToMakeMovable) do
            if framesToMakeMovable[i] then
                MakeFrameMovable(framesToMakeMovable[i])
            end
        end

        -- 登出兜底清扫：PLAYER_LOGOUT 先于引擎重写 layout-cache.txt，此刻清掉
        -- 全部受管框体的 UserPlaced 标记，引擎重写时就会把它们从缓存剔除。
        -- 这是不依赖"引擎何时重放缓存"任何假设的拦截点。
        local logoutSweep = CreateFrame("Frame")
        logoutSweep:RegisterEvent("PLAYER_LOGOUT")
        logoutSweep:SetScript("OnEvent", function()
            for i = 1, table.getn(framesToMakeMovable) do
                local fr = framesToMakeMovable[i]
                if fr and fr.SetUserPlaced then fr:SetUserPlaced(false) end
            end
        end)

        -- init
        RestoreFramePositions()
    end)

    DFUI.activeScripts["FrameControlScript"] = false
end)
