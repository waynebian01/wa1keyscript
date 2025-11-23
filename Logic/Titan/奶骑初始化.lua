aura_env.BeaconUnit = nil
aura_env.ShieldUnit = nil
aura_env.seal = { "命令圣印", "腐蚀圣印", "复仇圣印", }

function aura_env.GetUnitAuraBySpellId(unit, spellId)
    if not Skippy.Group then return nil end
    local data = Skippy.Group[unit]
    if data and data.inRange and data.canAssist and data.inSight and not data.isDead then
        for _, aura in pairs(data.aura) do
            if aura.sourceUnit == "player" and aura.spellId == spellId then
                return aura
            end
        end
    end
    return nil
end

function aura_env.SetUnitByName(name, spellName)
    if not Skippy.Group then return nil end
    for unit, data in pairs(Skippy.Group) do
        if data and data.name == name then
            if spellName == "Beacon" then
                aura_env.BeaconUnit = unit
            end
            if spellName == "Shield" then
                aura_env.ShieldUnit = unit
            end
        end
    end
end

--=======以下事件===========
function BeaconUnit(event, unit, target, castGUID, spellID)
    if event == "UNIT_SPELLCAST_SENT" and unit == "player" then
        if spellID == 53563 then
            aura_env.SetUnitByName(target, "Beacon")
        end
        if spellID == 53601 then
            aura_env.SetUnitByName(target, "Shield")
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
    end
end
