import SwiftUI
import AppKit

// MARK: - 数据模型

/// 仪表盘数据（由 AppDelegate 的主循环定时更新）。

final class DashboardModel: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var cpuHistory: [Double] = Array(repeating: 0, count: 60) // 0-100
    @Published var cpuTempText = "--"
    @Published var thermalText = "--"
    @Published var diskText = "--"
    @Published var memoryText = "--"
    @Published var networkDown = "--"
    @Published var networkUp = "--"
    @Published var batteryText = "--"
    @Published var stateText = "休息中 😴"

    @Published var breedImage: NSImage?
    @Published var breedName = ""
    @Published var breedPreviews: [(String, NSImage)] = []
    @Published var selectedBreed = 0

    @Published var showUsageInBar = false
    @Published var showTempInBar = false
    @Published var daemonInstalled = false
    @Published var daemonBusy = false
    @Published var loginAtLaunch = false

    @Published var topCPU: [ProcessEntry] = []
    @Published var topMemory: [ProcessEntry] = []

    @Published var claudeConfigured = false
    @Published var claudeActive = false
    @Published var claudeModel = "--"
    @Published var claudeContext = "--"
    @Published var claudeFive = "--"
    @Published var claudeSeven = "--"
}

// MARK: - 进程排行条目

enum ProcessMetric: String, CaseIterable {
    case cpu, memory
}

struct ProcessEntry: Identifiable, Equatable {
    let id: Int32
    let name: String
    let valueText: String
    let fraction: Double // 0-1（相对当前榜首）
    let icon: NSImage?
}

// MARK: - 仪表盘视图

