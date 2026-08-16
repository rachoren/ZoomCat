import AppKit

/// 角色种类：猫 + 其他动物（参考 RunCatNeo 的 Runner Gallery）。
enum RunnerKind: String, CaseIterable {
    case cat, shiba, rabbit, panda, penguin

    var displayName: String {
        switch self {
        case .cat:     return "猫咪"
        case .shiba:   return "柴犬"
        case .rabbit:  return "兔子"
        case .panda:   return "熊猫"
        case .penguin: return "企鹅"
        }
    }

    var emoji: String {
        switch self {
        case .cat:     return "🐱"
        case .shiba:   return "🐶"
        case .rabbit:  return "🐰"
        case .panda:   return "🐼"
        case .penguin: return "🐧"
        }
    }
}

/// 一个角色的全部动画帧。
struct RunnerFrames {
    let running: [NSImage]
    let sitting: [NSImage]
    let sleeping: [NSImage]? // 仅猫咪支持睡觉姿势
}

/// 角色帧工厂：按种类 + 猫咪品种生成动画。
enum RunnerFactory {
    static func frames(kind: RunnerKind, catBreed: CatBreed) -> RunnerFrames {
        switch kind {
        case .cat:
            let p = CatPainter(breed: catBreed)
            return RunnerFrames(running: p.runningFrames(),
                                sitting: p.sittingFrames(),
                                sleeping: p.sleepingFrames())
        case .shiba:
            let p = ShibaPainter()
            return RunnerFrames(running: p.runningFrames(), sitting: p.sittingFrames(), sleeping: nil)
        case .rabbit:
            let p = RabbitPainter()
            return RunnerFrames(running: p.runningFrames(), sitting: p.sittingFrames(), sleeping: nil)
        case .panda:
            let p = PandaPainter()
            return RunnerFrames(running: p.runningFrames(), sitting: p.sittingFrames(), sleeping: nil)
        case .penguin:
            let p = PenguinPainter()
            return RunnerFrames(running: p.runningFrames(), sitting: p.sittingFrames(), sleeping: nil)
        }
    }
}
