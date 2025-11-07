if not Skippy then Skippy = {} end
Skippy.spellInfo = {}
local watchList = {}
local knownSpell = {}
local frame = CreateFrame("Frame")
local insert, remove, sort, wipe = table.insert, table.remove, table.sort, table.wipe
local elapsed = 0
local function getCooldown(spellIdentifier) -- 检测冷却
    local cooldowninfo = C_Spell.GetSpellCooldown(spellIdentifier)
    if cooldowninfo and cooldowninfo.startTime > 0 and cooldowninfo.duration > 0 then
        return cooldowninfo.startTime + cooldowninfo.duration - GetTime()
    else
        return 0
    end
end

local function wipeTable()
    wipe(Skippy.spellInfo)
    wipe(watchList)
    wipe(knownSpell)
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
    if Skippy.spellInfo[spellIdentifier] ~= nil then
        return Skippy.spellInfo[spellIdentifier]
    end
    local info = C_Spell.GetSpellInfo(spellIdentifier)

    if info then
        local GCD = getCooldown(61304)
        local cd = getCooldown(spellIdentifier)
        local cooldowns = C_Spell.GetSpellCooldown(spellIdentifier)
        local charges = C_Spell.GetSpellCharges(spellIdentifier)
        local isUsable = C_Spell.IsSpellUsable(spellIdentifier)
        local usable = isUsable and cd <= GCD and cooldowns.isEnabled

        Skippy.spellInfo[spellIdentifier] = {
            info = info,
            usable = usable,
            cooldowns = cooldowns,
            charges = charges,
            cooldown = cd,
        }

        if not usable then
            watchList[spellIdentifier] = true
        end

        return Skippy.spellInfo[spellIdentifier]
    else
        Skippy.spellInfo[spellIdentifier] = {
            usable = false,
            cooldown = 300,
        }
        return Skippy.spellInfo[spellIdentifier]
    end
end

local function UpdateCooldowns(_, update)
    elapsed = elapsed + update
    if elapsed >= 0.1 then
        local GCD = getCooldown(61304)
        for spellIdentifier in pairs(watchList) do
            if spellIdentifier then
                local cd = getCooldown(spellIdentifier)
                if cd and cd <= GCD then
                    Skippy.spellInfo[spellIdentifier].usable = true
                    Skippy.spellInfo[spellIdentifier].cooldown = 0
                    watchList[spellIdentifier] = nil
                else
                    Skippy.spellInfo[spellIdentifier].usable = false
                    Skippy.spellInfo[spellIdentifier].cooldown = cd
                end
            end
        end
    end
end

local function updateSpellCharges()
    for spellIdentifier, spellData in pairs(Skippy.spellInfo) do
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
    end
end

function frame:SPELL_UPDATE_COOLDOWN(spellID)
    if not spellID then return end
    local spellname = C_Spell.GetSpellName(spellID)
    local GCD = getCooldown(61304)

    if spellname and Skippy.spellInfo[spellname] then
        local cooldown = getCooldown(spellname)
        local cooldowns = C_Spell.GetSpellCooldown(spellname)
        if cooldown and cooldown > GCD then
            Skippy.spellInfo[spellname].cooldowns = cooldowns
            Skippy.spellInfo[spellname].cooldown = cooldown
            Skippy.spellInfo[spellname].usable = false
            watchList[spellname] = true -- 写入watchlist
        end
    end

    if Skippy.spellInfo[spellID] then
        local cooldown = getCooldown(spellID)
        local cooldowns = C_Spell.GetSpellCooldown(spellID)
        if cooldown and cooldown > GCD then
            Skippy.spellInfo[spellID].cooldowns = cooldowns
            Skippy.spellInfo[spellID].cooldown = cooldown
            Skippy.spellInfo[spellID].usable = false
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
        for spellIdentifier, data in pairs(Skippy.spellInfo) do
            if spellIdentifier == spellname or spellIdentifier == spellID then
                local cooldown = getCooldown(spellIdentifier)
                local cooldowns = C_Spell.GetSpellCooldown(spellIdentifier)
                if cooldown and cooldown > GCD then
                    Skippy.spellInfo[spellIdentifier].cooldowns = cooldowns
                    Skippy.spellInfo[spellIdentifier].cooldown = cooldown
                    Skippy.spellInfo[spellIdentifier].usable = false
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

function frame:PLAYER_TALENT_UPDATE()
    wipeTable()
end

function frame:TRAIT_CONFIG_UPDATED()
    wipeTable()
end

frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("SPELL_UPDATE_CHARGES")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
