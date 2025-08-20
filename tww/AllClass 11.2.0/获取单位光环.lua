local e = aura_env
local partystatus = {}
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
}
local excludedDebuffs = {
    ["动能胶质炸药"] = true,
    ["不稳定的腐蚀"] = true,
    ["震地回响"] = true,
    ["烈焰震击"] = true,
    ["虚弱灵魂"] = true,
    ["虚弱光环"] = true,
    ["最后一击"] = true,
    ["饕餮虚空"] = true,
    ["灵魂枯萎"] = true,
    ["巨口蛙毒"] = true,
    ["培植毒药"] = true
}
function e.getAura(unit) -- 光环判断
    if not UnitExists(unit) then return end
    if not e.partystatus[unit] then e.partystatus[unit] = {} end
    e.partystatus[unit].buff = {}
    e.partystatus[unit].debuff = {}
    e.partystatus[unit].hasDisease = false
    e.partystatus[unit].hasMagic = false
    e.partystatus[unit].hasPoison = false
    e.partystatus[unit].hasCurse = false
    e.partystatus[unit].hasParticularDebuff = false
    for i = 1, 40 do
        local buff = C_UnitAuras.GetAuraDataByIndex(unit, i, "PLAYER|HELPFUL")
        local debuff = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")

        if buff then
            -- 将光环信息存储到表中，以光环名为键
            e.partystatus[unit].buff[buff.name] = {
                spellId = buff.spellId,
                count = buff.applications,
                expirationTime = buff.expirationTime,
            }
        end
        if debuff then
            e.partystatus[unit].debuff[debuff.name] = {
                name = debuff.name,
                spellId = debuff.spellId,
                count = debuff.applications,
                expirationTime = debuff.expirationTime,
            }
            local debuffType = debuff.dispelName
            if not excludedDebuffs[debuff.name] then
                if debuffType == "Disease" then
                    e.partystatus[unit].hasDisease = true
                end
                if debuffType == "Magic" then
                    e.partystatus[unit].hasMagic = true
                end
                if debuffType == "Poison" then
                    e.partystatus[unit].hasPoison = true
                end
                if debuffType == "Curse" then
                    e.partystatus[unit].hasCurse = true
                end
            end

            for debuffName in pairs(debuffLookup) do
                if debuff.name == debuffName then
                    e.partystatus[unit].hasParticularDebuff = true
                end
            end
        end
    end
end
