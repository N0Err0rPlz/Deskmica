# 全局事件修饰器 Custom Resource：描述活动期对指定 tag 目标施加的单条增益修改，嵌入 EventDefinition.modifiers。
class_name EventModifier
extends Resource

@export var target_tag: String = ""
@export var modifier_type: String = ""
@export var modifier_value: float = 1.0
