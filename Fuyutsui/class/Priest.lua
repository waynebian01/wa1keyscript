local _, fu = ...
if fu.classId ~= 5 then return end
local creat = fu.updateOrCreatTextureByIndex
local auras = {
    voidShield = {
        name = "虚空之盾",
        index = 23,
        remaining = 0,
        duration = 15,
        expirationTime = nil,
    },
    lightBurst = {
        name = "圣光涌动",
        index = 24,
        remaining = 0,
        duration = nil, -- 持续时间, nil代表无限时间
        expirationTime = nil,
    },
}

local voidShield = 23 -- 虚空之盾
local lightBurst = 24 -- 圣光涌动

fu.HarmfulSpellId = 585
fu.HelpfulSpellId = 2061

function fu.CreateClassMacro()
    local dynamicSpells = { "苦修", "快速治疗", "真言术：盾", "恳求", "纯净术" }
    local staticSpells = {
        [1] = "心灵震爆",
        [2] = "惩击",
        [3] = "暗言术：痛",
        [4] = "真言术：韧",
        [5] = "神圣新星",
        [6] = "苦修",
        [7] = "真言术：耀",
        [8] = "福音",
        [9] = "终极苦修",
        [10] = "绝望祷言",
        [11] = "暗言术：灭",
        [12] = "吸血鬼之触",
        [13] = "[nostance:1]暗影形态",
        [14] = "暗言术：癫",
        [15] = "精神鞭笞",
        [16] = "虚空形态",
        [17] = "虚空洪流",
        [18] = "触须猛击",
        [19] = "虚空冲击",
        [20] = "虚空齐射",
    }
    fu.CreateMacro(dynamicSpells, staticSpells)
end

function fu.updateSpellSuccess(spellID)
    if spellID == 47540 or spellID == 1253593 then -- 苦修, 虚空之盾
        C_Timer.After(0.5, function()
            local spellOverride = C_SpellBook.FindSpellOverrideByID(17)
            if spellOverride == 1253593 then
                creat(voidShield, 1 / 255)
            else
                creat(voidShield, 0)
            end
        end)
    end
end

-- 更新法术发光效果
function fu.updateSpellOverlay(spellId)
    local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellId)
    if spellId == 2061 then
        creat(lightBurst, isSpellOverlayed and 1 / 255 or 0)
    end
end

function fu.updateSpecInfo(specIndex)
    if specIndex == 1 then
        fu.powerType = "MANA"
        fu.blocks = {
            assistant = 11,
            target_valid = 12,
            group_type = 13,
            group_count = 14,
            spell_cd = {
                { index = 15, spellId = 17, name = "真言术：盾" },
                { index = 16, spellId = 47540, name = "苦修" },
                { index = 17, spellId = 194509, name = "真言术：耀" },
                { index = 18, spellId = 527, name = "纯净术" },
                { index = 19, spellId = 19236, name = "绝望祷言" },
                { index = 20, spellId = 8092, name = "心灵震爆" },
                { index = 21, spellId = 472433, name = "福音" },
                { index = 22, spellId = 32379, name = "暗言术：灭" },
            },
            aura = {
                ["虚空之盾"] = voidShield,
                ["圣光涌动"] = lightBurst,
            },
        }
        fu.group_show = true
        fu.group_unit_start = 40
        fu.group_block_num = 5
        fu.group_blocks = {
            healthPercent = 1,
            role = 2,
            dispel = 3,
            aura = {
                [4] = { 194384 },
                [5] = { 17, 1253593 },
            },
        }
        fu.assistant_spells = {
            [8092] = 1,  -- 心灵震爆
            [585] = 2,   -- 惩击
            [32379] = 3, -- 暗言术：灭
            [589] = 4,   -- 暗言术：痛
            [21562] = 5, -- 真言术：韧
            [47540] = 6, -- 苦修
        }
    elseif specIndex == 3 then
        fu.powerType = "INSANITY"
        fu.blocks = {
            assistant = 11,
            target_valid = 12,
            spell_cd = {
                { index = 13, spellId = 8092, name = "心灵震爆" },
                { index = 14, spellId = 32379, name = "暗言术：灭" },
                { index = 15, spellId = 263165, name = "虚空洪流" },
                { index = 16, spellId = 228260, name = "虚空形态" },
                { index = 17, spellId = 1227280, name = "触须猛击" },
                { index = 18, spellId = 19236, name = "绝望祷言" },
            }
        }
        fu.assistant_spells = {
            [34914] = 1,    -- 吸血鬼之触
            [8092] = 2,     -- 心灵震爆
            [232698] = 3,   -- 暗影形态
            [32379] = 4,    -- 暗言术：灭
            [589] = 5,      -- 暗言术：痛
            [335467] = 6,   -- 暗言术：癫
            [21562] = 7,    -- 真言术：韧
            [15407] = 8,    -- 精神鞭笞
            [228260] = 9,   -- 虚空形态
            [263165] = 10,  -- 虚空洪流
            [1227280] = 11, -- 触须猛击
            [450983] = 12,  -- 虚空冲击
            [1242173] = 13, -- 虚空齐射
        }
    end
end

function fu.updateOnUpdate()

end

fu.updateSpecInfo(fu.specIndex)
