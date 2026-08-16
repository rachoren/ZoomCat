import Foundation
import Darwin

/// 单条进程占用信息。
struct TopProcess {
    let pid: Int32
    let name: String
    let path: String?
    let cpuPercent: Double // 单核百分比（100 = 占满一个核）
    let memoryBytes: UInt64
}

/// 进程占用采集：一次 sysctl(KERN_PROC_ALL) 批量获取全部进程，开销极小。
enum ProcessMonitor {
    /// CPU 时间缓存：[pid: (累计CPU时间µs, 采样时刻)]
    typealias CPUCache = [Int32: (cpu: UInt64, at: TimeInterval)]

    /// 全量快照：返回所有进程的占用信息（CPU 为两次采样间的增量）。
    /// proc_pidinfo 全量遍历实测约 2ms，开销可忽略。
    static func snapshot(cache: CPUCache,
                         now: TimeInterval = Date().timeIntervalSince1970)
        -> (entries: [TopProcess], newCache: CPUCache) {

        var pids = [Int32](repeating: 0, count: 8192)
        let count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<Int32>.size))
        guard count > 0 else { return ([], cache) }

        var entries: [TopProcess] = []
        var newCache: CPUCache = [:]

        for i in 0..<Int(count) {
            let pid = pids[i]
            var info = proc_taskinfo()
            let infoSize = MemoryLayout<proc_taskinfo>.size
            guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(infoSize)) == Int32(infoSize) else {
                continue
            }
            // CPU 时间（纳秒）+ 内存（RSS）
            let total = UInt64(info.pti_total_user) + UInt64(info.pti_total_system)
            var cpu: Double = 0
            if let prev = cache[pid] {
                let dt = now - prev.at
                if dt > 0.3 {
                    let delta = total > prev.cpu ? total - prev.cpu : 0
                    // delta(ns) / dt(s) = 单核占用比例，×100 = 单核百分比
                    cpu = Double(delta) / (dt * 1e9) * 100.0
                }
            }
            newCache[pid] = (total, now)

            var nameBuf = [CChar](repeating: 0, count: 256)
            let nameLen = proc_name(pid, &nameBuf, UInt32(nameBuf.count))
            let name = nameLen > 0 ? String(cString: nameBuf) : "?"

            entries.append(TopProcess(pid: pid, name: name, path: nil,
                                      cpuPercent: cpu, memoryBytes: UInt64(info.pti_resident_size)))
        }
        return (entries, newCache)
    }

    /// 进程可执行文件路径（仅对少量进程调用，用于取应用图标）。
    static func path(for pid: Int32) -> String? {
        var buf = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let n = proc_pidpath(pid, &buf, UInt32(buf.count))
        return n > 0 ? String(cString: buf) : nil
    }
}
