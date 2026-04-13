# economy_manager.gd —— 经济管理器：信用点的持有、增减与广播（TDD 5.4，Phase 1 空壳）
extends Node

var _credits: int = 0

func _ready() -> void:
	print("[EconomyManager] Initialized.")

func update(delta: float) -> void:
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
