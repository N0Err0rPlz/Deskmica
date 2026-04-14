# 战利品表 Custom Resource：一组 LootEntry 的加权集合，由 BannerDefinition 通过 ID 关联。
class_name LootTable
extends Resource

@export var table_id: String = ""
@export var entries: Array[LootEntry] = []
