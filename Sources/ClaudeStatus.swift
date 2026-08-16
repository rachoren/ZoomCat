import Foundation

/// Claude Code 会话快照（statusLine 钩子写入 ~/.claude/zoomcat-usage.json）。
struct ClaudeStatusSnapshot: Decodable {
    let model: String?
    let context: Double?
    let fiveHour: Double?
    let sevenDay: Double?
    let fiveResetAt: Double?
    let sevenResetAt: Double?
    let updatedAt: String?
}

/// Claude Code 集成：statusLine 脚本安装 / settings.json 注册 / 状态读取。
/// 机制同 RunCatNeo 的 Custom Metrics 示例：Claude Code 每轮回答后调用
/// statusLine 命令（stdin 传 JSON），脚本把摘要写入状态文件，仪表盘读取展示。
enum ClaudeStatus {
    static let scriptPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/zoomcat-statusline.py").path
    static let jsonPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/zoomcat-usage.json").path
    static let settingsPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/settings.json").path

    /// 是否已配置（settings.json 的 statusLine 指向我们的脚本）。
    static var isConfigured: Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sl = json["statusLine"] as? [String: Any],
              let cmd = sl["command"] as? String else { return false }
        return cmd == scriptPath
    }

    /// 读取会话快照。
    static func read() -> ClaudeStatusSnapshot? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) else { return nil }
        return try? JSONDecoder().decode(ClaudeStatusSnapshot.self, from: data)
    }

    /// 安装 statusLine 脚本。
    static func installScript() -> Bool {
        do {
            try pythonScript.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
            return true
        } catch {
            return false
        }
    }

    enum RegisterResult { case success, conflict, failure }

    /// 注册 statusLine（保留 settings.json 中其他配置；冲突时返回 conflict）。
    static func register() -> RegisterResult {
        guard installScript() else { return .failure }
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = obj
        }
        if let existing = json["statusLine"] as? [String: Any],
           let cmd = existing["command"] as? String, cmd != scriptPath {
            return .conflict
        }
        json["statusLine"] = ["type": "command", "command": scriptPath]
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: settingsPath), options: .atomic)
            return .success
        } catch {
            return .failure
        }
    }

    /// 移除我们的 statusLine（保留用户自定义的其他 statusLine）。
    static func unregister() {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
           var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let sl = json["statusLine"] as? [String: Any],
               let cmd = sl["command"] as? String, cmd == scriptPath {
                json.removeValue(forKey: "statusLine")
                if let out = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
                    try? out.write(to: URL(fileURLWithPath: settingsPath), options: .atomic)
                }
            }
        }
        try? FileManager.default.removeItem(atPath: scriptPath)
    }

    /// 汇总展示文本。
    static func summary() -> (model: String, context: String, five: String, seven: String, active: Bool) {
        guard let s = read() else { return ("--", "--", "--", "--", false) }
        // 新鲜度：文件在 90 秒内更新过视为会话活跃
        var active = false
        if let attrs = try? FileManager.default.attributesOfItem(atPath: jsonPath),
           let mtime = attrs[.modificationDate] as? Date {
            active = Date().timeIntervalSince(mtime) < 90
        }
        let five = formatPercent(s.fiveHour) + formatReset(s.fiveResetAt)
        let seven = formatPercent(s.sevenDay) + formatReset(s.sevenResetAt)
        return (s.model ?? "--", formatPercent(s.context), five, seven, active)
    }

    private static func formatPercent(_ v: Double?) -> String {
        guard let v else { return "--" }
        return String(format: "%g%%", v)
    }

    private static func formatReset(_ epoch: Double?) -> String {
        guard let e = epoch, e > 0 else { return "" }
        let date = Date(timeIntervalSince1970: e)
        let f = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            f.dateFormat = "'('~HH:mm')'"
        } else {
            f.dateFormat = "'('~M/d HH:mm')'"
        }
        return f.string(from: date)
    }

    /// statusLine 脚本（写入 ~/.claude/zoomcat-statusline.py）。
    static let pythonScript = """
    #!/usr/bin/env python3
    # ZoomCat — Claude Code statusLine 集成脚本
    # 每轮回答后 Claude Code 调用本脚本（stdin 传 JSON），
    # 把会话摘要写入 ~/.claude/zoomcat-usage.json 供 ZoomCat 仪表盘展示。

    import json
    import os
    import sys
    import tempfile
    from datetime import datetime, timezone
    from pathlib import Path

    OUT = Path(os.environ.get("ZOOMCAT_OUT_FILE", str(Path.home() / ".claude" / "zoomcat-usage.json")))

    def pct(d):
        return d.get("used_percentage") if isinstance(d, dict) else None

    def epoch(d):
        return d.get("resets_at") if isinstance(d, dict) else None

    try:
        payload = json.load(sys.stdin)
        if not isinstance(payload, dict):
            payload = {}
    except Exception:
        payload = {}

    limits = payload.get("rate_limits") or {}
    snapshot = {
        "model": ((payload.get("model") or {}).get("display_name")) or "Claude Code",
        "context": pct(payload.get("context_window")),
        "fiveHour": pct(limits.get("five_hour")),
        "sevenDay": pct(limits.get("seven_day")),
        "fiveResetAt": epoch(limits.get("five_hour")),
        "sevenResetAt": epoch(limits.get("seven_day")),
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    OUT.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".zoomcat-", dir=str(OUT.parent))
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(snapshot, f)
    os.replace(tmp, OUT)
    print(snapshot["model"])
    """
}
