import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var cpu = CPUUsage()
    private let temperature = TemperatureProvider()

    private var lastCpuSample = Date()
    private var smoothedCPU: Double = 0

    private var frameIndex = 0
    private var accumulator = 0.0
    private var lastFrame = Date()

    private var runningFrames: [NSImage] = []
    private var sittingFrames: [NSImage] = []
    private var displayedFrame: NSImage?
    private var loginMenuItem: NSMenuItem?
    private var daemonStatusItem: NSMenuItem?
    private var daemonActionItem: NSMenuItem?

    private var cpuTemp: Double?
    private var lastTempCheck = Date()
    private var lastMiscCheck = Date()

    private var showTempInBar: Bool {
        didSet { UserDefaults.standard.set(showTempInBar, forKey: "showTempInBar") }
    }
    private var showUsageInBar: Bool {
        didSet { UserDefaults.standard.set(showUsageInBar, forKey: "showUsageInBar") }
    }
    private var selectedBreed: CatBreed {
        didSet { UserDefaults.standard.set(selectedBreed.rawValue, forKey: "catBreed") }
    }

    private let cpuMenuItem = NSMenuItem(title: "CPU 使用率: --", action: nil, keyEquivalent: "")
    private let tempMenuItem = NSMenuItem(title: "CPU 温度: --", action: nil, keyEquivalent: "")
    private let thermalMenuItem = NSMenuItem(title: "系统热状态: --", action: nil, keyEquivalent: "")
    private let diskMenuItem = NSMenuItem(title: "磁盘: --", action: nil, keyEquivalent: "")
    private let stateMenuItem = NSMenuItem(title: "状态: --", action: nil, keyEquivalent: "")

    override init() {
        let saved = UserDefaults.standard.string(forKey: "catBreed")
        selectedBreed = saved.flatMap(CatBreed.init(rawValue:)) ?? .ragdoll
        showTempInBar = UserDefaults.standard.bool(forKey: "showTempInBar")
        showUsageInBar = UserDefaults.standard.bool(forKey: "showUsageInBar")
        super.init()
    }

    // MARK: - 生命周期

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // 无 Dock 图标

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.toolTip = "ZoomCat"
        // 等宽字体：菜单栏数字对齐美观（参考原版 RunCat）
        if #available(macOS 10.15, *) {
            statusItem.button?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        }

        rebuildFrames()
        buildMenu()
        applyStatusBarText()

        let t = Timer(timeInterval: 1.0 / 20.0, target: self,
                      selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t

        // 睡眠时暂停动画，唤醒后恢复（避免唤醒瞬间动画跳变）
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification, object: nil)

        maybePromptDaemonInstall()
    }

    @objc private func handleSleep() {
        timer?.invalidate()
        timer = nil
        lastFrame = Date()
    }

    @objc private func handleWake() {
        guard timer == nil else { return }
        lastFrame = Date()
        let t = Timer(timeInterval: 1.0 / 20.0, target: self,
                      selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: - 主循环

    @objc private func tick() {
        let now = Date()

        // CPU：2Hz 采样并平滑
        if now.timeIntervalSince(lastCpuSample) >= 0.5 {
            smoothedCPU = cpu.sample()
            lastCpuSample = now
            cpuMenuItem.title = String(format: "CPU 使用率: %.1f%%", smoothedCPU * 100)
            stateMenuItem.title = "状态: " + stateText
            applyStatusBarText()
        }

        // 温度：2s
        if now.timeIntervalSince(lastTempCheck) >= 2.0 {
            lastTempCheck = now
            cpuTemp = temperature.currentTemperature()
            if let t = cpuTemp {
                tempMenuItem.title = String(format: "CPU 温度: %.1f°C", t)
            } else {
                tempMenuItem.title = "CPU 温度: --"
            }
            applyStatusBarText()
        }

        // 热状态 + 磁盘：5s
        if now.timeIntervalSince(lastMiscCheck) >= 5.0 {
            lastMiscCheck = now
            thermalMenuItem.title = "系统热状态: " + thermalText
            diskMenuItem.title = DiskUsage.formatted()
        }

        // 动画：帧率随 CPU 提升
        let dt = now.timeIntervalSince(lastFrame)
        lastFrame = now
        let fps: Double
        if smoothedCPU < 0.06 {
            fps = 1.6
        } else {
            fps = 5 + smoothedCPU * 15 // 5 ~ 20 帧/秒（小图标足够流畅，兼顾省电）
        }
        accumulator += dt * fps
        if accumulator >= 1 {
            let steps = Int(accumulator)
            accumulator -= Double(steps)
            frameIndex = (frameIndex + steps) % 8
        }

        // 仅当画面真正变化时才设置图像，避免菜单栏无谓重绘
        let targetFrame: NSImage
        if smoothedCPU < 0.06 {
            targetFrame = sittingFrames[frameIndex % sittingFrames.count]
        } else {
            targetFrame = runningFrames[frameIndex]
        }
        if targetFrame !== displayedFrame {
            statusItem.button?.image = targetFrame
            displayedFrame = targetFrame
        }
    }

    private var stateText: String {
        if smoothedCPU < 0.06 { return "休息中 😴" }
        if smoothedCPU < 0.30 { return "散步中 🚶" }
        if smoothedCPU < 0.60 { return "慢跑中 🏃" }
        return "飞奔中 💨"
    }

    private var thermalText: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:  return "正常 😌"
        case .fair:     return "偏高 🫤"
        case .serious:  return "严重 🔥"
        case .critical: return "危急 🚨"
        @unknown default: return "未知"
        }
    }

    // MARK: - 菜单

    private func buildMenu() {
        let menu = NSMenu()

        menu.addItem(cpuMenuItem)
        menu.addItem(tempMenuItem)
        menu.addItem(thermalMenuItem)
        menu.addItem(diskMenuItem)
        menu.addItem(stateMenuItem)
        menu.addItem(.separator())

        let usageItem = NSMenuItem(title: "菜单栏显示 CPU 使用率", action: #selector(toggleUsageInBar(_:)),
                                   keyEquivalent: "")
        usageItem.target = self
        usageItem.state = showUsageInBar ? .on : .off
        menu.addItem(usageItem)

        let barItem = NSMenuItem(title: "菜单栏显示 CPU 温度", action: #selector(toggleTempInBar(_:)),
                                 keyEquivalent: "")
        barItem.target = self
        barItem.state = showTempInBar ? .on : .off
        menu.addItem(barItem)

        menu.addItem(.separator())

        let daemonItem = NSMenuItem(title: "温度监控助手", action: nil, keyEquivalent: "")
        daemonItem.submenu = buildDaemonMenu()
        menu.addItem(daemonItem)
        updateDaemonItem()

        let breedMenu = NSMenu()
        for (i, b) in CatBreed.allCases.enumerated() {
            let item = NSMenuItem(title: b.displayName, action: #selector(chooseBreed(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.tag = i
            item.state = (b == selectedBreed) ? .on : .off
            breedMenu.addItem(item)
        }
        let breedItem = NSMenuItem(title: "猫咪品种", action: nil, keyEquivalent: "")
        breedItem.submenu = breedMenu
        menu.addItem(breedItem)

        let loginItem = NSMenuItem(title: "开机自动启动", action: #selector(toggleLaunchAtLogin(_:)),
                                   keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)
        loginMenuItem = loginItem
        refreshLoginItem()

        menu.addItem(.separator())
        let about = NSMenuItem(title: "关于 ZoomCat", action: #selector(showAbout(_:)),
                               keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        let quit = NSMenuItem(title: "退出 ZoomCat", action: #selector(NSApplication.terminate(_:)),
                              keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func toggleUsageInBar(_ sender: NSMenuItem) {
        showUsageInBar.toggle()
        sender.state = showUsageInBar ? .on : .off
        applyStatusBarText()
    }

    @objc private func toggleTempInBar(_ sender: NSMenuItem) {
        showTempInBar.toggle()
        sender.state = showTempInBar ? .on : .off
        applyStatusBarText()
    }

    @objc private func showAbout(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        let credits = NSAttributedString(
            string: "随 CPU 奔跑的菜单栏猫咪\n纯 Swift + AppKit，零第三方依赖",
            attributes: [.font: NSFont.systemFont(ofSize: 11)])
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "ZoomCat",
            .applicationVersion: "v0.2",
            .credits: credits,
        ])
    }

    // MARK: - 温度监控助手（LaunchDaemon）

    /// 启动时自动检测：原生路径不可用且助手未启用时，提示一次性启用。
    private func maybePromptDaemonInstall() {
        let declined = UserDefaults.standard.bool(forKey: "daemonPromptDeclined")
        guard !declined, !TemperatureDaemon.isInstalled, !temperature.hasNativeSource() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, !TemperatureDaemon.isInstalled else { return }
            let alert = NSAlert()
            alert.messageText = "启用温度监控助手？"
            alert.informativeText = "你的系统限制了对 CPU 温度的常规读取。启用后系统将在后台自动采集温度（开机自启、异常自愈），只需授权这一次，之后无需再输入密码。"
            alert.addButton(withTitle: "启用（需要一次授权）")
            alert.addButton(withTitle: "稍后再说")
            alert.addButton(withTitle: "不再提醒")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                self.installDaemon()
            case .alertThirdButtonReturn:
                UserDefaults.standard.set(true, forKey: "daemonPromptDeclined")
            default:
                break
            }
        }
    }

    private func installDaemon() {
        updateDaemonItem("正在启用…")
        TemperatureDaemon.install { [weak self] ok in
            guard let self else { return }
            self.updateDaemonItem()
            if ok {
                self.refreshTemperatureNow()
                let alert = NSAlert()
                alert.messageText = "温度监控助手已启用"
                alert.informativeText = "CPU 温度将自动显示，重启电脑后依然生效。"
                alert.runModal()
            } else {
                let alert = NSAlert()
                alert.messageText = "启用失败"
                alert.informativeText = "可能取消了授权。可稍后在菜单中重试。"
                alert.runModal()
            }
        }
    }

    @objc private func toggleDaemon(_ sender: NSMenuItem) {
        if TemperatureDaemon.isInstalled {
            let confirm = NSAlert()
            confirm.messageText = "停用温度监控助手？"
            confirm.informativeText = "停用后 CPU 温度将无法自动读取，显示为 --。"
            confirm.addButton(withTitle: "停用")
            confirm.addButton(withTitle: "取消")
            guard confirm.runModal() == .alertFirstButtonReturn else { return }
            TemperatureDaemon.uninstall { [weak self] ok in
                guard let self else { return }
                if ok {
                    self.cpuTemp = nil
                    self.tempMenuItem.title = "CPU 温度: --"
                    self.applyStatusBarText()
                    self.updateDaemonItem()
                } else {
                    let alert = NSAlert()
                    alert.messageText = "停用失败"
                    alert.informativeText = "可能取消了授权。"
                    alert.runModal()
                    self.updateDaemonItem()
                }
            }
        } else {
            installDaemon()
        }
    }

    private func buildDaemonMenu() -> NSMenu {
        let menu = NSMenu()
        let info = NSMenuItem(title: "状态: --", action: nil, keyEquivalent: "")
        menu.addItem(info)
        daemonStatusItem = info
        menu.addItem(.separator())
        let action = NSMenuItem(title: "启用…", action: #selector(toggleDaemon(_:)), keyEquivalent: "")
        action.target = self
        menu.addItem(action)
        daemonActionItem = action
        return menu
    }

    private func updateDaemonItem(_ forced: String? = nil) {
        guard let status = daemonStatusItem, let action = daemonActionItem else { return }
        if let forced {
            status.title = forced
            action.title = "停用…"
            return
        }
        if TemperatureDaemon.isInstalled {
            status.title = "已启用 · 开机自动运行"
            action.title = "停用…"
        } else {
            status.title = "未启用"
            action.title = "启用（需要一次授权）"
        }
    }

    /// 立即刷新一次温度显示（安装成功或手动触发时使用）。
    private func refreshTemperatureNow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            self.cpuTemp = self.temperature.currentTemperature()
            if let t = self.cpuTemp {
                self.tempMenuItem.title = String(format: "CPU 温度: %.1f°C", t)
            } else {
                self.tempMenuItem.title = "CPU 温度: --"
            }
            self.applyStatusBarText()
        }
    }

    @objc private func chooseBreed(_ sender: NSMenuItem) {
        selectedBreed = CatBreed.allCases[sender.tag]
        rebuildFrames()
        if let submenu = statusItem.menu?.item(withTitle: "猫咪品种")?.submenu {
            for item in submenu.items {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                let alert = NSAlert()
                alert.messageText = "开机自动启动设置失败"
                alert.informativeText = "请把 ZoomCat.app 移动到“应用程序”文件夹后重试。"
                alert.runModal()
            }
        }
        refreshLoginItem()
    }

    private func refreshLoginItem() {
        if #available(macOS 13.0, *) {
            loginMenuItem?.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        }
    }

    /// 菜单栏文字：CPU 使用率 / 温度 组合显示在猫的左侧（参考原版 RunCat 布局）。
    private func applyStatusBarText() {
        guard let button = statusItem.button else { return }
        if showUsageInBar || showTempInBar {
            var parts: [String] = []
            if showUsageInBar {
                parts.append(String(format: "%.1f%%", smoothedCPU * 100))
            }
            if showTempInBar {
                if let t = cpuTemp {
                    parts.append(String(format: "%.0f°", t))
                } else {
                    parts.append("--")
                }
            }
            let title = parts.joined(separator: " ")
            if button.title != title || button.imagePosition != .imageTrailing {
                button.imagePosition = .imageTrailing
                button.title = title
            }
        } else if button.title != "" || button.imagePosition != .imageOnly {
            button.imagePosition = .imageOnly
            button.title = ""
        }
    }

    private func rebuildFrames() {
        let painter = CatPainter(breed: selectedBreed)
        runningFrames = painter.runningFrames()
        sittingFrames = painter.sittingFrames()
    }
}
