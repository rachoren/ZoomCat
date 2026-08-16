import Foundation
import Darwin
import IOKit.ps

/// 内存用量（host_statistics64，公开 mach API）。
struct MemoryStats {
    static func usage() -> (usedGB: Double, totalGB: Double, percent: Double)? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }
        let page = Double(vm_kernel_page_size)
        // 已用 = 活跃 + 内核 + 压缩（不含可回收的空闲/非活跃）
        let used = (Double(stats.active_count) + Double(stats.wire_count) + Double(stats.compressor_page_count)) * page
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        guard total > 0 else { return nil }
        return (used / 1e9, total / 1e9, used / total)
    }

    static func formatted() -> String {
        guard let u = usage() else { return "--" }
        return String(format: "%.1f / %.1f GB", u.usedGB, u.totalGB)
    }
}

/// 网络流量计数器（NET_RT_IFLIST2，64 位不溢出）。
struct NetworkStats {
    static func counters() -> (rx: UInt64, tx: UInt64)? {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len: size_t = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &len, nil, 0) == 0, len > 0 else { return nil }
        var buf = [UInt8](repeating: 0, count: len)
        guard sysctl(&mib, UInt32(mib.count), &buf, &len, nil, 0) == 0 else { return nil }

        var rx: UInt64 = 0
        var tx: UInt64 = 0
        var offset: size_t = 0
        while offset < len {
            let msghdr = buf.withUnsafeBytes { raw -> if_msghdr in
                raw.baseAddress!.advanced(by: offset).assumingMemoryBound(to: if_msghdr.self).pointee
            }
            if msghdr.ifm_type == RTM_IFINFO2 {
                let data = buf.withUnsafeBytes { raw -> if_data64 in
                    raw.baseAddress!.advanced(by: offset).assumingMemoryBound(to: if_msghdr2.self).pointee.ifm_data
                }
                rx += data.ifi_ibytes
                tx += data.ifi_obytes
            }
            offset += Int(msghdr.ifm_msglen)
        }
        return (rx, tx)
    }

    /// 格式化速率：B/s / KB/s / MB/s。
    static func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1_048_576 {
            return String(format: "%.1f MB/s", bytesPerSec / 1_048_576)
        }
        if bytesPerSec >= 1024 {
            return String(format: "%.0f KB/s", bytesPerSec / 1024)
        }
        return String(format: "%.0f B/s", bytesPerSec)
    }
}

/// 电池信息（IOPS 公开 API）。
struct BatteryStats {
    static func formatted() -> String {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        guard let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as? [CFTypeRef] else {
            return "--"
        }
        for src in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, src)?.takeUnretainedValue() as? [String: Any],
                  let current = desc[kIOPSCurrentCapacityKey] as? Int else { continue }
            let maxCap = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            let pct = current * 100 / max(1, maxCap)
            let isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false
            let isCharged = desc[kIOPSIsChargedKey] as? Bool ?? false
            let state = desc[kIOPSPowerSourceStateKey] as? String ?? ""
            let timeToEmpty = desc[kIOPSTimeToEmptyKey] as? Int ?? -1
            let timeToFull = desc[kIOPSTimeToFullChargeKey] as? Int ?? -1

            if state == kIOPSACPowerValue {
                if isCharged { return "\(pct)% · 已充满" }
                if isCharging {
                    return timeToFull > 0 ? "\(pct)% · 充电中 \(formatMinutes(timeToFull))" : "\(pct)% · 充电中"
                }
                return "\(pct)% · 电源供电"
            }
            if timeToEmpty > 0 { return "\(pct)% · \(formatMinutes(timeToEmpty)) 剩余" }
            return "\(pct)% · 电池供电"
        }
        return "--"
    }

    private static func formatMinutes(_ m: Int) -> String {
        if m >= 60 { return "\(m / 60)h\(m % 60)m" }
        return "\(m)m"
    }
}
