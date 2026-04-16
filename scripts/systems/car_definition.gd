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

# === Phase 3 新增：美术管线关联 ===
@export var template_id: String = ""           # 关联的模板 ID（"S-Low" / "M-Mid"）
@export var real_length_mm: int = 0            # 真实车长（毫米），用于模板自动匹配
@export var real_width_mm: int = 0             # 真实车宽（毫米）
@export var real_height_mm: int = 0            # 真实车高（毫米）
@export var real_wheelbase_mm: int = 0         # 真实轴距（毫米）
@export var anchor_overrides: Dictionary = {}  # 车辆级锚点覆盖（可选），示例：{ "spoiler": Vector2i(32, 10) }

# === Phase 3 新增：分层 Sprite 路径 ===
@export var sprite_shadow_path: String = ""
@export var sprite_chassis_path: String = ""
@export var sprite_body_path: String = ""
@export var sprite_detail_path: String = ""
