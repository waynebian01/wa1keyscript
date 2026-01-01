function Dk(event, arg1, arg2, arg3)
    if event == "RUNE_POWER_UPDATE" then
        aura_env.RuneUpdata(arg1)
    end
    if event == "RUNE_TYPE_UPDATE" then
        aura_env.RuneType(arg1)
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        if aura_env.DeathAndDecaySpellId[arg3] then
            C_Timer.After(0.5, function()
                aura_env.GetDeacyCooldown(arg3)
            end)
        end
    end
end
