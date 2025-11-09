if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal then return end
if Skippy.state.class ~= "牧师" or Skippy.state.specID ~= 257 or not Skippy.state.inRaid then return end
if not Skippy.Group or not Skippy.state.initialization then return Skippy.UnitHeal("Skip", "Skip") end

local state = Skippy.state
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local inRange = C_Spell.IsSpellInRange(585, "target")
local spell = Skippy.GetSpellInfo
local isKnown = Skippy.IsSpellKnown
local player = Skippy.GetPlayerInfo()
local playerAura = Skippy.GetPlayerAuras
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local manaPct = mana / manaMax * 100
local target = Skippy.Units.target
local targetCanAttack = target.exists and target.canAttack and inRange
local Rhapsody = playerAura("狂想曲") and playerAura("狂想曲").applications == 20
local enemyCount = Skippy.GetEnemyCount(10)
local hasVoidBurstUnit = Skippy.GetUnitWithPlayerAura("虚空爆炸")
local averageHealthPct = Skippy.GetAverageHealthPct()

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local hasMendingUnit, hasMendingHealth = Skippy.GetLowestUnitWithPlayerAura("愈合祷言")
local noMendingUnit, noMendingHealth = Skippy.GetLowestUnitWithoutPlayerAuras("愈合祷言")
local noRenewTank = Skippy.GetUnitWithoutPlayerAurasAndRole("恢复", "TANK")
local noRenewUnit, noRenewHealth = Skippy.GetLowestUnitWithoutPlayerAuras("恢复")
local count90 = Skippy.GetCount(90)

if channel then return Skippy.UnitHeal("None", "None") end
if playerAura("救赎之魂") then player.isDead = true end

if spell("绝望祷言").usable and Skippy.state.healthPct <= 50 then
    return Skippy.UnitHeal("spell", "绝望祷言")
end

if state.isCombat then
    if manaPct < 90 then
        if spell("奥术洪流").usable then
            return Skippy.UnitHeal("spell", "奥术洪流")
        end
        if spell("暗影魔").usable and targetCanAttack then
            return Skippy.UnitHeal("target", "暗影魔")
        end
    end
    if player and player.healthPct <= 80 then
        if spell("渐隐术").usable then
            return Skippy.UnitHeal("spell", "渐隐术")
        end
        if isKnown["天使壁垒"] and not playerAura("防护圣光") and casting ~= "快速治疗" then
            return Skippy.UnitHeal("player", "快速治疗")
        end
        if spell("神圣新星").usable and Rhapsody then
            return Skippy.UnitHeal("spell", "神圣新星")
        end
        if spell("快速治疗").usable and playerAura("圣光涌动") then
            return Skippy.UnitHeal("player", "快速治疗")
        end
    end

    if spell("纯净术").usable and hasVoidBurstUnit then
        return Skippy.UnitHeal(hasVoidBurstUnit, "纯净术")
    end

    if spell("神圣新星").usable and Rhapsody and enemyCount >= 1 then
        return Skippy.UnitHeal("spell", "神圣新星")
    end

    if spell("预兆").usable and spell("愈合祷言").usable then
        if not playerAura("洞察预兆") and Skippy.GetCount(80) >= 3 then
            return Skippy.UnitHeal("spell", "预兆")
        end
    end

    if spell("神圣化身").usable and (averageHealthPct <= 80 or Skippy.GetCount(75) >= 10) then
        if spell("圣言术：静").charges.currentCharges < 2 and spell("圣言术：灵").charges.currentCharges < 2 then
            return Skippy.UnitHeal("spell", "神圣化身")
        end
    end
end

if spell("愈合祷言").usable then
    if noMendingUnit and noMendingHealth <= 80 then
        return Skippy.UnitHeal(noMendingUnit, "愈合祷言")
    end
    if lowestUnit and lowestHealth <= 80 then
        return Skippy.UnitHeal(lowestUnit, "愈合祷言")
    end
    if hasMendingUnit and hasMendingHealth <= 80 then
        return Skippy.UnitHeal(hasMendingUnit, "愈合祷言")
    end
    return Skippy.UnitHeal(noMendingUnit, "愈合祷言")
