import AppKit

// MARK: - 柴犬

/// 柴犬：橘棕卷尾犬（白口鼻、卷尾巴）。
struct ShibaPainter {
    private let tan = NSColor(calibratedRed: 0.83, green: 0.60, blue: 0.34, alpha: 1)
    private let white = NSColor(calibratedWhite: 0.96, alpha: 1)
    private let outline = NSColor(calibratedWhite: 0.12, alpha: 1)
    private let eye = NSColor(calibratedWhite: 0.10, alpha: 1)

    private struct Geo {
        var body: NSRect
        var head: NSPoint
        var headR: CGFloat
        var hipY: CGFloat
        var footY: CGFloat
        var backX: (CGFloat, CGFloat)
        var frontX: (CGFloat, CGFloat)
    }

    private var geo: Geo {
        Geo(body: NSRect(x: 4.7, y: 7.3, width: 11.6, height: 7.8),
            head: NSPoint(x: 15.6, y: 13.6), headR: 3.6,
            hipY: 8.3, footY: 5.0, backX: (7.0, 8.9), frontX: (12.6, 14.4))
    }

    private struct SitGeo {
        var haunch: NSRect
        var body: NSRect
        var frontXs: [CGFloat]
    }

    func runningFrames() -> [NSImage] {
        (0..<8).map { i in
            FrameRenderer.makeImage { drawRunning(phase: Double(i) / 8.0) }
        }
    }

    func sittingFrames() -> [NSImage] {
        (0..<2).map { _ in
            FrameRenderer.makeImage { drawSitting() }
        }
    }

