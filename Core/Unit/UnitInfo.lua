-- Skippy Units
-- 作者：Wayne
-- 功能：监听 player/target/focus/nameplate + party/raid
-- 版本：alpha 0.0.6

if not Skippy then Skippy = {} end
local isRetail = WeakAuras.IsRetail()
-- 初始化根表
Skippy.Units = {}     -- 核心单位： target, focus
Skippy.Boss = {}      -- 首领：boss1~5
Skippy.Nameplate = {} -- 姓名板：nameplate1~40
Skippy.Group = {}     -- 队伍成员： party1~4, raid1~40

-- 获取单位对象
function aura_env.GetUnitObj(unit)
    if not unit then return nil end
    return Skippy.Units[unit] or
        Skippy.Group[unit] or
        Skippy.Boss[unit] or
        Skippy.Nameplate[unit]
end

-- 获取预估治疗量
function aura_env.GetIncomingHeals(unit)
    if isRetail then -- 正式服不预估治疗量
        return 0
    else
        return UnitGetIncomingHeals(unit) or 0
    end
end

-- 获取单位完整血量
function aura_env.GetFullHealth(unit)
    local obj = aura_env.GetUnitObj(unit)
    if not obj then return end
    obj.health = UnitHealth(unit)
    obj.healthMax = UnitHealthMax(unit)
    obj.healAbsorbs = UnitGetTotalHealAbsorbs(unit)
    obj.healPrediction = aura_env.GetIncomingHeals(unit)
    obj.realHealthPercent = obj.healthMax > 0 and
        math.max(0, ((obj.health - obj.healAbsorbs) / obj.healthMax * 100)) or 0
    obj.healthPercent = obj.healthMax > 0 and
        math.max(0, ((obj.health - obj.healAbsorbs + obj.healPrediction) / obj.healthMax * 100)) or 0
end

-- 更新血量（自动计算百分比，吸收盾后血量）
function aura_env.UpdateHealth(unit, key, getter)
    local obj = aura_env.GetUnitObj(unit)
    if not obj or not key or not getter then return end

    obj[key] = getter(unit)

    if obj.isDead then
        obj.isDead = UnitIsDeadOrGhost(unit)
    end

    local h = obj.health or 0
    local m = obj.healthMax or 0
    local a = obj.healAbsorbs or 0
    local p = obj.healPrediction or 0

    obj.healthPercent = m > 0 and math.max(0, ((h - a + p) / m * 100)) or 0
    obj.realHealthPercent = m > 0 and math.max(0, ((h - a) / m * 100)) or 0
end

-- 更新是否在范围内,事件更新，仅在正式服有效
function aura_env.UpdateInRange(unit, inRange)
    local obj = aura_env.GetUnitObj(unit)
    if not obj then return end
    obj.inRange = inRange
end

-- 更新单位距离
function aura_env.UpdateMaxAndMinRange(unit)
    local obj = aura_env.GetUnitObj(unit)
    if not obj then return end
    local minRange, maxRange = WeakAuras.GetRange(unit)
    obj.minRange = minRange
    obj.maxRange = maxRange
end

-- 检测单位敌对状态,事件更新，仅在正式服有效
function aura_env.UpdateFaction(unit)
    local obj = aura_env.GetUnitObj(unit)
    if not obj then return end
    obj.canAttack = UnitCanAttack("player", unit)
    obj.canAssist = UnitCanAssist("player", unit)
end

-- 检测单位存活状态
function aura_env.UpdateIsDead(unit)
    local obj = aura_env.GetUnitObj(unit)
    if not obj then return end
    obj.isDead = UnitIsDeadOrGhost(unit)
end

-- 完整刷新光环
local function UpdateAuraFull(unit)
    local obj = aura_env.GetUnitObj(unit)
    if not obj then return end
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

-- 增量更新光环,事件更新
function aura_env.UpdateAuraIncremental(unit, info)
    local obj = aura_env.GetUnitObj(unit)
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

function aura_env.CheckUnitInsight()
    if Skippy.state.CastTargetUnit then
        local obj = aura_env.GetUnitObj(Skippy.state.CastTargetUnit)
        if not obj then return end
        obj.inSight = false
        if obj.inSightTimer then
            obj.inSightTimer:Cancel()
            obj.inSightTimer = nil
        end
        obj.inSightTimer = C_Timer.NewTimer(1, function()
            obj.inSight = true
            obj.inSightTimer = nil
        end)
    end
end

-- 更新核心单位（target / focus）
function aura_env.UpdateCoreUnit(unit)
    if UnitExists(unit) then
        Skippy.Units[unit] = {}
        local obj = Skippy.Units[unit]
        local creatureType, creatureID = UnitCreatureType(unit)
        obj.exists = true
        obj.immuneSpells = {}
        obj.name = GetUnitName(unit, true) or "无目标"
        obj.GUID = UnitGUID(unit)
        obj.creatureType = creatureType or "UNKNOWN"
        obj.creatureID = creatureID or 0
        obj.isDead = UnitIsDeadOrGhost(unit)
        obj.inRange = UnitInRange(unit)
        aura_env.UpdateFaction(unit)
        aura_env.UpdateMaxAndMinRange(unit)
        aura_env.GetFullHealth(unit) -- 获取完整血量
        UpdateAuraFull(unit)         -- 更新完整光环
        -- 更新队伍成员存活状态
        if Skippy.Group and Skippy.Group[unit] then
            Skippy.Group[unit].isDead = obj.isDead
        end
    else -- 单位不存在
        Skippy.Units[unit] = nil
    end
