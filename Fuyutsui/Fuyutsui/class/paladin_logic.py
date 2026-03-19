# -*- coding: utf-8 -*-
"""圣骑士职业的逻辑决策（神圣）。"""

from utils import get_hotkey, get_unit_with_dispel_type, get_lowest_health_unit, get_lowest_health_unit_without_aura, count_units_below_health


def run_paladin_logic(state_dict, spec_name):
    spells = state_dict.get("spells") or {}
    health_value = state_dict.get("生命值")
    energy_value = state_dict.get("能量值")
    target_valid = state_dict.get("目标有效")
    combat = state_dict.get("战斗")
    casting = state_dict.get("施法")
    channeling = state_dict.get("引导")

    action_hotkey = None
    current_step = "无匹配技能"
    unit_info = {}

    if spec_name != "神圣":
        return action_hotkey, current_step, unit_info

    dispel_unit_magic, _ = get_unit_with_dispel_type(state_dict, 1)
    dispel_unit_disease, _ = get_unit_with_dispel_type(state_dict, 3)
    dispel_unit_poison, _ = get_unit_with_dispel_type(state_dict, 4)
    lowest_unit, lowest_unit_pct = get_lowest_health_unit(state_dict, 100)
    no_eternal_lowest_unit, no_eternal_lowest_unit_pct = get_lowest_health_unit_without_aura(state_dict, "永恒之火", health_threshold=101)
    count_units_below_health_90 = count_units_below_health(state_dict, 90)
    holy_power = state_dict.get("神圣能量") or 0

    if channeling > 0:
        current_step = "在引导,不执行任何操作"
        return None, current_step, unit_info

    if spells.get("清洁术") == 0 and dispel_unit_magic is not None:
        current_step = f"施放 清洁术 on {dispel_unit_magic}"
        action_hotkey = get_hotkey(int(dispel_unit_magic), "清洁术")
    elif spells.get("清洁术") == 0 and dispel_unit_disease is not None:
        current_step = f"施放 清洁术 on {dispel_unit_disease}"
        action_hotkey = get_hotkey(int(dispel_unit_disease), "清洁术")
    elif spells.get("清洁术") == 0 and dispel_unit_poison is not None:
        current_step = f"施放 清洁术 on {dispel_unit_poison}"
        action_hotkey = get_hotkey(int(dispel_unit_poison), "清洁术")
    elif lowest_unit is not None and lowest_unit_pct is not None and lowest_unit_pct <= 95:
        if (holy_power == 5 or state_dict.get("神圣意志") > 0) and count_units_below_health_90 > 5:
            current_step = "施放 黎明之光"
            action_hotkey = get_hotkey(0, "黎明之光")
        elif (holy_power == 5 or state_dict.get("神圣意志") > 0) and count_units_below_health_90 <= 5:
            current_step = f"施放 荣耀圣令 on {lowest_unit}"
            action_hotkey = get_hotkey(int(lowest_unit), "荣耀圣令")
        elif spells.get("震击充能") <= 1 and state_dict.get("圣光灌注") == 0:
            current_step = f"施放 神圣震击 on {lowest_unit}"
            action_hotkey = get_hotkey(int(lowest_unit), "神圣震击")
        elif casting == 0 and lowest_unit_pct < 70 and state_dict.get("神性之手") > 0:
            current_step = f"施放 圣光术 on {lowest_unit}"
            action_hotkey = get_hotkey(int(lowest_unit), "圣光术")
        elif (holy_power > 3 or state_dict.get("神圣意志") > 0) and lowest_unit_pct <= 60:
            current_step = f"施放 荣耀圣令 on {lowest_unit}"
            action_hotkey = get_hotkey(int(lowest_unit), "荣耀圣令")
        elif holy_power > 3 and no_eternal_lowest_unit is not None and no_eternal_lowest_unit_pct is not None and no_eternal_lowest_unit_pct < 80:
            current_step = f"施放 荣耀圣令 on {no_eternal_lowest_unit}"
            action_hotkey = get_hotkey(int(no_eternal_lowest_unit), "荣耀圣令")
        elif spells.get("圣洁鸣钟") == 0 and holy_power <= 2 and count_units_below_health_90 >= 3:
            current_step = "施放 圣洁鸣钟"
            action_hotkey = get_hotkey(0, "圣洁鸣钟")
        elif casting == 0 and state_dict.get("圣光灌注") > 0 and lowest_unit_pct < 80:
            current_step = f"施放 圣光闪现 on {lowest_unit}"
            action_hotkey = get_hotkey(int(lowest_unit), "圣光闪现")
        elif spells.get("神圣震击") <= 1 and state_dict.get("圣光灌注") == 0:
            current_step = f"施放 神圣震击 on {lowest_unit}"
            action_hotkey = get_hotkey(int(lowest_unit), "神圣震击")
        elif casting == 0 and lowest_unit_pct < 50 and energy_value >= 50:
            current_step = f"施放 圣光术 on {lowest_unit}"
            action_hotkey = get_hotkey(int(lowest_unit), "圣光术")
        elif casting == 0:
            current_step = f"施放 圣光闪现 on {lowest_unit}"
            action_hotkey = get_hotkey(int(lowest_unit), "圣光闪现")
        else:
            current_step = "无匹配技能"
    elif combat and target_valid:
        if holy_power == 5 or state_dict.get("神圣意志") > 0:
            current_step = "施放 正义盾击"
            action_hotkey = get_hotkey(0, "正义盾击")
        elif spells.get("审判") <= 1:
            current_step = "施放 审判"
            action_hotkey = get_hotkey(0, "审判")
        elif spells.get("神圣震击") == 0:
            current_step = "施放 神圣震击"
            action_hotkey = get_hotkey(0, "神圣震击")
    else:
        current_step = "无匹配技能"

    return action_hotkey, current_step, unit_info
