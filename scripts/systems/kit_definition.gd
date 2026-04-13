# 改装套件定义 Custom Resource：描述一组配件 + 有序安装步骤的整体套装，由 DataRegistry 统一加载。
class_name KitDefinition
extends Resource

@export var kit_id: String = ""
@export var display_name: String = ""
@export var brand: String = ""
@export var purchase_price: int = 0
@export var included_part_ids: PackedStringArray = []
@export var task_steps: Array[TaskStepData] = []