    private func drawRunning(phase: Double) {
        let g = geo
        let phi = phase * 2 * .pi

        // 卷尾巴（先画，卷在身后上方）
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: g.body.minX + 0.5, y: g.body.midY + 0.5))
        tail.curve(to: NSPoint(x: g.body.minX - 1.1, y: g.body.maxY + 1.8),
                   controlPoint1: NSPoint(x: g.body.minX - 0.6, y: g.body.midY + 1.7),
                   controlPoint2: NSPoint(x: g.body.minX - 1.7, y: g.body.maxY + 0.4))
        tail.curve(to: NSPoint(x: g.body.minX + 0.8, y: g.body.maxY + 0.8),
                   controlPoint1: NSPoint(x: g.body.minX - 0.5, y: g.body.maxY + 2.8),
                   controlPoint2: NSPoint(x: g.body.minX + 1.0, y: g.body.maxY + 2.0))
        tail.lineWidth = 2.8
        tail.lineCapStyle = .round
        tan.setStroke()
        tail.stroke()

        drawLeg(hip: NSPoint(x: g.backX.0, y: g.hipY), offset: phi + .pi)
        drawLeg(hip: NSPoint(x: g.backX.1, y: g.hipY), offset: phi)

        let bodyPath = NSBezierPath(ovalIn: g.body)
        tan.setFill(); bodyPath.fill()
        outline.setStroke(); bodyPath.lineWidth = 0.7; bodyPath.stroke()
        // 白肚皮
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: g.body.midX - g.body.width * 0.40, y: g.body.minY + g.body.height * 0.10,
                                    width: g.body.width * 0.80, height: g.body.height * 0.48)).fill()

        drawLeg(hip: NSPoint(x: g.frontX.0, y: g.hipY), offset: phi)
        drawLeg(hip: NSPoint(x: g.frontX.1, y: g.hipY), offset: phi + .pi)

        drawHead(g)
    }

    private func drawSitting() {
        let g = geo
        let haunch = NSBezierPath(ovalIn: NSRect(x: 5.0, y: 6.6, width: 5.2, height: 5.4))
        tan.setFill(); haunch.fill()
        outline.setStroke(); haunch.lineWidth = 0.7; haunch.stroke()

        let body = NSBezierPath(ovalIn: NSRect(x: 7.6, y: 8.2, width: 9.2, height: 6.8))
        tan.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 8.2, y: 8.4, width: 6.6, height: 4.4)).fill()

        for x in [12.9, 15.0] {
            let leg = NSBezierPath()
            leg.move(to: NSPoint(x: x, y: 8.2))
            leg.line(to: NSPoint(x: x, y: 4.9))
            leg.lineWidth = 2.0
            leg.lineCapStyle = .round
            tan.setStroke()
            leg.stroke()
        }

        // 卷尾巴
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: 5.4, y: 10.8))
        tail.curve(to: NSPoint(x: 4.2, y: 13.4),
                   controlPoint1: NSPoint(x: 3.6, y: 11.6),
                   controlPoint2: NSPoint(x: 3.4, y: 12.9))
        tail.curve(to: NSPoint(x: 5.8, y: 12.8),
                   controlPoint1: NSPoint(x: 5.0, y: 13.9),
                   controlPoint2: NSPoint(x: 6.1, y: 13.4))
        tail.lineWidth = 2.8
        tail.lineCapStyle = .round
        tan.setStroke()
        tail.stroke()

        drawHead(g)
    }

    private func drawHead(_ g: Geo) {
        let r = g.headR
        let h = g.head
        let headPath = NSBezierPath(ovalIn: NSRect(x: h.x - r, y: h.y - r, width: r * 2, height: r * 2))
        tan.setFill(); headPath.fill()
        outline.setStroke(); headPath.lineWidth = 0.7; headPath.stroke()

        // 白色口鼻
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.25, y: h.y - r * 0.55, width: r * 1.15, height: r * 0.85)).fill()

        // 耳朵（小三角）
        for side: CGFloat in [-1, 1] {
            let ear = NSBezierPath()
            ear.move(to: NSPoint(x: h.x + side * r * 0.55, y: h.y + r * 0.55))
            ear.line(to: NSPoint(x: h.x + side * r * 0.95, y: h.y + r * 1.30))
            ear.line(to: NSPoint(x: h.x + side * r * 0.15, y: h.y + r * 0.90))
            ear.close()
            tan.setFill(); ear.fill()
            outline.setStroke(); ear.lineWidth = 0.6; ear.stroke()
        }

        // 眼睛
        eye.setFill()
        let es: CGFloat = 0.9
        NSBezierPath(ovalIn: NSRect(x: h.x - r * 0.35, y: h.y + r * 0.12, width: es, height: es)).fill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.30, y: h.y + r * 0.12, width: es, height: es)).fill()
        // 鼻子（口鼻前端）
        outline.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 1.05, y: h.y - r * 0.30, width: 0.8, height: 0.6)).fill()
    }

    private func drawLeg(hip: NSPoint, offset: Double) {
        let fx = hip.x + 3.4 * sin(offset)
        let lift = max(0, sin(offset + 0.7)) * 1.8
        let foot = NSPoint(x: fx, y: 5.0 - lift)
        let leg = NSBezierPath()
        leg.move(to: hip)
        leg.line(to: foot)
        leg.lineWidth = 2.0
        leg.lineCapStyle = .round
        tan.setStroke()
        leg.stroke()
    }
}

// MARK: - 兔子

/// 兔子：白兔长耳（粉色内耳、圆尾、蹦跳）。
struct RabbitPainter {
    private let white = NSColor(calibratedWhite: 0.96, alpha: 1)
    private let pink = NSColor(calibratedRed: 0.96, green: 0.66, blue: 0.70, alpha: 1)
    private let outline = NSColor(calibratedWhite: 0.14, alpha: 1)
    private let eye = NSColor(calibratedWhite: 0.12, alpha: 1)

    private var headC = NSPoint(x: 15.2, y: 14.0)
    private var headR: CGFloat = 3.4

    func runningFrames() -> [NSImage] {
        (0..<8).map { i in
            FrameRenderer.makeImage { drawRunning(phase: Double(i) / 8.0) }
        }
    }

    func sittingFrames() -> [NSImage] {
        (0..<2).map { _ in
            FrameRenderer.makeImage { drawSitting() }
        }
    }

