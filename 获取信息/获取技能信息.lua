if not Skippy then Skippy = {} end
local spellCache = {}
local watchList = {}
local knownSpell = {}
local frame = CreateFrame("Frame")
local insert, remove, sort, wipe = table.insert, table.remove, table.sort, table.wipe

local function getCooldown(spellIdentifier) -- 检测冷却
    local cooldowninfo = C_Spell.GetSpellCooldown(spellIdentifier)
    if cooldowninfo and cooldowninfo.startTime > 0 and cooldowninfo.duration > 0 then
        return cooldowninfo.startTime + cooldowninfo.duration - GetTime()
    else
        return 0
    end
end

function Skippy.IsSpellKnown(spellIdentifier)
    if knownSpell[spellIdentifier] ~= nil then
        return knownSpell[spellIdentifier]
    end
    if type(spellIdentifier) == "number" then
        local isKnown = C_SpellBook.IsSpellKnown(spellIdentifier)
        knownSpell[spellIdentifier] = isKnown
        return isKnown
    end
    if type(spellIdentifier) == "string" then
        local info = C_Spell.GetSpellInfo(spellIdentifier)
        if not info then return false end
        local isKnown = C_SpellBook.IsSpellKnown(info.spellID)
        knownSpell[spellIdentifier] = isKnown
        return isKnown
    end
    return false
end

function Skippy.GetSpellInfo(spellIdentifier)
    if spellCache[spellIdentifier] ~= nil then
        return spellCache[spellIdentifier]
    end
    local info = C_Spell.GetSpellInfo(spellIdentifier)

    if info then
        local GCD = getCooldown(61304)
        local cd = getCooldown(spellIdentifier)
        local cooldowns = C_Spell.GetSpellCooldown(spellIdentifier)
        local charges = C_Spell.GetSpellCharges(spellIdentifier)
        local isUsable = C_Spell.IsSpellUsable(spellIdentifier)
        local usable = isUsable and cd and cd <= GCD

        spellCache[spellIdentifier] = {
            info = info,
            usable = usable,
            cooldowns = cooldowns,
            charges = charges,
            cooldown = cd,
        }

        if usable then
            watchList[spellIdentifier] = true
        end

        return spellCache[spellIdentifier]
    else
        spellCache[spellIdentifier] = {
            usable = false,
            cooldown = 300,
        }
        return spellCache[spellIdentifier]
    end
end

local elapsed = 0
local function UpdateCooldowns(_, update)
    elapsed = elapsed + update
    if elapsed >= 0.1 then
        local GCD = getCooldown(61304)
        for spellIdentifier in pairs(watchList) do
            if spellIdentifier then
                local cd = getCooldown(spellIdentifier)
                if cd and cd <= GCD then
                    spellCache[spellIdentifier].usable = true
                    spellCache[spellIdentifier].cooldown = 0
                    watchList[spellIdentifier] = nil
                else
                    spellCache[spellIdentifier].usable = false
                    spellCache[spellIdentifier].cooldown = cd
                end
            end
        end
    end
end

local function updateSpellCharges()
    for spellIdentifier, spellData in pairs(spellCache) do
        if spellData.charges then
            local charges = C_Spell.GetSpellCharges(spellIdentifier)
            if charges then
                spellData.charges = charges
                if charges.currentCharges == 0 then
                    spellData.usable = false
                else
                    spellData.usable = true
                end
            end
        end
    end
end

function frame:PLAYER_ENTERING_WORLD()
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "arena" then
        self:SetScript("OnUpdate", nil)
        wipe(spellCache)
        wipe(watchList)
        wipe(knownSpell)
    end
end

function frame:SPELL_UPDATE_COOLDOWN(spellID)
    if not spellID then return end
    local spellname = C_Spell.GetSpellName(spellID)
    local GCD = getCooldown(61304)

    if spellname and spellCache[spellname] then
        local cooldown = getCooldown(spellname)
        local cooldowns = C_Spell.GetSpellCooldown(spellname)
        if cooldown and cooldown > GCD then
            spellCache[spellname].cooldowns = cooldowns
            spellCache[spellname].cooldown = cooldown
            spellCache[spellname].usable = false
            watchList[spellname] = true -- 写入watchlist
        end
    end

    if spellCache[spellID] then
        local cooldown = getCooldown(spellID)
        local cooldowns = C_Spell.GetSpellCooldown(spellID)
        if cooldown and cooldown > GCD then
            spellCache[spellID].cooldowns = cooldowns
            spellCache[spellID].cooldown = cooldown
            spellCache[spellID].usable = false
            watchList[spellID] = true -- 写入watchlist
        end
    end

    if next(watchList) then
        self:SetScript("OnUpdate", UpdateCooldowns)
    end
end

function frame:UNIT_SPELLCAST_SUCCEEDED(unit, GUID, spellID)
    if unit == "player" then
        local spellname = C_Spell.GetSpellName(spellID)
        local GCD = getCooldown(61304)
        for spellIdentifier, data in pairs(spellCache) do
            if spellIdentifier == spellname or spellIdentifier == spellID then
                local cooldown = getCooldown(spellIdentifier)
                local cooldowns = C_Spell.GetSpellCooldown(spellIdentifier)
                if cooldown and cooldown > GCD then
                    spellCache[spellIdentifier].cooldowns = cooldowns
                    spellCache[spellIdentifier].cooldown = cooldown
                    spellCache[spellIdentifier].usable = false
                    -- 写入watchlist
                    watchList[spellIdentifier] = true
                end
            end
            if data.charges then
                C_Timer.After(1, function()
                    updateSpellCharges()
                end)
            end
        end
    end
end

function frame:SPELL_UPDATE_CHARGES()
    updateSpellCharges()
    C_Timer.After(1, function()
        updateSpellCharges()
    end)
end

function frame:PLAYER_TARGET_CHANGED()
    wipe(spellCache)
    wipe(watchList)
    wipe(knownSpell)
end

function frame:PLAYER_TALENT_UPDATE()
    wipe(spellCache)
    wipe(watchList)
    wipe(knownSpell)
end

function frame:ACTIVE_TALENT_GROUP_CHANGED()
    wipe(spellCache)
    wipe(watchList)
    wipe(knownSpell)
end

function frame:TRAIT_CONFIG_UPDATED()
    wipe(spellCache)
    wipe(watchList)
    wipe(knownSpell)
end

frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("SPELL_UPDATE_CHARGES")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
