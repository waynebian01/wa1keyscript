# -*- coding: utf-8 -*-
"""
纪律牧 GUI：开关键、实时状态、技能冷却、Group 1-5 信息
"""
import threading
import time
import ctypes
import tkinter as tk
from tkinter import ttk, font as tkfont

from utils import (
    select_keymap_for_class,
    get_unit_with_dispel_type,
    get_lowest_health_unit,
    get_lowest_health_unit_without_aura,
    count_units_without_aura_below_health,
    get_hotkey,
    send_key_to_wow,
    get_vk,
)
from GetPixels import get_info

# 检测开关按键的轮询间隔（秒）
TOGGLE_INTERVAL = 0.05
# 实际执行战斗逻辑的间隔（秒）
LOGIC_INTERVAL = 0.2
# GUI 刷新间隔（毫秒）
GUI_UPDATE_MS = 150

toggle_key_str = "XBUTTON2"
vk_toggle = get_vk(toggle_key_str)

# 线程共享状态
_state_lock = threading.Lock()
_logic_enabled = False
_state_dict = {}
_last_action = ""


def _run_discipline_loop():
    """后台运行的 discipline 主循环"""
    global _logic_enabled, _state_dict, _last_action
    prev_pressed = False
    last_logic_time = 0.0

    while True:
        current_pressed = (ctypes.windll.user32.GetAsyncKeyState(vk_toggle) & 0x8000) != 0
        if current_pressed and not prev_pressed:
            with _state_lock:
                _logic_enabled = not _logic_enabled
            _last_action = "逻辑 " + ("开启" if _logic_enabled else "关闭")
        prev_pressed = current_pressed

        now = time.time()
        if not _logic_enabled:
            time.sleep(TOGGLE_INTERVAL)
            continue

        if now - last_logic_time < LOGIC_INTERVAL:
            time.sleep(TOGGLE_INTERVAL)
            continue
        last_logic_time = now

        state_dict = get_info()
        if not state_dict:
            state_dict = {}
        else:
            select_keymap_for_class(state_dict.get("职业"))

        with _state_lock:
            _state_dict = state_dict

        if not state_dict.get("有效性"):
            time.sleep(TOGGLE_INTERVAL)
            continue

        spells = state_dict.get("spells") or {}
        assistant_value = state_dict.get("一键辅助")
        target_valid = state_dict.get("目标有效")
        combat = state_dict.get("战斗")
        moving = state_dict.get("移动")
        dispel_unit, dispel_data = get_unit_with_dispel_type(state_dict, 1)
        lowest_unit, lowest_pct = get_lowest_health_unit(state_dict)
        no_atonement_unit, no_atonement_pct = get_lowest_health_unit_without_aura(
            state_dict, "救赎"
        )
        no_shield_lowest_unit, no_shield_lowest_pct = get_lowest_health_unit_without_aura(
            state_dict, "真言术：盾", 100
        )
        no_shield_unit, no_shield_pct = get_lowest_health_unit_without_aura(
            state_dict, "真言术：盾", 101
        )
        no_atonement_count_90 = count_units_without_aura_below_health(
            state_dict, "救赎", 90
        )

        action_hotkey = None
        if state_dict.get("引导") == 1:
            _last_action = "在引导,不执行任何操作"
        elif spells.get("纯净术") == 0 and dispel_unit is not None:
            _last_action = f"施放 纯净术 on {dispel_unit}"
            action_hotkey = get_hotkey(int(dispel_unit), "纯净术")
        elif (
            spells.get("真言术：耀") == 0
            and state_dict.get("施法") == 0
            and no_atonement_count_90 >= 3
        ):
            _last_action = "施放 真言术：耀"
            action_hotkey = get_hotkey(0, "真言术：耀")
        elif (
            spells.get("福音") == 0
            and spells.get("真言术：耀") > 3
            and no_atonement_count_90 >= 3
        ):
            _last_action = "施放 福音"
            action_hotkey = get_hotkey(0, "福音")
        elif target_valid and combat and assistant_value == 4:
            _last_action = "施放 暗言术：痛"
            action_hotkey = get_hotkey(0, "暗言术：痛")
        elif (
            state_dict.get("圣光涌动")
            and no_atonement_unit is not None
            and no_atonement_pct is not None
            and no_atonement_pct < 90
        ):
            _last_action = f"施放 快速治疗 on {no_atonement_unit}"
            action_hotkey = get_hotkey(int(no_atonement_unit), "快速治疗")
        elif spells.get("真言术：盾") == 0:
            if no_atonement_unit is not None:
                _last_action = f"施放 真言术：盾 on {no_atonement_unit}"
                action_hotkey = get_hotkey(int(no_atonement_unit), "真言术：盾")
            elif no_shield_unit is not None:
                _last_action = f"施放 真言术：盾 on {no_shield_unit}"
                action_hotkey = get_hotkey(int(no_shield_unit), "真言术：盾")
            elif state_dict.get("虚空之盾"):
                _last_action = "施放 真言术：盾"
                action_hotkey = get_hotkey(2, "真言术：盾")
        elif (
            spells.get("真言术：耀") == 0
            and state_dict.get("施法") == 0
            and no_atonement_count_90 >= 1
        ):
            _last_action = "施放 真言术：耀"
            action_hotkey = get_hotkey(0, "真言术：耀")
        elif (
            spells.get("福音") == 0
            and spells.get("真言术：耀") > 3
            and no_atonement_count_90 >= 1
        ):
            _last_action = "施放 福音"
            action_hotkey = get_hotkey(0, "福音")
        elif (
            state_dict.get("圣光涌动")
            and lowest_unit is not None
            and lowest_pct is not None
            and lowest_pct < 90
        ):
            _last_action = f"施放 快速治疗 on {lowest_unit}"
            action_hotkey = get_hotkey(int(lowest_unit), "快速治疗")
        elif (
            lowest_unit is not None
            and lowest_pct is not None
            and lowest_pct < 80
            and not state_dict.get("虚空之盾")
        ):
            _last_action = f"施放 苦修 on {lowest_unit} pct {lowest_pct}"
            action_hotkey = get_hotkey(int(lowest_unit), "苦修")
        elif target_valid and combat:
            if spells.get("暗言术：灭") == 0:
                _last_action = "施放 暗言术：灭"
                action_hotkey = get_hotkey(0, "暗言术：灭")
            elif not moving and spells.get("心灵震爆") == 0:
                _last_action = "施放 心灵震爆"
                action_hotkey = get_hotkey(0, "心灵震爆")
            elif spells.get("苦修") == 0 and not state_dict.get("虚空之盾"):
                _last_action = "施放 苦修"
                action_hotkey = get_hotkey(0, "苦修")
            elif not moving:
                _last_action = "施放 惩击"
                action_hotkey = get_hotkey(0, "惩击")
        elif assistant_value == 5:
            _last_action = "施放 真言术：韧"
            action_hotkey = get_hotkey(0, "真言术：韧")

        if action_hotkey:
            send_key_to_wow(action_hotkey)

        time.sleep(TOGGLE_INTERVAL)


