local e = aura_env
local player = e.playerinfo
if player.class ~= "牧师" then return end
if not player.inParty or player.inRaid or player.Specialization ~= 1 or not e.initialization then return end

local p = e.partystatus
local time = GetTime()
local target = e.targetinfo
local UnitKey = e.UnitKey
local buff = p["player"].buff
local spell = e.spellinfo
local talentInfo = e.talentInfo
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local disperse = WK_DISPERSE
local hekili = Hekili_GetRecommendedAbility("Primary", 1) -- 获取Hekili推荐技能
local interrupt = WK_Interrupt                            -- 打断法术即将到来
local aoeisComeing = WK_AoeIsComeing                      -- 团队AOE即将在2秒后到来
local aoeRemaining = aoeisComeing and aoeisComeing - time -- 团队AOE即将在到来的剩余时间
local highDamage = WK_HIGHDAMAGE or WK_HIGHDAMAGECAST     -- 坦克6秒内即将受到高伤害, WK_HIGHDAMAGE=4秒, WK_HIGHDAMAGECAST=2秒

-- 整理队伍信息
local function partyInfo()
    local lowestHealth = 9999999999
    local t = {
        lowest_Pct_Unit = nil,                 -- 生命值_百分比_最低的单位
        lowest_Pct_Health = 100,               -- 生命值_百分比_最低的单位的生命值

        maxHealth_lowestHealth = lowestHealth, -- 初始最大生命值
        maxHealth_lowestUnit = nil,            -- 总生命值_最低的单位的

        hasR_Count = 0,                        -- 有救赎 数量
        hasR_isAboutToExpire = nil,            -- 有救赎 即将过期的单位
        noR_Count = 0,                         -- 无救赎 数量
        noR_Pct_lowestUnit = nil,              -- 无救赎 生命值_百分比_最低的单位
        noR_Pct_lowestHealth = 100,            -- 无救赎 生命值_百分比_最低的
        noR_Tank = nil,                        -- 无救赎 坦克
        noR_Unit = nil,                        -- 无救赎 单位

        noS_Unit = nil,                        -- 无盾 的单位
        noS_lowestUnit = nil,                  -- 无盾 生命值_最低的单位
        noS_lowestHealth = lowestHealth,       -- 无盾 生命值_最低的
        noS_Pct_lowestUnit = nil,              -- 无盾 生命值_百分比_最低的单位
        noS_Pct_lowestHealth = 100,            -- 无盾 生命值_百分比_最低的
        noS_Tank = nil,                        -- 无盾 坦克

        hasDebuff_NoRedemption = nil,          -- 有减益 无救赎
        hasDebuff_NoShield = nil,              -- 有减益 无盾

        damage_Value = 0,                      -- 伤害
        damage_Unit = nil,                     -- 伤害单位

        hasDiseaseUnit = nil,                  -- 有疾病单位
        hasMagicUnit = nil,                    -- 有魔法单位

        evangelism_Count = 0,                  -- 满足福音治疗量的单位数量
    }
    local unit
    for i = 0, 4 do
        if i == 0 then unit = "player" else unit = "party" .. i end
        if p and p[unit] and p[unit].isValid and p[unit].inSight then
            if p[unit].healthPct < t.lowest_Pct_Health then
                t.lowest_Pct_Health = p[unit].healthPct
                t.lowest_Pct_Unit = unit
            end

            if p[unit].maxHealth < t.maxHealth_lowestHealth then
                t.maxHealth_lowestHealth = p[unit].maxHealth
                t.maxHealth_lowestUnit = unit
            end
            if p[unit].buff["救赎"] then
                t.hasR_Count = t.hasR_Count + 1
                if p[unit].buff["救赎"].expirationTime - time <= 3 then
                    t.hasR_isAboutToExpire = unit
                end
            else
                if p[unit].hasParticularDebuff then
                    t.hasDebuff_NoRedemption = unit
                end
                if p[unit].healthPct < 90 then
                    t.noR_Count = t.noR_Count + 1
                end
                if p[unit].healthPct < t.noR_Pct_lowestHealth then
                    t.noR_Pct_lowestHealth = p[unit].healthPct
                    t.noR_Pct_lowestUnit = unit
                end
                if p[unit].role == "TANK" then
                    t.noR_Tank = unit
                end
                t.noR_Unit = unit
            end
            if not p[unit].buff["真言术：盾"] then
                t.noS_Unit = unit
                if p[unit].hasParticularDebuff then
                    t.hasDebuff_NoShield = unit
                end
                if p[unit].health < t.noS_lowestHealth then
                    t.noS_lowestHealth = p[unit].health
                    t.noS_lowestUnit = unit
                end
                if p[unit].healthPct < t.noS_Pct_lowestHealth then
                    t.noS_Pct_lowestHealth = p[unit].healthPct
                    t.noS_Pct_lowestUnit = unit
                end
                if p[unit].role == "TANK" then
                    t.noS_Tank = unit
                end
            end
            if p[unit].hasDisease then
                t.hasDiseaseUnit = unit
            end
            if p[unit].hasMagic then
                t.hasMagicUnit = unit
            end
            if p[unit].damage > t.damage_Value then
                t.damage_Value = p[unit].damage
                t.damage_Unit = unit
            end
        end
    end

    if player.evangelismValue and t.hasR_Count > 0 then
        local averageEvangelism = player.evangelismValue / t.hasR_Count
        for i = 0, 4 do
            if i == 0 then unit = "player" else unit = "party" .. i end
            if p and p[unit] and p[unit].isValid and p[unit].inSight then
                if p[unit].buff["救赎"] and p[unit].losshealth > averageEvangelism then
                    t.evangelism_Count = t.evangelism_Count + 1
                end
            end
        end
    end
    return t
