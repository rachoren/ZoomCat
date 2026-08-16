import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var cpu = CPUUsage()
    private let temperature = TemperatureProvider()

    private let model = DashboardModel()
    private var dashboard: DashboardController!

    private var lastCpuSample = Date()
    private var smoothedCPU: Double = 0

    private var frameIndex = 0
    private var accumulator = 0.0
    private var lastFrame = Date()

    private var frames = RunnerFrames(running: [], sitting: [], sleeping: nil)
    private var displayedFrame: NSImage?

    private var cpuTemp: Double?
    private var lastTempCheck = Date()
    private var lastMiscCheck = Date()
    private var cpuHistory: [Double] = []
    private var lastHistoryPush = Date()
    private var lastNetworkCounters: (rx: UInt64, tx: UInt64)?
    private var lastNetworkSample = Date()
    private var cpuProcCache = ProcessMonitor.CPUCache()
    private var lastProcSample = Date()
    private var claudeProcessActive = false

    private var showTempInBar: Bool {
        didSet {
            UserDefaults.standard.set(showTempInBar, forKey: "showTempInBar")
            model.showTempInBar = showTempInBar
        }
    }
    private var showUsageInBar: Bool {
        didSet {
            UserDefaults.standard.set(showUsageInBar, forKey: "showUsageInBar")
            model.showUsageInBar = showUsageInBar
        }
    }
    private var selectedBreed: CatBreed {
        didSet { UserDefaults.standard.set(selectedBreed.rawValue, forKey: "catBreed") }
    }
    private var selectedKind: RunnerKind {
        didSet { UserDefaults.standard.set(selectedKind.rawValue, forKey: "runnerKind") }
    }

    override init() {
        let savedBreed = UserDefaults.standard.string(forKey: "catBreed")
        selectedBreed = savedBreed.flatMap(CatBreed.init(rawValue:)) ?? .ragdoll
        let savedKind = UserDefaults.standard.string(forKey: "runnerKind")
        selectedKind = savedKind.flatMap(RunnerKind.init(rawValue:)) ?? .cat
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
        statusItem.button?.action = #selector(toggleDashboard(_:))
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        // 等宽字体：菜单栏数字对齐美观（参考原版 RunCat）
        if #available(macOS 10.15, *) {
            statusItem.button?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        }

        dashboard = DashboardController(app: self, model: model)
        rebuildFrames()
        buildBreedPreviews()
        buildRunnerPreviews()
        syncModelPrefs()
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

    @objc private func toggleDashboard(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        dashboard.show(from: button)
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
            model.cpuUsage = smoothedCPU
            model.stateText = stateText
            applyStatusBarText()
        }

        // CPU 历史曲线 + 网络速率：1Hz
        if now.timeIntervalSince(lastHistoryPush) >= 1.0 {
            lastHistoryPush = now
            cpuHistory.append(smoothedCPU * 100)
            if cpuHistory.count > 60 { cpuHistory.removeFirst() }
            model.cpuHistory = cpuHistory

            if let c = NetworkStats.counters() {
                let dt = now.timeIntervalSince(lastNetworkSample)
                if let prev = lastNetworkCounters, dt > 0 {
                    let down = Double(c.rx > prev.rx ? c.rx - prev.rx : 0) / dt
                    let up = Double(c.tx > prev.tx ? c.tx - prev.tx : 0) / dt
                    model.networkDown = NetworkStats.formatSpeed(down)
                    model.networkUp = NetworkStats.formatSpeed(up)
                }
                lastNetworkCounters = c
                lastNetworkSample = now
            }
        }

        // 温度：2s
        if now.timeIntervalSince(lastTempCheck) >= 2.0 {
            lastTempCheck = now
            cpuTemp = temperature.currentTemperature()
            model.cpuTempText = cpuTemp.map { String(format: "%.1f°C", $0) } ?? "--"
            applyStatusBarText()
        }

        // 热状态 / 磁盘 / 内存 / 电池 / 助手状态：5s
        if now.timeIntervalSince(lastMiscCheck) >= 5.0 {
            lastMiscCheck = now
            model.thermalText = thermalText
            model.diskText = DiskUsage.formatted()
            model.memoryText = MemoryStats.formatted()
            model.batteryText = BatteryStats.formatted()
            model.daemonInstalled = TemperatureDaemon.isInstalled
            syncLoginState()
            refreshClaudeState()
        }

        // 占用排行（Top 3 进程）：2s，后台采集避免卡顿
        if now.timeIntervalSince(lastProcSample) >= 2.0 {
            lastProcSample = now
            refreshTopProcesses()
        }

        // 动画：帧率随 CPU 提升
        let dt = now.timeIntervalSince(lastFrame)
        lastFrame = now
        let fps: Double
        if smoothedCPU < 0.06 {
            fps = 1.6
        } else {
            fps = 3 + smoothedCPU * 7 // 3 ~ 10 帧/秒（小图标足够流畅，控制状态栏重绘开销）
        }
        accumulator += dt * fps
        if accumulator >= 1 {
            let steps = Int(accumulator)
            accumulator -= Double(steps)
            frameIndex += steps
        }

        // 仅当画面真正变化时才设置图像，避免菜单栏无谓重绘
        // 状态机：睡觉(<2%，仅猫咪) → 端坐(<6%) → 奔跑
        let targetFrame: NSImage
        if smoothedCPU < 0.02, let sleeping = frames.sleeping, !sleeping.isEmpty {
            targetFrame = sleeping[frameIndex % sleeping.count]
        } else if smoothedCPU < 0.06, !frames.sitting.isEmpty {
            targetFrame = frames.sitting[frameIndex % frames.sitting.count]
        } else {
            targetFrame = frames.running[frameIndex % frames.running.count]
        }
        if targetFrame !== displayedFrame {
            statusItem.button?.image = targetFrame
            displayedFrame = targetFrame
        }
    }

    private var stateText: String {
        if smoothedCPU < 0.02, frames.sleeping != nil { return "睡觉中 😴" }
        if smoothedCPU < 0.06 { return "休息中 🧘" }
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

    // MARK: - 占用排行采集

    private func refreshTopProcesses() {
        let cache = cpuProcCache
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let (entries, newCache) = ProcessMonitor.snapshot(cache: cache)
            // 排除系统内核与自身
            let filtered = entries.filter { $0.pid > 0 && $0.name != "kernel_task" }
            // 只对 Top 候选补路径（用于图标），避免逐个进程查路径的开销
            let cpuTop = Array(filtered.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(3))
                .map { TopProcess(pid: $0.pid, name: $0.name, path: ProcessMonitor.path(for: $0.pid),
                                  cpuPercent: $0.cpuPercent, memoryBytes: $0.memoryBytes) }
            let memTop = Array(filtered.sorted { $0.memoryBytes > $1.memoryBytes }.prefix(3))
                .map { TopProcess(pid: $0.pid, name: $0.name, path: ProcessMonitor.path(for: $0.pid),
                                  cpuPercent: $0.cpuPercent, memoryBytes: $0.memoryBytes) }
            DispatchQueue.main.async {
                guard let self else { return }
                self.cpuProcCache = newCache
                // 检测 Claude Code 进程（statusLine 只在交互式会话触发，进程检测兜底）
                self.claudeProcessActive = entries.contains {
                    $0.name.lowercased().contains("claude")
                }
                self.model.topCPU = Self.buildProcessEntries(cpuTop, metric: .cpu)
                self.model.topMemory = Self.buildProcessEntries(memTop, metric: .memory)
            }
        }
    }

    private static func buildProcessEntries(_ procs: [TopProcess], metric: ProcessMetric) -> [ProcessEntry] {
        let maxVal: Double
        switch metric {
        case .cpu: maxVal = procs.map { $0.cpuPercent }.max() ?? 1
        case .memory: maxVal = Double(procs.map { $0.memoryBytes }.max() ?? 1)
        }
        return procs.map { p in
            let value = metric == .cpu ? p.cpuPercent : Double(p.memoryBytes)
            let text = metric == .cpu
                ? String(format: "%.1f%%", p.cpuPercent)
                : Self.formatBytes(p.memoryBytes)
            return ProcessEntry(id: p.pid, name: p.name, valueText: text,
                                fraction: maxVal > 0 ? min(value / maxVal, 1) : 0,
                                icon: Self.appIcon(forPath: p.path))
        }
    }

    private static func appIcon(forPath path: String?) -> NSImage? {
        guard var p = path else { return nil }
        // 取 .app 包路径以获得正确图标（可执行文件路径通常只有通用图标）
        if let r = p.range(of: ".app/") {
            p = String(p[..<r.lowerBound]) + ".app"
        }
        return NSWorkspace.shared.icon(forFile: p)
    }

    private static func formatBytes(_ b: UInt64) -> String {
        if b >= 1 << 30 { return String(format: "%.1f GB", Double(b) / 1e9) }
        if b >= 1 << 20 { return String(format: "%.0f MB", Double(b) / 1e6) }
        return String(format: "%.0f KB", Double(b) / 1e3)
    }

    // MARK: - Claude Code 集成

    private func refreshClaudeState() {
        model.claudeConfigured = ClaudeStatus.isConfigured
        let s = ClaudeStatus.summary()
        model.claudeModel = s.model
        model.claudeContext = s.context
        model.claudeFive = s.five
        model.claudeSeven = s.seven
        model.claudeContextFrac = s.contextFrac
        model.claudeFiveFrac = s.fiveFrac
        model.claudeSevenFrac = s.sevenFrac
        model.claudeFiveValid = s.fiveValid
        model.claudeSevenValid = s.sevenValid
        model.claudeActive = s.active
        model.claudeRunning = claudeProcessActive
        model.claudeStatusText = Self.claudeStatusText(running: claudeProcessActive, fresh: s.active)
    }

    private static func claudeStatusText(running: Bool, fresh: Bool) -> String {
        if running {
            return fresh ? "运行中" : "运行中 · 等待本轮回答"
        }
        if fresh {
            return "会话刚结束"
        }
        return "未检测到会话（上次更新较久前）"
    }

    func setupClaudeStatus() {
        switch ClaudeStatus.register() {
        case .success:
            let alert = NSAlert()
            alert.messageText = "Claude Code 已配置"
            alert.informativeText = "下次启动 Claude Code 会话时生效：每轮回答后自动更新模型与用量。\n\n状态文件：~/.claude/zoomcat-usage.json"
            alert.runModal()
        case .conflict:
            let alert = NSAlert()
            alert.messageText = "检测到已有 statusLine 配置"
            alert.informativeText = "Claude Code 只允许一个 statusLine 命令。请把你的现有脚本与下面这行合并后填入 settings.json：\n\n\"command\": \"\(ClaudeStatus.scriptPath)\""
            alert.runModal()
        case .failure:
            let alert = NSAlert()
            alert.messageText = "配置失败"
            alert.informativeText = "无法写入脚本或 ~/.claude/settings.json。"
            alert.runModal()
        }
        refreshClaudeState()
    }

    func removeClaudeStatus() {
        ClaudeStatus.unregister()
        refreshClaudeState()
    }

    // MARK: - Dashboard 动作

    func setShowUsageInBar(_ on: Bool) {
        showUsageInBar = on
        model.showUsageInBar = on
        applyStatusBarText()
    }

    func setShowTempInBar(_ on: Bool) {
        showTempInBar = on
        model.showTempInBar = on
        applyStatusBarText()
    }

    func selectBreed(_ index: Int) {
        guard CatBreed.allCases.indices.contains(index) else { return }
        selectedBreed = CatBreed.allCases[index]
        model.selectedBreed = index
        updateRunnerHeader()
        rebuildFrames()
    }

    func selectKind(_ index: Int) {
        guard RunnerKind.allCases.indices.contains(index) else { return }
        selectedKind = RunnerKind.allCases[index]
        model.selectedKind = index
        model.showBreedSection = (selectedKind == .cat)
        updateRunnerHeader()
        rebuildFrames()
    }

    private func updateRunnerHeader() {
        if selectedKind == .cat {
            model.breedName = selectedBreed.displayName
        } else {
            model.breedName = selectedKind.displayName
        }
    }

    func toggleDaemonAction() {
        if TemperatureDaemon.isInstalled {
            let confirm = NSAlert()
            confirm.messageText = "停用温度监控助手？"
            confirm.informativeText = "停用后 CPU 温度将无法自动读取，显示为 --。"
            confirm.addButton(withTitle: "停用")
            confirm.addButton(withTitle: "取消")
            guard confirm.runModal() == .alertFirstButtonReturn else { return }
            model.daemonBusy = true
            TemperatureDaemon.uninstall { [weak self] ok in
                guard let self else { return }
                self.model.daemonBusy = false
                self.model.daemonInstalled = TemperatureDaemon.isInstalled
                if !ok {
                    let alert = NSAlert()
                    alert.messageText = "停用失败"
                    alert.informativeText = "可能取消了授权。"
                    alert.runModal()
                }
            }
        } else {
            installDaemon()
        }
    }

    func setLoginAtLaunch(_ on: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if on {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                let alert = NSAlert()
                alert.messageText = "开机自动启动设置失败"
                alert.informativeText = "请把 ZoomCat.app 移动到“应用程序”文件夹后重试。"
                alert.runModal()
            }
        }
        syncLoginState()
    }

    func showAboutPanel() {
        NSApp.activate(ignoringOtherApps: true)
        let credits = NSAttributedString(
            string: "随 CPU 奔跑的菜单栏猫咪\n纯 Swift + AppKit，零第三方依赖",
            attributes: [.font: NSFont.systemFont(ofSize: 11)])
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "ZoomCat",
            .applicationVersion: "v0.3.1",
            .credits: credits,
        ])
    }

    func quitApp() {
        NSApp.terminate(nil)
    }

    private func syncLoginState() {
        if #available(macOS 13.0, *) {
            model.loginAtLaunch = (SMAppService.mainApp.status == .enabled)
        }
    }

    private func syncModelPrefs() {
        model.showUsageInBar = showUsageInBar
        model.showTempInBar = showTempInBar
        model.daemonInstalled = TemperatureDaemon.isInstalled
        syncLoginState()
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
        model.daemonBusy = true
        TemperatureDaemon.install { [weak self] ok in
            guard let self else { return }
            self.model.daemonBusy = false
            self.model.daemonInstalled = TemperatureDaemon.isInstalled
            if ok {
                self.refreshTemperatureNow()
                let alert = NSAlert()
                alert.messageText = "温度监控助手已启用"
                alert.informativeText = "CPU 温度将自动显示，重启电脑后依然生效。"
                alert.runModal()
            } else {
                let alert = NSAlert()
                alert.messageText = "启用失败"
                alert.informativeText = "可能取消了授权。可稍后重试。"
                alert.runModal()
            }
        }
    }

    /// 立即刷新一次温度显示（安装成功或手动触发时使用）。
    private func refreshTemperatureNow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            self.cpuTemp = self.temperature.currentTemperature()
            self.model.cpuTempText = self.cpuTemp.map { String(format: "%.1f°C", $0) } ?? "--"
            self.applyStatusBarText()
        }
    }

    // MARK: - 菜单栏文字与帧

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
        frames = RunnerFactory.frames(kind: selectedKind, catBreed: selectedBreed)
        model.breedImage = frames.sitting.first
    }

    private func buildBreedPreviews() {
        var previews: [(String, NSImage)] = []
        for breed in CatBreed.allCases {
            let painter = CatPainter(breed: breed)
            previews.append((breed.displayName, painter.sittingFrames().first ?? NSImage()))
        }
        model.breedPreviews = previews
        model.selectedBreed = CatBreed.allCases.firstIndex(of: selectedBreed) ?? 0
        updateRunnerHeader()
    }

    private func buildRunnerPreviews() {
        var previews: [(String, NSImage)] = []
        for kind in RunnerKind.allCases {
            let f = RunnerFactory.frames(kind: kind, catBreed: selectedBreed)
            previews.append((kind.displayName, f.sitting.first ?? NSImage()))
        }
        model.runnerPreviews = previews
        model.selectedKind = RunnerKind.allCases.firstIndex(of: selectedKind) ?? 0
        model.showBreedSection = (selectedKind == .cat)
        updateRunnerHeader()
    }
}
