-- Skippy spellkey
-- 作者: Wayne
-- 说明: 扫描动作条 1..180 槽位

if not Skippy then Skippy = {} end
Skippy.spellkey = Skippy.spellkey or {}

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
    { startSlot = 169, endSlot = 180, bindingPrefix = "MULTIACTIONBAR7BUTTON" }
}

local keymap = {
    ["1"] = 49,
    ["2"] = 50,
    ["3"] = 51,
    ["4"] = 52,
    ["5"] = 53,
    ["6"] = 54,
    ["7"] = 55,
    ["8"] = 56,
    ["9"] = 57,
    ["0"] = 48,

    ["F1"] = 112,
    ["F2"] = 113,
    ["F3"] = 114,
    ["F4"] = 115,
    ["F5"] = 116,
    ["F6"] = 117,
    ["F7"] = 118,
    ["F8"] = 119,
    ["F9"] = 120,
    ["F10"] = 121,
    ["F11"] = 122,
    ["F12"] = 123,

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

    ["NUMPAD0"] = 96,
    ["NUMPAD1"] = 97,
    ["NUMPAD2"] = 98,
    ["NUMPAD3"] = 99,
    ["NUMPAD4"] = 100,
    ["NUMPAD5"] = 101,
    ["NUMPAD6"] = 102,
    ["NUMPAD7"] = 103,
    ["NUMPAD8"] = 104,
    ["NUMPAD9"] = 105,
    ["NUMPADMULTIPLY"] = 106,
    ["NUMPADPLUS"] = 107,
    ["NUMPADMINUS"] = 109,
    ["NUMPADDECIMAL"] = 110,
    ["NUMPADDIVIDE"] = 111,

    ["SPACE"] = 32,
    ["="] = 187,
    ["EQUALS"] = 187, -- WoW可能返回EQUALS而不是=
    ["-"] = 189,
    ["MINUS"] = 189,  -- WoW可能返回MINUS而不是-
    ["["] = 219,
    ["]"] = 221,
    ["\\"] = 220,
    [";"] = 186,
    ["SEMICOLON"] = 186, -- WoW可能返回SEMICOLON而不是;
    ["'"] = 222,
    [","] = 188,
    ["COMMA"] = 188,  -- WoW可能返回COMMA而不是,
    ["."] = 190,
    ["PERIOD"] = 190, -- WoW可能返回PERIOD而不是.
    ["/"] = 191,
}

-- 处理单个动作槽位
local function ProcessActionSlot_WLK(slot)
    local actionType, id = GetActionInfo(slot)
    if not id then return end
    if actionType ~= "macro" and actionType ~= "spell" and actionType ~= "item" then return end

    local name, icon, spellId, itemId

    -- macro: 尝试取宏中的 spell
    if actionType == "macro" then
        local macroSpell = GetMacroSpell(id)
        if macroSpell then
            local info = C_Spell.GetSpellInfo(macroSpell)
            if info then
                spellId = macroSpell
                icon = info.iconID
                name = info.name
            end
        else
            -- 宏没有直接施法技能, 让 name 标明为宏名以便调试
            local macroName = select(1, GetMacroInfo(id))
            name = macroName or "<macro>"
        end
    end

    if actionType == "spell" then
        local info = C_Spell.GetSpellInfo(id)
        if info then
            spellId = id
            icon = info.iconID
            name = info.name
        else
            -- 有时 spell 信息尚未加载, 忽略
            return
        end
    end

    if actionType == "item" then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(id)
        if itemName then
            itemId = id
            name = itemName
            icon = itemIcon
        else
            -- 物品信息未加载, 忽略
            return
        end
    end

    -- 找到动作条定义
    for _, bar in ipairs(actionBars) do
        if slot >= bar.startSlot and slot <= bar.endSlot then
            local slotInBar = slot - bar.startSlot + 1
            local command = bar.bindingPrefix .. slotInBar

            local binding = GetBindingKey(command)
            if not binding then break end
            local keycode = keymap[binding]
            if binding and keycode then
                -- 确保 Skippy.spellkey[slot] 是一个表格, 记录所有绑定
                if not Skippy.spellkey[slot] then
                    Skippy.spellkey[slot] = {}
                end
                Skippy.spellkey[slot].actionType = actionType
                Skippy.spellkey[slot].id = id
                Skippy.spellkey[slot].icon = icon
                Skippy.spellkey[slot].name = name
                Skippy.spellkey[slot].spellId = spellId
                Skippy.spellkey[slot].itemId = itemId
                Skippy.spellkey[slot].key = binding
                Skippy.spellkey[slot].keycode = keycode


                -- 如果没有任何绑定 (rare), 清理可能残留的数据
                if not binding and Skippy.spellkey[slot] then
                    Skippy.spellkey[slot] = nil
                end

                break -- 找到对应动作条后跳出
            end
        end
    end
end

local function ProcessActionSlot_MistsOrRetail(slot)
    -- 1. 获取动作信息并进行卫语句检查
    local actionType, id = GetActionInfo(slot)
    if actionType ~= "macro" and actionType ~= "spell" then
        return
    end

    -- 2. 获取法术信息并进行卫语句检查
    local spellinfo = C_Spell.GetSpellInfo(id)
    if not spellinfo then
        return
    end

    -- 3. 遍历动作条
    for _, bar in ipairs(actionBars) do
        -- 4. 检查槽位是否在当前动作条范围内
        if slot >= bar.startSlot and slot <= bar.endSlot then
            local slotInBar = slot - bar.startSlot + 1
            local command = bar.bindingPrefix .. slotInBar -- 构造绑定命令
            local key = GetBindingKey(command)             -- 获取绑定的按键
            -- 5. 检查是否有按键绑定
            if key then
                Skippy.spellkey[id] = {
                    key = key,
                    slot = slot,
                    keycode = keymap[key],
                    icon = spellinfo.iconID,
                    name = spellinfo.name,
                }
                -- 如果一个动作（如法术）只需要被记录一次，
                -- 找到绑定后就可以跳出动作条循环 (break)
                -- break
            end
        end
    end
end

-- 扫描函数
function aura_env.ReadKeybindings()
    -- 清理并重新扫描
    for slot = 1, 180 do
        if WeakAuras.IsMistsOrRetail() then
            ProcessActionSlot_MistsOrRetail(slot)
        elseif WeakAuras.IsWrathClassic() then
            ProcessActionSlot_WLK(slot)
        end
    end
end

aura_env.ReadKeybindings()
