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

## 🚀 阶段二：业务功能深度移植 (Milestone 2) —— 状态：🟡 进行中

### 1. 自定义音源沙箱运行环境 (User API)
* ⚪ **[TODO]** 调研并编写 C/C++ NAPI 模块，将轻量级 **QuickJS** 编译为鸿蒙 `.so`；
* ⚪ **[TODO]** 实现 ArkTS Worker 线程与 QuickJS 沙箱之间的双向通信与安全拦截；
* ⚪ **[TODO]** 兼容上游洛雪自定义音源规范（支持 URL 解析、搜索接口、歌词接口回调）；
* ⚪ **[TODO]** 设置界面提供本地文件导入与网络导入音源脚本功能。

### 2. 桌面与全局悬浮歌词
* ⚪ **[TODO]** 基于 `@ohos.window` 创建悬浮子窗口（`WindowType.TYPE_FLOAT`）；
* ⚪ **[TODO]** 悬浮窗触摸拖拽、锁定位置与透明度/字号调节；
* ⚪ **[TODO]** 悬浮歌词与当前播放进度的实时同步联动。

### 3. 多端数据同步协议对接
* ⚪ **[TODO]** 基于 `@ohos.net.webSocket` 或 HTTP 对接 `lx-music-sync-server`；
* ⚪ **[TODO]** 实现多设备收藏夹与歌单的加密传输、冲突检测与双向合并。

---

## 💎 阶段三：体验打磨与系统特性增强 (Milestone 3) —— 状态：⚪ 待排期

* ⚪ **[TODO] 本地音乐扫描**：基于媒体库访问接口扫描设备本地音频文件并提取 ID3 元数据；
* ⚪ **[TODO] 多设备响应式布局**：针对手机、折叠屏、平板（Tablet）与 2in1 设备进行自适应分栏排版；
* ⚪ **[TODO] 主题与色彩**：支持跟随系统深色模式与自定义个性化主题色切换；
* ⚪ **[TODO] 离线缓存管理**：音频与歌词的本地 LRU 磁盘缓存管理与清理。

---

## 🔍 任务认领与验收准则 (Acceptance Criteria)

任何新增功能在标记为 🟢 **`[DONE]`** 前，必须满足：
1. **类型安全**：ArkTS 代码通过严格类型检查，无隐式 `any`，无语法告警；
2. **状态解耦**：业务逻辑封装在 `services/` 或 `viewmodel/` 中，UI 仅做响应式绑定；
3. **文档同步**：同步更新 `doc/worklog.md` 与本文档的进度状态；
4. **Git 提交**：按规范提交并推送到 GitHub 远程仓库。
