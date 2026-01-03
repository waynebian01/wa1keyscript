--  Skippy 玩家状态
-- 作者：Wayne
-- 功能：监听 player 玩家状态
-- 版本：alpha 0.0.6

if not Skippy then Skippy = {} end
local e = aura_env
local isRetail = WeakAuras.IsRetail()
Skippy.state = {}
Skippy.state.CastTargetName = nil
Skippy.state.CastTargetUnit = nil
Skippy.state.health = {}
Skippy.state.power = {}
Skippy.state.auras = {}
Skippy.state.totems = {}
Skippy.state.shapeshiftForm = {}
Skippy.state.isMoving = false
Skippy.state.isCombat = false
Skippy.state.class = UnitClass("player")
Skippy.state.hasMainHandEnchant = GetWeaponEnchantInfo()

function e.UpdateSpec()
    -- 仅在熊猫人和正式服获取玩家的职业专精
    if WeakAuras.IsMistsOrRetail() then
        Skippy.state.specIndex = C_SpecializationInfo.GetSpecialization()
        Skippy.state.specID = C_SpecializationInfo.GetSpecializationInfo(Skippy.state.specIndex)
    end
    if Wa1Key and Wa1Key.Prop then
        Wa1Key.Prop.press = 0
        Wa1Key.Prop.heal = 0
    end
end

e.UpdateSpec()

local EnumPowerType = {
    ["MANA"] = 0,
    ["RAGE"] = 1,
    ["FOCUS"] = 2,
    ["ENERGY"] = 3,
    ["COMBO_POINTS"] = 4,
    ["RUNES"] = 5,
    ["RUNIC_POWER"] = 6,
    ["SOUL_SHARDS"] = 7,
    ["LUNAR_POWER"] = 8,
    ["HOLY_POWER"] = 9,
    ["MAELSTROM"] = 11,
    ["CHI"] = 12,
    ["INSANITY"] = 13,
    ["BURNING_EMBERS"] = 14,
    ["DEMONIC_FURY"] = 15,
    ["ARCANE_CHARGES"] = 16,
    ["FURY"] = 17,
    ["PAIN"] = 18,
    ["ESSENCE"] = 19,
    ["SHADOW_ORBS"] = 28,
}

-- 更新玩家队伍状态
function e.UpdateGroup()
    Skippy.state.inParty = UnitPlayerOrPetInParty("player")
    Skippy.state.inRaid = UnitPlayerOrPetInRaid("player")
end

e.UpdateGroup()

-- 更新血量（自动计算百分比，吸收盾后血量）
function e.UpdatePlayerHealth(key, getter)
    local unit = "player"
    Skippy.state.health[key] = getter(unit)

    local health = Skippy.state.health
    local h = health.health or 0
    local m = health.healthMax or 0
    local a = health.healAbsorbs or 0
    local p = health.healPrediction or 0
    if isRetail then
        Skippy.state.percentHealth = m > 0 and math.max(0, ((h - a) / m * 100)) or 0
    else
        Skippy.state.percentHealth = m > 0 and math.max(0, ((h - a + p) / m * 100)) or 0
    end
end

-- 获取玩家血量百分比
function e.GetHealthPercent()
    local health = Skippy.state.health
    health.health = UnitHealth("player")
    health.healthMax = UnitHealthMax("player")
    health.healAbsorbs = UnitGetTotalHealAbsorbs("player")
    health.healPrediction = UnitGetIncomingHeals("player") or 0
    local h = health.health or 0
    local m = health.healthMax or 0
    local a = health.healAbsorbs or 0
    local p = health.healPrediction or 0
    if isRetail then
        Skippy.state.percentHealth = m > 0 and math.max(0, ((h - a) / m * 100)) or 0
    else
        Skippy.state.percentHealth = m > 0 and math.max(0, ((h - a + p) / m * 100)) or 0
    end
end

e.GetHealthPercent()


