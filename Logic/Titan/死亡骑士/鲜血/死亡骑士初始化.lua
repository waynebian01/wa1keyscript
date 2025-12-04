local e = aura_env
e.Rune = {}
-- 血液沸腾的技能ID
e.BloodBoilSpellId = {
    [48721] = true,
    [49939] = true,
    [49940] = true,
    [49941] = true,
}
-- 死亡凋零的技能ID
e.DeathAndDecaySpellId = {
    [43265] = true,
    [49936] = true,
    [49937] = true,
    [49938] = true,
}
-- 获取枯萎凋零的冷却信息
function e.GetDeacyCooldown(arg3)
    local cooldownInfo = C_Spell.GetSpellCooldown(arg3)
    if not cooldownInfo then return end
    local duration = cooldownInfo.duration
    local expirationTime = cooldownInfo.startTime + duration
    e.DecayExpirationTime = expirationTime
end

-- 初始化符文
function e.InitRune()
    for i = 1, 6 do
        local startTime, duration, isRuneReady = GetRuneCooldown(i)
        local type = GetRuneType(i)
        e.Rune[i] = {
            type = type,
            startTime = startTime,
            duration = duration,
            isRuneReady = isRuneReady,
        }
    end
end

-- 获取符文CD
local function RuneCD(runeIndex)
    local rune = e.Rune[runeIndex]
    if rune.startTime == 0 then
        return 0
    else
        local cd = rune.startTime + rune.duration - GetTime()
        return cd
    end
end
-- 获取符文数量和冷却
function e.RuneCount()
    local runes = {
        BloodRunes_Count = 0,
        BloodRunes_CD = 10,
        UnholyRunes_Count = 0,
        UnholyRunes_CD = 10,
        FrostRunes_Count = 0,
        FrostRunes_CD = 10,
        DeathRunes_Count = 0,
        DeathRunes_CD = 10,
        Runes_Count = 0,
    }
    for i = 1, 6 do
        if e.Rune[i].isRuneReady then
            if e.Rune[i].type == 1 then
                runes.BloodRunes_Count = runes.BloodRunes_Count + 1
            elseif e.Rune[i].type == 2 then
                runes.UnholyRunes_Count = runes.UnholyRunes_Count + 1
            elseif e.Rune[i].type == 3 then
                runes.FrostRunes_Count = runes.FrostRunes_Count + 1
            elseif e.Rune[i].type == 4 then
                runes.DeathRunes_Count = runes.DeathRunes_Count + 1
            end
            runes.Runes_Count = runes.Runes_Count + 1
        else
            if e.Rune[i].type == 1 then
                local cd = RuneCD(i)
                if cd < runes.BloodRunes_CD then
                    runes.BloodRunes_CD = cd
                end
            elseif e.Rune[i].type == 2 then
                local cd = RuneCD(i)
                if cd < runes.UnholyRunes_CD then
                    runes.UnholyRunes_CD = cd
                end
            elseif e.Rune[i].type == 3 then
                local cd = RuneCD(i)
                if cd < runes.FrostRunes_CD then
                    runes.FrostRunes_CD = cd
                end
            elseif e.Rune[i].type == 4 then
                local cd = RuneCD(i)
                if cd < runes.DeathRunes_CD then
                    runes.DeathRunes_CD = cd
                end
            end
        end
    end
    return runes
end

-- 更新符文
function e.RuneUpdata(runeIndex)
    local startTime, duration, isRuneReady = GetRuneCooldown(runeIndex)
    e.Rune[runeIndex].startTime = startTime
    e.Rune[runeIndex].duration = duration
    e.Rune[runeIndex].isRuneReady = isRuneReady
end

-- 周围没有双疾病的单位数量
function e.noPlagueCount()
    local count = 0
    for unit, data in pairs(Skippy.Nameplate) do
        if data and data.exists and data.creatureID ~= 11 and data.maxRange and data.maxRange <= 15 then
            local hasFrostFever = false
            local hasBloodPlague = false
            for _, aura in pairs(data.aura) do
                if aura.sourceUnit == "player" then
                    if aura.name == "冰霜疫病" then
                        hasFrostFever = true
                    end
                    if aura.name == "血之疫病" then
                        hasBloodPlague = true
                    end
                end
            end
            if not (hasFrostFever and hasBloodPlague) then
                count = count + 1
            end
        end
    end
    return count
end

-- 目标双疾病的信息
function e.PlagueInfo()
    local info = {
        FrostFever = nil,
        BloodPlague = nil,
        ShortestPlague = nil,
    }
    local target = Skippy.Units.target
    if not target or not target.exists or not target.aura then return info end

    for _, aura in pairs(target.aura) do
        if aura.sourceUnit == "player" then
            if aura.name == "冰霜疫病" then
                info.FrostFever = aura.expirationTime - GetTime()
            end
            if aura.name == "血之疫病" then
                info.BloodPlague = aura.expirationTime - GetTime()
            end
        end
    end

    if info.FrostFever and info.BloodPlague then
        if info.FrostFever < info.BloodPlague then
            info.ShortestPlague = info.FrostFever
        else
            info.ShortestPlague = info.BloodPlague
        end
    end
    return info
end

e.GetDeacyCooldown("枯萎凋零")
e.InitRune()
e.RuneCount()
