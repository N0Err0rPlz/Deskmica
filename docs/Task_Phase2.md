# Task_Phase2.md — 第二阶段开发任务清单

**项目代号**：Deskmica
**阶段**：Phase 2 — 核心循环逻辑注入（Simulation 层）
**基准文档**：TDD.md v1.0-FINAL（§4.1 / §4.2 / §5.2 / §5.4 / §5.5 / §9.2）
**前置依赖**：Phase 1 已完成，`v0.1.0-foundation` Tag 已打在 main 分支。
**最后更新**：2026-04-15

---

> **Phase 2 范围边界**
>
> 本阶段的唯一目标是：**让模拟层的"时间"真正流动起来**。让 TaskManager 能把改装套件拆解为带倒计时的步骤队列，让 EconomyManager 能基于车库车辆价值每帧累积收益，并在 SaveManager 加载存档时一次性结算离线挂机收益。
>
> 本阶段**不涉及**：UI 界面、美术表现、动画播放、特效对象池、Shader、窗口管理。我们只证明一件事——**后台数据推演绝对正确，整个核心循环可以无 UI 闭环运行**。
>
> 完成本阶段后，项目应处于"按 F5 启动 → 无头脚本模拟完整买车/买套件/挂机/领钱/存档流程 → 控制台输出断言全绿"的状态。

> **Vibe Coding 工作流提醒**
>
> 每个编号任务（如 1.1、1.2 ...）视为一个独立的"AI 指令单元"。执行流程：
> 1. `git commit -m "Before: [任务名称]"` （Step 1：指令前存档）
> 2. 让 Claude Code 完成任务
> 3. 在 Godot 中按 F5 运行冒烟测试场景 → 崩溃则 `git revert`，成功则 `git commit` （Step 2/3）

---

## 目录

