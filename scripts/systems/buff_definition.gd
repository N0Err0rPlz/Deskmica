# Buff 定义 Custom Resource：描述单个增益效果的来源、作用维度、数值与叠加规则，由 DataRegistry 统一加载。
class_name BuffDefinition
extends Resource

@export var buff_id: String = ""
@export var source_type: String = ""
@export var target: String = "per_car"
@export var modifier_type: String = ""
@export var modifier_value: float = 0.0
@export var stack_mode: String = "additive"
@export var duration_seconds: float = -1.0
