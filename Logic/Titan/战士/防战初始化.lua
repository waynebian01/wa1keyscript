local battleShout = {
    [47436] = true, -- 等级9
    [2048] = true,  -- 等级8
    [25289] = true, -- 等级7
    [11551] = true, -- 等级6
    [11550] = true, -- 等级5
    [11549] = true, -- 等级4
    [6192] = true,  -- 等级3
    [5242] = true,  -- 等级2
    [6673] = true,  -- 等级1
}
local commandingShout = {
    [47440] = true, -- 等级3
    [47439] = true, -- 等级2
    [469] = true,   -- 等级1
}

aura_env.Shout = "战斗怒吼"

function aura_env.SetShout(spellID)
    if battleShout[spellID] then
        aura_env.Shout = "战斗怒吼"
    end
    if commandingShout[spellID] then
        aura_env.Shout = "命令怒吼"
    end
end

function aura_env.WarriorInfo()
    local talentInfo = Skippy.TalentInfo
    local SweepingStrikes = false                               -- 横扫攻击
    local freeSweepingStrikes = C_SpellBook.IsSpellKnown(58384) -- 横扫攻击雕文
    if talentInfo then
        if talentInfo["冷酷突击"] and talentInfo["冷酷突击"].rank == 2 then
            aura_env.useRevenge = true
        else
            aura_env.useRevenge = false
        end
        if talentInfo["横扫攻击"] and talentInfo["横扫攻击"].rank == 1 then
            SweepingStrikes = true
        end
    end
    aura_env.SweepingStrikes = SweepingStrikes and freeSweepingStrikes -- 免费横扫攻击
end
