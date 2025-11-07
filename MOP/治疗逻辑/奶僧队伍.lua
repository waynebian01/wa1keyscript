if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal then return end
if Skippy.state.class ~= "武僧" or Skippy.state.specID ~= 270 or not Skippy.state.inParty then return end
if not Skippy.Group or not Skippy.state.initialization then return Skippy.UnitHeal("Skip", "Skip") end

local currentTime = GetTime()
local state = Skippy.state
local castUnit = state.lastCastTargetUnit
local group = Skippy.Group
local target = Skippy.Units.target
local targetCanAttack = target.exists and target.canAttack and C_Spell.IsSpellInRange("猛虎掌", "target")
local player = Skippy.Group.player
local playerAuras = Skippy.GetPlayerAuras
local isKnown = Skippy.IsSpellKnown
local spell = Skippy.GetSpellInfo
local channeling = UnitChannelInfo("player")
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100
local enemyCount = Skippy.GetEnemyCount(8)
local chi = state.power.CHI[1]
local chiMax = state.power.CHI[2]
local BlackoutKick = isKnown(100784) and chi >= 2
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noZenUnit, noZenHealth = Skippy.GetLowestUnitWithoutPlayerAuras("禅意珠")
local noZenTank = Skippy.GetUnitWithoutAuraAndRole("禅意珠", "TANK")
local SoothingUnit, SoothingHealth = Skippy.GetUnitWithPlayerAura("抚慰之雾")
local noSoothingUnit, noSoothingHealth = Skippy.GetLowestUnitWithoutPlayerAuras("抚慰之雾")
local vital = playerAuras("活力之雾") and playerAuras("活力之雾").applications == 5

if spell("禅意珠").usable then
    if noZenTank then
        return Skippy.UnitHeal(noZenTank, "禅意珠")
    end
    if noZenUnit then
        return Skippy.UnitHeal(noZenUnit, "禅意珠")
    end
end

if chi < chiMax then
    if spell("移花接木").usable then
        return Skippy.UnitHeal("spell", "移花接木")
    end
    if lowestUnit then
        if spell("复苏之雾").usable then
            return Skippy.UnitHeal(lowestUnit, "复苏之雾")
        end
        if spell("升腾之雾").usable and vital then
            return Skippy.UnitHeal(lowestUnit, "升腾之雾")
        end
    end
end

if spell("真气波").usable and lowestUnit then
    return Skippy.UnitHeal(lowestUnit, "真气波")
end

if spell("真气爆裂").usable and state.isCombat then
    return Skippy.UnitHeal("spell", "真气爆裂")
end

if spell("抚慰之雾").usable then
    if channeling and channeling == "抚慰之雾" then
        if SoothingUnit and SoothingHealth < 50 then
            if spell("氤氲之雾").usable then
                return Skippy.UnitHeal(SoothingUnit, "氤氲之雾")
            end
            if spell("升腾之雾").usable then
                return Skippy.UnitHeal(SoothingUnit, "升腾之雾")
            end
        end
        if noSoothingUnit and noSoothingHealth < 50 then
            return Skippy.UnitHeal(noSoothingUnit, "抚慰之雾")
        end
        if lowestUnit and lowestHealth < 80 then
            return Skippy.UnitHeal("None", "None")
        end
    elseif lowestUnit and lowestHealth < 50 then
        return Skippy.UnitHeal(lowestUnit, "抚慰之雾")
    end
end

if targetCanAttack then
    if playerAuras("熟能生巧") then
        if not playerAuras("青龙之忱") then
            if BlackoutKick then -- 幻灭踢
                return Skippy.UnitHeal("target", "幻灭踢")
            else
                return Skippy.UnitHeal("target", "贯日击")
            end
        elseif chi >= 1 then
            if BlackoutKick and enemyCount >= 3 then -- 幻灭踢
                return Skippy.UnitHeal("target", "幻灭踢")
            end
            if playerAuras("活力之雾") then
                if playerAuras("活力之雾").applications < 5 then
                    return Skippy.UnitHeal("target", "猛虎掌")
                else
                    return Skippy.UnitHeal("player", "升腾之雾")
                end
            else
                return Skippy.UnitHeal("target", "猛虎掌")
            end
        end
    else
        if chi < chiMax then
            return Skippy.UnitHeal("target", "贯日击")
        else
            if BlackoutKick and (not playerAuras("青龙之忱") or enemyCount >= 3) then
                return Skippy.UnitHeal("target", "幻灭踢")
            end
            return Skippy.UnitHeal("target", "猛虎掌")
        end
    end
end

return Skippy.UnitHeal("None", "None")