end
local t = partyInfo()
local maxCountUnit, maxTimeUnit, minTimeUnit = e.SortDebuffs()
if player.isCombat then
    if interrupt and (casting or channel) then return UnitKey("macro", "中断施法") end
    if casting == "终极苦修" then return UnitKey("macro", "None") end
    if aoeisComeing and spell["渐隐术"].usable then return UnitKey("macro", "渐隐术") end
    if spell["绝望祷言"].usable and p and p["player"].healthPct <= 50 and channel ~= "终极苦修" then
        return UnitKey("macro", "绝望祷言")
    end
    if channel then return UnitKey("macro", "None") end
    if spell["纯净术"].usable and disperse then
        if target.helper.hasMagic then
            return UnitKey("macro", "驱散目标")
        end
        if target.helper.hasDisease and talentInfo["强化纯净术"] then
            return UnitKey("macro", "驱散目标")
        end
        if maxCountUnit then
            return UnitKey(maxCountUnit, "纯净术")
        end
        if maxTimeUnit then
            return UnitKey(maxTimeUnit, "纯净术")
        end
        if minTimeUnit then
            return UnitKey(minTimeUnit, "纯净术")
        end
        if t.hasDiseaseUnit and talentInfo["强化纯净术"] then
            return UnitKey(t.hasDiseaseUnit, "纯净术")
        end
        if t.hasMagicUnit then
            return UnitKey(t.hasMagicUnit, "纯净术")
        end
    end
    if interrupt then return UnitKey("macro", "中断施法") end
end

