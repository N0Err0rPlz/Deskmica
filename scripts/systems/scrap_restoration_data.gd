# 残骸修复任务数据 Custom Resource：描述残骸修复支线的条件、成本与战利品表引用，由 QuestSystem 解析。
class_name ScrapRestorationData
extends Resource

@export var quest_id: String = ""
@export var quest_type: String = "scrap_restoration"
@export var trigger_condition: String = "manual"
@export var repair_cost_credits: int = 0
@export var repair_duration_seconds: float = 120.0
@export var result_loot_table_id: String = ""
