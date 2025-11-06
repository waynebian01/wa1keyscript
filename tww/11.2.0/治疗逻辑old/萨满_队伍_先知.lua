if aura_env.initialization == false then return end
local e                = aura_env
local set              = e.config
local player           = WK.PlayerInfo
local target           = WK.TargetInfo
local talents          = player.talent
local UnitKey          = e.UnitKey
local channel          = UnitChannelInfo("player")
local casting          = UnitCastingInfo("player")
local interrupt        = WK.Interrupt
local aoeisComeing     = WK.AoeIsComeing
local aoeRemaining     = aoeisComeing and aoeisComeing - GetTime() -- 团队AOE即将在到来的剩余时间
local hekili           = Hekili_GetRecommendedAbility("Primary", 1) -- 获取Hekili推荐技能
local currentTime      = GetTime()
local inWindShearRange = C_Spell.IsSpellInRange(57994, "target") -- 风剪范围内

local spell            = WK.getSpellArguments -- 获取法术参数
local lowestUnit       = e.getLowestUnit(100) -- 生命值最低的单位
local noRiptideUnit    = e.getLowestUnit(100, "激流", "HELPFUL", false) -- 没有激流的单位
local noRiptideTank    = e.getLowestUnit(100, "激流", "HELPFUL", false, "TANK") -- 没有激流的坦克
local noShieldTank     = e.getLowestUnit(200, "大地之盾", "HELPFUL", false, "TANK") -- 没有大地之盾的坦克
local count90          = e.getCount(90) -- 90%血量的单位数量
local count70          = e.getCount(70) -- 70%血量的单位数量
local TidebringerCount = e.getCount(set.Tidebringer) -- 潮汐使者
local TideCount        = e.getCount(set.Tide) -- 浪潮汹涌
local ChainCount       = e.getCount(set.Chain) -- 治疗链

local inCombatTime     = player.inCombatTime
local ancestorsCount   = 0

if player.buff["先祖的召唤"] then ancestorsCount = player.buff["先祖的召唤"].applications end

if target.canAttack and inWindShearRange and hekili == 57994 then
    return UnitKey("macro", "输出")
end

if interrupt then return UnitKey("macro", "中断施法") end
if channel then return UnitKey("macro", "None") end

if aoeisComeing and aoeRemaining < spell("治疗链", "castTime") + 1 and lowestUnit then
    return UnitKey(lowestUnit, "治疗链")
end

if spell("净化灵魂", "usable") then
    if set.DisperseFriend and target.canAssist then
        if target.hasMagic then
            return UnitKey("macro", "净化灵魂")
        end
        if talents["强化净化灵魂"] and target.hasCurse then
            return UnitKey("macro", "净化灵魂")
        end
    end

    if set.Disperse then
        if WK.debuffPlayer then
            return UnitKey("player", "净化灵魂")
        end
        if WK.debuffMintimeUnit then
            return UnitKey(WK.debuffMintimeUnit, "净化灵魂")
        end
        if WK.hasMagicUnit then
            return UnitKey(WK.hasMagicUnit, "净化灵魂")
        end
        if talents["强化净化灵魂"] and WK.hasCurseUnit then
            return UnitKey(WK.hasCurseUnit, "净化灵魂")
        end
        if WK.hasDebuffUnit then
            return UnitKey(WK.hasDebuffUnit, "净化灵魂")
        end
    end
end

if set.PoisonTotem ~= 0 and spell("清毒图腾", "usable") and e.getdispelNameCount("Poison") >= set.PoisonTotem then
    return UnitKey("macro", "清毒图腾")
end

if set.DisperseEnemy and spell("净化术", "usable") and target.canAttack and target.hasMagic then
    return UnitKey("macro", "净化术")
end

