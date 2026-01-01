--=======以下事件===========
function BeaconUnit(event, arg1, arg2, arg3, arg4)
    if event == "UNIT_SPELLCAST_SENT" and arg1 == "player" then
        -- unit, target, castGUID, spellID
        if arg4 == 53563 then
            aura_env.SetUnitByName(arg2, "Beacon")
        elseif arg4 == 53601 then
            aura_env.SetUnitByName(arg2, "Shield")
        elseif aura_env.FlashLightSpellIds[arg4] or aura_env.HolyLightSpellIds[arg4] then
            aura_env.SetUnitByName(arg2, "Healing")
        end
    elseif event == "UNIT_SPELLCAST_START" and arg1 == "player" then
        -- unitTarget, castGUID, spellID
        local name, _, _, startTimeMS, endTimeMS = UnitCastingInfo("player")
        if aura_env.HolyLightSpellIds[arg3] then
            aura_env.isCastingHolyLight = true
        end
        if aura_env.FlashLightSpellIds[arg3] then
            aura_env.isCastingFlashLight = true
        end
        aura_env.CastingEndTime = endTimeMS / 1000
    elseif event == "UNIT_SPELLCAST_STOP" and arg1 == "player" then
        -- unitTarget, castGUID, spellID
        aura_env.healingUnit = nil
        aura_env.isCastingHolyLight = false
        aura_env.isCastingFlashLight = false
        aura_env.CastingEndTimeMS = nil
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        if arg3 == 20271 then
            aura_env.Judgement = "圣光审判"
        elseif arg3 == 53408 then
            aura_env.Judgement = "智慧审判"
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if UnitPlayerOrPetInParty("player") then
            if not UnitExists(aura_env.BeaconUnit) then
                aura_env.BeaconUnit = nil
            end
            if not UnitExists(aura_env.ShieldUnit) then
                aura_env.ShieldUnit = nil
            end
        else
            aura_env.BeaconUnit = nil
            aura_env.ShieldUnit = nil
        end
        aura_env.InitConfig()
    elseif event == "PLAYER_ENTERING_WORLD" then
        aura_env.InitConfig()
    end
end
