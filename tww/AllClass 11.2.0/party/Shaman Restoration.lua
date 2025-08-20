local e = aura_env
local player = e.playerinfo
if player.class ~= "萨满祭司" then return end
if player.Specialization ~= 3 or player.inRaid or not player.inParty or not e.initialization then return end

local p = e.partystatus
local target = e.targetinfo
local UnitKey = e.UnitKey
local buff = p["player"].buff
local spell = e.spellinfo
local talentInfo = e.talentInfo
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local disperse = WK_DISPERSE
local hekili = Hekili_GetRecommendedAbility("Primary", 1)      -- 获取Hekili推荐技能
local interrupt = WK_Interrupt                                 -- 打断法术即将到来
local aoeisComeing = WK_AoeIsComeing                           -- 团队AOE即将在2秒后到来
local aoeRemaining = aoeisComeing and aoeisComeing - GetTime() -- 团队AOE即将在到来的剩余时间
local highDamage = WK_HIGHDAMAGE or WK_HIGHDAMAGECAST          -- 坦克6秒内即将受到高伤害, WK_HIGHDAMAGE=4秒, WK_HIGHDAMAGECAST=2秒

local function partyInfo()
    local lowestHealth = 9999999999
    local t = {
        count_90 = 0,                                    -- 90%血量的单位数量
        count_70 = 0,                                    -- 70%血量的单位数量

        lowest_Pct_Unit = nil,                           -- 生命值_百分比_最低的单位
        lowest_Pct_Health = 100,                         -- 生命值_百分比_最低的单位的生命值

        maxHealth_lowestHealth = lowestHealth,           -- 初始最大生命值
        maxHealth_lowestUnit = nil,                      -- 总生命值_最低的单位的

        noRiptide_Pct_lowestUnit = nil,                  -- 无激流 生命值_百分比_最低的单位
        noRiptide_Pct_lowestHealth = 100,                -- 无激流 生命值_百分比_最低的
        noRiptide_maxHealth_lowestHealth = lowestHealth, -- 无激流 最大生命值_最低的
        noRiptide_maxHealth_lowestUnit = nil,            -- 无激流 最大生命值_最低的的单位

        noRiptide_Tank = nil,                            -- 无激流 坦克
        hasRiptide_Count = 0,                            -- 有激流 数量

        noShield_Tank = nil,                             -- 无盾 坦克

        hasMagicUnit = nil,                              -- 有魔法单位
        hasCurseUnit = nil,                              -- 有诅咒单位
        hasPoisonUnit = nil,                             -- 有中毒单位
        hasPoisonCount = 0,                              -- 有中毒数量
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
            if p[unit].healthPct < 90 then
                t.count_90 = t.count_90 + 1
            end
            if p[unit].healthPct < 70 then
                t.count_70 = t.count_70 + 1
            end
            if p[unit].buff["激流"] then
                t.hasRiptide_Count = t.hasRiptide_Count + 1
            else
                if p[unit].healthPct < t.noRiptide_Pct_lowestHealth then
                    t.noRiptide_Pct_lowestHealth = p[unit].healthPct
                    t.noRiptide_Pct_lowestUnit = unit
                end
                if p[unit].maxHealth < t.noRiptide_maxHealth_lowestHealth then
                    t.noRiptide_maxHealth_lowestHealth = p[unit].maxHealth
                    t.noRiptide_maxHealth_lowestUnit = unit
                end
                if p[unit].role == "TANK" then
                    t.noRiptide_Tank = unit
                end
            end
            if p[unit].role == "TANK" and not p[unit].buff["大地之盾"] then
                t.noShield_Tank = unit
            end
            if p[unit].hasMagic then
                t.hasMagicUnit = unit
            end
            if p[unit].hasCurse then
                t.hasCurseUnit = unit
            end
            if p[unit].hasPoison then
                t.hasPoisonUnit = unit
                t.hasPoisonCount = t.hasPoisonCount + 1
            end
        end
    end
    return t
end
local t = partyInfo()

if interrupt and (casting or channel) then return UnitKey("macro", "中断施法") end

if spell["净化灵魂"].usable and disperse then
    if t.hasCurseUnit and talentInfo["强化净化灵魂"] then
        return UnitKey(t.hasCurseUnit, "净化灵魂")
    end
    if t.hasMagicUnit then
        return UnitKey(t.hasMagicUnit, "净化灵魂")
    end
end

if talentInfo["清毒图腾"] and spell["清毒图腾"].usable then
    if t.hasPoisonUnit and t.hasPoisonCount >= 2 then
        return UnitKey("macro", "清毒图腾")
    end
end

if player.isCombat then
    if talentInfo["治疗之泉图腾"] then
        if talentInfo["暴雨图腾"] then
            if spell["治疗之泉图腾"].usable and not buff["暴雨图腾"] then
                return UnitKey("macro", "治疗之泉图腾")
            end
        else
            if t.count_90 >= 1 and spell["治疗之泉图腾"].charges == 2 then
                return UnitKey("macro", "治疗之泉图腾")
            end
            if t.count_70 >= 2 and spell["治疗之泉图腾"].charges >= 1 then
                return UnitKey("macro", "治疗之泉图腾")
            end
        end
    end

    if talentInfo["先祖迅捷"] then
        if spell["先祖迅捷"].usable and not buff["先祖迅捷"] then
            return UnitKey("macro", "先祖迅捷")
        end
    else
        if talentInfo["自然迅捷"] and spell["自然迅捷"].usable and t.count_70 >= 1 and not buff["自然迅捷"] then
            return UnitKey("macro", "自然迅捷")
        end
    end

    if talentInfo["生命释放"] and spell["生命释放"].usable then
        return UnitKey("macro", "生命释放")
    end
end


if spell["激流"].usable then
    if t.noRiptide_Pct_lowestUnit then
        return UnitKey(t.noRiptide_Pct_lowestUnit, "激流")
    end
    if spell["激流"].charges == 3 and t.noRiptide_maxHealth_lowestUnit then
        return UnitKey(t.noRiptide_maxHealth_lowestUnit, "激流")
    end
    if t.noRiptide_Tank then
        return UnitKey(t.noRiptide_Tank, "激流")
    end
end

if casting ~= "治疗链" then
    if t.count_90 >= 2 then
        if buff["潮汐使者"] and buff["浪潮汹涌"] then
            return UnitKey(t.lowest_Pct_Unit, "治疗链")
        end
    end
    if t.count_70 > 3 then
        return UnitKey(t.lowest_Pct_Unit, "治疗链")
    end
end

if spell["大地之盾"].usable and t.noShield_Tank then
    return UnitKey(t.noShield_Tank, "大地之盾")
end

if casting == "治疗之涌" then
    if t.lowest_Pct_Health < 50 then
        return UnitKey(t.lowest_Pct_Unit, "治疗之涌")
    end
else
    if buff["潮汐奔涌"] and t.lowest_Pct_Health < 80 then
        return UnitKey(t.lowest_Pct_Unit, "治疗之涌")
    end
end

return UnitKey("macro", "输出")
