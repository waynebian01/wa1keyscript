local e = aura_env
local unitindex = 1
e.initialization = false
e.spellinfo = {
    ["None"] = { key = 255 },
    ["输出"] = { key = 0 },
    ["上个敌人"] = { key = 46 },
    ["中断施法"] = { key = 48 },
    ["驱散目标"] = { key = 91 },

    ["回春术"] = { key = 111, id = 774 },
    ["愈合"] = { key = 112, id = 8936 },
    ["迅捷治愈"] = { key = 113, id = 18562 },
    ["生命绽放"] = { key = 114, id = 33763 },
    ["塞纳里奥结界"] = { key = 115, id = 102351 },
    ["林莽卫士"] = { key = 116, id = 102693 },
    ["自然之愈"] = { key = 117, id = 88423 },
    ["野性成长"] = { key = 92, id = 48438 },
    ["百花齐放"] = { key = 93, id = 145205 },
    ["激活"] = { key = 94, id = 29166 },
    ["甘霖"] = { key = 95, id = 108238 },
    ["自然的守护"] = { key = 96, id = 124974 },
    ["树皮术"] = { key = 97, id = 22812 },
    ["目标林莽卫士"] = { key = 98, id = 102693 },
    ["自然迅捷"] = { key = 99, id = 132158, id2 = 378081 },
    ["万灵之召"] = { key = 100, id = 391528 },
    ["宁静"] = { key = 101, id = 740 },
    ["月火术"] = { key = 102, id = 8921 },
    ["愤怒"] = { key = 103, id = 5176 },
    ["安抚"] = { key = 104, id = 77472 },

    ["纯净术"] = { key = 91, id = 527 },
    ["光晕"] = { key = 92, id = 120517 },
    ["预兆"] = { key = 93, id = 428924 },
    ["绝望祷言"] = { key = 94, id = 19236 },
    ["渐隐术"] = { key = 95, id = 586 },
    ["能量灌注"] = { key = 96, id = 10060 },
    ["真言术：盾"] = { key = 97, id = 17 },
    ["快速治疗"] = { key = 98, id = 2061 },
    ["愈合祷言"] = { key = 99, id = 33076 },
    ["驱散魔法"] = { key = 100, id = 528 },
    ["恢复"] = { key = 101, id = 139 },
    ["圣言术：静"] = { key = 102, id = 2050 },
    ["福音"] = { key = 102, id = 472433 },
    ["治疗术"] = { key = 103, id = 2060 },
    ["苦修"] = { key = 103, id = 47540 },
    ["治疗祷言"] = { key = 104, id = 596 },
    ["惩击"] = { key = 105, id = 585 },
    ["暗影魔"] = { key = 106, id = 34433 },

    ["净化灵魂"] = { key = 91, id = 77130 },
    ["清毒图腾"] = { key = 92, id = 383013 },
    ["生命释放"] = { key = 93, id = 73685 },
    ["治疗之泉图腾"] = { key = 94, id = 5394 },
    ["先祖迅捷"] = { key = 95, id = 443454 },
    ["治疗之雨"] = { key = 96, id = 73920 },
    ["激流"] = { key = 97, id = 61295 },
    ["治疗之涌"] = { key = 98, id = 8004 },
    ["治疗链"] = { key = 99, id = 1064 },
    ["治疗波"] = { key = 100, id = 77472 },
    ["大地之盾"] = { key = 101, id = 974 },
    ["奔涌之流"] = { key = 102, id = 197995 },

}
local debuffLookup = {
    ["燧火创伤"] = true,
    ["投掷燧酿"] = true,
    ["灼热之陨"] = true,
    ["鱼叉"] = true,
    ["混沌腐蚀"] = true,
    ["混沌脆弱"] = true,
    ["纯净"] = true,
    ["痛苦撕裂"] = true,
    ["巨力震击"] = true,
    ["诱引烛焰"] = true,
    ["超力震击"] = true,
    ["穿刺"] = true,
    ["迸发虫茧"] = true,
}
local excludedDebuffs = {
    ["不稳定的腐蚀"] = true,
    ["震地回响"] = true,
    ["烈焰震击"] = true,
    ["虚弱灵魂"] = true,
    ["虚弱光环"] = true,
    ["最后一击"] = true,
    ["饕餮虚空"] = true,
    ["灵魂枯萎"] = true,
    ["巨口蛙毒"] = true,
    -- 第三赛季
    -- 赎罪大厅
    ["心能蚀甲"] = true,
    --回响之城
    ["培植毒药"] = true,
    -- 水闸
    ["动能胶质炸药"] = true,
}

