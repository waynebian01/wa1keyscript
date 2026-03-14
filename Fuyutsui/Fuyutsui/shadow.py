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
        # 逻辑关闭时只检测开关按键
        if not logic_enabled:
            time.sleep(TOGGLE_INTERVAL)
            continue

        # 逻辑开启时，只有间隔达到 LOGIC_INTERVAL 才执行一次战斗逻辑
        if now - last_logic_time < LOGIC_INTERVAL:
            time.sleep(TOGGLE_INTERVAL)
            continue
        last_logic_time = now

        # 扫描并构建 state_dict（与 discipline 相同的 get_info 流程）
        state_dict = get_info()
        if not state_dict:
            state_dict = {}
        else:
            select_keymap_for_class(state_dict.get("职业"))

        # 1. 有效性为 true 才继续，否则本轮跳过
        if not state_dict.get("有效性"):
            time.sleep(TOGGLE_INTERVAL)
            continue

        # 预先计算常用信息
        spells = state_dict.get("spells") or {}
        assistant_value = state_dict.get("一键辅助")
        target_valid = state_dict.get("目标有效")
        combat = state_dict.get("战斗")
        moving = state_dict.get("移动")
        valid = state_dict.get("有效性")
        action_hotkey = None
        # 如果在引导,则什么也不做
        if not valid:
            print("无效,不执行任何操作")
            action_hotkey = None
        elif state_dict.get("引导") == 1:
            print("引导,不执行任何操作")
            action_hotkey = None
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

        # 本轮逻辑已执行完，短暂休眠再继续检测开关
        time.sleep(TOGGLE_INTERVAL)
except KeyboardInterrupt:
    print("\n已停止")
