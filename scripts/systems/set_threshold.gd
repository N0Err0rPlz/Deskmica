# 套装阈值 Custom Resource：描述套装共鸣的单个档位（集齐 N 件触发 Buff），嵌入 SetDefinition.thresholds。
class_name SetThreshold
extends Resource

@export var required_count: int = 3
@export var buff_id: String = ""