e.raidstatus, e.watching, e.playerinfo, e.talentInfo, e.targetinfo, e.nameplate = {}, {}, {}, {}, {}, {}
local function isSpellKnown(spellID) -- 判断技能是否已学习
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(spellID)
    else
        return IsPlayerSpell(spellID)
    end
end
local function getCooldown(spellID) -- 检测冷却
    local cooldowninfo = C_Spell.GetSpellCooldown(spellID)
    if cooldowninfo then
        if cooldowninfo.startTime > 0 then
            return cooldowninfo.startTime + cooldowninfo.duration - GetTime()
        else
            return 0
        end
    else
        return nil
    end
end
local function unitHealthPct(unit) -- 血量检测
    local maxHealth = UnitHealthMax(unit)
    local healAbsorbs = UnitGetTotalHealAbsorbs(unit) or 0
    local health = UnitHealth(unit) - healAbsorbs
    local healthPct = health / maxHealth * 100
    local lossHealth = maxHealth - health
    return healthPct, lossHealth, health, maxHealth -- 血量百分比, 血量损失, 当前血量, 最大血量
end

function e.UnitKey(unit, spell)
    if not Wa1Key or not Wa1Key.Prop then
        e.errortext = "Wa1Key错误"
        return
    end
    if not unit then
        Wa1Key.Prop.healing = 255
        e.errortext = "单位错误"
        return
    end
    if not e.spellinfo[spell] then
        Wa1Key.Prop.healing = 255
        e.errortext = "技能错误"
        e.icon = nil
        return
    end
    e.errortext = nil
    local keyvalue = 0
    local unitname
    if unit == "macro" then
        unitname = "无目标"
        keyvalue = e.spellinfo[spell].key
    else
        unitname = e.raidstatus[unit].name
        if UnitIsUnit(unit, "target") then
            keyvalue = e.spellinfo[spell].key
        else
            keyvalue = e.raidstatus[unit].raidindex + 5
        end
    end
    if e.spellinfo[spell].iconID then
        e.icon = e.spellinfo[spell].iconID
    else
        e.icon = nil
    end
    Wa1Key.Prop.healing = keyvalue
    e.errortext = "目标:" .. unitname .. "\n技能:" .. spell .. " \n代码:" .. keyvalue
    return true
end

function e.getTalentInfo() -- 获取已经学习的天赋
    e.talentInfo = {}
    local configID = C_ClassTalents.GetActiveConfigID()
    if configID == nil then return end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if configInfo == nil then return end

    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodes = C_Traits.GetTreeNodes(treeID)
        for _, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            for _, entryID in ipairs(nodeInfo.entryIDs) do
                local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                if entryInfo and entryInfo.definitionID then
                    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                    if definitionInfo.spellID then
                        local known = isSpellKnown(definitionInfo.spellID)
                        local name = C_Spell.GetSpellName(definitionInfo.spellID) or "未知法术"
                        if known then
                            e.talentInfo[name] = { spellID = definitionInfo.spellID }
                        end
                    end
                end
            end
        end
    end
end

