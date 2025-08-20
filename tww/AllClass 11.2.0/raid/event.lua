function WA(event, arg1, arg2, arg3) -- event, arg1, castGUID/updateInfo, spellID
    local e = aura_env
    local player = e.playerinfo
    local r = e.raidstatus
    if not e.initialization then return end
    if event == "PLAYER_ENTERING_WORLD" then
        e.initialization = false
        -- 队伍信息
        e.GetRaidfixedInfo()   -- 获取团队固定信息
        e.updateRaidStatus()   -- 更新团队状态
        -- 玩家信息
        e.getPlayerInfo()      -- 获取玩家信息
        e.getTalentInfo()      -- 获取玩家天赋
        e.getSpellInfo()       -- 获取技能信息
        e.getSpellCharges()    -- 获取技能充能
        e.getPlayerManaPct()   -- 获取玩家法力
        e.getHolyPower()       -- 获取圣骑士能量
        e.getEvangelismValue() -- 获取福音的总体治疗量
        e.updateCooldown()     -- 更新技能冷却
        -- 目标信息
        e.getTargetInfo()      -- 获取目标信息
        e.getTargetAura()      -- 获取目标光环
        e.updateUnitRange()    -- 更新单位距离
        e.initialization = true
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        local seasonsSpells = { [388007] = true, [388011] = true, [388010] = true, [388013] = true }
        if player.class == "圣骑士" and seasonsSpells[arg3] then
            C_Timer.After(1, function()
                player.seasonsID = C_Spell.GetOverrideSpell(388007)
                print(player.seasonsID)
            end)
        end
    end
    -- 光环变化
    if event == "UNIT_AURA" and arg1 == "target" then
        e.getTargetAura()
    end
    -- 队伍成员变化
    if event == "GROUP_ROSTER_UPDATE" then
        e.initialization = false
        e.GetRaidfixedInfo()
        e.initialization = true
    end
    -- 技能充能更新
    if event == "SPELL_UPDATE_CHARGES" then e.getSpellCharges() end
    -- 天赋变化
    if event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        e.getPlayerInfo() -- 更新玩家信息
        e.getTalentInfo() -- 获取天赋
        e.getSpellInfo()  -- 获取技能信息
    end
    -- 属性变化
    if event == "COMBAT_RATING_UPDATE" or event == "SPELL_POWER_CHANGED" then
        e.getEvangelismValue() -- 更新福音的总体治疗量
        e.getSpellInfo()       -- 获取技能信息
        e.updateCooldown()     -- 更新技能冷却
        e.playerinfo.GCD = 1.5 / (1 + GetHaste() / 100)
    end
    -- 目标变化
    if event == "PLAYER_TARGET_CHANGED" then
        e.getTargetInfo()
        e.getTargetAura()
    end
    if event == "UNIT_SPELLCAST_START" then
        if arg2 then e.getNameplateCastInfo(arg1, arg2, arg3) end
    end
    if event == "UNIT_SPELLCAST_STOP" then
        if arg2 then e.nameplate[arg2] = nil end
    end
    -- 移动状态
    if event == "PLAYER_STARTED_MOVING" then
        if player then player.isMoving = true end
    end
    if event == "PLAYER_STOPPED_MOVING" then
        if player then player.isMoving = false end
    end
    -- 战斗状态
    if event == "PLAYER_REGEN_DISABLED" then
        if player then player.isCombat = true end
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if player then player.isCombat = false end
    end

    if event == "UNIT_MAXPOWER" or event == "UNIT_POWER_UPDATE" then
        if arg1 == "player" then
            e.getPlayerManaPct()
            e.getHolyPower()
        end
    end
    -- 施法目标视野检查
    if event == "UNIT_SPELLCAST_SENT" and arg1 == "player" then
        e.lastCastTargetName = arg2
    end
    if event == "UI_ERROR_MESSAGE" and arg2 == "目标不在视野中" then
        for i = 1, 30 do
            local memberKey = "raid" .. i
            local member = r[memberKey]
            if member and member.name == e.lastCastTargetName then
                member.inSight = false
                if member.inSightTimer then
                    member.inSightTimer:Cancel()
                    member.inSightTimer = nil
                end
                member.inSightTimer = C_Timer.NewTimer(2, function()
                    member.inSight = true
                    member.inSightTimer = nil
                end)
                break
            end
        end
        e.lastCastTargetName = nil
    end
end
