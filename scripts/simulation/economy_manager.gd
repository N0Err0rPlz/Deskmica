# economy_manager.gd —— 经济管理器：信用点持有、挂机收益累积与广播（TDD 5.4）
extends Node

var _credits: int = 0

# 车库中所有处于产出状态的车辆 ID（含未改装的素车）
var _garage_car_ids: Array[String] = []
# 挂机收益累加缓冲（避免每帧写小数到 int _credits）
@warning_ignore("unused_private_class_variable")
var _yield_buffer: float = 0.0
# 全局产出倍率（Phase 2 固定为 1.0，Phase 3 由 Buff/SetBonus 注入）
@warning_ignore("unused_private_class_variable")
var _global_modifier: float = 1.0


func _ready() -> void:
	SignalBus.car_added_to_garage.connect(_on_car_added)
	print("[EconomyManager] Initialized.")


func _on_car_added(car_id: String) -> void:
	if car_id in _garage_car_ids:
		return
	_garage_car_ids.append(car_id)

func update(_delta: float) -> void:
	pass  # Phase 2: 挂机收益计算

func get_credits() -> int:
	return _credits

func add_credits(amount: int) -> void:
	_credits += amount
	SignalBus.credits_changed.emit(_credits)

func spend_credits(amount: int) -> bool:
	if _credits >= amount:
		_credits -= amount
		SignalBus.credits_changed.emit(_credits)
		return true
	return false
