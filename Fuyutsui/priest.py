"""
牧师通用脚本：根据当前专精（戒律 / 暗影）自动选择并执行对应逻辑。
"""
import time
import ctypes
from utils import *
from GetPixels import get_info

# 检测开关按键的轮询间隔（秒）
TOGGLE_INTERVAL = 0.05
# 实际执行战斗逻辑的间隔（秒）
LOGIC_INTERVAL = 0.2

# 控制键默认 XBUTTON2，按该键切换逻辑开关
toggle_key_str = "XBUTTON2"
vk_toggle = get_vk(toggle_key_str)

logic_enabled = False
prev_pressed = False
last_logic_time = 0.0

try:
    while True:
        # 检测控制键：从“未按下”变为“按下”时切换开关（每 TOGGLE_INTERVAL 检测一次）
        current_pressed = (ctypes.windll.user32.GetAsyncKeyState(vk_toggle) & 0x8000) != 0
        if current_pressed and not prev_pressed:
            logic_enabled = not logic_enabled
            print("逻辑", "开启" if logic_enabled else "关闭")
        prev_pressed = current_pressed

        now = time.time()
        if not logic_enabled:
            time.sleep(TOGGLE_INTERVAL)
            continue

        if now - last_logic_time < LOGIC_INTERVAL:
            time.sleep(TOGGLE_INTERVAL)
            continue
        last_logic_time = now

        # 扫描并构建 state_dict
        state_dict = get_info()
        spec_name = None
        if state_dict:
            class_id = state_dict.get("职业")
            spec_id = state_dict.get("专精")
            config = load_config()
            _, spec_name = get_class_and_spec_name(config, class_id, spec_id)
            select_keymap_for_class(class_id)
        else:
            state_dict = {}

        if not state_dict.get("有效性"):
            time.sleep(TOGGLE_INTERVAL)
            continue

        spells = state_dict.get("spells") or {}
        assistant_value = state_dict.get("一键辅助")
        target_valid = state_dict.get("目标有效")
        combat = state_dict.get("战斗")
        moving = state_dict.get("移动")
        action_hotkey = None

        if spec_name == "戒律":
            # ---------- 戒律专精逻辑 ----------
            dispel_unit, dispel_data = get_unit_with_dispel_type(state_dict, 1)  # 1=魔法
            lowest_unit, lowest_pct = get_lowest_health_unit(state_dict)
            no_atonement_unit, no_atonement_pct = get_lowest_health_unit_without_aura(state_dict, "救赎")
            no_shield_lowest_unit, no_shield_lowest_pct = get_lowest_health_unit_without_aura(state_dict, "真言术：盾", 100)
            no_shield_unit, no_shield_pct = get_lowest_health_unit_without_aura(state_dict, "真言术：盾", 101)
            no_atonement_count_90 = count_units_without_aura_below_health(state_dict, "救赎", 90)

            if state_dict.get("引导") == 1:
                print("在引导,不执行任何操作")
            elif spells.get("纯净术") == 0 and dispel_unit is not None:
                print("施放 纯净术 on", dispel_unit)
                action_hotkey = get_hotkey(int(dispel_unit), "纯净术")
            elif spells.get("真言术：耀") == 0 and state_dict.get("施法") == 0 and no_atonement_count_90 >= 3:
                print("施放 真言术：耀")
                action_hotkey = get_hotkey(0, "真言术：耀")
            elif spells.get("福音") == 0 and spells.get("真言术：耀") > 3 and no_atonement_count_90 >= 3:
                print("施放 福音")
                action_hotkey = get_hotkey(0, "福音")
            elif target_valid and combat and assistant_value == 4:
                print("施放 暗言术：痛")
                action_hotkey = get_hotkey(0, "暗言术：痛")
            elif state_dict.get("圣光涌动") and no_atonement_unit is not None and no_atonement_pct is not None and no_atonement_pct < 90:
                print("施放 快速治疗 on", no_atonement_unit)
                action_hotkey = get_hotkey(int(no_atonement_unit), "快速治疗")
            elif spells.get("真言术：盾") == 0:
                if no_atonement_unit is not None:
                    print("施放 真言术：盾 on", no_atonement_unit)
                    action_hotkey = get_hotkey(int(no_atonement_unit), "真言术：盾")
                elif no_shield_unit is not None:
                    print("施放 真言术：盾 on", no_shield_unit)
                    action_hotkey = get_hotkey(int(no_shield_unit), "真言术：盾")
                elif state_dict.get("虚空之盾"):
                    print("施放 真言术：盾")
                    action_hotkey = get_hotkey(2, "真言术：盾")
            elif spells.get("真言术：耀") == 0 and state_dict.get("施法") == 0 and no_atonement_count_90 >= 1:
                print("施放 真言术：耀")
                action_hotkey = get_hotkey(0, "真言术：耀")
            elif spells.get("福音") == 0 and spells.get("真言术：耀") > 3 and no_atonement_count_90 >= 1:
                print("施放 福音")
                action_hotkey = get_hotkey(0, "福音")
            elif state_dict.get("圣光涌动") and lowest_unit is not None and lowest_pct is not None and lowest_pct < 90:
                print("施放 快速治疗 on", lowest_unit)
                action_hotkey = get_hotkey(int(lowest_unit), "快速治疗")
            elif lowest_unit is not None and lowest_pct is not None and lowest_pct < 80 and not state_dict.get("虚空之盾"):
                print("施放 苦修 on", lowest_unit, "pct", lowest_pct)
                action_hotkey = get_hotkey(int(lowest_unit), "苦修")
            elif target_valid and combat:
                if spells.get("暗言术：灭") == 0:
                    print("施放 暗言术：灭")
                    action_hotkey = get_hotkey(0, "暗言术：灭")
                elif not moving and spells.get("心灵震爆") == 0:
                    print("施放 心灵震爆")
                    action_hotkey = get_hotkey(0, "心灵震爆")
                elif spells.get("苦修") == 0 and not state_dict.get("虚空之盾"):
                    print("施放 苦修")
                    action_hotkey = get_hotkey(0, "苦修")
                elif not moving:
                    print("施放 惩击")
                    action_hotkey = get_hotkey(0, "惩击")
            elif assistant_value == 5:
                print("施放 真言术：韧")
                action_hotkey = get_hotkey(0, "真言术：韧")

        elif spec_name == "暗影":
            # ---------- 暗影专精逻辑 ----------
            if state_dict.get("引导") == 1:
                print("引导,不执行任何操作")
            elif assistant_value == 7:
                print("施放 真言术：韧")
                action_hotkey = get_hotkey(0, "真言术：韧")
            elif assistant_value == 3:
                print("施放 暗影形态")
                action_hotkey = get_hotkey(0, "暗影形态")
            elif combat and target_valid:
                if assistant_value == 1:
                    print("施放 吸血鬼之触")
                    action_hotkey = get_hotkey(0, "吸血鬼之触")
                elif assistant_value == 2:
                    print("施放 心灵震爆")
                    action_hotkey = get_hotkey(0, "心灵震爆")
                elif assistant_value == 4:
                    print("施放 暗言术：灭")
                    action_hotkey = get_hotkey(0, "暗言术：灭")
                elif assistant_value == 5:
                    print("施放 暗言术：痛")
                    action_hotkey = get_hotkey(0, "暗言术：痛")
                elif assistant_value == 6:
                    print("施放 暗言术：癫")
                    action_hotkey = get_hotkey(0, "暗言术：癫")
                elif assistant_value == 8:
                    print("施放 精神鞭笞")
                    action_hotkey = get_hotkey(0, "精神鞭笞")
                elif assistant_value == 9:
                    print("施放 虚空形态")
                    action_hotkey = get_hotkey(0, "虚空形态")
                elif assistant_value == 10:
                    print("施放 虚空洪流")
                    action_hotkey = get_hotkey(0, "虚空洪流")
                elif assistant_value == 11:
                    print("施放 触须猛击")
                    action_hotkey = get_hotkey(0, "触须猛击")
                elif assistant_value == 12:
                    print("施放 虚空冲击")
                    action_hotkey = get_hotkey(0, "虚空冲击")
                elif assistant_value == 13:
                    print("施放 虚空齐射")
                    action_hotkey = get_hotkey(0, "虚空齐射")

        if action_hotkey:
            print("send hotkey:", action_hotkey)
            send_key_to_wow(action_hotkey)

        time.sleep(TOGGLE_INTERVAL)
except KeyboardInterrupt:
    print("\n已停止")
