# 技师专精数据 Custom Resource：描述技师的专精类型与效率系数，由 TaskManager 按 tag 匹配 TaskStepData。
class_name SpecialtyData
extends Resource

@export var specialty_id: String = ""
@export var specialty_tag: String = ""
@export var display_name: String = ""
@export var efficiency_multiplier: float = 1.0
@export var sprite_palette_id: String = ""
