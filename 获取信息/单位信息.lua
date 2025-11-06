-- ========== Skippy 单位数据管理系统 ==========
-- 作者：Wayne
-- 功能：监听 player/target/focus + party/raid
-- 版本：alpha 0.0.2

if not Skippy then Skippy = {} end
Skippy.state = {}
Skippy.state.lastCastTargetName = nil
Skippy.state.initialization = false
Skippy.state.power = {}
Skippy.state.shapeshiftForm = {}

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
    ["CHI"] = 12,
    ["INSANITY"] = 13,
    ["ARCANE_CHARGES"] = 16,
    ["FURY"] = 17,
    ["PAIN"] = 18,
}
-- 导入 table 函数
local insert, remove, sort, wipe = table.insert, table.remove, table.sort, table.wipe

-- ========== 1. 单位映射表 ==========
local ALL_UNITS = {}
local UNITS = {}
local GROUP = {}
local BOSS = {}
local function InitUnitMapping()
    wipe(ALL_UNITS)
    wipe(UNITS)
    wipe(GROUP)
    wipe(BOSS)

    UNITS["target"] = "target"
    UNITS["focus"] = "focus"

    for i = 1, 5 do
        BOSS["boss" .. i] = "boss" .. i
    end

    if IsInRaid() then
        UNITS["player"] = "player"
        for i = 1, 40 do
            GROUP["raid" .. i] = { index = i, unit = "raid" .. i }
        end
    elseif UnitInParty("player") then
        GROUP["player"] = "player"
        for i = 1, 4 do
            GROUP["party" .. i] = { index = i, unit = "party" .. i }
        end
    else
        UNITS["player"] = "player"
    end

    -- 合并所有单位（用于事件判断）
    for k, v in pairs(UNITS) do ALL_UNITS[k] = v end
    for k, v in pairs(GROUP) do ALL_UNITS[k] = v end
    for k, v in pairs(BOSS) do ALL_UNITS[k] = v end
end

-- ========== 2. 初始化数据结构 ==========
local function InitGroupMembers()
    Skippy.Units = {} -- 核心单位：player, target, focus, boss1~5
    Skippy.Group = {}
    Skippy.Boss = {}  -- 首领：boss1~5
    -- 初始化核心单位
    for unit, _ in pairs(UNITS) do
        Skippy.Units[unit] = { exists = UnitExists(unit) }
    end

    for unit, _ in pairs(BOSS) do
        Skippy.Boss[unit] = { exists = UnitExists(unit) }
    end

    if IsInRaid() then    -- 在团队中
        Skippy.Group = {} -- 队伍成员：party1~4, raid1~40
        for unit, data in pairs(GROUP) do
            local _, _, subgroup = GetRaidRosterInfo(data.index)
            local isPlayer = UnitIsUnit("player", unit)
            local exists = UnitExists(unit)
            if exists then
                Skippy.Group[unit] = {
                    exists = exists,
                    isPlayer = isPlayer,
                    index = data.index,
                    subgroup = subgroup,
                    aura = {}
                }
            end
        end
    elseif UnitInParty("player") then -- 在小队中
        Skippy.Group = {}             -- 队伍成员：party1~4, raid1~40
        for unit, data in pairs(GROUP) do
            local exists = UnitExists(unit)
            if exists then
                Skippy.Group[unit] = {
                    exists = exists,
                    aura = {}
                }
            end
        end
    end
end

Skippy.state.isMoving = false
Skippy.state.isCombat = false
Skippy.state.inParty = UnitPlayerOrPetInParty("player")
Skippy.state.inRaid = UnitPlayerOrPetInRaid("player")
Skippy.state.class = UnitClass("player")
Skippy.state.specIndex = C_SpecializationInfo.GetSpecialization()
Skippy.state.specID = C_SpecializationInfo.GetSpecializationInfo(Skippy.state.specIndex)
Skippy.state.hasMainHandEnchant = GetWeaponEnchantInfo()

-- ========== 3. 通用工具函数 ==========

-- 获取单位对象
local function GetUnitObj(unit)
    if UNITS[unit] then
        return Skippy.Units[unit]
    elseif GROUP[unit] then
        return Skippy.Group[unit]
    elseif BOSS[unit] then
        return Skippy.Boss[unit]
    end
