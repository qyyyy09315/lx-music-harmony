# Agent 极速上手与上下文恢复手册 (Agent Handbook)

> **🎯 本手册专为接入本项目的 AI Coding Agent 设计**。
> 当您在新的对话会话中被拉起，或者接手当前仓库时，请优先按本文档建立上下文，无需重新扫描全盘。

---

## ⚡ 30 秒极速上下文恢复

### 1. 项目本质与定位
* **项目名称**：`lx-music-harmony` (洛雪音乐 鸿蒙版)
* **目标平台**：**HarmonyOS NEXT (纯血鸿蒙)**，采用 **ArkTS + Stage 模型 (API 12+)**。
* **原始上游**：[lyswhut/lx-music-mobile](https://github.com/lyswhut/lx-music-mobile) (React Native 架构)。
* **免责规范**：项目本身不内置音频，依赖用户本地导入音源脚本解析。
* **远程仓库**：`https://github.com/qyyyy09315/lx-music-harmony` (分支: `main`)。

---

## 🧭 核心代码与关键路径速查

| 关注领域 | 核心文件路径 | 核心关注点 |
| :--- | :--- | :--- |
| **音频引擎** | `entry/src/main/ets/services/AudioPlayerService.ets` | 单例模式，管理 AVPlayer、循环模式与播放列表 |
| **系统播控** | `entry/src/main/ets/services/AVSessionService.ets` | 鸿蒙 AVSession 元数据广播与按键事件 |
| **歌词解析** | `entry/src/main/ets/common/LyricParser.ets` | LRC 文本解析与二分行索引查找 |
| **数据持久化** | `entry/src/main/ets/services/StorageService.ets` | `@ohos.data.preferences` 存取收藏/历史/设置 |
| **数据模型** | `entry/src/main/ets/model/MusicModel.ets` | `MusicItem`, `PlayMode`, `PlayState` |
| **UI 页面** | `entry/src/main/ets/pages/Index.ets` | 主 Tab 容器与底部迷你播放条 |
| **全屏播放器** | `entry/src/main/ets/view/PlayDetailModal.ets` | 旋转唱片、进度拖拽、控制栏、歌词切换 |
| **歌词滚动** | `entry/src/main/ets/view/LyricView.ets` | 随时间轴自动滚动居中高亮 |
| **上游参考** | `upstream_lx_music_mobile/` | 本地缓存的上游 RN 源码参考对比（已 gitignore） |

---

## 💻 本地工具链与常用命令 (Local Toolchains)

本机的 DevEco Studio 安装在 `G:\DevEco Studio`：

* **构建工具 Hvigor**：
  ```bash
  /g/DevEco\ Studio/tools/hvigor/bin/hvigorw --mode module -p module=entry@default assembleHap
  ```
* **包管理器 OHPM**：
  ```bash
  /g/DevEco\ Studio/tools/ohpm/bin/ohpm install
  ```
* **Git 提交与同步**：
  ```bash
  git add .
  git commit -m "feat/fix: <description>"
  git push origin main
  ```

---

## 🤖 Agent 行为准则 (Do's and Don'ts)

1. **✅ 必须遵守 ArkTS 语法规范**：
   * 必须显式声明变量与函数返回值类型；
   * 严禁使用动态 `any` 或隐式类型推导；
   * 鸿蒙 UI 组件中禁止在 `build()` 方法内部执行复杂异步逻辑或直接实例化服务（应使用 `@State`、`@Prop` 响应式驱动）。
2. **✅ 必须维护 `doc/` 文档库**：
   * 完成重要功能或架构调整后，必须同步更新 `doc/worklog.md` 与 `doc/roadmap-todo.md`。
3. **❌ 禁止修改上游许可与免责声明**：
   * 严格保留 README 与协议中关于原作者致谢与音源免责的声明。
