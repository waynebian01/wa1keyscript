-- Skippy 单位数据获取
-- 作者：Wayne
-- 功能：监听 player/target/focus/nameplate + party/raid
-- 版本：alpha 0.0.3

if not Skippy then Skippy = {} end
local e = aura_env

-- 1. 单位映射表
e.All_Units = {}
local units = {}
local group = {}
local boss = {}
local nameplate = {}

function e.InitUnitMapping()
    table.wipe(e.All_Units)
    table.wipe(units)
    table.wipe(group)
    table.wipe(boss)
    table.wipe(nameplate)

    units["target"] = "target"
    units["focus"] = "focus"

    for i = 1, 5 do
        boss["boss" .. i] = "boss" .. i
    end

    for i = 1, 40 do
        nameplate["nameplate" .. i] = "nameplate" .. i
    end

    if UnitInRaid("player") then
        units["player"] = "player"
        for i = 1, 40 do
            group["raid" .. i] = { index = i, unit = "raid" .. i }
        end
    elseif UnitInParty("player") then
        group["player"] = "player"
        for i = 1, 4 do
            group["party" .. i] = { index = i, unit = "party" .. i }
        end
    else
        units["player"] = "player"
    end

    -- 合并所有单位（用于事件判断）
    for k, v in pairs(units) do e.All_Units[k] = v end
    for k, v in pairs(group) do e.All_Units[k] = v end
    for k, v in pairs(boss) do e.All_Units[k] = v end
    for k, v in pairs(nameplate) do e.All_Units[k] = v end
end

e.InitUnitMapping()
--  2. 初始化数据结构
function e.InitGroupMembers()
    Skippy.Units = {}     -- 核心单位：player, target, focus, boss1~5
    Skippy.Group = {}
    Skippy.Boss = {}      -- 首领：boss1~5
    Skippy.Nameplate = {} -- 姓名板：nameplate1~40
    -- 初始化核心单位
    for unit, _ in pairs(units) do
        Skippy.Units[unit] = { exists = UnitExists(unit) }
    end

    for unit, _ in pairs(boss) do
        Skippy.Boss[unit] = { exists = UnitExists(unit) }
    end

    for unit, _ in pairs(nameplate) do
        Skippy.Nameplate[unit] = { exists = UnitExists(unit) }
    end

    if UnitInRaid("player") then -- 在团队中
        Skippy.Group = {}        -- 队伍成员： raid1~40
        for unit, data in pairs(group) do
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
        Skippy.Group = {}             -- 队伍成员：party1~4
        for unit, data in pairs(group) do
            local exists = UnitExists(unit)
            if exists then
                Skippy.Group[unit] = {
                    exists = exists,
                    aura = {}
                }
            end
        end
    else
        Skippy.Group = nil
    end
end

e.InitGroupMembers()
--  3. 通用工具函数
-- 获取单位对象
local function GetUnitObj(unit)
    if units[unit] then
        return Skippy.Units[unit]
    elseif group[unit] then
        return Skippy.Group[unit]
    elseif boss[unit] then
        return Skippy.Boss[unit]
    elseif nameplate[unit] then
        return Skippy.Nameplate[unit]
    end
end

-- 获取预估治疗量
function aura_env.GetIncomingHeals(unit)
    if WeakAuras.IsRetail() then
        return 0
    else
        return UnitGetIncomingHeals(unit) or 0
    end
end

-- 更新血量（自动计算百分比，吸收盾后血量）
function e.UpdateHealth(unit, key, getter)
    local obj = GetUnitObj(unit)
    if not obj or not key or not getter then return end

    obj[key] = getter(unit)

    if obj.isDead then
        obj.isDead = UnitIsDeadOrGhost(unit)
    end

    local h = obj.health or 0
    local m = obj.maxHealth or 0
    local a = obj.healAbsorbs or 0
    local p = obj.healPrediction or 0
    if WeakAuras.IsRetail() then
        obj.percentHealth = m > 0 and math.max(0, ((h - a) / m * 100)) or 0
    else
        obj.percentHealth = m > 0 and math.max(0, ((h - a + p) / m * 100)) or 0
    end
end

-- 更新是否在范围内
function e.UpdateInRange(unit, inRange)
    local obj = GetUnitObj(unit)
    if not obj then return end
    obj.inRange = inRange
end

-- 检测单位敌对状态
function e.UpdateFaction(unit)
    local obj = GetUnitObj(unit)
    if not obj then return end
    obj.canAttack = UnitCanAttack("player", unit)
    obj.canAssist = UnitCanAssist("player", unit)
end

-- 完整刷新光环
local function UpdateAuraFull(unit)
    local obj = GetUnitObj(unit)
    if not obj or not UnitExists(unit) then return end
    obj.aura = {}
    for i = 1, 40 do
        local buff = C_UnitAuras.GetBuffDataByIndex(unit, i)
        local debuff = C_UnitAuras.GetDebuffDataByIndex(unit, i)
        if buff then
            obj.aura[buff.auraInstanceID] = buff
        end
        if debuff then
            obj.aura[debuff.auraInstanceID] = debuff
        end
    end
end

-- 增量更新光环
function e.UpdateAuraIncremental(unit, info)
    local obj = GetUnitObj(unit)
    if not obj then return end
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

