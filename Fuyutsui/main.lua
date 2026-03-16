local _, fu = ...

local creat = fu.updateOrCreatTextureByIndex
local state, group, target, nameplate, fixed_blocks, blocks, assistant, group_list = {}, {}, {}, {}, {}, {}, {}, {}
local group_show, group_unit_start, group_block_num, group_blocks = false, 40, 7, {}
local castTargetName, castTargetUnit, updateIndex = nil, nil, 1
local updateSpellSuccess, updateSpellOverlay, updateOnUpdate, updateSpecInfo,
CreateClassMacro, spellActivationOverlayShow, spellActivationOverlayHide
local roleMap = fu.roleMap
local enumPowerType = fu.EnumPowerType

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

-- ================================================================
--                          玩家信息
-- ================================================================

-- 获取玩家固定信息
local function getPlayerInfo()
    local name = UnitName("player")
    local GUID = UnitGUID("player")
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(specIndex)

    blocks, assistant = fu.blocks, fu.assistant_spells
    group_show, group_unit_start, group_block_num, group_blocks = fu.group_show, fu.group_unit_start, fu.group_block_num,
        fu.group_blocks
    state.name, state.GUID = name, GUID
    state.className, state.classFilename, state.classId = fu.className, fu.classFilename, fu.classId
    state.specIndex, state.specID = specIndex, specID
    updateSpellSuccess = fu.updateSpellSuccess
    updateSpellOverlay = fu.updateSpellOverlay
    updateOnUpdate = fu.updateOnUpdate
    updateSpecInfo = fu.updateSpecInfo
    CreateClassMacro = fu.CreateClassMacro
    spellActivationOverlayShow = fu.spellActivationOverlayShow
    spellActivationOverlayHide = fu.spellActivationOverlayHide
    if CreateClassMacro then CreateClassMacro() end
    if updateSpecInfo then updateSpecInfo(specIndex) end
    state.powerType = fu.powerType or nil
    creat(fixed_blocks.anchor, 0)
    creat(fixed_blocks.class, fu.classId / 255)
    creat(fixed_blocks.specIndex, specIndex / 255)
end

-- 更新玩家有效性
local function updatePlayerValid()
    state.valid = not state.isDead and not state.mounted and not state.isChatOpen
    creat(fixed_blocks.valid, state.valid and 1 / 255 or 0)
end

local function updatePlayerMounted()
    state.mounted = IsMounted() or state.shapeshiftFormID == 27 or state.shapeshiftFormID == 3 or
        state.shapeshiftFormID == 29
    updatePlayerValid()
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
        local cast = UnitCastingDuration("player")
        if cast then
            local castingDurationColor = cast:EvaluateRemainingDuration(curve10)
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
        local channel = UnitChannelDuration("player")
        if channel then
            local channelDurationColor = channel:EvaluateRemainingDuration(curve10)
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
    if (state.powerType and powerType == state.powerType) or state.powerType == nil or powerType == nil then
        state.powerPercent = UnitPowerPercent("player", enumPowerType[state.powerType], nil, curve100)
        local _, _, b = state.powerPercent:GetRGB()
        creat(fixed_blocks.PowerPercent, b)
    end
    if powerType == "COMBO_POINTS" and blocks.comboPoints then
        local power = UnitPower("player", 4)
        creat(blocks.comboPoints, power / 255)
    end
    if powerType == "HOLY_POWER" and blocks.holyPower then
        local power = UnitPower("player", 9)
        creat(blocks.holyPower, power / 255)
    end
end

local function updateRune()
    if blocks and blocks.runes then
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
    if blocks and blocks.assistant and spellId then
        if assistant[spellId] then
            creat(blocks.assistant, assistant[spellId] / 255)
        else
            creat(blocks.assistant, 0)
        end
    end
end
-- 更新法术冷却信息
local function updateSpellCooldown()
    if blocks and blocks.spell_cd then
        for k, v in ipairs(blocks.spell_cd) do
            local isSpellKnown = C_SpellBook.IsSpellKnown(v.spellId)
            if isSpellKnown then
                local durationObj = C_Spell.GetSpellCooldownDuration(v.spellId)
                local cooldown = C_Spell.GetSpellCooldown(v.spellId)
                if durationObj and cooldown then
                    local result = durationObj:EvaluateRemainingDuration(curve255)
                    local _, _, b = result:GetRGB()
                    ---@diagnostic disable-next-line: undefined-field
                    if cooldown.isOnGCD then b = 0 end
                    creat(v.index, b)
                else
                    creat(v.index, 1)
                end
            else
                creat(v.index, 1)
            end
        end
    end
end
-- 更新法术充能冷却信息
local function updateSpellChargeCooldown()
    if blocks and blocks.spell_charge then
        for _, v in ipairs(blocks.spell_charge) do
            local isSpellKnown = C_SpellBook.IsSpellKnown(v.spellId)
            if isSpellKnown then
                local durationObj = C_Spell.GetSpellChargeDuration(v.spellId)
                local result = durationObj:EvaluateRemainingDuration(curve255)
                if durationObj then
                    local _, _, b = result:GetRGB()
                    creat(v.index, b)
                else
                    creat(v.index, 1)
                end
            else
                creat(v.index, 1)
            end
        end
    end
end

-- 获取玩家形态
local function updateShapeshiftForm()
    state.shapeshiftFormID = GetShapeshiftFormID()
    if blocks and blocks.stance then
        creat(blocks.stance, state.shapeshiftFormID and state.shapeshiftFormID / 255 or 0)
    end
end