1. [Phase 1 遗留补丁与 SignalBus 扩容](#1-phase-1-遗留补丁与-signalbus-扩容)
2. [TaskManager 核心逻辑实现](#2-taskmanager-核心逻辑实现)
3. [EconomyManager 在线挂机收益实现](#3-economymanager-在线挂机收益实现)
4. [SaveManager 存档字段扩容与数据回灌](#4-savemanager-存档字段扩容与数据回灌)
5. [SaveManager 离线收益结算](#5-savemanager-离线收益结算)
6. [MainLoopManager 调度接入](#6-mainloopmanager-调度接入)
7. [ShopSystem 轻量接线（无 UI）](#7-shopsystem-轻量接线无-ui)
8. [阶段验收：Phase 2 无头冒烟测试](#8-阶段验收phase-2-无头冒烟测试)

---

## 1. Phase 1 遗留补丁与 SignalBus 扩容

### - [ ] 1.1 DataRegistry 补注册 KitDefinition 扫描

**技术定位**：
- 修改文件：`scripts/core/data_registry.gd`
- 涉及技术：DataRegistry 资源扫描、Custom Resource。
- 原因：Phase 1 的 DataRegistry 中遗漏了 `KitDefinition` 的扫描注册，但 Phase 2 的 TaskManager（任务 2.2）依赖 `DataRegistry.get_kit(kit_id)` 方法。必须在其他任务之前补上。

**具体动作**：
- 新增私有字段：
  ```gdscript
  var kits: Dictionary = {}      # { "test_kit_01": KitDefinition, ... }
  ```
- 在 `_ready()` 中新增扫描行：
  ```gdscript
  _scan_and_cache("res://resources/kits/", kits, "kit_id")
  ```
- 新增类型安全 getter：
  ```gdscript
  func get_kit(id: String) -> KitDefinition:
      return kits.get(id)
  ```
- 更新 `_ready()` 末尾的日志输出，追加 kits 计数。
- 确保 `res://resources/kits/` 目录存在（如 Phase 1 未创建该目录，则一并创建并放入 `.gdkeep`）。

**验收标准 (DoD)**：
- F5 启动后控制台日志中包含 kits 计数（当前为 0）。
- 在 `res://resources/kits/` 下手动创建一个测试 `KitDefinition` 类型的 `.tres`，重启后 `DataRegistry.get_kit("xxx")` 返回非 null。验证后删除测试文件。

---

### - [ ] 1.2 新建 EconomyConfig Custom Resource 并注册到 DataRegistry

**技术定位**：
- 新建文件：`scripts/systems/economy_config.gd`
- 新建文件：`resources/economy_config.tres`
- 修改文件：`scripts/core/data_registry.gd`
- 涉及技术：Custom Resource、DataRegistry 单点加载。

**具体动作**：
- 创建 `EconomyConfig` 基类脚本：
  ```gdscript
  # economy_config.gd — 全局经济系统配置
  class_name EconomyConfig
  extends Resource

  @export var offline_cap_seconds: int = 86400  # 离线收益最多结算秒数（默认 24 小时）
  # [预留拓展] 后续可在此追加：离线衰减曲线参数、通胀系数上限等
  ```
- 在 Godot 编辑器中创建 `resources/economy_config.tres`，类型选择 `EconomyConfig`，`offline_cap_seconds` 填入 `86400`。
- 修改 `scripts/core/data_registry.gd`，新增以下内容：
  - 新增字段：
    ```gdscript
    var economy_config: EconomyConfig = null
    ```
  - 在 `_ready()` 中新增固定路径加载（全局仅一份，不走目录扫描）：
    ```gdscript
    var _eco_path: String = "res://resources/economy_config.tres"
    if ResourceLoader.exists(_eco_path):
        economy_config = ResourceLoader.load(_eco_path) as EconomyConfig
    ```
  - 新增 getter：
    ```gdscript
    func get_economy_config() -> EconomyConfig:
        return economy_config
    ```

**验收标准 (DoD)**：
- F5 启动后，`DataRegistry.get_economy_config()` 返回非 `null`。
- `DataRegistry.get_economy_config().offline_cap_seconds` 等于 `86400`。
- 在编辑器 Inspector 中修改 `.tres` 的值为 `3600`，重启后 getter 返回 `3600`（证明值确实从文件读取而非硬编码）。

---

### - [ ] 1.3 新增车库与离线收益信号

**技术定位**：
- 修改文件：`scripts/core/signal_bus.gd`

**具体动作**：
- 在 `# === 经济与交易 ===` 段追加：
  ```gdscript
  signal car_added_to_garage(car_id: String)
  signal offline_earnings_settled(amount: int, duration_seconds: int)
  ```
- 不新增其它信号；`kit_purchased` / `step_started` / `step_completed` / `kit_installed` / `credits_changed` / `item_purchased` 已在 Phase 1 声明，Phase 2 直接复用。
- 保持 `@warning_ignore_start("unused_signal")` 覆盖范围不变。

**验收标准 (DoD)**：
- Godot 编辑器 F5 启动无红字报错。
- 控制台输出 `[SignalBus] Initialized.`。
- 用 `SignalBus.car_added_to_garage.connect(Callable(...))` 手动连一下无报错（下一任务会自动验证）。

---

## 2. TaskManager 核心逻辑实现

### - [ ] 2.1 TaskManager 数据结构与队列字段

**技术定位**：
- 修改文件：`scripts/simulation/task_manager.gd`

**具体动作**：
- 保留 Phase 1 的 `extends Node` 与 `update(delta)` 入口，移除 `pass` 空实现。
- 新增私有字段（全部静态类型）：
  ```gdscript
  # 每辆车的步骤队列： { car_id: Array[TaskStepData] }
  var _queues: Dictionary = {}
  # 每辆车当前正在执行的步骤剩余秒数： { car_id: float }
  var _remaining_seconds: Dictionary = {}
  # 每辆车当前正在执行的 kit_id（用于结束时 emit kit_installed）： { car_id: String }
  var _active_kits: Dictionary = {}
  ```
- 不在脚本中硬编码任何数值，步骤耗时一律取自 `TaskStepData.base_duration_seconds`。

**验收标准 (DoD)**：
- 启动时控制台仍输出 `[TaskManager] Initialized.`。
- 字段声明通过 GDScript 静态类型检查，无告警。

---

### - [ ] 2.2 订阅 `kit_purchased` 并拆解套件入队

**技术定位**：
- 修改文件：`scripts/simulation/task_manager.gd`
- 依赖：`DataRegistry.get_kit(kit_id) -> KitDefinition`（任务 1.1 已补注册）

**具体动作**：
- 在 `_ready()` 中 `SignalBus.kit_purchased.connect(_on_kit_purchased)`。
- 实现 `_on_kit_purchased(car_id: String, kit_id: String) -> void`：
  1. 通过 `DataRegistry.get_kit(kit_id)` 取回 `KitDefinition`；取不到则 `push_warning` 后直接 return。
  2. 如 `_queues[car_id]` 不存在则初始化为空 `Array[TaskStepData]`。
  3. 将 `kit_def.task_steps` 的元素**依序 append** 进 `_queues[car_id]`。
  4. 记录 `_active_kits[car_id] = kit_id`（若该车此前空闲则立刻准备推进）。
  5. 若当前该车没有正在跑的步骤（`_remaining_seconds[car_id]` 不存在或为 0），调用 `_start_next_step(car_id)`。
- 实现 `_start_next_step(car_id: String) -> void`（**Peek 模型**，当前正在执行的步骤始终保留在队首 `_queues[car_id][0]`，直到 `update()` 中倒计时归零后才 `pop_front`）：
  - 若队列空：清理 `_remaining_seconds.erase(car_id)`，emit `SignalBus.kit_installed(car_id, _active_kits[car_id])`，再 `_active_kits.erase(car_id)`。
  - 若队列非空：**读取**队首 `step_data = _queues[car_id][0]`（**不出队、不 pop_front**），`_remaining_seconds[car_id] = step_data.base_duration_seconds`，emit `SignalBus.step_started(car_id, step_data)`。

**验收标准 (DoD)**：
- 在冒烟测试中发射一次 `kit_purchased` 后：
  - `TaskManager._queues[car_id].size() == kit_def.task_steps.size()`（当前步骤仍在队首，未被 pop）。
  - `TaskManager._remaining_seconds[car_id] == kit_def.task_steps[0].base_duration_seconds`。
  - 控制台能接收到一次 `step_started`。

---

### - [ ] 2.3 `update(delta)` 倒计时与步骤完成派发

**技术定位**：
- 修改文件：`scripts/simulation/task_manager.gd`

**具体动作**：
- 实现 `update(delta: float) -> void`：
  ```gdscript
  # 拷贝 keys 防止迭代中修改字典
  for car_id in _remaining_seconds.keys():
      _remaining_seconds[car_id] -= delta
      if _remaining_seconds[car_id] <= 0.0:
          # Peek 模型：当前步骤此刻仍留在 _queues[car_id][0]
          var finished_step: TaskStepData = _peek_current_step(car_id)
          SignalBus.step_completed.emit(car_id, finished_step)
          _queues[car_id].pop_front()   # 倒计时归零后，才真正从队列弹出
          _start_next_step(car_id)      # 读取新的队首或发射 kit_installed
  ```
- 新增辅助方法 `_peek_current_step(car_id: String) -> TaskStepData`：仅读取 `_queues[car_id][0]`，**不修改队列**。pop 时机严格固定为"`step_completed` emit 之后、`_start_next_step` 之前"。
- 增加公开只读查询 API 便于测试：
  - `func is_busy(car_id: String) -> bool`
  - `func get_remaining(car_id: String) -> float`

**红线复核**：
- ❌ 禁止用 `Timer` 节点做业务倒计时（红线 5）。
- ❌ 禁止 `load()` / `preload()` KitDefinition（红线 4）。
- ✅ 所有时长读自 Resource，无硬编码（红线 3）。

**验收标准 (DoD)**：
- 冒烟测试中，模拟 `update(1.0)` 调用 N 次后（N 为 `base_duration_seconds` 之和向上取整），应收到**全部步骤** `step_completed` + 一次 `kit_installed`。
- `TaskManager.is_busy(test_car_id)` 最终返回 `false`。

---

## 3. EconomyManager 在线挂机收益实现

### - [ ] 3.1 新增车库车辆清单与全局倍率字段

**技术定位**：
- 修改文件：`scripts/simulation/economy_manager.gd`

**具体动作**：
- 保留 Phase 1 已实现的 `_credits` / `get_credits` / `add_credits` / `spend_credits`。
- 新增私有字段：
  ```gdscript
  # 车库中所有处于产出状态的车辆 ID（含未改装的素车）
  var _garage_car_ids: Array[String] = []
  # 挂机收益累加缓冲（避免每帧写小数到 int _credits）
  var _yield_buffer: float = 0.0
  # 全局产出倍率（Phase 2 固定为 1.0，Phase 3 由 Buff/SetBonus 注入）
  var _global_modifier: float = 1.0
  ```
- 在 `_ready()` 中订阅 `SignalBus.car_added_to_garage.connect(_on_car_added)`。
- 实现 `_on_car_added(car_id: String) -> void`：若 `car_id not in _garage_car_ids` 则 append。

**验收标准 (DoD)**：
- 发射两次相同 `car_added_to_garage` 后，`_garage_car_ids.size() == 1`（去重）。

---

### - [ ] 3.2 `update(delta)` 计算每帧产出

**技术定位**：
- 修改文件：`scripts/simulation/economy_manager.gd`
- 依赖：`DataRegistry.get_car(car_id: String) -> CarDefinition`

**具体动作**：
- 实现 `update(delta: float) -> void`：
  ```gdscript
  if _garage_car_ids.is_empty():
      return
  var per_second: float = 0.0
  for car_id in _garage_car_ids:
      var def: CarDefinition = DataRegistry.get_car(car_id)
      if def == null:
          continue
      # TDD 5.4.1：yield = base_value × time_delta × global_modifier
      # base_value 单位为 credits/秒 的基准（Phase 2 先直接用）
      per_second += float(def.base_value)
  _yield_buffer += per_second * delta * _global_modifier
  if _yield_buffer >= 1.0:
      var gained: int = int(floor(_yield_buffer))
      _yield_buffer -= float(gained)
      add_credits(gained)  # 复用 Phase 1 的 emit credits_changed 路径
  ```
- 新增公开 API 供离线结算使用：
  ```gdscript
  func calculate_passive_yield_per_second() -> float:
      # 返回当前车库每秒被动产出（含 global_modifier）
  ```

**红线复核**：
- ✅ `base_value` / 倍率均来自 Resource，无魔法数字。
- ✅ 不直接触达 TaskManager，保持单向通信。

**验收标准 (DoD)**：
- 冒烟测试中，加入一辆 `base_value = 10` 的车，调用 `update(1.0)` 十次后 `get_credits()` 增量约为 100（允许 ±1 的浮点缓冲误差）。
- 控制台在每次整数进位时收到 `credits_changed`。

---

## 4. SaveManager 存档字段扩容与数据回灌

### - [ ] 4.1 扩容存档默认结构

**技术定位**：
- 修改文件：`scripts/core/save_manager.gd`

**具体动作**：
- 在 `_get_default_save_data()` 的 `"garage"` 字段中约定每辆车的结构（对齐 TDD §9.2）：
  ```gdscript
  # garage: Array[Dictionary]
  #   { "car_id": String, "installed_kit_ids": Array[String] }
  ```
- 在 `_collect_player_data()` 之外新增 `_collect_garage_data()` / `_collect_task_queue_data()`：
  - `_collect_garage_data` 遍历 `EconomyManager._garage_car_ids` 组装为 Array[Dictionary]。
  - `_collect_task_queue_data` 从 `TaskManager` 导出（由 TaskManager 提供 `export_queue_snapshot() -> Array`）。
- **`active_task_queue` 快照 Schema（显式定义，消除二义性）**：每辆车一个 Dictionary，字段如下：
  ```json
  {
    "car_id": "test_car_01",
    "active_kit_id": "test_kit_01",
    "remaining_seconds": 1.3,
    "pending_step_ids": ["test_step_01", "test_step_02"]
  }
  ```
  约定：
  - `pending_step_ids` **必须包含当前正在执行的队首 step_id**（即 `_queues[car_id]` 的完整 step_id 镜像，顺序一致）。
  - `remaining_seconds` 对应 `pending_step_ids[0]` 的剩余秒数。
  - 绝不写入 `TaskStepData` Resource 本体，只写字符串 id —— Resource 引用永远通过 DataRegistry 重新取回。
- 在 `save_game()` 中把这两份数据写入 `_save_data["garage"]` / `_save_data["active_task_queue"]`。

**红线复核**：
- SaveManager 作为可信基础设施，允许读写 Manager 私有字段（沿用 Phase 1 架构豁免注释）。

**验收标准 (DoD)**：
- 存档后打开 `user://save_data.json`，能看到 `garage` 非空数组、`active_task_queue` 字段结构正确。

---

### - [ ] 4.2 数据回灌 Manager 状态

**技术定位**：
- 修改文件：`scripts/core/save_manager.gd` / `scripts/simulation/task_manager.gd` / `scripts/simulation/economy_manager.gd`

**具体动作**：
- 在 `_apply_loaded_data()` 中新增：
  1. 读取 `garage`，逐条塞入 `EconomyManager._garage_car_ids`（去重）。
  2. 读取 `active_task_queue`，调用 `TaskManager.restore_queue_snapshot(data: Array)` 恢复 `_queues` / `_remaining_seconds` / `_active_kits`。
- 在 `TaskManager` / `EconomyManager` 中分别实现 `restore_queue_snapshot(snapshot: Array) -> void` / `restore_garage(ids: Array) -> void`。
- `restore_queue_snapshot` 的还原规则（对齐任务 4.1 Schema）：
  1. 清空 `_queues` / `_remaining_seconds` / `_active_kits`。
  2. 遍历每一条快照 Dictionary：
     - `_active_kits[car_id] = active_kit_id`
     - 逐个 step_id 通过 **`DataRegistry.get_task(step_id) -> TaskStepData`**（对应 [data_registry.gd:56](scripts/core/data_registry.gd#L56)）取回 Resource 引用，依序 append 进 `_queues[car_id]`。
     - `_remaining_seconds[car_id] = snapshot.remaining_seconds`
  3. 若某个 step_id 在 DataRegistry 中取不到，`push_warning` 并跳过该车条目（属于存档/资源版本失配，不中断加载）。
- **严禁**把 `TaskStepData` / `KitDefinition` Resource 本体 `str()` 或直接序列化进 JSON —— JSON 中只能是 String/int/float/bool/Array/Dictionary。

**验收标准 (DoD)**：
- 冒烟测试：保存一次 → 重新 `load_game()` → `TaskManager.is_busy(car_id)` 与存档前一致，`EconomyManager._garage_car_ids` 完全还原。

---

## 5. SaveManager 离线收益结算

### - [ ] 5.1 计算离线时长并发放被动收益

**技术定位**：
- 修改文件：`scripts/core/save_manager.gd`
- 依赖：`EconomyManager.calculate_passive_yield_per_second()`（任务 3.2）

**具体动作**：
- 在 `load_game()` 成功分支里，`_apply_loaded_data()` 调用**之后**、`load_completed` 发射**之前**，追加 `_settle_offline_earnings()`。
- 实现 `_settle_offline_earnings() -> void`：
  ```gdscript
  var last_ts: int = int(_save_data.get("last_save_timestamp", 0))
  if last_ts <= 0:
      return
  var now_ts: int = int(Time.get_unix_time_from_system())
  var duration: int = max(0, now_ts - last_ts)
  if duration == 0:
      return
  # 从 EconomyConfig Custom Resource 读取离线收益上限（铁律 4：数据驱动）
  # 硬失败策略：缺失 EconomyConfig 属于部署配置错误，禁止使用任何硬编码回落值
  var eco_config: EconomyConfig = DataRegistry.get_economy_config()
  assert(eco_config != null, "EconomyConfig.tres missing — required for offline settlement")
  var offline_cap: int = eco_config.offline_cap_seconds
  var effective: int = min(duration, offline_cap)
  var per_sec: float = EconomyManager.calculate_passive_yield_per_second()
  var amount: int = int(floor(per_sec * float(effective)))
  if amount > 0:
      EconomyManager.add_credits(amount)
  SignalBus.offline_earnings_settled.emit(amount, effective)
  print("[SaveManager] Offline settled: +%d credits over %d s" % [amount, effective])
  ```
- **绝不推进 TaskManager 队列**（TDD §5.4.3 明确：离线只结算被动挂机）。

**红线复核**：
- ✅ 离线上限从 `EconomyConfig` Custom Resource 读取，脚本内零硬编码数字（符合铁律 4）。
- ✅ 配置缺失走硬失败（`assert`），不存在"默默回落到 86400"的隐藏真相。
- ✅ 只使用 Signal 与公开 API 与 EconomyManager 通信（`add_credits` 已是公开 API）。

**验收标准 (DoD)**：
- 冒烟测试：手动把 `_save_data["last_save_timestamp"]` 改为 `now - 10`，触发 `load_game()` 后 `get_credits()` 增量 ≈ `per_sec * 10`。
- 控制台输出 `[SaveManager] Offline settled: ...`。
- 再次重载（时间戳已被刷新）不应重复发放，测试断言增量为 0。

---

## 6. MainLoopManager 调度接入

### - [ ] 6.1 启用 TaskManager.update 调度

**技术定位**：
- 修改文件：`scripts/core/main_loop_manager.gd`

**具体动作**：
- 将 `# TaskManager.update(delta)       # Phase 2: 接入后取消注释` 这一行取消注释，移除注释尾巴。
- 顺序保持不变：`EconomyManager → TaskManager → BuffManager → TokenManager`。
- QuestManager / EventManager / BusinessManager / MiniGameManager 仍保留注释（不在 Phase 2 范围）。

**验收标准 (DoD)**：
- F5 启动无报错，连续运行 5 秒控制台无红字。
- 手动挂一个 `kit_purchased` 事件后，真实时间推进下步骤会自动完成（不再依赖手动调 `update`）。

---

## 7. ShopSystem 轻量接线（无 UI）

### - [ ] 7.1 注册 ShopSystem 为 Autoload 并提供纯代码购买 API

**技术定位**：
- 修改文件：`scripts/systems/shop_system.gd`
- 新增 Autoload 注册：Project Settings → Autoload → 注册名 `ShopSystem`，路径 `scripts/systems/shop_system.gd`
- 依赖：`DataRegistry.get_car` / `get_kit`、`EconomyManager.spend_credits`
- 原因：GDScript 的 `static func` 无法访问 Autoload 单例（`DataRegistry`、`EconomyManager`、`SignalBus`），因此 ShopSystem 必须作为 Autoload 实例方法运行。

**具体动作**：
- 将 ShopSystem 注册为 Autoload 单例（注册顺序：在 `MainLoopManager` 之后）。
- 实现两个**实例方法**（非 static），Phase 2 不接任何 UI：
  ```gdscript
  extends Node

  func _ready() -> void:
      print("[ShopSystem] Initialized.")

  func try_buy_car(car_id: String) -> bool:
      var def: CarDefinition = DataRegistry.get_car(car_id)
      if def == null: return false
      if not EconomyManager.spend_credits(def.purchase_price): return false
      SignalBus.item_purchased.emit("car", car_id)
      SignalBus.car_purchased.emit(car_id)
      SignalBus.car_added_to_garage.emit(car_id)
      return true

  func try_buy_kit(car_id: String, kit_id: String) -> bool:
      var def: KitDefinition = DataRegistry.get_kit(kit_id)
      if def == null: return false
      if not EconomyManager.spend_credits(def.purchase_price): return false
      SignalBus.item_purchased.emit("kit", kit_id)
      SignalBus.kit_purchased.emit(car_id, kit_id)
      return true
  ```
- 不做扣款失败的花哨提示，Phase 2 只保证逻辑闭环。

**红线复核**：
- ✅ 所有扣款通过 `EconomyManager.spend_credits` 公开 API，无直写 `_credits`。
- ✅ 通过 SignalBus 广播，不直接持有 TaskManager 引用。

**验收标准 (DoD)**：
- F5 启动后控制台输出 `[ShopSystem] Initialized.`。
- 冒烟测试调用 `ShopSystem.try_buy_car("test_car_01")` 返回 `true`，`EconomyManager._garage_car_ids` 出现该 id。

---

## 8. 阶段验收：Phase 2 无头冒烟测试

### - [ ] 8.1 准备测试用 .tres 资源

**技术定位**：
- 新建：`resources/cars/test_car_01.tres`、`resources/kits/test_kit_01.tres`、`resources/tasks/test_step_01.tres`、`resources/tasks/test_step_02.tres`
- 注意：存放在 `resources/` 目录下（非 `data/`），以确保 DataRegistry 启动时能自动扫描到。

**具体动作**：
- `test_car_01.tres`：`car_id="test_car_01"`、`base_value=10`、`purchase_price=100`。
- `test_step_01.tres`：`step_id="test_step_01"`、`base_duration_seconds=2.0`、`task_tag="bodywork"`。
- `test_step_02.tres`：`step_id="test_step_02"`、`base_duration_seconds=3.0`、`task_tag="paint"`。
- `test_kit_01.tres`：`kit_id="test_kit_01"`、`purchase_price=50`、`task_steps=[test_step_01, test_step_02]`。

**验收标准 (DoD)**：
- F5 启动后 `DataRegistry.get_car("test_car_01")` 与 `DataRegistry.get_kit("test_kit_01")` 均非 `null`。

---

### - [ ] 8.2 编写 Phase 2 冒烟测试脚本

**技术定位**：
- 新建：`scripts/tests/phase2_smoke_test.gd`
- 新建：`scenes/tests/phase2_smoke_test.tscn`（一个挂着该脚本的根 Node，F5 可直接运行）

**具体动作**：
- 脚本结构（纯代码，无 UI）：
  ```gdscript
  # phase2_smoke_test.gd —— Phase 2 核心循环闭环断言脚本
  extends Node

  const INITIAL_CREDITS: int = 1000
  const CAR_ID: String = "test_car_01"
  const KIT_ID: String = "test_kit_01"

  var _step_started_count: int = 0
  var _step_completed_count: int = 0
  var _kit_installed_hit: bool = false

  func _ready() -> void:
      SignalBus.step_started.connect(func(_c, _s): _step_started_count += 1)
      SignalBus.step_completed.connect(func(_c, _s): _step_completed_count += 1)
      SignalBus.kit_installed.connect(func(_c, _k): _kit_installed_hit = true)

      EconomyManager.add_credits(INITIAL_CREDITS)

      # 1) 买车
      assert(ShopSystem.try_buy_car(CAR_ID), "buy car failed")

      # 2) 买套件
      assert(ShopSystem.try_buy_kit(CAR_ID, KIT_ID), "buy kit failed")
      assert(TaskManager.is_busy(CAR_ID), "task not queued")

      # 3) 手动模拟 10 秒推进（跳过 _process，保证确定性）
      var credits_before: int = EconomyManager.get_credits()
      for i in range(10):
          TaskManager.update(1.0)
          EconomyManager.update(1.0)

      # 4) 断言：套件已装完
      assert(_step_started_count == 2, "step_started count mismatch")
      assert(_step_completed_count == 2, "step_completed count mismatch")
      assert(_kit_installed_hit, "kit_installed not fired")
      assert(not TaskManager.is_busy(CAR_ID), "task still busy")

      # 5) 断言：挂机收益已入账（10 秒 * 10/s = 100）
      var gained: int = EconomyManager.get_credits() - credits_before
      assert(gained >= 95 and gained <= 105, "yield mismatch: %d" % gained)

      # 6) 离线结算验证：
      #    严禁在 SaveManager 生产代码上开 _debug_* 后门；
      #    测试作为黑盒视角直接读写 user://save_data.json 磁盘文件来回拨时间戳。
      SaveManager.trigger_event_save()  # ① 写一份正常存档（ts = now）
      var credits_before_offline: int = EconomyManager.get_credits()
      _rewind_save_timestamp_on_disk(30)  # ② 篡改磁盘 JSON：last_save_timestamp = now - 30
      SaveManager.load_game()             # ③ 重新加载，触发 _settle_offline_earnings

      # 7) 断言：离线收益已发放（30 秒 * 10/s = 300，允许浮点缓冲 ±5）
      var offline_gain: int = EconomyManager.get_credits() - credits_before_offline
      assert(offline_gain >= 295 and offline_gain <= 305,
          "offline settlement mismatch: %d" % offline_gain)

      # 8) 断言：紧接着再 load 一次不应重复发放（save_game 已把 ts 刷成 now）
      SaveManager.trigger_event_save()
      var credits_before_idempotent: int = EconomyManager.get_credits()
      SaveManager.load_game()
      assert(EconomyManager.get_credits() == credits_before_idempotent,
          "offline settlement must be idempotent when duration == 0")

      print("[Phase2Smoke] ALL ASSERTIONS PASSED ✅")
      get_tree().quit()

  # 测试专用工具：直接改写磁盘上的 last_save_timestamp，绕开 save_game() 的自动刷新
  # 这里故意走 FileAccess + JSON，而不是在 SaveManager 开后门 API。
  func _rewind_save_timestamp_on_disk(seconds_ago: int) -> void:
      const SAVE_PATH := "user://save_data.json"
      assert(FileAccess.file_exists(SAVE_PATH), "save file must exist before rewinding")
      var reader: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
      var raw: String = reader.get_as_text()
      reader.close()
      var json: JSON = JSON.new()
      assert(json.parse(raw) == OK, "save file is not valid JSON")
      var data: Dictionary = json.data
      data["last_save_timestamp"] = int(Time.get_unix_time_from_system()) - seconds_ago
      var writer: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
      writer.store_string(JSON.stringify(data, "  "))
      writer.close()
  ```
- 脚本中禁止硬编码 `base_value`/`duration`，全部从 Resource 或常量读取。
- 测试脚本放入 `scripts/tests/`，不得进入生产 Autoload。

**红线复核**：
- ✅ 无 UI、无美术、无特效创建。
- ✅ 全程通过 SignalBus + 公开 API 与各 Manager 通信。

**验收标准 (DoD)**：
- F5 运行 `phase2_smoke_test.tscn` 后，控制台最终打印：
  ```
  [Phase2Smoke] ALL ASSERTIONS PASSED ✅
  ```
- 任一 `assert` 失败即视为任务不通过，必须 `git revert` 后重做。
- 日志中应能按先后顺序看到：
  1. `[TaskManager] step_started`（×2）
  2. `[TaskManager] step_completed`（×2）
  3. `kit_installed` 信号日志
  4. 首次 `[SaveManager] Offline settled: +≈300 credits over 30 s`（验证修正 1 的磁盘篡改路径真实生效）
  5. 二次 `[SaveManager] Offline settled: +0 credits over 0 s`（验证幂等性）
  6. `[SaveManager] Game loaded.`（load 结束）
- **不允许** `SaveManager` 中存在任何 `_debug_*` / 测试专用 API —— 测试代码直接走 `FileAccess`。

---

### - [ ] 8.3 Phase 2 最终封存

**技术定位**：
- Git 操作。

**具体动作**：
- 清理所有 `print("debug ...")` 调试语句（保留规范化 `[Module] xxx` 日志）。
- 确认 `docs/Task_Phase2.md` 中的所有复选框已勾选。
- 提交收尾 commit（示例）：
  ```
  chore(phase2): 收尾 Phase 2 核心循环
  ```
- 在 main 分支打 Tag：`v0.2.0-simulation`。

**验收标准 (DoD)**：
- `git tag` 输出包含 `v0.2.0-simulation`。
- 重新 checkout 该 Tag，F5 运行 `phase2_smoke_test.tscn` 仍能输出 `ALL ASSERTIONS PASSED ✅`。
- Phase 3（View 层接入）可以基于此 Tag 安全起步。

---

## 附录 A — Phase 2 新增/修改文件汇总

| 类型 | 路径 | 说明 |
|------|------|------|
| 修改 | `scripts/core/data_registry.gd` | 补注册 KitDefinition 扫描与 getter |
| 修改 | `scripts/core/signal_bus.gd` | 新增 2 个信号 |
| 修改 | `scripts/simulation/task_manager.gd` | 队列/倒计时/快照 API |
| 修改 | `scripts/simulation/economy_manager.gd` | 车库清单/每帧产出/被动产出查询 |
| 修改 | `scripts/core/save_manager.gd` | garage/queue 字段、离线结算、settings 新增 offline_cap_seconds |
| 修改 | `scripts/core/main_loop_manager.gd` | 解注释 TaskManager.update |
| 修改 | `scripts/systems/shop_system.gd` | 注册为 Autoload + 实例方法 try_buy_car / try_buy_kit |
| 新建 | `resources/cars/test_car_01.tres` | 测试数据 |
| 新建 | `resources/kits/test_kit_01.tres` | 测试数据 |
| 新建 | `resources/tasks/test_step_01.tres` | 测试数据 |
| 新建 | `resources/tasks/test_step_02.tres` | 测试数据 |
| 新建 | `scripts/tests/phase2_smoke_test.gd` | 无头冒烟测试 |
| 新建 | `scenes/tests/phase2_smoke_test.tscn` | 测试场景入口 |
| 新建 | `scripts/systems/economy_config.gd` | EconomyConfig Custom Resource 基类（离线上限等全局经济参数） |
| 新建 | `resources/economy_config.tres` | 全局经济配置实例 |

## 附录 B — Phase 2 不做的事（显式排除）

- ❌ 任何 UI 节点、Control、Label、ProgressBar。
- ❌ 动画播放、Sprite2D、AnimationPlayer。
- ❌ VFXPool / 粒子 / Shader / 调色盘。
- ❌ SetBonusCalculator 的真实倍率计算（`_global_modifier` 锁定 1.0）。
- ❌ QuestManager / EventManager / BusinessManager / MiniGameManager 的业务逻辑（仍为空壳）。
- ❌ 跨车辆并发步骤的调度优化（Phase 2 默认一车串行一队列即可）。
- ❌ 离线收益的"半收益衰减曲线"等平衡向设计（Phase 2 按线性 + 可配置上限处理，后续平衡期再调）。
- ❌ 技师专精匹配的效率倍率（Phase 2 使用 `base_duration_seconds` 原值，不乘以 `efficiency_multiplier`，专精加速逻辑在 Phase 3+ 接入 NPC 实体系统时实现）。
- ❌ 在 `SaveManager` 生产代码上新增任何 `_debug_*` / 测试后门 API（违反"生产代码纯净性"原则）。冒烟测试对存档磁盘格式的依赖，与对 `load_game()` 的依赖属于同一层契约，应由测试脚本自行通过 `FileAccess` + `JSON` 直接读写 `user://save_data.json`。
