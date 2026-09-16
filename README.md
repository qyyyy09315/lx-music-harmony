# LX Music Harmony (洛雪音乐 鸿蒙版)

<p align="center">
  <img width="120" src="./AppScope/resources/base/media/app_icon.png" alt="LX Music Harmony Logo" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>基于 HarmonyOS NEXT (纯血鸿蒙) / ArkUI 架构深度移植开发的洛雪音乐客户端</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-HarmonyOS%20NEXT-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Language-ArkTS%20%2F%20Cangjie-orange" alt="Language">
  <img src="https://img.shields.io/badge/License-Apache%202.0-green" alt="License">
</p>

---

## 📌 致敬与项目声明 (Credits & Origin)

* **原项目地址**：[lyswhut/lx-music-mobile](https://github.com/lyswhut/lx-music-mobile) & [lyswhut/lx-music-desktop](https://github.com/lyswhut/lx-music-desktop)
* **原作者**：[@lyswhut](https://github.com/lyswhut)
* **移植说明**：本项目为社区发起的 **HarmonyOS NEXT 原生移植版本**，基于原移动版与桌面版的设计哲学与业务架构，采用华为纯血鸿蒙生态（ArkTS、ArkUI、AVPlayer、AVSession 及 Stage 模型）进行重新实现与原生适配。

---

## ⚠️ 免责声明与合规说明 (Disclaimer)

1. **无内置音频资源**：本项目为纯客户端播放与界面工具，**软件本体及其安装包内均不包含、不托管、亦不直接提供任何音视频文件或多媒体流媒体数据**。
2. **播放源解析机制**：所有歌曲的播放链接与多媒体地址均依赖于**使用者本地自主配置与导入的第三方自定义脚本/音源规则**在本地动态解析生成。
3. **知识产权与版权尊重**：我们强烈提倡尊重音乐创作者与发行方的知识产权。若您希望享受高品质音乐作品，请务必前往各大官方正版流媒体音乐平台订阅与收听。
4. **非商业用途**：本项目仅供 HarmonyOS 系统开发与跨平台移植技术的学习、研究与交流之用，严禁用于任何商业牟利行为。

---

## 🌟 鸿蒙原生特性与规划架构

- [x] **鸿蒙原生 Stage 架构**：完全适配 API 12+ 标准与分布式能力。
- [ ] **AVPlayer & AVSession 播控中心**：深度对接通知栏媒体卡片、锁屏界面、超级终端与蓝牙耳机物理按键控制。
- [ ] **后台长时音频任务**：低功耗音频播放保活与智能音频焦点管理（来电、导航避让）。
- [ ] **桌面/全局悬浮歌词**：基于鸿蒙悬浮子窗口（FloatWindow）的高性能平滑滚动与逐字动效。
- [ ] **User API 脚本沙箱**：基于轻量级 JS 运行时封装，兼容现有自定义音源脚本生态。
- [ ] **多端数据同步**：无缝对接 `lx-music-sync-server`，实现与桌面版、移动版播放列表双向同步。

---

## 🏗️ 目录结构

```text
├── AppScope/                 # 鸿蒙应用全局配置与资源
│   ├── app.json5
│   └── resources/
├── entry/                    # 主模块工程
│   └── src/main/
│       ├── ets/
│       │   ├── common/       # 工具库、加密、常量、网络请求
│       │   ├── entryability/ # EntryAbility 声明周期管理
│       │   ├── model/        # 音乐、歌单、播放状态等核心数据结构
│       │   ├── pages/        # 界面路由 (首页, 播放器详情, 歌单, 设置)
│       │   ├── services/     # AVPlayer、AVSession、播放调度等后台服务
│       │   └── view/         # ArkUI 复用组件 (歌词面板, 播放条等)
│       ├── module.json5      # 模块配置文件 (长时任务、权限声明)
│       └── resources/        # 国际化字符、图标等静态资源
├── LICENSE                   # Apache-2.0 许可证
└── README.md
```

---

## 🛠️ 构建与开发环境

* **开发工具**：DevEco Studio 5.0+ (Release)
* **SDK 版本**：HarmonyOS NEXT SDK (API Version 12+)
* **构建系统**：Hvigor

---

## 📄 开源许可证

本项目遵循 [Apache License 2.0](LICENSE) 开源协议。