-- 通用函数：更新核心单位（target / focus）
function e.UpdateCoreUnit(unit)
    local obj = Skippy.Units[unit]
    if not obj then return end
    if UnitExists(unit) then
        local creatureType, creatureID = UnitCreatureType(unit)
        local minRange, maxRange = WeakAuras.GetRange(unit)
        obj.exists = true
        obj.name = GetUnitName(unit, true) or "无目标"
        obj.GUID = UnitGUID(unit)
        obj.creatureType = creatureType or "UNKNOWN"
        obj.creatureID = creatureID or 0
        obj.canAttack = UnitCanAttack("player", unit)
        obj.canAssist = UnitCanAssist("player", unit)
        obj.isDead = UnitIsDeadOrGhost(unit)
        obj.inRange = UnitInRange(unit)
        obj.minRange = minRange
        obj.maxRange = maxRange
        obj.health = UnitHealth(unit)
        obj.maxHealth = UnitHealthMax(unit)
        obj.healAbsorbs = UnitGetTotalHealAbsorbs(unit)
        obj.percentHealth = obj.maxHealth > 0 and
            math.max(0, ((obj.health - obj.healAbsorbs) / obj.maxHealth * 100)) or 0
        UpdateAuraFull(unit)
    else
        table.wipe(obj)
        obj.exists = false
    end
    if Skippy.Group and obj.isDead then
        for k, v in pairs(Skippy.Group) do
            if v.name == obj.name then
                v.isDead = UnitIsDeadOrGhost(unit)
            end
        end
    end
end

-- 通用函数：更新姓名板单位（nameplate1~40）
function e.UpdateNameplateUnit(unit)
    local obj = Skippy.Nameplate[unit]
    if not obj then return end
    if UnitExists(unit) then
        local minRange, maxRange = WeakAuras.GetRange(unit)
        local creatureType, creatureID = UnitCreatureType(unit)
        obj.exists = true
        obj.name = GetUnitName(unit, true) or "无目标"
        obj.GUID = UnitGUID(unit)
        obj.creatureType = creatureType or "UNKNOWN"
        obj.creatureID = creatureID or 0
        obj.canAttack = UnitCanAttack("player", unit)
        obj.canAssist = UnitCanAssist("player", unit)
        obj.isDead = UnitIsDeadOrGhost(unit)
        obj.minRange = minRange
        obj.maxRange = maxRange
        obj.health = UnitHealth(unit)
        obj.maxHealth = UnitHealthMax(unit)
        obj.healAbsorbs = UnitGetTotalHealAbsorbs(unit)
        obj.healPrediction = aura_env.GetIncomingHeals(unit)
        obj.realPercentHealth = obj.maxHealth > 0 and
            math.max(0, ((obj.health - obj.healAbsorbs) / obj.maxHealth * 100)) or 0
        obj.percentHealth = obj.maxHealth > 0 and
            math.max(0, ((obj.health - obj.healAbsorbs + obj.healPrediction) / obj.maxHealth * 100)) or 0
        UpdateAuraFull(unit)
    else
        Skippy.Nameplate[unit] = { exists = false }
    end
end

-- 通用函数：更新首领单位（boss1~5）
function e.UpdateBossUnit()
    C_Timer.After(1, function()
        for i = 1, 5 do
            local unit = "boss" .. i
            local obj = Skippy.Boss[unit]
            if not obj then return end
            if UnitExists(unit) then
                local creatureType, creatureID = UnitCreatureType(unit)
                obj.exists = true
                obj.name = GetUnitName(unit, true) or "未知"
                obj.GUID = UnitGUID(unit)
                obj.creatureType = creatureType or "UNKNOWN"
                obj.creatureID = creatureID or 0
                obj.canAttack = UnitCanAttack("player", unit)
                obj.canAssist = UnitCanAssist("player", unit)
                obj.isDead = UnitIsDeadOrGhost(unit)
                obj.inRange = UnitInRange(unit)
                obj.health = UnitHealth(unit)
                obj.maxHealth = UnitHealthMax(unit)
                obj.healAbsorbs = UnitGetTotalHealAbsorbs(unit)
                obj.healPrediction = aura_env.GetIncomingHeals(unit)
                obj.realPercentHealth = obj.maxHealth > 0 and
                    math.max(0, ((obj.health - obj.healAbsorbs) / obj.maxHealth * 100)) or 0
                obj.percentHealth = obj.maxHealth > 0 and
                    math.max(0, ((obj.health - obj.healAbsorbs + obj.healPrediction) / obj.maxHealth * 100)) or 0
                UpdateAuraFull(unit)
            else
                table.wipe(obj)
                obj.exists = false
            end
        end
    end)
end

-- 更新所有单位
function e.UpdateAllUnits()
    C_Timer.After(2, function() -- 延迟确保单位加载
        for unit, data in pairs(e.All_Units) do
            local obj = GetUnitObj(unit)
            local exists = UnitExists(unit)
            if exists then
                local creatureType, creatureID = UnitCreatureType(unit)
                if obj then
                    obj.name = GetUnitName(unit, true) or "未知"
                    obj.GUID = UnitGUID(unit)
                    obj.health = UnitHealth(unit)
                    obj.maxHealth = UnitHealthMax(unit)
                    obj.healAbsorbs = UnitGetTotalHealAbsorbs(unit)
                    obj.healPrediction = aura_env.GetIncomingHeals(unit)
                    obj.realPercentHealth = obj.maxHealth > 0 and
                        math.max(0, ((obj.health - obj.healAbsorbs) / obj.maxHealth * 100)) or 0
                    obj.percentHealth = obj.maxHealth > 0 and
                        math.max(0, ((obj.health - obj.healAbsorbs + obj.healPrediction) / obj.maxHealth * 100)) or 100
                    obj.isDead = UnitIsDeadOrGhost(unit)
                    obj.creatureType = creatureType or "UNKNOWN"
                    obj.creatureID = creatureID or 0
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
    end)
end

e.UpdateAllUnits()
