# buff_manager.gd —— Buff 管理器：临时/永久修饰器的注册、过期与聚合计算（TDD 5.11，Phase 1 空壳）
extends Node

var _active_buffs: Array = []  # 运行时的 Buff 实例列表

func _ready() -> void:
	print("[BuffManager] Initialized.")

func update(delta: float) -> void:
	pass  # Phase 2: 临时 Buff 倒计时与过期移除

func register_buff(buff_def: BuffDefinition, target_car_id: String = "") -> void:
	pass  # Phase 2

func remove_buff(buff_id: String, target_car_id: String = "") -> void:
	pass  # Phase 2

func get_total_modifier(target: String, modifier_type: String) -> float:
	return 1.0  # 默认无修改（乘法基准值）