/// 点击菜单栏猫咪弹出的 Dashboard（参考 RunCatNeo 的卡片 + 曲线设计语言）。
struct DashboardView: View {
    @ObservedObject var model: DashboardModel
    let onToggleUsage: (Bool) -> Void
    let onToggleTemp: (Bool) -> Void
    let onSelectBreed: (Int) -> Void
    let onToggleDaemon: () -> Void
    let onToggleLogin: (Bool) -> Void
    let onAbout: () -> Void
    let onQuit: () -> Void
    let onClaudeSetup: () -> Void
    let onClaudeRemove: () -> Void
    @State private var processMetric: ProcessMetric = .cpu

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                infoGrid
                graphCard
                claudeSection
                processSection
                breedSection
                settingsSection
                footer
            }
            .padding(14)
        }
        .frame(width: 300)
    }

    // MARK: 头部

    private var header: some View {
        HStack(spacing: 10) {
            if let img = model.breedImage {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: 36, height: 36)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("ZoomCat").font(.headline)
                Text(model.stateText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.bottom, 2)
    }

    // MARK: 信息卡片

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            InfoCard(title: "CPU 使用率",
                     value: String(format: "%.1f%%", model.cpuUsage * 100))
            InfoCard(title: "CPU 温度", value: model.cpuTempText)
            InfoCard(title: "系统热状态", value: model.thermalText)
            InfoCard(title: "磁盘用量", value: model.diskText)
            InfoCard(title: "内存用量", value: model.memoryText)
            InfoCard(title: "电池", value: model.batteryText)
            InfoCard(title: "下载 ↓", value: model.networkDown)
            InfoCard(title: "上传 ↑", value: model.networkUp)
        }
    }

    // MARK: CPU 历史曲线

    private var graphCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CPU 使用率 · 最近 60 秒")
                .font(.caption)
                .foregroundStyle(.secondary)
            HistoryGraph(values: model.cpuHistory)
                .frame(height: 54)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }

    // MARK: Claude Code 集成

    private var claudeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Claude Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if model.claudeConfigured {
                    Button("移除", action: onClaudeRemove)
                        .controlSize(.small)
                } else {
                    Button("一键配置", action: onClaudeSetup)
                        .controlSize(.small)
                }
            }

            if !model.claudeConfigured {
                Text("配置后可在仪表盘查看 Claude Code 的模型与用量")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if !model.claudeActive {
                Text("等待 Claude Code 会话…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ClaudeRow(title: "模型", value: model.claudeModel)
                ClaudeRow(title: "上下文", value: model.claudeContext)
                ClaudeRow(title: "5h 限额", value: model.claudeFive)
                ClaudeRow(title: "7d 限额", value: model.claudeSeven)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }

    // MARK: 占用排行（Top 3 进程）

    private var processSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("占用排行 · Top 3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $processMetric) {
                    Text("CPU").tag(ProcessMetric.cpu)
                    Text("内存").tag(ProcessMetric.memory)
                }
                .pickerStyle(.segmented)
                .frame(width: 108)
                .controlSize(.small)
            }

            let list = processMetric == .cpu ? model.topCPU : model.topMemory
            if list.isEmpty {
                Text("采样中…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else if processMetric == .cpu, list.allSatisfy({ $0.fraction < 0.005 }) {
                Text("系统空闲 · 无显著占用")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(list) { entry in
                    ProcessRow(entry: entry)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }

    // MARK: 品种选择（Runner Gallery 风格）

    private var breedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("猫咪品种")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(model.breedPreviews.enumerated()), id: \.offset) { index, item in
                        Button {
                            onSelectBreed(index)
                        } label: {
                            VStack(spacing: 3) {
                                Image(nsImage: item.1)
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                Text(item.0)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 44)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(index == model.selectedBreed ? Color.accentColor.opacity(0.16) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(index == model.selectedBreed ? Color.accentColor : Color.clear,
                                                  lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }

    // MARK: 设置

    private var settingsSection: some View {
        VStack(spacing: 10) {
            Toggle("菜单栏显示 CPU 使用率",
                   isOn: Binding(get: { model.showUsageInBar }, set: onToggleUsage))
                .toggleStyle(.switch)
            Toggle("菜单栏显示 CPU 温度",
                   isOn: Binding(get: { model.showTempInBar }, set: onToggleTemp))
                .toggleStyle(.switch)
            Toggle("开机自动启动",
                   isOn: Binding(get: { model.loginAtLaunch }, set: onToggleLogin))
                .toggleStyle(.switch)

            Divider()

            HStack {
                Text(model.daemonInstalled ? "温度监控助手：已启用" : "温度监控助手：未启用")
                    .font(.callout)
                Spacer()
                if model.daemonBusy {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(model.daemonInstalled ? "停用" : "启用") {
                        onToggleDaemon()
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }

    // MARK: 底部

    private var footer: some View {
        HStack {
            Button("关于 ZoomCat", action: onAbout)
                .controlSize(.small)
            Spacer()
            Button("退出 ZoomCat", role: .destructive, action: onQuit)
                .controlSize(.small)
        }
        .padding(.top, 2)
    }
}

// MARK: - 卡片

struct InfoCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }
}

// MARK: - CPU 历史曲线

struct HistoryGraph: View {
    let values: [Double] // 0-100

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pts: [CGPoint] = values.enumerated().map { i, v in
                let x = values.count > 1 ? CGFloat(i) / CGFloat(values.count - 1) * w : 0
                let y = h - CGFloat(min(max(v, 0), 100) / 100) * h
                return CGPoint(x: x, y: y)
            }
            // 参考网格线
            var gridPath = Path()
            for f in [0.25, 0.5, 0.75] {
                let y = h - h * f
                gridPath.move(to: CGPoint(x: 0, y: y))
                gridPath.addLine(to: CGPoint(x: w, y: y))
            }
            // 渐变面积
            var fillPath = Path()
            if pts.count > 1 {
                fillPath.move(to: CGPoint(x: 0, y: h))
                for pt in pts { fillPath.addLine(to: pt) }
                fillPath.addLine(to: CGPoint(x: w, y: h))
                fillPath.closeSubpath()
            }
            // 折线
            var linePath = Path()
            if pts.count > 1 {
                linePath.move(to: pts[0])
                for pt in pts.dropFirst() { linePath.addLine(to: pt) }
            }
            return ZStack(alignment: .bottom) {
                gridPath.stroke(Color.primary.opacity(0.05), lineWidth: 1)
                if pts.count > 1 {
                    fillPath.fill(
                        LinearGradient(colors: [Color.orange.opacity(0.30), Color.orange.opacity(0.02)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    linePath.stroke(Color.orange,
                                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}

// MARK: - 进程排行行

struct ProcessRow: View {
    let entry: ProcessEntry

    var body: some View {
        HStack(spacing: 8) {
            if let icon = entry.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                Color.clear.frame(width: 16, height: 16)
            }
            Text(entry.name)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(Color.accentColor.opacity(0.85))
                        .frame(width: max(4, geo.size.width * entry.fraction))
                }
            }
            .frame(width: 64, height: 6)
            Text(entry.valueText)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .trailing)
        }
    }
}

// MARK: - Claude 行

struct ClaudeRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout.monospacedDigit())
        }
    }
}

// MARK: - 弹出控制器

/// 管理 NSPopover：点击菜单栏猫咪时展示/关闭仪表盘。

final class DashboardController {
    private let popover = NSPopover()
    private let model: DashboardModel
    private weak var app: AppDelegate?
    private var hosting: NSHostingController<DashboardView>?
    private var eventMonitor: Any?
    private var resignObserver: NSObjectProtocol?

    init(app: AppDelegate, model: DashboardModel) {
        self.app = app
        self.model = model
        popover.behavior = .transient
        popover.animates = true
    }

    deinit {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        if let resignObserver {
            NotificationCenter.default.removeObserver(resignObserver)
        }
    }

    /// 安装全局鼠标监视器：点击弹窗外部任意位置自动收起。
    private func installDismissMonitors() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismissIfClickOutside()
        }
        // 应用失去焦点（如 Cmd+Tab 切走）时也收起
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil, queue: .main) { [weak self] _ in
            self?.popover.performClose(nil)
        }
    }

    private func dismissIfClickOutside() {
        guard popover.isShown else { return }
        let loc = NSEvent.mouseLocation // 屏幕坐标（左下原点），与 window.frame 同坐标系
        if let frame = popover.contentViewController?.view.window?.frame,
           frame.contains(loc) {
            return // 点击仍在弹窗内
        }
        popover.performClose(nil)
    }

    func show(from button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        let view = DashboardView(
            model: model,
            onToggleUsage: { [weak self] on in self?.app?.setShowUsageInBar(on) },
            onToggleTemp: { [weak self] on in self?.app?.setShowTempInBar(on) },
            onSelectBreed: { [weak self] i in self?.app?.selectBreed(i) },
            onToggleDaemon: { [weak self] in self?.app?.toggleDaemonAction() },
            onToggleLogin: { [weak self] on in self?.app?.setLoginAtLaunch(on) },
            onAbout: { [weak self] in self?.app?.showAboutPanel() },
            onQuit: { [weak self] in self?.app?.quitApp() },
            onClaudeSetup: { [weak self] in self?.app?.setupClaudeStatus() },
            onClaudeRemove: { [weak self] in self?.app?.removeClaudeStatus() }
        )
        let hosting = NSHostingController(rootView: view)
        self.hosting = hosting
        popover.contentViewController = hosting
        // 先布局一次以获得内容高度
        hosting.view.layoutSubtreeIfNeeded()
        let fitting = hosting.view.fittingSize
        popover.contentSize = NSSize(width: 300, height: min(max(fitting.height, 240), 600))
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        installDismissMonitors()
    }

    func close() {
        popover.performClose(nil)
    }
}
