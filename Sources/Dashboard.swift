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

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                infoGrid
                graphCard
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

// MARK: - 弹出控制器

/// 管理 NSPopover：点击菜单栏猫咪时展示/关闭仪表盘。

final class DashboardController {
    private let popover = NSPopover()
    private let model: DashboardModel
    private weak var app: AppDelegate?
    private var hosting: NSHostingController<DashboardView>?

    init(app: AppDelegate, model: DashboardModel) {
        self.app = app
        self.model = model
        popover.behavior = .transient
        popover.animates = true
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
            onQuit: { [weak self] in self?.app?.quitApp() }
        )
        let hosting = NSHostingController(rootView: view)
        self.hosting = hosting
        popover.contentViewController = hosting
        // 先布局一次以获得内容高度
        hosting.view.layoutSubtreeIfNeeded()
        let fitting = hosting.view.fittingSize
        popover.contentSize = NSSize(width: 300, height: min(max(fitting.height, 240), 600))
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func close() {
        popover.performClose(nil)
    }
}
