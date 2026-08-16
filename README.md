# ZoomCat

![Version](https://img.shields.io/badge/version-v0.3.3-blue)
![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)
![Language](https://img.shields.io/badge/language-Swift%2FAppKit-orange)

一个原生 macOS 菜单栏小猫：根据整机 CPU 使用率控制猫咪奔跑速度 ——
CPU 低时端坐休息、摇尾巴，CPU 高时撒腿狂奔。纯 Swift + AppKit 实现，
无需任何第三方依赖，猫咪为程序化矢量绘制（任意分辨率清晰）。

> **当前版本：v0.3.3** —— Dashboard 点击外部自动收起。

## 特性

- 🐱 菜单栏小猫：8 帧奔跑动画 + 2 帧端坐摇尾动画
- 🖥️ **Dashboard 仪表盘**：点击猫咪弹出（参考 RunCatNeo 设计语言）
  - 系统信息卡片（CPU 使用率 / 温度 / 热状态 / 磁盘 / 内存 / **电池** / **网络**）
  - **CPU 使用率 60 秒历史曲线**（渐变面积图）
  - **占用排行 Top 3**：CPU / 内存一键切换，带应用图标与进度条
  - 品种画廊（10 品种缩略图点选即换）
  - 毛玻璃质感、明暗模式自适应
- 📊 实时监控 CPU（mach `host_statistics`，指数平滑）
- 🌡️ **CPU 温度**：三级读取链，自动回退
  1. SMC（`TC0P`/`TC0D`/`TCxC` 等键，常规 Intel Mac 无需 root）
  2. IOHID 热事件（Apple Silicon 及新机型，无需 root）
  3. **温度监控助手**（LaunchDaemon）：原生路径不可用时，启动时自动
     提示一次性启用。启用只需授权一次，之后由系统开机自动拉起
     `powermetrics` 常驻后台采集温度，重启电脑无需再次操作
- 🫤 **系统热状态**：正常 / 偏高 / 严重 / 危急（`ProcessInfo.thermalState`）
- 💾 **磁盘用量**：已用 / 总量 / 百分比（根卷，5 秒刷新）
- 🚶 速度分级：休息 😴 / 散步 🚶 / 慢跑 🏃 / 飞奔 💨
- 🐱 **10 种高人气猫品种**（萌系卡通化，大头圆眼 + 高光眼神 + 粉鼻腮红）：
  布偶猫 / 英短蓝猫 / 美短虎斑 / 暹罗猫 / 波斯猫 / 缅因猫 / 折耳猫 /
  斯芬克斯 / 豹猫 / 金渐层。选择会被记住
- 🎨 预览图：`build/previews/breeds.png`（10 品种端坐+奔跑总览）
- 📌 菜单栏可直接显示 **CPU 使用率** 和 **CPU 温度**（等宽字体，位于猫咪左侧）
- 🏃 奔跑动画带节奏弹跳，睡眠时自动暂停、唤醒自动恢复
- ⚡ 开机自动启动（SMAppService，需放在“应用程序”文件夹）
- 🖼️ 自带应用图标（由猫咪绘制器自动生成）
- ℹ️ 关于 ZoomCat（版本信息面板）

## 构建与运行

```bash
./build.sh          # 编译 + 打包 ZoomCat.app
open ZoomCat.app     # 启动（或双击）
```

构建产物为 `ZoomCat.app`，仅需 macOS 13.0+（已在 macOS 15.7 Intel 上验证）。
建议把 `ZoomCat.app` 拖入“应用程序”文件夹后使用“开机自动启动”功能。

## 使用

- 点击菜单栏小猫 → 弹出 **Dashboard 仪表盘**：系统信息卡片 / CPU 历史曲线 /
  品种画廊 / 显示开关 / 温度监控助手 / 开机自启 / 关于 / 退出
- 无 Dock 图标（LSUIElement 菜单栏应用）

### 关于 CPU 温度

macOS 没有公开的温度 API。本应用按 SMC → IOHID → 温度监控助手逐级尝试。
绝大多数 Mac 上无需任何授权即可显示温度；如果你的系统把前两条路都封禁了
（例如本机 macOS 15.7 上 AppleSMC 用户态接口被限制、无 HID 温度传感器），
启动时会出现**一次性**启用提示（或通过菜单“温度监控助手”手动启用）：

- 只需输入一次开机密码，注册一个 LaunchDaemon（`local.zoomcat.temperature`）
- 该守护进程由系统开机自动启动，后台运行 `powermetrics` 持续采集
  CPU 温度并写入 `/tmp/zoomcat_smc.log`（每 30 分钟自动截断，日志有界）
- 之后无需任何操作：重启电脑、重新打开 ZoomCat，温度都会自动显示
- 想停用时，点菜单“温度监控助手 ▸ 停用…”即可

> 说明：守护进程仅以只读方式采集温度，不访问任何用户数据；
> 不想要时可以随时停用。

## 版本记录

### v0.3.3（当前版本）
- 🖱️ **点击外部自动收起**：点桌面/其他窗口/Cmd+Tab 时仪表盘自动关闭（全局鼠标监视器）

### v0.3.2
- 🏆 **占用排行 Top 3**：CPU/内存一键切换，应用图标 + 进度条
- ⚙️ 进程采集优化：proc_pidinfo 全量遍历 5ms，后台刷新
- 🚀 性能：动画帧率上限 10fps，状态栏重绘开销减半

### v0.3.1
- 🌐 **网络速度**：下载/上传实时速率（64 位计数器，1 秒采样）
- 🔋 **电池**：电量百分比 + 充电/放电/已充满状态

### v0.3
- 🖥️ **全新 Dashboard 仪表盘**（点击猫咪弹出，参考 RunCatNeo 设计语言）：
  - 系统信息卡片：CPU 使用率 / 温度 / 热状态 / 磁盘 / **内存**（新增）
  - **CPU 使用率 60 秒历史曲线**（渐变面积图）
  - 品种画廊：10 品种缩略图点选即换
  - 毛玻璃卡片、明暗模式自适应
  - 原 NSMenu 菜单升级为完整仪表盘交互

### v0.2
- 🎨 UI 优化（参考原版 RunCat 设计）：菜单栏文字居左、CPU 使用率显示开关、奔跑弹跳、睡眠/唤醒处理、关于面板

### v0.1（2026-08）
- 🐱 菜单栏猫咪动画：随 CPU 使用率奔跑，速度分级（休息/散步/慢跑/飞奔）
- 🐈 10 种高人气猫品种（萌系卡通化，大头圆眼 + 高光眼神 + 粉鼻腮红）
- 📊 CPU 使用率 / 🌡️ CPU 温度（SMC→IOHID→监控助手三级回退）/ 🫤 系统热状态 / 💾 磁盘用量
- ⚙️ 温度监控助手：LaunchDaemon 一次性授权，开机自动采集温度
- 📦 纯 Swift + AppKit，零第三方依赖；`build.sh` 一键打包

## 项目结构

```
Sources/
  main.swift        # 入口 + 图标生成模式(--gen-icon)
  AppDelegate.swift # 状态栏、动画驱动、信息采样、仪表盘接线
  Dashboard.swift   # Dashboard 仪表盘（SwiftUI：卡片/曲线/品种画廊/弹出控制器）
  SystemStats.swift # 系统统计（内存/网络/电池）
  CatPainter.swift  # 猫咪矢量绘制与配色
  CPUUsage.swift    # CPU 采样
  TemperatureReader.swift # 温度三级读取（SMC / IOHID / 监控助手日志）
  TemperatureDaemon.swift # 温度监控助手（LaunchDaemon 启用/停用）
  SMC.c             # AppleSMC 协议读取（Intel，C 实现）
  DiskUsage.swift   # 磁盘用量
Info.plist          # 应用配置
build.sh            # 一键打包脚本
```

## 重新构建

改完代码后重新运行 `./build.sh` 即可覆盖生成新版本。
