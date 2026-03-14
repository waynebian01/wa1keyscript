local _, fu = ...

local creat = fu.updateOrCreatTextureByIndex
local state, group, target, nameplate, fixed_blocks, blocks, keybindings, macroList, assistant_spells = {}, {}, {}, {},
    {}, {}, {}, {},
    {}
local castTargetName, castTargetUnit, init = nil, nil, false

local actionBars = fu.actionBars
local keymap = fu.keymap
local roleMap = fu.roleMap

fixed_blocks.anchor = 1        -- 锚点
fixed_blocks.class = 2         -- 职业
fixed_blocks.specIndex = 3     -- 专精
fixed_blocks.valid = 4         -- 有效性
fixed_blocks.combat = 5        -- 战斗状态
fixed_blocks.moving = 6        -- 移动状态
fixed_blocks.casting = 7       -- 施法状态
fixed_blocks.channel = 8       -- 引导状态
fixed_blocks.HealthPercent = 9 -- 血量百分比
fixed_blocks.PowerPercent = 10 -- 能量百分比

-- 创建颜色曲线
local dispelCurve = fu.dispelCurve
local curve100 = fu.creatColorCurve(1, 100)
local curve80 = fu.creatColorCurve(1, 80)
local curve255 = fu.creatColorCurve(255, 255)
local curve10 = fu.creatColorCurve(10, 100)

local function ProcessActionSlot(slot)
    -- 1. 获取动作信息并进行卫语句检查
    local actionType, spellId = GetActionInfo(slot)
    if actionType ~= "macro" and actionType ~= "spell" then
        return
    end

    -- 2. 获取法术信息并进行卫语句检查
    local spellinfo = C_Spell.GetSpellInfo(spellId)
    if not spellinfo then
        return
    end

    -- 3. 遍历动作条
    for _, bar in ipairs(actionBars) do
        -- 4. 检查槽位是否在当前动作条范围内
        if slot >= bar.startSlot and slot <= bar.endSlot then
            local slotInBar = slot - bar.startSlot + 1
            local command = bar.bindingPrefix .. slotInBar -- 构造绑定命令
            local key = GetBindingKey(command)             -- 获取绑定的按键
            -- 5. 检查是否有按键绑定
            if key then
                keybindings[spellId] = {
                    key = key,
                    slot = slot,
                    keycode = keymap[key],
                    icon = spellinfo.iconID,
                    name = spellinfo.name,
                }
                -- 如果一个动作（如法术）只需要被记录一次，
                -- 找到绑定后就可以跳出动作条循环 (break)
                -- break
            end
        end
    end
end
-- 扫描按键
local function readKeybindings()
    -- 清理并重新扫描
    table.wipe(keybindings)
    C_Timer.After(0.5, function()
        for slot = 1, 180 do
            ProcessActionSlot(slot)
        end
    end)
end

-- 遍历队伍成员, 来自WeakAuras的代码
-- @param reversed 是否逆序
-- @param forceParty 是否强制使用队伍
-- @return 迭代器
local function iterateGroupMembers(reversed, forceParty)
    local unit = (not forceParty and IsInRaid()) and 'raid' or 'party'
    local numGroupMembers = unit == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
    local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)
    return function()
        local ret
        if i == 0 and unit == 'party' then
            ret = 'player'
        elseif i <= numGroupMembers and i > 0 then
            ret = unit .. i
        end
        i = i + (reversed and -1 or 1)
        return ret
    end
end

-- ================================================================
--                          玩家信息
-- ================================================================

-- 获取玩家固定信息
local function getPlayerInfo()
    local name = UnitName("player")
    local GUID = UnitGUID("player")
    local className, classFilename, classId = UnitClass("player")
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    print(specID)
    state.name, state.GUID = name, GUID
    state.className, state.classFilename, state.classId = className, classFilename, classId
    state.specIndex, state.specID = specIndex, specID

    creat(fixed_blocks.anchor, 0)
    creat(fixed_blocks.class, classId / 255)
    creat(fixed_blocks.specIndex, specIndex / 255)
    if classId == 6 and specIndex == 3 then -- 邪恶死亡骑士, 次级食尸鬼计数
        state.lesser_ghoul = 0
        state.lesser_ghoul_floor = 0
        state.lesser_ghoul_timer = nil
    end
    blocks, macroList, assistant_spells, init = fu.GetBlockIndexByClassIDAndSpecIndex(classId, specIndex)
