-- COMBAT_LOG_EVENT_UNFILTERED, UNIT_HEALTH, UNIT_MAXHEALTH, UNIT_HEAL_ABSORB_AMOUNT_CHANGED, UNIT_HEAL_PREDICTION, UNIT_AURA, UNIT_FACTION, PLAYER_TARGET_CHANGED, PLAYER_FOCUS_CHANGED, NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED, ENCOUNTER_START, ENCOUNTER_END, UNIT_IN_RANGE_UPDATE, UNIT_SPELLCAST_SENT, UI_ERROR_MESSAGE, PLAYER_ENTERING_WORLD, GROUP_ROSTER_UPDATE

function Unitinfo_event(event, arg1, arg2, arg3)
    local e = aura_env
    if event == "UNIT_HEALTH" and e.All_Units[arg1] then
        e.UpdateHealth(arg1, "health", UnitHealth)
    elseif event == "UNIT_MAXHEALTH" and e.All_Units[arg1] then
        e.UpdateHealth(arg1, "maxHealth", UnitHealthMax)
    elseif event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" and e.All_Units[arg1] then
        e.UpdateHealth(arg1, "healAbsorbs", UnitGetTotalHealAbsorbs)
    elseif event == "UNIT_HEAL_PREDICTION" and e.All_Units[arg1] then
        e.UpdateHealth(arg1, "healPrediction", aura_env.GetIncomingHeals)
    elseif event == "UNIT_AURA" and e.All_Units[arg1] then
        e.UpdateAuraIncremental(arg1, arg2)
    elseif event == "UNIT_FACTION" and e.All_Units[arg1] then
        e.UpdateFaction(arg1)
    elseif event == "PLAYER_TARGET_CHANGED" then
        e.UpdateCoreUnit("target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        e.UpdateCoreUnit("focus")
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        e.UpdateNameplateUnit(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        Skippy.Nameplate[arg1] = { exists = false }
    elseif event == "ENCOUNTER_START" then
        e.UpdateBossUnit()
    elseif event == "ENCOUNTER_END" then
        e.UpdateBossUnit()
    elseif event == "UNIT_IN_RANGE_UPDATE" and e.All_Units[arg1] then
        if WeakAuras.IsRetail() then e.UpdateInRange(arg1, arg2) end
    elseif event == "UI_ERROR_MESSAGE" and arg2 == "目标不在视野中" then
        if Skippy.state.CastTargetUnit then
            local obj = Skippy.Group[Skippy.state.CastTargetUnit]
            if obj then
                obj.inSight = false
                if obj.inSightTimer then
                    obj.inSightTimer:Cancel()
                    obj.inSightTimer = nil
                end
                obj.inSightTimer = C_Timer.NewTimer(2, function()
                    obj.inSight = true
                    obj.inSightTimer = nil
                end)
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        e.InitUnitMapping()
        e.InitGroupMembers()
        e.UpdateAllUnits()
    end
end
