# 详细技术规范与模块接口说明 (Technical Specification)

## 1. 核心数据模型规范 (`model/MusicModel.ets`)

### 1.1 `MusicItem` 接口
```typescript
export interface MusicItem {
  id: string;          // 唯一标识符（如: 'song_demo_1' 或源特定的 hash）
  name: string;        // 歌曲名称
  singer: string;      // 歌手名
  album?: string;      // 专辑名
  pic?: string;        // 专辑封面远程 URL 或本地资源路径
  duration?: number;   // 歌曲总时长（毫秒 ms）
  url?: string;        // 音频流媒体可播放链接 (HTTP/HTTPS 或 fd://)
  lrc?: string;        // 原始 LRC 格式歌词文本
  source?: string;     // 音源标记（例如: 'kw' | 'kg' | 'mg' | 'tx' | 'local'）
}
```

### 1.2 播放状态与枚举
* **`PlayMode`**：
  * `LIST_LOOP` ('list_loop')：列表循环
  * `SINGLE_LOOP` ('single_loop')：单曲循环
  * `RANDOM` ('random')：随机播放
* **`PlayState`**：
  * `IDLE` ('idle')：初始/空闲
  * `PREPARING` ('preparing')：准备中/缓冲
  * `PLAYING` ('playing')：正在播放
  * `PAUSED` ('paused')：已暂停
  * `STOPPED` ('stopped')：已停止
  * `ERROR` ('error')：发生错误

---

## 2. 播放引擎服务规范 (`services/AudioPlayerService.ets`)

### 2.1 单例获取与生命周期
```typescript
const player = AudioPlayerService.getInstance();
await player.init(); // 在 Ability 或页面初始化时调用
```

### 2.2 核心方法列表
| 方法签名 | 描述 |
| :--- | :--- |
| `init(): Promise<void>` | 初始化底层 AVPlayer 实例并绑定状态机事件 |
| `playMusic(music: MusicItem): Promise<void>` | 设置当前歌曲为 URL 并触发加载播放 |
| `setPlayList(list: MusicItem[], startIndex?: number): Promise<void>` | 重置播放列表并从指定索引开始播放 |
| `togglePlay(): Promise<void>` | 切换播放与暂停状态 |
| `playNext(): Promise<void>` | 根据当前播放模式切换下一首 |
| `playPrevious(): Promise<void>` | 切换上一首 |
| `seek(timeMs: number): Promise<void>` | 跳转至指定播放进度（毫秒） |
| `togglePlayMode(): PlayMode` | 轮转切换播放模式并返回当前模式 |
| `onStateChange(cb: (state: PlayState) => void): void` | 监听播放状态改变 |
| `onTimeUpdate(cb: (cur: number, dur: number) => void): void` | 监听播放进度与总时长更新（100ms 级别） |
| `onMusicChange(cb: (music: MusicItem \| null) => void): void` | 监听当前播放歌曲改变 |
| `onPlaylistChange(cb: (list: MusicItem[]) => void): void` | 监听播放列表变更 |

---

## 3. 播控中心服务规范 (`services/AVSessionService.ets`)

### 3.1 职责
对接鸿蒙系统的 `AVSession`（多媒体播控中心），确保系统锁屏、通知栏、播控卡片及蓝牙设备可以同步展示歌曲信息并响应物理按键（播放/暂停/切歌/进度拖拽）。

### 3.2 关键接口
* `initSession(context: Context): Promise<void>`：创建 `audio` 类型会话并激活；
* `updateMetadata(music: MusicItem): Promise<void>`：向系统广播标题、艺术家、专辑、封面图片与时长；
* `destroy(): Promise<void>`：Ability 销毁时清理资源。

---

## 4. 歌词解析算法与定位器 (`common/LyricParser.ets`)

### 4.1 数据结构
```typescript
export interface LyricLine {
  time: number; // 毫秒级时间戳
  text: string; // 歌词文本
}

export interface ParsedLyric {
  title?: string;
  artist?: string;
  album?: string;
  offset?: number;
  lines: LyricLine[];
}
```

### 4.2 核心算法
* **`LyricParser.parse(lrcText: string): ParsedLyric`**：
  * 支持提取元数据标签 `[ti:]`, `[ar:]`, `[al:]`, `[offset:]`；
  * 正则匹配 `[mm:ss.xx]` 与 `[mm:ss.xxx]` 时间戳并换算为毫秒，按时间正序排序。
* **`LyricParser.findCurrentLineIndex(lines: LyricLine[], currentTimeMs: number): number`**：
  * 使用**二分查找（Binary Search）**，在 $O(\log N)$ 时间内命中当前播放时间对应的歌词行索引。

---

## 5. 数据持久化服务规范 (`services/StorageService.ets`)

### 5.1 存储机制
基于鸿蒙 `@ohos.data.preferences` 单实例首选项存储，存储名称 `lx_music_harmony_pref`。

### 5.2 核心接口
* `getCollectionList(): Promise<MusicItem[]>` / `addCollection(music: MusicItem): Promise<void>` / `removeCollection(id: string): Promise<void>`
* `getHistoryList(): Promise<MusicItem[]>` / `addHistory(music: MusicItem): Promise<void>`（自动限额 100 条 LRU 队列）
* `setSetting(key: string, value: string): Promise<void>` / `getSetting(key: string, defaultVal?: string): Promise<string>`
