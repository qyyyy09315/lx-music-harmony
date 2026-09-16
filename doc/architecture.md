# 系统架构设计与技术选型 (Architecture Design)

## 1. 项目背景与移植目标

LX Music Harmony 是将 [lyswhut/lx-music-mobile](https://github.com/lyswhut/lx-music-mobile) 深度移植到 **HarmonyOS NEXT（纯血鸿蒙）** 的开源音乐客户端项目。

### 核心设计原则
1. **纯血原生（ArkTS Native）**：采用 Stage 模型标准工程架构，全面拥抱声明式 ArkUI、AVPlayer 和 AVSession 等鸿蒙原生能力。
2. **状态解耦与服务单例**：核心音频播放引擎（AudioPlayerService）、播控会话（AVSessionService）、数据存储（StorageService）设计为全局可复用服务，与 UI 组件完全解耦。
3. **低功耗与后台保活**：接入长时后台音频任务模式（`audioPlayback`），保障息屏与后台切换下的低功耗稳定运行。
4. **扩展性与沙箱安全**：预留 QuickJS NAPI 模块接口，支持加载用户自定义源（User API）脚本，且保持主 UI 线程与渲染性能不受影响。

---

## 2. 总体架构图

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                   ArkUI 声明式组件层 (UI / View Layer)                    │
│ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌─────────────┐ │
│ │  发现推荐页面   │ │   我的收藏列表 │ │    在线搜索页  │ │   设置与同步│ │
│ └───────┬────────┘ └───────┬────────┘ └───────┬────────┘ └──────┬──────┘ │
│         │                  │                  │                 │        │
│ ┌───────▼──────────────────▼──────────────────▼─────────────────▼──────┐ │
│ │              全屏播放器模态框 (PlayDetailModal) / 桌面悬浮歌词        │ │
│ │               - 唱片旋转动画        - 逐行歌词平滑滚动 (LyricView)     │ │
│ │               - 进度条拖拽控制      - 播放控制栏 (循环/上一首/下一首)   │ │
│ └───────────────────────────────────┬──────────────────────────────────┘ │
└─────────────────────────────────────┼────────────────────────────────────┘
                                      │ 订阅事件 / 状态同步
┌─────────────────────────────────────▼────────────────────────────────────┐
│                    业务与服务层 (Services & Logic Layer)                  │
│                                                                          │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌─────────────────┐ │
│  │  AudioPlayerService  │  │   AVSessionService   │  │ StorageService  │ │
│  │  - 播放队列与索引调度  │  │   - 播控中心同步     │  │ - 首选项持久化   │ │
│  │  - 循环模式状态机    │  │   - 锁屏/控制中心交互 │  │ - 历史记录/收藏 │ │
│  │  - AVPlayer 状态管理 │  │   - 媒体元数据更新   │  │ - 自定义配置    │ │
│  └──────────┬───────────┘  └──────────┬───────────┘  └─────────────────┘ │
│             │                         │                                  │
│  ┌──────────▼───────────┐  ┌──────────▼───────────┐                      │
│  │     LyricParser      │  │    UserApiEngine     │                      │
│  │  - LRC 多标签解析    │  │  - QuickJS NAPI 桥接 │                      │
│  │  - 二分时间轴行定位  │  │  - 脚本沙箱隔离      │                      │
│  └──────────────────────┘  └──────────────────────┘                      │
└─────────────────────────────────────┬────────────────────────────────────┘
                                      │
┌─────────────────────────────────────▼────────────────────────────────────┐
│                    HarmonyOS NEXT 平台能力层 (System APIs)               │
│                                                                          │
│  • @ohos.multimedia.media (AVPlayer 音频解码流控)                         │
│  • @ohos.multimedia.avsession (媒体播控中心)                              │
│  • @ohos.resourceschedule.backgroundTaskManager (长时任务保活)            │
│  • @ohos.data.preferences / @ohos.data.relationalStore (持久化)          │
│  • @ohos.net.http (网络通信)                                             │
│  • @ohos.window (悬浮子窗口 FloatWindow)                                 │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 核心分层说明

### 3.1 视图与交互层 (`entry/src/main/ets/view` & `pages`)
* **`pages/Index.ets`**：主入口页面，基于 `Tabs` 组件管理 4 个核心功能区（发现、我的、搜索、设置），并常驻底部迷你播放栏；通过 `bindSheet` 实现全屏播放器的平滑展开。
* **`view/PlayDetailModal.ets`**：全屏沉浸式播放器，支持唱片/歌词双态切换、基于手势的进度拖拽与循环模式切换。
* **`view/LyricView.ets`**：歌词滚动组件，利用 `Scroller` 监听播放时间变化并自动滚动当前高亮行居中。
* **`view/MusicListItem.ets`**：支持列表虚拟化、多源标识（KW/KG/MG/TX等）与当前播放高亮反馈。

### 3.2 服务与播放控制层 (`entry/src/main/ets/services`)
* **`AudioPlayerService`**：全局单例音频调度器。驱动底层的 `@ohos.multimedia.media.AVPlayer`，负责 URL 准备、播放、暂停、跳转、列表循环、单曲循环、随机播放等。
* **`AVSessionService`**：接入系统播控，与控制中心、锁屏媒体卡片、耳机蓝牙线控双向同步。
* **`StorageService`**：使用首选项 `@ohos.data.preferences` 维护收藏歌曲列表、最近播放（LRU 100 首）与用户偏好。

### 3.3 算法与工具层 (`entry/src/main/ets/common`)
* **`LyricParser`**：负责解析标准 LRC 格式文本，提取时间轴与文本并使用二分查找算法在 $O(\log N)$ 时间复杂度内定位当前高亮行。

---

## 4. 跨平台技术映射表（RN vs HarmonyOS NEXT）

| 功能模块 | 原 React Native 实现 | 鸿蒙 NEXT 原生实现 |
| :--- | :--- | :--- |
| **语言与运行时** | JavaScript / React 18 / Hermes | ArkTS (严格静态类型) / ArkUI 声明式 |
| **音频播放** | `react-native-track-player` (ExoPlayer) | `@ohos.multimedia.media.AVPlayer` |
| **系统媒体控制** | Android `MediaSession` | `@ohos.multimedia.avsession.AVSession` |
| **后台保活** | Android Foreground Service | BackgroundTasks `audioPlayback` 长时任务 |
| **数据持久化** | `@react-native-async-storage` | `@ohos.data.preferences` + `relationalStore` |
| **悬浮桌面歌词** | Android System Window Overlay | `@ohos.window.WindowType.TYPE_FLOAT` |
| **自定义音源** | Android 嵌入 QuickJS C 库 | C/C++ NAPI 编译 QuickJS 运行时 (.so) |
| **网络请求** | Fetch API / Axios | `@ohos.net.http` / Axios-Harmony |