function e.getSpellInfo() -- 获取技能信息
    for spellName, data in pairs(e.spellinfo) do
        if data.id then
            local known = isSpellKnown(data.id)
            if not known and data.id2 then
                known = isSpellKnown(data.id2)
            end
            local spellInfo = C_Spell.GetSpellInfo(data.id)
            local cooldown = getCooldown(data.id)
            if known then
                data.known = true
                data.castTime = spellInfo.castTime / 1000
                data.maxRange = spellInfo.maxRange
                data.iconID = spellInfo.iconID
                data.usable = false
                e.watching[spellName] = true
            end
        end
    end
end

function e.updateCooldown() -- 更新技能冷却
    for spellName, v in pairs(e.watching) do
        local cooldown = getCooldown(spellName)
        local gcd = getCooldown(61304)
        if cooldown then
            e.spellinfo[spellName].cooldown = cooldown
            if cooldown <= gcd then
                e.spellinfo[spellName].usable = true
            else
                e.spellinfo[spellName].usable = false
            end
        end
    end
end

function e.updataSpellCastCount() -- 获取技能施法次数
    for spellName, data in pairs(e.spellinfo) do
        if data.id and data.count then
            local castCount = C_Spell.GetSpellCastCount(data.id)
            if castCount then
                data.count = castCount
            end
        end
    end
end

function e.getSpellCharges() -- 获取技能充能
    for spellName, data in pairs(e.spellinfo) do
        if data.id then
            local charges = C_Spell.GetSpellCharges(data.id)
            if charges then
                data.charges = charges.currentCharges
            end
        end
    end
end

-- 更新团队固定信息
function e.GetRaidfixedInfo()
    e.raidstatus = {}
    for i = 1, 30 do
        local unit = "raid" .. i
        if UnitExists(unit) then
            if UnitIsUnit(unit, "player") then e.playerinfo.inRaidUnit = unit end
            local healthPct, lossHealth, health, maxHealth = unitHealthPct(unit)
            local name, _, subgroup, _, class, fileName, _, _, _, role, _, combatRole = GetRaidRosterInfo(i)
            e.raidstatus[unit] = {
                raidindex = i,
                name = name,
                healthPct = healthPct,
                losshealth = lossHealth,
                health = health,
                maxHealth = maxHealth,
                GUID = UnitGUID(unit),
                subgroup = subgroup,
                class = class,
                fileName = fileName,
                role = role,
                combatRole = combatRole,
                inSight = true,
                inSightTimer = nil,
            }
        end
    end
    print("团队状态已经更新")
end

local function getRaidStatus(unit) -- 逐帧更新团队成员状态
    if e.raidstatus[unit] then
        local healthPct, lossHealth, health, maxHealth = unitHealthPct(unit)
        local isAlive = not UnitIsDeadOrGhost(unit)
        local canAssist = UnitCanAssist("player", unit)
        local inRange = UnitInRange(unit)
        local hasAngel = AuraUtil.FindAuraByName("救赎之魂", unit, "HELPFUL")
        e.raidstatus[unit].isAlive = isAlive
        e.raidstatus[unit].canAssist = canAssist
        e.raidstatus[unit].inRange = inRange
        e.raidstatus[unit].hasAngel = hasAngel
        e.raidstatus[unit].healthPct = healthPct
        e.raidstatus[unit].losshealth = lossHealth
        e.raidstatus[unit].health = health
        e.raidstatus[unit].maxHealth = maxHealth
        e.raidstatus[unit].damage = Details and Details.UnitDamage and Details.UnitDamage(unit) or 0
        e.raidstatus[unit].buff = {}
        e.raidstatus[unit].debuff = {}
        e.raidstatus[unit].hasDisease = false
        e.raidstatus[unit].hasMagic = false
        e.raidstatus[unit].hasPoison = false
        e.raidstatus[unit].hasCurse = false
        e.raidstatus[unit].hasParticularDebuff = false
        for i = 1, 40 do
            local buff = C_UnitAuras.GetAuraDataByIndex(unit, i, "PLAYER|HELPFUL")
            local debuff = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
            -- 将光环信息存储到表中，以光环名为键
            if buff then
                e.raidstatus[unit].buff[buff.name] = {
                    spellId = buff.spellId,
                    count = buff.applications,
                    duration = buff.duration,
                    expirationTime = buff.expirationTime,
                }
            end
            if debuff then
                e.raidstatus[unit].debuff[debuff.name] = {
                    name = debuff.name,
                    spellId = debuff.spellId,
                    count = debuff.applications,
                    expirationTime = debuff.expirationTime,
                }
                local debuffType = debuff.dispelName
                if not excludedDebuffs[debuff.name] then
                    if debuffType == "Disease" then
                        e.raidstatus[unit].hasDisease = true
                    end
                    if debuffType == "Magic" then
                        e.raidstatus[unit].hasMagic = true
                    end
                    if debuffType == "Poison" then
                        e.raidstatus[unit].hasPoison = true
                    end
                    if debuffType == "Curse" then
                        e.raidstatus[unit].hasCurse = true
                    end
                end
                for debuffName in pairs(debuffLookup) do
                    if debuff.name == debuffName then
                        e.raidstatus[unit].hasParticularDebuff = true
                    end
                end
            end
        end
    end
