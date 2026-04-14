# 任务步骤数据 Custom Resource：描述改装流程中单个步骤的执行参数，由 KitDefinition 组装为有序队列。
class_name TaskStepData
extends Resource

@export var step_id: String = ""
@export var task_tag: String = ""
@export var base_duration_seconds: float = 60.0
@export var animation_key: String = ""
@export var vfx_key: String = ""
@export var minigame_eligible: bool = false
@export var minigame_config_id: String = ""
