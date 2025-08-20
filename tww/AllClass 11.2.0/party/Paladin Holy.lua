local e = aura_env
local player = e.playerinfo
if player.class ~= "圣骑士" then return end
if player.Specialization ~= 1 or player.inRaid or not player.inParty or not e.initialization then return end

local p = e.partystatus
local target = e.targetinfo
local UnitKey = e.UnitKey
local buff = p["player"].buff
local spell = e.spellinfo
local talentInfo = e.talentInfo
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local hekili = Hekili_GetRecommendedAbility("Primary", 1)      -- 获取Hekili推荐技能
local interrupt = WK_Interrupt                                 -- 打断法术即将到来
local aoeisComeing = WK_AoeIsComeing                           -- 团队AOE即将在2秒后到来
local aoeRemaining = aoeisComeing and aoeisComeing - GetTime() -- 团队AOE即将在到来的剩余时间
local highDamage = WK_HIGHDAMAGE or WK_HIGHDAMAGECAST          -- 坦克6秒内即将受到高伤害, WK_HIGHDAMAGE=4秒, WK_HIGHDAMAGECAST=2秒

local function partyInfo()
    local t = {
        count90 = 0,
        lowest_Health = 100,
        lowest_Unit = nil,
        maxHealth = 999999999,
        maxHealth_lowestUnit = nil,

        maxDamage = 0,
        maxDamage_Unit = nil,

        tank_Unit = nil,

        hasParticularDebuff = nil,
        hasDiseaseUnit = nil, -- 有疾病单位
        hasMagicUnit = nil,   -- 有魔法单位
        hasPoisonUnit = nil,  -- 有中毒单位
    }
    local unit
    for i = 0, 4 do
        if i == 0 then unit = "player" else unit = "party" .. i end
        if p and p[unit] and p[unit].isValid and p[unit].inSight then
            if p[unit].healthPct < t.lowest_Health then
                t.lowest_Health = p[unit].healthPct
                t.lowest_Unit = unit
            end
            if p[unit].maxHealth < t.maxHealth then
                t.maxHealth = p[unit].maxHealth
                t.maxHealth_lowestUnit = unit
            end
            if p[unit].healthPct < 90 then
                t.count90 = t.count90 + 1
            end
            if p[unit].damage > t.maxDamage then
                t.maxDamage = p[unit].damage
                t.maxDamage_Unit = unit
            end
            if p[unit].role == "TANK" then
                t.tank_Unit = unit
            end
            if p[unit].hasParticularDebuff then
                t.hasParticularDebuff = unit
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

if player.isCombat then
    if spell["清洁术"].charges > 0 then
        if t.hasMagicUnit then
            return UnitKey(t.hasMagicUnit, "清洁术")
        end
        if e.talentInfo["强化清洁术"] then
            if t.hasDiseaseUnit then
                return UnitKey(t.hasDiseaseUnit, "清洁术")
            end
            if t.hasPoisonUnit then
                return UnitKey(t.hasPoisonUnit, "清洁术")
            end
        end
    end

    if t.count90 >= 2 then
        if spell["美德道标"].usable then
            return UnitKey("macro", "美德道标")
        end
        if spell["神圣棱镜"].usable and target.CanAttack and target.inRange_30 then
            return UnitKey("macro", "神圣棱镜")
        end
    end

    if spell["圣洁鸣钟"].usable and t.count90 >= 3 then
        return UnitKey("macro", "圣洁鸣钟")
    end

    if spell["仲夏祝福"].usable then
        if player.seasonsID == 388007 and t.maxDamage_Unit then
            return UnitKey(t.maxDamage_Unit, "仲夏祝福")
        end
        if player.seasonsID == 388011 then
            return UnitKey("macro", "凛冬祝福")
        end
        if player.seasonsID == 388010 then
            return UnitKey("macro", "暮秋祝福")
        end
        if player.seasonsID == 388013 then
            return UnitKey("macro", "阳春祝福")
        end
    end

    if t.count90 >= 1 then
        if player.HolyPower >= 3 then
            return UnitKey(t.lowest_Unit, "荣耀圣令")
        end
        if spell["神圣震击"].charges >= 1 then
            return UnitKey(t.lowest_Unit, "神圣震击")
        end
        if casting ~= "圣光术" and player.divineFavor then
            return UnitKey(t.lowest_Unit, "圣光术")
        end
    end
    if player.HolyPower == 5 then
        if t.lowest_Unit then
            return UnitKey(t.lowest_Unit, "荣耀圣令")
        end
        return UnitKey(t.maxHealth_lowestUnit, "荣耀圣令")
    end
else
    if spell["仲夏祝福"].usable and player.seasonsID == 388011 then
        return UnitKey("macro", "凛冬祝福")
    end
    if t.count90 >= 2 and spell["美德道标"].usable then
        return UnitKey("macro", "美德道标")
    end
    if t.count90 >= 1 then
        if player.HolyPower >= 3 then
            return UnitKey(t.lowest_Unit, "荣耀圣令")
        end
        if spell["神圣震击"].charges >= 1 then
            return UnitKey(t.lowest_Unit, "神圣震击")
        end
        if casting ~= "圣光术" and player.divineFavor then
            return UnitKey(t.lowest_Unit, "圣光术")
        end
    end
end
return UnitKey("macro", "输出")