end

local function createSpecializationMacro()
    for i, v in ipairs(macroList) do
        fu.CreateMacro(v[1], v[2], v[3])
    end
end

-- 更新玩家有效性
local function updatePlayerValid()
    state.valid = not state.isDead and not state.mounted and not state.isChatOpen
    creat(fixed_blocks.valid, state.valid and 1 / 255 or 0)
end

-- 更新玩家战斗状态
local function updatePlayerCombat()
    state.combat = UnitAffectingCombat("player")
    creat(fixed_blocks.combat, state.combat and 1 / 255 or 0)
end

-- 更新玩家移动状态
local function updatePlayerMoving(boolean)
    state.moving = boolean
    creat(fixed_blocks.moving, state.moving and 1 / 255 or 0)
end

-- 更新玩家施法状态
local function updatePlayerCastingInfo()
    if state.casting then
        local castingDuration = UnitCastingDuration("player")
        local castingInfo = UnitCastingInfo("player")
        if castingDuration then
            local castingDurationColor = castingDuration:EvaluateRemainingDuration(curve10)
            local _, _, b = castingDurationColor:GetRGB()
            creat(fixed_blocks.casting, b)
        end
    else
        creat(fixed_blocks.casting, 0)
    end
end

-- 更新玩家引导状态
local function updatePlayerChannelingInfo()
    if state.channeling then
        local channelDuration = UnitChannelDuration("player")
        if channelDuration then
            local channelDurationColor = channelDuration:EvaluateRemainingDuration(curve10)
            local _, _, b = channelDurationColor:GetRGB()
            creat(fixed_blocks.channel, b)
        end
    else
        creat(fixed_blocks.channel, 0)
    end
end

-- 更新玩家血量信息
local function updatePlayerHealth()
    state.healthPercent = UnitHealthPercent("player", false, curve100)
    local _, _, b = state.healthPercent:GetRGB()
    creat(fixed_blocks.HealthPercent, b)
end

-- 更新玩家能量信息
local function updatePlayerPower(powerType)
    powerType = powerType or nil
    state.powerPercent = UnitPowerPercent("player", powerType, nil, curve100)
    local _, _, b = state.powerPercent:GetRGB()
    creat(fixed_blocks.PowerPercent, b)
end

local function updateRune()
    if init and blocks.runes then
        local total = 0
        for i = 1, 6 do
            total = total + GetRuneCount(i)
        end
        creat(blocks.runes, total / 255)
    end
end

-- 更新玩家[一键辅助]
local function updatePlayerAssistant()
    local spellId = C_AssistedCombat.GetNextCastSpell()
    if init and blocks.assistant and spellId then
        if assistant_spells[spellId] then
            creat(blocks.assistant, assistant_spells[spellId] / 255)
        else
            creat(blocks.assistant, 0)
        end
    end
end
-- 更新法术冷却信息
local function updateSpellCooldown()
    if init and blocks and blocks.spell_cd then
        for i, v in ipairs(blocks.spell_cd) do
            local durationObj = C_Spell.GetSpellCooldownDuration(v.spellId)
            local cooldown = C_Spell.GetSpellCooldown(v.spellId)
            local isSpellKnown = C_SpellBook.IsSpellKnown(v.spellId)
            if not isSpellKnown then
                creat(v.index, 1)
                return
            end
            if not durationObj or not cooldown then return end
            local result = durationObj:EvaluateRemainingDuration(curve255)
            local _, _, b = result:GetRGB()
            ---@diagnostic disable-next-line: undefined-field
            if cooldown.isOnGCD then b = 0 end
            creat(v.index, b)
        end
    end
