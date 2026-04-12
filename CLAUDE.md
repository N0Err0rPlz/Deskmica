# CLAUDE.md — Claude Code 项目指令

## 项目概述
本项目是一款基于 Godot 4.6.2 的 2D 像素风桌面挂机游戏（项目代号：Desktop Garage）。
编程语言为 GDScript。

## 核心文档
- `docs/TDD.md` 是本项目的技术设计文档（真理之源），所有代码必须严格遵循其中的架构规范。
- `docs/Task_Phase1.md` 是当前阶段的开发任务清单，按顺序执行。

## 铁律（每次写代码前必须回顾）
1. 禁止使用任何 Unity/Unreal 的术语或思维。
2. 事件驱动只用 Godot Signals。
3. 数据配置只用 Custom Resource 或 JSON，禁止在脚本中硬编码数值。
4. 禁止在业务逻辑中零散使用 load() 或 preload()，所有资源通过 DataRegistry 获取。
5. TDD 4.1 章列出的 Autoload 单例禁止作为普通子节点挂载。
6. 所有特效必须走对象池，禁止运行时 instantiate()/queue_free()。

## 代码规范
- 所有 GDScript 使用静态类型标注（如 `var x: int = 0`，`func foo() -> void:`）。
- 每个新建/修改的脚本文件开头注明用途的单行注释。
- 每完成一个 Task.md 中的子任务后，提醒我进行 git commit。

## 当前阶段
Phase 1 — 纯净底层框架与核心数据字典。
不涉及 UI、美术、游戏玩法表现逻辑。