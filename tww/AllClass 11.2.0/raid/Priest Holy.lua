local e = aura_env
local player = e.playerinfo
if player.class ~= "牧师" then return end
if player.Specialization ~= 2 or not player.inRaid or not e.initialization then return end

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
        count90 = 0,             -- 90%血量单位数量
        count80 = 0,             -- 80%血量单位数量
        count70 = 0,             -- 70%血量单位数量

        average_Pct_Health = 0,  -- 团队生命值平均血量
        total_health_pct = 0,    -- 团队生命值总血量
        UnitCount = 0,           -- 团队有效人数

        lowest_Pct_Unit = nil,   -- 生命值最低的单位
        lowest_Pct_Health = 100, -- 生命值最低的单位的生命值

        noRenew = nil,
        noRenew_LowestUnit = nil,   -- 无恢复生命值最低的单位
        noRenew_LowestHealth = 100, -- 无恢复生命值最低的
        noRenew_Tank = nil,         -- 无恢复坦克

        noMending = nil,
        noMending_Tank = nil,         -- 无愈合坦克

        noMending_LowestUnit = nil,   -- 无愈合生命值最低的单位
        noMending_LowestHealth = 100, -- 无愈合生命值最低的

        damage = 0,                   -- 伤害
        damageUnit = nil,             -- 伤害最高的单位
    }

    for i = 1, 30 do
        local unit = "raid" .. i
        if r and r[unit] then
            local raid = r[unit]
            if raid.isAlive and raid.canAssist and raid.inRange and raid.inSight and not raid.hasAngel then
                t.total_health_pct = t.total_health_pct + raid.health
                t.UnitCount = t.UnitCount + 1
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

                if not raid.buff["恢复"] then
                    if raid.combatRole == "TANK" then
                        t.noRenew_Tank = unit
                    end
                    if raid.healthPct < t.noRenew_LowestHealth then
                        t.noRenew_LowestHealth = raid.healthPct
                        t.noRenew_LowestUnit = unit
                    end
                    t.noRenew = unit
                end

                if not raid.buff["愈合祷言"] then
                    if raid.combatRole == "TANK" then
                        t.noMending_Tank = unit
                    end
                    if raid.healthPct < t.noMending_LowestHealth then
                        t.noMending_LowestHealth = raid.healthPct
                        t.noMending_LowestUnit = unit
                    end
                    t.noMending = unit
                end

                if raid.damage > t.damage then
                    t.damage = raid.damage
                    t.damageUnit = unit
                end
            end
        end
    end
    t.average_Pct_Health = t.total_health_pct / t.UnitCount
    return t
end
local t = raidInfo()

if channel then return UnitKey("macro", "None") end
if interrupt and (casting or channel) then return UnitKey("macro", "中断施法") end
if aoeisComeing and spell["渐隐术"].usable then return UnitKey("macro", "渐隐术") end
if spell["绝望祷言"].usable and r[player.inRaidUnit] and r[player.inRaidUnit].healthPct <= 50 then
    return UnitKey("macro", "绝望祷言")
end

if spell["暗影魔"].usable and player.isCombat then
    if target.CanAttack and target.inRange_30 then
        return UnitKey("macro", "暗影魔")
    else
        return UnitKey("macro", "上个敌人")
    end
end

if spell["愈合祷言"].usable then
    if t.noMending_Tank then
        return UnitKey(t.noMending_Tank, "愈合祷言")
    end
    if t.noMending_LowestUnit then
        return UnitKey(t.noMending_LowestUnit, "愈合祷言")
    end
    if t.noMending then
        return UnitKey(t.noMending, "愈合祷言")
    end
end

if spell["恢复"].usable then
    if t.noRenew_Tank then
        return UnitKey(t.noRenew_Tank, "恢复")
    end
    if t.noRenew_LowestUnit then
        return UnitKey(t.noRenew_LowestUnit, "恢复")
    end
    if t.noRenew then
        return UnitKey(t.noRenew, "恢复")
    end
end

if spell["光晕"].usable and t.count90 >= 4 then
    return UnitKey("macro", "光晕")
end

if buff["分秒必争"] then
    if spell["治疗祷言"].usable and t.count80 >= 4 then
        return UnitKey(t.lowest_Pct_Unit, "治疗祷言")
    end
end

if spell["预兆"].usable and spell["预兆"].charges == 2 and t.count80 >= 4 then
    return UnitKey("macro", "预兆")
end

if spell["圣言术：静"].usable and t.lowest_Pct_Health <= 70 then
    return UnitKey(t.lowest_Pct_Unit, "圣言术：静")
end

if spell["快速治疗"].usable and buff["圣光涌动"] and t.lowest_Pct_Health <= 85 then
    return UnitKey(t.lowest_Pct_Unit, "快速治疗")
end
if spell["神圣化身"].usable and t.average_Pct_Health <= 80 then
    if spell["圣言术：灵"].charges == 2 then
        return UnitKey(t.lowest_Pct_Unit, "圣言术：灵")
    end
    if spell["圣言术：静"].charges < 2 and spell["圣言术：灵"].charges < 2 then
        return UnitKey(t.lowest_Pct_Unit, "神圣化身")
    end
end

if buff["神圣化身"] then
    if spell["治疗祷言"].usable and t.count80 >= 4 then
        return UnitKey(t.lowest_Pct_Unit, "治疗祷言")
    end
    if spell["快速治疗"].usable and t.count90 >= 1 then
        return UnitKey(t.lowest_Pct_Unit, "快速治疗")
    end
end

if spell["治疗祷言"].usable and t.count70 >= 4 then
    return UnitKey(t.lowest_Pct_Unit, "治疗祷言")
end

if spell["快速治疗"].usable and t.lowest_Pct_Health <= 70 then
    return UnitKey(t.lowest_Pct_Unit, "快速治疗")
end

if spell["治疗术"].usable and t.lowest_Pct_Health <= 85 then
    return UnitKey(t.lowest_Pct_Unit, "治疗术")
end
if player.isCombat then
    if target.CanAttack and target.inRange_30 then
        return UnitKey("macro", "输出")
    else
        return UnitKey("macro", "上个敌人")
    end
end

return UnitKey("macro", "None")
