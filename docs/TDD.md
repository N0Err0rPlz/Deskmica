# TDD.md — 技术设计文档（Technical Design Document）

**项目代号**：Deskmica
**引擎**：Godot 4.6.2
**语言**：GDScript
**文档版本**：v1.0-FINAL
**最后更新**：2026-04-10

---

> **本文档的定位**
> 这是本项目的"真理之源（Source of Truth）"。所有后续的开发任务清单（Task.md）、Sprint 计划和代码审查，都以本文档为唯一且绝对的基准。文档中不存在任何"待补充"项——所有暂不实现的功能已明确标注为"Out of Scope / V2.0+"并给出了未来启用的技术路径。

> **V1.0 范围声明**
> 本文档描述的所有系统均为 **V1.0（桌面单机版）** 的技术方案。V1.0 的目标是在 Windows / macOS 平台上跑通"桌面悬浮挂机 + 1:64 小车收集改装"的核心循环。以下功能已在本文档中完成技术接口预留，但**明确不在 V1.0 开发范围内**，标注为 V2.0+：
> - 跨平台云存档同步（见第 14 章）
> - 限时活动奖池（见 5.6.2）
> - 活动代币（见 5.6.1）
> - Linux 平台支持（见第 13 章 R-001）
>
> 本文档中所有模块均保留了高拓展性设计（数据驱动 + 接口化），后续版本新增内容/模块时，只需添加数据文件和实现接口，无需修改核心代码。各模块中标注"由 Custom Resource 配置"的数值字段，均可在不改动代码的前提下进行内容扩展。

---

## 目录

