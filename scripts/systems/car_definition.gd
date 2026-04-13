# 车辆定义 Custom Resource：描述一辆素车的静态属性，供 DataRegistry 统一加载与查询。
class_name CarDefinition
extends Resource

@export var car_id: String = ""
@export var display_name: String = ""
@export var brand: String = ""
@export var base_value: int = 0
@export var purchase_price: int = 0
@export var part_slots: PackedStringArray = []
@export var sprite_path: String = ""
@export var palette_id: String = ""
