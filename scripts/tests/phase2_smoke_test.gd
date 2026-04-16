# phase2_smoke_test.gd — Phase 2 核心循环闭环断言脚本
extends Node

const INITIAL_CREDITS: int = 1000
const CAR_ID: String = "test_car_01"
const KIT_ID: String = "test_kit_01"

var _step_started_count: int = 0
var _step_completed_count: int = 0
var _kit_installed_hit: bool = false


func _ready() -> void:
	SignalBus.step_started.connect(func(_c: String, _s: Resource) -> void: _step_started_count += 1)
	SignalBus.step_completed.connect(func(_c: String, _s: Resource) -> void: _step_completed_count += 1)
	SignalBus.kit_installed.connect(func(_c: String, _k: String) -> void: _kit_installed_hit = true)

	EconomyManager.add_credits(INITIAL_CREDITS)

	# 1) 买车
	assert(ShopSystem.try_buy_car(CAR_ID), "buy car failed")

	# 2) 买套件
	assert(ShopSystem.try_buy_kit(CAR_ID, KIT_ID), "buy kit failed")
	assert(TaskManager.is_busy(CAR_ID), "task not queued")

	# 3) 手动模拟 10 秒推进（跳过 _process，保证确定性）
	var credits_before: int = EconomyManager.get_credits()
	for i in range(10):
		TaskManager.update(1.0)
		EconomyManager.update(1.0)

	# 4) 断言：套件已装完
	assert(_step_started_count == 2, "step_started count mismatch: %d" % _step_started_count)
	assert(_step_completed_count == 2, "step_completed count mismatch: %d" % _step_completed_count)
	assert(_kit_installed_hit, "kit_installed not fired")
	assert(not TaskManager.is_busy(CAR_ID), "task still busy")

	# 5) 断言：挂机收益已入账（10 秒 * 10/s = 100）
	var gained: int = EconomyManager.get_credits() - credits_before
	assert(gained >= 95 and gained <= 105, "yield mismatch: %d" % gained)

	# 6) 离线结算验证
	SaveManager.trigger_event_save()
	var credits_before_offline: int = EconomyManager.get_credits()
	_rewind_save_timestamp_on_disk(30)
	SaveManager.load_game()

	# 7) 断言：离线收益已发放（30 秒 * 10/s = 300，允许浮点缓冲 ±5）
	var offline_gain: int = EconomyManager.get_credits() - credits_before_offline
	assert(offline_gain >= 295 and offline_gain <= 305,
		"offline settlement mismatch: %d" % offline_gain)

	# 8) 断言：紧接着再 load 一次不应重复发放
	SaveManager.trigger_event_save()
	var credits_before_idempotent: int = EconomyManager.get_credits()
	SaveManager.load_game()
	assert(EconomyManager.get_credits() == credits_before_idempotent,
		"offline settlement must be idempotent when duration == 0")

	print("[Phase2Smoke] ALL ASSERTIONS PASSED ✅")
	get_tree().quit()


func _rewind_save_timestamp_on_disk(seconds_ago: int) -> void:
	const SAVE_PATH := "user://save_data.json"
	assert(FileAccess.file_exists(SAVE_PATH), "save file must exist before rewinding")
	var reader: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var raw: String = reader.get_as_text()
	reader.close()
	var json: JSON = JSON.new()
	assert(json.parse(raw) == OK, "save file is not valid JSON")
	var data: Dictionary = json.data
	data["last_save_timestamp"] = int(Time.get_unix_time_from_system()) - seconds_ago
	var writer: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	writer.store_string(JSON.stringify(data, "  "))
	writer.close()
