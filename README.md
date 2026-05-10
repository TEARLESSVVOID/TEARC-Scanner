<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0--beta-orange) ![FiveM](https://img.shields.io/badge/FiveM-cerulean-orange) ![Status](https://img.shields.io/badge/status-测试版-yellow) ![License](https://img.shields.io/badge/license-MIT-green)

# 📻 TEARC-Scanner

**FiveM 警用无线电扫描器**

3D 空间音效 · 附近玩家同步 · 自动版本检查

> ⚠️ 本仓库为**测试版本**，非正式发布。功能可能存在不稳定的情况，仅供测试和反馈使用。

</div>

---

## 功能

- **无线电扫描** — 自动循环播放警用无线电 chatter 音频，随机穿插调度事件
- **3D 空间音效** — 基于距离衰减的 3D 音效，越远声音越小
- **附近玩家同步** — 让范围内的其他玩家也能听到你的扫描器
- **音量归一化** — 自动平衡不同音频文件的响度差异
- **NUI 菜单** — 现代风格的设置菜单，支持开关、滑块操作
- **版本检查** — 启动时自动查询 GitHub Releases 检测更新

## 安装

1. 下载或克隆到你的 FiveM 资源目录：

```
resources/[local]/TEARC-Scanner-beta/
```

2. 在 `server.cfg` 中添加：

```lua
ensure TEARC-Scanner-beta
```

3. 重启服务器

## 按键

| 按键 | 功能 |
|:---:|:---|
| `F9` | 开关扫描器 |
| `F10` | 打开菜单 |

## 命令

| 命令 | 说明 |
|:---|:---|
| `/tearc-status` | 查看扫描器、同步、音效状态 |
| `/tearc-version` | 手动检查版本更新 |
| `/tearc-dispatch` | 手动触发一次调度事件 |

## 配置

所有设置在 `config.lua` 中修改，改完重启资源即可生效。

| 配置项 | 说明 | 默认值 |
|:---|:---|:---|
| `SpatialAudio.enabled` | 3D 空间音效 | `true` |
| `SpatialAudio.maxDistance` | 音效最大传播距离 | `50.0` |
| `Scanner.chatterInterval` | chatter 播放间隔(秒) | `4 ~ 10` |
| `Scanner.dispatchInterval` | 调度事件间隔(秒) | `30 ~ 90` |
| `PlayerSync.enabled` | 附近玩家同步 | `false` |
| `PlayerSync.syncRange` | 同步范围(米) | `80.0` |
| `Notify.position` | 通知位置 | `top-right` |
| `Debug` | 调试模式 | `false` |

## 音频结构

```
audio/
├── scanner/        ← 背景无线电 chatter (40段)
├── alerts/         ← 警报音效 (10段)
└── backup/
    ├── transport/  ← 运输调度
    ├── coroner/    ← 验尸官调度
    ├── animal/     ← 动物管制调度
    └── supervisor/ ← 主管调度
```

替换音频文件时保持文件名和格式(.wav)不变即可。

## 已知问题

这是测试版本，以下问题可能存在：

- 音频文件较大时首次加载可能有短暂延迟
- 3D 音效在某些场景下衰减曲线可能不够自然
- 同步功能在网络延迟较高时可能出现音画不同步

如果遇到问题，欢迎提 Issue 反馈。

## 许可

MIT License

---

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0--beta-orange) ![FiveM](https://img.shields.io/badge/FiveM-cerulean-orange) ![Status](https://img.shields.io/badge/status-BETA-yellow) ![License](https://img.shields.io/badge/license-MIT-green)

# 📻 TEARC-Scanner

**FiveM Police Radio Scanner**

3D Spatial Audio · Proximity Sync · Auto Version Check

> ⚠️ This is a **beta release** and not the final version. Features may be unstable. For testing and feedback only.

</div>

---

## Features

- **Radio Scanner** — Auto-cycles through police radio chatter with random dispatch events
- **3D Spatial Audio** — Distance-based volume attenuation, sound fades as you move away
- **Proximity Sync** — Nearby players can hear your scanner audio
- **Audio Normalization** — Automatically balances loudness differences between audio files
- **NUI Menu** — Modern settings menu with toggles and sliders
- **Version Check** — Automatically checks GitHub Releases for updates on startup

## Install

1. Download or clone into your FiveM resources directory:

```
resources/[local]/TEARC-Scanner-beta/
```

2. Add to `server.cfg`:

```lua
ensure TEARC-Scanner-beta
```

3. Restart your server

## Keys

| Key | Action |
|:---:|:---|
| `F9` | Toggle scanner |
| `F10` | Open menu |

## Commands

| Command | Description |
|:---|:---|
| `/tearc-status` | View scanner, sync, and audio status |
| `/tearc-version` | Manually check for updates |
| `/tearc-dispatch` | Trigger a dispatch event |

## Configuration

All settings are in `config.lua`. Restart the resource after making changes.

| Setting | Description | Default |
|:---|:---|:---|
| `SpatialAudio.enabled` | 3D spatial audio | `true` |
| `SpatialAudio.maxDistance` | Max audio propagation distance | `50.0` |
| `Scanner.chatterInterval` | Chatter playback interval (sec) | `4 ~ 10` |
| `Scanner.dispatchInterval` | Dispatch event interval (sec) | `30 ~ 90` |
| `PlayerSync.enabled` | Proximity sync | `false` |
| `PlayerSync.syncRange` | Sync range (meters) | `80.0` |
| `Notify.position` | Notification position | `top-right` |
| `Debug` | Debug mode | `false` |

## Audio Structure

```
audio/
├── scanner/        ← Background radio chatter (40 clips)
├── alerts/         ← Alert sounds (10 clips)
└── backup/
    ├── transport/  ← Transport dispatch
    ├── coroner/    ← Coroner dispatch
    ├── animal/     ← Animal control dispatch
    └── supervisor/ ← Supervisor dispatch
```

Keep filenames and format (.wav) unchanged when replacing audio files.

## Known Issues

This is a beta release. The following issues may be present:

- Brief loading delay on first playback with large audio files
- 3D audio attenuation curve may feel unnatural in certain scenarios
- Sync may have audio-visual desync under high network latency

If you run into problems, feel free to open an Issue.

## License

MIT License