-- 更新能量信息
function e.UpdatePower(unit, powerType)
    local powerValue = EnumPowerType[powerType]
    if not powerValue then return end
    Skippy.state.power[powerType] = {
        UnitPower(unit, powerValue),
        UnitPowerMax(unit, powerValue)
    }
end

-- 更新所有能量信息
function e.UpdateAllPower()
    for powerType, _ in pairs(EnumPowerType) do
        e.UpdatePower("player", powerType)
    end
end

e.UpdateAllPower()

-- 更新所有图腾信息
function e.UpdateAllTotem()
    for i = 1, 4 do -- 1:火,2:土,3:水,4:空气
        local _, totemName, startTime, duration, _, _, spellID = GetTotemInfo(i)
        if totemName ~= "" then
            Skippy.state.totems[i] = {
                name = totemName,
                startTime = startTime,
                duration = duration,
                spellID = spellID,
            }
        else
            Skippy.state.totems[i] = nil
        end
    end
end

e.UpdateAllTotem()
-- 更新图腾信息
function e.UpdateTotem(i)
    local _, totemName, startTime, duration, _, _, spellID = GetTotemInfo(i)
    if totemName ~= "" then
        Skippy.state.totems[i] = {
            name = totemName,
            startTime = startTime,
            duration = duration,
            spellID = spellID,
        }
    else
        Skippy.state.totems[i] = nil
    end
end

-- 更新玩家施法信息
function e.UpdateCastingInfo()
    local name, _, _, startTimeMS, endTimeMS, _, _, _, spellId = UnitCastingInfo("player")
    if name then
        Skippy.state.castInfo = {
            name = name,
            startTimeMS = startTimeMS,
            endTimeMS = endTimeMS,
            spellId = spellId,
        }
    end
end

-- 更新玩家引导信息
function e.UpdateChannelingInfo()
    local name, _, _, startTimeMs, endTimeMs, _, _, spellID = UnitChannelInfo("player")
    if name then
        Skippy.state.channelInfo = {
            name = name,
            startTimeMs = startTimeMs,
            endTimeMs = endTimeMs,
            spellID = spellID,
        }
    end
end

-- 施法目标
function e.UpdateCastTarget(name)
    if Skippy.Group then
        for k, v in pairs(Skippy.Group) do
            if v.name == name then
                Skippy.state.CastTargetUnit = k
            end
        end
    end
end

-- 完整刷新光环
function e.UpdateAuraFull()
    local unit = "player"
    Skippy.state.auras = {}
    for i = 1, 40 do
        local buff = C_UnitAuras.GetBuffDataByIndex(unit, i)
        local debuff = C_UnitAuras.GetDebuffDataByIndex(unit, i)
        if buff then
            Skippy.state.auras[buff.auraInstanceID] = buff
        end
        if debuff then
            Skippy.state.auras[debuff.auraInstanceID] = debuff
        end
    end
end

e.UpdateAuraFull()

-- 增量更新光环
function e.UpdatePlayerAuraIncremental(info)
    local unit = "player"
    if info.isFullUpdate then
        e.UpdateAuraFull()
        return
    end

    if info.addedAuras then
        for _, aura in pairs(info.addedAuras) do
            Skippy.state.auras[aura.auraInstanceID] = aura
        end
    end

    if info.updatedAuraInstanceIDs then
        for _, id in pairs(info.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
            if aura then
                Skippy.state.auras[id] = aura
            end
        end
    end

    if info.removedAuraInstanceIDs then
        for _, id in pairs(info.removedAuraInstanceIDs) do
            if Skippy.state.auras[id] then Skippy.state.auras[id] = nil end
        end
    end
end

-- 获取玩家形态
function e.UpdateShapeshiftForm()
    Skippy.state.shapeshiftForm = {}
    for i = 1, GetNumShapeshiftForms() do
        local _, active, _, spellID = GetShapeshiftFormInfo(i);
        if spellID then
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo then
                Skippy.state.shapeshiftForm[spellInfo.name] = active
            end
        end
    end
end

e.UpdateShapeshiftForm()
