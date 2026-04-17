# vehicle_renderer.gd —— 车辆分层渲染器（View 层骨架，详见 TDD §5.3.1 / ART_SPEC §4）
class_name VehicleRenderer
extends Node2D

@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var chassis_sprite: Sprite2D = $ChassisSprite
@onready var body_sprite: Sprite2D = $BodySprite
@onready var detail_sprite: Sprite2D = $DetailSprite
@onready var part_slots: Node2D = $PartSlots

var _car_id: String = ""
var _car_def: CarDefinition = null
var _template: TemplateGuide = null

# === 公开 API（Task 6.1 仅建骨架，方法体留待 Task 6.2 / 6.3 / 7.2 填充） ===

func initialize(car_def: CarDefinition) -> void:
	# Task 6.2 填充：加载四层 Sprite、应用调色盘 Shader、缓存模板引用
	pass

func set_palette_color(color: Color) -> void:
	# Task 6.3 填充：修改 SHADOW/CHASSIS/BODY 三层 ShaderMaterial 的 target_color
	pass

func attach_part(slot_type: String, part_def: PartDefinition) -> void:
	# Task 7.2 填充：按锚点坐标在 PartSlots 容器中挂载配件 Sprite
	pass

func detach_part(slot_type: String) -> void:
	# Task 7.2 填充：移除指定槽位的配件 Sprite
	pass
