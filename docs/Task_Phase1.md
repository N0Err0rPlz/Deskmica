# Task.md — 第一阶段开发任务清单

**项目代号**：Desktop Garage（桌面车库）
**阶段**：Phase 1 — 纯净底层框架与核心数据字典
**基准文档**：TDD.md v1.0-FINAL
**最后更新**：2026-04-11

---

> **Phase 1 范围边界**
>
> 本阶段的唯一目标是：**搭建一个"按 F5 能跑起来、控制台输出正确日志、所有单例互相能找到"的纯净骨架。**
>
> 本阶段**不涉及**：任何 UI 界面搭建、美术资产导入、具体游戏玩法表现逻辑、视图层（View Layer）实现。
>
> 完成本阶段后，项目应处于一个"所有管理器空壳就位、所有数据结构可在编辑器中创建 .tres 文件、存档可读写、主循环可调度"的状态。

> **Vibe Coding 工作流提醒**
>
> 每个编号任务（如 1.1、1.2 ...）视为一个独立的"AI 指令单元"。执行流程：
> 1. `git commit -m "Before: [任务名称]"` （Step 1：指令前存档）
> 2. 让 Claude Code 完成任务
> 3. 在 Godot 中按 F5 运行测试 → 崩溃则 `git revert`，成功则 `git commit` （Step 2/3）

---

## 目录