end

if spell("恢复").usable and isKnown["恢复增效"] then
    if noRenewUnit then
        return Skippy.UnitHeal(noRenewUnit, "恢复")
    end
    if noRenewTank then
        return Skippy.UnitHeal(noRenewTank, "恢复")
    end
end

if spell("光晕").usable and count90 >= 5 then
    return Skippy.UnitHeal("spell", "光晕")
end

if spell("治疗祷言").usable and playerAura("分秒必争") and count90 >= 5 then
    return Skippy.UnitHeal(lowestUnit, "治疗祷言")
end

if spell("圣言术：灵").usable then
    if count90 >= 5 then
        if not isKnown["祷言之环"] then
            return Skippy.UnitHeal("macro", "圣言术：灵")
        end
        if not playerAura("祷言之环") then
            return Skippy.UnitHeal("macro", "圣言术：灵")
        end
    end
    if isKnown["永恒圣洁"] and playerAura("神圣化身") and count90 >= 3 then
        return Skippy.UnitHeal("macro", "圣言术：灵")
    end
end

if spell("圣言术：静").usable then
    if not isKnown["持久圣言"] and lowestUnit and lowestHealth <= 80 then
        return Skippy.UnitHeal(lowestUnit, "圣言术：静")
    end

    if noRenewUnit and noRenewHealth <= 80 then
        return Skippy.UnitHeal(noRenewUnit, "圣言术：静")
    end

    if lowestUnit and lowestHealth <= 80 then
        return Skippy.UnitHeal(lowestUnit, "圣言术：静")
    end
end

if playerAura("圣洁") then -- 圣洁,瞬发治疗术或治疗祷言
    if spell("治疗祷言").usable and count90 >= 5 then
        return Skippy.UnitHeal(lowestUnit, "治疗祷言")
    end
    if spell("治疗术").usable and lowestUnit then
        return Skippy.UnitHeal(lowestUnit, "治疗术")
    end
end

if spell("快速治疗").usable and playerAura("圣光涌动") and lowestUnit then
    return Skippy.UnitHeal(lowestUnit, "快速治疗")
end

if spell("治疗祷言").usable and Skippy.GetCount(85) >= 5 then
    if not isKnown["祷言之环"] then
        return Skippy.UnitHeal(lowestUnit, "治疗祷言")
    end

    if playerAura("祷言之环") or not spell("圣言术：灵").usable then
        return Skippy.UnitHeal(lowestUnit, "治疗祷言")
    end
end

if spell("治疗术").usable and playerAura("织光者") and lowestUnit then
    return Skippy.UnitHeal(lowestUnit, "治疗术")
end

if spell("恢复").usable and not isKnown["恢复增效"] then
    if noRenewTank then
        return Skippy.UnitHeal(noRenewTank, "恢复")
    end
    if noRenewUnit then
        return Skippy.UnitHeal(noRenewUnit, "恢复")
    end
end

if casting == "治疗祷言" or casting == "治疗术" or casting == "快速治疗" then
    return Skippy.UnitHeal("None", "None")
end

--[[ 输出阶段
if state.isCombat then
    if target.canAttack and inRange then
        if set.Attack then
            if spell("暗言术：痛").usable and not target.debuff["暗言术：痛"] then
                return Skippy.UnitHeal("target", "暗言术：痛")
            end
            if spell("神圣之火").usable then
                return Skippy.UnitHeal("target", "神圣之火")
            end
            if spell("圣言术：罚").usable then
                return Skippy.UnitHeal("target", "圣言术：罚")
            end
            if spell("惩击").usable then
                return Skippy.UnitHeal("target", "惩击")
            end
        end
    else
        return Skippy.UnitHeal("macro", "上个敌人")
    end
end]]

return Skippy.UnitHeal("macro", "None")