end
-- 更新法术充能冷却信息
local function updateSpellChargeCooldown()
    if init and blocks and blocks.spell_charge then
        for i, v in ipairs(blocks.spell_charge) do
            local durationObj = C_Spell.GetSpellChargeDuration(v.spellId)
            local cooldown = C_Spell.GetSpellCooldown(v.spellId)
            local isSpellKnown = C_SpellBook.IsSpellKnown(v.spellId)
            if not isSpellKnown then
                creat(v.index, 1)
                return
            end
            if not durationObj or not cooldown then return end
            local result = durationObj:EvaluateRemainingDuration(curve255)
            local _, _, b = result:GetRGB()
            ---@diagnostic disable-next-line: undefined-field
            if cooldown.isOnGCD then b = 0 end
            creat(v.index, b)
        end
    end
end

-- 更新末日突降
local function updateSuddenDoom()
    if init and blocks.aura and blocks.aura.sudden_doom then
        local powerCosts = C_Spell.GetSpellPowerCost(47541)
        if powerCosts and powerCosts[1] and powerCosts[1].cost == 15 then
            creat(blocks.aura.sudden_doom, 1 / 255)
        else
            creat(blocks.aura.sudden_doom, 0)
        end
    end
end

-- 施放成功
local function updateSpellSuccess(spellID)
    if init and blocks.aura then
        if blocks.aura["虚空之盾"] and (spellID == 47540 or spellID == 1253593) then
            C_Timer.After(0.5, function()
                local spellOverride = C_SpellBook.FindSpellOverrideByID(17)
                if spellOverride == 1253593 then
                    creat(blocks.aura["虚空之盾"], 1 / 255)
                else
                    creat(blocks.aura["虚空之盾"], 0)
                end
            end)
        end
        if blocks.aura["自然迅捷"] then
            if spellID == 132158 then
                creat(blocks.aura["自然迅捷"], 1 / 255)
                C_Timer.After(30, function()
                    creat(blocks.aura["自然迅捷"], 0)
                end)
            elseif spellID == 8936 or spellID == 20484 or spellID == 339 then
                creat(blocks.aura["自然迅捷"], 0)
            end
        end
        if blocks.aura["丛林之魂"] then
            if spellID == 18562 then
                creat(blocks.aura["丛林之魂"], 1 / 255)
                C_Timer.After(15, function()
                    creat(blocks.aura["丛林之魂"], 0)
                end)
            elseif spellID == 8936 or spellID == 774 then
                creat(blocks.aura["丛林之魂"], 0)
            end
        end
        if blocks.aura.festering then
            if spellID == 85948 or spellID == 458128 then -- 脓疮打击, 脓疮毒镰
                C_Timer.After(0.5, function()
                    local spellOverride = C_SpellBook.FindSpellOverrideByID(85948)
                    if spellOverride == 458128 then
                        creat(blocks.aura.festering, 1 / 255)
                    else
                        creat(blocks.aura.festering, 0)
                    end
                end)
            end
        end

        if blocks.aura.lesser_ghoul then
            if spellID == 85948 or spellID == 458128 then -- 脓疮打击, 脓疮毒镰
                state.lesser_ghoul = math.min(8, state.lesser_ghoul + 2.5)
                state.lesser_ghoul_floor = math.floor(state.lesser_ghoul)
                creat(blocks.aura.lesser_ghoul, state.lesser_ghoul_floor / 255)
                if state.lesser_ghoul_timer then
                    state.lesser_ghoul_timer:Cancel()
                end
                state.lesser_ghoul_timer = C_Timer.NewTimer(30, function()
                    state.lesser_ghoul = 0
                    state.lesser_ghoul_floor = 0
                    state.lesser_ghoul_timer = nil
                    creat(blocks.aura.lesser_ghoul, 0)
                end)
            elseif spellID == 55090 then -- 天灾打击
                state.lesser_ghoul = math.max(0, state.lesser_ghoul - 1)
                state.lesser_ghoul_floor = math.floor(state.lesser_ghoul)
                creat(blocks.aura.lesser_ghoul, state.lesser_ghoul_floor / 255)
            end
        end

        if blocks.aura.forbidden_knowledge then
            if spellID == 42650 then -- 亡者大军
                creat(blocks.aura.forbidden_knowledge, 1 / 255)
                C_Timer.After(30, function()
                    creat(blocks.aura.forbidden_knowledge, 0)
                end)
            end
        end
    end
