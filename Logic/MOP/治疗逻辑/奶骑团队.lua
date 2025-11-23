if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal or not Skippy.state.initialization then return end
if Skippy.state.class ~= "圣骑士" or Skippy.state.specID ~= 65 then return end
if not Skippy.state.inParty then return Skippy.UnitHeal("Skip", "Skip") end

-- ===== 状态 =====
local state = Skippy.state
local target = Skippy.Units.target
local targetCanAttack = target.exists and target.canAttack
local insight = state.shapeshiftForm["洞察圣印"]
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100
local holyPower = state.power.HOLY_POWER[1]
local holyPowerMax = state.power.HOLY_POWER[2]

-- ===== 变量 =====
local UnitHeal = Skippy.UnitHeal
local spell = Skippy.GetSpellInfo
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local count90 = Skippy.GetCount(90)
local noBeaconUnit, noBeaconHealth = Skippy.GetLowestUnitWithoutPlayerAuras("圣光道标")
local noSacredShieldTank = Skippy.GetUnitWithoutPlayerAurasAndRole("圣洁护盾", "TANK")
local DivinePurpose = Skippy.GetPlayerAuras("神圣意志")
local SelflessHealer = Skippy.IsSpellKnown(85804) -- 是否学会[无私治愈]
local SelflessAura = Skippy.GetPlayerAuras("无私治愈")
local EternalFlame = Skippy.IsSpellKnown(114163)  -- 是否学会[永恒之火]
local SealofInsight = Skippy.IsSpellKnown(20167)  -- 是否学会[洞察圣印]
local HolyAvenger = Skippy.GetPlayerAuras("神圣复仇者")

-- ===== 逻辑 =====
-- [洞察圣印]未激活时使用[洞察圣印]
if SealofInsight and not insight then
    return UnitHeal("spell", "洞察圣印")
end
-- 魔法值低于85%时使用[神圣恳求]
if spell("神圣恳求").usable and percentMana < 85 then
    return UnitHeal("spell", "神圣恳求")
end
-- 对没有[圣洁护盾]的坦克使用[圣洁护盾]
if spell("圣洁护盾").usable and noSacredShieldTank then
    return UnitHeal(noSacredShieldTank, "圣洁护盾")
end
-- 检测到光环[神圣复仇者]且圣能大于等于3，或者光环[神圣意志]
if (HolyAvenger and holyPower >= 3) or DivinePurpose then
    -- 如果没有学会永恒之火，受伤人数大于等于3时使用[黎明圣光]
    if not EternalFlame and spell("黎明圣光").usable and count90 >= 4 then
        return UnitHeal("spell", "黎明圣光")
    end
    -- 否则使用[荣耀圣令]
    if spell("荣耀圣令").usable and lowestUnit then
        return UnitHeal(lowestUnit, "荣耀圣令")
    end
end
-- 检测到光环[无私治愈]且应用次数为3时使用[圣光普照]或[神圣之光]
if SelflessAura and SelflessAura.applications == 3 then
    if spell("圣光普照").usable and count90 >= 3 then
        return UnitHeal(lowestUnit, "圣光普照")
    elseif spell("神圣之光").usable and lowestUnit then
        return UnitHeal(lowestUnit, "神圣之光")
    end
end
-- 圣能等于最大值时使用[荣耀圣令]
if holyPower == holyPowerMax then
    -- 如果没有学会永恒之火，受伤人数大于等于3时使用[黎明圣光]
    if not EternalFlame and spell("黎明圣光").usable and count90 >= 4 then
        return UnitHeal("spell", "黎明圣光")
    end
    -- 否则使用[荣耀圣令]
    if spell("荣耀圣令").usable and lowestUnit then
        return UnitHeal(lowestUnit, "荣耀圣令")
    end
end
-- 检测到神圣棱镜可用且有治疗目标且圣能大于等于3时使用[神圣棱镜]
if state.isCombat and spell("神圣棱镜").usable and targetCanAttack and count90 >= 3 then
    return UnitHeal("target", "神圣棱镜")
end
-- 检测到神圣震击可用且有治疗目标时使用[神圣震击]
if spell("神圣震击").usable and lowestUnit then
    return UnitHeal(lowestUnit, "神圣震击")
end
-- 学会了天赋[无私治愈]，可以攻击目标时使用[审判]
if state.isCombat and SelflessHealer and spell("审判").usable and targetCanAttack then
    return UnitHeal("target", "审判")
end
-- 圣能大于等于3且治疗目标生命值低于70%时使用[荣耀圣令]
if spell("荣耀圣令").usable and holyPower >= 3 and lowestUnit and lowestHealth < 70 then
    return UnitHeal(lowestUnit, "荣耀圣令")
end
-- 非移动状态时使用[圣光闪现]、[神圣之光]或[圣光术]
if not state.isMoving then
    if spell("圣光闪现").usable and lowestUnit and lowestHealth < 50 then
        return UnitHeal(lowestUnit, "圣光闪现")
    end
    if spell("神圣之光").usable and lowestUnit and lowestHealth < 60 then
        return UnitHeal(lowestUnit, "神圣之光")
    end
    -- 使用[圣光术],优先为没有[圣光道标]的单位治疗
    if spell("圣光术").usable and lowestUnit then
        if noBeaconUnit and noBeaconHealth < 90 then
            return UnitHeal(noBeaconUnit, "圣光术")
        end
        if lowestUnit and lowestHealth < 90 then
            return UnitHeal(lowestUnit, "圣光术")
        end
    end
end
-- 战斗中，[十字军打击]可用时使用[十字军打击]
if state.isCombat and spell("十字军打击").usable and C_Spell.IsSpellInRange("十字军打击", "target") and targetCanAttack then
    return UnitHeal("target", "十字军打击")
end

return UnitHeal("None", "None")