    private func drawRunning(phase: Double) {
        let phi = phase * 2 * .pi
        let body = NSRect(x: 5.2, y: 7.2, width: 10.8, height: 7.6)
        let bounce = 0.6 * abs(sin(phi * 2))
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        cg.translateBy(x: 0, y: bounce)

        // 圆尾（先画）
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: body.minX - 1.6, y: body.midY + 0.2, width: 2.6, height: 2.6)).fill()

        // 后腿
        drawLeg(hip: NSPoint(x: body.minX + 2.4, y: body.minY + 1.0), offset: phi + .pi)
        drawLeg(hip: NSPoint(x: body.minX + 4.2, y: body.minY + 1.0), offset: phi)

        // 身体
        let bodyPath = NSBezierPath(ovalIn: body)
        white.setFill(); bodyPath.fill()
        outline.setStroke(); bodyPath.lineWidth = 0.7; bodyPath.stroke()

        drawLeg(hip: NSPoint(x: body.maxX - 3.6, y: body.minY + 1.0), offset: phi)
        drawLeg(hip: NSPoint(x: body.maxX - 1.8, y: body.minY + 1.0), offset: phi + .pi)

        drawHead(body)
        cg.restoreGState()
    }

    private func drawSitting() {
        // 后臀
        let haunch = NSBezierPath(ovalIn: NSRect(x: 5.4, y: 6.6, width: 4.8, height: 5.6))
        white.setFill(); haunch.fill()
        outline.setStroke(); haunch.lineWidth = 0.7; haunch.stroke()
        // 圆尾
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 4.0, y: 9.0, width: 2.8, height: 2.8)).fill()

        // 身体
        let body = NSBezierPath(ovalIn: NSRect(x: 8.0, y: 8.4, width: 8.6, height: 6.4))
        white.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()

        // 前爪
        for x in [12.6, 14.8] {
            let leg = NSBezierPath()
            leg.move(to: NSPoint(x: x, y: 8.4))
            leg.line(to: NSPoint(x: x, y: 5.2))
            leg.lineWidth = 2.0
            leg.lineCapStyle = .round
            white.setStroke()
            leg.stroke()
        }

        drawHead(NSRect(x: 7.0, y: 8.0, width: 9.6, height: 7.0))
    }

    private func drawHead(_ body: NSRect) {
        let h = headC
        let r = headR

        // 长耳朵（先画在头后）
        for side: CGFloat in [-1, 1] {
            let ear = NSBezierPath(ovalIn: NSRect(x: h.x + side * r * 0.95 - 0.7,
                                                  y: h.y + r * 0.55,
                                                  width: 1.5, height: 4.4))
            white.setFill(); ear.fill()
            outline.setStroke(); ear.lineWidth = 0.6; ear.stroke()
            // 粉色内耳
            pink.setFill()
            NSBezierPath(ovalIn: NSRect(x: h.x + side * r * 0.95 - 0.35,
                                        y: h.y + r * 0.75,
                                        width: 0.75, height: 3.2)).fill()
        }

        // 头
        let headPath = NSBezierPath(ovalIn: NSRect(x: h.x - r, y: h.y - r, width: r * 2, height: r * 2))
        white.setFill(); headPath.fill()
        outline.setStroke(); headPath.lineWidth = 0.7; headPath.stroke()

        // 眼睛
        eye.setFill()
        let es: CGFloat = 0.85
        NSBezierPath(ovalIn: NSRect(x: h.x - r * 0.35, y: h.y + r * 0.10, width: es, height: es)).fill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.28, y: h.y + r * 0.10, width: es, height: es)).fill()
        // 粉鼻子
        pink.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.85, y: h.y - r * 0.25, width: 0.8, height: 0.7)).fill()
    }

    private func drawLeg(hip: NSPoint, offset: Double) {
        let fx = hip.x + 3.2 * sin(offset)
        let lift = max(0, sin(offset + 0.7)) * 1.8
        let foot = NSPoint(x: fx, y: 5.0 - lift)
        let leg = NSBezierPath()
        leg.move(to: hip)
        leg.line(to: foot)
        leg.lineWidth = 2.0
        leg.lineCapStyle = .round
        white.setStroke()
        leg.stroke()
    }
}

// MARK: - 熊猫

