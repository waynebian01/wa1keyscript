if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal then return end
if Skippy.state.class ~= "德鲁伊" or Skippy.state.specID ~= 105 then return end
if not Skippy.state.inParty then return end
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
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noLifebloomTank = Skippy.GetUnitWithoutPlayerAurasAndRole("生命绽放", "TANK")
local hasLifebloomUnit, hasLifebloomAura = Skippy.GetUnitAndAuraWithPlayerAura("生命绽放")
local canSwiftmendUnit, canSwiftmendHealth = Skippy.GetLowestUnitWithAnyPlayerAuras({ "回春术", "愈合" })
local noRejuvenation, noRejuvenationHealth = Skippy.GetLowestUnitWithoutPlayerAuras("回春术")

local Forest = playerAuras("丛林之魂")
local clearCast = playerAuras("节能施法")

if spell("野性成长").usable and Skippy.GetCount(90) >= 2 then
    return Skippy.UnitHeal("spell", "野性成长")
end

if spell("生命绽放").usable then
    if noLifebloomTank then
        return Skippy.UnitHeal(noLifebloomTank, "生命绽放")
    end
    if hasLifebloomUnit and hasLifebloomAura then
        if Forest or hasLifebloomAura.expirationTime - currentTime < 3 then
            return Skippy.UnitHeal(hasLifebloomUnit, "生命绽放")
        end
    end
end

if spell("自然迅捷").cooldown == 0 and not playerAuras("自然迅捷") and lowestUnit and lowestHealth < 50 then
    return Skippy.UnitHeal("spell", "自然迅捷")
end

if spell("迅捷治愈").cooldown <= 1 and canSwiftmendUnit and canSwiftmendHealth < 85 then
    return Skippy.UnitHeal(canSwiftmendUnit, "迅捷治愈")
end

if spell("愈合").usable and lowestUnit then
    if lowestHealth < 50 or (clearCast and lowestHealth < 70) then
        return Skippy.UnitHeal(lowestUnit, "愈合")
    end
end

if spell("回春术").usable and noRejuvenation and noRejuvenationHealth < 90 then
    return Skippy.UnitHeal(noRejuvenation, "回春术")
end

if spell("治疗之触").usable and lowestUnit and lowestHealth < 60 then
    return Skippy.UnitHeal(lowestUnit, "治疗之触")
end

if spell("滋养").usable and lowestUnit and lowestHealth < 70 then
    return Skippy.UnitHeal(lowestUnit, "滋养")
end

if spell("生命绽放").usable and hasLifebloomUnit and hasLifebloomAura and hasLifebloomAura.applications < 3 then
    return Skippy.UnitHeal(hasLifebloomUnit, "生命绽放")
end

return Skippy.UnitHeal("None", "None")