end

-- 更新法术发光效果
local function updateSpellOverlay(spellId)
    local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellId)
    if spellId == 2061 and blocks.aura["圣光涌动"] then
        creat(blocks.aura["圣光涌动"], isSpellOverlayed and 1 / 255 or 0)
    end
    if spellId == 49998 and blocks.aura.dark_succor then
        creat(blocks.aura.dark_succor, isSpellOverlayed and 1 / 255 or 0)
    end
    if spellId == 8936 and blocks.aura["节能施法"] then
        creat(blocks.aura["节能施法"], isSpellOverlayed and 1 / 255 or 0)
    end
end

-- 获取玩家形态
local function updateShapeshiftForm()
    state.shapeshiftFormID = GetShapeshiftFormID()
    if init and blocks.stance then
        creat(blocks.stance, state.shapeshiftFormID and state.shapeshiftFormID / 255 or 0)
    end
end

-- ================================================================
--                          目标信息
-- ================================================================
-- 更新目标是否有效
local function updateTargetValid()
    target.valid = target.canAttack and target.inRange and not target.isDead
    if init and blocks.target_valid then
        creat(blocks.target_valid, target.valid and 1 / 255 or 0)
    end
end

-- 更新目标是否可以攻击
local function updateTargetCanAttack()
    target.canAttack = UnitCanAttack("player", "target")
    updateTargetValid()
end

-- 更新目标距离, 0:不在范围内, 1:近战范围, 2:远程范围
local function updateTargetDistance()
    local distance = 0
    local melee = fu.HarmfulMeleeSpellId and C_Spell.IsSpellInRange(fu.HarmfulMeleeSpellId, "target")
    local remote = fu.HarmfulRemoteSpellId and C_Spell.IsSpellInRange(fu.HarmfulRemoteSpellId, "target")
    if melee then
        -- print("近战范围")
        distance = 1
    elseif remote then
        -- print("远程范围")
        distance = 2
    else
        -- print("不在范围内")
        distance = 0
    end
    return distance
end

local function updateTargetDistanceBlock()
    C_Timer.After(0.2, function()
        target.distance = updateTargetDistance()
        if init and blocks.target_distance then
            creat(blocks.target_distance, target.distance / 255)
        end
    end)
end

-- 更新目标是否在范围内
local function updateTargetInRange()
    target.inRange = fu.HarmfulSpellId and C_Spell.IsSpellInRange(fu.HarmfulSpellId, "target")
    updateTargetDistanceBlock()
    updateTargetValid()
end

-- 更新目标是否死亡
local function updateTargetDeath()
    target.isDead = UnitIsDeadOrGhost("target")
    updateTargetValid()
end

-- 更新目标生命值
local function updateTargetHealth()
    target.healthPercent = UnitHealthPercent("target", false, curve100)
    local _, _, b = target.healthPercent:GetRGB()
    if init and blocks.target_health then
        creat(blocks.target_health, b)
    end
end

-- 更新目标完整信息
local function updateTargetFullInfo()
    updateTargetCanAttack()
    updateTargetInRange()
    updateTargetDeath()
    updateTargetHealth()
end


-- ================================================================
--                          姓名版信息
-- ================================================================

-- 更新目标是否在范围内
local function updateNameplateCount()
    if blocks.enemy_count and fu.HarmfulSpellId then
        nameplate.count = 0
        for i = 1, 40 do
            local unit = "nameplate" .. i
            if UnitExists(unit) and UnitCanAttack("player", unit) and C_Spell.IsSpellInRange(fu.HarmfulSpellId, unit) then
                nameplate.count = nameplate.count + 1
            end
        end
        creat(blocks.enemy_count, nameplate.count / 255)
    end
end


-- ================================================================
--                          队伍信息
-- ================================================================

local function updateUnitHealthInfo(unit)
    local obj = group[unit]
    if not obj then return end
    local healthPercent = UnitHealthPercent(unit, false, obj.curve)
    local _, _, b = healthPercent:GetRGB()
    obj.healthPercent = b
    if init and blocks.unit and blocks.unit.HealthPercent and blocks.unit_start and blocks.unit_num then
        local index = blocks.unit_start + obj.index * blocks.unit_num + blocks.unit.HealthPercent
        creat(index, obj.healthPercent)
    end