if player.isCombat then
    if talents["治疗之泉图腾"] and not player.isMoving then
        if talents["暴雨图腾"] then
            if spell("暴雨图腾", "charges") > 0 and set.Cloudburst and not player.buff["暴雨图腾"] and inCombatTime and currentTime - inCombatTime > set.CloudburstTotem then
                return UnitKey("macro", "暴雨图腾")
            end
            if spell("收回图腾", "usable") and spell("暴雨图腾", "charges") == 0 then
                return UnitKey("macro", "收回图腾")
            end
        else
            if count90 >= 1 and spell("治疗之泉图腾", "charges") == 2 then
                return UnitKey("macro", "治疗之泉图腾")
            end
            if count70 >= 2 and spell("治疗之泉图腾", "charges") >= 1 then
                return UnitKey("macro", "治疗之泉图腾")
            end
        end
    end

    if player.buff["先祖迅捷"] then
        if count90 == 1 and spell("治疗之涌", "usable") then
            return UnitKey(lowestUnit, "治疗之涌")
        elseif count90 >= 2 and spell("治疗链", "usable") then
            return UnitKey(lowestUnit, "治疗链")
        end
    end

    if talents["先祖迅捷"] then
        if set.Ancestors and spell("先祖迅捷", "usable") and not player.buff["先祖迅捷"] and lowestUnit then
            return UnitKey("macro", "先祖迅捷")
        end
    else
        if talents["自然迅捷"] and spell("自然迅捷", "usable") and count70 >= 1 and not player.buff["自然迅捷"] then
            return UnitKey("macro", "自然迅捷")
        end
    end

    if spell("生命释放", "usable") then
        if lowestUnit then
            return UnitKey(lowestUnit, "生命释放")
        else
            return UnitKey("macro", "生命释放")
        end
    end
end

if player.buff["潮汐奔涌"] and player.buff["潮汐奔涌"].applications > 2 then
    if casting == "治疗链" then
        if player.buff["潮汐使者"] then
            if e.getCount(set.Tidebringer - 10) >= set.TidebringerCount then
                return UnitKey(lowestUnit, "治疗链")
            end
        end
        if player.buff["浪潮汹涌"] then
            if e.getCount(set.Tide - 10) >= set.TideCount then
                return UnitKey(lowestUnit, "治疗链")
            end
        end
        if e.getCount(set.Chain - 10) >= set.ChainCount then
            return UnitKey(lowestUnit, "治疗链")
        end
    else
        if player.buff["潮汐使者"] then
            if TidebringerCount >= set.TidebringerCount then
                return UnitKey(lowestUnit, "治疗链")
            end
        end
        if player.buff["浪潮汹涌"] then
            if TideCount >= set.TideCount then
                return UnitKey(lowestUnit, "治疗链")
            end
        end
        if ChainCount >= set.ChainCount then
            return UnitKey(lowestUnit, "治疗链")
        end
    end

    if casting == "治疗之涌" then
        if spell("治疗之涌", "usable") and e.getLowestUnit(set.Surge - (ancestorsCount * set.AncestorsValue) - 10) then
            return UnitKey(lowestUnit, "治疗之涌")
        end
    else
        if spell("治疗之涌", "usable") and e.getLowestUnit(set.Surge - (ancestorsCount * set.AncestorsValue)) then
            return UnitKey(lowestUnit, "治疗之涌")
        end
    end
end

if spell("激流", "usable") then
    if noRiptideUnit then
        return UnitKey(noRiptideUnit, "激流")
    end
    if noRiptideTank then
        return UnitKey(noRiptideTank, "激流")
    end
    if lowestUnit then
        return UnitKey(lowestUnit, "激流")
    end
end

if casting == "治疗链" then
    if player.buff["潮汐使者"] then
        if e.getCount(set.Tidebringer - 10) >= set.TidebringerCount then
            return UnitKey(lowestUnit, "治疗链")
        end
    end
    if player.buff["浪潮汹涌"] then
        if e.getCount(set.Tide - 10) >= set.TideCount then
            return UnitKey(lowestUnit, "治疗链")
        end
    end
    if e.getCount(set.Chain - 10) >= set.ChainCount then
        return UnitKey(lowestUnit, "治疗链")
    end
else
    if player.buff["潮汐使者"] then
        if TidebringerCount >= set.TidebringerCount then
            return UnitKey(lowestUnit, "治疗链")
        end
    end
    if player.buff["浪潮汹涌"] then
        if TideCount >= set.TideCount then
            return UnitKey(lowestUnit, "治疗链")
        end
    end
    if ChainCount >= set.ChainCount then
        return UnitKey(lowestUnit, "治疗链")
    end
end

if casting == "治疗之涌" then
    if spell("治疗之涌", "usable") and e.getLowestUnit(set.Surge - (ancestorsCount * set.AncestorsValue) - 10) then
        return UnitKey(lowestUnit, "治疗之涌")
    end
else
    if spell("治疗之涌", "usable") and e.getLowestUnit(set.Surge - (ancestorsCount * set.AncestorsValue)) then
        return UnitKey(lowestUnit, "治疗之涌")
    end
end

if spell("大地之盾", "usable") then
    if noShieldTank then
        return UnitKey(noShieldTank, "大地之盾")
    end
    if not player.buff["大地之盾"] then
        return UnitKey("player", "大地之盾")
    end
end

if player.isCombat and set.Attack then
    return UnitKey("macro", "输出")
else
    return UnitKey("macro", "None")
end
