local addonName, SK = ...




local creat = SK.updateOrCreatTextureByIndex
local state, group, target, fixed_blocks, blocks, keybindings, macroList, assistant_spells = {}, {}, {}, {}, {}, {}, {},
    {}
local castTargetName, castTargetUnit, init = nil, nil, false

local actionBars = {
    { startSlot = 1,   endSlot = 12,  bindingPrefix = "ACTIONBUTTON" },
    { startSlot = 13,  endSlot = 24,  bindingPrefix = "ACTIONBUTTON" },
    { startSlot = 25,  endSlot = 36,  bindingPrefix = "MULTIACTIONBAR3BUTTON" },
    { startSlot = 37,  endSlot = 48,  bindingPrefix = "MULTIACTIONBAR4BUTTON" },
    { startSlot = 49,  endSlot = 60,  bindingPrefix = "MULTIACTIONBAR2BUTTON" },
    { startSlot = 61,  endSlot = 72,  bindingPrefix = "MULTIACTIONBAR1BUTTON" },
    { startSlot = 73,  endSlot = 84,  bindingPrefix = "ACTIONBUTTON" }, -- 战斗姿态, 猫形态, 潜行, 暗影
    { startSlot = 85,  endSlot = 96,  bindingPrefix = "ACTIONBUTTON" }, -- 防御姿态,
    { startSlot = 97,  endSlot = 108, bindingPrefix = "ACTIONBUTTON" }, -- 狂暴姿态, 熊形态
    { startSlot = 109, endSlot = 120, bindingPrefix = "ACTIONBUTTON" }, -- 枭兽形态
    { startSlot = 121, endSlot = 143, bindingPrefix = "ACTIONBUTTON" },
    { startSlot = 145, endSlot = 156, bindingPrefix = "MULTIACTIONBAR5BUTTON" },
    { startSlot = 157, endSlot = 168, bindingPrefix = "MULTIACTIONBAR6BUTTON" },
    { startSlot = 169, endSlot = 180, bindingPrefix = "MULTIACTIONBAR7BUTTON" }
}
local keymap = {
    ["1"] = 49,
    ["2"] = 50,
    ["3"] = 51,
    ["4"] = 52,
    ["5"] = 53,
    ["6"] = 54,
    ["7"] = 55,
    ["8"] = 56,
    ["9"] = 57,
    ["0"] = 48,

    ["F1"] = 112,
    ["F2"] = 113,
    ["F3"] = 114,
    ["F4"] = 115,
    ["F5"] = 116,
    ["F6"] = 117,
    ["F7"] = 118,
    ["F8"] = 119,
    ["F9"] = 120,
    ["F10"] = 121,
    ["F11"] = 122,
    ["F12"] = 123,

    ["Q"] = 81,
    ["W"] = 87,
    ["E"] = 69,
    ["R"] = 82,
    ["T"] = 84,
    ["Y"] = 89,
    ["U"] = 85,
    ["I"] = 73,
    ["O"] = 79,
    ["P"] = 80,
    ["A"] = 65,
    ["S"] = 83,
    ["D"] = 68,
    ["F"] = 70,
    ["G"] = 71,
    ["H"] = 72,
    ["J"] = 74,
    ["K"] = 75,
    ["L"] = 76,
    ["Z"] = 90,
    ["X"] = 88,
    ["C"] = 67,
    ["V"] = 86,
    ["B"] = 66,
    ["N"] = 78,
    ["M"] = 77,

    ["NUMPAD0"] = 96,
    ["NUMPAD1"] = 97,
    ["NUMPAD2"] = 98,
    ["NUMPAD3"] = 99,
    ["NUMPAD4"] = 100,
    ["NUMPAD5"] = 101,
    ["NUMPAD6"] = 102,
    ["NUMPAD7"] = 103,
    ["NUMPAD8"] = 104,
    ["NUMPAD9"] = 105,
    ["NUMPADMULTIPLY"] = 106,
    ["NUMPADPLUS"] = 107,
    ["NUMPADMINUS"] = 109,
    ["NUMPADDECIMAL"] = 110,
    ["NUMPADDIVIDE"] = 111,

    ["N0"] = 96,  -- 0x60
    ["N1"] = 97,  -- 0x61
    ["N2"] = 98,  -- 0x62
    ["N3"] = 99,  -- 0x63
    ["N4"] = 100, -- 0x64
    ["N5"] = 101, -- 0x65
    ["N6"] = 102, -- 0x66
    ["N7"] = 103, -- 0x67
    ["N8"] = 104, -- 0x68
    ["N9"] = 105, -- 0x69
    ["N*"] = 106, -- 0x6A
    ["N+"] = 107, -- 0x6B
    ["N-"] = 109, -- 0x6D
    ["N."] = 110, -- 0x6E
    ["N/"] = 111, -- 0x6F

    ["SPACE"] = 32,
    ["="] = 187,
    ["EQUALS"] = 187, -- WoW可能返回EQUALS而不是=
    ["-"] = 189,
    ["MINUS"] = 189,  -- WoW可能返回MINUS而不是-
    ["["] = 219,
    ["]"] = 221,
    ["\\"] = 220,
    [";"] = 186,
    ["SEMICOLON"] = 186, -- WoW可能返回SEMICOLON而不是;
    ["'"] = 222,
    [","] = 188,
    ["COMMA"] = 188,  -- WoW可能返回COMMA而不是,
    ["."] = 190,
    ["PERIOD"] = 190, -- WoW可能返回PERIOD而不是.
    ["/"] = 191,
}
local roleMap = {
    ["TANK"] = 1,
    ["HEALER"] = 2,
    ["DAMAGER"] = 3,
    ["NONE"] = 0,
}
local healerBuffs = {
    -- Preservation Evoker
    355941,      -- Dream Breath
    363502,      -- Dream Flight
    364343,      -- Echo
    366155,      -- Reversion
    367364,      -- Echo Reversion
    373267,      -- Lifebind
    376788,      -- Echo Dream Breath
    -- Augmentation Evoker
    360827,      -- Blistering Scales
    395152,      -- Ebon Might
    410089,      -- Prescience
    410263,      -- Inferno's Blessing
    410686,      -- Symbiotic Bloom
    413984,      -- Shifting Sands
    -- Resto Druid
    774,         -- Rejuv
    8936,        -- Regrowth
    33763,       -- Lifebloom
    48438,       -- Wild Growth
    155777,      -- Germination
    -- Disc Priest
    17,          -- 真言术：盾
    194384,      -- 救赎
    1253593,     -- 虚空护盾
    -- Holy Priest
    139,         -- 恢复
    41635,       -- 愈合祷言
    77489,       -- 圣言术：静
    -- Mistweaver Monk
    115175,      -- Soothing Mist
    119611,      -- Renewing Mist
    124682,      -- Enveloping Mist
    450769,      -- Aspect of Harmony
    -- Restoration Shaman
    974, 383648, -- Earth Shield
    61295,       -- Riptide
    -- Holy Paladin
    53563,       -- Beacon of Light
    156322,      -- Eternal Flame
    156910,      -- Beacon of Faith
    1244893,     -- Beacon of the Savior
}
function SetTestSecret(set)
    SetCVar("secretChallengeModeRestrictionsForced", set)
    SetCVar("secretCombatRestrictionsForced", set)
    SetCVar("secretEncounterRestrictionsForced", set)
    SetCVar("secretMapRestrictionsForced", set)
    SetCVar("secretPvPMatchRestrictionsForced", set)
    SetCVar("secretAuraDataRestrictionsForced", set)
    SetCVar("scriptErrors", set);
    SetCVar("doNotFlashLowHealthWarning", set);
