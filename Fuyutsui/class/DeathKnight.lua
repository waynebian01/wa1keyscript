local _, fu = ...
if fu.classId ~= 6 then return end
local creat = fu.updateOrCreatTextureByIndex
fu.HarmfulSpellId = 47528
local festering = 22           -- 脓疮
local lesser_ghoul = 23        -- 次级食尸鬼
local sudden_doom = 24         -- 末日突降
local dark_succor = 25         -- 黑暗援助
local forbidden_knowledge = 26 -- 禁断知识

function fu.CreateClassMacro()
    local dynamicSpells = {}
    local staticSpells = {
        [1] = "亡者复生",
        [2] = "亡者大军",
        [3] = "凋零缠绕",
        [4] = "天灾打击",
        [5] = "扩散",
        [6] = "爆发",
        [7] = "脓疮打击",
        [8] = "腐化",
        [9] = "黑暗突变",
        [10] = "灵魂收割",
        [11] = "灵界打击",
        [12] = "心脏打击",
        [13] = "[@player]枯萎凋零",
        [14] = "死神的抚摸",
        [15] = "符文刃舞",
        [16] = "精髓分裂",
        [17] = "血液沸腾",
        [18] = "吸血鬼之血",
        [19] = "冰封之韧",
        [20] = "巫妖之躯",
    }
    fu.CreateMacro(dynamicSpells, staticSpells, _)
end

-- 更新末日突降
function fu.updateSuddenDoom()
    local powerCosts = C_Spell.GetSpellPowerCost(47541)
    if powerCosts and powerCosts[1] and powerCosts[1].cost == 15 then
        creat(sudden_doom, 1 / 255)
    else
        creat(sudden_doom, 0)
    end
end

-- 更新法术发光效果
function fu.updateSpellOverlay(spellId)
    local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellId)
    if spellId == 49998 then
        creat(dark_succor, isSpellOverlayed and 1 / 255 or 0)
    end
end

local lesser_ghoul_count = 0
local lesser_ghoul_floor = 0
local lesser_ghoul_timer = nil
function fu.updateSpellSuccess(spellID)
    if spellID == 85948 or spellID == 458128 or spellID == 1247378 then -- 脓疮打击, 脓疮毒镰, 腐化
        lesser_ghoul_count = math.min(8, lesser_ghoul_count + 3)
        lesser_ghoul_floor = math.floor(lesser_ghoul_count)
        creat(lesser_ghoul, lesser_ghoul_floor / 255)
        if lesser_ghoul_timer then
            lesser_ghoul_timer:Cancel()
        end
        lesser_ghoul_timer = C_Timer.NewTimer(30, function()
            lesser_ghoul_count = 0
            lesser_ghoul_floor = 0
            lesser_ghoul_timer = nil
            creat(lesser_ghoul, 0)
        end)
        C_Timer.After(0.5, function()
            local spellOverride = C_SpellBook.FindSpellOverrideByID(85948)
            if spellOverride == 458128 then
                creat(festering, 1 / 255)
            else
                creat(festering, 0)
            end
        end)
    elseif spellID == 55090 then -- 天灾打击
        lesser_ghoul_count = math.max(0, lesser_ghoul_count - 1)
        lesser_ghoul_floor = math.floor(lesser_ghoul_count)
        creat(lesser_ghoul, lesser_ghoul_floor / 255)
    elseif spellID == 42650 then -- 亡者大军
        creat(forbidden_knowledge, 1 / 255)
        C_Timer.After(30, function()
            creat(forbidden_knowledge, 0)
        end)
    end
end

function fu.updateSpecInfo(specIndex)
    if specIndex == 1 then
        fu.blocks = {
            runes = 11,
            assistant = 12,
            target_valid = 13,
            target_health = 14,
            enemy_count = 15,
            spell_cd = {
                { index = 16, spellId = 46584, name = "亡者复生" },
                { index = 17, spellId = 55233, name = "吸血鬼之血" },
                { index = 18, spellId = 48792, name = "冰封之韧" },
                { index = 19, spellId = 49039, name = "巫妖之躯" },
            }
        }
        fu.assistant_spells = {
            [206930] = 1, -- 心脏打击
            [43265] = 2,  -- 枯萎凋零
            [195292] = 3, -- 死神的抚摸
            [49998] = 4,  -- 灵界打击
            [49028] = 5,  -- 符文刃舞
            [195182] = 6, -- 精髓分裂
            [50842] = 7,  -- 血液沸腾
            [433895] = 8, -- 吸血鬼打击
        }
    elseif specIndex == 3 then
        fu.blocks = {
            runes = 11,
            assistant = 12,
            target_valid = 13,
            target_health = 14,
            enemy_count = 15,
            spell_cd = {
                { index = 16, spellId = 46584, name = "亡者复生" },
                { index = 17, spellId = 42650, name = "亡者大军" },
                { index = 18, spellId = 1247378, name = "腐化" },
                { index = 19, spellId = 1233448, name = "黑暗突变" },
                { index = 20, spellId = 343294, name = "灵魂收割" },
            },
            spell_charge = {
                { index = 21, spellId = 1247378, name = "腐化" },
            },
            aura = {
                festering = 22,            -- 脓疮
                lesser_ghoul = 23,         -- 次级食尸鬼
                sudden_doom = sudden_doom, -- 末日突降
                dark_succor = 25,          -- 黑暗援助
                forbidden_knowledge = 26,  -- 禁断知识
            }
        }
        fu.assistant_spells = {
            [46584] = 1,    -- 亡者复生
            [42650] = 2,    -- 亡者大军
            [47541] = 3,    -- 凋零缠绕
            [55090] = 4,    -- 天灾打击
            [207317] = 5,   -- 扩散
            [77575] = 6,    -- 爆发
            [85948] = 7,    -- 脓疮打击
            [1247378] = 8,  -- 腐化
            [1233448] = 10, -- 黑暗突变
            [343294] = 11,  -- 灵魂收割
        }
    end
end

function fu.updateOnUpdate()
    local powerCosts = C_Spell.GetSpellPowerCost(47541)
    if powerCosts and powerCosts[1] and powerCosts[1].cost == 15 then
        creat(sudden_doom, 1 / 255)
    else
        creat(sudden_doom, 0)
    end
end

fu.updateSpecInfo(fu.specIndex)
