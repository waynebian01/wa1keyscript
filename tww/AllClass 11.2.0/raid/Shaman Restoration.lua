local e = aura_env
local player = e.playerinfo
if player.class ~= "萨满祭司" then return end
if player.Specialization ~= 3 or not player.inRaid or not e.initialization then return end

local r = e.raidstatus
local target = e.targetinfo
local buff = r[player.inRaidUnit] and r[player.inRaidUnit].buff or {}
local spell = e.spellinfo
local talentInfo = e.talentInfo
local UnitKey = e.UnitKey
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local hekili = Hekili_GetRecommendedAbility("Primary", 1)      -- 获取Hekili推荐技能
local interrupt = WK_Interrupt                                 -- 打断法术即将到来
local aoeisComeing = WK_AoeIsComeing                           -- 团队AOE即将在2秒后到来
local aoeRemaining = aoeisComeing and aoeisComeing - GetTime() -- 团队AOE即将在到来的剩余时间
local highDamage = WK_HIGHDAMAGE or WK_HIGHDAMAGECAST          -- 坦克6秒内即将受到高伤害, WK_HIGHDAMAGE=4秒, WK_HIGHDAMAGECAST=2秒

local function raidInfo()
    local t = {
        count90 = 0,
        count80 = 0,
        count70 = 0,

        lowest_Pct_Unit = nil,   -- 生命值最低的单位
        lowest_Pct_Health = 100, -- 生命值最低的单位的生命值

        TankUnit = nil,
        hasShield_Tank_Count = 0, -- 有盾 坦克数量
        noShield_Tank = nil,      -- 无盾 坦克

        noRiptide_Pct_lowestHealth = 100,
        noRiptide_Pct_lowestUnit = nil,
        noRiptide_maxHealth_lowestHealth = 9999999999,
        noRiptide_maxHealth_lowestUnit = nil,
        noRiptide_Tank = nil,

        hasRiptide_LowestHealth = 100,
        hasRiptide_LowestUnit = nil,

        hasMagicUnit = nil,  -- 有魔法单位

        hasCurseUnit = nil,  -- 有诅咒单位
        hasPoisonUnit = nil, -- 有中毒单位
        hasPoisonCount = 0,  -- 有中毒数量
    }

    for i = 1, 30 do
        local unit = "raid" .. i
        if r and r[unit] then
            local raid = r[unit]
            if raid.isAlive and raid.canAssist and raid.inRange and raid.inSight and not raid.hasAngel then
                if raid.healthPct < t.lowest_Pct_Health then
                    t.lowest_Pct_Health = raid.healthPct
                    t.lowest_Pct_Unit = unit
                end
                if raid.healthPct < 90 then
                    t.count90 = t.count90 + 1
                end
                if raid.healthPct < 80 then
                    t.count80 = t.count80 + 1
                end
                if raid.healthPct < 70 then
                    t.count70 = t.count70 + 1
                end
                if raid.combatRole == "TANK" then
                    t.TankUnit = unit
                    if raid.buff["大地之盾"] then
                        t.hasShield_Tank_Count = t.hasShield_Tank_Count + 1
                    else
                        t.noShield_Tank = unit
                    end
                end

                if raid.buff["激流"] or raid.buff["大地之盾"] then
                    if raid.healthPct < t.hasRiptide_LowestHealth then
                        t.hasRiptide_LowestHealth = raid.healthPct
                        t.hasRiptide_LowestUnit = unit
                    end
                end

                if not raid.buff["激流"] then
                    if raid.healthPct < t.noRiptide_Pct_lowestHealth then
                        t.noRiptide_Pct_lowestHealth = raid.healthPct
                        t.noRiptide_Pct_lowestUnit = unit
                    end
                    if raid.maxHealth < t.noRiptide_maxHealth_lowestHealth then
                        t.noRiptide_maxHealth_lowestHealth = raid.maxHealth
                        t.noRiptide_maxHealth_lowestUnit = unit
                    end
                    if raid.combatRole == "TANK" then
                        t.noRiptide_Tank = unit
                    end
                end
                if raid.hasMagic then
                    t.hasMagicUnit = unit
                end
                if raid.hasCurse then
                    t.hasCurseUnit = unit
                end
                if raid.hasPoison then
                    t.hasPoisonUnit = unit
                    t.hasPoisonCount = t.hasPoisonCount + 1
                end
            end
        end
    end
    return t
