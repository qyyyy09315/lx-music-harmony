# 洛雪音乐鸿蒙版 (LX Music Harmony) 文档中心

欢迎查阅 **LX Music Harmony** 移植项目的工程与技术文档库。本文档集旨在为人类开发者与 AI Agent 提供清晰、精准、机器可读的项目全景，便于随时进行上下文恢复与高效协同开发。

---

## 📚 文档目录索引

| 文档名称 | 对应文件 | 说明 | 推荐阅读对象 |
| :--- | :--- | :--- | :--- |
| **🚀 Agent 极速恢复手册** | [`doc/agent-handbook.md`](./agent-handbook.md) | **新 Agent 接手必读**：包含 30 秒上下文重建、环境指引、命令速查与自检清单 | AI Agent / 开发者 |
| **🏗️ 系统架构与设计** | [`doc/architecture.md`](./architecture.md) | 总体技术栈、Stage 模型架构图、分层设计、跨端差异与模块拓扑 | 架构师 / 核心开发 |
| **📋 模块技术规范** | [`doc/tech-spec.md`](./tech-spec.md) | 播放引擎、AVSession、歌词解析器、数据持久化与 User API 规范 | 模块开发者 |
| **📅 工作日志与演进** | [`doc/worklog.md`](./worklog.md) | 按时间线记录的架构决策、移植历程与版本变动记录 | 全体维护者 |
| **📌 路线图与待办事项** | [`doc/roadmap-todo.md`](./roadmap-todo.md) | 分阶段开发计划、当前任务进度、未解决问题与验收标准 | 项目管理者 / 协作 Agent |
| **⚖️ 规范与文档自维护规则** | [`doc/rules.md`](./rules.md) | 代码风格、提交规范、**文档自动同步与更新强制守则** | 全体贡献者 |

---

## ⚡ 快速定位代码

* **核心播放引擎**：`entry/src/main/ets/services/AudioPlayerService.ets`
* **系统播控中心**：`entry/src/main/ets/services/AVSessionService.ets`
* **歌词解析算法**：`entry/src/main/ets/common/LyricParser.ets`
* **数据持久化**：`entry/src/main/ets/services/StorageService.ets`
* **核心数据模型**：`entry/src/main/ets/model/MusicModel.ets`
* **主界面与路由**：`entry/src/main/ets/pages/Index.ets`
* **UI 组件库**：`entry/src/main/ets/view/`
