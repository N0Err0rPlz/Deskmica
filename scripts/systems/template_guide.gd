# 模板导引 Custom Resource：描述某一车型模板的包围盒、地面线、车轮、阴影与配件锚点，供 DataRegistry 统一加载与渲染/锚点查询层消费。
class_name TemplateGuide
extends Resource

@export var template_id: String = ""
@export var display_name: String = ""
@export var bbox_width: int = 64
@export var bbox_height: int = 36
@export var ground_line_y: int = 32
@export var wheel_front: Vector2i = Vector2i(18, 32)
@export var wheel_rear: Vector2i = Vector2i(46, 32)
@export var shadow_ellipse_rx: int = 28
@export var shadow_ellipse_ry: int = 6
@export var shadow_offset_y: int = 2
@export var part_anchors: Dictionary = {}
