-- ═══════════════════════════════════════════════════════════════
-- libevents - 自定义事件库 (DFRL 简化版)
-- 提供延迟自定义事件触发，不 Hook 全局 CreateFrame
-- ═══════════════════════════════════════════════════════════════

local libevents = CreateFrame('Frame', 'DFRL_LibEvents', UIParent)
DFRL_Libs = DFRL_Libs or {}
DFRL_Libs.libevents = libevents

-- 已注册的帧: [事件名] = { frame1, frame2, ... }
local registeredFrames = {}

-- 自定义事件定义
local customEvents = {
    ['PLAYER_AFTER_ENTERING_WORLD'] = {
        triggerEvent = 'PLAYER_ENTERING_WORLD',
        delay = 0.05,
        fired = false,
        active = false,
        startTime = 0,
    },
    ['SYNC_READY'] = {
        triggerEvent = 'PLAYER_ENTERING_WORLD',
        delay = 2.0,
        fired = false,
        active = false,
        startTime = 0,
    },
}

-- 注册自定义事件监听
function libevents:RegisterCustomEvent(frame, eventName)
    if not customEvents[eventName] then return end
    registeredFrames[eventName] = registeredFrames[eventName] or {}
    table.insert(registeredFrames[eventName], frame)
end

-- 监听触发事件
for _, ce in pairs(customEvents) do
    if ce.triggerEvent then
        libevents:RegisterEvent(ce.triggerEvent)
    end
end

-- 事件触发后标记为活跃，开始计时
libevents:SetScript('OnEvent', function()
    for _, ce in pairs(customEvents) do
        if ce.triggerEvent == event then
            ce.startTime = GetTime()
            ce.active = true
        end
    end
end)

-- OnUpdate 检查延迟是否到达，触发自定义事件
libevents:SetScript('OnUpdate', function()
    for eventName, ce in pairs(customEvents) do
        if not ce.fired and ce.active then
            if ce.delay and GetTime() - ce.startTime >= ce.delay then
                ce.active = false
                ce.fired = true
                -- 广播给所有注册帧
                local frames = registeredFrames[eventName]
                if frames then
                    for _, frame in ipairs(frames) do
                        local handler = frame:GetScript('OnEvent')
                        if handler then
                            -- 通过临时修改全局 event 变量传递事件名
                            -- 使用 pcall 确保异常时也能恢复 event
                            local oldEvent = event
                            event = eventName
                            pcall(handler)
                            event = oldEvent
                        end
                    end
                end

                -- 所有事件都已触发时停止 OnUpdate
                local allFired = true
                for _, c in pairs(customEvents) do
                    if not c.fired then
                        allFired = false
                        break
                    end
                end
                if allFired then
                    libevents:SetScript('OnUpdate', nil)
                end
            end
        end
    end
end)
