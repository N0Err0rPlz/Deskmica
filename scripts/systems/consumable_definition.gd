# 耗材定义 Custom Resource：描述商店耗材的基础属性与使用后挂载的 Buff ID，由 DataRegistry 统一加载。
class_name ConsumableDefinition
extends Resource

@export var consumable_id: String = ""
@export var display_name: String = ""
@export var purchase_price: int = 0
@export var buff_id: String = ""
@export var description: String = ""
