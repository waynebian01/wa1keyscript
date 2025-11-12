if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal then return end
if Skippy.state.class ~= "德鲁伊" or Skippy.state.specID ~= 105 then return end
if not Skippy.state.inRaid then return end
if not Skippy.Group or not Skippy.state.initialization then return Skippy.UnitHeal("Skip", "Skip") end

local state = Skippy.state
local player = Skippy.GetPlayerInfo()
local playerAuras = Skippy.GetPlayerAuras
local isKnown = Skippy.IsSpellKnown
local spell = Skippy.GetSpellInfo
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local manaPct = mana / manaMax * 100
local target = Skippy.Units.target
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")

local lowestUnit, lowestHealth = Skippy.GetLowestUnit() -- 生命值最低的单位
local averageHealthPct = Skippy.GetAverageHealthPct()
local hasVoidBurstUnit = Skippy.GetUnitWithPlayerAura("虚空爆炸")
local canSwiftmendUnit, canSwiftmendHealth = Skippy.GetLowestUnitWithAnyPlayerAuras({ "回春术", "愈合", "回春术（萌芽）", "野性成长" })
local regrowth, regrowthHealth = Skippy.GetLowestUnitWithoutPlayerAuras("愈合")
local rejuvenation1, rejuvenation1Health = Skippy.GetLowestUnitWithDifferentAuraCount({ "回春术", "回春术（萌芽）" }, 0)
local rejuvenation2, rejuvenation2Health = Skippy.GetLowestUnitWithDifferentAuraCount({ "回春术", "回春术（萌芽）" }, 1)

local rejuvenation = Skippy.GetLowestUnitWithAuraTableAndWithoutPlayerAuras(aura_env.raidDebuff, "回春术")

if channel then return Skippy.UnitHeal("None", "None") end

if playerAuras("自然迅捷") and spell("万灵之召").usable then
    return Skippy.UnitHeal("spell", "万灵之召")
end

if spell("繁盛").usable and not spell("万灵之召").usable then
    if spell("野性成长").usable and not state.isMoving then
        return Skippy.UnitHeal("spell", "野性成长")
    end
    return Skippy.UnitHeal("spell", "繁盛")
end

if state.isCombat and spell("甘霖").usable and player and player.healthPct <= 50 then
    return Skippy.UnitHeal("spell", "甘霖")
end

if spell("自然之愈").usable and hasVoidBurstUnit then
    return Skippy.UnitHeal(hasVoidBurstUnit, "纯净术")
end

if Skippy.GetCount(75) >= 5 then
    if spell("激活").usable and averageHealthPct <= 80 then
        return Skippy.UnitHeal("spell", "激活")
    end
    if spell("林莽卫士").cooldown == 0 then
        return Skippy.UnitHeal("spell", "林莽卫士")
    end
    if spell("自然迅捷").usable and casting ~= "愈合" then
        return Skippy.UnitHeal("spell", "自然迅捷")
    end
end

if playerAuras("自然迅捷") and lowestUnit then
    return Skippy.UnitHeal(lowestUnit, "万灵之召")
end

if spell("迅捷治愈").usable and canSwiftmendUnit and canSwiftmendHealth < 85 then
    return Skippy.UnitHeal(canSwiftmendUnit, "迅捷治愈")
end

if Skippy.GetCount(90) >= 2 then
    if spell("林莽卫士").cooldown == 0 and spell("林莽卫士").charges.currentCharges > 1 then
        return Skippy.UnitHeal("spell", "林莽卫士")
    end
    if spell("野性成长").usable and not state.isMoving then
        return Skippy.UnitHeal("spell", "野性成长")
    end
end

if spell("林莽卫士").cooldown == 0 and spell("林莽卫士").charges.currentCharges == 3 and lowestUnit then
    return Skippy.UnitHeal("spell", "林莽卫士")
end

if rejuvenation then -- 给有指定debuff的单位施放[回春术]
    return Skippy.UnitHeal(rejuvenation, "回春术")
end

if spell("愈合").usable and casting ~= "愈合" and regrowth and not state.isMoving then
    if playerAuras("节能施法") and regrowthHealth < 80 then
        return Skippy.UnitHeal(regrowth, "愈合")
    end
    if regrowth and regrowthHealth < 70 then
        return Skippy.UnitHeal(regrowth, "愈合")
    end
end

if not playerAuras("生命绽放") and spell("生命绽放").usable then
    return Skippy.UnitHeal("player", "生命绽放")
end

if rejuvenation1 and rejuvenation1Health < 85 then
    return Skippy.UnitHeal(rejuvenation1, "回春术")
end

if isKnown(155675) and rejuvenation2 and rejuvenation2Health < 70 then
    return Skippy.UnitHeal(rejuvenation2, "回春术")
end

if state.isCombat and target.canAttack then
    return Skippy.UnitHeal("Skip", "Skip")
end

return Skippy.UnitHeal("None", "None")
