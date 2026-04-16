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


func update(delta: float) -> void:
	# 拷贝 keys 快照，防止迭代过程中 _start_next_step 修改字典
	for car_id in _remaining_seconds.keys():
		_remaining_seconds[car_id] = float(_remaining_seconds[car_id]) - delta
		if float(_remaining_seconds[car_id]) <= 0.0:
			# Peek 模型：当前步骤此刻仍留在 _queues[car_id][0]
			var finished_step: TaskStepData = _peek_current_step(car_id)
			SignalBus.step_completed.emit(car_id, finished_step)
			(_queues[car_id] as Array).pop_front()  # 倒计时归零后才真正弹出
			_start_next_step(car_id)  # 读取新的队首或发射 kit_installed


func is_busy(car_id: String) -> bool:
	return _remaining_seconds.has(car_id) and float(_remaining_seconds[car_id]) > 0.0


func get_remaining(car_id: String) -> float:
	return float(_remaining_seconds.get(car_id, 0.0))


func restore_queue_snapshot(snapshot: Array) -> void:
	_queues.clear()
	_remaining_seconds.clear()
	_active_kits.clear()
	for entry in snapshot:
		var car_id: String = String(entry.get("car_id", ""))
		if car_id == "":
			continue
		var active_kit_id: String = String(entry.get("active_kit_id", ""))
		var remaining: float = float(entry.get("remaining_seconds", 0.0))
		var step_ids: Array = entry.get("pending_step_ids", [])

		var queue: Array[TaskStepData] = []
		var skip_car: bool = false
		for sid in step_ids:
			var step: TaskStepData = DataRegistry.get_task(String(sid))
			if step == null:
				push_warning("[TaskManager] 存档还原跳过车辆 %s：step_id '%s' 在 DataRegistry 中不存在" % [car_id, sid])
				skip_car = true
				break
			queue.append(step)
		if skip_car:
			continue

		_queues[car_id] = queue
		if active_kit_id != "":
			_active_kits[car_id] = active_kit_id
		if not queue.is_empty():
			_remaining_seconds[car_id] = remaining


func export_queue_snapshot() -> Array:
	# 导出当前所有车辆的任务队列快照，用于存档序列化。
	# 仅写 step_id 字符串，绝不序列化 Resource 本体。
	var snapshot: Array = []
	for car_id in _queues:
		var queue: Array[TaskStepData] = _queues[car_id]
		if queue.is_empty() and not _active_kits.has(car_id):
			continue
		var pending_ids: Array[String] = []
		for step in queue:
			pending_ids.append(step.step_id)
		var entry: Dictionary = {
			"car_id": car_id,
			"active_kit_id": String(_active_kits.get(car_id, "")),
			"remaining_seconds": float(_remaining_seconds.get(car_id, 0.0)),
			"pending_step_ids": pending_ids,
		}
		snapshot.append(entry)
	return snapshot


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


func _peek_current_step(car_id: String) -> TaskStepData:
	# 仅读取队首步骤，不改动队列；pop 时机严格由 update() 控制
	return (_queues[car_id] as Array)[0]


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
