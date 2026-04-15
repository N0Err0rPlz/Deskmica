# signal_bus.gd —— 全局信号总线：集中声明跨模块通信的 Godot Signals（TDD 4.1）
extends Node

# SignalBus 内所有 signal 均由外部模块 emit，编辑器会误报 UNUSED_SIGNAL，此处整体抑制。
@warning_ignore_start("unused_signal")

func _ready() -> void:
	print("[SignalBus] Initialized.")

# === 经济与交易 ===
signal credits_changed(new_amount: int)
signal car_purchased(car_id: String)
signal car_delivered(car_id: String, sell_price: int)
signal item_purchased(item_type: String, item_id: String)
signal car_added_to_garage(car_id: String)
signal offline_earnings_settled(amount: int, duration_seconds: int)

# === 改装流程 ===
signal kit_purchased(car_id: String, kit_id: String)
signal step_started(car_id: String, step_data: Resource)
signal step_completed(car_id: String, step_data: Resource)
signal kit_installed(car_id: String, kit_id: String)

# === 配件与套装 ===
signal parts_changed(car_id: String)
signal set_bonus_changed(car_id: String, set_id: String, active_tier: int)

# === 支线任务 ===
signal quest_available(quest_id: String)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal quest_expired(quest_id: String)

# === 抽卡与代币 ===
signal token_changed(token_id: String, new_amount: int)
signal gacha_pull_result(banner_id: String, results: Array)

# === 小游戏 ===
signal minigame_reward(reward_data: Dictionary)

# === 全局事件 ===
signal global_event_started(event_id: String)
signal global_event_ended(event_id: String)

# === 主理人状态 ===
signal player_state_changed(new_state: String)
signal action_points_changed(current: float, max_points: float)

# === 存档 ===
signal save_completed()
signal load_completed()

# === 专注模式 ===
signal focus_mode_changed(is_active: bool)