def create_gui():
    root = tk.Tk()
    root.title("戒律牧 Skippy")
    root.geometry("580x640")
    root.resizable(True, True)
    root.attributes("-topmost", True)

    # 样式
    style = ttk.Style()
    style.configure("Title.TLabel", font=("Microsoft YaHei", 11, "bold"))
    style.configure("Status.TLabel", font=("Consolas", 9))
    style.configure("Group.TLabel", font=("Consolas", 9))

    main_frame = ttk.Frame(root, padding="10 10 10 10")
    main_frame.pack(fill=tk.BOTH, expand=True)

    # ---- 1. 开关区域 ----
    toggle_frame = ttk.LabelFrame(main_frame, text="开关", padding="5 5 5 5")
    toggle_frame.pack(fill=tk.X, pady=(0, 5))

    toggle_var = tk.BooleanVar(value=False)

    def on_toggle():
        with _state_lock:
            global _logic_enabled
            _logic_enabled = toggle_var.get()
        status_text = "开启" if _logic_enabled else "关闭"
        status_label.config(text=f"状态: {status_text}")

    ttk.Checkbutton(
        toggle_frame,
        text="逻辑开启 (也可用 X2 切换)",
        variable=toggle_var,
        command=on_toggle,
    ).pack(side=tk.LEFT, padx=5, pady=3)

    def sync_toggle_from_logic():
        with _state_lock:
            v = _logic_enabled
        if toggle_var.get() != v:
            toggle_var.set(v)
            status_label.config(text=f"状态: {'开启' if v else '关闭'}")

    # ---- 2. 状态区域 ----
    status_frame = ttk.LabelFrame(main_frame, text="实时状态", padding="5 5 5 5")
    status_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 5))

    status_label = ttk.Label(
        status_frame, text="状态: 关闭", style="Status.TLabel"
    )
    status_label.pack(anchor=tk.W)

    status_grid = ttk.Frame(status_frame)
    status_grid.pack(fill=tk.X, pady=2)

    status_vars = {}
    status_keys = [
        "有效性",
        "战斗",
        "移动",
        "施法",
        "引导",
        "虚空之盾",
        "圣光涌动",
        "目标有效",
        "一键辅助",
    ]
    for i, k in enumerate(status_keys):
        row, col = i // 3, (i % 3) * 2
        ttk.Label(status_grid, text=k + ":").grid(row=row, column=col, sticky=tk.W, padx=(0, 2))
        lbl = ttk.Label(status_grid, text="-", style="Status.TLabel", width=6)
        lbl.grid(row=row, column=col + 1, sticky=tk.W)
        status_vars[k] = lbl

    action_label = ttk.Label(status_frame, text="最近动作: -", style="Status.TLabel")
    action_label.pack(anchor=tk.W, pady=(5, 0))

    # ---- 3. 技能冷却 ----
    spells_frame = ttk.LabelFrame(main_frame, text="技能冷却", padding="5 5 5 5")
    spells_frame.pack(fill=tk.X, pady=(0, 5))

    spells_grid = ttk.Frame(spells_frame)
    spells_grid.pack(fill=tk.X)

    spell_keys = [
        "真言术：盾",
        "苦修",
        "真言术：耀",
        "纯净术",
        "绝望祷言",
        "心灵震爆",
        "福音",
        "暗言术：灭",
    ]
    spell_vars = {}
    for i, name in enumerate(spell_keys):
        row, col = i // 4, (i % 4) * 2
        ttk.Label(spells_grid, text=name + ":").grid(
            row=row, column=col, sticky=tk.W, padx=(0, 2)
        )
        lbl = ttk.Label(spells_grid, text="-", style="Status.TLabel", width=4)
        lbl.grid(row=row, column=col + 1, sticky=tk.W)
        spell_vars[name] = lbl

    # ---- 4. Group 1-5 ----
    group_frame = ttk.LabelFrame(main_frame, text="Group 1-5", padding="5 5 5 5")
    group_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 5))

    # 表头
    headers = ["", "生命值", "职责", "驱散", "救赎", "盾"]
    for c, h in enumerate(headers):
        ttk.Label(group_frame, text=h, style="Title.TLabel").grid(
            row=0, column=c, padx=5, pady=2, sticky=tk.W
        )

    group_vars = {}
    for i in range(1, 6):
        row = i
        key = str(i)
        ttk.Label(group_frame, text=f"Unit {i}").grid(
            row=row, column=0, padx=5, pady=2, sticky=tk.W
        )
        group_vars[key] = {}
        for j, field in enumerate(["生命值", "职责", "驱散", "救赎", "真言术：盾"]):
            lbl = ttk.Label(group_frame, text="-", style="Group.TLabel", width=6)
            lbl.grid(row=row, column=j + 1, padx=5, pady=2, sticky=tk.W)
            group_vars[key][field] = lbl

    def update_display():
        sync_toggle_from_logic()
        with _state_lock:
            sd = dict(_state_dict)
            enabled = _logic_enabled

        status_label.config(text=f"状态: {'开启' if enabled else '关闭'}")

        for k in status_keys:
            v = sd.get(k)
            if v is None:
                status_vars[k].config(text="-")
            else:
                status_vars[k].config(text=str(v))

        action_label.config(text=f"最近动作: {_last_action}")

        spells = sd.get("spells") or {}
        for name in spell_keys:
            v = spells.get(name)
            if v is None:
                spell_vars[name].config(text="-")
            else:
                spell_vars[name].config(text=str(v))

        group = sd.get("group") or {}
        for i in range(1, 6):
            key = str(i)
            data = group.get(key) or {}
            for field in ["生命值", "职责", "驱散", "救赎", "真言术：盾"]:
                v = data.get(field)
                lbl = group_vars[key][field]
                if v is None:
                    lbl.config(text="-")
                else:
                    lbl.config(text=str(v))

        root.after(GUI_UPDATE_MS, update_display)

    root.after(0, update_display)

    # 启动后台逻辑线程
    def start_worker():
        try:
            _run_discipline_loop()
        except Exception as e:
            print("Worker error:", e)

    worker = threading.Thread(target=start_worker, daemon=True)
    worker.start()

    root.mainloop()


if __name__ == "__main__":
    create_gui()
