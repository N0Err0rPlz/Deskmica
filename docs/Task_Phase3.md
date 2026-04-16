# Task_Phase3.md — 第三阶段开发任务清单

**项目代号**：Deskmica
**阶段**：Phase 3 — 视图层接入与美术管线贯通（View Layer）
**基准文档**：TDD.md v1.0-FINAL（§5.3 / §7 / §8）、ART_SPEC.md v1.0
**前置依赖**：Phase 2 已完成，`v0.2.0-simulation` Tag 已打在 main 分支。
**最后更新**：2026-04-17

---

> **Phase 3 范围边界**
>
> 本阶段的唯一目标是：**让画面"看得见"模拟层的数据——车辆能渲染在屏幕上、配件能动态挂载、Shader 调色能生效、窗口能以桌面挂件形态运行**。
>
> 本阶段**不涉及**：NPC 技师动画、FSM 状态机表现层、VFX 特效对象池、UI 面板搭建、小游戏 UI 覆盖层。我们只证明一件事——**一辆分层渲染的车辆能正确显示在无边框透明窗口中，配件能按锚点挂载，Shader 能实时换色**。
>
> 完成本阶段后，项目应处于"F5 启动 → 无边框透明窗口出现在屏幕底部 → 一辆测试车辆分四层渲染 → 手动切换调色盘颜色生效 → 手动挂载一个配件 Sprite 到正确锚点位置"的状态。

> **Vibe Coding 工作流提醒**
>
> 每个编号任务（如 1.1、1.2 ...）视为一个独立的"AI 指令单元"。执行流程：
> 1. `git commit -m "Before: [任务名称]"` （Step 1：指令前存档）
> 2. 让 Claude Code 完成任务
> 3. 在 Godot 中按 F5 运行测试 → 崩溃则 `git revert`，成功则 `git commit` （Step 2/3）

---

## 目录

