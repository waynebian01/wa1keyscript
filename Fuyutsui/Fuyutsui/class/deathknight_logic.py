# -*- coding: utf-8 -*-
"""死亡骑士职业的逻辑决策（鲜血 / 邪恶）。"""

from utils import get_hotkey


def run_deathknight_logic(state_dict, spec_name):
    spells = state_dict.get("spells") or {}
    health_value = state_dict.get("生命值")
    energy_value = state_dict.get("能量值")
    assistant_value = state_dict.get("一键辅助")
    target_valid = state_dict.get("目标有效")
    combat = state_dict.get("战斗")
    channeling = state_dict.get("引导")

    action_hotkey = None
    current_step = "无匹配技能"
    unit_info = {}

    if spec_name == "鲜血":
        if channeling > 0:
            current_step = "在引导,不执行任何操作"
            return None, current_step, unit_info

        if combat and target_valid:
            action_map = {
                1: ("心脏打击", "心脏打击"),
                2: ("枯萎凋零", "枯萎凋零"),
                3: ("死神的抚摸", "死神的抚摸"),
                4: ("灵界打击", "灵界打击"),
                5: ("符文刃舞", "符文刃舞"),
                6: ("精髓分裂", "精髓分裂"),
                7: ("血液沸腾", "血液沸腾"),
                8: ("吸血鬼打击", "心脏打击"),
            }
            tup = action_map.get(assistant_value)
            if tup:
                current_step = f"施放 {tup[0]}"
                action_hotkey = get_hotkey(0, tup[1])
            else:
                current_step = "战斗中-无匹配技能"
        else:
            current_step = "非战斗状态,不执行任何操作"

    elif spec_name == "邪恶":
        if channeling > 0:
            current_step = "在引导,不执行任何操作"
            return None, current_step, unit_info
        if not combat:
            current_step = "非战斗状态,不执行任何操作"
            return None, current_step, unit_info
        if not target_valid:
            current_step = "目标无效,不执行任何操作"
            return None, current_step, unit_info

        if assistant_value == 1:
            current_step = "施放 亡者复生"
            action_hotkey = get_hotkey(0, "亡者复生")
        elif state_dict.get("黑暗援助") == 1 and health_value <= 80:
            current_step = "施放 灵界打击"
            action_hotkey = get_hotkey(0, "灵界打击")
        elif health_value <= 30 and energy_value >= 40:
            current_step = "施放 灵界打击"
            action_hotkey = get_hotkey(0, "灵界打击")
        elif assistant_value == 6:
            current_step = "施放 爆发"
            action_hotkey = get_hotkey(0, "爆发")
        elif spells.get("黑暗突变") == 0:
            current_step = "施放 黑暗突变"
            action_hotkey = get_hotkey(0, "黑暗突变")
        elif spells.get("腐化") == 0 and spells.get("腐化2") < 2:
            current_step = "施放 腐化"
            action_hotkey = get_hotkey(0, "腐化")
        elif spells.get("灵魂收割") == 0 and state_dict.get("目标生命值") < 20:
            current_step = "施放 灵魂收割"
            action_hotkey = get_hotkey(0, "灵魂收割")
        elif spells.get("腐化") == 0 and spells.get("黑暗突变") > 15:
            current_step = "施放 腐化2"
            action_hotkey = get_hotkey(0, "腐化")
        elif state_dict.get("脓疮毒镰") == 1 and state_dict.get("符文") >= 2:
            current_step = "施放 脓疮打击"
            action_hotkey = get_hotkey(0, "脓疮打击")
        elif ((state_dict.get("末日突降") == 1 and energy_value >= 15) or energy_value >= 80) and state_dict.get("敌人人数") >= 3:
            current_step = "施放 扩散"
            action_hotkey = get_hotkey(0, "扩散")
        elif ((state_dict.get("末日突降") == 1 and energy_value >= 15) or energy_value >= 80) and state_dict.get("敌人人数") < 3:
            current_step = "施放 凋零缠绕"
            action_hotkey = get_hotkey(0, "凋零缠绕")
        elif state_dict.get("禁断知识") == 1 and energy_value >= 30 and state_dict.get("敌人人数") < 3:
            current_step = "施放 凋零缠绕"
            action_hotkey = get_hotkey(0, "凋零缠绕")
        elif state_dict.get("禁断知识") == 1 and energy_value >= 30 and state_dict.get("敌人人数") >= 3:
            current_step = "施放 扩散"
            action_hotkey = get_hotkey(0, "扩散")
        elif state_dict.get("次级食尸鬼") == 0 and state_dict.get("符文") >= 2:
            current_step = "施放 脓疮打击"
            action_hotkey = get_hotkey(0, "脓疮打击")
        elif state_dict.get("次级食尸鬼") > 0 and state_dict.get("符文") > 0:
            current_step = "施放 天灾打击"
            action_hotkey = get_hotkey(0, "天灾打击")
        elif energy_value >= 30:
            current_step = "施放 凋零缠绕"
            action_hotkey = get_hotkey(0, "凋零缠绕")
        else:
            current_step = "战斗中-无匹配技能"

    return action_hotkey, current_step, unit_info
