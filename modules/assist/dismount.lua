----------------------------------------------------------------------
-- DFUI.Assist  --  自动下马 + 解除形态
-- 移植 Automatonex Dismount + Unshapeshift。
-- 施法/攻击/与飞行管理员交互报错时，自动取消坐骑 buff，并解除
-- 德鲁伊/萨满/牧师形态。坐骑用 libtipscan 扫 buff 测速关键词识别
-- （兼容 Turtle 自定义坐骑提示）。
-- 不处理“需要站立”——已由现有 autoStand 模块负责。
----------------------------------------------------------------------

local L = DFUI.Assist.L
local scanner = DFUI_Libs.libtipscan:GetScanner("DFUIAssistDismount")
local _, playerClass = UnitClass("player")

-- 触发下马/解形态的错误常量（运行时取值，缺失则忽略）
local triggers = {}
local function add(s) if s and s ~= "" then triggers[s] = true end end
add(SPELL_FAILED_NOT_MOUNTED)
add(ERR_ATTACK_MOUNTED)
add(ERR_TAXIPLAYERALREADYMOUNTED)
add(SPELL_FAILED_NOT_SHAPESHIFT)
add(ERR_NOT_WHILE_SHAPESHIFTED)
add(ERR_TAXIPLAYERSHAPESHIFTED)
add(ERR_CANT_INTERACT_SHAPESHIFTED)
add(ERR_NO_ITEMS_WHILE_SHAPESHIFTED)
add(SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED)
add(ERR_MOUNT_SHAPESHIFTED)

-- 坐骑 buff 测速关键词（移植自源码 patterns，含 enUS/zhCN/Turtle）
local mountPatterns = {
    "^Increases speed by",
    "^速度提高",
    "speed based on",
    "Slow and steady",
    "Riding",
    "根据您的骑行技能提高速度",
    "根据骑术技能提高速度",
    "又慢又稳",
}

-- 需要取消的形态图标（小写匹配）
local shiftIcons = {
    "spell_nature_spiritwolf",   -- 萨满 幽灵狼
    "spell_shadow_shadowform",   -- 牧师 暗影形态
}

-- 扫 buff 找坐骑 buff，返回 buff index（无则 nil）
local function FindMountBuff()
    for i = 0, 31 do
        local tex = GetPlayerBuffTexture(i)
        if tex then
            scanner:SetPlayerBuff(i)
            for pi = 1, table.getn(mountPatterns) do
                if scanner:FindText(mountPatterns[pi]) then
                    return i
                end
            end
        end
    end
end

-- 取消坐骑 buff
local function CancelMount()
    local i = FindMountBuff()
    if i then CancelPlayerBuff(i) end
end

-- 是否骑乘（1.12 无 IsMounted API）。供其他模块查询，例如 autoattack
-- 骑乘时跳过普攻，避免 AttackTarget() 报 ERR_ATTACK_MOUNTED 连锁下马。
function DFUI.Assist.IsMounted()
    return FindMountBuff() ~= nil
end

-- 解除形态（德鲁伊取消当前形态，萨满/牧师取消对应 buff）
local function Unshift()
    if playerClass == "DRUID" then
        for i = 1, GetNumShapeshiftForms() do
            local _, _, active = GetShapeshiftFormInfo(i)
            if active then
                CastShapeshiftForm(i)
                return
            end
        end
    else
        for i = 0, 31 do
            local tex = GetPlayerBuffTexture(i)
            if tex then
                local low = string.lower(tex)
                for si = 1, table.getn(shiftIcons) do
                    if string.find(low, shiftIcons[si]) then
                        CancelPlayerBuff(i)
                        return
                    end
                end
            end
        end
    end
end

DFUI.Assist:register({
    key = "autoDismount",
    title = L["autoDismount"],
    desc = L["autoDismountDesc"],
    default = false,
    events = {
        UI_ERROR_MESSAGE = function(self)
            if arg1 and triggers[arg1] then
                CancelMount()
                Unshift()
            end
        end,
        -- 打开飞行点强制下马
        TAXIMAP_OPENED = function(self)
            CancelMount()
        end,
    },
})