end

-- 更新血量（计算百分比， （当前生命值 + 治疗预估 - 治疗吸收） / 最大生命值）
local function UpdateHealth(unit, key, getter)
    local obj = GetUnitObj(unit)
    if not obj then return end

    obj[key] = getter(unit)
    if obj.isDead then
        obj.isDead = UnitIsDeadOrGhost(unit)
    end
    if key == "health" or key == "maxHealth" or key == "healAbsorbs" or key == "healPrediction" then
        local h = obj.health or 0
        local m = obj.maxHealth or 0
        local a = obj.healAbsorbs or 0
        local p = obj.healPrediction or 0
        -- 吸收后血量百分比，最低0
        obj.percentHealth = m > 0 and math.max(0, ((h - a + p) / m * 100)) or 0
    end
end

-- 更新能量信息
local function UpdatePower(unit, powerType)
    local powerValue = EnumPowerType[powerType]
    if not powerValue then return end
    Skippy.state.power[powerType] = {
        UnitPower(unit, powerValue),
        UnitPowerMax(unit, powerValue)
    }
end

-- 更新所有能量信息
local function UpdateAllPower()
    for powerType, _ in pairs(EnumPowerType) do
        UpdatePower("player", powerType)
    end
end

-- 更新图腾信息
local function UpdateAllTotem()
    Skippy.state.totem = {}
    for i = 1, 4 do -- 1:火,2:土,3:水,4:空气
        local _, totemName, startTime, duration, _, _, spellID = GetTotemInfo(i)
        if totemName ~= "" then
            Skippy.state.totem[i] = {
                name = totemName,
                startTime = startTime,
                duration = duration,
                spellID = spellID,
            }
        else
            Skippy.state.totem[i] = nil
        end
    end
end

-- 更新图腾信息
local function UpdateTotem(i)
    Skippy.state.totem = Skippy.state.totem or {}
    local _, totemName, startTime, duration, _, _, spellID = GetTotemInfo(i)
    if totemName ~= "" then
        Skippy.state.totem[i] = {
            name = totemName,
            startTime = startTime,
            duration = duration,
            spellID = spellID,
        }
    else
        Skippy.state.totem[i] = nil
    end
end

-- 更新是否在范围内
local function UpdateInRange(unit, inRange)
    local obj = GetUnitObj(unit)
    if not obj then return end
    obj.inRange = inRange
end

-- 检测单位敌对状态
local function UpdateFaction(unit)
    local obj = GetUnitObj(unit)
    if not obj then return end
    obj.canAttack = UnitCanAttack("player", unit)
    obj.canAssist = UnitCanAssist("player", unit)
end

-- 更新玩家施法信息
local function UpdateCastingInfo()
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
local function UpdateChannelingInfo()
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

-- 完整刷新光环
local function UpdateAuraFull(unit)
    local obj = GetUnitObj(unit)
    if not obj or not UnitExists(unit) then return end
    obj.aura = {}
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i)
        if aura then
            obj.aura[aura.auraInstanceID] = aura
        end
    end
end