end

local function updateUnitRole(unit)
    local obj = group[unit]
    if not obj then return end
    if init and blocks.unit and blocks.unit.Role then
        local index = blocks.unit_start + obj.index * blocks.unit_num + blocks.unit.Role
        if obj.valid then
            -- print(obj.name, obj.role)
            creat(index, roleMap[obj.role] and roleMap[obj.role] / 255 or 0)
        else
            -- print(obj.name, "无效")
            creat(index, 0)
        end
    end
end

local function updateUnitValid(unit)
    local obj = group[unit]
    if not obj then return end
    obj.valid = not obj.isDead and obj.inRange and obj.canAssist and obj.inSight
    updateUnitRole(unit)
end

local function updateUnitInRange(unit)
    local obj = group[unit]
    if not obj then return end
    obj.inRange = fu.HelpfulSpellId and C_Spell.IsSpellInRange(fu.HelpfulSpellId, unit)
    updateUnitValid(unit)
end

local function updateUnitCanAssist(unit)
    local obj = group[unit]
    if not obj then return end
    obj.canAssist = UnitCanAssist("player", unit)
    updateUnitValid(unit)
end

local function updateUnitDeath(unitGUID)
    for unit, data in pairs(group) do
        if data.GUID == unitGUID then
            data.isDead = true
            -- print(unit, data.GUID, data.name)
            updateUnitValid(unit)
        end
    end
end

local function updateUnitDeathByHealthInfo(unit)
    local obj = group[unit]
    if not obj then return end
    obj.isDead = UnitIsDeadOrGhost(unit)
    updateUnitValid(unit)
end

local function updateUnitInSight(unit)
    local obj = group[unit]
    if not obj then return end
    obj.inSight = false
    -- print("目标不在视野中", obj.name)
    if obj.inSightTimer then
        obj.inSightTimer:Cancel()
        obj.inSightTimer = nil
    end
    obj.inSightTimer = C_Timer.NewTimer(1.5, function()
        obj.inSight = true
        obj.inSightTimer = nil
        -- print("目标在视野中", obj.name)
        updateUnitValid(unit)
    end)
    updateUnitValid(unit)
end

local function updateUnitCurve(unit)
    local obj = group[unit]
    if not obj then return end
    obj.curve = curve80
    if obj.curveTimer then
        obj.curveTimer:Cancel()
    end
    obj.curveTimer = C_Timer.NewTimer(1, function()
        if group[unit] and group[unit] == obj then
            obj.curve = curve100
            obj.curveTimer = nil
        end
        updateUnitHealthInfo(unit)
    end)
end

local function updateUnitFullAura(unit)
    local obj = group[unit]
    if not obj then return end
    if init and blocks.unit and blocks.unit.aura then
        for _, spellIds in pairs(blocks.unit.aura) do
            for _, spellId in ipairs(spellIds) do
                local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spellId)
                if aura and aura.sourceUnit == "player" then
                    obj.aura[aura.auraInstanceID] = aura
                end
            end
        end
    end
end

local function OnUpdateUnitAura()
    if not init or not blocks.unit or not blocks.unit.aura then return end
    for unit, data in pairs(group) do
        for i, spellIds in pairs(blocks.unit.aura) do
            local index = blocks.unit_start + data.index * blocks.unit_num + i
            local hasAura = false
            for j, spellId in ipairs(spellIds) do
                local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spellId)
                if aura and aura.sourceUnit == "player" then
                    hasAura = true
                    local duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                    local auraduration = duration:EvaluateRemainingDuration(curve255)
                    local _, _, b = auraduration:GetRGB()
                    creat(index, b)
                end
            end
            if not hasAura then
                creat(index, 0)
            end
        end
    end
end

