# task_manager.gd —— 任务流水线管理器：订阅套件购买信号、拆解步骤入队并驱动倒计时（Phase 2）
extends Node

# 每辆车的步骤队列： { car_id: Array[TaskStepData] }
var _queues: Dictionary = {}
# 每辆车当前正在执行的步骤剩余秒数： { car_id: float }
var _remaining_seconds: Dictionary = {}
# 每辆车当前正在执行的 kit_id（用于结束时 emit kit_installed）： { car_id: String }
var _active_kits: Dictionary = {}


func _ready() -> void:
	SignalBus.kit_purchased.connect(_on_kit_purchased)
	print("[TaskManager] Initialized.")


func update(_delta: float) -> void:
	# Phase 2 Task 2.3 将在此填充倒计时与步骤完成派发逻辑
	return


func _on_kit_purchased(car_id: String, kit_id: String) -> void:
	var kit_def: KitDefinition = DataRegistry.get_kit(kit_id)
	if kit_def == null:
		push_warning("[TaskManager] 未找到 KitDefinition: %s（car_id=%s）" % [kit_id, car_id])
		return

	if not _queues.has(car_id):
		var empty_queue: Array[TaskStepData] = []
		_queues[car_id] = empty_queue

	var queue: Array[TaskStepData] = _queues[car_id]
	for step in kit_def.task_steps:
		queue.append(step)

	_active_kits[car_id] = kit_id

	var idle: bool = not _remaining_seconds.has(car_id) or float(_remaining_seconds[car_id]) <= 0.0
	if idle:
		_start_next_step(car_id)


func _start_next_step(car_id: String) -> void:
	var queue: Array[TaskStepData] = _queues.get(car_id, [] as Array[TaskStepData])
	if queue.is_empty():
		_remaining_seconds.erase(car_id)
		var finished_kit_id: String = String(_active_kits.get(car_id, ""))
		SignalBus.kit_installed.emit(car_id, finished_kit_id)
		_active_kits.erase(car_id)
		return

	var step_data: TaskStepData = queue[0]
	_remaining_seconds[car_id] = step_data.base_duration_seconds
	SignalBus.step_started.emit(car_id, step_data)
