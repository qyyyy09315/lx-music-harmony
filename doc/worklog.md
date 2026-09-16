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

### 8. 本地音乐扫描与离线下载管理落地 (Sprint 4)
* **本地音乐扫描体系 (`LocalMusicService.ets`)**：
  * 实现设备本地音频自动发现、元数据提取与曲库扫描同步。
* **离线下载管理器 (`DownloadManagerService.ets`)**：
  * 实现单曲离线下载任务状态流转（等待、下载进度追踪 0~100%、完成入库与管理）。
* **「我的」Tab 交互重构**：
  * 引入「收藏」、「本地音乐」、「下载」三段式 Segment 视图切换，支持一键扫描与离线曲库一键播放。
* **歌曲卡片 (`MusicListItem.ets`) 升级**：
  * 增加下载快速操作入口与已下载视觉状态反馈。

### 9. 响应式布局、自定义歌单与 5 频段音效均衡器 (Sprint 5)
* **多设备响应式断点系统 (`BreakpointSystem.ets`)**：
  * 基于 `@ohos.mediaquery` 实现 `sm` / `md` / `lg` 三档动态断点监听；
  * 小屏 (sm) 保持经典底部 TabBar，大屏 (md/lg) 自适应切换为左侧侧边栏 Navigation Rail；
  * 宽屏 (lg) 实现双栏沉浸式排版：左侧列表浏览、右侧常驻大黑胶唱片与实时居中歌词。
* **自定义歌单管理体系 (`PlaylistManagerService.ets`)**：
  * 具备自定义歌单新建、重命名、封面管理、歌曲归纳及 JSON 导入/导出能力；
  * 增加 `AddToPlaylistDialog.ets` 半模态归纳弹窗。
* **5 频段音效均衡器 (`EqualizerService.ets` & `EqualizerDialog.ets`)**：
  * 提供 60Hz、230Hz、910Hz、3.6kHz、14kHz 增益调节，支持流行、摇滚、人声、古典等预设音效、低音增强与 3D 空间环绕声。

### 10. 全量编译与 HAP 产物构建验证 (Sprint 6)
* **静态类型与 ArkTS 语法全量适配**：
  * 修复了对象的解构赋值与 `Object.assign`，对齐 ArkTS Strict 规范；
  * 补齐了 `app_icon.png` 和 `icon.png` 系统媒体图标；
  * 统一了组件对外回调参数的访问权限。
* **编译测试通过**：
  * 执行 `assembleHap` 构建流水线，全量 33 个编译与打包任务 **0 Error 全部通过 (BUILD SUCCESSFUL in 4.3s)**。

### 11. 移动端 5 大主视图 1:1 深度还原与全量编译通过 (Sprint 7)
* **搜索 (Search) 深度还原**：
  * 增加多源 Tab 切换栏（KW/KG/TX/WY/MG/ALL）、热门搜索推荐词快速填入检索。
* **歌单广场 (SongList) & 详情弹窗**：
  * 呈现热门精选歌单卡片流，实现 `SongListDetailDialog.ets` 详情页与一键全歌单播放。
* **排行榜大厅 (Leaderboard)**：
  * 呈现官方权威热歌榜、飙升榜、新歌榜横向滑动切换，支持 Top 冠亚季军排名徽章展示。
* **我的曲库 (MyList) & 5 大主导航**：
  * 统一 5 大主视图（搜索、歌单、排行榜、我的、设置），全量 33 个构建任务 **0 Error 编译成功 (BUILD SUCCESSFUL in 2.7s)**。

### 12. 真实多源搜索接入与列表渲染零闪烁优化 (Sprint 8)
* **真实多源网络解析 (`SourceManagerService.ets`)**：
  * 深度集成网易云（WY）与酷狗（KG）等公开接口的实时异步检索；
  * 解析真实歌名、歌手、封面 pic、真实时长 duration 与真实音频流；
  * 支持多源并发聚合与网络异常时的优雅保底回退。
* **ArkUI 渲染零闪烁优化 (`Index.ets`)**：
  * 为所有 `ForEach` 列表项注入稳定的唯一主键 `(item: MusicItem) => item.id`，彻底消除组件重新构建导致的白屏跳动与闪烁；
  * 搜索状态切换时保留原列表结构，采用轻量内联加载指示器；
  * 成功通过全量编译构建验证 (**BUILD SUCCESSFUL in 1.7s**)。

### 13. 移动端极简纯文本列表排版重构 (Sprint 9)
* **移除冗余缩略图**：重构 `MusicListItem.ets` 为经典紧凑纯文字排版，第一行歌名加粗高亮、第二行展示音源徽章 `[WY/KW/KG]` + 音质徽章 `[SQ]` + `歌手 · 专辑`。
* **极速加载体验**：彻底去除重复的占位封面图，提升首屏渲染帧率与信息密度，全量编译验证通过 (**BUILD SUCCESSFUL in 1.8s**)。
