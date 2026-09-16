# 路线图与待办事项清单 (Roadmap & TODO)

本文档是项目的动态任务跟踪看板，任何开发者或 AI Agent 在接手任务时，均需依据本看板认领并更新进度。

---

## 🚦 状态图例说明
* 🟢 **`[DONE]`**：已完成并经验证
* 🟡 **`[IN PROGRESS]`**：正在开发/设计中
* ⚪ **`[TODO]`**：待排期计划

---

## 🎯 阶段一：基础骨架与核心播放 (Milestone 1) —— 状态：🟢 基础已完成

* 🟢 **工程与 Stage 架构**：完成 `module.json5`、`build-profile.json5`、API 12+ 配置；
* 🟢 **AVPlayer 音频引擎**：`AudioPlayerService.ets` 实现单曲、多循环模式、播放列表调度；
* 🟢 **AVSession 播控对接**：`AVSessionService.ets` 实现基础媒体元数据广播与系统播控监听；
* 🟢 **LRC 歌词解析引擎**：`LyricParser.ets` 实现时间轴解析与二分高亮定位；
* 🟢 **持久化存储**：`StorageService.ets` 实现收藏夹与播放历史持久化；
* 🟢 **基础 ArkUI 组件**：`Index.ets`、`LyricView.ets`、`PlayDetailModal.ets`。

---

## 🚀 阶段二：业务功能深度移植 (Milestone 2) —— 状态：🟡 核心模块已落地

### 1. 自定义音源沙箱与管理体系 (User API)
* 🟢 **[DONE]** 实现 `SourceManagerService.ets` 自定义音源管理体系，支持元数据提取、脚本导入、音源切换；
* 🟢 **[DONE]** 实现统一网络代理请求器，支持自定义 Header、防盗链注入与超时保护；
* 🟢 **[DONE]** 搜索页集成多源并发检索、即搜即播与歌曲列表无缝衔接；
* ⚪ **[TODO]** 拓展 QuickJS / NAPI 底层沙箱加密运算与动态 Worker 隔离。

### 2. 桌面与全局悬浮歌词
* 🟢 **[DONE]** 实现 `FloatLyricService.ets` 全局歌词服务，集成 `@ohos.window` 悬浮子窗口；
* 🟢 **[DONE]** 主界面实现全局悬浮歌词胶囊条，与当前播放进度及歌词解析器毫秒级联动。

### 3. 播放列表管理体系
* 🟢 **[DONE]** 实现 `PlaylistDrawer.ets` 半模态抽屉组件，支持当前队列展示、切歌、单曲移除、一键清空。

### 4. 多端数据同步协议对接
* 🟢 **[DONE]** 实现 `SyncService.ets` 对接 `lx-music-sync-server` 协议；
* 🟢 **[DONE]** 实现双向合并、冲突处理、密钥认证与连接状态机；
* 🟢 **[DONE]** 在设置界面提供多端同步配置与立即同步面板。

---

## 💎 阶段三：体验打磨与系统特性增强 (Milestone 3) —— 状态：🟢 已全部落地

* 🟢 **[DONE] 主题与色彩体系**：实现 `ThemeService.ets`，支持浅色/深色模式及 5 套预设主题色动态切换；
* 🟢 **[DONE] 音质切换面板**：实现 `QualitySelectDialog.ets`，支持 128k/320k/FLAC/Hi-Res 灵活切换；
* 🟢 **[DONE] 本地音乐扫描**：实现 `LocalMusicService.ets` 扫描设备本地音频并支持一键曲库入库；
* 🟢 **[DONE] 离线缓存与下载管理器**：实现 `DownloadManagerService.ets`，支持单曲下载进度追踪与离线曲库自动联动；
* 🟢 **[DONE] 多设备与折叠屏/平板响应式布局**：实现 `BreakpointSystem.ets`，支持 `sm` 手机底栏、`md` 侧边栏导航、`lg` 宽屏双栏常驻大唱片与歌词；
* 🟢 **[DONE] 自定义歌单管理体系**：实现 `PlaylistManagerService.ets` 与 `AddToPlaylistDialog.ets`，支持创建、归纳与导入导出；
* 🟢 **[DONE] 音效预设与 5 频段均衡器**：实现 `EqualizerService.ets` 与 `EqualizerDialog.ets`，支持 5 段 EQ 增益、低音增强与 3D 空间环绕。

---

## 🔍 任务认领与验收准则 (Acceptance Criteria)

任何新增功能在标记为 🟢 **`[DONE]`** 前，必须满足：
1. **类型安全**：ArkTS 代码通过严格类型检查，无隐式 `any`，无语法告警；
2. **状态解耦**：业务逻辑封装在 `services/` 或 `viewmodel/` 中，UI 仅做响应式绑定；
3. **文档同步**：同步更新 `doc/worklog.md` 与本文档的进度状态；
4. **Git 提交**：按规范提交并推送到 GitHub 远程仓库。
