-- UPDATE_BINDINGS, SPELLS_CHANGED, ACTIONBAR_SHOWGRID, ACTIONBAR_HIDEGRID, ACTIVE_TALENT_GROUP_CHANGED, PLAYER_ENTERING_WORLD

C_Timer.After(0.2, function()
    table.wipe(Skippy.spellkey)
    aura_env.ReadKeybindings()
end)
