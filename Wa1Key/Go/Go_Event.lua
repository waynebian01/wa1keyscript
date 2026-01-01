-- PLAYER_TARGET_CHANGED,PLAYER_MOUNT_DISPLAY_CHANGED,PLAYER_DEAD,PLAYER_ALIVE,PLAYER_UNGHOST,PLAYER_REGEN_DISABLED,PLAYER_REGEN_ENABLED,PLAYER_TALENT_UPDATE,UPDATE_SHAPESHIFT_FORM,UPDATE_STEALTH,PLAYER_ENTERING_WORLD,GROUP_ROSTER_UPDATE

function Go_Event(event, arg1)
    local e = aura_env
    if event == "PLAYER_TARGET_CHANGED" then
        e.targetCanAttack = UnitCanAttack("player", "target")
        e.targetisdead = UnitIsDeadOrGhost("target") -- 目标死亡
    elseif event == "UNIT_FACTION" and arg1 == "target" then
        e.targetCanAttack = UnitCanAttack("player", "target")
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        e.mounted = IsMounted("player")
    elseif event == "PLAYER_DEAD" then
        e.dead = UnitIsDeadOrGhost("player")
    elseif event == "PLAYER_ALIVE" then
        e.dead = UnitIsDeadOrGhost("player")
    elseif event == "PLAYER_UNGHOST" then
        e.dead = UnitIsDeadOrGhost("player")
    elseif event == "PLAYER_REGEN_DISABLED" then
        e.isCombat = true
        e.targetCanAttack = UnitCanAttack("player", "target")
    elseif event == "PLAYER_REGEN_ENABLED" then
        e.isCombat = false
    elseif event == "PLAYER_TALENT_UPDATE" then
        e.specIndex = C_SpecializationInfo.GetSpecialization()
        e.specID = C_SpecializationInfo.GetSpecializationInfo(e.specIndex)
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        e.shapeshiftFormID = GetShapeshiftFormID() -- 变形形态
        e.travel = e.travelNumber[e.shapeshiftFormID]
    elseif event == "UPDATE_STEALTH" then
        e.stealth = C_UnitAuras.GetPlayerAuraBySpellID(5215)
        e.vanish = C_UnitAuras.GetPlayerAuraBySpellID(11327)
        e.catStealth = e.shapeshiftFormID == 1 and e.stealth
    elseif event == "PLAYER_ENTERING_WORLD" then
        e.Go_Init()
    elseif event == "GROUP_ROSTER_UPDATE" then
        e.inParty = UnitPlayerOrPetInParty("player")
    end
end
