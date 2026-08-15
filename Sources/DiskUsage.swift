import Foundation

/// 根卷磁盘用量（已用 / 总量 / 百分比）。
struct DiskUsage {
    static func snapshot() -> (total: UInt64, available: UInt64)? {
        let url = URL(fileURLWithPath: "/")
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
        ]
        guard let values = try? url.resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity,
              let available = values.volumeAvailableCapacityForImportantUsage else {
            return nil
        }
        return (UInt64(total), UInt64(available))
    }

    static func formatted() -> String {
        guard let s = snapshot(), s.total > 0 else { return "磁盘: --" }
        let used = s.total - s.available
        let pct = Double(used) / Double(s.total) * 100
        return String(format: "磁盘已用: %.1f GB / %.1f GB (%d%%)",
                      Double(used) / 1e9, Double(s.total) / 1e9, Int(pct))
    }
}
