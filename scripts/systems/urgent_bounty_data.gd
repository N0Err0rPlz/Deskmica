# 紧急悬赏任务数据 Custom Resource：描述限时悬赏的触发、需求与奖励，由 QuestSystem 按概率投放。
class_name UrgentBountyData
extends Resource

@export var quest_id: String = ""
@export var quest_type: String = "urgent_bounty"
@export var trigger_probability: float = 0.1
@export var trigger_cooldown_seconds: float = 300.0
@export var time_limit_seconds: float = 7200.0
@export var required_car_tag: String = ""
@export var required_part_ids: PackedStringArray = []
@export var reward_credits: int = 0
@export var reward_token_id: String = ""
@export var reward_token_amount: int = 0
