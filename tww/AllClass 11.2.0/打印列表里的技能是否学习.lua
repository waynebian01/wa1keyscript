local spellinfo = {
    ["圣光术"] = { key = 50, id = 82326 },
    ["圣光闪现"] = { key = 55, id = 19750 },
    ["神圣震击"] = { key = 60, id = 20473 },
    ["圣疗术"] = { key = 65, id = 633 },
    ["荣耀圣令"] = { key = 70, id = 85673 },
    ["仲夏祝福"] = { key = 75, id = 388007 },
    ["清毒术"] = { key = 85, id = 4987 },
    ["凛冬祝福"] = { key = 92, id = 388011 },
    ["暮秋祝福"] = { key = 92, id = 388010 },
    ["阳春祝福"] = { key = 92, id = 388013 },
    ["美德道标"] = { key = 93, id = 200025 },
    ["神圣棱镜"] = { key = 94, id = 114165 },
    ["圣洁鸣钟"] = { key = 95, id = 375576 },
    ["审判"] = { key = 102, id = 275773 },
    ["十字军打击"] = { key = 103, id = 35395 },
    ["愤怒之锤"] = { key = 104, id = 27275 },
}

local function isSpellKnown(spellID) -- 判断技能是否已学习
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(spellID)
    else
        return IsPlayerSpell(spellID)
    end
end

for spellName, data in pairs(spellinfo) do
    if data.id then
        local known = isSpellKnown(data.id)
        local ktxt = known and "已学习" or "未学习"
        if not known then
            print(spellName, ktxt, data.id)
        end
    end
end