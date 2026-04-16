# save_manager.gd —— 存档读写系统：JSON 序列化、自动存档与退出前强制存档（TDD 第 9 章）
extends Node

const SAVE_PATH: String = "user://save_data.json"
const SAVE_VERSION: String = "1.0"
const AUTO_SAVE_INTERVAL: float = 180.0  # 3 分钟

var _auto_save_timer: Timer
var _save_data: Dictionary = {}

func _ready() -> void:
	_init_auto_save_timer()
	load_game()
	print("[SaveManager] Initialized. Save path: %s" % SAVE_PATH)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()  # 退出前强制存档
		get_tree().quit()

# === 公开 API ===

func save_game() -> void:
	_save_data["save_version"] = SAVE_VERSION
	_save_data["last_save_timestamp"] = int(Time.get_unix_time_from_system())
	# Phase 2+: 各管理器将自己的数据写入 _save_data
	_save_data["player"] = _collect_player_data()
	_save_data["tokens"] = _collect_token_data()
	_save_data["garage"] = _collect_garage_data()
	_save_data["active_task_queue"] = _collect_task_queue_data()
	_save_data["settings"] = _collect_settings_data()

	var json_string: String = JSON.stringify(_save_data, "  ")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		SignalBus.save_completed.emit()
		print("[SaveManager] Game saved.")
	else:
		push_warning("[SaveManager] Failed to open save file for writing: %s" % SAVE_PATH)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] No save file found. Starting fresh.")
		_save_data = _get_default_save_data()
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string: String = file.get_as_text()
		file.close()
		var json: JSON = JSON.new()
		var parse_result: int = json.parse(json_string)
		if parse_result == OK:
			_save_data = json.data
			_apply_loaded_data()
			SignalBus.load_completed.emit()
			print("[SaveManager] Game loaded. Version: %s" % _save_data.get("save_version", "unknown"))
		else:
			push_warning("[SaveManager] Failed to parse save file. Starting fresh.")
			_save_data = _get_default_save_data()

func get_save_data() -> Dictionary:
	return _save_data

func trigger_event_save() -> void:
	save_game()  # 关键事件时调用

# === 内部方法 ===

func _init_auto_save_timer() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save)
	add_child(_auto_save_timer)

func _on_auto_save() -> void:
	save_game()
	print("[SaveManager] Auto-save triggered.")

func _get_default_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"last_save_timestamp": 0,
		"player": {
			"total_credits": 0,
			"action_points_current": 100.0,
			"player_state": "joker",
			"unlocked_achievements": []
		},
		"tokens": {
			"normal_token": 0,
			"premium_token": 0
		},
		"garage": [],
		"active_task_queue": [],
		"inventory": {
			"uninstalled_parts": [],
			"unidentified_scraps": []
		},
		"quests": {
			"active_urgent_bounties": [],
			"active_restorations": []
		},
		"global_events": {
			"active_event_ids": []
		},
		"gacha_pity": {
			"normal_banner_consecutive_misses": 0,
			"premium_banner_consecutive_misses": 0
		},
		"global_collection_achievements": [],
		"settings": {
			"focus_mode": false,
			"window_position": { "x": 0, "y": 0 },
			"window_scale": 2,
			"sfx_volume": 0.7
		}
	}

func _collect_player_data() -> Dictionary:
	return {
		"total_credits": EconomyManager.get_credits(),
		"action_points_current": 100.0,  # Phase 2: 从 ActionPointPool 读取
		"player_state": "joker",         # Phase 2: 从 PlayerFSM 读取
		"unlocked_achievements": []      # Phase 2
	}

func _collect_token_data() -> Dictionary:
	# 架构豁免：SaveManager 作为可信基础设施，直接读取 TokenManager 私有状态以便序列化。
	return TokenManager._tokens.duplicate()

# 架构豁免：SaveManager 直接读取 EconomyManager._garage_car_ids 组装存档结构。
func _collect_garage_data() -> Array:
	var garage: Array = []
	for car_id in EconomyManager._garage_car_ids:
		garage.append({
			"car_id": car_id,
			"installed_kit_ids": [],  # Phase 2 暂无配件跟踪，预留字段
		})
	return garage


func _collect_task_queue_data() -> Array:
	return TaskManager.export_queue_snapshot()


func _collect_settings_data() -> Dictionary:
	return _save_data.get("settings", _get_default_save_data()["settings"])

# 架构豁免：SaveManager 作为可信基础设施，直接写回 Manager 私有状态，避免为回灌暴露公共 setter。
# Godot 的 JSON 会把 int 退化为 float，此处统一 int() 强转还原整数语义。
func _apply_loaded_data() -> void:
	var player_data: Dictionary = _save_data.get("player", {})
	EconomyManager._credits = int(player_data.get("total_credits", 0))

	var token_data: Dictionary = _save_data.get("tokens", {})
	for token_id in token_data:
		TokenManager._tokens[token_id] = int(token_data[token_id])

	print("[SaveManager] Data applied to managers.")
