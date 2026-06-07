----------------------------------------------------------------------
-- DFUI.Assist  --  自动攻击（仅已进战斗时确保普攻）
--
-- AttackTarget() 是 toggle：已在攻击时再调用会“停止”攻击。
-- 1.12 中 PLAYER_ENTER_COMBAT / PLAYER_LEAVE_COMBAT = 近战自动攻击
-- 开始 / 停止（非进出战斗），用它维护 isAttacking 防止误 toggle。
--
-- 安全策略：仅当自己已处于战斗中、目标可攻击、且当前未在普攻时才开打，
-- 绝不主动开战（避免误触发 PvP / 打中立单位）。
----------------------------------------------------------------------

local L = DFUI.Assist.L

local isAttacking = false

local function ensureAttack()
    if isAttacking then return end
    if not UnitAffectingCombat("player") then return end
    if not UnitExists("target") then return end
    if UnitIsDeadOrGhost("target") then return end
    if not UnitCanAttack("player", "target") then return end
    AttackTarget()
end

DFUI.Assist:register({
    key = "autoAttack",
    title = L["autoAttack"],
    desc = L["autoAttackDesc"],
    default = false,
    events = {
        PLAYER_ENTER_COMBAT   = function(self) isAttacking = true end,
        PLAYER_LEAVE_COMBAT   = function(self) isAttacking = false end,
        PLAYER_TARGET_CHANGED = function(self) ensureAttack() end,
        PLAYER_REGEN_DISABLED = function(self) ensureAttack() end,
    },
})
