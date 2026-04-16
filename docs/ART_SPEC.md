# ART_SPEC.md — 美术资产规格文档

**项目代号**：Deskmica
**引擎**：Godot 4.6.2
**美术工具**：Aseprite
**文档版本**：v1.0
**最后更新**：2026-04-17

---

> **本文档的定位**
> 这是 Deskmica 项目所有 2D 像素美术资产的生产规范与约束标准。所有车辆、配件、NPC 的绘制必须严格遵循本文档中的模板系统、分层结构和命名规范。本文档与 `TDD.md` 共同构成项目的技术基准。
>
> **核心理念**：模板导引图不是用来画车的，而是用来防止画错车的。

---

## 目录

1. [尺度与视角规范](#1-尺度与视角规范)
2. [模板引导系统](#2-模板引导系统-template-guide)
3. [模板分类标准](#3-模板分类标准-class-tiers)
4. [车辆资产分层结构](#4-车辆资产分层结构)
5. [配件锚点系统](#5-配件锚点系统-part-anchor-system)
6. [Aseprite 图层规范](#6-aseprite-图层规范)
7. [调色盘替换 Shader 规范](#7-调色盘替换-shader-规范)
8. [NPC 技师美术规范](#8-npc-技师美术规范)
9. [文件命名与目录规范](#9-文件命名与目录规范)
10. [美术生产管线](#10-美术生产管线-pipeline)
11. [导出校验规则](#11-导出校验规则)
12. [V1.0 优先级与排期](#12-v10-优先级与排期)
13. [严禁事项](#13-严禁事项-red-lines)

---

## 1. 尺度与视角规范

### 1.1 比例尺

全局统一比例尺：**1px = 5cm**。

| 真实参照 | 真实尺寸 | 像素尺寸 |
|----------|----------|----------|
| 成年人身高 | 175cm | 35px |
| 紧凑型轿车车长 | 4500mm | 90px（等距投影后约 64px） |
| 轮毂直径（17寸） | 43cm | 8-9px |

### 1.2 等距视角

采用标准等距视角（2:1 像素斜线），但**不是严格等距投影**。遵循"结构严格、表现允许修正"的双轨原则。

**必须严格等距的要素**（不允许视觉偏差）：

- 轮位坐标（Wheel Centers）
- 车长方向的比例关系
- 地面接触线（Ground Line）

**允许视觉修正的要素**（为了"看起来对"而偏离数学投影）：

| 修正项 | 修正范围 | 原因 |
|--------|----------|------|
| 车身高度 | ×1.0 ~ 1.2 | 纯等距投影下车辆显得过扁 |
| 车身宽度 | +10% ~ 15% | 增强体量感 |
| 阴影投影 | 非等距方向 | 使用平面化阴影更自然 |

### 1.3 数据驱动模式

车辆的视觉尺寸不由美术主观判断，而由数据驱动生成：

```
真实尺寸 (cm) → 比例尺换算 → 等距投影 → 视觉修正系数 → 最终像素尺寸
```

输入数据来源为 `CarDefinition` Custom Resource 中的真实参数（长/宽/高/轴距）。

---

## 2. 模板引导系统 (Template Guide)

### 2.1 核心定义

模板导引图是**美术生产的约束工具**，不是游戏运行时资产。它在 Aseprite 中以锁定图层的形式存在，约束美术人员在正确的范围内绘制。

生产流程：

```
CarDefinition（真实尺寸数据）
  → 匹配模板分类（Template Class）
  → 生成模板导引图（Template Guide）
  → 美术在导引图约束下填充 Sprite
  → 导出分层 PNG
  → 引擎加载
```

### 2.2 模板必须包含的 5 个结构要素

| 要素 | 作用 | 说明 |
|------|------|------|
| **Bounding Box** | 限制最大绘制范围 | 基于长/宽/高生成的像素矩形，任何笔触不得超出此范围 |
| **Ground Line** | 统一接地基准 | 所有车辆的轮胎底部必须对齐到此线，确保多车并排时视觉对齐 |
| **Wheel Centers** | 固定轮位坐标 | 基于轴距和轮距计算，精确到像素，配件安装的基准参考 |
| **Height Guide** | 高度控制参考 | 标注腰线、车顶等关键高度位置 |
| **Shadow Area** | 阴影范围预设 | 定义投影影响区域的椭圆参考范围 |

### 2.3 模板数据结构（TemplateGuide Custom Resource）

模板数据在引擎中以 Custom Resource 形式存在，由 `DataRegistry` 管理。

```
TemplateGuide.tres:
  template_id: String              # "S-Low" / "M-Mid" / ...
  display_name: String             # "紧凑型低矮"
  bbox_width: int                  # Bounding Box 宽度（像素）
  bbox_height: int                 # Bounding Box 高度（像素）
  ground_line_y: int               # 接地线 Y 坐标（像素，从顶部计）
  wheel_front: Vector2i            # 前轮轮心坐标
  wheel_rear: Vector2i             # 后轮轮心坐标
  shadow_ellipse_rx: int           # 阴影椭圆长半轴
  shadow_ellipse_ry: int           # 阴影椭圆短半轴
  shadow_offset_y: int             # 阴影椭圆中心 Y 偏移
  part_anchors: Dictionary         # 默认配件安装锚点（见第 5 章）
```

---

## 3. 模板分类标准 (Class Tiers)

### 3.1 五档分类

分类维度为**尺寸 + 高度**的混合方式：

| 模板 ID | 名称 | 对应车型 | V1.0 优先级 |
|---------|------|----------|-------------|
| `S-Low` | 微型/小型低矮 | A00/A0 级别：Miata、86/BRZ、Civic | ★★★ 首批制作 |
| `M-Mid` | 中型标准 | A/B/C 级轿车、超级跑车：3 Series、Supra、911、GT-R | ★★★ 首批制作 |
| `L-Mid` | 大型标准 | D/F 级长轴轿车、中大型 SUV：S-Class、X5 | ☆ V1.5+ |
| `L-High` | 大型高位 | 硬派 SUV / 越野车：G-Wagon、Land Cruiser | ☆ V1.5+ |
| `XL-High` | 超大高位 | 皮卡 / 全尺寸大型车：F-150、Ram | ☆ V2.0+ |

### 3.2 模板选型规则

一辆车归属哪个模板，由 `CarDefinition` 中的真实尺寸参数自动匹配：

| 条件 | 匹配模板 |
|------|----------|
| 车长 ≤ 4300mm 且 车高 ≤ 1350mm | S-Low |
| 车长 4300-5000mm 且 车高 ≤ 1500mm | M-Mid |
| 车长 > 5000mm 且 车高 ≤ 1600mm | L-Mid |
| 车高 > 1600mm 且 车长 ≤ 5200mm | L-High |
| 车长 > 5200mm 且 车高 > 1600mm | XL-High |

> 注：以上阈值为初始参考值，可在 `TemplateGuide` Resource 的配置中调整。边界情况由美术负责人手动指定 `template_id` 覆盖自动匹配。

---

## 4. 车辆资产分层结构

### 4.1 四层结构

每辆车辆在 Aseprite 中绘制为 4 个独立图层，导出为 4 张独立 PNG，在引擎中作为 4 个 `Sprite2D` 节点按 Z-index 叠加渲染：

| 图层（从底到顶） | Aseprite 图层名 | 引擎节点 | 内容 | 支持调色 |
|------------------|-----------------|----------|------|----------|
| 1. 阴影层 | `SHADOW` | `Sprite2D` (Z: 0) | 独立于车身的地面投影 | 是（Shader） |
| 2. 底盘层 | `CHASSIS` | `Sprite2D` (Z: 1) | 轮毂、悬挂可见部分、底盘细节 | 是（Shader） |
| 3. 车身层 | `BODY` | `Sprite2D` (Z: 2) | 车辆主体外壳 | 是（Shader） |
| 4. 细节层 | `DETAIL` | `Sprite2D` (Z: 3) | 灯组、Logo、改装件（Kits）、内饰可见部分 | 部分 |

### 4.2 分层原则

- **SHADOW** 必须独立导出，不得与车身合并，以便 Shader 独立控制透明度和颜色。
- **CHASSIS** 包含所有"车身以下"的可见内容，是调色盘替换的主要目标之一。
- **BODY** 是面积最大的图层，绘制车辆外壳轮廓和基础涂装。
- **DETAIL** 是改装件的视觉呈现层。当玩家安装/更换配件时，引擎替换此层的 Sprite 或在此层上叠加配件 Sprite。

### 4.3 改装件的视觉叠加方式

改装件不重画整车，而是作为**独立 Sprite 叠加在 DETAIL 层上方**（或替换 DETAIL 层的局部区域）。每个改装件有自己独立的 PNG 文件，引擎根据 `PartDefinition` 中的 `slot_type` 和配件锚点坐标（见第 5 章），将配件 Sprite 定位到正确的像素位置。

---

## 5. 配件锚点系统 (Part Anchor System)

### 5.1 分层锚点策略

采用**模板提供默认锚点、车辆级别可选覆盖**的分层方案：

**第一层（模板级默认锚点）**：每个 `TemplateGuide` Resource 中定义一组默认的配件安装槽位坐标。同一模板下的所有车辆共享这套默认锚点。

**第二层（车辆级覆盖锚点）**：`CarDefinition` 中增加一个可选的 `anchor_overrides` 字段。仅当某辆车的特定槽位需要微调时才填写，未填写的槽位自动回落（fallback）到模板默认值。

### 5.2 模板默认锚点（TemplateGuide 中的 part_anchors）

```json
"part_anchors": {
  "front_bumper":     { "x": 8,  "y": 28 },
  "rear_bumper":      { "x": 56, "y": 28 },
  "side_skirt_left":  { "x": 12, "y": 30 },
  "side_skirt_right": { "x": 52, "y": 30 },
  "spoiler":          { "x": 32, "y": 12 },
  "hood":             { "x": 24, "y": 16 },
  "wheels_front":     { "x": 18, "y": 32 },
  "wheels_rear":      { "x": 46, "y": 32 }
}
```

> 注：以上坐标为 M-Mid 模板的示意值，实际值在制作模板时精确标定。

### 5.3 车辆级覆盖（CarDefinition 中的 anchor_overrides）

```
CarDefinition.tres:
  # ... 原有字段 ...
  anchor_overrides: Dictionary = {}
  # 示例：BMW E30 的尾翼位置比模板默认值高 2px
  # anchor_overrides = { "spoiler": Vector2i(32, 10) }
```

**引擎侧的锚点查询逻辑**（伪代码）：

```gdscript
func get_part_anchor(car_def: CarDefinition, slot_type: String) -> Vector2i:
    # 优先查车辆级覆盖
    if car_def.anchor_overrides.has(slot_type):
        return car_def.anchor_overrides[slot_type]
    # 回落到模板默认
    var template: TemplateGuide = DataRegistry.get_template(car_def.template_id)
    if template and template.part_anchors.has(slot_type):
        return template.part_anchors[slot_type]
    # 兜底
    push_warning("No anchor found for slot: %s" % slot_type)
    return Vector2i.ZERO
```

### 5.4 配件 Sprite 的对齐规则

- 每个配件 Sprite 的**左上角原点**对齐到锚点坐标位置。
- 如果配件需要居中对齐（如尾翼），则在 `PartDefinition` 中增加 `anchor_mode: String`（`"top_left"` / `"center"`），引擎加载时自动偏移半宽半高。
- 配件 Sprite 的尺寸**不得超出** `TemplateGuide.bbox` 的范围。

---

## 6. Aseprite 图层规范

### 6.1 Aseprite 文件中的完整图层栈（从底到顶）

```
[LOCKED] GUIDE_SHADOW      — 阴影范围导引（紫色，不导出）
[LOCKED] GUIDE_BBOX         — Bounding Box 导引（红色，不导出）
[LOCKED] GUIDE_GROUND       — 接地线导引（绿色，不导出）
[LOCKED] GUIDE_WHEELS       — 轮位导引（蓝色，不导出）
[LOCKED] GUIDE_HEIGHT       — 高度导引（黄色，不导出）
[LOCKED] GUIDE_ANCHORS      — 配件锚点导引（橙色，不导出）
─────────────────────────────
SHADOW                       — 阴影层（导出）
CHASSIS                      — 底盘层（导出）
BODY                         — 车身层（导出）
DETAIL                       — 细节层（导出）
```

**规则**：
- 所有 `GUIDE_*` 层必须设为 `[LOCKED]`，防止误触修改。
- `GUIDE_*` 层仅存在于 Aseprite 源文件中，**不随 PNG 导出**。
- 新增 `GUIDE_ANCHORS` 层用于可视化标注配件安装锚点位置。

### 6.2 配件 Aseprite 文件的图层栈

改装配件使用独立的 Aseprite 文件，图层更简单：

```
[LOCKED] GUIDE_BBOX         — 配件 Bounding Box（不导出）
[LOCKED] GUIDE_ANCHOR       — 安装锚点标记（不导出）
─────────────────────────────
PART                         — 配件图层（导出）
PART_SHADOW                  — 配件阴影（如有，导出）
```

---

## 7. 调色盘替换 Shader 规范

### 7.1 灰度图制作要求

使用调色盘替换 Shader 的图层（CHASSIS、BODY、SHADOW）需要以**灰度图**形式绘制基础版本：

- 灰度值 `0.0`（纯黑）= 最深阴影
- 灰度值 `0.5`（中灰）= 基础色调
- 灰度值 `1.0`（纯白）= 最亮高光

运行时 Shader 将灰度值乘以目标颜色，实现同一车型不同涂装的动态着色。

### 7.2 不参与调色的区域

以下内容**不使用灰度图**，直接以最终颜色绘制：

- 灯组（车灯始终保持固定颜色）
- 品牌 Logo
- 轮毂花纹细节
- 车窗玻璃

这些内容绘制在 DETAIL 层，不受调色盘 Shader 影响。

### 7.3 Shader 引用

参见 TDD 第 8 章「渲染管线与 Shader」中的 Godot Shading Language 实现。每辆车通过 `CarDefinition.palette_id` 关联调色方案。

---

## 8. NPC 技师美术规范

### 8.1 技师分层结构

NPC 技师同样采用分层渲染，与 TDD 5.3.1 章一致：

| 图层 | 内容 | 动画 |
|------|------|------|
| 底盘层（Chassis） | 脚部/移动 | `Idle` / `Move` 循环 |
| 躯干层（Torso） | 身体主体 | 轻微上下浮动（呼吸感） |
| 动作层（Work） | 手持工具/动作 | 根据 `animation_key` 切换 |
| 特效层（VFX） | 火花、灰尘 | 由对象池管理 |

### 8.2 技师基础尺寸

以 1px = 5cm 比例尺，成年人 175cm：

- 基础尺寸：**32×35 px**（宽×高）
- Spritesheet 帧排列：**水平排列**

### 8.3 调色盘复用

技师使用与车辆相同的灰度图 + Shader 调色方案。不同专精的技师通过更换 `SpecialtyData.sprite_palette_id` 实现颜色区分（如焊接工偏橙、喷漆工偏蓝）。

---

## 9. 文件命名与目录规范

### 9.1 车辆资产文件命名

```
{brand}_{model}_{template_id}_{layer}.png
```

示例：

| 文件名 | 说明 |
|--------|------|
| `bmw_e30_M-Mid_shadow.png` | BMW E30 阴影层 |
| `bmw_e30_M-Mid_chassis.png` | BMW E30 底盘层 |
| `bmw_e30_M-Mid_body.png` | BMW E30 车身层 |
| `bmw_e30_M-Mid_detail.png` | BMW E30 细节层 |

### 9.2 配件资产文件命名

```
{brand}_{part_type}_{slot_type}.png
```

示例：

| 文件名 | 说明 |
|--------|------|
| `rwb_widebody_front_bumper.png` | RWB 宽体前包围 |
| `bbs_rs_wheels.png` | BBS RS 轮毂 |
| `generic_carbon_spoiler.png` | 通用碳纤维尾翼 |

### 9.3 NPC 技师资产文件命名

```
mechanic_{specialty}_{animation_key}_{width}x{height}.png
```

示例：`mechanic_bodywork_welding_32x35.png`

### 9.4 目录结构

```
assets/
├── sprites/
│   ├── cars/
│   │   ├── bmw_e30/
│   │   │   ├── bmw_e30_M-Mid_shadow.png
│   │   │   ├── bmw_e30_M-Mid_chassis.png
│   │   │   ├── bmw_e30_M-Mid_body.png
│   │   │   └── bmw_e30_M-Mid_detail.png
│   │   └── nissan_s13/
│   │       └── ...
│   ├── parts/
│   │   ├── rwb_widebody_front_bumper.png
│   │   ├── bbs_rs_wheels.png
│   │   └── ...
│   ├── mechanics/
│   │   ├── mechanic_bodywork_welding_32x35.png
│   │   ├── mechanic_paint_spraying_32x35.png
│   │   └── ...
│   └── vfx/
│       ├── spark_16x16.png
│       ├── coin_text_32x16.png
│       └── ...
├── templates/
│   ├── S-Low_guide.aseprite      — 模板 Aseprite 源文件（不导出到引擎）
│   ├── M-Mid_guide.aseprite
│   └── ...
└── shaders/
    └── palette_swap.gdshader
```

---

## 10. 美术生产管线 (Pipeline)

### 10.1 六阶段流程

| 阶段 | 名称 | 动作 | 输入 | 输出 |
|------|------|------|------|------|
| Stage 0 | 数据定义 | 在 `CarDefinition` 中填入真实尺寸参数 | 车辆技术资料 | `.tres` 数据文件 |
| Stage 1 | 模板选型 | 根据尺寸自动或手动匹配模板等级 | `CarDefinition` | `template_id` |
| Stage 2 | 导引图生成 | 在 Aseprite 中基于模板创建导引层 | `TemplateGuide` 数据 | `.aseprite` 源文件 |
| Stage 3 | 美术填充 | 在导引线约束下逐层绘制（CHASSIS → BODY → DETAIL → SHADOW） | 导引图 | 完成的 `.aseprite` 文件 |
| Stage 4 | 导出与校验 | 分层导出 PNG，执行校验规则（见第 11 章） | `.aseprite` 文件 | 4 张分层 `.png` |
| Stage 5 | 引擎接入 | 将 PNG 放入 `assets/sprites/cars/` 目录，配置 `CarDefinition.sprite_path` | `.png` 文件 | 引擎可加载的资产 |

### 10.2 配件生产流程

| 阶段 | 动作 |
|------|------|
| 1 | 确定目标模板（该配件适用于哪个模板等级的车辆） |
| 2 | 从模板 `part_anchors` 中获取安装锚点坐标 |
| 3 | 在 Aseprite 中以锚点为基准绘制配件 Sprite |
| 4 | 导出 PNG，确认尺寸不超出模板 Bounding Box |
| 5 | 创建 `PartDefinition.tres`，填入 `slot_type` 和可选的 `anchor_mode` |

---

## 11. 导出校验规则

每次从 Aseprite 导出 PNG 后，必须执行以下校验（可人工目检，后续可写自动化脚本）：

| 校验项 | 规则 | 失败处理 |
|--------|------|----------|
| 尺寸一致 | 导出 PNG 的像素尺寸必须与 `TemplateGuide.bbox` 完全一致 | 退回重导 |
| 透明边界 | 车辆像素不得超出 Bounding Box 范围 | 退回修改 |
| 轮位对齐 | 轮胎底部必须落在 `ground_line_y` ±1px 内 | 退回修改 |
| 轮心对齐 | 轮心必须在 `wheel_front` / `wheel_rear` 的 ±1px 内 | 退回修改 |
| 图层完整 | 4 个图层（SHADOW/CHASSIS/BODY/DETAIL）必须全部导出 | 补导缺失图层 |
| 导引层清除 | 导出的 PNG 中不得包含任何 `GUIDE_*` 图层内容 | 重新导出 |
| 命名合规 | 文件名必须符合第 9 章命名规范 | 重命名 |

---

## 12. V1.0 优先级与排期

### 12.1 模板制作优先级

| 优先级 | 模板 | 时机 |
|--------|------|------|
| P0（Phase 3 首批） | `S-Low`、`M-Mid` | Phase 3 第一批任务 |
| P1（V1.5 扩展） | `L-Mid`、`L-High` | 核心循环跑通后 |
| P2（V2.0 扩展） | `XL-High` | 有明确内容需求时 |

### 12.2 V1.0 最小美术资产清单

| 资产类型 | 数量 | 说明 |
|----------|------|------|
| 模板导引图 | 2 个 | S-Low + M-Mid |
| 测试车辆完整 Sprite | 1-2 辆 | 各模板至少 1 辆，验证全管线 |
| 改装配件 Sprite | 3-5 件 | 至少覆盖前包围、尾翼、轮毂 3 个槽位 |
| NPC 技师 Spritesheet | 1 套 | 含 Idle / Move / Welding / Painting 动画 |
| VFX 特效贴图 | 2-3 种 | 火花、金币飘字 |

---

## 13. 严禁事项 (Red Lines)

- ❌ 禁止绕过模板导引图直接手绘车辆资产。
- ❌ 禁止随意修改 `GUIDE_*` 锁定层中的轮位、轴距等像素坐标。
- ❌ 禁止将阴影层与车身层合并为单层导出。
- ❌ 禁止在不破坏视觉连贯性的前提下随意改变车辆长宽比例。
- ❌ 禁止在导出 PNG 中残留导引层内容。
- ❌ 禁止在非 `DETAIL` 层绘制可替换的改装件内容。
- ❌ 禁止配件 Sprite 超出模板 Bounding Box 范围。
- ❌ 禁止在运行时动态创建/销毁 Sprite 节点（必须走对象池或预加载切换）。

---

> **文档结束。本 ART_SPEC 为 Deskmica 项目所有美术资产生产的唯一约束标准。**
