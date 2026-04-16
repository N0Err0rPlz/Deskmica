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

# === Phase 3 新增：美术资产关联 ===
@export var sprite_path: String = ""                       # 配件 Sprite PNG 路径
@export var anchor_mode: String = "top_left"               # "top_left" 或 "center"
@export var compatible_templates: PackedStringArray = []   # 适用的模板 ID 列表
