if not Skippy then Skippy = {} end
Skippy.spellkey = {}
local wipe = table.wipe
if not Wa1Key or not Wa1Key.Prop then return end

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
    ["1"] = 49,        -- 0x31
    ["2"] = 50,        -- 0x32
    ["3"] = 51,        -- 0x33
    ["4"] = 52,        -- 0x34
    ["5"] = 53,        -- 0x35
    ["6"] = 54,        -- 0x36
    ["7"] = 55,        -- 0x37
    ["8"] = 56,        -- 0x38
    ["9"] = 57,        -- 0x39
    ["0"] = 48,        -- 0x30

    ["F1"] = 112,      -- 0x70
    ["F2"] = 113,      -- 0x71
    ["F3"] = 114,      -- 0x72
    ["F4"] = 115,      -- 0x73
    ["F5"] = 116,      -- 0x74
    ["F6"] = 117,      -- 0x75
    ["F7"] = 118,      -- 0x76
    ["F8"] = 119,      -- 0x77
    ["F9"] = 120,      -- 0x78
    ["F10"] = 121,     -- 0x79
    ["F11"] = 122,     -- 0x7A
    ["F12"] = 123,     -- 0x7B

    ["Q"] = 81,        -- 0x51
    ["W"] = 87,        -- 0x57
    ["E"] = 69,        -- 0x45
    ["R"] = 82,        -- 0x52
    ["T"] = 84,        -- 0x54
    ["Y"] = 89,        -- 0x59
    ["U"] = 85,        -- 0x55
    ["I"] = 73,        -- 0x49
    ["O"] = 79,        -- 0x4F
    ["P"] = 80,        -- 0x50
    ["A"] = 65,        -- 0x41
    ["S"] = 83,        -- 0x53
    ["D"] = 68,        -- 0x44
    ["F"] = 70,        -- 0x46
    ["G"] = 71,        -- 0x47
    ["H"] = 72,        -- 0x48
    ["J"] = 74,        -- 0x4A
    ["K"] = 75,        -- 0x4B
    ["L"] = 76,        -- 0x4C
    ["Z"] = 90,        -- 0x5A
    ["X"] = 88,        -- 0x58
    ["C"] = 67,        -- 0x43
    ["V"] = 86,        -- 0x56
    ["B"] = 66,        -- 0x42
    ["N"] = 78,        -- 0x4E
    ["M"] = 77,        -- 0x4D

    ["NUMPAD0"] = 96,  -- 0x60
    ["NUMPAD1"] = 97,  -- 0x61
    ["NUMPAD2"] = 98,  -- 0x62
    ["NUMPAD3"] = 99,  -- 0x63
    ["NUMPAD4"] = 100, -- 0x64
    ["NUMPAD5"] = 101, -- 0x65
    ["NUMPAD6"] = 102, -- 0x66
    ["NUMPAD7"] = 103, -- 0x67
    ["NUMPAD8"] = 104, -- 0x68
    ["NUMPAD9"] = 105, -- 0x69
    ["NUMPAD*"] = 106, -- 0x6A
    ["NUMPAD+"] = 107, -- 0x6B
    ["NUMPAD-"] = 109, -- 0x6D
    ["NUMPAD."] = 110, -- 0x6E
    ["NUMPAD/"] = 111, -- 0x6F

    ["Space"] = 32,    -- 0x20
    ["="] = 187,       -- 0xBB
    ["-"] = 189,       -- 0xBD
    ["["] = 219,       -- 0xDB
    ["]"] = 221,       -- 0xDD
    ["\\"] = 220,      -- 0xDC
    [";"] = 186,       -- 0xBA
    ["'"] = 222,       -- 0xDE
    [","] = 188,       -- 0xBC
    ["."] = 190,       -- 0xBE
    ["/"] = 191,       -- 0xBF
}

local function ReadKeybindings()
    for slot = 1, 180 do
        local actionType, id = GetActionInfo(slot)
        if actionType == "macro" or actionType == "spell" then
            local spellinfo = C_Spell.GetSpellInfo(id)
            if spellinfo then
                for _, bar in ipairs(actionBars) do
                    if slot >= bar.startSlot and slot <= bar.endSlot then
                        -- 计算动作条内的槽位编号（1-12）
                        local slotInBar = slot - bar.startSlot + 1
                        local command = bar.bindingPrefix .. slotInBar -- 构造绑定命令
                        local key = GetBindingKey(command)             -- 获取绑定的按键
                        if key then
                            Skippy.spellkey[id] = {
                                key = key,
                                slot = slot,
                                keycode = keymap[key],
                                icon = spellinfo.iconID,
                                name = spellinfo.name,
                            }
                        end
                    end
                end
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UPDATE_BINDINGS")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("ACTIONBAR_SHOWGRID")
frame:RegisterEvent("ACTIONBAR_HIDEGRID")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event)
    if event == "UPDATE_BINDINGS" or
        event == "SPELLS_CHANGED" or
        event == "ACTIONBAR_SHOWGRID" or
        event == "ACTIONBAR_HIDEGRID" or
        event == "ACTIVE_TALENT_GROUP_CHANGED" or
        event == "PLAYER_ENTERING_WORLD" then        
        C_Timer.After(0.5, function()
            wipe(Skippy.spellkey)
            ReadKeybindings()
        end)
    end
end)
