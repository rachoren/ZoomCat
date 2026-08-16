import Foundation
import Darwin

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
