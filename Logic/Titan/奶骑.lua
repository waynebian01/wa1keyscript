if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal or not Skippy.state.initialization then return end
if Skippy.state.class ~= "圣骑士" then return end
if not Skippy.state.inParty then return Skippy.UnitHeal("Skip", "Skip") end

-- ===== 状态 =====
local e = aura_env
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
local PlayersLight = Skippy.GetTargetAurasByPlayer("圣光审判")
local noBeaconUnit, noBeaconHealth = Skippy.GetLowestUnitWithoutPlayerAuras("圣光道标")
local hasBeaconUnit, hasBeaconHealth = Skippy.GetLowestUnitWithPlayerAura("圣光道标")
local SealofWisdom = Skippy.GetPlayerAuras("智慧圣印")
local InfusionofLight = Skippy.GetPlayerAuras("圣光灌注")
local DivineFavor = Skippy.GetPlayerAuras("神恩术")
local hasMagicUnit = Skippy.GetUnitHasDebuffWithdispelName("Magic")
local hasDiseaseUnit = Skippy.GetUnitHasDebuffWithdispelName("Disease")
local hasPoisonUnit = Skippy.GetUnitHasDebuffWithdispelName("Poison")

-- ===== 逻辑 =====
-- 当没有受伤单位时，正在施法，将会在最后0.2秒停止施法
if not lowestUnit and state.cast and state.castInfo then
    if (state.castInfo.name == "圣光术" or state.castInfo.name == "圣光闪现") and state.castInfo.endTimeMS / 1000 - GetTime() < 0.2 then
        return UnitHeal("spell", "停止施法")
    end
end

-- 驱散疾病、中毒
if spell("纯净术").usable then
    if hasDiseaseUnit then
        return UnitHeal(hasDiseaseUnit, "纯净术")
    end
    if hasPoisonUnit then
        return UnitHeal(hasPoisonUnit, "纯净术")
    end
end

-- 驱散魔法
if spell("清洁术").usable and hasMagicUnit then
    return UnitHeal(hasMagicUnit, "清洁术")
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
if e.BeaconUnit and Skippy.IsUnitCanAssist(e.BeaconUnit) then
    local aura = e.GetUnitAuraBySpellId(e.BeaconUnit, 53563)
    if aura then
        if aura.expirationTime - GetTime() < 3 then
            return UnitHeal(e.BeaconUnit, "圣光道标")
        end
    else
        return UnitHeal(e.BeaconUnit, "圣光道标")
    end
end

-- 圣洁护盾即将消失时使用[圣洁护盾]
if e.ShieldUnit and Skippy.IsUnitCanAssist(e.ShieldUnit) then
    local aura = e.GetUnitAuraBySpellId(e.ShieldUnit, 53601)
    if aura then
        if aura.expirationTime - GetTime() < 3 then
            return UnitHeal(e.ShieldUnit, "圣洁护盾")
        end
    else
        return UnitHeal(e.ShieldUnit, "圣洁护盾")
    end
end

-- 可以攻击目标时，且目标没有来自于玩家的[圣光审判]时使用[圣光审判]
if state.isCombat and spell("圣光审判").usable and targetCanAttack and not PlayersLight then
    return UnitHeal("target", "圣光审判")
end

-- 神恩术，当有单位生命值低于50%时使用[神恩术]
if spell("神恩术").usable and lowestHealth < 50 and not DivineFavor then
    return UnitHeal("spell", "神恩术")
end

-- 有[圣光道标]时对没有[圣光道标]的单位使用[神圣震击]、[圣光闪现]、[圣光术]
if hasBeaconUnit and noBeaconUnit then
    if spell("神圣震击").usable and lowestHealth < 80 then
        return UnitHeal(noBeaconUnit, "神圣震击")
    end
    if InfusionofLight and lowestHealth < 85 then
        return UnitHeal(noBeaconUnit, "圣光闪现")
    end
    if not state.isMoving then
        if spell("圣光术").usable and lowestHealth < 60 then
            return UnitHeal(noBeaconUnit, "圣光术")
        end
        if spell("圣光闪现").usable and lowestHealth < 85 then
            return UnitHeal(noBeaconUnit, "圣光闪现")
        end
    end
end

-- 没有[圣光道标]时对所有单位使用[神圣震击]、[圣光闪现]、[圣光术]
if lowestUnit then
    if spell("神圣震击").usable and lowestHealth < 80 then
        return UnitHeal(lowestUnit, "神圣震击")
    end
    if InfusionofLight and lowestHealth < 85 then
        return UnitHeal(lowestUnit, "圣光闪现")
    end
    if not state.isMoving then
        if spell("圣光术").usable and lowestHealth < 60 then
            return UnitHeal(lowestUnit, "圣光术")
        end
        if spell("圣光闪现").usable and lowestHealth < 85 then
            return UnitHeal(lowestUnit, "圣光闪现")
        end
    end
end

-- 可以攻击目标时使用[审判]
if state.isCombat and spell("圣光审判").usable and targetCanAttack then
    return UnitHeal("target", "圣光审判")
end

return UnitHeal("None", "None")
