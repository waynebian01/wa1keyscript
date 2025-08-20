local e = aura_env
Wa1Key.Prop.autospell = 0
-- 技能 ID 到数字的映射表
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
    { startSlot = 169, endSlot = 180, bindingPrefix = "MULTIACTIONBAR7BUTTON" },
}
local keymap = {
    -- 数字键 1-9
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["0"] = 10,
    ["-"] = 11,
    ["="] = 12,

    -- 功能键 F1-F12
    ["F1"] = 13,
    ["F2"] = 14,
    ["F3"] = 15,
    ["F4"] = 16,
    ["F5"] = 17,
    ["F6"] = 18,
    ["F7"] = 19,
    ["F8"] = 20,
    ["F9"] = 21,
    ["F10"] = 22,
    ["F11"] = 23,
    ["F12"] = 24,

    -- 字母键
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

    -- 数字键盘
    ["NUMPAD0"] = 25,
    ["NUMPAD1"] = 26,
    ["NUMPAD2"] = 27,
    ["NUMPAD3"] = 28,
    ["NUMPAD4"] = 29,
    ["NUMPAD5"] = 30,
    ["NUMPAD6"] = 31,
    ["NUMPAD7"] = 32,
    ["NUMPAD8"] = 33,
    ["NUMPAD9"] = 34,
    ["NUMPADMULTIPLY"] = 35,
    ["NUMPADPLUS"] = 36,
    ["NUMPADMINUS"] = 37,
    ["NUMPADDECIMAL"] = 38,
    ["NUMPADDIVIDE"] = 39,

    -- 特殊键
    ["Space"] = 40,
    ["["] = 41,
    ["]"] = 42,
    ["\\"] = 43,
    [";"] = 44,
    ["'"] = 45,
    [","] = 46,
    ["."] = 47,
    ["/"] = 48
}
local function IsSpellKnown(spellID)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(spellID)
    else
        return IsPlayerSpell(spellID)
    end
end
local function getCooldown(spellID)
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

-- 检测冷却
function e.spellIsUsable(spellID)
    if not IsSpellKnown(spellID) then
        return false
    end
    local cooldown = getCooldown(spellID)
    local gcd = getCooldown(61304)
    if not cooldown then return false end
    return cooldown <= gcd
end

function e.autospell(spellid)
    if spellid == nil then
        Wa1Key.Prop.autospell = 0
        return false
    end
    local spellInfo = C_Spell.GetSpellInfo(spellid)
    if spellInfo and spellInfo.iconID then
        e.iconID = spellInfo.iconID
    else
        e.iconID = 22829
    end
    for slot = 1, 180 do
        local _, id = GetActionInfo(slot)
        if id == spellid then
            for _, bar in ipairs(e.actionBars) do
                if slot >= bar.startSlot and slot <= bar.endSlot then
                    -- 计算动作条内的槽位编号（1-12）
                    local slotInBar = slot - bar.startSlot + 1
                    local command = bar.bindingPrefix .. slotInBar -- 构造绑定命令
                    local key = GetBindingKey(command)             -- 获取绑定的按键
                    if key then
                        e.key = e.keymap[key]
                        Wa1Key.Prop.autospell = e.key
                        return true
                    end
                end
            end
            break
        end
    end
    Wa1Key.Prop.autospell = 0
    return false
end

function e.hasAura(unit, spellId)
    for j = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, j, "HELPFUL|PLAYER")
        if not auraData then break end
        if auraData.spellId == spellId then
            return true
        end
    end
    return false
end
