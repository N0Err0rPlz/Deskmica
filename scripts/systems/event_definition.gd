# 全局事件定义 Custom Resource：描述限时活动的时间窗、重复模式与效果集合，由 EventSystem 解析并注入全局增益管线。
class_name EventDefinition
extends Resource

@export var event_id: String = ""
@export var event_name: String = ""
@export var start_month: int = 1
@export var start_day: int = 1
@export var start_hour: int = 0
@export var end_month: int = 1
@export var end_day: int = 1
@export var end_hour: int = 23
@export var recurrence: String = "once"
@export var modifiers: Array[EventModifier] = []
