import Darwin

/// 通过 mach host_statistics 采样整机 CPU 使用率（0.0 ~ 1.0），带指数平滑。
struct CPUUsage {
    private var previous = host_cpu_load_info()
    private var hasPrevious = false
    private var smoothed: Double = 0

    mutating func sample() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
        )
        let kr = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return smoothed }

        if hasPrevious {
            let user = Double(info.cpu_ticks.0 - previous.cpu_ticks.0)
            let system = Double(info.cpu_ticks.1 - previous.cpu_ticks.1)
            let idle = Double(info.cpu_ticks.2 - previous.cpu_ticks.2)
            let nice = Double(info.cpu_ticks.3 - previous.cpu_ticks.3)
            let total = user + system + idle + nice
            if total > 0 {
                let busy = (user + system + nice) / total
                smoothed = smoothed <= 0 ? busy : smoothed * 0.65 + busy * 0.35
            }
        }
        previous = info
        hasPrevious = true
        return smoothed
    }
}
