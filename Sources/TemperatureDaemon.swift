import Foundation

/// 温度监控助手：以 LaunchDaemon 方式常驻运行 powermetrics。
/// 一次性授权安装后，开机自动启动、崩溃自动重启，无需再次输入密码。
enum TemperatureDaemon {
    static let label = "local.runcat.temperature"
    static let plistPath = "/Library/LaunchDaemons/\(label).plist"
    static let logPath = "/tmp/runcat_smc.log"

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    /// LaunchDaemon 配置：powermetrics 每 1s 采样一次，
    /// 行缓冲实时写入日志；每 1800 个样本（30 分钟）由 shell 循环
    /// 截断重写日志，保证日志体积有界；KeepAlive 保证异常退出后自动重启。
    static var plistContent: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>/bin/sh</string>
                <string>-c</string>
                <string>while true; do /usr/bin/powermetrics -s smc -i 1000 -f text -n 1800 -b 1 > \(logPath) 2&gt;&amp;1; sleep 2; done</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardErrorPath</key>
            <string>/tmp/runcat_smc.err</string>
        </dict>
        </plist>
        """
    }

    /// 安装（一次管理员授权）。成功时回调 true。
    static func install(completion: @escaping (Bool) -> Void) {
        let tmpPlist = "/tmp/\(label).plist"
        do {
            try plistContent.write(toFile: tmpPlist, atomically: true, encoding: .utf8)
        } catch {
            completion(false)
            return
        }
        let cmd = """
        cp \(tmpPlist) \(plistPath) && chown root:wheel \(plistPath) && chmod 644 \(plistPath) && \
        (launchctl bootout system/\(label) >/dev/null 2>&1; true) && \
        launchctl bootstrap system \(plistPath) && rm -f \(tmpPlist)
        """
        runAdminShell(cmd, completion: completion)
    }

    /// 卸载：停止守护进程并删除配置文件与日志。
    static func uninstall(completion: @escaping (Bool) -> Void) {
        let cmd = """
        (launchctl bootout system/\(label) >/dev/null 2>&1; true) && \
        rm -f \(plistPath) \(logPath) /tmp/runcat_smc.err
        """
        runAdminShell(cmd, completion: completion)
    }

    /// 通过 osascript 以管理员权限执行 shell 命令（弹出一次系统授权框）。
    private static func runAdminShell(_ cmd: String, completion: @escaping (Bool) -> Void) {
        let osa = Process()
        osa.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        osa.arguments = ["-e", "do shell script \"\(cmd)\" with administrator privileges"]
        osa.terminationHandler = { p in
            DispatchQueue.main.async { completion(p.terminationStatus == 0) }
        }
        do {
            try osa.run()
        } catch {
            completion(false)
        }
    }
}
