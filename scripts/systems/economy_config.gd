# 经济系统全局配置 Custom Resource：承载离线收益上限等不可枚举的全局参数，由 DataRegistry 单点加载。
class_name EconomyConfig
extends Resource

@export var offline_cap_seconds: int = 86400  # 离线收益最多结算秒数（默认 24 小时）