-- 增量更新光环
local function UpdateAuraIncremental(unit, info)
    local obj = GetUnitObj(unit)
    if not obj.aura then obj.aura = {} end

    if info.isFullUpdate then
        UpdateAuraFull(unit)
        return
    end

    if info.addedAuras then
        for _, aura in pairs(info.addedAuras) do
            obj.aura[aura.auraInstanceID] = aura
        end
    end

    if info.updatedAuraInstanceIDs then
        for _, id in pairs(info.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
            if aura then
                obj.aura[id] = aura
            end
        end
    end

    if info.removedAuraInstanceIDs then
        for _, id in pairs(info.removedAuraInstanceIDs) do
            if obj.aura[id] then obj.aura[id] = nil end
        end
    end
end

local function GetShapeshiftFormName()
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

-- 通用函数：更新核心单位（target / focus）
local function UpdateCoreUnit(unit)
    local obj = Skippy.Units[unit]
    if not obj then return end
    if UnitExists(unit) then
        obj.exists = true
        obj.name = GetUnitName(unit, true) or "无目标"
        obj.GUID = UnitGUID(unit)
        obj.canAttack = UnitCanAttack("player", unit)
        obj.canAssist = UnitCanAssist("player", unit)
        obj.isDead = UnitIsDeadOrGhost(unit)
        obj.inRange = UnitInRange(unit)
        obj.health = UnitHealth(unit)
        obj.maxHealth = UnitHealthMax(unit)
        obj.healAbsorbs = UnitGetTotalHealAbsorbs(unit)
        obj.percentHealth = obj.maxHealth > 0 and
            math.max(0, ((obj.health - obj.healAbsorbs) / obj.maxHealth * 100)) or 0
        UpdateAuraFull(unit)
    else
        wipe(obj)
        obj.exists = false
    end
end

-- 通用函数：更新首领单位（boss1~5）
local function UpdateBossUnit()
    C_Timer.After(1, function()
        for i = 1, 5 do
            local unit = "boss" .. i
            local obj = Skippy.Boss[unit]
            if not obj then return end
            if UnitExists(unit) then
                obj.exists = true
                obj.name = GetUnitName(unit, true) or "未知"
                obj.GUID = UnitGUID(unit)
                obj.canAttack = UnitCanAttack("player", unit)
                obj.canAssist = UnitCanAssist("player", unit)
                obj.isDead = UnitIsDeadOrGhost(unit)
                obj.inRange = UnitInRange(unit)
                obj.health = UnitHealth(unit)
                obj.maxHealth = UnitHealthMax(unit)
                obj.healAbsorbs = UnitGetTotalHealAbsorbs(unit)
                obj.healPrediction = UnitGetIncomingHeals(unit) or 0
                obj.percentHealth = obj.maxHealth > 0 and
                    math.max(0, ((obj.health - obj.healAbsorbs + obj.healPrediction) / obj.maxHealth * 100)) or 0
                UpdateAuraFull(unit)
            else
                wipe(obj)
                obj.exists = false
            end
        end
    end)
end

-- 更新所有单位
local function UpdateAllUnits()
    Skippy.state.initialization = false
    C_Timer.After(1, function() -- 延迟确保单位加载
        for unit, data in pairs(ALL_UNITS) do
            local obj = GetUnitObj(unit)
            local exists = UnitExists(unit)
            if exists then
                if obj then
                    obj.name = GetUnitName(unit, true) or "未知"
                    obj.GUID = UnitGUID(unit)
                    obj.health = UnitHealth(unit)
                    obj.maxHealth = UnitHealthMax(unit)
                    obj.healAbsorbs = UnitGetTotalHealAbsorbs(unit)
                    obj.healPrediction = UnitGetIncomingHeals(unit) or 0
                    obj.percentHealth = obj.maxHealth > 0 and
                        math.max(0, ((obj.health - obj.healAbsorbs + obj.healPrediction) / obj.maxHealth * 100)) or 100
                    obj.isDead = UnitIsDeadOrGhost(unit)
                    obj.canAttack = UnitCanAttack("player", unit)
                    obj.canAssist = UnitCanAssist("player", unit)
                    obj.inRange = UnitInRange(unit)
                    obj.role = UnitGroupRolesAssigned(unit) or "NONE"
                    obj.inSight = true
                    obj.inSightTimer = nil
                    obj.aura = {}
                    UpdateAuraFull(unit)
                else
                    obj.exists = false
                end
            end
        end
        Skippy.state.initialization = true
    end)
end

-- ========== 4. 主框架 ==========
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_MAXHEALTH")
frame:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_FACTION")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("UNIT_SPELLCAST_SENT")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:RegisterEvent("UNIT_IN_RANGE_UPDATE")
frame:RegisterEvent("PLAYER_STARTED_MOVING")
frame:RegisterEvent("PLAYER_STOPPED_MOVING")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("UNIT_HEAL_PREDICTION")
frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
frame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
frame:RegisterEvent("PLAYER_TOTEM_UPDATE")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")

-- ========== 5. 事件处理 ==========
frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
        if (Skippy.state.inParty or Skippy.state.inRaid) and subEvent == "UNIT_DIED" then
            for k, v in pairs(Skippy.Group) do
                if v.GUID == destGUID then
                    v.isDead = true
                end
            end
        end
    elseif event == "UNIT_HEALTH" and ALL_UNITS[arg1] then
        UpdateHealth(arg1, "health", UnitHealth)
    elseif event == "UNIT_MAXHEALTH" and ALL_UNITS[arg1] then
        UpdateHealth(arg1, "maxHealth", UnitHealthMax)
    elseif event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" and ALL_UNITS[arg1] then
        UpdateHealth(arg1, "healAbsorbs", UnitGetTotalHealAbsorbs)
    elseif event == "UNIT_HEAL_PREDICTION" and ALL_UNITS[arg1] then
        UpdateHealth(arg1, "healPrediction", UnitGetIncomingHeals)
    elseif event == "UNIT_POWER_UPDATE" and arg1 == "player" then
        UpdatePower("player", arg2)
    elseif event == "UNIT_AURA" and ALL_UNITS[arg1] then
        UpdateAuraIncremental(arg1, arg2)
    elseif event == "UNIT_FACTION" and ALL_UNITS[arg1] then
        UpdateFaction(arg1)
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateCoreUnit("target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        UpdateCoreUnit("focus")
    elseif event == "ENCOUNTER_START" then
        UpdateBossUnit()
    elseif event == "ENCOUNTER_END" then
        UpdateBossUnit()
    elseif event == "UNIT_IN_RANGE_UPDATE" and ALL_UNITS[arg1] then
        UpdateInRange(arg1, arg2)
    elseif event == "UNIT_SPELLCAST_SENT" and arg1 == "player" then
        Skippy.state.lastCastTargetName = arg2
        for k, v in pairs(Skippy.Group) do
            if v.name == Skippy.state.lastCastTargetName then
                Skippy.state.lastCastTargetUnit = k
            end
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" and arg1 == "player" then
        Skippy.state.channel = true
        UpdateChannelingInfo()
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" and arg1 == "player" then
        Skippy.state.channel = false
        Skippy.state.lastCastTargetName = nil
        Skippy.state.lastCastTargetUnit = nil
        wipe(Skippy.state.channelInfo)
    elseif event == "UNIT_SPELLCAST_START" and arg1 == "player" then
        Skippy.state.cast = true
        UpdateCastingInfo()
    elseif event == "UNIT_SPELLCAST_STOP" and arg1 == "player" then
        Skippy.state.cast = false
        Skippy.state.lastCastTargetName = nil
        Skippy.state.lastCastTargetUnit = nil
        wipe(Skippy.state.castInfo)
    elseif event == "PLAYER_STARTED_MOVING" then
        Skippy.state.isMoving = true
    elseif event == "PLAYER_STOPPED_MOVING" then
        Skippy.state.isMoving = false
    elseif event == "PLAYER_REGEN_DISABLED" then
        Skippy.state.isCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        Skippy.state.isCombat = false
    elseif event == "PLAYER_TALENT_UPDATE" then
        Skippy.state.specIndex = C_SpecializationInfo.GetSpecialization()
        Skippy.state.specID = C_SpecializationInfo.GetSpecializationInfo(Skippy.state.specIndex)
    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
        GetShapeshiftFormName()
    elseif event == "PLAYER_TOTEM_UPDATE" then
        UpdateTotem(arg1)
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        Skippy.state.hasMainHandEnchant = GetWeaponEnchantInfo()
    elseif event == "UI_ERROR_MESSAGE" and arg2 == "目标不在视野中" then
        for k, v in pairs(Skippy.Group) do
            if v.name == Skippy.state.lastCastTargetName then
                local obj = Skippy.Group[k]
                if obj then
                    obj.inSight = false
                    if obj.inSightTimer then
                        obj.inSightTimer:Cancel()
                        obj.inSightTimer = nil
                    end
                    obj.inSightTimer = C_Timer.NewTimer(2, function()
                        obj.inSight = true
                        obj.inSightTimer = nil
                    end)
                    break
                end
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        Skippy.state.inParty = UnitPlayerOrPetInParty("player")
        Skippy.state.inRaid = UnitPlayerOrPetInRaid("player")
        InitUnitMapping()
        InitGroupMembers()
        UpdateAllUnits()
        UpdateAllPower()
        GetShapeshiftFormName()
        UpdateAllTotem()
    end
end)