end

function e.updateRaidStatus() -- 更新队伍状态
    local unit = "raid" .. unitindex
    getRaidStatus(unit)
    unitindex = unitindex + 1
    if unitindex > 30 then unitindex = 1 end
end

function e.getTargetAura() -- 获取目标光环
    e.targetinfo.enemy = {
        buff = {},
        debuff = {},
        hasDisease = false,
        hasMagic = false,
        hasPoison = false,
        hasCurse = false,
        hasEnrage = false,
    }
    e.targetinfo.helper = {
        buff = {},
        debuff = {},
        hasDisease = false,
        hasMagic = false,
        hasPoison = false,
        hasCurse = false,
    }
    if not UnitExists("target") then return end
    for i = 1, 10 do
        local buff = C_UnitAuras.GetAuraDataByIndex("target", i, "HELPFUL")
        local debuff = C_UnitAuras.GetAuraDataByIndex("target", i, "HARMFUL")

        if UnitCanAttack("player", "target") then
            if buff then
                e.targetinfo.enemy.buff[buff.name] = {
                    spellId = buff.spellId,
                    count = buff.applications,
                    duration = buff.duration,
                    expirationTime = buff.expirationTime,
                }
                local buffType = buff.dispelName
                if buffType == "Disease" then
                    e.targetinfo.enemy.hasDisease = true
                end
                if buffType == "Magic" then
                    e.targetinfo.enemy.hasMagic = true
                end
                if buffType == "Poison" then
                    e.targetinfo.enemy.hasPoison = true
                end
                if buffType == "Curse" then
                    e.targetinfo.enemy.hasCurse = true
                end
                if buffType == "" then
                    e.targetinfo.enemy.hasEnrage = true
                end
            end
            if debuff and debuff.isFromPlayerOrPlayerPet then
                e.targetinfo.enemy.debuff[debuff.name] = {
                    name = debuff.name,
                    spellId = debuff.spellId,
                    count = debuff.applications,
                    expirationTime = debuff.expirationTime,
                }
            end
        end
        if UnitCanAssist("player", "target") and debuff then
            local debuffType = debuff.dispelName
            if debuffType == "Disease" then
                e.targetinfo.helper.hasDisease = true
            end
            if debuffType == "Magic" then
                e.targetinfo.helper.hasMagic = true
            end
            if debuffType == "Poison" then
                e.targetinfo.helper.hasPoison = true
            end
            if debuffType == "Curse" then
                e.targetinfo.helper.hasCurse = true
            end
            e.targetinfo.helper.debuff[debuff.name] = {
                name = debuff.name,
                spellId = debuff.spellId,
                count = debuff.applications,
                expirationTime = debuff.expirationTime,
            }
        end
    end
end

