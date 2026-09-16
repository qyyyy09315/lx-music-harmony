# 路线图与待办事项清单 (Roadmap & TODO)

本文档是项目的动态任务跟踪看板，任何开发者或 AI Agent 在接手任务时，均需依据本看板认领并更新进度。

---

## 🚦 状态图例说明
* 🟢 **`[DONE]`**：已完成并经验证
* 🟡 **`[IN PROGRESS]`**：正在开发/设计中
* ⚪ **`[TODO]`**：待排期计划

---

## 🎯 阶段一：基础骨架与核心播放 (Milestone 1) —— 状态：🟢 已完成
* 🟢 **工程与 Stage 架构**：完成 `module.json5`、`build-profile.json5`、API 12+ / 26 配置；
* 🟢 **AVPlayer 音频引擎**：`AudioPlayerService.ets` 实现单曲、多循环模式、播放列表调度；
* 🟢 **AVSession 播控对接**：`AVSessionService.ets` 实现媒体元数据广播与系统播控监听；
* 🟢 **LRC 歌词解析引擎**：`LyricParser.ets` 实现时间轴解析与二分高亮定位；
* 🟢 **持久化存储**：`StorageService.ets` 实现收藏夹与播放历史持久化。

---

## 🚀 阶段二：移动端核心功能深度 1:1 还原 (Milestone 2) —— 状态：🟢 已完成

* 🟢 **搜索 (Search)**：支持多源 Tab 快速切换（KW 酷我、KG 酷狗、TX 企鹅、WY 网易、MG 咪咕、ALL 聚合）与热门搜索词推荐；
* 🟢 **歌单广场 (SongList)**：精选推荐歌单瀑布流、歌单详情 `SongListDetailDialog` 与一键播放全部；
* 🟢 **排行榜大厅 (Leaderboard)**：多源官方权威榜单（热歌总榜、飙升榜、新歌榜）与 Top 排名徽章；
* 🟢 **我的列表 (MyList)**：收藏夹、自建歌单（支持创建/重命名/删除/导入导出）、本地音乐（一键扫描）与下载管理；
* 🟢 **全屏播放器 (PlayDetail)**：黑胶唱片旋转动效、实时居中歌词滚动、128k/320k/FLAC/Hi-Res 音质切换、播放模式切换与播放列表抽屉。

---

## 💎 阶段三：体验打磨与系统特性增强 (Milestone 3) —— 状态：🟢 已完成

* 🟢 **主题与色彩体系**：实现 `ThemeService.ets`，支持浅色/深色模式及 5 套预设主题色动态切换；
* 🟢 **音效与 5 频段均衡器**：实现 `EqualizerService.ets` 与 `EqualizerDialog.ets`，支持 5 段 EQ 增益、低音增强与 3D 空间环绕；
* 🟢 **桌面全局悬浮歌词**：实现 `FloatLyricService.ets`，支持跨应用浮窗与应用内自适应发光胶囊条；
* 🟢 **多端数据同步协议**：实现 `SyncService.ets`，对接 `lx-music-sync-server` 密钥认证与双向歌单合并；
* 🟢 **多设备响应式布局**：实现 `BreakpointSystem.ets`，适配手机 (`sm`)、折叠屏/平板 (`md` 侧边栏) 与宽屏 (`lg` 双栏大唱片)。

---

## 🔍 任务认领与验收准则 (Acceptance Criteria)

任何新增功能在标记为 🟢 **`[DONE]`** 前，必须满足：
1. **类型安全**：ArkTS 代码通过严格类型检查，无隐式 `any`，无语法告警；
2. **状态解耦**：业务逻辑封装在 `services/` 或 `viewmodel/` 中，UI 仅做响应式绑定；
3. **文档同步**：同步更新 `doc/worklog.md` 与本文档的进度状态；
4. **Git 提交**：按规范提交并推送到 GitHub 远程仓库。