local function OnUpdateUnitRejuv()
    if not init or not blocks.unit or not blocks.unit.rejuv then return end
    for unit, data in pairs(group) do
        local has_rejuv_count = 0
        local index = blocks.unit_start + data.index * blocks.unit_num + blocks.unit.rejuv
        local rejuv_aura = C_UnitAuras.GetUnitAuraBySpellID(unit, 774)
        local rejuv2_aura = C_UnitAuras.GetUnitAuraBySpellID(unit, 155777)
        if rejuv_aura and rejuv_aura.sourceUnit == "player" then
            has_rejuv_count = has_rejuv_count + 1
        end
        if rejuv2_aura and rejuv2_aura.sourceUnit == "player" then
            has_rejuv_count = has_rejuv_count + 1
        end
        creat(index, has_rejuv_count / 255)
    end
end

local function getAuraDispelTypeColor(unit)
    local obj = group[unit]
    if not obj or not init or not blocks.unit or not blocks.unit.dispel then return end
    local index = blocks.unit_start + obj.index * blocks.unit_num + blocks.unit.dispel
    local auraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs(unit, "HARMFUL|RAID_PLAYER_DISPELLABLE", 1, 4)
    if auraInstanceIDs and #auraInstanceIDs > 0 then
        local color = C_UnitAuras.GetAuraDispelTypeColor(unit, auraInstanceIDs[1], dispelCurve)
        if color then
            creat(index, color.b)
        end
    else
        creat(index, 0)
    end
end

local function clearGroupBlocks()
    for i = 25, 200 do
        creat(i, 0)
    end
end

local function updateGroupCount()
    if not init or not blocks.members_count then return end
    local count = GetNumGroupMembers()
    creat(blocks.members_count, count / 255)
end

local function updateGroup()
    table.wipe(group)
    clearGroupBlocks()
    local i = 0
    for unit in iterateGroupMembers() do
        group[unit] = {
            index = i,
            name = GetUnitName(unit, true),
            GUID = UnitGUID(unit),
            role = UnitGroupRolesAssigned(unit),
            isDead = UnitIsDeadOrGhost(unit),
            inRange = fu.HelpfulSpellId and C_Spell.IsSpellInRange(fu.HelpfulSpellId, unit),
            canAttack = UnitCanAttack("player", unit),
            canAssist = UnitCanAssist("player", unit),
            inSight = true,
            inSightTimer = nil,
            curve = curve100,
            curveTimer = nil,
            aura = {}
        }
        updateUnitValid(unit)
        updateUnitHealthInfo(unit)
        updateUnitFullAura(unit)
        updateUnitRole(unit)
        i = i + 1
    end
end


-- ================================================================
--                          注册事件
-- ================================================================
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
function frame:PLAYER_ENTERING_WORLD()
    getPlayerInfo()
    state.isDead = UnitIsDeadOrGhost("player")
    state.mounted = IsMounted()
    state.moving = IsPlayerMoving()
    state.isChatOpen = false
    state.casting = false
    state.channeling = false
    updatePlayerMoving(IsPlayerMoving())
    updatePlayerValid()
    updatePlayerCombat()
    updatePlayerHealth()
    updatePlayerPower()
    updatePlayerAssistant()
    updateGroup()
    updateTargetFullInfo()
    readKeybindings() -- 读取按键绑定
    createSpecializationMacro()
    updateShapeshiftForm()
    updateRune()
end

frame:RegisterEvent("PLAYER_TALENT_UPDATE")
function frame:PLAYER_TALENT_UPDATE()
    getPlayerInfo()
    updatePlayerMoving(IsPlayerMoving())
    updatePlayerValid()
    updatePlayerCombat()
    updatePlayerHealth()
    updatePlayerPower()
    updatePlayerAssistant()
    updateGroup()
    updateTargetFullInfo()
    readKeybindings() -- 读取按键绑定
    updateShapeshiftForm()
end

frame:RegisterEvent("PLAYER_DEAD")
function frame:PLAYER_DEAD()
    state.isDead = UnitIsDeadOrGhost("player")
    updatePlayerValid()
end

frame:RegisterEvent("PLAYER_ALIVE")
function frame:PLAYER_ALIVE()
    state.isDead = UnitIsDeadOrGhost("player")
    updatePlayerValid()
end

frame:RegisterEvent("PLAYER_UNGHOST")
function frame:PLAYER_UNGHOST()
    state.isDead = UnitIsDeadOrGhost("player")
    updatePlayerValid()
