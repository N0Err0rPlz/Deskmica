# 奖池定义 Custom Resource：抽卡入口配置，通过字符串 ID 关联共享的 LootTable 与 PityConfig。
class_name BannerDefinition
extends Resource

@export var banner_id: String = ""
@export var banner_type: String = "permanent"
@export var required_token_id: String = ""
@export var cost_per_pull: int = 1
@export var cost_per_multi: int = 10
@export var loot_table_id: String = ""
@export var pity_config_id: String = ""
