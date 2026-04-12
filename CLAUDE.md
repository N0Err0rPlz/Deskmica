# CLAUDE.md — Claude Code 项目指令

## 项目概述
本项目是一款基于 Godot 4.6.2 的 2D 像素风桌面挂机游戏（项目代号：Deskmica）。
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

## Commit Message 规范
所有 commit 必须遵循 Conventional Commits 格式：

格式：`<type>(<scope>): <subject>`

- **type**（必须，英文小写）：
  - `feat` 新功能 / `fix` bug 修复 / `docs` 文档 / `style` 格式（不影响代码运行）
  - `refactor` 重构 / `perf` 性能优化 / `test` 测试 / `build` 构建系统或依赖
  - `ci` CI 配置 / `chore` 杂项 / `revert` 回滚
  - `art` 美术资产（项目扩展，用于 Aseprite 精灵图、调色盘等资源提交，必须与代码逻辑 commit 分开）
- **scope**（可选，英文）：影响范围，如 `core`、`save`、`ui`、`signal-bus`
- **subject**（必须，中文）：简短描述，不加句号，祈使句式（"新增 XX" 而非 "新增了 XX"）
- **body**（可选，中文）：空一行后书写，说明动机与细节
- **footer**（可选）：破坏性变更用 `BREAKING CHANGE:` 开头；关联 issue 用 `Closes #12`

示例：
- `feat(save): 新增存档版本号字段`
- `fix(signal-bus): 修复多订阅者触发顺序错乱`
- `docs: 补齐 TDD 第 4 章 Autoload 列表`
- `chore: 统一项目代号为 Deskmica`

## 当前阶段
Phase 1 — 纯净底层框架与核心数据字典。
不涉及 UI、美术、游戏玩法表现逻辑。