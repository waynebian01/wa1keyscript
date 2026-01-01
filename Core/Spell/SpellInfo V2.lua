if not Skippy then Skippy = {} end
Skippy.SpellInfo = {}
Skippy.SpellBook = {}
Skippy.GlyphInfo = {}
Skippy.TalentInfo = {}
local spellFunc = {
    SPELL = GetSpellInfo,
    FUTURESPELL = GetSpellInfo,
    FLYOUT = GetFlyoutInfo,
}

local function addSpellInfo(spellName)
    local spellInfo = C_Spell.GetSpellInfo(spellName)
    local cooldownInfo = C_Spell.GetSpellCooldown(spellName)
    local chargeInfo = C_Spell.GetSpellCharges(spellName)
    local isUsable, sufficientPower = C_Spell.IsSpellUsable(spellName)
    local castCount = C_Spell.GetSpellCastCount(spellName)
    local isHarmful = C_Spell.IsSpellHarmful(spellName)
    local isHelpful = C_Spell.IsSpellHelpful(spellName)
    local isPassive = C_Spell.IsSpellPassive(spellName)
    Skippy.SpellInfo[spellName] = {
        spellInfo = spellInfo,
        cooldownInfo = cooldownInfo,
        chargeInfo = chargeInfo,
        isUsable = isUsable,
        sufficientPower = sufficientPower,
        castCount = castCount,
        isHarmful = isHarmful,
        isHelpful = isHelpful,
        isPassive = isPassive,
    }
end

function aura_env.GetSpellBookInfo()
    Skippy.SpellInfo = {}
    Skippy.SpellBook = {}
    for i = 1, GetNumSpellTabs() do
        local _, _, offset, numSlots = GetSpellTabInfo(i)
        for j = offset + 1, offset + numSlots do
            local spellType, id = GetSpellBookItemInfo(j, BOOKTYPE_SPELL)
            local spellName = spellFunc[spellType](id)
            if not Skippy.SpellBook[spellName] then
                Skippy.SpellBook[spellName] = true
            end
        end
    end

    for spellName in pairs(Skippy.SpellBook) do
        addSpellInfo(spellName)
    end
end

aura_env.GetSpellBookInfo()

function Skippy.GetSpellInSpellInfo(spellIdentifier)
    if Skippy.SpellInfo[spellIdentifier] then
        return Skippy.SpellInfo[spellIdentifier]
    else
        for spellName, spellData in pairs(Skippy.SpellInfo) do
            if spellData.spellInfo and spellData.spellInfo.spellID == spellIdentifier then
                return spellData
            end
        end
        --[[local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)
        local isKnown = C_SpellBook.IsSpellKnown(spellIdentifier)
        if isKnown and spellInfo then
            addSpellInfo(spellInfo.name)
            return Skippy.SpellInfo[spellInfo.name]
        end]]
    end
    return nil
end

local function gcdCooldown() -- 检测冷却
    local cooldowninfo = C_Spell.GetSpellCooldown(61304)
    if cooldowninfo and cooldowninfo.startTime > 0 and cooldowninfo.duration > 0 then
        return cooldowninfo.startTime + cooldowninfo.duration - GetTime()
    else
        return 0
    end
end

function Skippy.GetSpellCooldown(spellIdentifier) -- 检测冷却
    local spell = Skippy.GetSpellInSpellInfo(spellIdentifier)
    if not spell then return 0 end
    local cooldowninfo = spell.cooldownInfo
    if cooldowninfo then
        if not cooldowninfo.isEnabled then
            return cooldowninfo.duration
        end
        if cooldowninfo.startTime > 0 and cooldowninfo.duration > 0 then
            local cdLeft = cooldowninfo.startTime + cooldowninfo.duration - GetTime()
            if cdLeft < 0 then
                spell.cooldownInfo = C_Spell.GetSpellCooldown(spellIdentifier)
            end
            return cdLeft
        end
    end
    return 0
end

function Skippy.IsUsableSpell(spellIdentifier)
    local spell = Skippy.GetSpellInSpellInfo(spellIdentifier)
    local gcd = gcdCooldown()
    local cd = Skippy.GetSpellCooldown(spellIdentifier)
    local isUsable = C_Spell.IsSpellUsable(spellIdentifier)
    if not spell then return false end
    local cooldownInfo = spell.cooldownInfo
    local charges = spell.chargeInfo and spell.chargeInfo.currentCharges or nil
    if charges == nil then
        charges = (cooldownInfo.duration == 0 or cd <= gcd) and 1 or 0
    end
    local ready = (cooldownInfo.startTime == 0 and not cooldownInfo.isEnabled) or charges > 0
    local active = isUsable and ready
    return active
end

--[[function Skippy.IsUsableSpellOnUnit(spellIdentifier, unit)
    local spell = Skippy.GetSpellInSpellInfo(spellIdentifier)
    if not spell or not Skippy.IsUsableSpell(spellIdentifier) then
        return false
    end

    if unit and not UnitExists(unit) then
        return false
    end

    local inSpellRange = IsSpellInRange(spell.spellInfo.name, unit)
    -- 没有范围的技能,返回true
    if spell.spellInfo.maxRange == 0 and spell.spellInfo.minRange == 0 then
        return true
    end

    -- 不在范围内或没有单位,返回false
    if not unit then
        return false
    end

    if inSpellRange == 0 then
        return false
    end

    -- 在范围内,返回true
    if inSpellRange == 1 then
        return true
    end
    -- 其他情况,返回false
    return false
end]]

function Skippy.IsUsableSpellOnUnit(spellIdentifier, unit)
    local spell = Skippy.GetSpellInSpellInfo(spellIdentifier)
    if not spell or not Skippy.IsUsableSpell(spellIdentifier) then
        return false
    end
    if unit then
        if not UnitExists(unit) then
            return false
        end
    else
        if spell.spellInfo.maxRange == 0 and spell.spellInfo.minRange == 0 then
            return true
        end
        return false
    end

    local inSpellRange = C_Spell.IsSpellInRange(spellIdentifier, unit)

    return inSpellRange
end

function aura_env.GetGlyphInfo()
    Skippy.GlyphInfo = {}
    for index = 1, 6 do
        local enabled, glyphType, glyphIndex, glyphSpellID, iconFile, glyphID = GetGlyphSocketInfo(index)
        Skippy.GlyphInfo[index] = {
            enabled = enabled,
            glyphType = glyphType,
            glyphIndex = glyphIndex,
            glyphSpellID = glyphSpellID,
            iconFile = iconFile,
            glyphID = glyphID,
        }
    end
end

aura_env.GetGlyphInfo()

function aura_env.GetTalentInfo()
    if WeakAuras.IsClassicOrWrathOrCata() then
        for tab = 1, GetNumTalentTabs() do
            for talent = 1, GetNumTalents(tab) do
                local name, icon, tier, column, rank, maxRank = GetTalentInfo(tab, talent)
                Skippy.TalentInfo[name] = {
                    name = name,
                    icon = icon,
                    tier = tier,
                    column = column,
                    rank = rank,
                    maxRank = maxRank,

                }
            end
        end
    end
end

aura_env.GetTalentInfo()

function aura_env.UpdateSpellCooldown(spellID)
    local spell = Skippy.GetSpellInSpellInfo(spellID)
    if spell then
        spell.cooldownInfo = C_Spell.GetSpellCooldown(spellID)
    end
end

function aura_env.UpdateSpellCharges()
    for spellName, spellData in pairs(Skippy.SpellInfo) do
        if spellData.chargeInfo then
            spellData.chargeInfo = C_Spell.GetSpellCharges(spellName)
        end
    end
end
