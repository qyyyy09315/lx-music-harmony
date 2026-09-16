# 协作规范与文档自动自维护规则 (Rules & Doc Maintenance)

为了保证人类开发者与多 Agent 协作时代码的高质量、文档的强时效性与上下文连贯性，本项目确立以下**强制执行规则**。

---

## 1. 文档自动完善守则 (Doc Auto-Maintenance Protocol)

任何开发者或 Agent 在完成代码修改或功能交付前，**必须遵循以下三步自维护流程**：

```
┌─────────────────────────┐     ┌──────────────────────────┐     ┌────────────────────────┐
│  1. 检查代码改动范围    │ ──> │  2. 同步更新关联文档     │ ──> │  3. 原子提交与推送     │
│  - 新增接口/实体模型    │     │  - doc/worklog.md (日志) │     │  - Git commit 规范     │
│  - 重构逻辑/修复缺陷    │     │  - doc/roadmap-todo.md   │     │  - 推送至 GitHub main  │
│  - 新增/调整页面组件    │     │  - doc/tech-spec.md      │     │                        │
└─────────────────────────┘     └──────────────────────────┘     └────────────────────────┘
```

### 具体更新规则对照表：
| 代码变更类型 | 必须同步更新的文档 | 必须补充的内容 |
| :--- | :--- | :--- |
| **新增功能 / 模块实现** | `doc/worklog.md`<br>`doc/roadmap-todo.md`<br>`doc/tech-spec.md` | • 工作日志记录日期与特性描述<br>• 将待办事项标记为 🟢 `[DONE]`<br>• 补充新模块类定义、公开方法与参数契约 |
| **数据模型变更 (Model)** | `doc/tech-spec.md` | • 更新数据接口与字段说明 |
| **架构调整 / 依赖升级** | `doc/architecture.md`<br>`doc/worklog.md` | • 更新架构拓扑图或技术映射表<br>• 记录升级决策与原因 |
| **重命名目录 / 工程调整** | `doc/agent-handbook.md`<br>`doc/README.md`<br>`README.md` | • 更新路径速查表与目录树说明 |

---

## 2. ArkTS 编码规范

1. **命名约定**：
   * 组件与类名：大驼峰（`PlayDetailModal`、`AudioPlayerService`）；
   * 文件名：组件使用大驼峰（`LyricView.ets`），服务与工具使用大驼峰或小驼峰，页面入口放在 `pages/`；
   * 变量与属性：小驼峰（`currentMusic`、`playState`）；
   * 枚举与常量：全大写下划线（`LIST_LOOP`、`KEY_COLLECTION_LIST`）。
2. **状态与属性管理**：
   * 组件内部私有状态使用 `@State`；
   * 父子单向传递使用 `@Prop`；
   * 跨页面或全局生命周期共享状态使用单例服务监听或 `AppStorage`。
3. **异常处理**：
   * 涉及底层平台 API（`AVPlayer`, `Preferences`, `AVSession`, `NAPI`）的所有异步调用，必须使用 `try...catch` 包裹并输出结构化 `console.error` 日志。

---

## 3. Git 提交信息规范 (Conventional Commits)

每次提交必须采用规范前缀：
* `feat:` 新增功能（如: `feat: implement user api quickjs bridge`）
* `fix:` 修复问题（如: `fix: handle audio focus interruption`）
* `docs:` 文档更新（如: `docs: update roadmap and tech spec`）
* `refactor:` 代码重构（不改变外部功能的优化）
* `style:` 格式调整与 UI 样式微调
* `chore:` 构建配置或工程杂项维护
