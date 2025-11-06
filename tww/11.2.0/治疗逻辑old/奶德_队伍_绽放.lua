if aura_env.initialization == false then return end
local e                = aura_env
local player           = WK.PlayerInfo
local target           = WK.TargetInfo
local spell            = WK.getSpellArguments
local talents          = player.talent
local UnitKey          = aura_env.UnitKey
local channel          = UnitChannelInfo("player")
local casting          = UnitCastingInfo("player")
local interrupt        = WK.Interrupt
local aoeisComeing     = WK.AoeIsComeing
local inMeleeRange     = C_Spell.IsSpellInRange(5221, "target")
local inRangedRange    = C_Spell.IsSpellInRange(5176, "target")

local set              = aura_env.config
local lowestUnit       = e.getLowestUnit(100) -- 生命值最低的单位
local regrowth         = e.getLowestUnit(set.Regrowth, "愈合", "HELPFUL", false) -- 愈合阈值
local regrowthClear    = e.getLowestUnit(set.RegrowthClear, "愈合", "HELPFUL", false) -- 愈合(节能施法)阈值
local noLife_lowest    = e.maxHealth_lowestUnit("生命绽放", "HELPFUL", false) -- 无生命绽放 的最大血量的单位
local noRe_lowest      = e.rejuvenation_lowestUnit(set.Rejuvenation, 0) -- 无回春术 的单位
local oneRe_lowest     = e.rejuvenation_lowestUnit(set.Rejuvenation2, 1) -- 只有一个回春术 的单位
local noCenarion_tank  = e.getLowestUnit(200, "塞纳里奥结界", "HELPFUL", false, "TANK") -- 坦克的单位
local noSymbiotic_tank = e.getLowestUnit(200, "共生关系", "HELPFUL", false, "TANK")
local lifebloomCount   = e.getCount(200, "生命绽放", "HELPFUL", true)

if channel then return UnitKey("macro", "None") end

if player.buff["自然迅捷"] and spell("万灵之召", "usable") then
    return UnitKey("macro", "万灵之召")
end

if player.isCombat then
    if aoeisComeing then
        if spell("树皮术", "usable") then
            return UnitKey("macro", "树皮术")
        end
        if talents["巨熊活力"] and not player.buff["巨熊活力"] then
            return UnitKey("macro", "熊形态")
        end
    end
    if spell("甘霖", "usable") and player.healthPct < 60 then
        return UnitKey("macro", "甘霖")
    end
    if spell("自然的守护", "usable") then
        return UnitKey("macro", "自然的守护")
    end
end

if spell("自然之愈", "usable") then
    if target.canAssist and set.DisperseTarget then
        if target.hasCurse or target.hasPoison or target.hasMagic then
            return UnitKey("macro", "自然之愈")
        end
    end
    if set.Disperse then
        if WK.debuffPlayer then
            return UnitKey("player", "自然之愈")
        end
        if WK.debuffMintimeUnit then
            return UnitKey(WK.debuffMintimeUnit, "自然之愈")
        end
        if WK.hasMagicUnit then
            return UnitKey(WK.hasMagicUnit, "自然之愈")
        end
        if WK.hasCurseUnit then
            return UnitKey(WK.hasCurseUnit, "自然之愈")
        end
        if WK.hasPoisonUnit then
            return UnitKey(WK.hasPoisonUnit, "自然之愈")
        end
        if WK.hasDebuffUnit then
            return UnitKey(WK.hasDebuffUnit, "自然之愈")
        end
    end
end

if set.Soothe and spell("安抚", "usable") and target.hasEnrage then
    return UnitKey("target", "安抚")
end

if aoeisComeing then
    if spell("野性成长", "usable") and not player.isMoving then
        return UnitKey("macro", "野性成长")
    end
end
if e.getCount(70) >= 2 then
    if spell("激活", "usable") then
        return UnitKey("macro", "激活")
    end
    if talents["林莽卫士"] and spell("林莽卫士", "charges") > 0 then
        return UnitKey(lowestUnit, "林莽卫士")
    end
end

if casting ~= "愈合" and spell("自然迅捷", "usable") and e.getCount(90) >= 3 and e.getCount(70) >= 1 then
    return UnitKey("macro", "自然迅捷")
end

if player.buff["自然迅捷"] and spell("愈合", "usable") and lowestUnit then
    return UnitKey(lowestUnit, "愈合")
end

if e.getCount(set.WildGrowth) >= set.WildGrowthCount then
    if talents["林莽卫士"] and spell("林莽卫士", "charges") > 1 then
        return UnitKey(lowestUnit, "林莽卫士")
    end
    if spell("野性成长", "usable") and not player.isMoving then
        return UnitKey("macro", "野性成长")
    end
end

if talents["林莽卫士"] and spell("林莽卫士", "charges") == 3 and e.getLowestUnit(90) then
    return UnitKey(lowestUnit, "林莽卫士")
end

if spell("迅捷治愈", "usable") and e.swiftmend_lowestUnit(80) then
    return UnitKey(e.swiftmend_lowestUnit(80), "迅捷治愈")
end

if set.Efflorescence and player.isCombat and talents["百花齐放"] and not player.buff["百花齐放"] and spell("百花齐放", "usable") then
    return UnitKey("macro", "百花齐放")
end

if spell("愈合", "usable") and player.buff["节能施法"] and not player.isMoving and casting ~= "愈合" then
    if regrowthClear then
        return UnitKey(regrowthClear, "愈合")
    end
end

if spell("生命绽放", "usable") and noLife_lowest then
    if talents["蔓生绽放"] then
        if lifebloomCount ~= 2 then
            return UnitKey(noLife_lowest, "生命绽放")
        end
    else
        if lifebloomCount ~= 1 then
            return UnitKey(noLife_lowest, "生命绽放")
        end
    end
end

if spell("塞纳里奥结界", "usable") and noCenarion_tank then
    return UnitKey(noCenarion_tank, "塞纳里奥结界")
end

if noRe_lowest then
    return UnitKey(noRe_lowest, "回春术")
end

if talents["萌芽"] and oneRe_lowest then
    return UnitKey(oneRe_lowest, "回春术")
end

if spell("愈合", "usable") and regrowth and casting ~= "愈合" then
    return UnitKey(lowestUnit, "愈合")
end

if set.Attack and player.isCombat and target.canAttack then
    if talents["杀手本能"] then
        if inMeleeRange then
            return UnitKey("macro", "输出")
        end
        if inRangedRange then
            if target.debuff["月火术"] then
                return UnitKey("target", "愤怒")
            else
                return UnitKey("target", "月火术")
            end
        end
    else
        return UnitKey("macro", "输出")
    end
end

if talents["共生关系"] and spell("共生关系", "usable") and casting ~= "共生关系" and noSymbiotic_tank then
    return UnitKey(noSymbiotic_tank, "共生关系")
end

return UnitKey("macro", "None")
