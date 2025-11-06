if aura_env.initialization == false then return end
local e = aura_env
local set = e.config
local player = WK.PlayerInfo
local target = WK.TargetInfo
local spell = WK.getSpellArguments
local talents = player.talent
local UnitKey = e.UnitKey
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local interrupt = WK.Interrupt
local aoeisComeing = WK.AoeIsComeing
local aoeRemaining = aoeisComeing and aoeisComeing - GetTime() -- 团队AOE即将在到来的剩余时间
local hekili = Hekili_GetRecommendedAbility("Primary", 1)      -- 获取Hekili推荐技能
local inRange = C_Spell.IsSpellInRange(585, "target")

local lowestUnit = e.getLowestUnit(100)
local hasR_Count = e.getCount(101, "救赎")
local noR_Count = e.getCount(100, "救赎", "HELPFUL", false)
local noR_lowestUnit = e.getLowestUnit(100, "救赎", "HELPFUL", false)
local noR_Unit = e.getLowestUnit(101, "救赎", "HELPFUL", false)
local noS_lowestUnit = e.getLowestUnit(100, "真言术：盾", "HELPFUL", false)


if not talents["预兆"] then
    if spell("纯净术", "usable") then
        if target.canAssist and set.DisperseFriend then
            if target.hasMagic then
                return UnitKey("macro", "纯净术")
            end
            if talents["强化纯净术"] and target.hasDisease then
                return UnitKey("target", "纯净术")
            end
        end
        if set.Disperse then
            if WK.debuffPlayer then
                return UnitKey("player", "纯净术")
            end
            if WK.debuffMintimeUnit then
                return UnitKey(WK.debuffMintimeUnit, "纯净术")
            end
            if WK.hasMagicUnit then
                return UnitKey(WK.hasMagicUnit, "纯净术")
            end
            if talents["强化纯净术"] and WK.hasDiseaseUnit then
                return UnitKey(WK.hasDiseaseUnit, "纯净术")
            end
            if WK.hasDebuffUnit then
                return UnitKey(WK.hasDebuffUnit, "纯净术")
            end
        end
    end

    if player.isCombat then
        if hekili == 10060 and e.DamageUnit() then
            return UnitKey(e.DamageUnit(), "能量灌注")
        end
        if set.DisperseEnemy and spell("驱散魔法", "usable") and target.canAttack and target.hasMagic then
            return UnitKey("target", "驱散魔法")
        end
        if spell("福音", "usable") then
            if e.getCount(85, "福音") > 3 then
                return UnitKey("macro", "福音")
            end
        end

        if casting ~= "真言术：耀" and spell("真言术：耀", "usable") and not player.isMoving then
            if hasR_Count <= 3 and aoeisComeing and aoeRemaining <= player.GCD + 1 then
                return UnitKey(noR_lowestUnit, "真言术：耀")
            end
            if noR_Count >= 2 then
                return UnitKey(noR_lowestUnit, "真言术：耀")
            end
            if not spell("真言术：盾", "usable") and noR_Count >= 1 then
                return UnitKey(noR_lowestUnit, "真言术：耀")
            end
        end

        if spell("真言术：盾", "usable") then
            if e.getLowestUnit(40, "真言术：盾", "HELPFUL", false) then
                return UnitKey(noS_lowestUnit, "真言术：盾")
            end
            if noR_lowestUnit then
                return UnitKey(noR_lowestUnit, "真言术：盾")
            end
            if noR_Unit then
                return UnitKey(noR_Unit, "真言术：盾")
            end
        end

        if spell("快速治疗", "usable") and casting ~= "快速治疗" then
            if player.buff["圣光涌动"] then
                if noR_lowestUnit and noR_lowestUnit ~= "player" then
                    return UnitKey(noR_lowestUnit, "快速治疗")
                end
            end
            if not player.isMoving and noR_lowestUnit and noR_lowestUnit ~= "player" then
                return UnitKey(noR_lowestUnit, "快速治疗")
            end
        end
        if spell("恢复", "usable") and player.isMoving then
            if noR_lowestUnit then
                return UnitKey(noR_lowestUnit, "恢复")
            end
        end
    else
        if e.getLowestUnit(70) then
            if player.isMoving then
                if player.buff["圣光涌动"] then
                    return UnitKey(lowestUnit, "快速治疗")
                end
                if spell("苦修", "usable") then
                    return UnitKey(lowestUnit, "苦修")
                end
            else
                if spell("苦修", "usable") then
                    return UnitKey(lowestUnit, "苦修")
                end
                if spell("快速治疗", "usable") then
                    return UnitKey(lowestUnit, "快速治疗")
                end
            end
        end
        if spell("恢复", "usable") and player.isMoving then
            if noR_Unit then
                return UnitKey(noR_Unit, "恢复")
            end
        end
    end
    if interrupt then return UnitKey("macro", "None") end
    return UnitKey("macro", "输出")
end
