local _, fu = ...
if fu.classId ~= 11 then return end

local creat = fu.updateOrCreatTextureByIndex
local naturalSwiftness = 19
local auras = {
    clearcasting = {
        name = "节能施法",
        index = 18,
        remaining = 0,
        duration = 15,
        expirationTime = nil,
    },
    --[[naturalSwiftness = {
        name = "自然迅捷",
        index = 19,
        remaining = 0,
        duration = nil, -- 持续时间, nil代表无限时间
        expirationTime = nil,
    },]]
    forestSoul = {
        name = "丛林之魂",
        index = 20,
        remaining = 0,
        duration = 15,
        expirationTime = nil,
    },
    ironfur = {
        name = "铁鬃",
        index = 21,
        remaining = 0,
        duration = 7,
        expirationTime = nil,
    },
    frenzied = {
        name = "狂暴回复",
        index = 22,
        remaining = 0,
        duration = 4,
        expirationTime = nil,
    },
    cenariusDream = {
        name = "塞纳留斯的梦境", -- 372152
        index = 23,
        remaining = 0,
        duration = 30,
        applications = 0,
        expirationTime = nil,
    },
    giftOfIronfur = {
        name = "铁鬃之赐", -- 1269659
        index = 24,
        remaining = 0,
        duration = 60,
        applications = 0,
        expirationTime = nil,
    },
    giftOfMaul = {
        name = "重殴之赐", -- 1269660
        index = 25,
        remaining = 0,
        duration = 60,
        applications = 0,
        expirationTime = nil,
    },
    giftOfFrenziedRegeneration = {
        name = "狂暴回复之赐", -- 1269661
        index = 26,
        remaining = 0,
        duration = 60,
        applications = 0,
        expirationTime = nil,
    },
}

fu.HelpfulSpellId = 774
fu.HarmfulSpellId = 5176
fu.HarmfulRemoteSpellId = 5176
fu.HarmfulMeleeSpellId = 1822

-- 创建德鲁伊宏
function fu.CreateClassMacro()
    local dynamicSpells = { "回春术", "愈合", "生命绽放", "迅捷治愈", "自然之愈" }
    local specialSpells = { [17] = "/cancelaura [spec:4]猎豹形态\n/cast 万灵之召", }
    local staticSpells = {
        [1] = "[nostance:2]猎豹形态(变形)",
        [2] = "[nostance:1]熊形态(变形)",
        [3] = "[nostance:4]枭兽形态",
        [4] = "月火术",
        [5] = "树皮术",
        [6] = "横扫",
        [7] = "潜行",
        [8] = "凶猛撕咬",
        [9] = "愤怒",
        [10] = "割裂",
        [11] = "撕碎",
        [12] = "斜掠",
        [13] = "痛击",
        [14] = "野性印记",
        [15] = "裂伤",
        [16] = "野性成长",
        [18] = "自然迅捷",
        [19] = "激活",
        [20] = "野性之心",
        [21] = "野性冲锋",
        [22] = "铁鬃",
        [23] = "摧折",
        [24] = "明月普照",
        [25] = "狂暴回复",
    }
    fu.CreateMacro(dynamicSpells, staticSpells, specialSpells)
end

-- 更新法术成功效果
function fu.updateSpellSuccess(spellID)
    local currentTime = GetTime()
    if spellID == 132158 then -- 获得 自然迅捷
        creat(naturalSwiftness, 1 / 255)
        C_Timer.After(30, function()
            creat(naturalSwiftness, 0)
        end)
    elseif spellID == 18562 then -- 获得 丛林之魂
        auras.forestSoul.expirationTime = currentTime + auras.forestSoul.duration
        C_Timer.After(15, function()
            auras.forestSoul.expirationTime = nil
        end)
    elseif spellID == 8936 then -- 消耗 丛林之魂 和 自然迅捷 和 塞纳留斯的梦境(1层)
        auras.forestSoul.expirationTime = nil
        auras.cenariusDream.applications = auras.cenariusDream.applications - 1
        local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellID)
        if not isSpellOverlayed then auras.clearcasting.expirationTime = nil end
        creat(naturalSwiftness, 0)
    elseif spellID == 774 then                     -- 消耗 丛林之魂
        auras.forestSoul.expirationTime = nil
    elseif spellID == 20484 or spellID == 339 then -- 消耗 自然迅捷
        creat(naturalSwiftness, 0)
    elseif spellID == 192081 then                  -- 铁鬃
        auras.ironfur.expirationTime = currentTime + auras.ironfur.duration
        auras.giftOfIronfur.applications = auras.giftOfIronfur.applications - 1
    elseif spellID == 22842 then -- 狂暴回复
        auras.frenzied.expirationTime = currentTime + auras.frenzied.duration
        auras.giftOfFrenziedRegeneration.applications = auras.giftOfFrenziedRegeneration.applications - 1
        local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellID)
        if not isSpellOverlayed then auras.clearcasting.expirationTime = nil end
    elseif spellID == 400254 then  -- 摧折
        auras.giftOfMaul.applications = auras.giftOfMaul.applications - 1
    elseif spellID == 1269658 then -- 荒野守护者
        auras.cenariusDream.expirationTime = currentTime + auras.cenariusDream.duration
        auras.cenariusDream.applications = 2
        auras.giftOfIronfur.expirationTime = currentTime + auras.giftOfIronfur.duration
        auras.giftOfIronfur.applications = 2
        auras.giftOfMaul.expirationTime = currentTime + auras.giftOfMaul.duration
        auras.giftOfMaul.applications = 2
        auras.giftOfFrenziedRegeneration.expirationTime = currentTime + auras.giftOfFrenziedRegeneration.duration
        auras.giftOfFrenziedRegeneration.applications = 2
    end
