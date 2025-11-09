if not Skippy or not Skippy.Units or not Skippy.state or not Skippy.UnitHeal then return end
if Skippy.state.class ~= "萨满祭司" or Skippy.state.specID ~= 264 or not Skippy.state.inRaid then return end
if not Skippy.Group or not Skippy.state.initialization then return Skippy.UnitHeal("Skip", "Skip") end

local state = Skippy.state
local playerAuras = Skippy.GetPlayerAuras
local isKnown = Skippy.IsSpellKnown
local spell = Skippy.GetSpellInfo
local lowestUnit = Skippy.GetLowestUnit() -- 生命值最低的单位
local noRiptideUnit = Skippy.GetLowestUnitWithoutPlayerAuras("激流") -- 没有[激流]光环生命值最低的单位
local hasRiptideUnit = Skippy.GetLowestUnitWithPlayerAura("激流") -- 有[激流]光环生命值最低的单位
local noRiptideTank = Skippy.GetLowestUnitWithoutPlayerAurasAndRole("激流", "TANK") -- 没有[激流]光环的坦克单位生命值最低的单位
local noShieldTank = Skippy.GetUnitWithoutPlayerAurasAndRole("大地之盾", "TANK") -- 没有[大地之盾]光环的坦克单位
local shieldTankCount = Skippy.GetCountWithPlayerAuraAndRole(200, "大地之盾", "TANK") -- 有[大地之盾]光环的坦克单位数量

if state.isCombat then
    if isKnown(157153) then -- 学会天赋[暴雨图腾]的治疗逻辑
        if spell("收回图腾").usable and spell(157153).charges.currentCharges == 0 then
            return Skippy.UnitHeal("spell", "收回图腾")
        end
        if not playerAuras["暴雨图腾"] and spell(157153).charges.currentCharges > 0 then
            return Skippy.UnitHeal("spell", "暴雨图腾")
        end
    end
    if spell("先祖迅捷").usable and lowestUnit and not playerAuras["先祖迅捷"] then
        return Skippy.UnitHeal("spell", "先祖迅捷")
    end
end

-- 学会天赋[低语之潮]时的治疗逻辑
if isKnown(1217598) then
    if spell("激流").usable then
        -- 给没有[激流]生命值最低的单位施放[激流]
        if noRiptideUnit then
            return Skippy.UnitHeal(noRiptideUnit, "激流")
        end
        -- 给没有[激流]的坦克单位施放[激流]
        if noRiptideTank then
            return Skippy.UnitHeal(noRiptideTank, "激流")
        end
    end
    -- 有[波动]光环时，施放[治疗吧]，优先级为：有激流生命值最低，生命值最低，玩家
    if playerAuras["波动"] then
        if hasRiptideUnit then
            return Skippy.UnitHeal(hasRiptideUnit, "治疗波")
        end
        if lowestUnit then
            return Skippy.UnitHeal(lowestUnit, "治疗波")
        end
        return Skippy.UnitHeal("player", "治疗波")
    end
    -- 瞬发[治疗之涌]
    if playerAuras["灵魂行者的潮汐图腾"] and lowestUnit then
        return Skippy.UnitHeal(lowestUnit, "治疗之涌")
    end
    -- 对有[激流]的单位施放[治疗波]
    if hasRiptideUnit then
        return Skippy.UnitHeal(hasRiptideUnit, "治疗波")
    end
    -- 对生命值最低的单位施放[治疗波]
    if lowestUnit then
        return Skippy.UnitHeal(lowestUnit, "治疗波")
    end
end

-- 施放[大地之盾]
if spell("大地之盾").usable then
    -- 玩家没有[大地之盾]光环时，施放[大地之盾]
    if not playerAuras["大地之盾"] then
        return Skippy.UnitHeal("player", "大地之盾")
    end
    -- 学会天赋[元素环绕]时，为没有[大地之盾]的坦克单位施放
    if isKnown(383010) and noShieldTank and shieldTankCount == 0 then
        return Skippy.UnitHeal(noShieldTank, "大地之盾")
    end
end

return Skippy.UnitHeal("None", "None")
