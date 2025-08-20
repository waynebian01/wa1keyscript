local e = aura_env
e.spellkey = {}
local wipe = table.wipe
if not Wa1Key or not Wa1Key.Prop then return end
Wa1Key.Prop.insert = 0
-- 技能 ID 到数字的映射表
local spells = {
    --奥术洪流
    [80483] = true,  -- 猎人
    [50613] = true,  -- 死亡骑士
    [202719] = true, -- 恶魔猎手
    [155145] = true, -- 圣骑士
    [69179] = true,  -- 战士
    [25046] = true,  -- 盗贼
    [232633] = true, -- 牧师
    [28730] = true,  -- 法师 术士
    [129597] = true, -- 武僧
    -- 武僧
    [101643] = true, -- 魂体双分
    [119996] = true, -- 魂体双分：转移
    [119381] = true, -- 扫堂腿
    [116844] = true, -- 平心之环
    [117952] = true, -- 碎玉闪电
    -- 死亡骑士
    [207167] = true, -- 致盲冰雨
    [221562] = true, -- 窒息
    [383269] = true, -- 憎恶
    [51052] = true,  -- 反魔法领域
    [108199] = true, -- 血魔之握
    [279302] = true, -- 冰霜巨龙
    -- 恶魔猎手
    [179057] = true, -- 混乱新星
    [211881] = true, -- 邪能爆发
    [202137] = true, -- 沉默符咒
    [207684] = true, -- 悲苦符咒
    [278326] = true, -- 吞噬魔法
    [196718] = true, -- 黑暗
    [204596] = true, -- 烈焰符咒
    -- 德鲁伊
    [145205] = true, -- 百花齐放
    [99] = true,     -- 夺魂咆哮
    [102359] = true, -- 群体缠绕
    [106898] = true, -- 狂奔怒吼
    [77761] = true,  -- 狂奔怒吼
    [740] = true,    -- 宁静
    [132469] = true, -- 台风
    [102793] = true, -- 乌索尔旋风
    -- 猎人
    [109304] = true, -- 意气风发
    [77764] = true,  -- 狂奔怒吼
    [186387] = true, -- 爆裂射击
    [19801] = true,  -- 宁神射击
    [109248] = true, -- 束缚射击
    [19577] = true,  -- 胁迫
    [187698] = true, -- 焦油陷进
    [187650] = true, -- 冰霜陷阱
    [462031] = true, -- 内爆陷阱
    [236776] = true, -- 高爆陷阱
    -- 法师
    [414660] = true, -- 群体屏障
    [45438] = true,  -- 寒冰屏障
    [30449] = true,  -- 法术吸取
    [113724] = true, -- 冰霜之环
    [118] = true,    -- 变形术
    [449700] = true, -- 引力失效
    [235450] = true, -- 棱光护体
    [11426] = true,  -- 寒冰护体
    [235313] = true, -- 烈焰护体
    -- 牧师
    [421453] = true, -- 终极苦修
    [32375] = true,  -- 群体驱散
    [472433] = true, -- 福音
    [62618] = true,  -- 真言术：障
    [34861] = true,  -- 真言术：灵
    [271466] = true, -- 微光屏障
    [8122] = true,   -- 心灵尖啸
    [200183] = true, -- 神圣化身
    [64843] = true,  -- 神圣赞美诗
    -- 战士
    [46968] = true,  -- 震荡波
    [107570] = true, -- 风暴之锤
    [376079] = true, -- 勇士之矛
    [202168] = true, -- 胜利在望
    [97462] = true,  -- 集结呐喊
    [385952] = true, -- 盾牌冲锋
    [228920] = true, -- 破坏者
    -- 圣骑士
    [375576] = true, -- 圣洁鸣钟
    [387174] = true, -- 提尔之眼
    [853] = true,    -- 制裁之锤
    [642] = true,    -- 圣盾术
    [115750] = true, -- 盲目之光
    -- 萨满祭司
    [188443] = true, -- 闪电链
    [108280] = true, -- 奶潮
    [114052] = true, -- 升腾
    [108270] = true, -- 石壁图腾
    [383013] = true, -- 情毒
    [192063] = true, -- 阵风
    [51490] = true,  -- 雷霆
    [192077] = true, -- 狂风图腾
    [98008] = true,  -- link
    [73920] = true,  -- 大雨
    [198838] = true, -- 墙
}
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

local function ReadKeybindings()
    wipe(e.spellkey)
    for slot = 1, 180 do
        local _, id = GetActionInfo(slot)
        if spells[id] then
            for _, bar in ipairs(actionBars) do
                if slot >= bar.startSlot and slot <= bar.endSlot then
                    -- 计算动作条内的槽位编号（1-12）
                    local slotInBar = slot - bar.startSlot + 1
                    local command = bar.bindingPrefix .. slotInBar -- 构造绑定命令
                    local key = GetBindingKey(command)             -- 获取绑定的按键
                    local spellinfo = C_Spell.GetSpellInfo(id)
                    if key then
                        e.spellkey[id] = {
                            key = key,
                            slot = slot,
                            keycode = keymap[key],
                            icon = spellinfo.iconID
                        }
                    end
                end
            end
        end
    end
end

local function getCooldown(id)
    local cooldown = C_Spell.GetSpellCooldown(id)
    return (cooldown.startTime > 0) and (cooldown.startTime + cooldown.duration - GetTime()) or 0
end
function e.spellIsUsable(spellID)
    local spellCD = getCooldown(spellID)
    local GCD = getCooldown(61304)
    local isUsable = C_Spell.IsSpellUsable(spellID)
    return spellCD <= GCD and isUsable
end

e.ReadKeybindings = ReadKeybindings
e.ReadKeybindings()
