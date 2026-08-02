-- ============================================================
-- 内置标准默认布局（aym 基准，2026-08-02 实测定稿）
--
-- 采集自 2560x1440 @ uiScale 0.87 的手调布局。新格式锚点：
-- 每个框体锚到离它最近的屏幕角/边/中心（九宫格），ox/oy 为
-- UIParent 终态坐标系里相对该锚点的偏移——贴边元素换分辨率后
-- 仍贴同一条边，居中元素仍居中（见 frames.lua ComputeAnchor）。
--
-- 生效场合（三处接入，均经 DFUI:CopyFramePos 深拷贝，本表只读）：
--   1. 登录时档案无 _FramePos 且角色无历史位置 → 开箱即此布局
--   2. 新建档案 → 自带此布局
--   3. 配置面板「重置为默认」→ 恢复此布局
-- ============================================================

DFUI.defaultFramePos = {
    ["PlayerFrame"] = {
        point = "LEFT", ox = 298.4943118571642, oy = -121.1621163963126,
    },
    ["TargetFrame"] = {
        point = "BOTTOMRIGHT", ox = -281.4419017106973, oy = 206.8045248929552,
    },
    ["TargetofTargetFrame"] = {
        point = "RIGHT", ox = -418.4363598408972, oy = -99.75592807921998,
    },
    ["DFUIFocusFrame"] = {
        point = "LEFT", ox = 300.5155454111444, oy = -70.02577824483001,
    },
    ["PartyMemberFrame1"] = {
        point = "TOPLEFT", ox = 11.00000102580859, oy = -156.0917145708671,
    },
    ["DFUI_MainBar"] = {
        point = "BOTTOM", ox = 9.333431689817417, oy = 25.4266995135137,
    },
    ["MultiBarBottomLeft"] = {
        point = "BOTTOM", ox = 8.663696305349959, oy = 65.42677884271151,
    },
    ["MultiBarBottomRight"] = {
        point = "BOTTOM", ox = 7.990056830156391, oy = 106.1107043058179,
    },
    ["DFUI_PetBar"] = {
        point = "BOTTOM", ox = 9.714718347220696, oy = 216.0655607635754,
    },
    ["DFUI_ShapeshiftBar"] = {
        point = "BOTTOM", ox = 9.207263558108252, oy = 148.8662468728651,
    },
    ["DFUI_XPBar"] = {
        point = "BOTTOM", ox = 36.41507753428368, oy = 14.35840027354896,
    },
    ["DFUI_RepBar"] = {
        point = "BOTTOM", ox = 9.777272473628045, oy = 5.354699863225521,
    },
    ["DFUICastbar"] = {
        point = "BOTTOM", ox = 8.963803584412517, oy = 192.8613815959407,
    },
    ["DFUIAssistAttackBar"] = {
        point = "BOTTOM", ox = 8.006233421327352, oy = 258.3202028693781,
    },
    ["DFUI_questframe"] = {
        point = "TOPRIGHT", ox = -100.4634437004625, oy = -265.9182158513565,
    },
    ["DFUIRollAnchor"] = {
        point = "RIGHT", ox = -211.966123301062, oy = -19.25675484675151,
    },
    ["DFUI_TrackBtn"] = {
        point = "TOPRIGHT", ox = -213.7272008541745, oy = -23.54870976823645,
    },
}
