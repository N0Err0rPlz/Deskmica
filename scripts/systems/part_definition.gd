# 配件定义 Custom Resource：描述单个配件的静态属性，供 DataRegistry 统一加载与查询。
class_name PartDefinition
extends Resource

@export var part_id: String = ""
@export var display_name: String = ""
@export var brand: String = ""
@export var slot_type: String = ""
@export var part_value: int = 0
@export var purchase_price: int = 0
@export var buff_id: String = ""
@export var set_id: String = ""
@export var rarity_tag: String = "common"
