# 战利品条目 Custom Resource：LootTable 中的单条掉落项，描述物品 ID、类型、稀有度与权重。
class_name LootEntry
extends Resource

@export var item_id: String = ""
@export var item_type: String = ""
@export var rarity_tag: String = "common"
@export var weight: float = 1.0
