# token_manager.gd —— 代币管理器：抽卡代币的持有、增减与广播（TDD 5.6.1，Phase 1 空壳）
extends Node

var _tokens: Dictionary = {}  # { "normal_token": 0, "premium_token": 0 }

func _ready() -> void:
	print("[TokenManager] Initialized.")

func update(delta: float) -> void:
	pass  # Phase 2: 在线时长累计代币

func get_token_count(token_id: String) -> int:
	return _tokens.get(token_id, 0)

func add_tokens(token_id: String, amount: int) -> void:
	_tokens[token_id] = _tokens.get(token_id, 0) + amount
	SignalBus.token_changed.emit(token_id, _tokens[token_id])

func spend_tokens(token_id: String, amount: int) -> bool:
	if get_token_count(token_id) >= amount:
		_tokens[token_id] -= amount
		SignalBus.token_changed.emit(token_id, _tokens[token_id])
		return true
	return false