1. [项目初始化与目录构建](#1-项目初始化与目录构建)
2. [核心数据资源基类（Custom Resources）](#2-核心数据资源基类custom-resources)
3. [全局信号总线（SignalBus）](#3-全局信号总线signalbus)
4. [核心单例空壳与 Autoload 注册](#4-核心单例空壳与-autoload-注册)
5. [MainLoopManager 执行流调度](#5-mainloopmanager-执行流调度)
6. [DataRegistry 资源注册表](#6-dataregistry-资源注册表)
7. [SaveManager 存档读写系统](#7-savemanager-存档读写系统)
8. [阶段验收：全链路冒烟测试](#8-阶段验收全链路冒烟测试)

---

## 1. 项目初始化与目录构建

### - [ ] 1.1 创建 Godot 项目并配置基础设置

**技术定位**：
- 新建 Godot 4.6.2 项目，项目根目录 `project.godot`。
- 涉及技术：Project Settings 配置。

**具体动作**：
- 创建新的 Godot 4.6.2 项目，项目名称设为 `DesktopGarage`。
- 在 Project Settings 中配置以下关键项：
  - `display/window/size/viewport_width` = 960
  - `display/window/size/viewport_height` = 540
  - `rendering/textures/canvas_textures/default_texture_filter` = `NEAREST`（像素画防模糊）
  - `application/run/max_fps` = 30（常规模式锁帧）
  - `display/window/size/borderless` = `true`（无边框窗口）
  - `display/window/size/always_on_top` = `true`（置顶）
  - `display/window/size/transparent` = `true`（透明背景）

**验收标准 (DoD)**：
- Godot 编辑器中按 F5 能启动一个无边框、置顶、透明背景的空窗口。
- 窗口以 30FPS 运行（可通过 Godot Profiler 或 `Engine.get_frames_per_second()` 验证）。

---

### - [ ] 1.2 创建标准目录结构

**技术定位**：
- 按照 TDD 第 3 章的规范，在 `res://` 下创建完整的文件夹树。
- 涉及技术：Godot FileSystem。

**具体动作**：
- 创建以下目录（空文件夹需放入一个 `.gdkeep` 占位文件以确保 Git 追踪）：

```
res://
├── scenes/main/
├── scenes/ui/
├── scenes/minigames/
├── scripts/core/
├── scripts/simulation/
├── scripts/view/
├── scripts/entities/components/
├── scripts/entities/fsm/
├── scripts/systems/
├── scripts/ui/
├── scripts/utils/
├── resources/cars/
├── resources/parts/
├── resources/sets/
├── resources/tasks/
├── resources/gacha/
├── resources/quests/
├── resources/tokens/
├── resources/events/
├── resources/minigames/
├── resources/buffs/
├── assets/sprites/
├── assets/animations/
├── assets/shaders/
├── assets/sfx/
├── data/
├── addons/
```

**验收标准 (DoD)**：
- 在 Godot 编辑器的 FileSystem 面板中能看到完整的目录树。
- 所有文件夹均存在且不为空（有 `.gdkeep` 占位）。
- `git status` 显示所有目录已被追踪。

---

### - [ ] 1.3 创建主场景入口

**技术定位**：
- 新建文件：`res://scenes/main/main.tscn`
- 涉及技术：Scene Tree、Node2D。

**具体动作**：
- 创建一个空的 `Node2D` 作为根节点，命名为 `Main`。
- 保存为 `res://scenes/main/main.tscn`。
- 在 Project Settings → Application → Run → Main Scene 中将其设为启动场景。

**验收标准 (DoD)**：
- 按 F5 运行后，游戏启动并进入空的主场景，控制台无报错。

---

### - [ ] 1.4 初始化 Git 仓库与双分支

**技术定位**：
- 涉及技术：Git、GitHub。
- 遵循 TDD 第 11 章双分支策略。

**具体动作**：
- 在项目根目录初始化 Git 仓库。
- 创建 `.gitignore` 文件，排除 Godot 缓存文件：

```
# Godot 缓存
.godot/
*.import

# OS 垃圾
.DS_Store
Thumbs.db
```

- 提交初始 Commit：`"init: Project scaffolding with directory structure"`。
- 创建 `dev` 分支并切换到该分支。
- 推送至 GitHub 远程仓库（`main` + `dev` 双分支）。

**验收标准 (DoD)**：
- GitHub 上能看到 `main` 和 `dev` 两个分支。
- `main` 分支包含完整的初始目录结构和空主场景。
- 后续所有开发均在 `dev` 分支上进行。

---

## 2. 核心数据资源基类（Custom Resources）

> **本节说明**：定义所有 Custom Resource 的 GDScript 基类。这些脚本本身不包含任何业务逻辑，仅声明数据字段（`@export` 变量）。完成后，开发者可在 Godot 编辑器中右键 → New Resource → 选择对应类型 → 创建 `.tres` 文件并在 Inspector 面板中填写数值。

---

### - [ ] 2.1 车辆定义（CarDefinition）

**技术定位**：
- 新建文件：`res://scripts/systems/car_definition.gd`
- 涉及技术：Custom Resource（`extends Resource`、`class_name`、`@export`）。

**具体动作**：
- 创建脚本，声明以下字段：

```gdscript
class_name CarDefinition
extends Resource

@export var car_id: String = ""
@export var display_name: String = ""
@export var brand: String = ""
@export var base_value: int = 0          # 素车价值（用于挂机收益计算）
@export var purchase_price: int = 0      # 购买价格
@export var part_slots: PackedStringArray = []  # 可安装的配件槽位列表
@export var sprite_path: String = ""     # 关联的 Sprite 贴图路径
@export var palette_id: String = ""      # 关联的调色盘 Shader ID
```

**验收标准 (DoD)**：
- 在 Godot 编辑器中，右键 `res://resources/cars/` → New Resource → 能在列表中找到 `CarDefinition`。
- 创建一个测试文件 `test_bmw_e30.tres`，在 Inspector 面板中能看到并编辑所有字段。
- 验证后**删除**测试文件（不入库垃圾数据）。

---

### - [ ] 2.2 配件定义（PartDefinition）

**技术定位**：
- 新建文件：`res://scripts/systems/part_definition.gd`
- 涉及技术：Custom Resource。

**具体动作**：

```gdscript
class_name PartDefinition
extends Resource

@export var part_id: String = ""
@export var display_name: String = ""
@export var brand: String = ""           # 品牌（用于套装共鸣匹配）
@export var slot_type: String = ""       # 安装槽位类型（front_bumper / wheels / ...）
@export var part_value: int = 0          # 配件价值（用于车辆估价）
@export var purchase_price: int = 0
@export var buff_id: String = ""         # 散件 Buff ID（关联 BuffDefinition）
@export var set_id: String = ""          # 所属套装 ID（关联 SetDefinition）
@export var rarity_tag: String = "common"  # 稀有度标签
```

**验收标准 (DoD)**：
- 编辑器中可创建 `PartDefinition` 类型的 `.tres` 资源并编辑所有字段。

---

### - [ ] 2.3 改装套件定义（KitDefinition）

**技术定位**：
- 新建文件：`res://scripts/systems/kit_definition.gd`
- 涉及技术：Custom Resource、`Array[Resource]` 引用。

**具体动作**：

```gdscript
class_name KitDefinition
extends Resource

@export var kit_id: String = ""
@export var display_name: String = ""
@export var brand: String = ""
@export var purchase_price: int = 0
@export var included_part_ids: PackedStringArray = []  # 包含的配件 ID 列表
@export var task_steps: Array[TaskStepData] = []        # 安装步骤队列（有序）
```

**验收标准 (DoD)**：
- 编辑器中可创建 `KitDefinition` 并能在 Inspector 中展开 `task_steps` 数组、为每个元素分配 `TaskStepData` 资源。

---

### - [ ] 2.4 任务步骤数据（TaskStepData）

**技术定位**：
- 新建文件：`res://scripts/systems/task_step_data.gd`
- 涉及技术：Custom Resource。
- 来源：TDD 5.2 章 TaskManager。

**具体动作**：

```gdscript
class_name TaskStepData
extends Resource

@export var step_id: String = ""
@export var task_tag: String = ""              # 匹配技师专精标签
@export var base_duration_seconds: float = 60.0
@export var animation_key: String = ""         # 视图层动画 Key
@export var vfx_key: String = ""               # 视图层特效 Key
@export var minigame_eligible: bool = false
@export var minigame_config_id: String = ""
```

**验收标准 (DoD)**：
- 编辑器中可创建 `TaskStepData` 类型的 `.tres` 文件并编辑所有字段。

---

### - [ ] 2.5 技师专精数据（SpecialtyData）

**技术定位**：
- 新建文件：`res://scripts/entities/specialty_data.gd`
- 涉及技术：Custom Resource。
- 来源：TDD 5.1.1 章。

**具体动作**：

```gdscript
class_name SpecialtyData
extends Resource

@export var specialty_id: String = ""
@export var specialty_tag: String = ""         # 匹配 TaskStepData 的 task_tag
@export var display_name: String = ""
@export var efficiency_multiplier: float = 1.0
@export var sprite_palette_id: String = ""
```

**验收标准 (DoD)**：
- 编辑器中可创建 `SpecialtyData` 并编辑所有字段。

---

### - [ ] 2.6 行动点数配置（ActionPointConfig）

**技术定位**：
- 新建文件：`res://scripts/entities/action_point_config.gd`
- 涉及技术：Custom Resource。
- 来源：TDD 5.1.3 章。

**具体动作**：

```gdscript
class_name ActionPointConfig
extends Resource

@export var max_points: float = 100.0
@export var regen_rate_per_second: float = 0.5
@export var joker_drain_rate: float = 1.0
@export var business_drain_rate: float = 0.8
```

**验收标准 (DoD)**：
- 编辑器中可创建 `ActionPointConfig` 并编辑所有字段。

---

### - [ ] 2.7 代币类型定义（TokenDefinition）

**技术定位**：
- 新建文件：`res://scripts/systems/token_definition.gd`
- 涉及技术：Custom Resource。
- 来源：TDD 5.6.1 章。

**具体动作**：

```gdscript
class_name TokenDefinition
extends Resource

@export var token_id: String = ""
@export var display_name: String = ""
@export var icon_path: String = ""
@export var max_stack: int = -1              # -1 = 无上限
@export var exchange_target_id: String = ""  # 可兑换目标代币 ID
@export var exchange_rate: float = 0.0
@export var exchange_cap_per_cycle: int = 0
@export var exchange_cycle_hours: float = 168.0  # 默认每周
```

**验收标准 (DoD)**：
- 编辑器中可创建 `TokenDefinition` 并编辑所有字段。

---

### - [ ] 2.8 奖池定义（BannerDefinition）与战利品表（LootTable / LootEntry）

**技术定位**：
- 新建文件：
  - `res://scripts/systems/banner_definition.gd`
  - `res://scripts/systems/loot_table.gd`
  - `res://scripts/systems/loot_entry.gd`
- 涉及技术：Custom Resource、嵌套 Resource 数组。
- 来源：TDD 5.6.2 章。

**具体动作**：

```gdscript
# loot_entry.gd
class_name LootEntry
extends Resource

@export var item_id: String = ""
@export var item_type: String = ""        # "part" / "paint" / "scrap" / "credits"
@export var rarity_tag: String = "common"
@export var weight: float = 1.0

# loot_table.gd
class_name LootTable
extends Resource

@export var table_id: String = ""
@export var entries: Array[LootEntry] = []

# banner_definition.gd
class_name BannerDefinition
extends Resource

@export var banner_id: String = ""
@export var banner_type: String = "permanent"  # "permanent" / "limited"
@export var required_token_id: String = ""
@export var cost_per_pull: int = 1
@export var cost_per_multi: int = 10
@export var loot_table_id: String = ""
@export var pity_config_id: String = ""
```

**验收标准 (DoD)**：
- 可创建 `LootEntry` → 嵌入 `LootTable` 的 entries 数组中 → `BannerDefinition` 通过 ID 字符串关联 `LootTable`。
- 在 Inspector 中展开 `LootTable.entries`，能看到每个 `LootEntry` 的全部字段。

---

### - [ ] 2.9 保底配置（PityConfig）

**技术定位**：
- 新建文件：`res://scripts/systems/pity_config.gd`
- 涉及技术：Custom Resource。
- 来源：TDD 5.6.3 章。

**具体动作**：

```gdscript
class_name PityConfig
extends Resource

@export var pity_mode: String = "soft"       # "soft" / "hard"
@export var soft_pity_start: int = 50
@export var soft_pity_increment: float = 0.02
@export var hard_pity_threshold: int = 90
@export var guaranteed_rarity: String = "epic"
```

**验收标准 (DoD)**：
- 编辑器中可创建 `PityConfig` 并切换 `pity_mode` 字段。

---

### - [ ] 2.10 套装定义（SetDefinition）与阈值结构（SetThreshold）

**技术定位**：
- 新建文件：
  - `res://scripts/systems/set_definition.gd`
  - `res://scripts/systems/set_threshold.gd`
- 涉及技术：Custom Resource、嵌套 Resource。
- 来源：TDD 5.7.1 章。

**具体动作**：

```gdscript
# set_threshold.gd
class_name SetThreshold
extends Resource

@export var required_count: int = 3
@export var buff_id: String = ""

# set_definition.gd
class_name SetDefinition
extends Resource

@export var set_id: String = ""
@export var brand: String = ""
@export var required_part_ids: PackedStringArray = []
@export var thresholds: Array[SetThreshold] = []
```

**验收标准 (DoD)**：
- 可创建 `SetDefinition`，在 Inspector 中展开 `thresholds` 数组并为每项设置 `required_count` 和 `buff_id`。

---

### - [ ] 2.11 Buff 定义（BuffDefinition）

**技术定位**：
- 新建文件：`res://scripts/systems/buff_definition.gd`
- 涉及技术：Custom Resource。
- 来源：TDD 5.11 章。

**具体动作**：

```gdscript
class_name BuffDefinition
extends Resource

@export var buff_id: String = ""
@export var source_type: String = ""       # "part" / "set_bonus" / "consumable" / "event" / "aura"
@export var target: String = "per_car"     # "per_car" / "global"
@export var modifier_type: String = ""     # "yield_speed" / "task_speed" / "sell_multiplier"
@export var modifier_value: float = 0.0
@export var stack_mode: String = "additive"  # "additive" / "multiplicative" / "replace"
@export var duration_seconds: float = -1.0   # -1 = 永久
```

**验收标准 (DoD)**：
- 编辑器中可创建 `BuffDefinition` 并编辑所有字段。

---

### - [ ] 2.12 支线任务数据（QuestData 家族）

**技术定位**：
- 新建文件：
  - `res://scripts/systems/urgent_bounty_data.gd`
  - `res://scripts/systems/scrap_restoration_data.gd`
- 涉及技术：Custom Resource。
- 来源：TDD 5.8.2 章。

**具体动作**：

```gdscript
# urgent_bounty_data.gd
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

# scrap_restoration_data.gd
class_name ScrapRestorationData
extends Resource

@export var quest_id: String = ""
@export var quest_type: String = "scrap_restoration"
@export var trigger_condition: String = "manual"
@export var repair_cost_credits: int = 0
@export var repair_duration_seconds: float = 120.0
@export var result_loot_table_id: String = ""
```

**验收标准 (DoD)**：
- 编辑器中可分别创建 `UrgentBountyData` 和 `ScrapRestorationData` 类型的资源。

---

### - [ ] 2.13 全局事件定义（EventDefinition / EventModifier）

**技术定位**：
- 新建文件：
  - `res://scripts/systems/event_definition.gd`
  - `res://scripts/systems/event_modifier.gd`
- 涉及技术：Custom Resource、嵌套 Resource。
- 来源：TDD 5.9 章。

**具体动作**：

```gdscript
# event_modifier.gd
class_name EventModifier
extends Resource

@export var target_tag: String = ""          # 影响哪些品牌/车型（"" = 全局）
@export var modifier_type: String = ""       # "task_speed" / "sell_multiplier" / "yield_multiplier"
@export var modifier_value: float = 1.0

# event_definition.gd
class_name EventDefinition
extends Resource

@export var event_id: String = ""
@export var event_name: String = ""
@export var start_month: int = 1
@export var start_day: int = 1
@export var start_hour: int = 0
@export var end_month: int = 1
@export var end_day: int = 1
@export var end_hour: int = 23
@export var recurrence: String = "once"      # "once" / "weekly" / "monthly" / "yearly"
@export var modifiers: Array[EventModifier] = []
```

**验收标准 (DoD)**：
- 可创建 `EventDefinition`，在 Inspector 中展开 `modifiers` 数组并为每项设置所有字段。

---

### - [ ] 2.14 小游戏配置（MiniGameConfig）

**技术定位**：
- 新建文件：`res://scripts/systems/minigame_config.gd`
- 涉及技术：Custom Resource。
- 来源：TDD 5.10.4 章。

**具体动作**：

```gdscript
class_name MiniGameConfig
extends Resource

@export var minigame_id: String = ""
@export var minigame_type: String = ""       # "qte_timing" / "qte_sequence" / ...
@export var scene_path: String = ""
@export var duration_seconds: float = 10.0
@export var cooldown_seconds: float = 60.0
@export var contextual_speed_bonus: float = 0.1
@export var standalone_loot_table_id: String = ""
```

**验收标准 (DoD)**：
- 编辑器中可创建 `MiniGameConfig` 并编辑所有字段。

---

### - [ ] 2.15 耗材定义（ConsumableDefinition）

**技术定位**：
- 新建文件：`res://scripts/systems/consumable_definition.gd`
- 涉及技术：Custom Resource。
- 来源：TDD 5.5 章商店模块 → 耗材商店。

**具体动作**：

```gdscript
class_name ConsumableDefinition
extends Resource

@export var consumable_id: String = ""
@export var display_name: String = ""
@export var purchase_price: int = 0
@export var buff_id: String = ""           # 使用后立即应用的 Buff ID
@export var description: String = ""
```

**验收标准 (DoD)**：
- 编辑器中可创建 `ConsumableDefinition` 并编辑所有字段。

---

## 3. 全局信号总线（SignalBus）

### - [ ] 3.1 创建 SignalBus 脚本

**技术定位**：
- 新建文件：`res://scripts/core/signal_bus.gd`
- 涉及技术：Godot Signals、Autoload。
- 来源：TDD 4.1 章。

**具体动作**：
- 创建脚本，集中定义所有跨模块的全局信号：

```gdscript
# signal_bus.gd
extends Node

# === 经济与交易 ===
signal credits_changed(new_amount: int)
signal car_purchased(car_id: String)
signal car_delivered(car_id: String, sell_price: int)
signal item_purchased(item_type: String, item_id: String)

# === 改装流程 ===
signal kit_purchased(car_id: String, kit_id: String)
signal step_started(car_id: String, step_data: Resource)
signal step_completed(car_id: String, step_data: Resource)
signal kit_installed(car_id: String, kit_id: String)

# === 配件与套装 ===
signal parts_changed(car_id: String)
signal set_bonus_changed(car_id: String, set_id: String, active_tier: int)

# === 支线任务 ===
signal quest_available(quest_id: String)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal quest_expired(quest_id: String)

# === 抽卡与代币 ===
signal token_changed(token_id: String, new_amount: int)
signal gacha_pull_result(banner_id: String, results: Array)

# === 小游戏 ===
signal minigame_reward(reward_data: Dictionary)

# === 全局事件 ===
signal global_event_started(event_id: String)
signal global_event_ended(event_id: String)

# === 主理人状态 ===
signal player_state_changed(new_state: String)
signal action_points_changed(current: float, max_points: float)

# === 存档 ===
signal save_completed()
signal load_completed()

# === 专注模式 ===
signal focus_mode_changed(is_active: bool)
```

**验收标准 (DoD)**：
- 脚本语法无报错。
- 在 Godot 编辑器 Script Editor 中打开该文件能看到所有信号声明。
- **暂不注册为 Autoload**（在任务 4.1 中统一注册）。

---

## 4. 核心单例空壳与 Autoload 注册

> **本节说明**：为 TDD 4.1 章 Autoloads 清单中的每个管理器创建"空壳"脚本——只包含类声明、`_ready()` 日志输出和公开方法的签名（方法体为 `pass` 或占位打印）。不实现任何业务逻辑。

---

### - [ ] 4.1 EconomyManager 空壳

**技术定位**：
- 新建文件：`res://scripts/simulation/economy_manager.gd`
- 涉及技术：Autoload 单例。
- 来源：TDD 5.4 章。

**具体动作**：

```gdscript
extends Node

var _credits: int = 0

func _ready() -> void:
    print("[EconomyManager] Initialized.")

func update(delta: float) -> void:
    pass  # Phase 2: 挂机收益计算

func get_credits() -> int:
    return _credits

func add_credits(amount: int) -> void:
    _credits += amount
    SignalBus.credits_changed.emit(_credits)

func spend_credits(amount: int) -> bool:
    if _credits >= amount:
        _credits -= amount
        SignalBus.credits_changed.emit(_credits)
        return true
    return false
```

**验收标准 (DoD)**：
- 脚本无语法错误，控制台打印 `[EconomyManager] Initialized.`。

---

### - [ ] 4.2 TokenManager 空壳

**技术定位**：
- 新建文件：`res://scripts/simulation/token_manager.gd`
- 来源：TDD 5.6.1 章。

**具体动作**：

```gdscript
extends Node

var _tokens: Dictionary = {}  # { "normal_token": 0, "premium_token": 0 }

func _ready() -> void:
    print("[TokenManager] Initialized.")

func update(delta: float) -> void:
    pass  # Phase 2: 在线时长累计代币

func get_token_count(token_id: String) -> int:
    return _tokens.get(token_id, 0)

func add_tokens(token_id: String, amount: int) -> void:
    _tokens[token_id] = _tokens.get(token_id, 0) + amount
    SignalBus.token_changed.emit(token_id, _tokens[token_id])

func spend_tokens(token_id: String, amount: int) -> bool:
    if get_token_count(token_id) >= amount:
        _tokens[token_id] -= amount
        SignalBus.token_changed.emit(token_id, _tokens[token_id])
        return true
    return false
```

**验收标准 (DoD)**：
- 脚本无语法错误，控制台打印 `[TokenManager] Initialized.`。

---

### - [ ] 4.3 BuffManager 空壳

**技术定位**：
- 新建文件：`res://scripts/simulation/buff_manager.gd`
- 来源：TDD 5.11 章。

**具体动作**：

```gdscript
extends Node

var _active_buffs: Array = []  # 运行时的 Buff 实例列表

func _ready() -> void:
    print("[BuffManager] Initialized.")

func update(delta: float) -> void:
    pass  # Phase 2: 临时 Buff 倒计时与过期移除

func register_buff(buff_def: BuffDefinition, target_car_id: String = "") -> void:
    pass  # Phase 2

func remove_buff(buff_id: String, target_car_id: String = "") -> void:
    pass  # Phase 2

func get_total_modifier(target: String, modifier_type: String) -> float:
    return 1.0  # 默认无修改（乘法基准值）
```

**验收标准 (DoD)**：
- 脚本无语法错误，控制台打印 `[BuffManager] Initialized.`。

---

### - [ ] 4.4 其余模拟层管理器空壳（批量创建）

**技术定位**：
- 新建以下文件（每个文件结构相同：`extends Node` + `_ready()` 打印 + `update(delta)` 空方法）：
  - `res://scripts/simulation/task_manager.gd`
  - `res://scripts/simulation/quest_manager.gd`
  - `res://scripts/simulation/event_manager.gd`
  - `res://scripts/simulation/business_manager.gd`
  - `res://scripts/simulation/set_bonus_calculator.gd`
  - `res://scripts/systems/gacha_system.gd`
  - `res://scripts/systems/shop_system.gd`
  - `res://scripts/systems/minigame_manager.gd`

**具体动作**：
- 每个脚本遵循统一模板：

```gdscript
# 以 task_manager.gd 为例
extends Node

func _ready() -> void:
    print("[TaskManager] Initialized.")

func update(delta: float) -> void:
    pass  # Phase 2+: 具体业务逻辑
```

- 注意：这些管理器**不在 Autoload 清单中**（它们不是全局单例）。它们将在 Phase 2 中作为 `MainLoopManager` 的子系统被实例化或引用。目前仅创建脚本文件确保路径存在。

**验收标准 (DoD)**：
- 所有 8 个脚本文件存在于正确路径，语法无报错。
- 每个文件中 `_ready()` 输出对应的 `[ClassName] Initialized.` 日志。

---

### - [ ] 4.5 在 Project Settings 中注册所有 Autoload 单例

**技术定位**：
- 涉及技术：Godot Project Settings → Autoload。
- 来源：TDD 4.1 章 Autoloads 清单。

**具体动作**：
- 在 Project Settings → Autoload 中，按以下**精确顺序**注册（加载顺序决定了哪些单例可以在 `_ready()` 中引用其他单例）：

| 顺序 | 注册名 | 脚本路径 |
|------|--------|----------|
| 1 | `SignalBus` | `res://scripts/core/signal_bus.gd` |
| 2 | `DataRegistry` | `res://scripts/core/data_registry.gd`（下一节创建） |
| 3 | `SaveManager` | `res://scripts/core/save_manager.gd`（第 7 节创建） |
| 4 | `EconomyManager` | `res://scripts/simulation/economy_manager.gd` |
| 5 | `TokenManager` | `res://scripts/simulation/token_manager.gd` |
| 6 | `BuffManager` | `res://scripts/simulation/buff_manager.gd` |
| 7 | `MainLoopManager` | `res://scripts/core/main_loop_manager.gd`（第 5 节创建） |

- **注意**：`DataRegistry`、`SaveManager`、`MainLoopManager` 的脚本在后续任务中创建。注册时 Godot 会提示脚本不存在——**先跳过这三个**，在对应任务完成后再回来补注册。或者先创建只含 `extends Node` 和 `_ready()` 打印的最小占位脚本。

**推荐做法**：先为这三个创建最小占位脚本：

```gdscript
# 占位脚本模板（data_registry.gd / save_manager.gd / main_loop_manager.gd）
extends Node

func _ready() -> void:
    print("[占位] Initialized. 待后续任务填充。")
```

然后一次性完成全部 7 个 Autoload 注册。

**验收标准 (DoD)**：
- 按 F5 运行游戏，控制台按注册顺序依次输出 7 行 `[XXX] Initialized.` 日志。
- 在任意脚本中可通过 `SignalBus`、`EconomyManager` 等全局名称直接访问对应单例，无需 `get_node()`。

---

## 5. MainLoopManager 执行流调度

### - [ ] 5.1 实现 MainLoopManager 核心调度逻辑

**技术定位**：
- 修改文件：`res://scripts/core/main_loop_manager.gd`（替换占位内容）
- 涉及技术：`_process(delta)` 集中调度、Autoload 单例引用。
- 来源：TDD 第 4 章架构总览。

**具体动作**：

```gdscript
extends Node

# 模拟层子系统引用（Phase 1 中仅引用已注册为 Autoload 的管理器）
# 非 Autoload 的子系统将在 Phase 2 中通过实例化或场景挂载接入

var _is_focus_mode: bool = false

func _ready() -> void:
    print("[MainLoopManager] Initialized. Update loop active.")
    SignalBus.focus_mode_changed.connect(_on_focus_mode_changed)

func _process(delta: float) -> void:
    # === 模拟层更新（严格固定顺序） ===
    EconomyManager.update(delta)
    # TaskManager.update(delta)       # Phase 2: 接入后取消注释
    # QuestManager.update(delta)      # Phase 2
    # EventManager.update(delta)      # Phase 2
    # BusinessManager.update(delta)   # Phase 2
    BuffManager.update(delta)
    # MiniGameManager.update(delta)   # Phase 2
    TokenManager.update(delta)

func _on_focus_mode_changed(is_active: bool) -> void:
    _is_focus_mode = is_active
    if is_active:
        Engine.max_fps = 15
        print("[MainLoopManager] Focus Mode ON → 15 FPS")
    else:
        Engine.max_fps = 30
        print("[MainLoopManager] Focus Mode OFF → 30 FPS")
```

**验收标准 (DoD)**：
- 按 F5 运行，控制台输出 `[MainLoopManager] Initialized. Update loop active.`。
- 不崩溃、无报错（即使所有 `update()` 方法体都是 `pass`）。
- 手动在调试控制台执行 `SignalBus.focus_mode_changed.emit(true)` → 控制台输出 `Focus Mode ON → 15 FPS`，且游戏帧率实际降至 15。

---

## 6. DataRegistry 资源注册表

### - [ ] 6.1 实现 DataRegistry 扫描与缓存逻辑

**技术定位**：
- 修改文件：`res://scripts/core/data_registry.gd`（替换占位内容）
- 涉及技术：`DirAccess`、`ResourceLoader`、Dictionary 缓存。
- 来源：TDD 4.2 章。

**具体动作**：

```gdscript
extends Node

var cars: Dictionary = {}
var parts: Dictionary = {}
var sets: Dictionary = {}
var tasks: Dictionary = {}
var banners: Dictionary = {}
var tokens: Dictionary = {}
var buffs: Dictionary = {}
var events: Dictionary = {}
var quests: Dictionary = {}
var minigames: Dictionary = {}

func _ready() -> void:
    _scan_and_cache("res://resources/cars/", cars, "car_id")
    _scan_and_cache("res://resources/parts/", parts, "part_id")
    _scan_and_cache("res://resources/sets/", sets, "set_id")
    _scan_and_cache("res://resources/tasks/", tasks, "step_id")
    _scan_and_cache("res://resources/gacha/", banners, "banner_id")
    _scan_and_cache("res://resources/tokens/", tokens, "token_id")
    _scan_and_cache("res://resources/buffs/", buffs, "buff_id")
    _scan_and_cache("res://resources/events/", events, "event_id")
    _scan_and_cache("res://resources/quests/", quests, "quest_id")
    _scan_and_cache("res://resources/minigames/", minigames, "minigame_id")
    print("[DataRegistry] Initialized. Loaded: %d cars, %d parts, %d sets, %d buffs." % [
        cars.size(), parts.size(), sets.size(), buffs.size()
    ])

func _scan_and_cache(dir_path: String, target_dict: Dictionary, id_field: String) -> void:
    var dir = DirAccess.open(dir_path)
    if dir == null:
        return  # 目录不存在或为空，静默跳过
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
        if file_name.ends_with(".tres") or file_name.ends_with(".res"):
            var resource = ResourceLoader.load(dir_path + file_name)
            if resource and resource.get(id_field) != null:
                var id_value = resource.get(id_field)
                if id_value != "":
                    target_dict[id_value] = resource
        file_name = dir.get_next()
    dir.list_dir_end()

# === 类型安全的 Getter ===
func get_car(id: String) -> CarDefinition:
    return cars.get(id)

func get_part(id: String) -> PartDefinition:
    return parts.get(id)

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
```

**验收标准 (DoD)**：
- 按 F5 运行，控制台输出 `[DataRegistry] Initialized. Loaded: 0 cars, 0 parts, 0 sets, 0 buffs.`（因为 resources 目录下还没有 .tres 文件，计数全为 0，但不崩溃）。
- **关键测试**：在 `res://resources/cars/` 下手动创建一个 `test_car.tres`（类型选 `CarDefinition`，填入 `car_id = "test_car_001"`），重新运行 → 日志显示 `1 cars` → 在任意脚本中调用 `DataRegistry.get_car("test_car_001")` 返回非 null → 验证后删除测试文件。

---

## 7. SaveManager 存档读写系统

### - [ ] 7.1 实现 SaveManager 基础读写逻辑

**技术定位**：
- 修改文件：`res://scripts/core/save_manager.gd`（替换占位内容）
- 涉及技术：`FileAccess`、`JSON`、`Timer`、`notification`。
- 来源：TDD 第 9 章。

**具体动作**：

```gdscript
extends Node

const SAVE_PATH: String = "user://save_data.json"
const AUTO_SAVE_INTERVAL: float = 180.0  # 3 分钟

var _auto_save_timer: Timer
var _save_data: Dictionary = {}

func _ready() -> void:
    _init_auto_save_timer()
    load_game()
    print("[SaveManager] Initialized. Save path: %s" % SAVE_PATH)

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        save_game()  # 退出前强制存档
        get_tree().quit()

# === 公开 API ===

func save_game() -> void:
    _save_data["save_version"] = "1.0"
    _save_data["last_save_timestamp"] = int(Time.get_unix_time_from_system())
    # Phase 2+: 各管理器将自己的数据写入 _save_data
    _save_data["player"] = _collect_player_data()
    _save_data["tokens"] = _collect_token_data()
    _save_data["settings"] = _collect_settings_data()

    var json_string = JSON.stringify(_save_data, "  ")
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()
        SignalBus.save_completed.emit()
        print("[SaveManager] Game saved.")

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        print("[SaveManager] No save file found. Starting fresh.")
        _save_data = _get_default_save_data()
        return

    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        file.close()
        var json = JSON.new()
        var parse_result = json.parse(json_string)
        if parse_result == OK:
            _save_data = json.data
            SignalBus.load_completed.emit()
            print("[SaveManager] Game loaded. Version: %s" % _save_data.get("save_version", "unknown"))
        else:
            push_warning("[SaveManager] Failed to parse save file. Starting fresh.")
            _save_data = _get_default_save_data()

func get_save_data() -> Dictionary:
    return _save_data

func trigger_event_save() -> void:
    save_game()  # 关键事件时调用

# === 内部方法 ===

func _init_auto_save_timer() -> void:
    _auto_save_timer = Timer.new()
    _auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
    _auto_save_timer.autostart = true
    _auto_save_timer.timeout.connect(_on_auto_save)
    add_child(_auto_save_timer)

func _on_auto_save() -> void:
    save_game()
    print("[SaveManager] Auto-save triggered.")

func _get_default_save_data() -> Dictionary:
    return {
        "save_version": "1.0",
        "last_save_timestamp": 0,
        "player": {
            "total_credits": 0,
            "action_points_current": 100.0,
            "player_state": "joker",
            "unlocked_achievements": []
        },
        "tokens": {
            "normal_token": 0,
            "premium_token": 0
        },
        "garage": [],
        "active_task_queue": [],
        "inventory": {
            "uninstalled_parts": [],
            "unidentified_scraps": []
        },
        "quests": {
            "active_urgent_bounties": [],
            "active_restorations": []
        },
        "global_events": {
            "active_event_ids": []
        },
        "gacha_pity": {
            "normal_banner_consecutive_misses": 0,
            "premium_banner_consecutive_misses": 0
        },
        "global_collection_achievements": [],
        "settings": {
            "focus_mode": false,
            "window_position": { "x": 0, "y": 0 },
            "window_scale": 2,
            "sfx_volume": 0.7
        }
    }

func _collect_player_data() -> Dictionary:
    return {
        "total_credits": EconomyManager.get_credits(),
        "action_points_current": 100.0,  # Phase 2: 从 ActionPointPool 读取
        "player_state": "joker",         # Phase 2: 从 PlayerFSM 读取
        "unlocked_achievements": []       # Phase 2
    }

func _collect_token_data() -> Dictionary:
    return TokenManager._tokens.duplicate()

func _collect_settings_data() -> Dictionary:
    return _save_data.get("settings", _get_default_save_data()["settings"])
```

**验收标准 (DoD)**：
- 按 F5 运行 → 控制台输出 `[SaveManager] No save file found. Starting fresh.`（首次运行）。
- 等待 3 分钟或手动调用 `SaveManager.save_game()` → `user://save_data.json` 文件被创建。
- 关闭游戏再重新启动 → 控制台输出 `[SaveManager] Game loaded. Version: 1.0`。
- 打开 `user://save_data.json`（Godot 编辑器 → Open User Data Folder），确认 JSON 结构与 TDD 9.2 章的字段一致。

---

### - [ ] 7.2 实现 SaveManager 数据回灌（Load → Managers）

**技术定位**：
- 修改文件：`res://scripts/core/save_manager.gd`
- 涉及技术：读取 JSON 数据后分发给各管理器。

**具体动作**：
- 在 `load_game()` 成功解析 JSON 后，追加以下数据回灌逻辑：

```gdscript
func _apply_loaded_data() -> void:
    # 回灌资金
    var player_data = _save_data.get("player", {})
    EconomyManager._credits = player_data.get("total_credits", 0)

    # 回灌代币
    var token_data = _save_data.get("tokens", {})
    for token_id in token_data:
        TokenManager._tokens[token_id] = token_data[token_id]

    print("[SaveManager] Data applied to managers.")
```

- 在 `load_game()` 的解析成功分支末尾调用 `_apply_loaded_data()`。

**验收标准 (DoD)**：
- 手动编辑 `user://save_data.json`，将 `total_credits` 设为 `9999`。
- 重新启动游戏 → 调用 `EconomyManager.get_credits()` 返回 `9999`。

---

## 8. 阶段验收：全链路冒烟测试

### - [ ] 8.1 创建临时测试脚本验证全链路

**技术定位**：
- 新建文件：`res://scripts/core/phase1_smoke_test.gd`（临时文件，验收后删除）
- 挂载到主场景 `Main` 节点上。
- 涉及技术：所有 Autoload 单例的跨模块访问。

**具体动作**：
- 创建测试脚本，在 `_ready()` 中按顺序执行以下断言式检查：

```gdscript
extends Node

func _ready() -> void:
    print("=== Phase 1 Smoke Test START ===")

    # 1. 验证所有 Autoload 可访问
    assert(SignalBus != null, "SignalBus is null!")
    assert(DataRegistry != null, "DataRegistry is null!")
    assert(SaveManager != null, "SaveManager is null!")
    assert(EconomyManager != null, "EconomyManager is null!")
    assert(TokenManager != null, "TokenManager is null!")
    assert(BuffManager != null, "BuffManager is null!")
    assert(MainLoopManager != null, "MainLoopManager is null!")
    print("  [PASS] All 7 Autoloads accessible.")

    # 2. 验证 EconomyManager 基础操作
    EconomyManager.add_credits(100)
    assert(EconomyManager.get_credits() == 100, "Credits should be 100!")
    assert(EconomyManager.spend_credits(30) == true, "Spend 30 should succeed!")
    assert(EconomyManager.get_credits() == 70, "Credits should be 70!")
    assert(EconomyManager.spend_credits(999) == false, "Spend 999 should fail!")
    print("  [PASS] EconomyManager credit operations.")

    # 3. 验证 TokenManager 基础操作
    TokenManager.add_tokens("normal_token", 50)
    assert(TokenManager.get_token_count("normal_token") == 50, "Normal tokens should be 50!")
    assert(TokenManager.spend_tokens("normal_token", 20) == true, "Spend 20 should succeed!")
    assert(TokenManager.get_token_count("normal_token") == 30, "Normal tokens should be 30!")
    print("  [PASS] TokenManager token operations.")

    # 4. 验证 BuffManager 默认倍率
    var modifier = BuffManager.get_total_modifier("global", "yield_speed")
    assert(modifier == 1.0, "Default modifier should be 1.0!")
    print("  [PASS] BuffManager default modifier.")

    # 5. 验证 Signal 连通性
    var _signal_received = false
    SignalBus.credits_changed.connect(func(amount): _signal_received = true)
    EconomyManager.add_credits(1)
    assert(_signal_received, "credits_changed signal not received!")
    print("  [PASS] SignalBus cross-module communication.")

    # 6. 验证 SaveManager 读写
    SaveManager.save_game()
    assert(FileAccess.file_exists(SaveManager.SAVE_PATH), "Save file should exist!")
    print("  [PASS] SaveManager write/read cycle.")

    # 7. 验证 DataRegistry（空目录不崩溃）
    var null_car = DataRegistry.get_car("nonexistent_id")
    assert(null_car == null, "Nonexistent car should return null!")
    print("  [PASS] DataRegistry null-safe lookup.")

    print("=== Phase 1 Smoke Test COMPLETE — ALL PASSED ===")
```

**验收标准 (DoD)**：
- 按 F5 运行，控制台输出所有 `[PASS]` 行，最终输出 `ALL PASSED`。
- 无 assert 失败、无脚本报错。
- **测试通过后**：从主场景中移除该脚本节点，将脚本文件删除或移至 `res://scripts/tests/`（不入 main 分支）。

---

### - [ ] 8.2 Phase 1 最终封存

**技术定位**：
- 涉及技术：Git 工作流。
- 来源：TDD 11.1 / 11.2 章。

**具体动作**：
1. 确认所有 Phase 1 任务的 DoD 均已通过。
2. 删除或归档临时测试脚本。
3. 在 `dev` 分支提交最终 Commit：`"feat: Phase 1 complete — foundation layer with all Autoloads, Custom Resources, DataRegistry, SaveManager, MainLoopManager"`。
4. 创建 Pull Request 从 `dev` → `main`。
5. 在 Godot 中最后一次 F5 运行确认无报错后，合并 PR。
6. 在 `main` 分支打 Tag：`v0.1.0-foundation`。

**验收标准 (DoD)**：
- `main` 分支包含完整的 Phase 1 代码。
- GitHub 上存在 `v0.1.0-foundation` Tag。
- 从 `main` 分支 clone 到一台全新的机器上，用 Godot 4.6.2 打开，按 F5 能直接运行，控制台输出所有管理器的初始化日志，无报错。

---

> **Phase 1 完成标志**：项目处于"所有管道已铺设、所有阀门已安装、但还没有通水"的状态。Phase 2 将开始向这些管道中注入业务逻辑——从 TaskManager 的步骤队列推进和 EconomyManager 的挂机收益计算开始。
