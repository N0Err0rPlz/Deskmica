# main_loop_manager.gd —— 主循环调度器：以固定顺序驱动模拟层子系统并切换省电档位（TDD 第 4 章）
extends Node

const FPS_NORMAL: int = 30
const FPS_FOCUS: int = 15

@warning_ignore("unused_private_class_variable")
var _is_focus_mode: bool = false

func _ready() -> void:
	print("[MainLoopManager] Initialized. Update loop active.")
	SignalBus.focus_mode_changed.connect(_on_focus_mode_changed)

func _process(delta: float) -> void:
	# === 模拟层更新（严格固定顺序，顺序写死以保证跨模块依赖可预测） ===
	EconomyManager.update(delta)
	TaskManager.update(delta)
	# QuestManager.update(delta)      # Phase 2
	# EventManager.update(delta)      # Phase 2
	# BusinessManager.update(delta)   # Phase 2
	BuffManager.update(delta)
	# MiniGameManager.update(delta)   # Phase 2
	TokenManager.update(delta)

func _on_focus_mode_changed(is_active: bool) -> void:
	_is_focus_mode = is_active
	if is_active:
		Engine.max_fps = FPS_FOCUS
		print("[MainLoopManager] Focus Mode ON → %d FPS" % FPS_FOCUS)
	else:
		Engine.max_fps = FPS_NORMAL
		print("[MainLoopManager] Focus Mode OFF → %d FPS" % FPS_NORMAL)
