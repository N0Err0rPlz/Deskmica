# 小游戏配置 Custom Resource：描述单个小游戏的类型、场景路径、时长、冷却与奖励来源，由 MiniGameSystem 读取。
class_name MiniGameConfig
extends Resource

@export var minigame_id: String = ""
@export var minigame_type: String = ""
@export var scene_path: String = ""
@export var duration_seconds: float = 10.0
@export var cooldown_seconds: float = 60.0
@export var contextual_speed_bonus: float = 0.1
@export var standalone_loot_table_id: String = ""