if talentInfo["预兆"] then
    if player.isCombat then
        if hekili == 10060 and t.damage_Unit then
            return UnitKey(t.damage_Unit, "能量灌注")
        end
        if spell["福音"].usable then
            if t.evangelism_Count > 0 and t.evangelism_Count <= 3 then
                if t.hasR_Count == t.evangelism_Count then
                    return UnitKey("macro", "福音")
                end
            end
            if t.evangelism_Count > 3 then
                return UnitKey("macro", "福音")
            end
        end
        if casting ~= "真言术：耀" then
            if spell["真言术：耀"].usable then
                if buff["分秒必争"] then
                    if t.lowest_Pct_Health <= 90 then
                        return UnitKey(t.lowest_Pct_Unit, "真言术：耀")
                    end
                else
                    if t.hasR_Count <= 3 and aoeisComeing and aoeRemaining <= spell["真言术：耀"].castTime + player.GCD then
                        if spell["预兆"].usable and spell["预兆"].charges == 2 then
                            return UnitKey("macro", "预兆")
                        end
                    end
                end
                if not player.isMoving and t.noR_Count >= 2 then
                    return UnitKey(t.noR_Pct_lowestUnit, "真言术：耀")
                end
            else
                if spell["真言术：盾"].usable and buff["祸福相倚"] and buff["祸福相倚"].count >= 4 and aoeisComeing then
                    return UnitKey("player", "真言术：盾")
                end
            end
        end

        if buff["祸福相倚"] then
            if buff["祸福相倚"].count < 4 then
                if spell["苦修"].usable then
                    if t.lowest_Pct_Health <= 50 then
                        return UnitKey(t.lowest_Pct_Unit, "苦修")
                    end
                    if target.CanAttack and target.inRange_30 then
                        return UnitKey("macro", "目标苦修")
                    else
                        if t.lowest_Pct_Health <= 90 then
                            return UnitKey(t.lowest_Pct_Unit, "苦修")
                        end
                    end
                end
            else
                if spell["真言术：盾"].usable then
                    if t.noS_Pct_lowestHealth <= 40 then
                        return UnitKey(t.noS_Pct_lowestUnit, "真言术：盾")
                    end
                    if t.hasDebuff_NoShield then
                        return UnitKey(t.hasDebuff_NoShield, "真言术：盾")
                    end
                    if highDamage and t.noS_Tank then
                        return UnitKey(t.noS_Tank, "真言术：盾")
                    end
                    if t.noS_Pct_lowestUnit then
                        return UnitKey(t.noS_Pct_lowestUnit, "真言术：盾")
                    end
                    if t.noR_Pct_lowestHealth <= 90 then
                        return UnitKey(t.noR_Pct_lowestUnit, "真言术：盾")
                    end
                    if t.noS_lowestUnit then
                        return UnitKey(t.noS_lowestUnit, "真言术：盾")
                    end
                end
            end
        else
            if spell["苦修"].usable then
                if t.lowest_Pct_Health <= 50 then
                    return UnitKey(t.lowest_Pct_Unit, "苦修")
                end
                if target.CanAttack and target.inRange_30 then
                    return UnitKey("macro", "目标苦修")
                else
                    if t.lowest_Pct_Health <= 90 then
                        return UnitKey(t.lowest_Pct_Unit, "苦修")
                    end
                end
            end
        end
        if spell["快速治疗"].usable and casting ~= "快速治疗" then
            if t.hasDebuff_NoRedemption then
                return UnitKey(t.hasDebuff_NoRedemption, "快速治疗")
            end
            if (buff["圣光涌动"] and t.lowest_Pct_Health <= 90) or t.lowest_Pct_Health <= 30 then
                return UnitKey(t.lowest_Pct_Unit, "快速治疗")
            end
            if t.noR_Pct_lowestHealth <= 90 then
                return UnitKey(t.noR_Pct_lowestUnit, "快速治疗")
            end
        end
        if buff["洞察预兆"] and target.CanAttack and target.inRange_30 then
            if hekili ~= 585 and hekili ~= 589 then
                return UnitKey("target", "惩击")
            end
        end
    else
        if spell["苦修"].usable and buff["祸福相倚"] and buff["祸福相倚"].count < 4 and t.lowest_Pct_Health < 80 then
            return UnitKey(t.lowest_Pct_Unit, "苦修")
        end
        if spell["真言术：盾"].usable and buff["祸福相倚"] and buff["祸福相倚"].count >= 4 then
            if t.noS_lowestHealth < 100 then
                return UnitKey(t.noS_lowestUnit, "真言术：盾")
            end
            if t.noS_Tank then
                return UnitKey(t.noS_Tank, "真言术：盾")
            end
            if t.noS_lowestUnit then
                return UnitKey(t.noS_lowestUnit, "真言术：盾")
            end
        end
        if t.lowest_Pct_Health < 70 then
            if player.isMoving then
                if buff["圣光涌动"] then
                    return UnitKey(t.lowest_Pct_Unit, "快速治疗")
                end
                if spell["苦修"].usable then
                    return UnitKey(t.lowest_Pct_Unit, "苦修")
                end
            else
                if spell["苦修"].usable then
                    return UnitKey(t.lowest_Pct_Unit, "苦修")
                end
                if spell["快速治疗"].usable then
                    return UnitKey(t.lowest_Pct_Unit, "快速治疗")
                end
            end
        end
    end
    if interrupt then return UnitKey("macro", "None") end
    return UnitKey("macro", "输出")
