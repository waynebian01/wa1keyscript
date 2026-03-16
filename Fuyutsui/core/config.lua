local _, fu = ...
local className, classFilename, classId = UnitClass("player")
local specIndex = C_SpecializationInfo.GetSpecialization()

fu.className, fu.classFilename, fu.classId = className, classFilename, classId
fu.specIndex = specIndex

function SetTestSecret(set)
    SetCVar("secretChallengeModeRestrictionsForced", set)
    SetCVar("secretCombatRestrictionsForced", set)
    SetCVar("secretEncounterRestrictionsForced", set)
    SetCVar("secretMapRestrictionsForced", set)
    SetCVar("secretPvPMatchRestrictionsForced", set)
    SetCVar("secretAuraDataRestrictionsForced", set)
    SetCVar("scriptErrors", set);
    SetCVar("doNotFlashLowHealthWarning", set);
end

SetTestSecret(1)

-- /script SetTestSecret(0)
-- 遍历队伍成员, 来自WeakAuras的代码
-- @param reversed 是否逆序
-- @param forceParty 是否强制使用队伍
-- @return 迭代器
function fu.IterateGroupMembers(reversed, forceParty)
    local unit = (not forceParty and IsInRaid()) and 'raid' or 'party'
    local numGroupMembers = unit == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
    local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)
    return function()
        local ret
        if i == 0 and unit == 'party' then
            ret = 'player'
        elseif i <= numGroupMembers and i > 0 then
            ret = unit .. i
        end
        i = i + (reversed and -1 or 1)
        return ret
    end
end

function fu.creatColorCurve(point, b)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Linear)
    curve:AddPoint(0, CreateColor(0, 0, 0, 1))
    curve:AddPoint(point, CreateColor(0, 0, b / 255, 1))
    return curve
end

-- 创建颜色曲线
fu.dispelCurve = C_CurveUtil.CreateColorCurve()
fu.dispelCurve:SetType(Enum.LuaCurveType.Step)
fu.dispelCurve:AddPoint(0, CreateColor(0, 0, 0, 1))         -- 无
fu.dispelCurve:AddPoint(1, CreateColor(0, 1, 1 / 255, 1))   -- 魔法
fu.dispelCurve:AddPoint(2, CreateColor(0, 1, 2 / 255, 1))   -- 诅咒
fu.dispelCurve:AddPoint(3, CreateColor(0, 1, 3 / 255, 1))   -- 疾病
fu.dispelCurve:AddPoint(4, CreateColor(0, 1, 4 / 255, 1))   -- 中毒
fu.dispelCurve:AddPoint(11, CreateColor(0, 1, 11 / 255, 1)) -- 流血

fu.EnumPowerType = {
    ["MANA"] = 0,
    ["RAGE"] = 1,
    ["FOCUS"] = 2,
    ["ENERGY"] = 3,
    ["COMBO_POINTS"] = 4,
    ["RUNES"] = 5,
    ["RUNIC_POWER"] = 6,
    ["SOUL_SHARDS"] = 7,
    ["LUNAR_POWER"] = 8,
    ["HOLY_POWER"] = 9,
    ["MAELSTROM"] = 11,
    ["CHI"] = 12,
    ["INSANITY"] = 13,
    ["BURNING_EMBERS"] = 14,
    ["DEMONIC_FURY"] = 15,
    ["ARCANE_CHARGES"] = 16,
    ["FURY"] = 17,
    ["PAIN"] = 18,
    ["ESSENCE"] = 19,
    ["SHADOW_ORBS"] = 28,
}
fu.healerBuffs = {
    -- Preservation Evoker
    355941,      -- Dream Breath
    363502,      -- Dream Flight
    364343,      -- Echo
    366155,      -- Reversion
    367364,      -- Echo Reversion
    373267,      -- Lifebind
    376788,      -- Echo Dream Breath
    -- Augmentation Evoker
    360827,      -- Blistering Scales
    395152,      -- Ebon Might
    410089,      -- Prescience
    410263,      -- Inferno's Blessing
    410686,      -- Symbiotic Bloom
    413984,      -- Shifting Sands
    -- Resto Druid
    774,         -- Rejuv, 回春
    8936,        -- Regrowth, 愈合
    33763,       -- Lifebloom, 生命绽放
    48438,       -- Wild Growth, 野性生长
    155777,      -- Germination, 萌芽
    -- Disc Priest
    17,          -- 真言术：盾
    194384,      -- 救赎
    1253593,     -- 虚空护盾
    -- Holy Priest
    139,         -- 恢复
    41635,       -- 愈合祷言
    77489,       -- 圣言术：静
    -- Mistweaver Monk
    115175,      -- Soothing Mist
    119611,      -- Renewing Mist
    124682,      -- Enveloping Mist
    450769,      -- Aspect of Harmony
    -- Restoration Shaman
    974, 383648, -- Earth Shield
    61295,       -- Riptide
    -- Holy Paladin
    53563,       -- Beacon of Light, 圣光道标
    156322,      -- Eternal Flame, 永恒之火
    156910,      -- Beacon of Faith, 信仰道标
    1244893,     -- Beacon of the Savior, 救世道标
}
fu.actionBars = {
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
fu.keymap = {
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

    ["N0"] = 96,  -- 0x60
    ["N1"] = 97,  -- 0x61
    ["N2"] = 98,  -- 0x62
    ["N3"] = 99,  -- 0x63
    ["N4"] = 100, -- 0x64
    ["N5"] = 101, -- 0x65
    ["N6"] = 102, -- 0x66
    ["N7"] = 103, -- 0x67
    ["N8"] = 104, -- 0x68
    ["N9"] = 105, -- 0x69
    ["N*"] = 106, -- 0x6A
    ["N+"] = 107, -- 0x6B
    ["N-"] = 109, -- 0x6D
    ["N."] = 110, -- 0x6E
    ["N/"] = 111, -- 0x6F

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
fu.roleMap = {
    ["TANK"] = 1,
    ["HEALER"] = 2,
    ["DAMAGER"] = 3,
    ["NONE"] = 0,
}
