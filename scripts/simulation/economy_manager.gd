# economy_manager.gd —— 经济管理器：信用点持有、挂机收益累积与广播（TDD 5.4）
extends Node

var _credits: int = 0

# 车库中所有处于产出状态的车辆 ID（含未改装的素车）
var _garage_car_ids: Array[String] = []
# 挂机收益累加缓冲（避免每帧写小数到 int _credits）
var _yield_buffer: float = 0.0
# 全局产出倍率（Phase 2 固定为 1.0，Phase 3 由 Buff/SetBonus 注入）
var _global_modifier: float = 1.0


func _ready() -> void:
	SignalBus.car_added_to_garage.connect(_on_car_added)
	print("[EconomyManager] Initialized.")


func _on_car_added(car_id: String) -> void:
	if car_id in _garage_car_ids:
		return
	_garage_car_ids.append(car_id)

func update(delta: float) -> void:
	if _garage_car_ids.is_empty():
		return
	# TDD 5.4.1：yield = Σ base_value × delta × global_modifier
	_yield_buffer += calculate_passive_yield_per_second() * delta
	if _yield_buffer >= 1.0:
		var gained: int = int(floor(_yield_buffer))
		_yield_buffer -= float(gained)
		add_credits(gained)  # 复用 Phase 1 的 emit credits_changed 路径


func calculate_passive_yield_per_second() -> float:
	# 返回当前车库每秒被动产出（含 global_modifier），供在线 update 与
	# 离线结算（Task 5）共用同一公式，避免数值漂移。
	var per_second: float = 0.0
	for car_id in _garage_car_ids:
		var def: CarDefinition = DataRegistry.get_car(car_id)
		if def == null:
			push_warning("[EconomyManager] 未找到 CarDefinition: %s" % car_id)
			continue
		per_second += float(def.base_value)
	return per_second * _global_modifier

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
