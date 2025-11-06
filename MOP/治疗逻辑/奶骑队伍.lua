if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal then return end
if Skippy.state.class ~= "圣骑士" or Skippy.state.specID ~= 65 or not Skippy.state.inParty then return end
if not Skippy.Group or not Skippy.state.initialization then return Skippy.UnitHeal("Skip", "Skip") end

local currentTime = GetTime()
local state = Skippy.state
local castUnit = state.lastCastTargetUnit
local group = Skippy.Group
local target = Skippy.Units.target
local targetCanAttack = target.exists and target.canAttack
local playerAuras = Skippy.GetPlayerAuras
local isKnown = Skippy.IsSpellKnown
local spell = Skippy.GetSpellInfo
local insight = state.shapeshiftForm["洞察圣印"]
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100
local holyPower = state.power.HOLY_POWER[1]
local holyPowerMax = state.power.HOLY_POWER[2]

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noBeaconUnit, noBeaconHealth = Skippy.GetLowestUnitWithoutPlayerAuras("圣光道标")
local hasBeaconUnit, hasBeaconHealth = Skippy.GetUnitWithPlayerAura("圣光道标")
local selfless = playerAuras("无私治愈")

if not insight then
    return Skippy.UnitHeal("spell", "洞察圣印")
end

if spell("神圣恳求").usable and percentMana < 85 then
    return Skippy.UnitHeal("spell", "神圣恳求")
end

if playerAuras("神圣复仇者") and holyPower >= 3 and lowestUnit then
    return Skippy.UnitHeal(lowestUnit, "荣耀圣令")
end

if playerAuras("神圣意志") and lowestUnit then
    return Skippy.UnitHeal(lowestUnit, "荣耀圣令")
end

if selfless and selfless.applications == 3 then
    if Skippy.GetCount(90) >= 3 then
        return Skippy.UnitHeal(lowestUnit, "圣光普照")
    elseif lowestUnit then
        return Skippy.UnitHeal(lowestUnit, "神圣之光")
    end
end

if spell("荣耀圣令").usable and lowestUnit then
    if holyPower == holyPowerMax and lowestUnit then
        return Skippy.UnitHeal(lowestUnit, "荣耀圣令")
    end
end

if state.isCombat and spell("神圣棱镜").usable and targetCanAttack and Skippy.GetCount(90) >= 3 then
    return Skippy.UnitHeal("target", "神圣棱镜")
end

if spell("神圣震击").usable and lowestUnit then
    return Skippy.UnitHeal(lowestUnit, "神圣震击")
end

if state.isCombat and isKnown(85804) and spell("审判").usable and targetCanAttack then
    return Skippy.UnitHeal("target", "审判")
end

if spell("荣耀圣令").usable and holyPower >= 3 and lowestUnit and lowestHealth < 70 then
    return Skippy.UnitHeal(lowestUnit, "荣耀圣令")
end

if not state.isMoving then
    if spell("圣光闪现").usable and lowestUnit and lowestHealth < 50 then
        return Skippy.UnitHeal(lowestUnit, "圣光闪现")
    end

    if spell("神圣之光").usable and lowestUnit and lowestHealth < 60 then
        return Skippy.UnitHeal(lowestUnit, "神圣之光")
    end

    if spell("圣光术").usable and lowestUnit then
        if noBeaconUnit and noBeaconHealth < 90 then
            return Skippy.UnitHeal(noBeaconUnit, "圣光术")
        end
        if lowestUnit and lowestHealth < 90 then
            return Skippy.UnitHeal(lowestUnit, "圣光术")
        end
    end
end

if state.isCombat and spell("十字军打击").usable and C_Spell.IsSpellInRange("十字军打击", "target") and targetCanAttack then
    return Skippy.UnitHeal("target", "十字军打击")
end

return Skippy.UnitHeal("None", "None")