end

SetTestSecret(1)
-- /script SetTestSecret(0)
state.isDead = UnitIsDeadOrGhost("player")
state.mounted = IsMounted()
state.isChatOpen = false

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

-- 创建颜色两定点曲线
local function creatColorCurve(point, b)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Linear)
    curve:AddPoint(0, CreateColor(0, 0, 0, 1))
    curve:AddPoint(point, CreateColor(0, 0, b / 255, 1))
    return curve
end
local dispelCurve = C_CurveUtil.CreateColorCurve()
dispelCurve:SetType(Enum.LuaCurveType.Step)
dispelCurve:AddPoint(0, CreateColor(0, 0, 0, 1))         -- 无
dispelCurve:AddPoint(1, CreateColor(0, 1, 1 / 255, 1))   -- 魔法
dispelCurve:AddPoint(2, CreateColor(0, 1, 2 / 255, 1))   -- 诅咒
dispelCurve:AddPoint(3, CreateColor(0, 1, 3 / 255, 1))   -- 疾病
dispelCurve:AddPoint(4, CreateColor(0, 1, 4 / 255, 1))   -- 中毒
dispelCurve:AddPoint(11, CreateColor(0, 1, 11 / 255, 1)) -- 流血
local curve100 = creatColorCurve(1, 100)
local curve90 = creatColorCurve(1, 90)
local curve255 = creatColorCurve(255, 255)
local curve10 = creatColorCurve(10, 100)

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

    state.name, state.GUID = name, GUID
    state.className, state.classFilename, state.classId = className, classFilename, classId
    state.specIndex, state.specID = specIndex, specID

    creat(fixed_blocks.anchor, 0)
    creat(fixed_blocks.class, classId / 255)
    creat(fixed_blocks.specIndex, specIndex / 255)

    blocks, macroList, assistant_spells, init = SK.GetBlockIndexByClassIDAndSpecIndex(classId, specIndex)
end

local function createSpecializationMacro()
    for i, v in ipairs(macroList) do
        SK.CreateMacro(v[1], v[2], v[3])
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
local function updatePlayerPower()
    state.powerPercent = UnitPowerPercent("player", nil, nil, curve100)
    local _, _, b = state.powerPercent:GetRGB()
    creat(fixed_blocks.PowerPercent, b)
end

-- 更新玩家[一键辅助]
local function updatePlayerAssistant()
    local spellId = C_AssistedCombat.GetNextCastSpell()
    if init and blocks.assistant and spellId and assistant_spells[spellId] then
        -- print(spellId, assistant_spells[spellId])
        creat(blocks.assistant, assistant_spells[spellId] / 255)
    end
