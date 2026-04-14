# 保底配置 Custom Resource：描述单个抽卡奖池的软/硬保底参数，由 BannerDefinition 通过 ID 关联。
class_name PityConfig
extends Resource

@export var pity_mode: String = "soft"
@export var soft_pity_start: int = 50
@export var soft_pity_increment: float = 0.02
@export var hard_pity_threshold: int = 90
@export var guaranteed_rarity: String = "epic"