end

aura_env.UpdateCoreUnit("target")
aura_env.UpdateCoreUnit("focus")

-- 更新姓名板单位（nameplate1~40）
function aura_env.UpdateNameplateUnit(unit)
    if UnitExists(unit) then
        Skippy.Nameplate[unit] = {}
        local obj = Skippy.Nameplate[unit]
        local creatureType, creatureID = UnitCreatureType(unit)
        obj.exists = true
        obj.name = GetUnitName(unit, true) or "无目标"
        obj.GUID = UnitGUID(unit)
        obj.creatureType = creatureType or "UNKNOWN"
        obj.creatureID = creatureID or 0
        obj.isDead = UnitIsDeadOrGhost(unit)
        aura_env.UpdateFaction(unit)
        aura_env.UpdateMaxAndMinRange(unit)
        aura_env.GetFullHealth(unit) -- 获取完整血量
        UpdateAuraFull(unit)         -- 更新完整光环
    else                             -- 单位不存在
        Skippy.Nameplate[unit] = nil
    end
end

-- 初始化姓名板单位
function aura_env.InitNameplateUnit()
    for i = 1, 40 do
        local unit = "nameplate" .. i
        aura_env.UpdateNameplateUnit(unit)
    end
end

aura_env.InitNameplateUnit()

-- 更新首领单位（boss1~5）
function aura_env.UpdateBossUnit(unit)
    if UnitExists(unit) then
        Skippy.Boss[unit] = {}
        local obj = Skippy.Boss[unit]
        local creatureType, creatureID = UnitCreatureType(unit)
        obj.exists = true
        obj.name = GetUnitName(unit, true) or "未知"
        obj.GUID = UnitGUID(unit)
        obj.creatureType = creatureType or "UNKNOWN"
        obj.creatureID = creatureID or 0
        obj.isDead = UnitIsDeadOrGhost(unit)
        aura_env.UpdateFaction(unit)        -- 更新敌对状态
        aura_env.UpdateMaxAndMinRange(unit) -- 更新单位距离
        aura_env.GetFullHealth(unit)        -- 获取完整血量
        UpdateAuraFull(unit)                -- 更新完整光环
    else
        Skippy.Boss[unit] = nil
    end
end

function aura_env.InitBossUnit()
    C_Timer.After(1, function()
        for i = 1, 5 do
            local unit = "boss" .. i
            aura_env.UpdateBossUnit(unit)
        end
    end)
end

aura_env.InitBossUnit()

-- 更新队伍单位(player, party1~4, raid1~40)
local group = {}
function aura_env.UpdateGroupUnit()
    table.wipe(group)
    Skippy.Group = {}
    for unit in WA_IterateGroupMembers() do
        table.insert(group, unit)
        if UnitExists(unit) then
            Skippy.Group[unit] = {}
            local obj = Skippy.Group[unit]
            local creatureType, creatureID = UnitCreatureType(unit)
            obj.exists = true
            obj.name = GetUnitName(unit, true) or "未知"
            obj.GUID = UnitGUID(unit)
            obj.creatureType = creatureType or "UNKNOWN"
            obj.creatureID = creatureID or 0
            obj.isDead = UnitIsDeadOrGhost(unit)
            aura_env.UpdateFaction(unit)        -- 更新敌对状态
            aura_env.UpdateMaxAndMinRange(unit) -- 更新单位距离
            aura_env.GetFullHealth(unit)        -- 获取完整血量
            UpdateAuraFull(unit)                -- 更新完整光环
        else                                    -- 单位不存在
            Skippy.Group[unit] = nil
        end
    end
end

aura_env.UpdateGroupUnit()


aura_env.updateIndex = 1

function aura_env.UpdateGroupInfo()
    local numUnits = #group
    if numUnits > 0 then
        -- 如果人数变动导致索引越界，重置索引
        if aura_env.updateIndex > numUnits then
            aura_env.updateIndex = 1
        end
        -- 执行核心逻辑：仅针对当前索引的单位
        local unit = group[aura_env.updateIndex]
        local obj = aura_env.GetUnitObj(unit)

        if obj then
            local minRange, maxRange = WeakAuras.GetRange(unit)
            if not isRetail then obj.inRange = UnitInRange(unit) end
            obj.canAssist = UnitCanAssist("player", unit)
            obj.minRange = minRange
            obj.maxRange = maxRange
        end

        -- 索引递增，准备下一帧更新下一个单位
        aura_env.updateIndex = aura_env.updateIndex + 1
        if aura_env.updateIndex > numUnits then
            aura_env.updateIndex = 1
        end
    end
end
