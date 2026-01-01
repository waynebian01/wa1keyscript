--PLAYER_TALENT_UPDATE,TRAIT_CONFIG_UPDATED,PLAYER_ENTERING_WORLD,PLAYER_LEVEL_UP
-- UNIT_SPELLCAST_SUCCEEDED
function WarriorEvent(event, arg1, _, arg3)
    if event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        aura_env.SetShout(arg3)
    else
        aura_env.WarriorInfo()
    end
end