1. [架构哲学与铁律](#1-架构哲学与铁律)
2. [技术栈](#2-技术栈)
3. [项目目录结构](#3-项目目录结构)
4. [架构总览：Simulation vs. View](#4-架构总览simulation-vs-view)
   - 4.1 [全局单例注册清单（Autoloads）](#41-全局单例注册清单autoloads)
   - 4.2 [资源注册表与加载策略（DataRegistry）](#42-资源注册表与加载策略dataregistry)
5. [核心系统与模块划分](#5-核心系统与模块划分)
   - 5.1 [实体定义与职能系统](#51-实体定义与职能系统-entity--role-system)
   - 5.2 [任务管理器](#52-任务管理器-taskmanager)
   - 5.3 [动画与渲染模块](#53-动画与渲染模块-animation--rendering)
   - 5.4 [经济系统](#54-经济系统-economy-system)
   - 5.5 [商店模块](#55-商店模块-shop-system)
   - 5.6 [抽卡模块](#56-抽卡模块-gacha-system)
   - 5.7 [套装共鸣系统](#57-套装共鸣系统-set-bonus-system)
   - 5.8 [支线任务模块](#58-支线任务模块-sub-quest-system)
   - 5.9 [全局事件与日程模块](#59-全局事件与日程模块-global-event-system)
   - 5.10 [小游戏模块](#510-小游戏模块-minigame-system)
   - 5.11 [资产增益模块](#511-资产增益模块-buff-system)
6. [交互与界面](#6-交互与界面-uiux)
7. [窗口管理系统](#7-窗口管理系统-window-management)
8. [渲染管线与 Shader](#8-渲染管线与-shader)
9. [数据结构与存储](#9-数据结构与存储-data--save-system)
10. [性能红线与技术约束](#10-性能红线与技术约束)
11. [项目管理与版本容灾](#11-项目管理与版本容灾)
12. [硬件要求](#12-硬件要求)
13. [技术风险登记表](#13-技术风险登记表)
14. [跨平台同步策略（V2.0+ / Out of Scope）](#14-跨平台同步策略v20-out-of-scope)

---

## 1. 架构哲学与铁律

本项目的所有技术决策必须服从以下五条不可违背的原则。当任何设计出现冲突时，按此优先级裁决：

### 铁律 1：引擎纯洁性（Godot Native）

- 所有事件驱动 → Godot `Signals`（信号）。
- 所有外部数据配置 → `Custom Resources`（自定义资源）或 JSON 文件。
- 执行顺序统筹 → `_process` / `_physics_process`，由 `MainLoopManager` 集中分发。
- **禁止引入任何 Unity / Unreal 生态的思维、术语或插件方案。**

### 铁律 2：极简功耗（Performance First）

- 常规模式内存 ≤ 200MB，专注模式 ≤ 100MB。
- CPU 峰值 < 2%（基准：Intel i5 / AMD Ryzen 5 级别多核处理器后台运行）。
- 常规模式锁 30FPS，专注模式锁 10-15FPS。
- 一切特效必须走**对象池（Object Pooling）**。
- 存档 I/O 频率 ≤ 每 3 分钟一次，或仅在关键事件时触发。

### 铁律 3：终极解耦（Simulation vs. View）

- **模拟层（Simulation / Data）**：纯数据推演，完全不知道画面的存在。即使隐藏所有图层，挂机收益仍精准计算。
- **视图层（View）**：监听模拟层发出的 Signal，播放对应的动画/特效。可以随时替换全部美术资产而不影响任何逻辑代码。
- 两层之间通过 Signal 单向通信（Simulation → View），视图层**绝不反向修改**模拟层数据。

### 铁律 4：数据驱动（Data-Driven Design）

- **禁止在脚本中硬编码任何数值**（速度、价格、概率、冷却时间等）。
- 所有可变数据存放于 Custom Resource 或 JSON 配置文件中。
- 新增内容（新车型、新品牌套件、新支线任务类型）只需添加数据文件，不改动核心代码。

### 铁律 5：组合优于继承（Composition over Inheritance）

- 实体（Entity）为白板节点，功能通过挂载**组件（Component）**实现。
- 组件之间通过 Signal 或接口通信，互不持有引用。
- 禁止构建超过 2 层深度的继承链。

---

## 2. 技术栈

| 类别 | 工具 | 备注 |
|------|------|------|
| 游戏引擎 | Godot 4.6.2 | 2D、无边框、置顶、侵入式窗口 |
| 编程语言 | GDScript | Godot 原生，新手友好 |
| AI 辅助编程 | VS Code + Claude Code | Vibe Coding 工作流 |
| 2D 像素美术 | Aseprite | 绘制 + 动画制作 |
| 音效生成 | Bfxr | 复古电子音效 |
| 版本管理 | GitHub | 双分支策略（main / dev） |

---

## 3. 项目目录结构

```
res://
├── scenes/                    # 场景文件 (.tscn)
│   ├── main/                  # 主场景（车库/工坊）
│   ├── ui/                    # UI 场景（商店面板、抽卡面板等）
│   └── minigames/             # 小游戏 UI 覆盖层场景
├── scripts/                   # GDScript 脚本
│   ├── core/                  # 核心管理器（MainLoopManager、SaveManager 等）
│   ├── simulation/            # 模拟层（TaskManager、EconomyManager 等）
│   ├── view/                  # 视图层（动画控制器、VFX 池等）
│   ├── entities/              # 实体与组件
│   │   ├── components/        # 可挂载组件（MovementComp、WorkComp 等）
│   │   └── fsm/               # 有限状态机基类与状态定义
│   ├── systems/               # 独立系统（GachaSystem、ShopSystem 等）
│   ├── ui/                    # UI 逻辑脚本
│   └── utils/                 # 工具类（ObjectPool、MathHelper 等）
├── resources/                 # Custom Resource 数据文件 (.tres)
│   ├── cars/                  # 车型定义
│   ├── parts/                 # 配件定义
│   ├── sets/                  # 套装共鸣定义
│   ├── tasks/                 # 任务步骤定义
│   ├── gacha/                 # 奖池与概率表定义
│   ├── quests/                # 支线任务定义
│   ├── tokens/                # 代币类型定义
│   ├── events/                # 全局事件定义
│   ├── minigames/             # 小游戏配置定义
│   └── buffs/                 # Buff 定义
├── assets/                    # 美术与音频资产（独立管理）
│   ├── sprites/               # Aseprite 导出的 .png 贴图
│   ├── animations/            # .json 动画配置
│   ├── shaders/               # .gdshader 着色器文件
│   └── sfx/                   # Bfxr 导出的音效文件
├── data/                      # 外部 JSON 数据文件（平衡性数值表等）
└── addons/                    # 第三方插件（如有）
```

**规范**：`assets/` 文件夹的版本提交必须与 `scripts/` 分开（详见第 11 章）。

---

## 4. 架构总览：Simulation vs. View

```
┌─────────────────────────────────────────────────────────┐
│                    MainLoopManager                       │
│         (_process 集中调度所有子系统更新)                    │
│                                                         │
│  ┌─────────────── Simulation Layer ──────────────┐      │
│  │  TaskManager    EconomyManager   QuestManager │      │
│  │  GachaSystem    SetBonusCalc     EventManager │      │
│  │  BusinessManager  TokenManager   BuffManager  │      │
│  │  MiniGameManager                              │      │
│  └───────────────────┬───────────────────────────┘      │
│                      │ Signals（单向）                    │
│  ┌───────────────────▼───────────────────────────┐      │
│  │              View Layer                        │      │
│  │  EntityAnimator   VFXPool   UIController      │      │
│  │  ShaderManager    SFXPlayer                   │      │
│  └───────────────────────────────────────────────┘      │
│                                                         │
│  ┌─────────────── Persistence ───────────────────┐      │
│  │  SaveManager (JSON, ≤ 1次/3分钟)              │      │
│  └───────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

**MainLoopManager**（`Autoload` 单例）：

- 在 `_process(delta)` 中按**严格固定顺序**依次调用各子系统的 `update(delta)` 方法。
- 调用顺序：`EconomyManager` → `TaskManager` → `QuestManager` → `EventManager` → `BusinessManager` → `BuffManager` → `MiniGameManager` → `GachaSystem`（按需） → `TokenManager`（按需） → `SetBonusCalc`（按需）。
- 视图层的更新由各自节点的 `_process` 响应 Signal 自行处理（不经过 MainLoopManager）。

### 4.1 全局单例注册清单（Autoloads）

以下节点**必须**在 Godot 项目设置（Project Settings → Autoload）中注册为全局单例。AI 辅助编程时，任何管理器如果出现在此清单中，**禁止**作为普通子节点挂载到场景树上。

| 注册名 | 脚本路径 | 职责 |
|--------|----------|------|
| `MainLoopManager` | `res://scripts/core/main_loop_manager.gd` | 集中调度所有模拟层子系统的 `update(delta)` |
| `SignalBus` | `res://scripts/core/signal_bus.gd` | 集中定义所有跨模块的全局 Signal。其他模块连接信号时只引用 `SignalBus`，禁止模块之间互相 `get_node()` |
| `SaveManager` | `res://scripts/core/save_manager.gd` | 统一管理存档的读写、自动保存计时、关键事件触发保存 |
| `EconomyManager` | `res://scripts/simulation/economy_manager.gd` | 管理资金的增减与全局经济系数计算 |
| `TokenManager` | `res://scripts/simulation/token_manager.gd` | 管理所有代币类型的增减、兑换与上限校验 |
| `BuffManager` | `res://scripts/simulation/buff_manager.gd` | 管理所有 Buff 的注册、过期、叠加计算与查询 |
| `DataRegistry` | `res://scripts/core/data_registry.gd` | 启动时统一预加载并缓存所有 Custom Resource（见 4.2） |

**SignalBus 示例结构**：

```gdscript
# signal_bus.gd — 所有跨模块的全局信号集中定义于此
extends Node

signal car_delivered(car_id: String, sell_price: int)
signal kit_purchased(car_id: String, kit_id: String)
signal step_completed(car_id: String, step_data: Resource)
signal kit_installed(car_id: String, kit_id: String)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal minigame_reward(reward_data: Dictionary)
signal parts_changed(car_id: String)
# ... 按需扩展，新增信号只需在此文件追加一行
```

### 4.2 资源注册表与加载策略（DataRegistry）

游戏中存在大量 Custom Resource 文件（车辆、配件、套装、任务、奖池等）。为防止在业务逻辑脚本中零散使用 `load()` / `preload()` 导致路径硬编码和管理混乱，必须遵守以下规范：

**规则**：所有 Custom Resource 在游戏启动时，由 `DataRegistry`（Autoload 单例）统一扫描 `res://resources/` 目录，预加载并缓存为 Dictionary（以 `item_id` 为 Key）。各模块通过 ID 向 `DataRegistry` 索要数据，**严禁在业务逻辑中零散使用 `load()` 或 `preload()`**。

```gdscript
# data_registry.gd — 统一资源注册表
extends Node

var cars: Dictionary = {}      # { "bmw_e30": CarDefinition, ... }
var parts: Dictionary = {}     # { "rwb_front_v1": PartDefinition, ... }
var sets: Dictionary = {}      # { "rwb_full": SetDefinition, ... }
var tasks: Dictionary = {}     # { "weld_widebody": TaskStepData, ... }
var banners: Dictionary = {}   # { "normal_permanent": BannerDefinition, ... }
var tokens: Dictionary = {}    # { "normal_token": TokenDefinition, ... }
var buffs: Dictionary = {}     # { "spoiler_yield_boost": BuffDefinition, ... }
var events: Dictionary = {}    # { "race_weekend_q3": EventDefinition, ... }
var quests: Dictionary = {}    # { "ub_template_001": QuestData, ... }
var minigames: Dictionary = {} # { "precision_welding_qte": MiniGameConfig, ... }

func _ready():
    _scan_and_cache("res://resources/cars/", cars, "car_id")
    _scan_and_cache("res://resources/parts/", parts, "part_id")
    # ... 对每个子目录重复

func get_car(id: String) -> CarDefinition:
    return cars.get(id)

func get_part(id: String) -> PartDefinition:
    return parts.get(id)

# ... 各类型的 getter
```

**好处**：新增一辆车或一个配件，只需在 `res://resources/` 对应目录下放入 `.tres` 文件，`DataRegistry` 启动时自动发现和注册，无需修改任何代码。

---

## 5. 核心系统与模块划分

### 5.1 实体定义与职能系统 (Entity & Role System)

#### 5.1.1 NPC 技师（Mechanic Entity）

| 属性 | 说明 |
|------|------|
| 底层类 | 唯一通用类 `MechanicEntity`（白板 Node2D） |
| 差异化方式 | 注入不同的 `SpecialtyData`（Custom Resource） |
| 组件挂载 | `MovementComponent`、`WorkComponent`、`AnimationComponent` |
| 专精逻辑 | 所有技师可执行所有任务类型。当任务的 `task_tag` 与技师的 `specialty_tag` 匹配时，触发 `efficiency_multiplier`（效率倍率，具体数值由 Resource 配置） |
| 数量上限 | 同屏活动工人 < 5（性能红线） |

**SpecialtyData（Custom Resource）结构**：

```
SpecialtyData.tres:
  specialty_id: String           # "chassis_expert" / "paint_expert" / ...
  specialty_tag: String          # 匹配 TaskStepData 的 task_tag
  display_name: String           # 展示名称
  efficiency_multiplier: float   # 专精匹配时的效率倍率（如 1.5）
  sprite_palette_id: String      # 关联调色盘 Shader 参数
  # [预留拓展] 未来可增加 ability_stats 等字段
```

**拓展性保证**：新增"电车改装专家"只需新建一个 `SpecialtyData.tres` 文件，设置 `specialty_tag = "ev_specialist"`，零代码改动。

#### 5.1.2 玩家主理人（Player Entity）

主理人拥有独立的高级有限状态机 `PlayerFSM`，包含两个**互斥**核心状态：

**状态 A：改装状态 / 全能补位（The Joker）**

- 挂载 `AuraComponent`（光环组件）。当主理人在工坊场景中处于此状态时，通过 Signal 通知 `TaskManager` 将当前所有 NPC 的 `progress_speed_multiplier` 临时调高。
- 作为触发小游戏（QTE）的**唯一媒介**。改装过程中的阶段性小游戏只有在主理人处于改装状态时才会弹出提示。

**状态 B：主理状态 / 外勤与声望（Business & Outreach）**

- 进入此状态时，主理人实体在屏幕上隐藏（`visible = false`），停止动画更新（`set_process(false)`），彻底释放渲染性能。
- 后台 `BusinessManager` 开始计时演算，负责：
  - 寻找报废车（触发 RNG 生成车辆实例）
  - 提升曝光度（修改全局流量系数）
  - 参与车展（数值比对演算）
- 外勤结果通过系统级气泡通知或侧边悬浮极简 UI 的文本播报向玩家汇报。

#### 5.1.3 资源调度池（Action Point System）

- 引入全局 `ActionPointPool` 资源。主理人处于任一状态时持续消耗 `action_points`。
- 数值耗尽后必须等待恢复（恢复速率由 `ActionPointConfig` Custom Resource 配置）。
- **设计目的**：强制玩家在"加速造车"和"拓展商路"之间做策略抉择。

```
ActionPointConfig.tres:
  max_points: float
  regen_rate_per_second: float
  joker_drain_rate: float        # 改装状态消耗速率
  business_drain_rate: float     # 外勤状态消耗速率
```

---

### 5.2 任务管理器 (TaskManager)

**定位**：模拟层核心。负责将玩家购买的改装套件拆解为有顺序的"步骤队列（Queue）"，进行倒计时并派发指令。完全不知道画面的存在。

**工作流程**：

1. 玩家购买改装套件 → `ShopSystem` 发出 `Signal: kit_purchased(car_id, kit_id)`
2. `TaskManager` 接收信号 → 查询 `KitDefinition` Resource → 将其拆解为有序的 `TaskStepData` 数组并入队
3. 每帧由 `MainLoopManager` 调用 `TaskManager.update(delta)` → 推进当前步骤倒计时
4. 步骤完成 → 发出 `Signal: step_completed(car_id, step_data)` → 视图层响应播放动画
5. 整套完成 → 发出 `Signal: kit_installed(car_id, kit_id)` → 触发 `SetBonusCalculator` 重新评估

**TaskStepData（Custom Resource）结构**：

```
TaskStepData.tres:
  step_id: String               # "remove_stock_bumper" / "weld_widebody" / ...
  task_tag: String               # 用于匹配技师专精（如 "bodywork"、"paint"）
  base_duration_seconds: float   # 基础耗时（受 Buff 影响）
  animation_key: String          # 视图层用于播放对应动画的 Key
  vfx_key: String                # 视图层用于触发对应特效的 Key
  minigame_eligible: bool        # 该步骤是否可触发小游戏加速
  minigame_config_id: String     # 关联的小游戏配置 ID（如有）
```

---

### 5.3 动画与渲染模块 (Animation & Rendering)

#### 5.3.1 分层渲染架构

每个可视实体（NPC 技师 / 车辆）由 3-4 个独立的 `Sprite2D` 节点在同一坐标下按 Z-index 叠加：

| 图层 | 节点 | 职责 | 动画类型 |
|------|------|------|----------|
| 底盘层（Chassis） | `Sprite2D` | 负责移动表现 | `Idle` / `Move` 循环 |
| 躯干层（Torso） | `Sprite2D` | NPC 主体 | 轻微上下浮动（呼吸感） |
| 动作层（Work） | `Sprite2D` | 当前任务动作 | 根据 `animation_key` 切换 |
| 特效层（VFX） | `Sprite2D` / 粒子 | 火花、灰尘等 | 由对象池管理 |

**动画同步示例**（以"焊接宽体"步骤为例）：

当 `TaskManager` 发出 `Signal: step_started(car_id, step_data)` 且 `step_data.animation_key == "welding"` 时，视图层的 `EntityAnimator` 同时向各图层发送指令：

- 底盘层 → 播放 `Idle`
- 动作层 → 播放 `Welding_Action`
- 特效层 → 在动画第 3 帧触发 `Spark` 粒子（从对象池取出）

#### 5.3.2 特效对象池（VFX Object Pool）

- 所有运行时特效（火花、金币飘字 "+10$"、灰尘）**禁止**动态 `instantiate()` / `queue_free()`。
- 启动时预创建固定数量的特效实例（上限 < 50），存入 `VFXPool`。
- 使用时从池中取出（`set_visible(true)`），使用完毕归还（`set_visible(false)` + 重置状态）。

```gdscript
# VFXPool 伪代码结构
class_name VFXPool
var _pools: Dictionary = {}  # { "spark": [Node2D, ...], "coin_text": [...] }

func get_effect(effect_type: String) -> Node2D
func return_effect(effect: Node2D) -> void
```

#### 5.3.3 专注模式对动画的影响

- 工人停止走动（`MovementComponent.set_active(false)`）
- 所有特效关闭（`VFXPool.disable_all()`）
- 仅保留车辆静态 Sprite 和极简进度条
- 帧率降至 10-15 FPS（通过 `Engine.max_fps` 设置）

---

### 5.4 经济系统 (Economy System)

统一管理所有资源的产出与消耗。此模块合并了原文档中分散的"资源产出模块"和"资源消耗模块"。

#### 5.4.1 资源产出

| 产出类型 | 机制 | 计算公式（伪） |
|----------|------|---------------|
| 基础挂机收益 | 每辆停放车辆按素车价值产出 | `yield = base_value × time_delta × global_modifier` |
| 改装增益 | 已安装配件提供产出倍率 Buff | 叠加至 `global_modifier` |
| 品牌共鸣 | 套装激活额外倍率 | 叠加至 `global_modifier`（见 5.7） |
| 支线委托 | 完成支线获取即时资金/代币 | 固定值（由 QuestData 定义） |
| 车辆交付 | 卖出改装车获取即时大额资金 | `sell_price = base_value + Σ(part_value) × condition_multiplier` |

#### 5.4.2 资源消耗

| 消耗类型 | 用途 |
|----------|------|
| 资金（Credits） | 购买素车、改装套件、耗材 |
| 时间 | 改装的核心成本，越高级套件耗时越长 |
| 行动点数 | 主理人状态切换消耗（见 5.1.3） |
| 抽卡代币 | 抽卡消耗（见 5.6） |

#### 5.4.3 离线收益计算

- 存档中记录 `last_save_timestamp`（Unix 时间戳）。
- 游戏启动时，计算 `offline_duration = current_time - last_save_timestamp`。
- 基于 `offline_duration` 和当前车库状态计算离线期间的被动收益。
- **注意**：离线收益仅计算被动挂机产出，不推进任务队列（任务队列需要在线时间）。

---

### 5.5 商店模块 (Shop System)

包含三个子页签，共用同一套 UI 框架：

| 子页签 | 功能 | 数据源 |
|--------|------|--------|
| 车市（Car Dealership） | 购买基础素车 | `CarDefinition.tres` |
| 改装件库（Parts Catalog） | 购买改装套件 | `PartDefinition.tres` / `KitDefinition.tres` |
| 耗材商店（Consumables） | 购买加速道具 | `ConsumableDefinition.tres` |

**购买流程**：
1. 玩家点击购买 → `ShopSystem` 检查 `EconomyManager.credits >= price`
2. 扣款 → 发出 `Signal: item_purchased(item_type, item_id)`
3. 对应管理器响应：车辆 → 加入车库清单；套件 → 进入 `TaskManager` 拆解为步骤队列；耗材 → 立即应用 Buff

---

### 5.6 抽卡模块 (Gacha System)

#### 5.6.1 代币管理器（TokenManager）

独立的代币管理中枢。所有代币的增减**只能**通过 `TokenManager` 执行，其他模块仅通过 Signal 请求变动。

**代币类型定义（Custom Resource）**：

```
TokenDefinition.tres:
  token_id: String               # "normal_token" / "premium_token"
  display_name: String
  icon_path: String
  max_stack: int                 # 持有上限（-1 = 无上限）
  exchange_target_id: String     # 可兑换的目标代币 ID（"" = 不可兑换）
  exchange_rate: float           # 兑换比率（如 10:1 则填 10.0）
  exchange_cap_per_cycle: int    # 每周期兑换上限（防止经济崩溃）
  exchange_cycle_hours: float    # 兑换周期长度（小时）
```

**代币来源（通过 Signal 接入）**：
- 交付车辆 → `Signal: car_delivered` → TokenManager 增加代币
- 完成紧急订单 → `Signal: quest_completed` → TokenManager 增加代币
- 小游戏掉落（UI 入口） → `Signal: minigame_reward` → TokenManager 增加代币
- 在线时长累计 → `MainLoopManager` 内部计时器 → 达到阈值时 Signal 通知 TokenManager

**V1.0 代币种类**：
- **普通代币（Normal Token）**：抽普通常驻池
- **高级代币（Premium Token）**：抽高级常驻池

**拓展性**：未来增加"活动代币"只需新建 `TokenDefinition.tres`，零代码改动。代币间兑换逻辑已内置但数值后期调整。

#### 5.6.2 奖池系统（Banner System）

**奖池定义（Custom Resource）**：

```
BannerDefinition.tres:
  banner_id: String              # "normal_permanent" / "premium_permanent"
  banner_type: String            # "permanent" / "limited"（limited 为 V2.0+）
  required_token_id: String      # 消耗哪种代币
  cost_per_pull: int             # 单抽消耗量（数值后期调整）
  cost_per_multi: int            # 十连消耗量（数值后期调整）
  loot_table_id: String          # 关联战利品表
  pity_config_id: String         # 关联保底配置
```

**战利品表（Custom Resource）**：

```
LootTable.tres:
  table_id: String
  entries: Array[LootEntry]
    LootEntry:
      item_id: String            # 物品 ID
      item_type: String          # "part" / "paint" / "scrap" / "credits"
      rarity_tag: String         # "common" / "rare" / "epic" / "legendary"
      weight: float              # 概率权重（具体数值后期调整）
```

#### 5.6.3 保底机制（PityCalculator）

统一组件，通过配置切换模式：

```
PityConfig.tres:
  pity_mode: String              # "soft" / "hard"
  # 软保底参数（普通池使用）
  soft_pity_start: int           # 从第 N 抽开始递增概率
  soft_pity_increment: float     # 每抽递增量
  # 硬保底参数（高级池使用）
  hard_pity_threshold: int       # 第 N 抽必出保底
  guaranteed_rarity: String      # 保底物品的最低稀有度
```

**算法伪代码**：

```
func calculate_adjusted_probability(base_prob, consecutive_misses, config):
    if config.pity_mode == "hard":
        if consecutive_misses >= config.hard_pity_threshold:
            return 1.0  # 必出
        return base_prob
    elif config.pity_mode == "soft":
        if consecutive_misses >= config.soft_pity_start:
            bonus = (consecutive_misses - config.soft_pity_start) * config.soft_pity_increment
            return min(base_prob + bonus, 1.0)
        return base_prob
```

**V1.0 奖池配置**：
- 普通常驻池 → 使用普通代币 → 软保底
- 高级常驻池 → 使用高级代币 → 硬保底
- 限时活动池 → **Out of Scope / V2.0+**（技术接口已预留：`banner_type = "limited"` + 活动代币）

---

### 5.7 套装共鸣系统 (Set Bonus System)

采用类似自走棋"羁绊"机制，按安装件数分梯度激活 Buff。

#### 5.7.1 套装定义（Custom Resource）

```
SetDefinition.tres:
  set_id: String                 # "rwb_full" / "bbs_wheel_set"
  brand: String                  # "RWB" / "BBS" / "Mansory"
  required_part_ids: Array[String]   # 该套装包含的所有配件 ID
  thresholds: Array[SetThreshold]
    SetThreshold:
      required_count: int        # 需要安装的件数（如 3）
      buff_id: String            # 激活的 Buff ID（关联 BuffDefinition）
```

**示例**：RWB 套装共 7 件（前包围、后包围、侧裙、尾翼、轮毂、引擎盖、迎宾灯），阈值为 3 件 / 5 件 / 7 件，分别激活三档 Buff。

#### 5.7.2 SetBonusCalculator

分两个独立子模块：

**PerCarEvaluator（单车羁绊判定）**：
- 触发时机：每次安装/卸载配件时
- 逻辑：扫描该车的 `equipped_parts`，按品牌分组计数，对照 `SetDefinition` 的阈值表判定激活到哪一档
- 效果：Buff 仅作用于该车自身

**GlobalCollectionEvaluator（全局收藏成就判定）**：
- 触发时机：每次车库数据变动时（购入/卖出车辆、安装/卸载配件）
- 逻辑：扫描整个车库，统计满足条件的车辆数量（如"拥有 3 辆装备了 RWB 套件的车辆"）
- 效果：激活全局 Buff，作用于整个车库或玩家经济系数

**多品牌并行**：一辆车上可同时激活多个品牌的部分羁绊。BBS 轮毂触发 BBS 两件套效果，同时 RWB 包围触发 RWB 三件套效果，互不干扰。

**Buff 叠加规则**：套装 Buff 与散件 Buff 的叠加方式（加法/乘法/替换）**由 BuffDefinition 中的 `stack_mode` 字段定义**，留给后期数值调整阶段决定。

---

### 5.8 支线任务模块 (Sub-Quest System)

采用数据驱动与接口化设计。所有支线任务继承自同一个基础结构 `BaseQuest`，`QuestManager` 通过统一接口调度。

#### 5.8.1 BaseQuest 接口

```gdscript
class_name BaseQuest extends Resource

# 由子类实现
func check_trigger_condition(game_state: Dictionary) -> bool
func get_requirements() -> QuestRequirements
func calculate_rewards() -> QuestRewards
func is_expired() -> bool
```

#### 5.8.2 V1.0 支线类型

**紧急订单（Urgent Bounties）**：

```
UrgentBountyData.tres:
  quest_id: String
  quest_type: "urgent_bounty"
  trigger_probability: float     # 每检查周期的触发概率
  trigger_cooldown_seconds: float
  time_limit_seconds: float      # 限时
  required_car_tag: String       # 要求的车型标签
  required_part_ids: Array[String]  # 要求安装的配件
  reward_credits: int
  reward_token_id: String
  reward_token_amount: int
```

**废件修复（Scrap Restoration）**：

```
ScrapRestorationData.tres:
  quest_id: String
  quest_type: "scrap_restoration"
  trigger_condition: "manual"    # 手动触发（玩家将废件放入工作台）
  repair_cost_credits: int
  repair_duration_seconds: float
  result_loot_table_id: String   # 修复结果的战利品表
```

**拓展性保证**：未来新增支线玩法（如"竞速挑战"）只需新建一个继承 `BaseQuest` 的脚本 + 对应的 `QuestData` Resource，`QuestManager` 通过接口自动识别和调度。

---

### 5.9 全局事件与日程模块 (Global Event System)

**EventManager** 读取本地系统时间（`Time.get_datetime_dict_from_system()`），对照事件配置表判定当前是否有活动事件。

```
EventDefinition.tres:
  event_id: String               # "race_weekend_q3"
  event_name: String
  start_time: Dictionary         # { month: 7, day: 15, hour: 0 }
  end_time: Dictionary           # { month: 7, day: 17, hour: 23 }
  recurrence: String             # "once" / "weekly" / "monthly" / "yearly"
  modifiers: Array[EventModifier]
    EventModifier:
      target_tag: String         # 影响哪些品牌/车型（"" = 全局）
      modifier_type: String      # "task_speed" / "sell_multiplier" / "yield_multiplier"
      modifier_value: float      # 倍率值
```

---

### 5.10 小游戏模块 (MiniGame System)

#### 5.10.1 架构定位

小游戏与主理人 QTE 为**同一套底层系统**，通过不同入口和配置调用不同的玩法组件。

#### 5.10.2 双入口设计

| 入口 | 触发方式 | 调用的组件 | 奖励类型 |
|------|----------|-----------|----------|
| 画面触发 | 改装过程中弹出阶段性提示（仅主理人处于改装状态时） | 与当前改装步骤相关的小游戏组件 | 加速当前改装进度 |
| UI 菜单触发 | 玩家从 Dock 栏主动点击进入 | 独立小游戏组件 | 可能包含稀有改装零件 |

两种入口作为**不同的接口**调用 `MiniGameManager`：

```gdscript
# 画面触发（绑定当前任务步骤）
MiniGameManager.start_contextual(task_step_data: TaskStepData)

# UI 菜单触发（独立小游戏）
MiniGameManager.start_standalone(minigame_config_id: String)
```

#### 5.10.3 技术规格

- **呈现方式**：一律使用 UI 覆盖层（`Control` 节点树），**不切换场景**。主循环在小游戏期间**继续运行**。
- **帧率**：渲染保持 30FPS 锁定。按键输入检测写在 `_physics_process`（默认 60Hz）以保证响应精度。
- **节奏**：单局时长为快节奏（目标 5-15 秒），具体由 `MiniGameConfig` 定义。
- **冷却机制**：存在冷却时间，冷却长度根据改装阶段不同而不同（由 `TaskStepData` 或 `MiniGameConfig` 配置）。无次数上限。

#### 5.10.4 MiniGameConfig（Custom Resource）

```
MiniGameConfig.tres:
  minigame_id: String            # "precision_welding_qte"
  minigame_type: String          # "qte_timing" / "qte_sequence" / ... (可拓展)
  scene_path: String             # UI 覆盖层场景路径
  duration_seconds: float        # 单局时长上限
  cooldown_seconds: float        # 冷却时间
  # 画面触发入口的奖励
  contextual_speed_bonus: float  # 加速当前步骤的百分比
  # UI 菜单入口的奖励
  standalone_loot_table_id: String  # 关联战利品表
```

#### 5.10.5 BaseMiniGame 接口

```gdscript
class_name BaseMiniGame extends Control

signal minigame_completed(result: Dictionary)
signal minigame_cancelled

func initialize(config: MiniGameConfig) -> void
func start_game() -> void
func _physics_process(delta):  # 输入检测在此处理
```

**拓展性保证**：新增小游戏玩法只需新建一个继承 `BaseMiniGame` 的场景/脚本 + 对应的 `MiniGameConfig.tres`，零底层改动。具体小游戏的玩法内容（如"节奏拧螺丝"、"精密切割 QTE"）由游戏设计文档定义，TDD 仅规范技术框架。

---

### 5.11 资产增益模块 (Buff System)

统一管理所有 Buff 的注册、计算与分发。

```
BuffDefinition.tres:
  buff_id: String                # "spoiler_yield_boost"
  source_type: String            # "part" / "set_bonus" / "consumable" / "event" / "aura"
  target: String                 # "per_car" / "global"
  modifier_type: String          # "yield_speed" / "task_speed" / "sell_multiplier"
  modifier_value: float          # 数值（后期调整）
  stack_mode: String             # "additive" / "multiplicative" / "replace"（后期调整）
  duration_seconds: float        # -1 = 永久（配件/套装），>0 = 临时（耗材/事件）
```

`BuffManager` 负责：
1. 注册新 Buff（来自配件安装、套装激活、耗材使用、事件触发、主理人光环）
2. 每帧更新临时 Buff 的剩余时间，过期后自动移除
3. 提供 `get_total_modifier(target, modifier_type)` 供其他系统查询当前叠加后的总倍率

---

## 6. 交互与界面 (UI/UX)

### 6.1 设计原则

**隐形与沉浸（Invisible until needed）**。游戏窗口固定在屏幕底部或边缘，UI 元素在默认状态下完全隐藏或保持极高透明度。

### 6.2 触发机制（Hover Activation）

- 鼠标移入游戏窗口 → 背景增加半透明黑色遮罩 → 主菜单和状态栏平滑浮现（`Tween` 动画）。
- 鼠标移出后 **1.5 秒** → UI 自动淡出 → 恢复"纯净车库"观赏模式。
- 检测方式：`mouse_entered` / `mouse_exited` Signal + 1.5 秒 `Timer`。

### 6.3 区域划分

| 区域 | 位置 | 内容 |
|------|------|------|
| 状态信息区 | 左侧 | 总资金、全局事件 Buff 图标、特殊代币数量 |
| 核心操作区 | 正中 | 悬浮 Dock 栏：【商店/抽卡】【车库/仓库】【改装面板】 |
| 系统与支线区 | 右侧 | 【支线/订单面板】（有新订单时红点提示）、【设置】 |
| 防误触区 | 右上角绝对边缘 | 【最小化】【退出游戏】 |

### 6.4 专注模式（Focus Mode）

通过【设置】或快捷键一键切换：

| 项目 | 常规模式 | 专注模式 |
|------|----------|----------|
| FPS | 30 | 10-15 |
| 工人 | 正常走动 | 停止走动 |
| 特效 | 全部开启 | 全部关闭 |
| UI 悬浮响应 | 正常 | 锁定不响应 |
| 进度条 | 正常 | 仅保留极简提示 |
| 目标内存 | ≤ 200MB | ≤ 100MB |

---

## 7. 窗口管理系统 (Window Management)

Godot 4 通过 `DisplayServer` API **原生支持**无边框置顶窗口，无需调用底层操作系统 API。

### 7.1 核心 API 调用

```gdscript
# 启动时设置
DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)

# 不抢夺系统输入焦点
DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)

# 透明背景
get_window().transparent = true
get_window().transparent_bg = true
```

### 7.2 窗口定位与缩放

- 窗口默认定位于屏幕底部中央。位置可通过拖拽调整，存入存档。
- 视口高度/宽度上限不超过屏幕分辨率的 **1/4**。
- 缩放比例**必须为整数倍**（1x, 2x, 3x），防止像素画模糊。通过 `Viewport.canvas_transform` 控制。

### 7.3 多显示器兼容

- 使用 `DisplayServer.get_screen_count()` 和 `DisplayServer.screen_get_position()` 检测多显示器环境。
- 窗口拖拽时自动对齐到最近的屏幕边缘（Snap to Edge）。

---

## 8. 渲染管线与 Shader

### 8.1 调色盘替换 Shader

使用 **Godot Shading Language**（基于 GLSL 语法）编写，实现"灰度图 + 目标颜色映射"：

```gdshader
shader_type canvas_item;

uniform sampler2D mask_texture;      // 灰度遮罩图
uniform vec4 target_color : source_color = vec4(1.0);  // 目标颜色
uniform sampler2D highlight_texture; // 高光层（可选）

void fragment() {
    float gray = texture(mask_texture, UV).r;           // 1. 采样灰度值
    vec4 base = vec4(target_color.rgb * gray, 1.0);     // 2. 正片叠底
    float highlight = texture(highlight_texture, UV).r;  // 3. 叠加高光
    COLOR = base + vec4(vec3(highlight), 0.0);
}
```

**用途**：同一种 NPC 底盘灰度图，通过更换 `target_color` uniform 参数，运行时渲染为不同颜色。大幅减少美术资产数量。

---

## 9. 数据结构与存储 (Data & Save System)

### 9.1 存档格式

本地 JSON 文件，路径：`user://save_data.json`

### 9.2 完整存档字段

```json
{
  "save_version": "1.0",
  "last_save_timestamp": 1712700000,

  "player": {
    "total_credits": 15000,
    "action_points_current": 80.0,
    "player_state": "joker",
    "unlocked_achievements": ["first_car", "first_delivery"]
  },

  "tokens": {
    "normal_token": 120,
    "premium_token": 5
  },

  "garage": [
    {
      "car_id": "bmw_e30",
      "current_value": 25000,
      "equipped_parts": {
        "front_bumper": "rwb_front_v1",
        "rear_bumper": "rwb_rear_v1",
        "side_skirt": null,
        "spoiler": "carbon_wing_generic",
        "wheels": "bbs_rs_17",
        "hood": null,
        "extras": []
      },
      "active_set_bonuses": [
        { "set_id": "rwb_full", "active_tier": 1 }
      ],
      "per_car_buffs": ["rwb_tier1_yield_boost"]
    }
  ],

  "active_task_queue": [
    {
      "car_id": "bmw_e30",
      "kit_id": "rwb_widebody_kit",
      "current_step_index": 2,
      "remaining_seconds": 342.5,
      "assigned_mechanic_id": "mech_01"
    }
  ],

  "inventory": {
    "uninstalled_parts": ["vintage_wheel_001", "rare_paint_midnight"],
    "unidentified_scraps": ["scrap_003"]
  },

  "quests": {
    "active_urgent_bounties": [
      {
        "quest_id": "ub_20260410_001",
        "remaining_seconds": 3600,
        "requirements": { "car_tag": "bmw", "required_parts": ["carbon_spoiler"] }
      }
    ],
    "active_restorations": [
      {
        "quest_id": "sr_scrap_003",
        "remaining_seconds": 120.0
      }
    ]
  },

  "global_events": {
    "active_event_ids": ["race_weekend_q3"]
  },

  "gacha_pity": {
    "normal_banner_consecutive_misses": 42,
    "premium_banner_consecutive_misses": 7
  },

  "global_collection_achievements": [
    { "achievement_id": "rwb_collector_3", "unlocked": true }
  ],

  "settings": {
    "focus_mode": false,
    "window_position": { "x": 500, "y": 800 },
    "window_scale": 2,
    "sfx_volume": 0.7
  }
}
```

### 9.3 存档策略

| 触发条件 | 说明 |
|----------|------|
| 定时自动保存 | 每 3 分钟一次（`Timer` 节点） |
| 关键事件保存 | 购买素车/套件、交付车辆、抽卡、完成支线 |
| 退出保存 | 游戏关闭前强制存档一次 |
| **禁止** | 每帧或每秒写入 |

存档读写由 `SaveManager`（Autoload 单例）统一管理，使用 `FileAccess` API 操作 JSON。

---

## 10. 性能红线与技术约束

### 10.1 资源占用硬限制

| 指标 | 常规模式 | 专注模式 |
|------|----------|----------|
| 内存（RAM） | ≤ 200MB | ≤ 100MB |
| CPU 峰值 | < 2% | < 1% |
| FPS | 锁 30 | 锁 10-15 |

### 10.2 实体数量限制

| 实体类型 | 上限 |
|----------|------|
| 同屏活动 NPC 工人 | < 5 |
| 同屏特效粒子 | < 50（对象池管理） |

### 10.3 显示约束

- 视口尺寸 ≤ 屏幕分辨率的 1/4（高度和宽度）
- 缩放比例仅限整数倍（1x / 2x / 3x），防止像素画模糊
- 必须支持透明窗口无边框渲染

### 10.4 I/O 约束

- 自动保存频率 ≤ 每 3 分钟一次
- 禁止每帧/每秒写入硬盘

---

## 11. 项目管理与版本容灾

### 11.1 双分支策略（Two-Branch Strategy）

| 分支 | 定位 | 规则 |
|------|------|------|
| `main` | 绝对安全区 | 只有游戏完美运行、无明显 Bug 时才能合并。**禁止在 main 上直接让 AI 写代码。** |
| `dev` | 试验田 | 所有日常开发、AI 生成代码、功能测试都在这里进行。 |

### 11.2 AI 协作"三步存档法"（The Vibe-Coding Commit Rule）

| 步骤 | 操作 | Commit 备注示例 |
|------|------|----------------|
| Step 1：指令前存档 | 在要求 Claude Code 进行大规模重构或编写新系统**之前**，手动提交 | `"Before asking AI to write Gacha System"` |
| Step 2：局部测试 | AI 写完后立即在 Godot 中运行。崩溃则 `git revert` 到 Step 1，**绝不让 AI 在烂摊子上继续修补** | — |
| Step 3：成功后封存 | 功能测试跑通后立即提交 | `"feat: Added basic Gacha logic"` |

### 11.3 美术资产独立管理

- 所有 Aseprite 导出的 `.png` 和 `.json` 统一存放在 `assets/` 文件夹。
- 美术资产的 Commit **必须与代码逻辑的 Commit 分开**，保持版本记录清晰。
- 美术 Commit 备注格式：`"art: Updated mechanic_welding spritesheet"`

---

## 12. 硬件要求

### 12.1 最低配置

| 项目 | 要求 |
|------|------|
| 操作系统 | Windows 10 (64-bit) / macOS 11.0 (Big Sur) |
| 处理器 | 双核 CPU, 2.0 GHz |
| 内存 | 4 GB RAM |
| 显卡 | Intel HD Graphics 4000 或同等（支持 OpenGL 3.3 / Vulkan） |
| 存储 | 200 MB 可用空间 |

### 12.2 推荐配置

| 项目 | 要求 |
|------|------|
| 操作系统 | Windows 11 / macOS 13+ |
| 处理器 | 四核 CPU 及以上 |
| 内存 | 8 GB RAM |
| 显卡 | 任意近五年独显或现代集显（Intel Iris Xe / AMD Radeon） |
| 存储 | 500 MB（SSD 最佳） |

### 12.3 必备功能

操作系统必须支持**透明窗口无边框渲染（Borderless Window with Transparency）**。

---

## 13. 技术风险登记表

| 风险 ID | 风险描述 | 严重程度 | 缓解策略 |
|---------|---------|----------|----------|
| R-001 | 无边框 + 置顶 + 不抢焦点的窗口组合在部分 Linux 桌面环境下行为不一致 | 中 | V1.0 仅支持 Windows / macOS；Linux 支持标注为 V2.0+ |
| R-002 | 像素画非整数倍缩放导致模糊/脏点 | 高 | 强制整数倍缩放（1x/2x/3x），禁用抗锯齿，`Viewport` 的 `canvas_item_default_texture_filter` 设为 `NEAREST` |
| R-003 | 对象池预分配数量不足导致特效"消失" | 中 | 运行时监控池使用率，达到 80% 时输出警告日志；池上限可通过配置文件调整 |
| R-004 | AI 辅助编程引入隐蔽 Bug | 高 | 严格执行"三步存档法"；永不在 main 上直接开发；崩溃后回滚而非修补 |
| R-005 | 多显示器环境下窗口定位异常 | 中 | 使用 `DisplayServer` 多屏 API 检测边界；窗口位置超出屏幕范围时自动重置到主屏幕底部 |
| R-006 | 挂机经济系统数值失衡（通货膨胀/通缩） | 高 | 所有经济数值外置于 Custom Resource，支持热调整；预留代币兑换上限和冷却字段防止崩溃 |
| R-007 | 专注模式下内存仍超 100MB | 中 | 专注模式激活时主动 `queue_free()` 所有 VFX 池中的实例并释放非必要纹理缓存；使用 Godot Profiler 持续监控 |

---

## 14. 跨平台同步策略（V2.0+ / Out of Scope）

**V1.0 明确不实现跨平台同步。** 所有存档仅在本地 JSON 文件中读写。

**V2.0+ 启用路径**（预研方向，不作为当前开发承诺）：

| 方案 | 技术路径 | 适用场景 |
|------|----------|----------|
| 方案 A：云服务 | Godot `HTTPClient` + Firebase REST API（Realtime Database + Auth） | 快速上线、免费额度高、海外用户 |
| 方案 B：自建后端 | Godot `HTTPClient` + Python FastAPI + MongoDB | 数据自主、可做交易市场等复杂功能 |

**启用条件**：
1. 单机版核心循环跑通且足够好玩
2. 本地存档结构稳定（不再频繁变动字段）
3. 有明确的多端需求（如移动端移植）

**预留的技术接口**：`SaveManager` 已设计为统一的读写抽象层。V2.0 启用时，只需新增一个 `CloudSaveAdapter` 实现类，替换底层的 `FileAccess` 为 HTTP 请求，上层代码零改动。

---

> **文档结束。本 TDD 为本项目的唯一技术基准。所有后续的 Task.md 任务拆解，以本文档为"真理之源"。**