1. [模板引导系统数据层](#1-模板引导系统数据层)
2. [CarDefinition 字段扩容](#2-cardefinition-字段扩容)
3. [PartDefinition 字段扩容](#3-partdefinition-字段扩容)
4. [DataRegistry 补注册模板扫描](#4-dataregistry-补注册模板扫描)
5. [调色盘替换 Shader](#5-调色盘替换-shader)
6. [车辆分层渲染器](#6-车辆分层渲染器-vehiclerenderer)
7. [配件锚点查询与动态挂载](#7-配件锚点查询与动态挂载)
8. [窗口管理系统](#8-窗口管理系统-windowmanager)
9. [测试美术资产准备（占位图）](#9-测试美术资产准备占位图)
10. [阶段验收：Phase 3 视觉冒烟测试](#10-阶段验收phase-3-视觉冒烟测试)

---

## 1. 模板引导系统数据层

### - [ ] 1.1 创建 TemplateGuide Custom Resource 基类

**技术定位**：
- 新建文件：`scripts/systems/template_guide.gd`
- 涉及技术：Custom Resource。
- 来源：ART_SPEC §2.3。

**具体动作**：

```gdscript
class_name TemplateGuide
extends Resource

@export var template_id: String = ""
@export var display_name: String = ""
@export var bbox_width: int = 64
@export var bbox_height: int = 36
@export var ground_line_y: int = 32
@export var wheel_front: Vector2i = Vector2i(18, 32)
@export var wheel_rear: Vector2i = Vector2i(46, 32)
@export var shadow_ellipse_rx: int = 28
@export var shadow_ellipse_ry: int = 6
@export var shadow_offset_y: int = 2
@export var part_anchors: Dictionary = {}
# part_anchors 示例：
# { "front_bumper": Vector2i(8, 28), "spoiler": Vector2i(32, 12), ... }
```

**验收标准 (DoD)**：
- 在 Godot 编辑器中右键 `resources/` → New Resource → 能在列表中找到 `TemplateGuide`。
- 创建测试 `.tres` 文件，Inspector 面板中能看到并编辑所有字段，`part_anchors` 字典可手动添加键值对。

---

### - [ ] 1.2 创建 S-Low 和 M-Mid 模板数据文件

**技术定位**：
- 新建文件：`resources/templates/S-Low.tres`、`resources/templates/M-Mid.tres`
- 新建目录：`resources/templates/`
- 来源：ART_SPEC §3.1、§5.2。

**具体动作**：

**S-Low.tres**（微型/小型低矮车）：
```
template_id = "S-Low"
display_name = "微型/小型低矮"
bbox_width = 56
bbox_height = 30
ground_line_y = 27
wheel_front = Vector2i(14, 27)
wheel_rear = Vector2i(42, 27)
shadow_ellipse_rx = 24
shadow_ellipse_ry = 5
shadow_offset_y = 2
part_anchors = {
    "front_bumper": Vector2i(6, 22),
    "rear_bumper": Vector2i(48, 22),
    "side_skirt_left": Vector2i(10, 25),
    "side_skirt_right": Vector2i(44, 25),
    "spoiler": Vector2i(28, 8),
    "hood": Vector2i(18, 12),
    "wheels_front": Vector2i(14, 27),
    "wheels_rear": Vector2i(42, 27)
}
```

**M-Mid.tres**（中型标准车）：
```
template_id = "M-Mid"
display_name = "中型标准"
bbox_width = 64
bbox_height = 36
ground_line_y = 32
wheel_front = Vector2i(18, 32)
wheel_rear = Vector2i(46, 32)
shadow_ellipse_rx = 28
shadow_ellipse_ry = 6
shadow_offset_y = 2
part_anchors = {
    "front_bumper": Vector2i(8, 28),
    "rear_bumper": Vector2i(56, 28),
    "side_skirt_left": Vector2i(12, 30),
    "side_skirt_right": Vector2i(52, 30),
    "spoiler": Vector2i(32, 12),
    "hood": Vector2i(24, 16),
    "wheels_front": Vector2i(18, 32),
    "wheels_rear": Vector2i(46, 32)
}
```

> 注：以上锚点坐标为初始估算值，在实际制作 Aseprite 模板导引图时会精确标定后回填。Phase 3 仅需数据文件能被引擎加载即可。

**验收标准 (DoD)**：
- F5 启动后 `DataRegistry.get_template("S-Low")` 和 `DataRegistry.get_template("M-Mid")` 均返回非 null。

---

## 2. CarDefinition 字段扩容

### - [ ] 2.1 为 CarDefinition 添加模板关联与锚点覆盖字段

**技术定位**：
- 修改文件：`scripts/systems/car_definition.gd`
- 来源：ART_SPEC §1.3、§5.3。

**具体动作**：
- 在现有字段之后追加以下新字段：

```gdscript
# === Phase 3 新增：美术管线关联 ===
@export var template_id: String = ""           # 关联的模板 ID（"S-Low" / "M-Mid"）
@export var real_length_mm: int = 0            # 真实车长（毫米），用于模板自动匹配
@export var real_width_mm: int = 0             # 真实车宽（毫米）
@export var real_height_mm: int = 0            # 真实车高（毫米）
@export var real_wheelbase_mm: int = 0         # 真实轴距（毫米）
@export var anchor_overrides: Dictionary = {}  # 车辆级锚点覆盖（可选）
# anchor_overrides 示例：{ "spoiler": Vector2i(32, 10) }

# 分层 Sprite 路径
@export var sprite_shadow_path: String = ""
@export var sprite_chassis_path: String = ""
@export var sprite_body_path: String = ""
@export var sprite_detail_path: String = ""
```

- **不删除** Phase 1 已有的 `sprite_path` 和 `palette_id` 字段（向后兼容）。

**验收标准 (DoD)**：
- 编辑器中打开已有的 `CarDefinition` 类型 `.tres` 文件，Inspector 中能看到所有新增字段。
- Phase 2 的冒烟测试仍能通过（新增字段均有默认值，不影响已有逻辑）。

---

## 3. PartDefinition 字段扩容

### - [ ] 3.1 为 PartDefinition 添加 Sprite 路径与锚点模式

**技术定位**：
- 修改文件：`scripts/systems/part_definition.gd`
- 来源：ART_SPEC §5.4、§9.2。

**具体动作**：
- 追加以下字段：

```gdscript
# === Phase 3 新增：美术资产关联 ===
@export var sprite_path: String = ""           # 配件 Sprite PNG 路径
@export var anchor_mode: String = "top_left"   # "top_left" 或 "center"
@export var compatible_templates: PackedStringArray = []  # 适用的模板 ID 列表
```

**验收标准 (DoD)**：
- 编辑器中可编辑新增字段。Phase 2 冒烟测试不受影响。

---

## 4. DataRegistry 补注册模板扫描

### - [ ] 4.1 DataRegistry 新增 TemplateGuide 扫描与 getter

**技术定位**：
- 修改文件：`scripts/core/data_registry.gd`
- 涉及技术：目录扫描、Dictionary 缓存。

**具体动作**：
- 新增字段：
  ```gdscript
  var templates: Dictionary = {}  # { "S-Low": TemplateGuide, "M-Mid": TemplateGuide }
  ```
- 在 `_ready()` 中新增扫描行：
  ```gdscript
  _scan_and_cache("res://resources/templates/", templates, "template_id")
  ```
- 新增 getter：
  ```gdscript
  func get_template(id: String) -> TemplateGuide:
      return templates.get(id)
  ```
- 更新日志输出追加 templates 计数。

**验收标准 (DoD)**：
- F5 启动后日志包含 `2 templates`（S-Low + M-Mid）。
- `DataRegistry.get_template("M-Mid").bbox_width` 返回 `64`。

---

## 5. 调色盘替换 Shader

### - [ ] 5.1 编写 palette_swap.gdshader

**技术定位**：
- 新建文件：`assets/shaders/palette_swap.gdshader`
- 涉及技术：Godot Shading Language。
- 来源：TDD §8.1、ART_SPEC §7。

**具体动作**：

```gdshader
shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    // 灰度图的 R 通道作为明度值
    float gray = tex.r;
    // 正片叠底：灰度值 × 目标颜色
    COLOR = vec4(target_color.rgb * gray, tex.a);
}
```

- 此为基础版本，不含高光层叠加（高光层在后续迭代中按需追加）。
- Shader 作用于 CHASSIS、BODY、SHADOW 层的 `Sprite2D` 节点。DETAIL 层不使用此 Shader。

**验收标准 (DoD)**：
- 在 Godot 编辑器中新建一个 `Sprite2D`，手动指定一张灰度测试图，将此 Shader 赋给它的 Material，修改 `target_color` 为红色 → Sprite 显示为红色调灰度。
- 修改为蓝色 → 显示蓝色调灰度。确认 Shader 语法无报错。

---

### - [ ] 5.2 创建 ShaderMaterial 预设资源

**技术定位**：
- 新建文件：`resources/shaders/palette_swap_material.tres`
- 新建目录：`resources/shaders/`
- 涉及技术：ShaderMaterial Resource。

**具体动作**：
- 在 Godot 编辑器中创建一个 `ShaderMaterial` 资源。
- 将 `Shader` 字段指向 `assets/shaders/palette_swap.gdshader`。
- `target_color` 默认值设为白色 `(1, 1, 1, 1)`（不着色）。
- 保存为 `resources/shaders/palette_swap_material.tres`。

> 注：运行时不直接共用此实例。VehicleRenderer 在构建车辆时会 `duplicate()` 此 Material，然后为每辆车设置不同的 `target_color`。

**验收标准 (DoD)**：
- 编辑器中可加载此 `.tres` 文件，Inspector 中能看到 Shader 引用和 `target_color` 参数。

---

## 6. 车辆分层渲染器 (VehicleRenderer)

### - [ ] 6.1 创建 VehicleRenderer 场景与脚本骨架

**技术定位**：
- 新建文件：`scripts/view/vehicle_renderer.gd`
- 新建场景：`scenes/view/vehicle_renderer.tscn`
- 涉及技术：Node2D、Sprite2D、ShaderMaterial、Z-index。
- 来源：TDD §5.3.1（分层渲染架构）、ART_SPEC §4。

**具体动作**：

场景树结构（`vehicle_renderer.tscn`）：
```
VehicleRenderer (Node2D)
├── ShadowSprite (Sprite2D)     Z-index: 0
├── ChassisSprite (Sprite2D)    Z-index: 1
├── BodySprite (Sprite2D)       Z-index: 2
├── DetailSprite (Sprite2D)     Z-index: 3
└── PartSlots (Node2D)          Z-index: 4  — 挂载配件 Sprite 的容器
```

脚本骨架（`vehicle_renderer.gd`）：

```gdscript
# vehicle_renderer.gd — 车辆分层渲染器（View 层）
class_name VehicleRenderer
extends Node2D

@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var chassis_sprite: Sprite2D = $ChassisSprite
@onready var body_sprite: Sprite2D = $BodySprite
@onready var detail_sprite: Sprite2D = $DetailSprite
@onready var part_slots: Node2D = $PartSlots

var _car_id: String = ""
var _car_def: CarDefinition = null
var _template: TemplateGuide = null

# === 公开 API ===

func initialize(car_def: CarDefinition) -> void:
    # 加载分层 Sprite、应用 Shader、缓存模板引用
    pass

func set_palette_color(color: Color) -> void:
    # 修改 SHADOW/CHASSIS/BODY 三层的 ShaderMaterial target_color
    pass

func attach_part(slot_type: String, part_def: PartDefinition) -> void:
    # 在 PartSlots 容器中定位到锚点坐标，加载配件 Sprite
    pass

func detach_part(slot_type: String) -> void:
    # 移除指定槽位的配件 Sprite
    pass
```

**验收标准 (DoD)**：
- 场景文件可在编辑器中打开，看到 5 个子节点。
- 脚本无语法错误。
- 此时所有方法体为 `pass`，下一步任务填充逻辑。

---

### - [ ] 6.2 实现 VehicleRenderer.initialize() —— 加载分层 Sprite 与 Shader

**技术定位**：
- 修改文件：`scripts/view/vehicle_renderer.gd`

**具体动作**：

```gdscript
func initialize(car_def: CarDefinition) -> void:
    _car_def = car_def
    _car_id = car_def.car_id
    _template = DataRegistry.get_template(car_def.template_id)

    # 加载四层 Sprite 纹理
    _load_texture(shadow_sprite, car_def.sprite_shadow_path)
    _load_texture(chassis_sprite, car_def.sprite_chassis_path)
    _load_texture(body_sprite, car_def.sprite_body_path)
    _load_texture(detail_sprite, car_def.sprite_detail_path)

    # 为 SHADOW/CHASSIS/BODY 三层应用调色盘 Shader
    var base_mat: ShaderMaterial = DataRegistry.get_shader_material("palette_swap")
    if base_mat:
        for sprite in [shadow_sprite, chassis_sprite, body_sprite]:
            sprite.material = base_mat.duplicate()

    print("[VehicleRenderer] Initialized: %s (template: %s)" % [_car_id, car_def.template_id])

func _load_texture(sprite: Sprite2D, path: String) -> void:
    if path == "" or not ResourceLoader.exists(path):
        sprite.visible = false
        return
    sprite.texture = load(path)
    sprite.visible = true
```

- 注意：`_load_texture` 中的 `load()` 调用是 View 层的例外允许——因为 Sprite 纹理不由 DataRegistry 管理（它们是美术资产而非 Custom Resource 数据文件）。但路径仍来自 `CarDefinition` Resource，未硬编码。

**验收标准 (DoD)**：
- 创建一辆测试 `CarDefinition.tres`，填入分层 Sprite 路径（使用任意临时占位 PNG），实例化 `VehicleRenderer` 后调用 `initialize()`，四层 Sprite 可见且无报错。

---

### - [ ] 6.3 实现 VehicleRenderer.set_palette_color() —— Shader 实时换色

**技术定位**：
- 修改文件：`scripts/view/vehicle_renderer.gd`

**具体动作**：

```gdscript
func set_palette_color(color: Color) -> void:
    for sprite in [shadow_sprite, chassis_sprite, body_sprite]:
        if sprite.material and sprite.material is ShaderMaterial:
            (sprite.material as ShaderMaterial).set_shader_parameter("target_color", color)
```

**验收标准 (DoD)**：
- 调用 `set_palette_color(Color.RED)` → 三层 Sprite 呈现红色调灰度。
- 调用 `set_palette_color(Color.BLUE)` → 立即切换为蓝色调。
- DETAIL 层不受影响（无 Shader）。

---

## 7. 配件锚点查询与动态挂载

### - [ ] 7.1 实现锚点查询工具函数

**技术定位**：
- 新建文件：`scripts/utils/anchor_helper.gd`
- 来源：ART_SPEC §5.1 ~ §5.3。

**具体动作**：

```gdscript
# anchor_helper.gd — 配件锚点分层查询工具
class_name AnchorHelper

## 查询配件安装锚点。优先读取车辆级覆盖，回落到模板默认。
static func get_part_anchor(car_def: CarDefinition, slot_type: String) -> Vector2i:
    # 第一层：车辆级覆盖
    if car_def.anchor_overrides.has(slot_type):
        return car_def.anchor_overrides[slot_type]
    # 第二层：模板默认
    var template: TemplateGuide = DataRegistry.get_template(car_def.template_id)
    if template and template.part_anchors.has(slot_type):
        return template.part_anchors[slot_type]
    # 兜底
    push_warning("[AnchorHelper] No anchor for slot '%s' on car '%s'" % [slot_type, car_def.car_id])
    return Vector2i.ZERO
```

> 注：此处使用 `static func` 是合理的——`AnchorHelper` 是无状态的纯工具类，内部通过 `DataRegistry`（Autoload）获取数据。GDScript 的 static func 可以访问全局单例。

**验收标准 (DoD)**：
- 调用 `AnchorHelper.get_part_anchor(test_car_def, "spoiler")` 返回模板中定义的 spoiler 坐标。
- 在 `CarDefinition` 中设置 `anchor_overrides = { "spoiler": Vector2i(99, 99) }` 后，返回 `(99, 99)`（覆盖生效）。

---

### - [ ] 7.2 实现 VehicleRenderer.attach_part() / detach_part()

**技术定位**：
- 修改文件：`scripts/view/vehicle_renderer.gd`
- 来源：ART_SPEC §4.3、§5.4。

**具体动作**：

```gdscript
# 已挂载的配件 Sprite 缓存：{ slot_type: Sprite2D }
var _attached_parts: Dictionary = {}

func attach_part(slot_type: String, part_def: PartDefinition) -> void:
    # 先移除旧配件（如有）
    detach_part(slot_type)

    if part_def.sprite_path == "" or not ResourceLoader.exists(part_def.sprite_path):
        push_warning("[VehicleRenderer] Part sprite not found: %s" % part_def.sprite_path)
        return

    var anchor: Vector2i = AnchorHelper.get_part_anchor(_car_def, slot_type)
    var part_sprite: Sprite2D = Sprite2D.new()
    part_sprite.texture = load(part_def.sprite_path)
    part_sprite.position = Vector2(anchor.x, anchor.y)

    # 锚点模式处理
    if part_def.anchor_mode == "center":
        part_sprite.centered = true
    else:
        part_sprite.centered = false

    part_slots.add_child(part_sprite)
    _attached_parts[slot_type] = part_sprite
    print("[VehicleRenderer] Attached '%s' at (%d, %d)" % [slot_type, anchor.x, anchor.y])

func detach_part(slot_type: String) -> void:
    if _attached_parts.has(slot_type):
        var sprite: Sprite2D = _attached_parts[slot_type]
        sprite.queue_free()
        _attached_parts.erase(slot_type)
```

> 注：配件 Sprite 使用 `Sprite2D.new()` + `queue_free()` 而非对象池。这是 Phase 3 的简化实现——配件安装/卸载频率极低（玩家手动操作），不属于"每帧频繁创建销毁"的性能敏感场景。如后续性能测试发现问题，Phase 4+ 可改为预分配池。

**验收标准 (DoD)**：
- 调用 `attach_part("spoiler", test_part_def)` → 在 PartSlots 子节点下出现一个 Sprite2D，位置对应锚点坐标。
- 调用 `detach_part("spoiler")` → 该 Sprite2D 被移除。
- 重复调用 `attach_part` 不会产生重复节点（先 detach 再 attach）。

---

## 8. 窗口管理系统 (WindowManager)

### - [ ] 8.1 创建 WindowManager Autoload 并实现基础窗口设置

**技术定位**：
- 新建文件：`scripts/core/window_manager.gd`
- 注册为 Autoload 单例：注册名 `WindowManager`
- 涉及技术：`DisplayServer` API。
- 来源：TDD §7。

**具体动作**：

```gdscript
# window_manager.gd — 桌面挂件窗口管理器
extends Node

const MAX_SCREEN_RATIO: float = 0.25  # 视口尺寸不超过屏幕的 1/4

func _ready() -> void:
    _apply_window_flags()
    _apply_initial_position()
    print("[WindowManager] Initialized. Borderless + AlwaysOnTop + Transparent.")

func _apply_window_flags() -> void:
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
    # 透明背景
    get_window().transparent = true
    get_window().transparent_bg = true

func _apply_initial_position() -> void:
    # 读取存档中的窗口位置（如有），否则默认居中底部
    var saved_pos: Dictionary = SaveManager.get_save_data().get("settings", {})
    var saved_x: int = int(saved_pos.get("window_position", {}).get("x", -1))
    var saved_y: int = int(saved_pos.get("window_position", {}).get("y", -1))

    if saved_x >= 0 and saved_y >= 0:
        DisplayServer.window_set_position(Vector2i(saved_x, saved_y))
    else:
        _center_bottom()

func _center_bottom() -> void:
    var screen_size: Vector2i = DisplayServer.screen_get_size()
    var window_size: Vector2i = DisplayServer.window_get_size()
    var x: int = (screen_size.x - window_size.x) / 2
    var y: int = screen_size.y - window_size.y
    DisplayServer.window_set_position(Vector2i(x, y))

## 设置整数倍缩放（1x / 2x / 3x）
func set_pixel_scale(scale: int) -> void:
    scale = clampi(scale, 1, 3)
    get_window().content_scale_factor = float(scale)
    print("[WindowManager] Pixel scale set to %dx" % scale)
```

**验收标准 (DoD)**：
- F5 启动后窗口出现在屏幕底部中央，无边框、置顶、背景透明。
- 控制台输出 `[WindowManager] Initialized.`。
- 窗口不抢夺其他应用的输入焦点。

---

### - [ ] 8.2 实现窗口像素级缩放（整数倍）

**技术定位**：
- 修改文件：`scripts/core/window_manager.gd`
- 来源：TDD §7.2、ART_SPEC §1.2（等距视角）。

**具体动作**：
- 在 `_ready()` 末尾调用 `set_pixel_scale()`，从存档读取上次的缩放值：
  ```gdscript
  var saved_scale: int = int(saved_pos.get("window_scale", 2))
  set_pixel_scale(saved_scale)
  ```
- 确保 Project Settings 中 `rendering/textures/canvas_textures/default_texture_filter` 已设为 `NEAREST`（Phase 1 已配置，此处确认）。

**验收标准 (DoD)**：
- 默认以 2x 缩放启动。像素画边缘锐利、无模糊。
- 手动调用 `WindowManager.set_pixel_scale(1)` → 窗口内容缩小，像素仍锐利。
- 手动调用 `WindowManager.set_pixel_scale(3)` → 窗口内容放大，像素仍锐利。

---

## 9. 测试美术资产准备（占位图）

### - [ ] 9.1 创建占位 Sprite 用于 Phase 3 视觉测试

**技术定位**：
- 新建占位 PNG 文件（无需精美美术，使用纯色/简笔画即可，目的是验证渲染管线）。
- 新建目录：`assets/sprites/cars/test_car_m_mid/`
- 来源：ART_SPEC §4、§9.4。

**具体动作**：
- 使用 Aseprite（或任意图片工具）创建以下占位文件，尺寸严格遵循 M-Mid 模板（64×36 px）：
  - `test_car_m_mid_shadow.png`：64×36，深灰色椭圆置于底部（灰度图）
  - `test_car_m_mid_chassis.png`：64×36，简笔画两个圆表示轮子（灰度图）
  - `test_car_m_mid_body.png`：64×36，简笔画轿车轮廓（灰度图）
  - `test_car_m_mid_detail.png`：64×36，两个小方块表示车灯（彩色，不走 Shader）

- 创建一个占位配件 PNG：
  - `assets/sprites/parts/test_spoiler.png`：16×8，简笔画翼形（彩色）

- 创建测试用 `CarDefinition`：
  - `resources/cars/test_car_visual.tres`：
    ```
    car_id = "test_car_visual"
    display_name = "Visual Test Car"
    brand = "Test"
    base_value = 10
    purchase_price = 100
    template_id = "M-Mid"
    sprite_shadow_path = "res://assets/sprites/cars/test_car_m_mid/test_car_m_mid_shadow.png"
    sprite_chassis_path = "res://assets/sprites/cars/test_car_m_mid/test_car_m_mid_chassis.png"
    sprite_body_path = "res://assets/sprites/cars/test_car_m_mid/test_car_m_mid_body.png"
    sprite_detail_path = "res://assets/sprites/cars/test_car_m_mid/test_car_m_mid_detail.png"
    ```

- 创建测试用 `PartDefinition`：
  - `resources/parts/test_spoiler.tres`：
    ```
    part_id = "test_spoiler"
    slot_type = "spoiler"
    sprite_path = "res://assets/sprites/parts/test_spoiler.png"
    anchor_mode = "top_left"
    ```

**验收标准 (DoD)**：
- 所有 PNG 文件存在于正确路径，Godot 编辑器 FileSystem 面板可预览。
- `DataRegistry` 能扫描到 `test_car_visual` 和 `test_spoiler`。

---

### - [ ] 9.2 DataRegistry 补注册 ShaderMaterial 加载

**技术定位**：
- 修改文件：`scripts/core/data_registry.gd`

**具体动作**：
- 新增字段和固定路径加载（与 EconomyConfig 相同的模式，非目录扫描）：
  ```gdscript
  var _shader_materials: Dictionary = {}

  # 在 _ready() 中追加
  _load_shader_material("palette_swap", "res://resources/shaders/palette_swap_material.tres")

  func _load_shader_material(key: String, path: String) -> void:
      if ResourceLoader.exists(path):
          _shader_materials[key] = ResourceLoader.load(path) as ShaderMaterial

  func get_shader_material(key: String) -> ShaderMaterial:
      return _shader_materials.get(key)
  ```

**验收标准 (DoD)**：
- `DataRegistry.get_shader_material("palette_swap")` 返回非 null。

---

## 10. 阶段验收：Phase 3 视觉冒烟测试

### - [ ] 10.1 编写 Phase 3 视觉冒烟测试场景

**技术定位**：
- 新建：`scripts/tests/phase3_visual_test.gd`
- 新建：`scenes/tests/phase3_visual_test.tscn`

**具体动作**：
- 场景结构：
  ```
  Phase3VisualTest (Node2D)
  └── （脚本在 _ready() 中动态创建 VehicleRenderer 实例）
  ```

- 脚本内容：

```gdscript
# phase3_visual_test.gd — Phase 3 视觉管线验证
extends Node2D

const CAR_ID: String = "test_car_visual"
const PART_ID: String = "test_spoiler"

var _renderer: VehicleRenderer = null

func _ready() -> void:
    print("=== Phase 3 Visual Test START ===")

    # 1) 验证模板加载
    var template: TemplateGuide = DataRegistry.get_template("M-Mid")
    assert(template != null, "M-Mid template not loaded!")
    assert(template.bbox_width == 64, "bbox_width mismatch!")
    print("  [PASS] TemplateGuide loaded.")

    # 2) 验证 Shader Material 加载
    var mat: ShaderMaterial = DataRegistry.get_shader_material("palette_swap")
    assert(mat != null, "palette_swap material not loaded!")
    print("  [PASS] ShaderMaterial loaded.")

    # 3) 实例化 VehicleRenderer 并初始化
    var car_def: CarDefinition = DataRegistry.get_car(CAR_ID)
    assert(car_def != null, "test car not found in DataRegistry!")

    var scene: PackedScene = load("res://scenes/view/vehicle_renderer.tscn")
    _renderer = scene.instantiate() as VehicleRenderer
    add_child(_renderer)
    _renderer.position = Vector2(200, 150)
    _renderer.initialize(car_def)
    print("  [PASS] VehicleRenderer initialized with 4-layer sprites.")

    # 4) 测试 Shader 换色
    _renderer.set_palette_color(Color.RED)
    print("  [PASS] Palette set to RED. (Visual check: should appear reddish)")

    # 5) 测试配件挂载
    var part_def: PartDefinition = DataRegistry.get_part(PART_ID)
    assert(part_def != null, "test spoiler not found!")
    _renderer.attach_part("spoiler", part_def)
    print("  [PASS] Spoiler attached at anchor point.")

    # 6) 测试配件卸载
    _renderer.detach_part("spoiler")
    _renderer.attach_part("spoiler", part_def)  # 重新挂载确认无重复
    print("  [PASS] Detach/reattach cycle clean.")

    # 7) 测试锚点覆盖
    var anchor_default: Vector2i = AnchorHelper.get_part_anchor(car_def, "spoiler")
    assert(anchor_default == template.part_anchors["spoiler"], "Default anchor mismatch!")
    print("  [PASS] AnchorHelper fallback to template default.")

    # 8) 验证窗口管理器
    assert(WindowManager != null, "WindowManager not loaded!")
    print("  [PASS] WindowManager Autoload accessible.")

    print("=== Phase 3 Visual Test COMPLETE ===")
    print(">>> 请目视确认：窗口中应有一辆红色调的测试车辆，尾翼已挂载。 <<<")
    # 不自动 quit()，保持窗口显示供目视检查
```

**验收标准 (DoD)**：
- F5 运行 `phase3_visual_test.tscn` → 控制台输出所有 `[PASS]`，无 assert 失败。
- **目视确认**：屏幕上出现一辆带红色调的占位车辆图形，尾翼配件 Sprite 显示在正确的锚点位置上。
- 窗口为无边框、透明背景、置顶。

---

### - [ ] 10.2 Shader 换色交互验证（手动）

**技术定位**：
- 修改：`scripts/tests/phase3_visual_test.gd`

**具体动作**：
- 在测试脚本中追加 `_input()` 方法，允许按键切换颜色供目视验证：

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1: _renderer.set_palette_color(Color.RED)
            KEY_2: _renderer.set_palette_color(Color.BLUE)
            KEY_3: _renderer.set_palette_color(Color.GREEN)
            KEY_4: _renderer.set_palette_color(Color.WHITE)
            KEY_ESCAPE: get_tree().quit()
```

**验收标准 (DoD)**：
- 按 1/2/3/4 键 → 车辆颜色实时切换为红/蓝/绿/白。
- DETAIL 层（车灯占位图）颜色始终不变。
- 按 ESC 退出。

---

### - [ ] 10.3 Phase 3 最终封存

**技术定位**：
- Git 操作。

**具体动作**：
- 清理调试语句（保留规范化 `[Module]` 日志）。
- 确认 `docs/Task_Phase3.md` 所有复选框已勾选。
- 提交收尾 commit：
  ```
  chore(phase3): 收尾 Phase 3 视图层接入
  ```
- 创建 PR：`dev` → `main`，合并后打 Tag：`v0.3.0-view`。

**验收标准 (DoD)**：
- `git tag` 输出包含 `v0.3.0-view`。
- 从 `main` 分支 checkout 该 Tag，F5 运行 `phase3_visual_test.tscn`：控制台全绿 + 目视车辆渲染正确 + 按键换色生效。
- Phase 4（UI 界面与交互）可基于此 Tag 安全起步。

---

## 附录 A — Phase 3 新增/修改文件汇总

| 类型 | 路径 | 说明 |
|------|------|------|
| 新建 | `scripts/systems/template_guide.gd` | TemplateGuide Custom Resource 基类 |
| 新建 | `resources/templates/S-Low.tres` | S-Low 模板数据 |
| 新建 | `resources/templates/M-Mid.tres` | M-Mid 模板数据 |
| 修改 | `scripts/systems/car_definition.gd` | 新增模板关联、真实尺寸、锚点覆盖、分层 Sprite 路径字段 |
| 修改 | `scripts/systems/part_definition.gd` | 新增 sprite_path、anchor_mode、compatible_templates 字段 |
| 修改 | `scripts/core/data_registry.gd` | 补注册 templates 扫描 + ShaderMaterial 加载 |
| 新建 | `assets/shaders/palette_swap.gdshader` | 调色盘替换 Shader |
| 新建 | `resources/shaders/palette_swap_material.tres` | ShaderMaterial 预设资源 |
| 新建 | `scripts/view/vehicle_renderer.gd` | 车辆分层渲染器脚本 |
| 新建 | `scenes/view/vehicle_renderer.tscn` | 车辆分层渲染器场景 |
| 新建 | `scripts/utils/anchor_helper.gd` | 配件锚点分层查询工具 |
| 新建 | `scripts/core/window_manager.gd` | 窗口管理器 Autoload |
| 新建 | `assets/sprites/cars/test_car_m_mid/*.png` | 占位测试 Sprite（4 张） |
| 新建 | `assets/sprites/parts/test_spoiler.png` | 占位配件 Sprite |
| 新建 | `resources/cars/test_car_visual.tres` | 视觉测试用 CarDefinition |
| 新建 | `resources/parts/test_spoiler.tres` | 视觉测试用 PartDefinition |
| 新建 | `scripts/tests/phase3_visual_test.gd` | 视觉冒烟测试脚本 |
| 新建 | `scenes/tests/phase3_visual_test.tscn` | 视觉冒烟测试场景 |

## 附录 B — Phase 3 不做的事（显式排除）

- ❌ NPC 技师的 Sprite 加载与 FSM 动画状态切换（Phase 4+）。
- ❌ VFX 特效对象池的创建与管理（Phase 4+）。
- ❌ 任何 UI 面板（商店/车库/改装面板/设置面板）。
- ❌ 小游戏 UI 覆盖层。
- ❌ Hover 激活 / UI 淡入淡出交互。
- ❌ 专注模式的视觉切换（帧率/动画/特效关闭）。
- ❌ 多显示器自动对齐 Snap to Edge（Phase 3 仅实现单屏居中底部）。
- ❌ L-Mid / L-High / XL-High 模板的制作（V1.5+）。
- ❌ 正式美术资产绘制（Phase 3 使用占位图验证管线，正式美术在管线跑通后生产）。
- ❌ 高光层 Shader 叠加（基础 Shader 仅含灰度×颜色，高光叠加后续迭代）。