/// 熊猫：黑白圆滚滚（黑耳、黑眼圈、黑四肢）。
struct PandaPainter {
    private let white = NSColor(calibratedWhite: 0.96, alpha: 1)
    private let black = NSColor(calibratedWhite: 0.16, alpha: 1)
    private let outline = NSColor(calibratedWhite: 0.10, alpha: 1)

    private var headC = NSPoint(x: 15.0, y: 13.8)
    private var headR: CGFloat = 3.5

    func runningFrames() -> [NSImage] {
        (0..<8).map { i in
            FrameRenderer.makeImage { drawRunning(phase: Double(i) / 8.0) }
        }
    }

    func sittingFrames() -> [NSImage] {
        (0..<2).map { _ in
            FrameRenderer.makeImage { drawSitting() }
        }
    }

    private func drawRunning(phase: Double) {
        let phi = phase * 2 * .pi
        let body = NSRect(x: 5.0, y: 7.0, width: 11.2, height: 8.0)
        let bounce = 0.4 * abs(sin(phi * 2))
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        cg.translateBy(x: 0, y: bounce)

        // 黑后腿
        drawLeg(hip: NSPoint(x: body.minX + 2.4, y: body.minY + 1.0), offset: phi + .pi, color: black)
        drawLeg(hip: NSPoint(x: body.minX + 4.2, y: body.minY + 1.0), offset: phi, color: black)

        // 白身体
        let bodyPath = NSBezierPath(ovalIn: body)
        white.setFill(); bodyPath.fill()
        outline.setStroke(); bodyPath.lineWidth = 0.7; bodyPath.stroke()

        // 黑前腿
        drawLeg(hip: NSPoint(x: body.maxX - 3.4, y: body.minY + 1.0), offset: phi, color: black)
        drawLeg(hip: NSPoint(x: body.maxX - 1.6, y: body.minY + 1.0), offset: phi + .pi, color: black)

        drawHead(body)
        cg.restoreGState()
    }

    private func drawSitting() {
        // 后臀
        let haunch = NSBezierPath(ovalIn: NSRect(x: 5.2, y: 6.8, width: 5.2, height: 5.2))
        white.setFill(); haunch.fill()
        outline.setStroke(); haunch.lineWidth = 0.7; haunch.stroke()
        // 身体
        let body = NSBezierPath(ovalIn: NSRect(x: 7.8, y: 8.4, width: 9.0, height: 6.6))
        white.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()
        // 黑前臂
        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: 12.6, y: 7.4, width: 2.2, height: 3.4)).fill()
        NSBezierPath(ovalIn: NSRect(x: 14.8, y: 7.4, width: 2.2, height: 3.4)).fill()
        drawHead(NSRect(x: 7.2, y: 8.0, width: 9.8, height: 7.0))
    }

    private func drawHead(_ body: NSRect) {
        let h = headC
        let r = headR

        // 黑耳朵（圆）
        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x - r * 1.25, y: h.y + r * 0.75, width: 1.7, height: 1.7)).fill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.55, y: h.y + r * 0.75, width: 1.7, height: 1.7)).fill()

        // 头
        let headPath = NSBezierPath(ovalIn: NSRect(x: h.x - r, y: h.y - r, width: r * 2, height: r * 2))
        white.setFill(); headPath.fill()
        outline.setStroke(); headPath.lineWidth = 0.7; headPath.stroke()

        // 黑眼圈 + 眼睛
        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x - r * 0.85, y: h.y - r * 0.05, width: r * 0.95, height: r * 1.05)).fill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.25, y: h.y - r * 0.05, width: r * 0.95, height: r * 1.05)).fill()
        white.setFill()
        let es: CGFloat = 0.55
        NSBezierPath(ovalIn: NSRect(x: h.x - r * 0.40, y: h.y + r * 0.15, width: es, height: es)).fill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.62, y: h.y + r * 0.15, width: es, height: es)).fill()
        // 鼻子
        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.75, y: h.y - r * 0.42, width: 0.9, height: 0.7)).fill()
    }

    private func drawLeg(hip: NSPoint, offset: Double, color: NSColor) {
        let fx = hip.x + 3.2 * sin(offset)
        let lift = max(0, sin(offset + 0.7)) * 1.8
        let foot = NSPoint(x: fx, y: 5.0 - lift)
        let leg = NSBezierPath()
        leg.move(to: hip)
        leg.line(to: foot)
        leg.lineWidth = 2.2
        leg.lineCapStyle = .round
        color.setStroke()
        leg.stroke()
    }
}

