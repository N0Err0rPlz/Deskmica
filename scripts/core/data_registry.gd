# data_registry.gd —— 资源注册表：启动时扫描 res://resources/ 并按主键字段缓存所有 Custom Resource（TDD 4.2）
extends Node

var cars: Dictionary = {}
var parts: Dictionary = {}
var kits: Dictionary = {}
var sets: Dictionary = {}
var tasks: Dictionary = {}
var banners: Dictionary = {}
var tokens: Dictionary = {}
var buffs: Dictionary = {}
var events: Dictionary = {}
var quests: Dictionary = {}
var minigames: Dictionary = {}

# 全局单例配置（非可枚举数据字典，固定路径加载）
var economy_config: EconomyConfig = null

const ECONOMY_CONFIG_PATH: String = "res://resources/economy_config.tres"

func _ready() -> void:
	_scan_and_cache("res://resources/cars/", cars, "car_id")
	_scan_and_cache("res://resources/parts/", parts, "part_id")
	_scan_and_cache("res://resources/kits/", kits, "kit_id")
	_scan_and_cache("res://resources/sets/", sets, "set_id")
	_scan_and_cache("res://resources/tasks/", tasks, "step_id")
	_scan_and_cache("res://resources/gacha/", banners, "banner_id")
	_scan_and_cache("res://resources/tokens/", tokens, "token_id")
	_scan_and_cache("res://resources/buffs/", buffs, "buff_id")
	_scan_and_cache("res://resources/events/", events, "event_id")
	_scan_and_cache("res://resources/quests/", quests, "quest_id")
	_scan_and_cache("res://resources/minigames/", minigames, "minigame_id")
	_load_economy_config()
	print("[DataRegistry] Initialized. Loaded: %d cars, %d parts, %d kits, %d sets, %d buffs. EconomyConfig: %s" % [
		cars.size(), parts.size(), kits.size(), sets.size(), buffs.size(),
		"OK" if economy_config != null else "MISSING"
	])

func _load_economy_config() -> void:
	if ResourceLoader.exists(ECONOMY_CONFIG_PATH):
		economy_config = ResourceLoader.load(ECONOMY_CONFIG_PATH) as EconomyConfig
	if economy_config == null:
		push_warning("[DataRegistry] EconomyConfig.tres missing at %s" % ECONOMY_CONFIG_PATH)

func _scan_and_cache(dir_path: String, target_dict: Dictionary, id_field: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return  # 目录不存在或为空，静默跳过（Phase 1 常态）
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var resource: Resource = ResourceLoader.load(dir_path + file_name)
			if resource and resource.get(id_field) != null:
				var id_value: String = resource.get(id_field)
				if id_value != "":
					target_dict[id_value] = resource
		file_name = dir.get_next()
	dir.list_dir_end()

# === 类型安全的 Getter（返回对应 Custom Resource 类，供业务方做静态检查） ===
func get_car(id: String) -> CarDefinition:
	return cars.get(id)

func get_part(id: String) -> PartDefinition:
	return parts.get(id)

func get_kit(id: String) -> KitDefinition:
	return kits.get(id)

func get_set(id: String) -> SetDefinition:
	return sets.get(id)

func get_task(id: String) -> TaskStepData:
	return tasks.get(id)

func get_banner(id: String) -> BannerDefinition:
	return banners.get(id)

func get_token_def(id: String) -> TokenDefinition:
	return tokens.get(id)

func get_buff(id: String) -> BuffDefinition:
	return buffs.get(id)

func get_event(id: String) -> EventDefinition:
	return events.get(id)

func get_minigame(id: String) -> MiniGameConfig:
	return minigames.get(id)

func get_economy_config() -> EconomyConfig:
	return economy_config
