# 洛雪音乐鸿蒙版工作日志 (Work Log)

本文档记录项目自立项移植以来的所有核心技术演进、架构决策与版本提交记录。

---

## 📅 2026-09-16 (Sprint 1: 架构立项、骨架搭建与核心功能落地)

### 1. 调研与架构决策
* **上游项目审阅**：深入分析原版 [lyswhut/lx-music-mobile](https://github.com/lyswhut/lx-music-mobile) 源码架构，确定业务状态流、QuickJS 原生交互方式、播放队列和歌词逻辑。
* **技术路线决议**：
  * 对比了 RNOH（React Native on OpenHarmony）与 **纯血鸿蒙原生（ArkTS + Stage 模型）** 两套路线。
  * 最终决定采用 **ArkTS 纯原生方案**：深度接入 HarmonyOS NEXT 的 `AVSession`、`AVPlayer`、`BackgroundTasks` 及声明式 ArkUI，保证最高性能、低功耗保活与系统一致性。

### 2. 工程建立与开源声明
* **开源合规与免责**：
  * 在醒目位置标注原作者 [@lyswhut](https://github.com/lyswhut) 与原项目出处。
  * 严格规范免责条款：软件不内置、不提供音频内容，由用户本地导入音源脚本，遵守 Apache-2.0 许可证。
* **GitHub 仓库发布**：
  * 通过 GitHub CLI (`gh`) 建立公共仓库 `https://github.com/qyyyy09315/lx-music-harmony`，并配置好 `.gitignore` 规则。

### 3. 核心功能与模块落地
* **音频播放子系统 (`AudioPlayerService.ets`)**：
  * 接入 `@ohos.multimedia.media.AVPlayer`，实现准备、播放、暂停、进度拖拽（seek）、重置等完整状态机管理。
  * 实现了三种播放模式：列表循环（List Loop）、单曲循环（Single Loop）、随机播放（Random）。
  * 实现了播放列表调度、上一首/下一首智能切换与播放完成自动连播。
* **系统播控中心 (`AVSessionService.ets`)**：
  * 接入 `@ohos.multimedia.avsession`，支持歌曲元数据（歌名、歌手、封面、时长）广播及响应系统控制操作。
* **歌词算法引擎 (`LyricParser.ets`)**：
  * 编写了标准 LRC 标签解析器与 $O(\log N)$ 二分查找歌词行定位算法。
* **数据持久化 (`StorageService.ets`)**：
  * 基于 `@ohos.data.preferences` 实现收藏列表持久化、最近播放（LRU 100条）与偏好设置。
* **ArkUI 界面与交互系统 (`entry/src/main/ets/`)**：
  * `Index.ets`：实现发现、我的、搜索、设置四大 Tab 切换与常驻迷你播放栏。
  * `PlayDetailModal.ets`：全屏播放器沉浸式界面，支持唱片/歌词双态切换、进度拖拽、控制栏。
  * `LyricView.ets`：实现歌词自动滚动居中与当前行高亮动效。
  * `MusicListItem.ets`：高质感卡片歌曲组件。

### 4. 远程推送与代码同步
* 提交哈希：
  * `ef5ad59`: 初始化 Stage 架构与 README/LICENSE
  * `0e3cac3`: 实现歌词解析、播放引擎、持久化服务与 ArkUI 界面
  * `21a9a6b`: 建立完整 doc/ 架构与 Agent 极速恢复手册

### 5. DevEco Studio 26 构建与环境适配
* **SDK 26 对齐**：修复 `build-profile.json5` 中的 `compileSdkVersion`、`compatibleSdkVersion`、`targetSdkVersion` 为 `"26.0.0"` 字符串格式。
* **Hvigor 6.26 适配**：将 `hvigor-config.json5` 中插件版本对齐为 `@ohos/hvigor-ohos-plugin@6.26.4`，补充 `oh-package.json5` 与 `hvigorw` 脚本。
* **HAP 任务流修正**：修正 `entry/hvigorfile.ts` 为 `hapTasks`，成功通过工程全量同步。

### 6. 自定义音源、悬浮歌词与播放列表体系落地 (Sprint 2)
* **自定义音源服务 (`SourceManagerService.ets`)**：
  * 实现自定义音源脚本元数据解析、脚本代码导入与持久化存储管理；
  * 提供多源搜索、音频流 URL 解析及歌词解析统一门面。
* **全局悬浮歌词 (`FloatLyricService.ets`)**：
  * 实现基于 `@ohos.window` 的全局浮窗歌词服务及应用内自适应发光胶囊条。
* **播放列表抽屉 (`PlaylistDrawer.ets`)**：
  * 在全屏播放器与主页中集成队列抽屉，支持歌曲高亮、单曲移除、一键清空与播放模式切换。
* **搜索 Tab 升级**：
  * 接入跨源异步检索、Loading 指示与即搜即播。

### 7. 多端同步、全套主题体系与音质切换 (Sprint 3)
* **多端同步体系 (`SyncService.ets`)**：
  * 接入 `lx-music-sync-server` 规范，实现基于 HTTP/WebSocket 的认证握手与双向歌单合并。
* **主题与深浅模式 (`ThemeService.ets`)**：
  * 实现全局调色板管理，支持浅色/深色模式及 5 套经典预设主题色（翡翠绿、极光蓝、魅影紫、珊瑚红、曜石黑）实时响应式切换。
* **音质选择面板 (`QualitySelectDialog.ets`)**：
  * 支持 128k、320k、FLAC、Hi-Res (24bit) 四档音质自适应切换。
* **设置中心与主界面升级**：
  * 在 `Index.ets` 设置 Tab 中集成多端同步配置弹窗与主题配色调整面板。
