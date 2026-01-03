-- UNIT_HEALTH, UNIT_MAXHEALTH, UNIT_HEAL_ABSORB_AMOUNT_CHANGED, UNIT_HEAL_PREDICTION, UNIT_AURA, UNIT_FACTION, PLAYER_TARGET_CHANGED, PLAYER_FOCUS_CHANGED, NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED, ENCOUNTER_START, ENCOUNTER_END, UNIT_IN_RANGE_UPDATE, UNIT_SPELLCAST_SENT, UI_ERROR_MESSAGE, PLAYER_ENTERING_WORLD, GROUP_ROSTER_UPDATE

function Unitinfo_event(event, arg1, arg2, arg3)   
    if event == "UNIT_HEALTH" and aura_env.GetUnitObj(arg1) then
        aura_env.UpdateHealth(arg1, "health", UnitHealth)
    elseif event == "UNIT_MAXHEALTH" and aura_env.GetUnitObj(arg1) then
        aura_env.UpdateHealth(arg1, "healthMax", UnitHealthMax)
    elseif event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" and aura_env.GetUnitObj(arg1) then
        aura_env.UpdateHealth(arg1, "healAbsorbs", UnitGetTotalHealAbsorbs)
    elseif event == "UNIT_HEAL_PREDICTION" and aura_env.GetUnitObj(arg1) then
        aura_env.UpdateHealth(arg1, "healPrediction", aura_env.GetIncomingHeals)
    elseif event == "UNIT_AURA" and aura_env.GetUnitObj(arg1) then
        aura_env.UpdateAuraIncremental(arg1, arg2)
    elseif event == "UNIT_FACTION" and aura_env.GetUnitObj(arg1) then
        aura_env.UpdateFaction(arg1)
    elseif event == "PLAYER_TARGET_CHANGED" then
        aura_env.UpdateCoreUnit("target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        aura_env.UpdateCoreUnit("focus")
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        aura_env.UpdateNameplateUnit(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        aura_env.UpdateNameplateUnit(arg1)
    elseif event == "ENCOUNTER_START" then
        aura_env.InitBossUnit()
    elseif event == "ENCOUNTER_END" then
        aura_env.InitBossUnit()
    elseif event == "UNIT_IN_RANGE_UPDATE" and aura_env.GetUnitObj(arg1) then
        aura_env.UpdateInRange(arg1, arg2)
    elseif event == "UI_ERROR_MESSAGE" and arg2 == "目标不在视野中" then
        aura_env.CheckUnitInsight()
    elseif event == "GROUP_ROSTER_UPDATE" then
        C_Timer.After(1, function()
            aura_env.UpdateGroupUnit()
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        aura_env.UpdateCoreUnit("target") -- 初始化目标
        aura_env.UpdateCoreUnit("focus")  -- 初始化焦点
        aura_env.InitNameplateUnit()      -- 初始化姓名板
        aura_env.UpdateGroupUnit()        -- 初始化队伍
    end
end