end

frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
function frame:PLAYER_MOUNT_DISPLAY_CHANGED()
    state.mounted = IsMounted()
    updatePlayerValid()
end

-- 战斗状态更新
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
function frame:PLAYER_REGEN_DISABLED()
    updateTargetCanAttack()
    updatePlayerCombat()
end

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
function frame:PLAYER_REGEN_ENABLED()
    updateTargetCanAttack()
    updatePlayerCombat()
end

-- 移动状态更新
frame:RegisterEvent("PLAYER_STARTED_MOVING")
function frame:PLAYER_STARTED_MOVING()
    updatePlayerMoving(true)
end

frame:RegisterEvent("PLAYER_STOPPED_MOVING")
function frame:PLAYER_STOPPED_MOVING()
    updatePlayerMoving(false)
end

frame:RegisterEvent("UNIT_SPELLCAST_SENT")
function frame:UNIT_SPELLCAST_SENT(player, targetName)
    if not issecretvalue(targetName) then
        for unit, data in pairs(group) do
            -- print(data.name, targetName)
            if data.name == targetName then
                castTargetUnit = unit
                castTargetName = targetName
                break
            end
            castTargetUnit = nil
            castTargetName = nil
        end
        -- print(castTargetUnit, castTargetName)
    end
end

-- 施法状态
frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
function frame:UNIT_SPELLCAST_START(unit, spellId)
    state.casting = true
end

frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
function frame:UNIT_SPELLCAST_STOP(unit, spellId)
    state.casting = false
end

-- 引导状态
frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
function frame:UNIT_SPELLCAST_CHANNEL_START(unit, spellId)
    state.channeling = true
end

frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
function frame:UNIT_SPELLCAST_CHANNEL_STOP(unit, spellId)
    state.channeling = false
end

frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
function frame:UNIT_SPELLCAST_SUCCEEDED(unitTarget, castGUID, spellID, castBarID)
    if not issecretvalue(spellID) then
        updateSpellSuccess(spellID)
    end
    updateTargetDistanceBlock()
end

frame:RegisterEvent("UNIT_HEALTH")
function frame:UNIT_HEALTH(unit)
    if unit == "player" then
        updatePlayerHealth()
    end
    if unit == "target" then
        updateTargetHealth()
    end
    if group[unit] then
        updateUnitHealthInfo(unit)
        updateUnitDeathByHealthInfo(unit)
    end
end

frame:RegisterEvent("UNIT_MAXHEALTH")
function frame:UNIT_MAXHEALTH(unit)
    if unit == "player" then
        updatePlayerHealth()
    end
    if group[unit] then
        updateUnitHealthInfo(unit)
        updateUnitDeathByHealthInfo(unit)
    end
end

frame:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
function frame:UNIT_HEAL_ABSORB_AMOUNT_CHANGED(unit)
    updateUnitCurve(unit)
    if unit == "player" then
        updatePlayerHealth()
    end
    if group[unit] then
        updateUnitHealthInfo(unit)
        updateUnitDeathByHealthInfo(unit)
    end
end

frame:RegisterEvent("UNIT_HEAL_PREDICTION")
function frame:UNIT_HEAL_PREDICTION(unit)
    if unit == "player" then
        updatePlayerHealth()
    end
    if group[unit] then
        updateUnitHealthInfo(unit)
        updateUnitDeathByHealthInfo(unit)
    end
end

-- 能量更新
frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
function frame:UNIT_POWER_UPDATE(unit)
    updatePlayerPower()
    updateRune()
end

-- Hook 所有默认聊天框
for i = 1, NUM_CHAT_WINDOWS do
    local editBox = _G["ChatFrame" .. i .. "EditBox"]
    if editBox then
        editBox:HookScript("OnEditFocusGained", function()
            state.isChatOpen = true
            updatePlayerValid()
        end)
        editBox:HookScript("OnEditFocusLost", function()
            state.isChatOpen = false
            updatePlayerValid()
        end)
    end
end

frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
function frame:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(spellId)
    updateSpellOverlay(spellId)
end

function frame:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(spellId)
    updateSpellOverlay(spellId)
