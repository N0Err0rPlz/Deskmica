# 代币类型定义 Custom Resource：描述单种代币的属性与兑换规则，由 DataRegistry 统一加载。
class_name TokenDefinition
extends Resource

@export var token_id: String = ""
@export var display_name: String = ""
@export var icon_path: String = ""
@export var max_stack: int = -1
@export var exchange_target_id: String = ""
@export var exchange_rate: float = 0.0
@export var exchange_cap_per_cycle: int = 0
@export var exchange_cycle_hours: float = 168.0
