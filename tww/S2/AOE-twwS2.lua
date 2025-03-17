--Boss技能
local BossSpell = { "喷涌佳酿", "振翼之风", "遮天蔽日", --酒庄
}

--Boss引导技能
local BossChannelSpell = { "炽焰波峰", "排放口" }

--小怪技能无控制
local NameplateAfter = { "蜂拥惊喜", --酒庄
}
--小怪技能有控制,如果AOE有控制需要提前施放“耀”
local NameplateBefor = { "暴捶", --酒庄
}
--打断技能
local Nameplateinterrupt = { "瓦解怒吼", --修道院
}
local hastePercent = GetHaste() / 100
--获取技能充能层数的函数
local function getCharges(spellID)
    local charges = C_Spell.GetSpellCharges(spellID)
    return charges and charges.currentCharges or 0 -- 如果没有充能信息,则返回 0
end
-- 获取技能冷却时间的函数
local function getCooldown(spellID)
    local cooldown = C_Spell.GetSpellCooldown(spellID)
    if cooldown and cooldown.startTime > 0 then
        local remainingTimeMs = (cooldown.startTime + cooldown.duration - GetTime()) * 1000 -- 剩余时间（毫秒）
        local totalDurationMs = cooldown.duration * 1000                                    -- 总冷却时间（毫秒）
        return remainingTimeMs, totalDurationMs
    end
    return 0, 0 -- 无冷却或不可用时返回 0, 0
end
--获取法术需要的施法时间
local function GetSpellCastTimeMs(spellInput)
    local spellInfo = C_Spell.GetSpellInfo(spellInput)
    return spellInfo and spellInfo.castTime or nil
end
-- 检查玩家是否正在施放特定法术的函数
local function isCastingSpell(spellID)
    local spellName = C_Spell.GetSpellInfo(spellID)
    local castingSpellName, _, _, _, _, _, _, _, _ = UnitCastingInfo("player")
    local channelingSpellName, _, _, _, _, _, _, _ = UnitChannelInfo("player")

    if castingSpellName == spellName or channelingSpellName == spellName then
        return true
    else
        return false
    end
end

-- 检查单位施法的函数，返回剩余时间（毫秒）
local function checkCasting(unitType, spellList)
    for i = 1, 40 do
        local unit = unitType .. i
        if UnitExists(unit) then
            local spellName, _, _, startTime, endTime = UnitCastingInfo(unit)
            if spellName then
                for _, spell in ipairs(spellList) do
                    if spellName == spell then
                        local timeLeftMs = endTime - (GetTime() * 1000) -- 转换为毫秒
                        return timeLeftMs
                    end
                end
            end
        end
    end
    return 0
end

-- 检查单位引导施法的函数，返回已持续时间和剩余时间（毫秒）
local function checkChanneling(unitType, spellList)
    for i = 1, 40 do
        local unit = unitType .. i
        if UnitExists(unit) then
            local spellName, _, _, startTime, endTime = UnitChannelInfo(unit)
            if spellName then
                for _, spell in ipairs(spellList) do
                    if spellName == spell then
                        local currentTimeMs = GetTime() * 1000          -- 当前时间（毫秒）
                        local elapsedTimeMs = currentTimeMs - startTime -- 已持续时间（毫秒）
                        local timeLeftMs = endTime - currentTimeMs      -- 剩余时间（毫秒）
                        return elapsedTimeMs, timeLeftMs
                    end
                end
            end
        end
    end
    return 0, 0
end

--获取单位光环的函数
local function hasAura(unit, auraName, onlyPlayerCast)
    for j = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, j, "HELPFUL")
        if not auraData then break end
        if auraData.name == auraName then
            if onlyPlayerCast then
                return auraData.sourceUnit == "player"
            else
                return true
            end
        end
    end
    return false
end

local isCastShine = isCastingSpell(194509)
local CastShineNeedMs = GetSpellCastTimeMs(194509)
local ShineCharges = getCharges(194509)
local ShineremainingMs, ShinetotalMs = getCooldown(194509)
local GremainingMs, GtotalMs = getCooldown(61304)
local GCD = 1500 / (hastePercent + 1)
local ShineSucceededMs = CastShineNeedMs + ShineremainingMs

local BossAoeRemainingMs = checkCasting("boss", BossSpell)
local BossChannelSpellelapsedMs, BossChannelSpelltimeLeftMs = checkChanneling("boss", BossChannelSpell)
local NameBeforAoeRemainingMs = checkCasting("nameplate", NameplateBefor)
local NameAfterAoeRemainingMs = checkCasting("nameplate", NameplateAfter)

local NameplateinterruptRemainingMs = checkCasting("nameplate", Nameplateinterrupt)

if not isCastShine and (ShineCharges > 0 or ShineremainingMs <= GCD) then
    if NameplateinterruptRemainingMs < 400 then
        return 3
    end
    if CastShineNeedMs < NameBeforAoeRemainingMs and NameBeforAoeRemainingMs <= CastShineNeedMs + 400 then
        return 1
    end
    if CastShineNeedMs < NameBeforAoeRemainingMs and NameBeforAoeRemainingMs < CastShineNeedMs + GCD then
        return 2
    end

    if 0 < BossAoeRemainingMs and BossAoeRemainingMs <= ShineSucceededMs then
        return 1
    end
    if 0 < NameAfterAoeRemainingMs and NameAfterAoeRemainingMs <= ShineSucceededMs then
        return 1
    end
end


return 0
