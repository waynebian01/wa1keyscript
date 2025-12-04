if not Skippy or not Skippy.Units or not Skippy.state then return end
if Skippy.state.class ~= "死亡骑士" then return end

-- ===== 状态 =====
local state = Skippy.state
local player = Skippy.GetPlayerInfo()
local runic = state.power.RUNIC_POWER[1]
local runicMax = state.power.RUNIC_POWER[2]
local target = Skippy.Units.target
local FrostPresence = state.shapeshiftForm["冰霜灵气"]
local BloodPresence = state.shapeshiftForm["鲜血灵气"]
local UnholyPresence = state.shapeshiftForm["邪恶灵气"]
local spell = Skippy.IsUsableSpellOnUnit
local cd = Skippy.GetSpellCooldown

-- ===== 变量 =====
local enemyCount = Skippy.GetEnemyCount(10)
local GlyphofDisease = C_SpellBook.IsSpellKnown(63334) -- 疾病雕文,你的传染技能可以使你的主要目标身上的疾病效果持续时间、疾病附加效果持续时间刷新到起始状态。
local runes = aura_env.RuneCount()
local canUseBloodSkill = true                          -- 是否可以使用[鲜血符文]技能
local useDeathCount = 0                                -- 灵界打击使用[死亡符文]的数量
local canUseDeathStrike = true                         -- 是否可以使用[灵界打击]
-- 疾病效果
local plagueInfo = aura_env.PlagueInfo()
local noPlagueCount = aura_env.noPlagueCount()

local DeathAndDecayCD = aura_env.DecayExpirationTime - GetTime() --死亡凋零CD
aura_env.DeathAndDecayCD = DeathAndDecayCD
-- ===== 逻辑 =====
-- 如果有疾病雕文,用传染延迟疾病的时间,使疾病时间刷新到起始状态
if GlyphofDisease and plagueInfo.FrostFever and plagueInfo.BloodPlague then
    -- 如果任意一个疾病时间小于3秒，则释放传染
    if spell("传染", "target") and plagueInfo.ShortestPlague < 3 then
        return Skippy.PressKey("传染")
    end
    -- 计算施放[灵界打击]需要的死亡符文数量
    if runes.UnholyRunes_Count == 0 then
        useDeathCount = useDeathCount + 1
    end
    if runes.FrostRunes_Count == 0 then
        useDeathCount = useDeathCount + 1
    end
    -- 当[鲜血]或[死亡]符文CD+3秒 > 最短[疾病]持续时间时
    if (runes.BloodRunes_CD + 3 > plagueInfo.ShortestPlague and
            runes.DeathRunes_CD + 3 > plagueInfo.ShortestPlague) then
        -- 当[鲜血]和[死亡]符文总数等于1时,不可以使用[鲜血符文]技能
        if runes.BloodRunes_Count + runes.DeathRunes_Count == 1 then
            canUseBloodSkill = false
        end
        -- 当[灵界打击]需要的全部[死亡符文]数量时,不可以使用[灵界打击]
        if runes.DeathRunes_Count == useDeathCount then
            canUseDeathStrike = false
        end
    end
end

if enemyCount >= 2 and canUseBloodSkill then
    if DeathAndDecayCD < 1 then
        if cd("枯萎凋零") > 1 and spell("活力分流") and runes.BloodRunes_Count < 2 then
            return Skippy.PressKey("活力分流")
        end
        return Skippy.PressKey("枯萎凋零")
    end
    if runes.BloodRunes_Count == 2 and spell("血液沸腾", "target") then
        return Skippy.PressKey("血液沸腾")
    end
end

if spell("冰冷触摸", "target") and not plagueInfo.FrostFever then
    return Skippy.PressKey("冰冷触摸")
end

if spell("暗影打击", "target") and not plagueInfo.BloodPlague then
    return Skippy.PressKey("暗影打击")
end

-- 当[灵界打击]可以施放,生命值低于80%时,施放[灵界打击]
if spell("灵界打击", "target") and player and player.percentHealth < 80 then
    -- 当[鲜血]和[冰霜]符文都存在时,施放[灵界打击]
    if runes.UnholyRunes_Count > 0 and runes.FrostRunes_Count > 0 then
        return Skippy.PressKey("灵界打击")
    end
    -- 当[鲜血]和[冰霜]符文都不存在时,[死亡]符文可用时又不影响使用[传染]时,施放[灵界打击]
    if canUseDeathStrike then
        return Skippy.PressKey("灵界打击")
    end
end

if spell("符文分流") and player and player.percentHealth < 70 then
    return Skippy.PressKey("符文分流")
end

if spell("符文打击", "target") then
    return Skippy.PressKey("符文打击")
end

if spell("活力分流") and runes.BloodRunes_Count == 0 then
    return Skippy.PressKey("活力分流")
end

if spell("凋零缠绕", "target") and runicMax - runic < 20 then
    return Skippy.PressKey("凋零缠绕")
end

if enemyCount >= 2 then
    if spell("传染", "target") and plagueInfo.ShortestPlague and noPlagueCount >= 1 then
        return Skippy.PressKey("传染")
    end
    if spell("血液沸腾", "target") and canUseBloodSkill then
        return Skippy.PressKey("血液沸腾")
    end
end

if spell("灵界打击", "target") and runes.UnholyRunes_Count > 0 and runes.FrostRunes_Count > 0 then
    return Skippy.PressKey("灵界打击")
end

if spell("鲜血打击", "target") and canUseBloodSkill then
    return Skippy.PressKey("鲜血打击")
end

return Skippy.PressKey("None")