// MARK: - 企鹅

/// 企鹅：黑背白肚橙嘴，左右摇摆走路。
struct PenguinPainter {
    private let black = NSColor(calibratedWhite: 0.22, alpha: 1)
    private let white = NSColor(calibratedWhite: 0.97, alpha: 1)
    private let orange = NSColor(calibratedRed: 0.96, green: 0.62, blue: 0.23, alpha: 1)
    private let outline = NSColor(calibratedWhite: 0.10, alpha: 1)

    func runningFrames() -> [NSImage] {
        (0..<8).map { i in
            FrameRenderer.makeImage { drawWaddle(phase: Double(i) / 8.0) }
        }
    }

    func sittingFrames() -> [NSImage] {
        (0..<2).map { _ in
            FrameRenderer.makeImage { drawStanding() }
        }
    }

    private func drawWaddle(phase: Double) {
        let phi = phase * 2 * .pi
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        // 摇摆
        cg.translateBy(x: 11, y: 8.2)
        cg.rotate(by: CGFloat(sin(phi) * 0.08))
        cg.translateBy(x: -11, y: -8.2)

        // 橙色脚（交替）
        let footLift = max(0, sin(phi + .pi))
        orange.setStroke()
        for (x, off) in [(7.4, phi), (14.0, phi + .pi)] {
            let foot = NSBezierPath()
            foot.move(to: NSPoint(x: x, y: 5.4))
            foot.line(to: NSPoint(x: x + 1.4, y: 4.6 - CGFloat(max(0, sin(off + 0.6))) * 1.0))
            foot.lineWidth = 1.8
            foot.lineCapStyle = .round
            foot.stroke()
        }
        _ = footLift

        // 身体（蛋形）
        let body = NSBezierPath(ovalIn: NSRect(x: 5.4, y: 6.6, width: 11.2, height: 8.8))
        black.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()
        // 白肚皮
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 7.0, y: 7.2, width: 7.0, height: 7.0)).fill()

        // 鳍（两侧）
        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: 3.6, y: 8.6, width: 2.0, height: 5.0)).fill()
        NSBezierPath(ovalIn: NSRect(x: 16.2, y: 8.6, width: 2.0, height: 5.0)).fill()

        // 橙嘴
        orange.setFill()
        let beak = NSBezierPath()
        beak.move(to: NSPoint(x: 15.8, y: 11.2))
        beak.line(to: NSPoint(x: 17.6, y: 10.8))
        beak.line(to: NSPoint(x: 15.8, y: 10.2))
        beak.close()
        beak.fill()

        // 白眼睛
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 14.9, y: 11.4, width: 1.3, height: 1.5)).fill()
        cg.restoreGState()
    }

    private func drawStanding() {
        let body = NSBezierPath(ovalIn: NSRect(x: 5.4, y: 6.2, width: 11.2, height: 9.2))
        black.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 7.0, y: 6.8, width: 7.0, height: 7.4)).fill()

        // 鳍
        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: 3.4, y: 7.8, width: 2.2, height: 5.6)).fill()
        NSBezierPath(ovalIn: NSRect(x: 16.4, y: 7.8, width: 2.2, height: 5.6)).fill()

        // 橙嘴 + 脚
        orange.setFill()
        let beak = NSBezierPath()
        beak.move(to: NSPoint(x: 15.8, y: 10.8))
        beak.line(to: NSPoint(x: 17.6, y: 10.4))
        beak.line(to: NSPoint(x: 15.8, y: 9.8))
        beak.close()
        beak.fill()
        NSBezierPath(ovalIn: NSRect(x: 7.0, y: 5.6, width: 2.6, height: 1.2)).fill()
        NSBezierPath(ovalIn: NSRect(x: 12.6, y: 5.6, width: 2.6, height: 1.2)).fill()

        // 白眼睛
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 14.9, y: 11.0, width: 1.3, height: 1.5)).fill()
    }
}
