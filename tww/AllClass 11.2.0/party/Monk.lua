local e = aura_env
local player = e.playerinfo
if player.class ~= "武僧" then return end
if player.Specialization ~= 2 or player.inRaid or not player.inParty or not e.initialization then return end

local target = e.targetinfo
local UnitKey = e.UnitKey
local p = e.partystatus
local spell = e.spellinfo
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local hekili = Hekili_GetRecommendedAbility("Primary", 1) -- 获取Hekili推荐技能

local function partyInfo()
    local t = {
        count_80 = 0,                   -- 80%以下数量
        count_hasEM = 0,                -- 有氤氲之雾数量
        count_hasRM = 0,                -- 有复苏之雾数量

        lowest_Unit = nil,              -- 生命值最低的单位
        lowest_Health = 100,            -- 生命值最低的单位的生命值

        maxHealth = 999999999,          -- 初始最大生命值
        maxHealth_lowestUnit = nil,     -- 总生命值最低的单位的

        noEM_lowestUnit = nil,          -- 无氤氲之雾生命值最低的单位
        noEM_lowestHealth = 100,        -- 无氤氲之雾生命值最低的
        noEM_tank = nil,                -- 无氤氲之雾坦克

        noRM_lowestUnit = nil,          -- 无复苏之雾生命值最低的单位
        noRM_lowestHealth = 100,        -- 无复苏之雾生命值最低的
        noRM_maxHealth = 999999999,     -- 无复苏之雾最大生命值
        noRM_maxHealthlowestUnit = nil, -- 无复苏之雾最大生命值的单位

        noRM_Tank = nil,                -- 无复苏之雾坦克

        hasDebuff_noRM = nil,           -- 有减益无复苏之雾
        hasDebuff_noEM = nil,           -- 有减益无氤氲之雾

        damage_Value = 0,               -- 伤害
        damage_Unit = nil,              -- 伤害单位

        hasDiseaseUnit = nil,           -- 有疾病单位
        hasMagicUnit = nil,             -- 有魔法单位
        hasPoisonUnit = nil,            -- 有中毒单位
    }
    local unit
    for i = 0, 4 do
        if i == 0 then unit = "player" else unit = "party" .. i end
        if p and p[unit] and p[unit].isValid and p[unit].inRange and p[unit].inSight then
            if p[unit].healthPct < t.lowest_Health then
                t.lowest_Health = p[unit].healthPct
                t.lowest_Unit = unit
            end
            if p[unit].maxHealth < t.maxHealth then
                t.maxHealth = p[unit].maxHealth
                t.maxHealth_lowestUnit = unit
            end
            if p[unit].healthPct < 80 then
                t.count_80 = t.count_80 + 1
            end
            if p[unit].buff["氤氲之雾"] then
                t.count_hasEM = t.count_hasEM + 1
            else
                if p[unit].role == "TANK" then
                    t.noEM_Tank = unit
                end
                if p[unit].hasParticularDebuff then
                    t.hasDebuff_noEM = unit
                end
                if p[unit].healthPct < t.noEM_lowestHealth then
                    t.noEM_lowestHealth = p[unit].healthPct
                    t.noEM_lowestUnit = unit
                end
            end

            if p[unit].buff["复苏之雾"] then
                t.count_hasRM = t.count_hasRM + 1
            else
                if p[unit].role == "TANK" then
                    t.noRM_Tank = unit
                end
                if p[unit].healthPct < t.noRM_lowestHealth then
                    t.noRM_lowestHealth = p[unit].healthPct
                    t.noRM_lowestUnit = unit
                end
                if p[unit].hasParticularDebuff then
                    t.hasDebuff_noRM = unit
                end
                if p[unit].maxHealth < t.noRM_maxHealth then
                    t.noRM_maxHealth = p[unit].maxHealth
                    t.noRM_maxHealthlowestUnit = unit
                end
            end

            if p[unit].damage > t.damage_Value then
                t.damage_Value = p[unit].damage
                t.damage_Unit = unit
            end
            if p[unit].hasDisease then
                t.hasDiseaseUnit = unit
            end
            if p[unit].hasMagic then
                t.hasMagicUnit = unit
            end
            if p[unit].hasPoison then
                t.hasPoisonUnit = unit
            end
        end
    end

    return t
end

local t = partyInfo()
if target.Name == "虚空大使" and spell["轮回之触"].usable and target.inRange_8 then
    return UnitKey("target", "轮回之触")
end
if channel then return UnitKey("macro", "None") end
if player.isCombat then
    if spell["清创生血"].charges > 0 then
        if t.hasMagicUnit then
            return UnitKey(t.hasMagicUnit, "清创生血")
        end
        if e.talentInfo["强化清创生血"] then
            if t.hasDiseaseUnit then
                return UnitKey(t.hasDiseaseUnit, "清创生血")
            end
            if t.hasPoisonUnit then
                return UnitKey(t.hasPoisonUnit, "清创生血")
            end
        end
    end

    if player.manaPct < 20 and spell["法力茶"].count >= 10 then
        return UnitKey("macro", "法力茶")
    end
    if t.count_80 >= 2 then
        if spell["神龙之赐"].count >= 8 then
            return UnitKey("macro", "神龙之赐")
        end
        if spell["朱鹤下凡"].usable then
            return UnitKey("macro", "朱鹤下凡")
        end
    end
    if spell["旭日东升踢"].usable and p["player"].buff["雷光聚神茶"] and target.inRange_8 then
        return UnitKey("target", "旭日东升踢")
    end
    if spell["雷光茶"].charges == 2 then
        return UnitKey("macro", "雷光茶")
    end
    if spell["复苏之雾"].charges > 0 then
        if t.noRM_Tank then
            return UnitKey(t.noRM_Tank, "复苏之雾")
        end
        if t.noRM_lowestHealth < 99 then
            return UnitKey(t.noRM_lowestUnit, "复苏之雾")
        end
        if t.maxHealth_lowestUnit then
            return UnitKey(t.maxHealth_lowestUnit, "复苏之雾")
        end
    end
    if p["player"].buff["活力苏醒"] then
        if p["player"].buff["清晰使命"] and p["player"].buff["活力苏醒"] and p["player"].buff["活力苏醒"].count >= 8 and t.lowest_Unit then
            return UnitKey(t.lowest_Unit, "活血术")
        end
        if t.lowest_Health <= 70 then
            return UnitKey(t.lowest_Unit, "活血术")
        end
    end
    if t.count_hasEM < 2 and t.noEM_lowestHealth <= 80 then
        return UnitKey(t.noEM_lowestUnit, "氤氲之雾")
    end
else
    if player.manaPct < 20 and spell["法力茶"].count >= 10 then
        return UnitKey("macro", "法力茶")
    end
    if spell["雷光茶"].charges == 2 then
        if p["player"].buff["青玉赋能"] then
            if p["player"].buff["青玉赋能"].count < 2 then
                return UnitKey("macro", "雷光茶")
            end
        else
            return UnitKey("macro", "雷光茶")
        end
    end
    if spell["复苏之雾"].charges > 0 then
        if t.noRM_Tank then
            return UnitKey(t.noRM_Tank, "复苏之雾")
        end
        if t.noRM_lowestHealth < 99 then
            return UnitKey(t.noRM_lowestUnit, "复苏之雾")
        end
        if t.noRM_maxHealthlowestUnit then
            return UnitKey(t.noRM_maxHealthlowestUnit, "复苏之雾")
        end
    end
end
return UnitKey("macro", "输出")
