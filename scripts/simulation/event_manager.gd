# event_manager.gd —— 全局事件管理器：事件触发、持续期与修饰器应用（Phase 1 空壳）
extends Node

func _ready() -> void:
	print("[EventManager] Initialized.")

func update(delta: float) -> void:
	pass  # Phase 2+: 具体业务逻辑