end

if not talentInfo["预兆"] then
    if player.isCombat then
        if hekili == 10060 and t.damage_Unit then
            return UnitKey(t.damage_Unit, "能量灌注")
        end
        if spell["福音"].usable then
            if t.evangelism_Count > 0 and t.evangelism_Count <= 3 then
                if t.hasR_Count == t.evangelism_Count then
                    return UnitKey("macro", "福音")
                end
            end
            if t.evangelism_Count > 3 then
                return UnitKey("macro", "福音")
            end
        end
        if casting ~= "真言术：耀" and spell["真言术：耀"].usable and not player.isMoving then
            if t.hasR_Count <= 3 and aoeisComeing and aoeRemaining <= spell["真言术：耀"].castTime + player.GCD then
                return UnitKey(t.noR_Pct_lowestUnit, "真言术：耀")
            end
            if t.noR_Count >= 2 then
                return UnitKey(t.noR_Pct_lowestUnit, "真言术：耀")
            end
            if not spell["真言术：盾"].usable and t.noR_Count >= 1 then
                return UnitKey(t.noR_Pct_lowestUnit, "真言术：耀")
            end
        end

        if spell["真言术：盾"].usable then
            if t.noS_Pct_lowestHealth <= 40 then
                return UnitKey(t.noS_Pct_lowestUnit, "真言术：盾")
            end
            if t.noR_Pct_lowestHealth <= 90 then
                return UnitKey(t.noR_Pct_lowestUnit, "真言术：盾")
            end
            if t.noR_Unit then
                return UnitKey(t.noR_Unit, "真言术：盾")
            end
            if t.hasR_isAboutToExpire then
                return UnitKey(t.hasR_isAboutToExpire, "真言术：盾")
            end
        end

        if spell["快速治疗"].usable and casting ~= "快速治疗" then
            if buff["圣光涌动"] then
                if t.hasDebuff_NoRedemption then
                    return UnitKey(t.hasDebuff_NoRedemption, "快速治疗")
                end
                if t.noR_Pct_lowestUnit and t.noR_Pct_lowestUnit ~= "player" then
                    return UnitKey(t.noR_Pct_lowestUnit, "快速治疗")
                end
                if t.hasR_isAboutToExpire then
                    return UnitKey(t.hasR_isAboutToExpire, "快速治疗")
                end
            end
            if not player.isMoving and t.noR_Pct_lowestUnit and t.noR_Pct_lowestUnit ~= "player" then
                return UnitKey(t.noR_Pct_lowestUnit, "快速治疗")
            end
        end
        if spell["恢复"].usable and player.isMoving then
            if t.noR_Pct_lowestUnit then
                return UnitKey(t.noR_Pct_lowestUnit, "恢复")
            end
        end
    else
        if t.lowest_Pct_Health < 70 then
            if player.isMoving then
                if buff["圣光涌动"] then
                    return UnitKey(t.lowest_Pct_Unit, "快速治疗")
                end
                if spell["苦修"].usable then
                    return UnitKey(t.lowest_Pct_Unit, "苦修")
                end
            else
                if spell["苦修"].usable then
                    return UnitKey(t.lowest_Pct_Unit, "苦修")
                end
                if spell["快速治疗"].usable then
                    return UnitKey(t.lowest_Pct_Unit, "快速治疗")
                end
            end
        end
        if spell["恢复"].usable and player.isMoving then
            if t.noR_Unit then
                return UnitKey(t.noR_Unit, "恢复")
            end
        end
    end
    if interrupt then return UnitKey("macro", "None") end
    return UnitKey("macro", "输出")
end
