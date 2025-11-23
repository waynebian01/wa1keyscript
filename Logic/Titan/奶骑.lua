if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal or not Skippy.state.initialization then return end
if Skippy.state.class ~= "圣骑士" then return end
if not Skippy.state.inParty then return Skippy.UnitHeal("Skip", "Skip") end

-- ===== 状态 =====
local state = Skippy.state
local target = Skippy.Units.target
local targetCanAttack = target.exists and target.canAttack
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100

-- ===== 变量 =====
local UnitHeal = Skippy.UnitHeal
local spell = Skippy.GetSpellInfo
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local count90 = Skippy.GetCount(90)
local PlayersLight = Skippy.GetTargetAurasByPlayer("圣光审判")
local beaconUnit, beaconAura = Skippy.GetUnitAndAuraWithPlayerAura("圣光道标")
local holyshieldUnit, holyshieldAura = Skippy.GetUnitAndAuraWithPlayerAura(53601)
local noBeaconUnit, noBeaconHealth = Skippy.GetLowestUnitWithoutPlayerAuras("圣光道标")
local hasBeaconUnit, hasBeaconHealth = Skippy.GetLowestUnitWithPlayerAura("圣光道标")
local SealofWisdom = Skippy.GetPlayerAuras("智慧圣印")
local InfusionofLight = Skippy.GetPlayerAuras("圣光灌注")
local DivineFavor = Skippy.GetPlayerAuras("神恩术")
local hasMagicUnit = Skippy.GetUnitHasDebuffWithdispelName("Magic")
local hasDiseaseUnit = Skippy.GetUnitHasDebuffWithdispelName("Disease")
local hasPoisonUnit = Skippy.GetUnitHasDebuffWithdispelName("Poison")

-- ===== 逻辑 =====
if not lowestUnit and state.cast and state.castInfo then
    if state.castInfo.endTimeMS / 1000 - GetTime() < 0.4 then
        return UnitHeal("spell", "停止施法")
    end
end

if spell("纯净术").usable then
    if hasDiseaseUnit then
        return UnitHeal(hasDiseaseUnit, "纯净术")
    end
    if hasPoisonUnit then
        return UnitHeal(hasPoisonUnit, "纯净术")
    end
end

if spell("清洁术").usable then
    if hasMagicUnit then
        return UnitHeal(hasMagicUnit, "清洁术")
    end
end

-- [智慧圣印]未激活时使用[智慧圣印]
if spell("智慧圣印").usable and not SealofWisdom then
    return UnitHeal("spell", "智慧圣印")
end

-- 魔法值低于85%时使用[神圣恳求]
if spell("神圣恳求").usable and percentMana < 85 and not state.isCombat then
    return UnitHeal("spell", "神圣恳求")
end

-- 圣光道标即将消失时使用[圣光道标]
if beaconUnit and beaconAura and beaconAura.expirationTime - GetTime() < 4 then
    return UnitHeal(beaconUnit, "圣光道标")
end

-- 圣洁护盾即将消失时使用[圣洁护盾]
if holyshieldUnit and holyshieldAura and holyshieldAura.expirationTime - GetTime() < 4 then
    return UnitHeal(holyshieldUnit, "圣洁护盾")
end

-- 可以攻击目标时使用[审判]
if state.isCombat and spell("圣光审判").usable and targetCanAttack and not PlayersLight then
    return UnitHeal("target", "圣光审判")
end

if spell("神恩术").usable and lowestHealth < 50 and not DivineFavor then
    return UnitHeal("spell", "神恩术")
end

-- 非移动状态时使用[圣光闪现]、[神圣震击]或[圣光术]
if hasBeaconUnit and noBeaconUnit then
    if spell("神圣震击").usable and lowestHealth < 80 then
        return UnitHeal(noBeaconUnit, "神圣震击")
    end
    if InfusionofLight and lowestHealth < 85 then
        return UnitHeal(noBeaconUnit, "圣光闪现")
    end
    if spell("圣光术").usable and lowestHealth < 60 and not state.isMoving then
        return UnitHeal(noBeaconUnit, "圣光术")
    end
    if spell("圣光闪现").usable and lowestHealth < 85 and not state.isMoving then
        return UnitHeal(noBeaconUnit, "圣光闪现")
    end
end

if lowestUnit then
    if spell("神圣震击").usable and lowestHealth < 80 then
        return UnitHeal(lowestUnit, "神圣震击")
    end
    if InfusionofLight and lowestHealth < 85 then
        return UnitHeal(lowestUnit, "圣光闪现")
    end
    if spell("圣光术").usable and lowestHealth < 60 and not state.isMoving then
        return UnitHeal(lowestUnit, "圣光术")
    end
    if spell("圣光闪现").usable and lowestHealth < 85 and not state.isMoving then
        return UnitHeal(lowestUnit, "圣光闪现")
    end
end

-- 可以攻击目标时使用[审判]
if state.isCombat and spell("圣光审判").usable and targetCanAttack then
    return UnitHeal("target", "圣光审判")
end

return UnitHeal("None", "None")
