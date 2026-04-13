# 行动点数配置 Custom Resource：全局唯一的行动点平衡参数，由 ActionPointSystem 读取。
class_name ActionPointConfig
extends Resource

@export var max_points: float = 100.0
@export var regen_rate_per_second: float = 0.5
@export var joker_drain_rate: float = 1.0
@export var business_drain_rate: float = 0.8