end

-- 更新法术发光效果
function fu.updateSpellOverlay(spellId)
    if spellId == 8936 then
        local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellId)
        if isSpellOverlayed then
            auras.clearcasting.expirationTime = GetTime() + auras.clearcasting.duration
        else
            auras.clearcasting.expirationTime = nil
        end
    end
end

function fu.updateSpecInfo(specIndex)
    if specIndex == 3 then
        fu.powerType = "RAGE"
        auras.clearcasting.duration = 30
        fu.blocks = {
            assistant = 11,
            target_valid = 12,
            target_health = 13,
            enemy_count = 14,
            stance = 15,
            aura = {
                ["铁鬃"] = auras.ironfur.index, -- 16
            },
            spell_cd = {
                { index = 31, spellId = 22812, name = "树皮术" },
                { index = 32, spellId = 61336, name = "生存本能" },
                { index = 33, spellId = 22842, name = "狂暴回复" },
                { index = 34, spellId = 132469, name = "台风" },
                { index = 35, spellId = 99, name = "夺魂咆哮" },
                { index = 36, spellId = 102558, name = "化身：乌索克的守护者" },
                { index = 37, spellId = 132158, name = "自然迅捷" },
                { index = 38, spellId = 29166, name = "激活" },
                { index = 39, spellId = 1261867, name = "野性之心" },
            },
            spell_charge = {
                { index = 40, spellId = 22842, name = "狂暴回复" },
            },
        }
        fu.group_show = false
        fu.assistant_spells = {
            [400254] = 1, -- 摧折
            [204066] = 2, -- 明月普照
            [8921] = 3,   -- 月火术
            [213771] = 4, -- 横扫
            [5487] = 5,   -- 熊形态
            [77758] = 6,  -- 痛击
            [33917] = 7,  -- 裂伤
            [1126] = 8,   -- 野性印记
        }
    elseif specIndex == 4 then
        fu.powerType = "MANA"
        fu.blocks = {
            assistant = 11,
            target_valid = 12,
            group_type = 13,
            stance = 14,
            target_distance = 15,
            members_count = 16,
            comboPoints = 17,
            aura = {
                ["节能施法"] = auras.clearcasting.index,
                ["自然迅捷"] = naturalSwiftness,
                ["丛林之魂"] = auras.forestSoul.index,
            },
            spell_cd = {
                { index = 31, spellId = 22812, name = "树皮术" },
                { index = 32, spellId = 48438, name = "野性成长" },
                { index = 33, spellId = 391528, name = "万灵之召" },
                { index = 34, spellId = 18562, name = "迅捷治愈" },
                { index = 35, spellId = 88423, name = "自然之愈" },
                { index = 36, spellId = 102342, name = "铁木树皮" },
                { index = 37, spellId = 132158, name = "自然迅捷" },
                { index = 38, spellId = 29166, name = "激活" },
                { index = 39, spellId = 1261867, name = "野性之心" },
            },
        }
        fu.group_show = true
        fu.group_unit_start = 40
        fu.group_block_num = 7
        fu.group_blocks = {
            healthPercent = 1,
            role = 2,
            dispel = 3,
            aura = {
                [4] = { 33763 },                    -- 生命绽放
                [5] = { 774, 155777, 8936, 48438 }, -- 迅捷治愈(回春术, 萌芽, 愈合, 野性生长)
                [6] = { 8936 },                     -- 愈合
            },
            rejuv = 7,                              -- 回春术数量
        }
        fu.assistant_spells = {
            [22568] = 1, -- 凶猛撕咬
            [1079] = 2,  -- 割裂
            [5221] = 3,  -- 撕碎
            [1822] = 4,  -- 斜掠
            [8921] = 5,  -- 月火术
            [5176] = 6,  -- 愤怒
            [1126] = 7,  -- 野性印记
        }
    end
end

fu.updateSpecInfo(fu.specIndex)

function fu.updateOnUpdate()
    for _, aura in pairs(auras) do
        if aura.expirationTime then
            aura.remaining = math.floor(aura.expirationTime - GetTime() + 0.5)
            if aura.remaining > 0 then
                creat(aura.index, aura.remaining / 255)
            else
                aura.expirationTime = nil
                creat(aura.index, 0)
            end
        else
            aura.remaining = 0
            creat(aura.index, 0)
        end
        if aura.applications and aura.applications <= 0 then
            aura.expirationTime = nil
            creat(aura.index, 0)
        end
    end
    if not fu.group_show or not fu.group_blocks.rejuv then return end
    for unit, data in pairs(fu.group) do
        local has_rejuv_count = 0
        local index = fu.group_unit_start + data.index * fu.group_block_num + fu.group_blocks.rejuv
        local rejuv_aura = C_UnitAuras.GetUnitAuraBySpellID(unit, 774)
        local rejuv2_aura = C_UnitAuras.GetUnitAuraBySpellID(unit, 155777)
        if rejuv_aura and rejuv_aura.sourceUnit == "player" then
            has_rejuv_count = has_rejuv_count + 1
        end
        if rejuv2_aura and rejuv2_aura.sourceUnit == "player" then
            has_rejuv_count = has_rejuv_count + 1
        end
        creat(index, has_rejuv_count / 255)
    end
end