function e.getNameplateCastInfo(unit, castGUID, spellID) -- 获取姓名版施法信息
    local name, _, _, startTimeMS, endTimeMS = UnitCastingInfo(unit)
    local unitTarget = unit .. "target"
    if UnitExists(unitTarget) then
        for k, v in pairs(e.raidstatus) do
            if UnitIsUnit(unitTarget, k) then
                unitTarget = k
                break
            end
        end
    end
    if castGUID then
        e.nameplate[castGUID] = {
            unit = unit,
            unitName = UnitName(unit),
            unitTargetName = UnitName(unitTarget),
            unitTarget = unitTarget,
            name = name,
            spellID = spellID,
            startTime = startTimeMS / 1000,
            endTime = endTimeMS / 1000,
        }
    end
end

function e.updateUnitRange() -- 更新单位距离
    if e.targetinfo then
        e.targetinfo.inRange_5 = C_Item.IsItemInRange(37727, "target") or false
        e.targetinfo.inRange_8 = C_Item.IsItemInRange(34368, "target") or false
        e.targetinfo.inRange_30 = C_Item.IsItemInRange(835, "target") or false
        e.targetinfo.inRange_40 = C_Item.IsItemInRange(28767, "target") or false
    end
end

function e.getPlayerManaPct() -- 更新玩家法力
    local currentMana = UnitPower("player", Enum.PowerType.Mana)
    local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)
    e.playerinfo.manaPct = currentMana / maxMana * 100
end

function e.getEvangelismValue() -- 牧师专属,更新福音的总体治疗量
    if e.playerinfo.class == "牧师" then
        local intelligence = UnitStat("player", 4)
        local versatility = GetCombatRatingBonus(29) / 100 + 1
        local mastery = GetMasteryEffect() / 100 + 1
        e.playerinfo.evangelismValue = intelligence * 58 * versatility * mastery
    end
end

function e.getHolyPower() -- 更新圣骑士能量
    if e.playerinfo.class == "圣骑士" then
        if e.raid and e.raid["player"] and e.raid["player"].buff["神圣意志"] then
            e.playerinfo.HolyPower = 5
        else
            e.playerinfo.HolyPower = UnitPower("player", Enum.PowerType.HolyPower)
        end
    end
end

function e.getTargetInfo() -- 更新目标信息
    e.targetinfo.CanAttack = UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    e.targetinfo.name = UnitName("target") or "无目标"
end

function e.getPlayerInfo() -- 获取玩家信息
    if not e.playerinfo then e.playerinfo = {} end
    e.playerinfo.inParty = UnitPlayerOrPetInParty("player")
    e.playerinfo.inRaid = UnitPlayerOrPetInRaid("player")
    e.playerinfo.class = UnitClass("player")
    e.playerinfo.Specialization = GetSpecialization()
    e.playerinfo.GCD = 1.5 / (1 + GetHaste() / 100)
    e.playerinfo.isCombat = false
    e.playerinfo.isMoving = false
    if e.playerinfo.class == "圣骑士" then
        e.playerinfo.seasonsID = C_Spell.GetOverrideSpell(388007)
    end
    if e.playerinfo.class == "武僧" then
        e.updataSpellCastCount()
    end
end

-- 队伍信息
e.GetRaidfixedInfo() -- 获取团队固定信息
e.updateRaidStatus() -- 更新团队状态
-- 玩家信息
e.getPlayerInfo()      -- 获取玩家信息
e.getTalentInfo()      -- 获取玩家天赋
e.getSpellInfo()       -- 获取技能信息
e.getSpellCharges()    -- 获取技能充能
e.getPlayerManaPct()   -- 获取玩家法力
e.getHolyPower()       -- 获取圣骑士能量
e.getEvangelismValue() -- 获取福音的总体治疗量
e.updateCooldown()     -- 更新技能冷却
-- 目标信息
e.getTargetInfo()      -- 获取目标信息
e.getTargetAura()      -- 获取目标光环
e.updateUnitRange()    -- 更新单位距离

print("初始化完成")
e.initialization = true