end

frame:RegisterEvent("GROUP_ROSTER_UPDATE")
function frame:GROUP_ROSTER_UPDATE()
    castTargetName, castTargetUnit = nil, nil
    updateGroupCount()
    updateGroup()
end

frame:RegisterEvent("UNIT_DIED")
function frame:UNIT_DIED(unitGUID)
    if not issecretvalue(unitGUID) then
        updateUnitDeath(unitGUID)
    end
end

frame:RegisterEvent("UNIT_FLAGS")
function frame:UNIT_FLAGS(unit)
    if unit == "target" then
        updateTargetCanAttack()
    end
    updateUnitCanAssist(unit)
end

frame:RegisterEvent("UNIT_IN_RANGE_UPDATE")
function frame:UNIT_IN_RANGE_UPDATE(unit)
    updateUnitInRange(unit)
end

frame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
function frame:SPELL_RANGE_CHECK_UPDATE()
    updateTargetInRange()
    updateNameplateCount()
    for unit, data in pairs(group) do
        updateUnitInRange(unit)
    end
end

frame:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
function frame:ACTION_RANGE_CHECK_UPDATE(slot, isInRange, checksRange)
    updateTargetInRange()
    updateNameplateCount()
    C_Timer.After(0.2, function() updateTargetDistanceBlock() end)
end

frame:RegisterEvent("UI_ERROR_MESSAGE")
function frame:UI_ERROR_MESSAGE(errorType, message)
    if message == "目标不在视野中" then
        updateUnitInSight(castTargetUnit)
    elseif message == "距离太远。" then
        updateTargetInRange()
    end
end

frame:RegisterEvent("PLAYER_TARGET_CHANGED")
function frame:PLAYER_TARGET_CHANGED()
    updateTargetFullInfo()
end

frame:RegisterEvent("UPDATE_BINDINGS")
function frame:UPDATE_BINDINGS()
    readKeybindings()
end

frame:RegisterEvent("SPELLS_CHANGED")
function frame:SPELLS_CHANGED()
    readKeybindings()
end

frame:RegisterEvent("ACTIONBAR_SHOWGRID")
function frame:ACTIONBAR_SHOWGRID()
    readKeybindings()
end

frame:RegisterEvent("ACTIONBAR_HIDEGRID")
function frame:ACTIONBAR_HIDEGRID()
    readKeybindings()
end

frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
function frame:NAME_PLATE_UNIT_ADDED(unit)
    updateNameplateCount()
    updateTargetCanAttack()
end

frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
function frame:NAME_PLATE_UNIT_REMOVED(unit)
    updateNameplateCount()
end

frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
function frame:UPDATE_SHAPESHIFT_FORM()
    updateShapeshiftForm()
end

frame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
function frame:UPDATE_SHAPESHIFT_FORMS()
    updateShapeshiftForm()
end

frame:RegisterEvent("UNIT_AURA")
function frame:UNIT_AURA(unit, info)
    local obj = group[unit]
    if not obj then return end
    getAuraDispelTypeColor(unit)
    if info.isFullUpdate then
        updateUnitFullAura(unit)
        return
    elseif info.addedAuras then
        for k, v in pairs(info.addedAuras) do
            if not issecretvalue(v.spellId) then
                obj.aura[v.auraInstanceID] = v
            end
        end
    elseif info.updatedAuraInstanceIDs then
        for _, v in pairs(info.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, v)
            if aura and not issecretvalue(aura.spellId) then
                obj.aura[aura.auraInstanceID] = aura
            end
        end
    elseif info.removedAuraInstanceIDs then
        for _, v in pairs(info.removedAuraInstanceIDs) do
            obj.aura[v] = nil
        end
    end
end

local elapsed = 0
frame:SetScript("OnUpdate", function(_, update)
    elapsed = elapsed + update
    if elapsed > 0.1 then
        updateSuddenDoom()
        updateSpellCooldown()
        updateSpellChargeCooldown()
        updatePlayerCastingInfo()
        updatePlayerChannelingInfo()
        OnUpdateUnitAura()
        OnUpdateUnitRejuv()
        updatePlayerAssistant()
    end
end)
