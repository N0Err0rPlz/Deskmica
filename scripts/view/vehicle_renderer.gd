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
	_car_def = car_def
	_car_id = car_def.car_id
	_template = DataRegistry.get_template(car_def.template_id)

	# 加载四层 Sprite 纹理（Sprite 纹理是美术资产而非 Custom Resource，View 层使用 load() 在 Task_Phase3 §6.2 注中显式豁免）
	_load_texture(shadow_sprite, car_def.sprite_shadow_path)
	_load_texture(chassis_sprite, car_def.sprite_chassis_path)
	_load_texture(body_sprite, car_def.sprite_body_path)
	_load_texture(detail_sprite, car_def.sprite_detail_path)

	# 为 SHADOW/CHASSIS/BODY 三层独立挂一份 ShaderMaterial.duplicate()，确保每辆车可独立换色；Detail 层按 TDD §8.1 不挂 Shader
	var base_mat: ShaderMaterial = DataRegistry.get_shader_material("palette_swap")
	if base_mat:
		for sprite in [shadow_sprite, chassis_sprite, body_sprite]:
			sprite.material = base_mat.duplicate()

	print("[VehicleRenderer] Initialized: %s (template: %s)" % [_car_id, car_def.template_id])

func _load_texture(sprite: Sprite2D, path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		sprite.visible = false
		return
	sprite.texture = load(path)
	sprite.visible = true

func set_palette_color(color: Color) -> void:
	# Task 6.3 填充：修改 SHADOW/CHASSIS/BODY 三层 ShaderMaterial 的 target_color
	pass

func attach_part(slot_type: String, part_def: PartDefinition) -> void:
	# Task 7.2 填充：按锚点坐标在 PartSlots 容器中挂载配件 Sprite
	pass

func detach_part(slot_type: String) -> void:
	# Task 7.2 填充：移除指定槽位的配件 Sprite
	pass
