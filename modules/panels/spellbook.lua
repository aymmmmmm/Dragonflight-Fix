setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("SpellBook", {
    enabled = {true},
})

DFUI:NewMod("SpellBook", 5, function()
    -- 暂不做任何修改，保留暴雪原生法术书
    local callbacks = {}
    DFUI:NewCallbacks("SpellBook", callbacks)
end)
