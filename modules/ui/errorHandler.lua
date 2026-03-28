DFUI:NewDefaults('Errors', {
    enabled = {true},
    hideErrors = {false, 'checkbox', nil, nil, '功能调整', 1, '隐藏所有Lua错误', nil, nil},
})

DFUI:NewMod('Errors', 1, function()
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
