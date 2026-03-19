local _, fu = ...
if fu.classId ~= 2 then return end

local creat = fu.updateOrCreatTextureByIndex
local auras = {
    divinePurpose = {
        name = "神圣意志",
        index = 15,
        remaining = 0,
        duration = 12,
        expirationTime = nil,
    },
    infusionOfLight = {
        name = "圣光灌注",
        index = 16,
        remaining = 0,
        duration = 15,
        expirationTime = nil,
    },
    handOfDivinity = {
        name = "神性之手",
        index = 17,
        remaining = 0,
        duration = 19.5,
        applications = 0,
        expirationTime = nil,
    },
}
local dynamicSpells = { "神圣震击", "圣光闪现", "圣光术", "荣耀圣令", "清洁术" }
local specialSpells = {}
local staticSpells = {
    [1] = "圣疗术",
    [2] = "牺牲祝福",
    [3] = "代祷",
    [4] = "圣盾术",
    [5] = "盲目之光",
    [6] = "保护祝福",
    [7] = "审判",
    [8] = "制裁之锤",
    [9] = "光环掌握",
    [10] = "圣洁鸣钟",
    [11] = "正义盾击",
    [12] = "黎明之光",
    [13] = "自由祝福",
    [14] = "神圣棱镜",
    [15] = "神圣震击",
}
fu.HelpfulSpellId = 19750
fu.HarmfulSpellId = 275773
fu.HarmfulRemoteSpellId = 275773
fu.HarmfulMeleeSpellId = 853

-- 创建圣骑士宏
function fu.CreateClassMacro()
    fu.CreateMacro(dynamicSpells, staticSpells, specialSpells)
end

-- 更新法术成功效果
function fu.updateSpellSuccess(spellID)
    if spellID == 31884 then
        C_Timer.After(0.5, function()
            local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(82326)
            if isSpellOverlayed then
                auras.handOfDivinity.expirationTime = GetTime() + auras.handOfDivinity.duration
                auras.handOfDivinity.applications = 2
            end
        end)
    elseif spellID == 82326 then
        C_Timer.After(0.1, function()
            local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(82326)
            print(isSpellOverlayed)
            if isSpellOverlayed then
                auras.handOfDivinity.applications = auras.handOfDivinity.applications - 1
            else
                auras.handOfDivinity.applications = 0
                auras.handOfDivinity.expirationTime = nil
            end
        end)
    end
end

-- 更新法术发光效果
function fu.updateSpellOverlay(spellId)
    --[[if spellId == 82326 then
        local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(82326)
        if isSpellOverlayed then
            auras.handOfDivinity.expirationTime = GetTime() + auras.handOfDivinity.duration
        else
            auras.handOfDivinity.expirationTime = nil
        end
    end]]
end

-- 更新法术警报, SPELL_ACTIVATION_OVERLAY_SHOW
function fu.spellActivationOverlayShow(spellID)
    if spellID == 223819 then
        auras.divinePurpose.expirationTime = GetTime() + auras.divinePurpose.duration
    elseif spellID == 54149 then
        auras.infusionOfLight.expirationTime = GetTime() + auras.infusionOfLight.duration
    end
end

-- 更新法术警报, SPELL_ACTIVATION_OVERLAY_HIDE
function fu.spellActivationOverlayHide(spellID)
    if spellID == 223819 then
        auras.divinePurpose.expirationTime = nil
    elseif spellID == 54149 then
        auras.infusionOfLight.expirationTime = nil
    end
end

function fu.updateSpecInfo(specIndex)
    if specIndex == 1 then
        fu.powerType = "MANA"
        fu.blocks = {
            holyPower = 11,
            target_valid = 12,
            group_type = 13,
            members_count = 14,
            aura = {
                ["神圣意志"] = auras.divinePurpose.index,
                ["圣光灌注"] = auras.infusionOfLight.index,
                ["神性之手"] = auras.handOfDivinity.index,
            },
            spell_cd = {
                { index = 21, spellId = 20473, name = "神圣震击" },
                { index = 22, spellId = 4987, name = "清洁术" },
                { index = 23, spellId = 115750, name = "盲目之光" },
                { index = 24, spellId = 275773, name = "审判" },
                { index = 25, spellId = 375576, name = "圣洁鸣钟" },
                { index = 26, spellId = 114165, name = "神圣棱镜" },
                { index = 27, spellId = 31821, name = "光环掌握" },
                { index = 28, spellId = 6940, name = "牺牲祝福" },
                { index = 29, spellId = 1044, name = "自由祝福" },
            },
            spell_charge = {
                { index = 30, spellId = 20473, name = "神圣震击" },
            },
        }
        fu.group_show = true
        fu.group_unit_start = 40
        fu.group_block_num = 6
        fu.group_blocks = {
            healthPercent = 1,
            role = 2,
            dispel = 3,
            aura = {
                [4] = { 156322 },        -- 永恒之火
                [5] = { 1244893 },       -- 救世道标
                [6] = { 53563, 156910 }, -- 圣光道标, 信仰道标
            },
        }
        fu.assistant_spells = {
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
end

print("载入圣骑士")
