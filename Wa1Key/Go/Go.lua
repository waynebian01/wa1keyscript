if not Wa1Key or not Wa1Key.Prop then return true end

local e = aura_env
--local inVehicle = UnitInVehicle("player")                     -- 载具
local chatFrame = ChatFrame1EditBox:IsVisible()                                            -- 聊天框
local minRange, maxRange = WeakAuras.GetRange("target")
local interrupt = Wa1Key.Prop.Interrupt                                                    -- 防御打断
local range = e.specRangeMap[e.specID] or 8                                                -- 默认8码
local hekili = Hekili_GetRecommendedAbility and Hekili_GetRecommendedAbility("Primary", 1) -- 获取Hekili推荐技能
local inRange = true

if not maxRange then maxRange = 255 end
if hekili and hekili > 0 then
    local spellInfo = C_Spell.GetSpellInfo(hekili)
    local inSpellRange = C_Spell.IsSpellInRange(hekili, "target")
    local isHarmful = C_Spell.IsSpellHarmful(hekili)
    if spellInfo then
        if spellInfo.maxRange == 0 then
            inRange = maxRange <= range
        else
            if isHarmful and inSpellRange == false then
                inRange = false
            end
        end
    end
end

if interrupt == 1 then
    Wa1Key.Prop.Go = 254
    return true
end

if e.mounted or chatFrame or e.dead or e.travel or e.catStealth then
    Wa1Key.Prop.Go = 255
    return true
end

if e.vanish then -- 消失
    Wa1Key.Prop.Go = 1
    return true
end

if e.validSkills[hekili] then
    Wa1Key.Prop.Go = 1
    return true
end

if e.targetCanAttack and inRange and e.isCombat and not e.targetisdead then
    Wa1Key.Prop.Go = 1
    return true
end

Wa1Key.Prop.Go = 2
return true
