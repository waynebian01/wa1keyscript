-- UNIT_HEALTH, UNIT_MAXHEALTH, UNIT_HEAL_ABSORB_AMOUNT_CHANGED, UNIT_HEAL_PREDICTION, UNIT_POWER_UPDATE, UNIT_AURA, UNIT_SPELLCAST_SENT, UNIT_SPELLCAST_CHANNEL_START, UNIT_SPELLCAST_CHANNEL_STOP, UNIT_SPELLCAST_START, UNIT_SPELLCAST_STOP, UNIT_INVENTORY_CHANGED, PLAYER_STARTED_MOVING, PLAYER_STOPPED_MOVING, PLAYER_REGEN_DISABLED, PLAYER_REGEN_ENABLED, PLAYER_TALENT_UPDATE, UPDATE_SHAPESHIFT_FORM, UPDATE_SHAPESHIFT_FORMS, PLAYER_TOTEM_UPDATE, PLAYER_ENTERING_WORLD, GROUP_ROSTER_UPDATE

function State(event, arg1, arg2)
    local e = aura_env
    if event == "UNIT_HEALTH" and arg1 == "player" then
        e.UpdatePlayerHealth("health", UnitHealth)
    elseif event == "UNIT_MAXHEALTH" and arg1 == "player" then
        e.UpdatePlayerHealth("healthMax", UnitHealthMax)
    elseif event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" and arg1 == "player" then
        e.UpdatePlayerHealth("healAbsorbs", UnitGetTotalHealAbsorbs)
    elseif event == "UNIT_HEAL_PREDICTION" and arg1 == "player" then
        e.UpdatePlayerHealth("healPrediction", UnitGetIncomingHeals)
    elseif event == "UNIT_POWER_UPDATE" and arg1 == "player" then
        e.UpdatePower("player", arg2)
    elseif event == "UNIT_AURA" and arg1 == "player" then
        e.UpdatePlayerAuraIncremental(arg2)
    elseif event == "UNIT_SPELLCAST_SENT" and arg1 == "player" then
        Skippy.state.CastTargetName = arg2
        if Skippy.state.inParty or Skippy.state.inRaid then
            e.UpdateCastTarget(arg2)
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" and arg1 == "player" then
        Skippy.state.channel = true
        e.UpdateChannelingInfo()
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" and arg1 == "player" then
        Skippy.state.channel = false
        Skippy.state.CastTargetName = nil
        Skippy.state.CastTargetUnit = nil
        table.wipe(Skippy.state.channelInfo)
    elseif event == "UNIT_SPELLCAST_START" and arg1 == "player" then
        Skippy.state.cast = true
        e.UpdateCastingInfo()
    elseif event == "UNIT_SPELLCAST_STOP" and arg1 == "player" then
        Skippy.state.cast = false
        Skippy.state.CastTargetName = nil
        Skippy.state.CastTargetUnit = nil
        table.wipe(Skippy.state.castInfo)
    elseif event == "PLAYER_STARTED_MOVING" then
        Skippy.state.isMoving = true
    elseif event == "PLAYER_STOPPED_MOVING" then
        Skippy.state.isMoving = false
    elseif event == "PLAYER_REGEN_DISABLED" then
        Skippy.state.isCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        Skippy.state.isCombat = false
    elseif event == "PLAYER_TALENT_UPDATE" then
        e.UpdateSpec()
    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
        e.UpdateShapeshiftForm()
    elseif event == "PLAYER_TOTEM_UPDATE" then
        e.UpdateTotem(arg1)
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        Skippy.state.hasMainHandEnchant = GetWeaponEnchantInfo()
    elseif event == "PLAYER_ENTERING_WORLD" then
        e.UpdateSpec()
        e.UpdateGroup()
        e.UpdateAllPower()
        e.GetHealthPercent()
        e.UpdateAllTotem()
        e.UpdateAuraFull()
    elseif event == "GROUP_ROSTER_UPDATE" then
        e.UpdateGroup()
    end
end
