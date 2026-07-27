DFUI:NewDefaults('Errors', {
    enabled = {true},
    hideErrors = {false, 'checkbox', nil, nil, '功能调整', 1, '隐藏所有Lua错误', nil, nil},

    -- 诊断页（tab16）两个复选框的存储。故意写成单元素形式：elem.lua 的
    -- `table.getn(valueTable) > 1` 门槛会跳过它们，所以不会跑到 tab11「界面」页，
    -- 仍由 gui/bugs.lua 的手写复选框控制——只是存进档案，从而能随导出串共享。
    bugAutoToast = {false},
    bugOnlyDFUI  = {false},
})

DFUI:NewMod('Errors', 1, function()
    -- 把旧版 DFUI_BUGS.prefs 迁进档案并刷新 DFUI.errors.prefs 镜像。
    -- 必须在这里（prio 1）跑：Gui-bugs 是 prio 5，建复选框时要读到迁移后的值；
    -- core/error.lua 自己的 ADDON_LOADED handler 比整个 RunMods 还晚。
    if DFUI.errors and DFUI.errors.SyncPrefs then DFUI.errors.SyncPrefs() end

    local originalHandler = geterrorhandler()

    local callbacks = {}

    callbacks.hideErrors = function(value)
        if value then
            seterrorhandler(function() end)
        else
            seterrorhandler(originalHandler)
        end
    end

    DFUI:NewCallbacks('Errors', callbacks)
end)