end
-- 更新法术冷却信息
local function updateSpellCooldown()
    if init and blocks and blocks.spell_cd then
        for i, v in ipairs(blocks.spell_cd) do
            local durationObj = C_Spell.GetSpellCooldownDuration(v.spellId)
            local cooldown = C_Spell.GetSpellCooldown(v.spellId)
            if not durationObj or not cooldown then return end
            local result = durationObj:EvaluateRemainingDuration(curve255)
            local _, _, b = result:GetRGB()
            ---@diagnostic disable-next-line: undefined-field
            if cooldown.isOnGCD then b = 0 end
            creat(v.index, b)
        end
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

-- 更新目标是否在范围内
local function updateTargetInRange()
    target.inRange = SK.HarmfulSpellId and C_Spell.IsSpellInRange(SK.HarmfulSpellId, "target")
    updateTargetValid()
end

-- 更新目标是否死亡
local function updateTargetDeath()
    target.isDead = UnitIsDeadOrGhost("target")
    updateTargetValid()
end

-- 更新目标完整信息
local function updateTargetFullInfo()
    updateTargetCanAttack()
    updateTargetInRange()
    updateTargetDeath()
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
            creat(index, roleMap[obj.role] and roleMap[obj.role] / 255 or 0)
        else
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
    obj.inRange = C_Spell.IsSpellInRange(SK.HelpfulSpellId, unit)
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
    obj.curve = curve90
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
        for _, spellId in ipairs(blocks.unit.aura) do
            local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spellId)
            if aura then
                obj.aura[aura.auraInstanceID] = aura
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
                if aura then
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
    if not init or not blocks.group_count then return end
    local count = GetNumGroupMembers()
    creat(blocks.group_count, count / 255)
end

local function updateGroup()
    table.wipe(group)
    clearGroupBlocks()
    local i = 0
    for unit in iterateGroupMembers() do
        group[unit] = {
            index = i,
            name = UnitName(unit),
            GUID = UnitGUID(unit),
            role = UnitGroupRolesAssigned(unit),
            isDead = UnitIsDeadOrGhost(unit),
            inRange = SK.HelpfulSpellId and C_Spell.IsSpellInRange(SK.HelpfulSpellId, unit),
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
    updatePlayerMoving(IsPlayerMoving())
    state.casting = false
    state.channeling = false
    updatePlayerValid()
    updatePlayerCombat()
    updatePlayerHealth()
    updatePlayerPower()
    updatePlayerAssistant()
    updateGroup()
    updateTargetFullInfo()
    readKeybindings() -- 读取按键绑定
    createSpecializationMacro()
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

frame:RegisterEvent("UNIT_HEALTH")
function frame:UNIT_HEALTH(unit)
    if unit == "player" then
        updatePlayerHealth()
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
end

frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
function frame:UNIT_SPELLCAST_SUCCEEDED(unitTarget, castGUID, spellID, castBarID)
    if not issecretvalue(spellID) then
        if init and blocks.aura and blocks.aura["虚空之盾"] and (spellID == 47540 or spellID == 1253593) then
            C_Timer.After(0.5, function()
                local spellOverride = C_SpellBook.FindSpellOverrideByID(17)
                if spellOverride == 1253593 then
                    creat(blocks.aura["虚空之盾"], 1 / 255)
                else
                    creat(blocks.aura["虚空之盾"], 0)
                end
            end)
        end
    end
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
    if spellId == 2061 and blocks.aura["圣光涌动"] then
        local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellId)
        creat(blocks.aura["圣光涌动"], isSpellOverlayed and 1 / 255 or 0)
    end
end

function frame:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(spellId)
    if spellId == 2061 and blocks.aura["圣光涌动"] then
        local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellId)
        creat(blocks.aura["圣光涌动"], isSpellOverlayed and 1 / 255 or 0)
    end
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

frame:RegisterEvent("UNIT_SPELLCAST_SENT")
function frame:UNIT_SPELLCAST_SENT(player, targetName)
    if not issecretvalue(targetName) then
        for unit, data in pairs(group) do
            if data.name == targetName then
                castTargetUnit = unit
                castTargetName = targetName
                break
            end
        end
    end
end

frame:RegisterEvent("UNIT_IN_RANGE_UPDATE")
function frame:UNIT_IN_RANGE_UPDATE(unit)
    updateUnitInRange(unit)
end

frame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
function frame:SPELL_RANGE_CHECK_UPDATE()
    updateTargetInRange()
    for unit, data in pairs(group) do
        updateUnitInRange(unit)
    end
end

frame:RegisterEvent("UI_ERROR_MESSAGE")
function frame:UI_ERROR_MESSAGE(errorType, message)
    if message == "目标不在视野中" then
        updateUnitInSight(castTargetUnit)
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
        updateSpellCooldown()
        updatePlayerCastingInfo()
        updatePlayerChannelingInfo()
        OnUpdateUnitAura()
        updatePlayerAssistant()
    end
end)