-- ================================================================
--                          目标信息
-- ================================================================
-- 更新目标是否有效
local function updateTargetValid()
    target.valid = target.canAttack and target.inRange and not target.isDead
    if blocks and blocks.target_valid then
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
        distance = 1
    elseif remote then
        distance = 2
    else
        distance = 0
    end
    return distance
end

local function updateTargetDistanceBlock()
    target.distance = updateTargetDistance()
    if blocks and blocks.target_distance then
        creat(blocks.target_distance, target.distance / 255)
    end
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
    if blocks and blocks.target_health then
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
    if blocks and blocks.enemy_count and fu.HarmfulSpellId then
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
    if not group_show or not obj then return end
    local index = group_unit_start + obj.index * group_block_num + group_blocks.healthPercent
    local healthPercent = UnitHealthPercent(unit, false, obj.curve)
    local _, _, b = healthPercent:GetRGB()
    obj.healthPercent = b
    creat(index, obj.healthPercent)
end

local function updateUnitRole(unit)
    local obj = group[unit]
    if not group_show or not obj then return end
    local index = group_unit_start + obj.index * group_block_num + group_blocks.role
    if obj.valid then
        creat(index, roleMap[obj.role] and roleMap[obj.role] / 255 or 0)
    else
        creat(index, 0)
    end
end

local function updateUnitValid(unit)
    local obj = group[unit]
    if not obj then return end
    obj.valid = not obj.isDead and obj.inRange and obj.canAssist and obj.inSight
    updateUnitRole(unit)
end

local function updateGroupInRange()
    local numUnits = #group_list
    if numUnits > 1 then
        local unit = group_list[updateIndex]
        local obj = group[unit]
        if fu.HelpfulSpellId and obj then
            obj.inRange = C_Spell.IsSpellInRange(fu.HelpfulSpellId, unit)
            obj.canAssist = UnitCanAssist("player", unit)
            updateUnitValid(unit)
        end
        updateIndex = updateIndex + 1
        if updateIndex > numUnits then
            updateIndex = 1
        end
    end
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
end

local function OnUpdateUnitAura()
    if not group_show then return end
    for unit, data in pairs(group) do
        for i, spellIds in pairs(group_blocks.aura) do
            local index = group_unit_start + data.index * group_block_num + i
            local hasAura = false
            for j, spellId in ipairs(spellIds) do
                local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spellId)
                if aura and aura.sourceUnit == "player" then
                    hasAura = true
                    if aura.expirationTime == 0 then
                        creat(index, 1)
                    else
                        local duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                        local auraduration = duration:EvaluateRemainingDuration(curve255)
                        local _, _, b = auraduration:GetRGB()
                        creat(index, b)
                    end
                end
            end
            if not hasAura then
                creat(index, 0)
            end
        end
    end
end

local function getAuraDispelTypeColor(unit)
    local obj = group[unit]
    if not group_show or not obj then return end
    local index = group_unit_start + obj.index * group_block_num + group_blocks.dispel
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
    for i = 40, 200 do
        creat(i, 0)
    end
end

local function updateGroupCount()
    if not blocks.members_count then return end
    local count = GetNumGroupMembers()
    creat(blocks.members_count, count / 255)
end

local function updateGroup()
    table.wipe(group)
    clearGroupBlocks()
    local i = 0
    for unit in fu.IterateGroupMembers() do
        table.insert(group_list, unit)
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
    fu.group = group
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
    updatePlayerMounted()
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
    fu.readKeybindings() -- 读取按键绑定
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
    fu.readKeybindings() -- 读取按键绑定
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
    updatePlayerMounted()
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
    if not issecretvalue(spellID) and type(updateSpellSuccess) == "function" then
        updateSpellSuccess(spellID)
    end
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
function frame:UNIT_POWER_UPDATE(unit, powerType)
    updatePlayerPower(powerType)
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

--[[frame:RegisterEvent("UNIT_IN_RANGE_UPDATE")
function frame:UNIT_IN_RANGE_UPDATE(unit, inRange)

end]]

frame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
function frame:SPELL_RANGE_CHECK_UPDATE()
    updateTargetInRange()
    updateNameplateCount()
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
    updatePlayerMounted()
end

frame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
function frame:UPDATE_SHAPESHIFT_FORMS()
    updateShapeshiftForm()
    updatePlayerMounted()
end

frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_SHOW")
function frame:SPELL_ACTIVATION_OVERLAY_SHOW(spellId)
    spellActivationOverlayShow(spellId)
end

frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_HIDE")
function frame:SPELL_ACTIVATION_OVERLAY_HIDE(spellId)
    spellActivationOverlayHide(spellId)
end

frame:RegisterEvent("UNIT_AURA")
function frame:UNIT_AURA(unit, info)
    local obj = group[unit]
    if not obj then return end
    local testaura = C_UnitAuras.GetPlayerAuraBySpellID(1254252)
    if testaura then print("测试:", testaura.applications) end
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

local timer02 = 0
local timer10 = 0
frame:SetScript("OnUpdate", function(_, update)
    timer02 = timer02 + update
    timer10 = timer10 + update
    updatePlayerCastingInfo()
    updatePlayerChannelingInfo()
    if timer02 > 0.2 then
        updateSpellCooldown()
        updateSpellChargeCooldown()
        OnUpdateUnitAura()
        updatePlayerAssistant()
        updateGroupInRange()
        timer02 = 0
    end
    if timer10 >= 1 then
        updateTargetDistanceBlock()
        if updateOnUpdate then updateOnUpdate() end
        timer10 = 0
    end
end)
