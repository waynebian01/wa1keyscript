if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal then return end
if not Skippy.Group or not Skippy.state.inRaid or not Skippy.state.initialization then
    return Skippy.UnitHeal("None", "None")
end
local currentTime = GetTime()
local state = Skippy.state
local castUnit = state.lastCastTargetUnit
local playerAuras = Skippy.Units.player.aura.byPlayer
local raid = Skippy.Group
local isKnown = Skippy.IsSpellKnown
local spell = Skippy.GetSpellInfo
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noRiptideUnit = Skippy.GetLowestUnitWithoutPlayerAuras("激流")
local hasRiptideUnit, hasRiptideHealth = Skippy.GetLowestUnitWithPlayerAura("激流")
local noRiptideTank = Skippy.GetLowestUnitWithoutPlayerAurasAndRole("激流", "TANK")
local noShieldTank = Skippy.GetUnitWithoutPlayerAurasAndRole("大地之盾", "TANK")

if state.isCombat then
    if isKnown(157153) then
        if spell("收回图腾").usable and spell(157153).charges.currentCharges == 0 then
            return Skippy.UnitHeal("spell", "收回图腾")
        end
        if spell(157153).charges.currentCharges > 0 and not playerAuras["暴雨图腾"] then
            return Skippy.UnitHeal("spell", "暴雨图腾")
        end
    end
    if spell("先祖迅捷").usable and lowestUnit and not playerAuras["先祖迅捷"] then
        return Skippy.UnitHeal("spell", "先祖迅捷")
    end
end

if isKnown(1217598) then
    if spell("激流").usable then
        if noRiptideUnit then
            return Skippy.UnitHeal(noRiptideUnit, "激流")
        end
        if noRiptideTank then
            return Skippy.UnitHeal(noRiptideTank, "激流")
        end
    end

    if playerAuras["波动"] and lowestUnit then
        return Skippy.UnitHeal(lowestUnit, "治疗波")
    end

    if playerAuras["灵魂行者的潮汐图腾"] and lowestUnit then
        return Skippy.UnitHeal(lowestUnit, "治疗之涌")
    end

    if state.cast then
        if castUnit then
            local unitTemp, healthTemp = Skippy.GetLowestUnitWithoutUnit(castUnit)
            local castHealth = raid[castUnit].percentHealth
            if unitTemp then
                if castHealth + 10 < healthTemp then
                    return Skippy.UnitHeal(castUnit, "治疗波")
                else
                    return Skippy.UnitHeal(unitTemp, "治疗波")
                end
            end
        end
    else
        if hasRiptideUnit then
            return Skippy.UnitHeal(hasRiptideUnit, "治疗波")
        end
        if lowestUnit then
            return Skippy.UnitHeal(lowestUnit, "治疗波")
        end
    end
end

if spell("大地之盾").usable then
    if not playerAuras["大地之盾"] then
        return Skippy.UnitHeal("player", "大地之盾")
    end
    if isKnown(383010) and noShieldTank and Skippy.GetCountWithPlayerAura(200, "大地之盾") < 2 then
        return Skippy.UnitHeal(noShieldTank, "大地之盾")
    end
end

return Skippy.UnitHeal("None", "None")