end
local t = raidInfo()

if interrupt and (casting or channel) then return UnitKey("macro", "中断施法") end

if spell["净化灵魂"].usable then
    if t.hasCurseUnit and talentInfo["强化净化灵魂"] then
        return UnitKey(t.hasCurseUnit, "净化灵魂")
    end
    if t.hasMagicUnit then
        return UnitKey(t.hasMagicUnit, "净化灵魂")
    end
end

if talentInfo["清毒图腾"] and spell["清毒图腾"].usable then
    if t.hasPoisonUnit and t.hasPoisonCount >= 2 then
        return UnitKey(t.hasPoisonUnit, "清毒图腾")
    end
end

if talentInfo["治疗之泉图腾"] then
    if not talentInfo["暴雨图腾"] then
        if t.count90 >= 1 and spell["治疗之泉图腾"].charges == 2 then
            return UnitKey("macro", "治疗之泉图腾")
        end
        if t.count80 >= 2 and spell["治疗之泉图腾"].charges >= 1 then
            return UnitKey("macro", "治疗之泉图腾")
        end
    else
        if player.isCombat and spell["治疗之泉图腾"].usable and not buff["暴雨图腾"] then
            return UnitKey("macro", "治疗之泉图腾")
        end
    end
end

if player.isCombat then
    if talentInfo["先祖迅捷"] then
        if spell["先祖迅捷"].usable and not buff["先祖迅捷"] then
            return UnitKey("macro", "先祖迅捷")
        end
    else
        if spell["自然迅捷"].usable and not buff["自然迅捷"] and t.count70 >= 1 then
            return UnitKey("macro", "自然迅捷")
        end
    end
end

if player.isCombat and talentInfo["生命释放"] and spell["生命释放"].usable then
    return UnitKey("macro", "生命释放")
end

if talentInfo["奔涌之流"] and spell["奔涌之流"].usable and t.count90 >= 5 then
    return UnitKey("macro", "奔涌之流")
end


if talentInfo["低语之潮"] then
    if spell["激流"].usable then
        if t.noRiptide_Pct_lowestUnit then
            return UnitKey(t.noRiptide_Pct_lowestUnit, "激流")
        end
        if t.noRiptide_Tank then
            return UnitKey(t.noRiptide_Tank, "激流")
        end
    end
    if buff["潮汐奔涌"] then
        if buff["灵魂行者的潮汐图腾"] and spell["治疗之涌"].usable and t.lowest_Pct_Health <= 80 then
            return UnitKey(t.lowest_Pct_Unit, "治疗之涌")
        end
        if casting == "治疗波" then
            if t.hasRiptide_LowestHealth <= 70 then
                return UnitKey(t.hasRiptide_LowestUnit, "治疗波")
            end
        else
            if t.hasRiptide_LowestUnit then
                return UnitKey(t.hasRiptide_LowestUnit, "治疗波")
            end
        end
    end
end

if spell["大地之盾"].usable then
    if not buff["大地之盾"] then
        return UnitKey(player.inRaidUnit, "大地之盾")
    end
    if t.noShield_Tank and t.hasShield_Tank_Count == 0 then
        return UnitKey(t.noShield_Tank, "大地之盾")
    end
end

if casting ~= "治疗链" and t.count70 >= 5 then
    return UnitKey(t.lowest_Pct_Unit, "治疗链")
end

if player.isCombat then
    if target.CanAttack and target.inRange_30 then
        return UnitKey("macro", "输出")
    else
        return UnitKey("macro", "上个敌人")
    end
end

return UnitKey("macro", "None")
