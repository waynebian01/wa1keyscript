if aura_env.initialization == false then return end
local e = aura_env
local player = WK.PlayerInfo
local target = WK.TargetInfo
local set = aura_env.config
local talents = player.talent
local UnitKey = aura_env.UnitKey
local casting = UnitCastingInfo("player")
local inRange = C_Spell.IsSpellInRange(57994, "target")

local spell = WK.getSpellArguments
local lowestUnit = e.getLowestUnit(100)
local noRiptideUnit = e.getLowestUnit(100, "激流", "HELPFUL", false)
local hasRiptideUnit = e.getLowestUnit(100, "激流")
local noRiptideTank = e.getLowestUnit(100, "激流", "HELPFUL", false, "TANK")
local noShieldTank = e.getLowestUnit(100, "大地之盾", "HELPFUL", false, "TANK")
local cloudburst = C_Spell.GetSpellCharges(157153)
local cloudburstCharges = cloudburst and cloudburst.currentCharges or 0

if player.isCombat then
    if talents["治疗之泉图腾"] and not player.isMoving then
        if talents["暴雨图腾"] then
            if spell("收回图腾", "usable") and cloudburstCharges == 0 then
                return UnitKey("macro", "收回图腾")
            end
            if set.Cloudburst and cloudburstCharges > 0 and not player.buff["暴雨图腾"] then
                return UnitKey("macro", "暴雨图腾")
            end
        else
            if e.getCount(1, 90) and spell("治疗之泉图腾", "charges") == 2 then
                return UnitKey("macro", "治疗之泉图腾")
            end
            if e.getCount(2, 70) and spell("治疗之泉图腾", "charges") >= 1 then
                return UnitKey("macro", "治疗之泉图腾")
            end
            if spell("收回图腾", "usable") and spell("治疗之泉图腾", "charges") == 0 then
                return UnitKey("macro", "收回图腾")
            end
        end
    end

    if spell("净化灵魂", "usable") then
        if WK.RaidDebuffUnit then
            return UnitKey(WK.RaidDebuffUnit, "纯净术")
        end
    end

    if talents["先祖迅捷"] then
        if set.Ancestors and spell("先祖迅捷", "usable") and lowestUnit and not player.buff["先祖迅捷"] then
            return UnitKey("macro", "先祖迅捷")
        end
    else
        if spell("自然迅捷", "usable") and not player.buff["自然迅捷"] and e.getCount(1, 70) then
            return UnitKey("macro", "自然迅捷")
        end
    end

    if talents["生命释放"] and spell("生命释放", "usable") then
        if lowestUnit then
            return UnitKey(lowestUnit, "生命释放")
        else
            return UnitKey("macro", "生命释放")
        end
    end
end

if talents["奔涌之流"] and spell("奔涌之流", "usable") and e.getCount(5, 90) then
    return UnitKey("macro", "奔涌之流")
end

if talents["低语之潮"] then
    if spell("激流", "usable") then
        if noRiptideUnit then
            return UnitKey(noRiptideUnit, "激流")
        end
        if noRiptideTank then
            return UnitKey(noRiptideTank, "激流")
        end
    end
    if player.buff["潮汐奔涌"] then
        if player.buff["波动"] and lowestUnit then
            return UnitKey(lowestUnit, "治疗波")
        end
        if player.buff["灵魂行者的潮汐图腾"] and spell("治疗之涌", "usable") and e.getLowestUnit(80) then
            return UnitKey(lowestUnit, "治疗之涌")
        end
        if casting == "治疗波" then
            if e.getLowestUnit(70, "激流") then
                return UnitKey(hasRiptideUnit, "治疗波")
            end
            if e.getLowestUnit(70) then
                return UnitKey(lowestUnit, "治疗波")
            end
        else
            if hasRiptideUnit then
                return UnitKey(hasRiptideUnit, "治疗波")
            end
            if lowestUnit then
                return UnitKey(lowestUnit, "治疗波")
            end
        end
    end
end

if spell("大地之盾", "usable") then
    if not player.buff["大地之盾"] then
        return UnitKey(e.getPlayer(), "大地之盾")
    end
    if talents["元素环绕"] and noShieldTank and not e.getCount(1, 200, "大地之盾", "HELPFUL", true, "TANK") then
        return UnitKey(noShieldTank, "大地之盾")
    end
end

if casting ~= "治疗链" and e.getCount(5, 70) then
    return UnitKey(lowestUnit, "治疗链")
end

if player.isCombat and set.Attack then
    if target.canAttack and inRange then
        return UnitKey("macro", "输出")
    else
        return UnitKey("macro", "上个敌人")
    end
end

return UnitKey("macro", "None")
