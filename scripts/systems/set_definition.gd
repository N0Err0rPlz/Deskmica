# 套装定义 Custom Resource：描述品牌套装共鸣规则，包含必需配件列表与多档位阈值，由 DataRegistry 统一加载。
class_name SetDefinition
extends Resource

@export var set_id: String = ""
@export var brand: String = ""
@export var required_part_ids: PackedStringArray = []
@export var thresholds: Array[SetThreshold] = []
