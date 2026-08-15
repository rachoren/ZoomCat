import Foundation
import Darwin

/// CPU 温度读取器：SMC → IOHID 热事件 → 温度监控助手日志，逐级回退。
/// - SMC：常规 Intel Mac 的标准路径（无需 root）
/// - IOHID：Apple Silicon 及部分新机型（无需 root，参考 Hot/sensors_cmdline）
/// - 温度监控助手：LaunchDaemon 常驻 powermetrics，一次授权安装后自动运行
final class TemperatureProvider {

    // MARK: - SMC（Intel）

    @_silgen_name("smc_open") private static func smc_open() -> Int32
    @_silgen_name("smc_cpu_temp") private static func smc_cpu_temp() -> Double

    private let smcAvailable: Bool

    // MARK: - IOHID

    private let iohid: IOHIDTemperatureReader?

    init() {
        smcAvailable = TemperatureProvider.smc_open() == 1
        iohid = IOHIDTemperatureReader()
    }

    /// 无需任何授权的原生路径（SMC/IOHID）当前是否可用。
    func hasNativeSource() -> Bool {
        if smcAvailable, TemperatureProvider.smc_cpu_temp() > 0 { return true }
        if let t = iohid?.maxTemperature(), t > 0 { return true }
        return false
    }

    /// 当前 CPU 温度（°C），所有来源均不可用时返回 nil。
    func currentTemperature() -> Double? {
        if smcAvailable {
            let t = TemperatureProvider.smc_cpu_temp()
            if t > 0 { return t }
        }
        if let t = iohid?.maxTemperature(), t > 0 { return t }
        if let t = readDaemonLog() { return t }
        return nil
    }

    // MARK: - 温度监控助手日志

    private func readDaemonLog() -> Double? {
        let path = TemperatureDaemon.logPath
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let mtime = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(mtime) < 15 else {
            return nil // 日志不存在或已过期（守护进程未运行）
        }
        guard let fh = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? fh.close() }

        let size = (try? fh.seekToEnd()) ?? 0
        guard size > 0 else { return nil }
        let tailLen = min(size, 65536)
        try? fh.seek(toOffset: size - tailLen)
        let data = fh.readDataToEndOfFile()
        guard let content = String(data: data, encoding: .utf8),
              let re = try? NSRegularExpression(pattern: "CPU die temperature: ([0-9.]+) C") else {
            return nil
        }
        let ns = content as NSString
        let matches = re.matches(in: content, range: NSRange(location: 0, length: ns.length))
        guard let last = matches.last, last.numberOfRanges > 1 else { return nil }
        return Double(ns.substring(with: last.range(at: 1)))
    }
}

/// 通过 IOKit 私有接口 IOHIDEventSystemClient 读取系统热传感器（无需 root）。
/// 参考 Hot (https://github.com/macmade/Hot) 与 sensors_cmdline 的实现。
final class IOHIDTemperatureReader {
    private let handle: UnsafeMutableRawPointer
    private let client: CFTypeRef

    private let clientSetMatching: @convention(c) (CFTypeRef?, CFDictionary?) -> Void
    private let clientCopyServices: @convention(c) (CFTypeRef?) -> Unmanaged<CFArray>?
    private let serviceCopyEvent: @convention(c) (CFTypeRef?, Int64, Int32, Int64) -> Unmanaged<CFTypeRef>?
    private let eventGetFloat: @convention(c) (CFTypeRef?, Int32) -> Double

    init?() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else {
            return nil
        }
        guard
            let symCreate = dlsym(handle, "IOHIDEventSystemClientCreate"),
            let symSetMatching = dlsym(handle, "IOHIDEventSystemClientSetMatching"),
            let symCopyServices = dlsym(handle, "IOHIDEventSystemClientCopyServices"),
            let symCopyEvent = dlsym(handle, "IOHIDServiceClientCopyEvent"),
            let symGetFloat = dlsym(handle, "IOHIDEventGetFloatValue")
        else {
            dlclose(handle)
            return nil
        }

        typealias CreateFn = @convention(c) (CFAllocator?) -> CFTypeRef?
        typealias SetMatchingFn = @convention(c) (CFTypeRef?, CFDictionary?) -> Void
        typealias CopyServicesFn = @convention(c) (CFTypeRef?) -> Unmanaged<CFArray>?
        typealias CopyEventFn = @convention(c) (CFTypeRef?, Int64, Int32, Int64) -> Unmanaged<CFTypeRef>?
        typealias GetFloatFn = @convention(c) (CFTypeRef?, Int32) -> Double

        clientSetMatching = unsafeBitCast(symSetMatching, to: SetMatchingFn.self)
        clientCopyServices = unsafeBitCast(symCopyServices, to: CopyServicesFn.self)
        serviceCopyEvent = unsafeBitCast(symCopyEvent, to: CopyEventFn.self)
        eventGetFloat = unsafeBitCast(symGetFloat, to: GetFloatFn.self)

        let create: CreateFn = unsafeBitCast(symCreate, to: CreateFn.self)
        guard let client = create(kCFAllocatorDefault) else {
            dlclose(handle)
            return nil
        }
        self.client = client
        self.handle = handle

        // 匹配 AppleSMC 温度传感器（kHIDPage_AppleVendor / kHIDUsage_AppleVendor_TemperatureSensor）
        let matching: [String: Int] = ["PrimaryUsagePage": 0xFF00, "PrimaryUsage": 5]
        clientSetMatching(client, matching as CFDictionary)
    }

    deinit {
        dlclose(handle)
    }

    /// 所有热传感器中的最高温度（°C）。
    func maxTemperature() -> Double? {
        guard let services = clientCopyServices(client)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }
        var best = 0.0
        for service in services {
            guard let event = serviceCopyEvent(service, 15, 0, 0)?.takeRetainedValue() else { continue }
            let t = eventGetFloat(event, 15 << 16)
            if t > 0, t < 150, t > best { best = t }
        }
        return best > 0 ? best : nil
    }
}
