import AppKit

// 30×18 画布公共模板（地面 y≈4.3）：
// 奔跑身体 (4.0, 6.0, 19.0, 6.6)、头 (23.6, 10.4)、腿臀 y 6.6 / 脚 y 4.3
// 端坐：后臀 (5.2, 5.6, 6.2, 6.0)、身体 (8.6, 7.4, 13.5, 6.0)、前腿至 y 4.9

// MARK: - 柴犬

/// 柴犬：橘棕卷尾犬（长身体、白口鼻、卷尾巴）。
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
        Geo(body: NSRect(x: 4.0, y: 6.0, width: 19.0, height: 6.6),
            head: NSPoint(x: 23.6, y: 10.4), headR: 3.7,
            hipY: 6.6, footY: 4.3, backX: (7.0, 9.0), frontX: (19.6, 21.4))
    }

    func runningFrames() -> [NSImage] {
        (0..<16).map { i in
            FrameRenderer.makeImage { drawRunning(frame: i) }
        }
    }

    func sittingFrames() -> [NSImage] {
        (0..<4).map { i in
            FrameRenderer.makeImage { drawSitting(frame: i) }
        }
    }

    private func drawRunning(frame: Int) {
        let g = geo
        let phase = Double(frame % 8) / 8.0
        let stride = Double(frame / 8)
        let phi = phase * 2 * .pi
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        cg.translateBy(x: 0, y: CGFloat((0.35 - 0.10 * stride) * abs(sin(phi * 2))))

        // 卷尾巴（在身体后上方）
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: g.body.minX + 0.6, y: g.body.midY + 0.6))
        tail.curve(to: NSPoint(x: g.body.minX - 0.8 - 0.4 * stride, y: g.body.maxY + 2.2),
                   controlPoint1: NSPoint(x: g.body.minX - 0.3, y: g.body.midY + 2.2),
                   controlPoint2: NSPoint(x: g.body.minX - 1.3, y: g.body.maxY + 0.8))
        tail.curve(to: NSPoint(x: g.body.minX + 1.0, y: g.body.maxY + 1.2),
                   controlPoint1: NSPoint(x: g.body.minX - 0.3, y: g.body.maxY + 3.2),
                   controlPoint2: NSPoint(x: g.body.minX + 1.2, y: g.body.maxY + 2.6))
        tail.lineWidth = 2.8
        tail.lineCapStyle = .round
        tan.setStroke()
        tail.stroke()

        drawLeg(hip: NSPoint(x: g.backX.0, y: g.hipY), offset: phi + .pi)
        drawLeg(hip: NSPoint(x: g.backX.1, y: g.hipY), offset: phi)

        let bodyPath = NSBezierPath(ovalIn: g.body)
        tan.setFill(); bodyPath.fill()
        outline.setStroke(); bodyPath.lineWidth = 0.7; bodyPath.stroke()
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: g.body.midX - g.body.width * 0.40, y: g.body.minY + g.body.height * 0.08,
                                    width: g.body.width * 0.80, height: g.body.height * 0.50)).fill()

        drawLeg(hip: NSPoint(x: g.frontX.0, y: g.hipY), offset: phi)
        drawLeg(hip: NSPoint(x: g.frontX.1, y: g.hipY), offset: phi + .pi)

        drawHead(g, blink: false)
        cg.restoreGState()
    }

    private func drawSitting(frame: Int) {
        let g = geo
        let blink = (frame == 2)
        let tailWave = CGFloat(frame % 2) * 0.5

        let haunch = NSBezierPath(ovalIn: NSRect(x: 5.2, y: 5.6, width: 6.2, height: 6.0))
        tan.setFill(); haunch.fill()
        outline.setStroke(); haunch.lineWidth = 0.7; haunch.stroke()

        let body = NSBezierPath(ovalIn: NSRect(x: 8.6, y: 7.4, width: 13.5, height: 6.0))
        tan.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 9.6, y: 7.8, width: 9.4, height: 4.0)).fill()

        for x in [21.2, 23.6] {
            let leg = NSBezierPath()
            leg.move(to: NSPoint(x: x, y: 7.6))
            leg.line(to: NSPoint(x: x, y: 4.9))
            leg.lineWidth = 2.0
            leg.lineCapStyle = .round
            tan.setStroke()
            leg.stroke()
        }

        // 卷尾巴（摇动）
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: 5.6, y: 10.2))
        tail.curve(to: NSPoint(x: 4.4 + tailWave * 0.6, y: 13.2),
                   controlPoint1: NSPoint(x: 3.8, y: 11.0),
                   controlPoint2: NSPoint(x: 3.6, y: 12.6))
        tail.curve(to: NSPoint(x: 6.0 + tailWave * 0.5, y: 12.4),
                   controlPoint1: NSPoint(x: 5.2, y: 13.8),
                   controlPoint2: NSPoint(x: 6.3, y: 13.2))
        tail.lineWidth = 2.8
        tail.lineCapStyle = .round
        tan.setStroke()
        tail.stroke()

        drawHead(g, blink: blink)
    }

    private func drawHead(_ g: Geo, blink: Bool) {
        let r = g.headR
        let h = g.head
        let headPath = NSBezierPath(ovalIn: NSRect(x: h.x - r, y: h.y - r, width: r * 2, height: r * 2))
        tan.setFill(); headPath.fill()
        outline.setStroke(); headPath.lineWidth = 0.7; headPath.stroke()

        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.25, y: h.y - r * 0.55, width: r * 1.15, height: r * 0.85)).fill()

        for side: CGFloat in [-1, 1] {
            let ear = NSBezierPath()
            ear.move(to: NSPoint(x: h.x + side * r * 0.55, y: h.y + r * 0.55))
            ear.line(to: NSPoint(x: h.x + side * r * 0.95, y: h.y + r * 1.30))
            ear.line(to: NSPoint(x: h.x + side * r * 0.15, y: h.y + r * 0.90))
            ear.close()
            tan.setFill(); ear.fill()
            outline.setStroke(); ear.lineWidth = 0.6; ear.stroke()
        }

        if blink {
            outline.setStroke()
            for side: CGFloat in [-1, 1] {
                let eye = NSBezierPath()
                eye.move(to: NSPoint(x: h.x + side * r * 0.52, y: h.y + r * 0.15))
                eye.curve(to: NSPoint(x: h.x + side * r * 0.12, y: h.y + r * 0.15),
                          controlPoint1: NSPoint(x: h.x + side * r * 0.38, y: h.y + r * 0.35),
                          controlPoint2: NSPoint(x: h.x + side * r * 0.26, y: h.y + r * 0.35))
                eye.lineWidth = 0.5
                eye.lineCapStyle = .round
                eye.stroke()
            }
        } else {
            eye.setFill()
            let es: CGFloat = 0.9
            NSBezierPath(ovalIn: NSRect(x: h.x - r * 0.35, y: h.y + r * 0.12, width: es, height: es)).fill()
            NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.30, y: h.y + r * 0.12, width: es, height: es)).fill()
        }
        outline.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 1.05, y: h.y - r * 0.30, width: 0.8, height: 0.6)).fill()
    }

    private func drawLeg(hip: NSPoint, offset: Double) {
        let fx = hip.x + 3.4 * sin(offset)
        let lift = max(0, sin(offset + 0.7)) * 1.6
        let foot = NSPoint(x: fx, y: 4.3 - lift)
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

/// 兔子：白兔长耳（长身体、长耳朵、圆尾、蹦跳）。
struct RabbitPainter {
    private let white = NSColor(calibratedWhite: 0.96, alpha: 1)
    private let pink = NSColor(calibratedRed: 0.96, green: 0.66, blue: 0.70, alpha: 1)
    private let outline = NSColor(calibratedWhite: 0.14, alpha: 1)
    private let eye = NSColor(calibratedWhite: 0.12, alpha: 1)

    private var headC = NSPoint(x: 23.2, y: 10.6)
    private var headR: CGFloat = 3.4

    func runningFrames() -> [NSImage] {
        (0..<16).map { i in
            FrameRenderer.makeImage { drawRunning(frame: i) }
        }
    }

    func sittingFrames() -> [NSImage] {
        (0..<4).map { i in
            FrameRenderer.makeImage { drawSitting(frame: i) }
        }
    }

    private func drawRunning(frame: Int) {
        let phase = Double(frame % 8) / 8.0
        let stride = Double(frame / 8)
        let phi = phase * 2 * .pi
        let body = NSRect(x: 4.6, y: 6.2, width: 18.2, height: 6.4)
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        cg.translateBy(x: 0, y: CGFloat((0.6 - 0.15 * stride) * abs(sin(phi * 2))))

        // 圆尾
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: body.minX - 1.8, y: body.midY + 0.4, width: 2.6, height: 2.6)).fill()

        drawLeg(hip: NSPoint(x: body.minX + 2.6, y: body.minY + 1.0), offset: phi + .pi)
        drawLeg(hip: NSPoint(x: body.minX + 4.4, y: body.minY + 1.0), offset: phi)

        let bodyPath = NSBezierPath(ovalIn: body)
        white.setFill(); bodyPath.fill()
        outline.setStroke(); bodyPath.lineWidth = 0.7; bodyPath.stroke()

        drawLeg(hip: NSPoint(x: body.maxX - 3.4, y: body.minY + 1.0), offset: phi)
        drawLeg(hip: NSPoint(x: body.maxX - 1.6, y: body.minY + 1.0), offset: phi + .pi)

        drawHead(blink: false, earTilt: 0)
        cg.restoreGState()
    }

    private func drawSitting(frame: Int) {
        let blink = (frame == 2)
        let earTilt = CGFloat(frame % 2) * 0.5

        let haunch = NSBezierPath(ovalIn: NSRect(x: 5.6, y: 5.8, width: 5.6, height: 5.8))
        white.setFill(); haunch.fill()
        outline.setStroke(); haunch.lineWidth = 0.7; haunch.stroke()
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 4.0, y: 8.6, width: 2.8, height: 2.8)).fill()

        let body = NSBezierPath(ovalIn: NSRect(x: 8.8, y: 7.8, width: 12.6, height: 5.8))
        white.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()

        for x in [21.0, 23.2] {
            let leg = NSBezierPath()
            leg.move(to: NSPoint(x: x, y: 7.8))
            leg.line(to: NSPoint(x: x, y: 5.0))
            leg.lineWidth = 2.0
            leg.lineCapStyle = .round
            white.setStroke()
            leg.stroke()
        }

        drawHead(blink: blink, earTilt: earTilt)
    }

    private func drawHead(blink: Bool, earTilt: CGFloat) {
        let h = headC
        let r = headR

        // 长耳朵（先画在头后，向上竖起）
        for side: CGFloat in [-1, 1] {
            let ear = NSBezierPath(ovalIn: NSRect(x: h.x + side * r * 0.95 - 0.7 + earTilt,
                                                  y: h.y + r * 0.45,
                                                  width: 1.6, height: 5.2))
            white.setFill(); ear.fill()
            outline.setStroke(); ear.lineWidth = 0.6; ear.stroke()
            pink.setFill()
            NSBezierPath(ovalIn: NSRect(x: h.x + side * r * 0.95 - 0.38 + earTilt,
                                        y: h.y + r * 0.65,
                                        width: 0.8, height: 3.8)).fill()
        }

        let headPath = NSBezierPath(ovalIn: NSRect(x: h.x - r, y: h.y - r, width: r * 2, height: r * 2))
        white.setFill(); headPath.fill()
        outline.setStroke(); headPath.lineWidth = 0.7; headPath.stroke()

        if blink {
            outline.setStroke()
            for side: CGFloat in [-1, 1] {
                let e = NSBezierPath()
                e.move(to: NSPoint(x: h.x + side * r * 0.50, y: h.y + r * 0.10))
                e.curve(to: NSPoint(x: h.x + side * r * 0.08, y: h.y + r * 0.10),
                        controlPoint1: NSPoint(x: h.x + side * r * 0.36, y: h.y + r * 0.30),
                        controlPoint2: NSPoint(x: h.x + side * r * 0.22, y: h.y + r * 0.30))
                e.lineWidth = 0.5
                e.lineCapStyle = .round
                e.stroke()
            }
        } else {
            eye.setFill()
            let es: CGFloat = 0.85
            NSBezierPath(ovalIn: NSRect(x: h.x - r * 0.35, y: h.y + r * 0.10, width: es, height: es)).fill()
            NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.28, y: h.y + r * 0.10, width: es, height: es)).fill()
        }
        pink.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.85, y: h.y - r * 0.25, width: 0.8, height: 0.7)).fill()
    }

    private func drawLeg(hip: NSPoint, offset: Double) {
        let fx = hip.x + 3.2 * sin(offset)
        let lift = max(0, sin(offset + 0.7)) * 1.6
        let foot = NSPoint(x: fx, y: 4.3 - lift)
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

/// 熊猫：黑白圆滚滚（长身体、黑耳、黑眼圈、黑四肢）。
struct PandaPainter {
    private let white = NSColor(calibratedWhite: 0.96, alpha: 1)
    private let black = NSColor(calibratedWhite: 0.16, alpha: 1)
    private let outline = NSColor(calibratedWhite: 0.10, alpha: 1)

    private var headC = NSPoint(x: 23.4, y: 10.6)
    private var headR: CGFloat = 3.5

    func runningFrames() -> [NSImage] {
        (0..<16).map { i in
            FrameRenderer.makeImage { drawRunning(frame: i) }
        }
    }

    func sittingFrames() -> [NSImage] {
        (0..<4).map { i in
            FrameRenderer.makeImage { drawSitting(frame: i) }
        }
    }

    private func drawRunning(frame: Int) {
        let phase = Double(frame % 8) / 8.0
        let stride = Double(frame / 8)
        let phi = phase * 2 * .pi
        let body = NSRect(x: 4.4, y: 6.0, width: 18.6, height: 6.8)
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        cg.translateBy(x: 0, y: CGFloat((0.4 - 0.10 * stride) * abs(sin(phi * 2))))

        drawLeg(hip: NSPoint(x: body.minX + 2.6, y: body.minY + 1.0), offset: phi + .pi, color: black)
        drawLeg(hip: NSPoint(x: body.minX + 4.4, y: body.minY + 1.0), offset: phi, color: black)

        let bodyPath = NSBezierPath(ovalIn: body)
        white.setFill(); bodyPath.fill()
        outline.setStroke(); bodyPath.lineWidth = 0.7; bodyPath.stroke()

        drawLeg(hip: NSPoint(x: body.maxX - 3.2, y: body.minY + 1.0), offset: phi, color: black)
        drawLeg(hip: NSPoint(x: body.maxX - 1.4, y: body.minY + 1.0), offset: phi + .pi, color: black)

        drawHead(blink: false)
        cg.restoreGState()
    }

    private func drawSitting(frame: Int) {
        let blink = (frame == 2)
        let haunch = NSBezierPath(ovalIn: NSRect(x: 5.4, y: 5.8, width: 6.0, height: 6.0))
        white.setFill(); haunch.fill()
        outline.setStroke(); haunch.lineWidth = 0.7; haunch.stroke()
        let body = NSBezierPath(ovalIn: NSRect(x: 8.8, y: 7.6, width: 13.2, height: 6.2))
        white.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()
        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: 20.6, y: 6.4, width: 2.2, height: 3.4)).fill()
        NSBezierPath(ovalIn: NSRect(x: 22.8, y: 6.4, width: 2.2, height: 3.4)).fill()
        drawHead(blink: blink)
    }

    private func drawHead(blink: Bool) {
        let h = headC
        let r = headR

        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x - r * 1.25, y: h.y + r * 0.75, width: 1.7, height: 1.7)).fill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.55, y: h.y + r * 0.75, width: 1.7, height: 1.7)).fill()

        let headPath = NSBezierPath(ovalIn: NSRect(x: h.x - r, y: h.y - r, width: r * 2, height: r * 2))
        white.setFill(); headPath.fill()
        outline.setStroke(); headPath.lineWidth = 0.7; headPath.stroke()

        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x - r * 0.85, y: h.y - r * 0.05, width: r * 0.95, height: r * 1.05)).fill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.25, y: h.y - r * 0.05, width: r * 0.95, height: r * 1.05)).fill()
        if blink {
            white.setStroke()
            for x: CGFloat in [h.x - r * 0.40, h.x + r * 0.62] {
                let line = NSBezierPath()
                line.move(to: NSPoint(x: x - 0.4, y: h.y + r * 0.30))
                line.line(to: NSPoint(x: x + 0.4, y: h.y + r * 0.30))
                line.lineWidth = 0.5
                line.lineCapStyle = .round
                line.stroke()
            }
        } else {
            white.setFill()
            let es: CGFloat = 0.55
            NSBezierPath(ovalIn: NSRect(x: h.x - r * 0.40, y: h.y + r * 0.15, width: es, height: es)).fill()
            NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.62, y: h.y + r * 0.15, width: es, height: es)).fill()
        }
        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.75, y: h.y - r * 0.42, width: 0.9, height: 0.7)).fill()
    }

    private func drawLeg(hip: NSPoint, offset: Double, color: NSColor) {
        let fx = hip.x + 3.2 * sin(offset)
        let lift = max(0, sin(offset + 0.7)) * 1.6
        let foot = NSPoint(x: fx, y: 4.3 - lift)
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

/// 企鹅：黑背白肚橙嘴，左右摇摆走路（长形蛋身）。
struct PenguinPainter {
    private let black = NSColor(calibratedWhite: 0.22, alpha: 1)
    private let white = NSColor(calibratedWhite: 0.97, alpha: 1)
    private let orange = NSColor(calibratedRed: 0.96, green: 0.62, blue: 0.23, alpha: 1)
    private let outline = NSColor(calibratedWhite: 0.10, alpha: 1)

    func runningFrames() -> [NSImage] {
        (0..<16).map { i in
            FrameRenderer.makeImage { drawWaddle(frame: i) }
        }
    }

    func sittingFrames() -> [NSImage] {
        (0..<4).map { i in
            FrameRenderer.makeImage { drawStanding(frame: i) }
        }
    }

    private func drawWaddle(frame: Int) {
        let phase = Double(frame % 8) / 8.0
        let stride = Double(frame / 8)
        let phi = phase * 2 * .pi
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        let sway = (0.08 - 0.025 * stride) * sin(phi)
        cg.translateBy(x: 14, y: 8.0)
        cg.rotate(by: CGFloat(sway))
        cg.translateBy(x: -14, y: -8.0)

        orange.setStroke()
        for (x, off) in [(7.0, phi), (20.0, phi + .pi)] {
            let foot = NSBezierPath()
            foot.move(to: NSPoint(x: x, y: 4.9))
            foot.line(to: NSPoint(x: x + 1.5, y: 4.2 - CGFloat(max(0, sin(off + 0.6))) * 1.0))
            foot.lineWidth = 1.8
            foot.lineCapStyle = .round
            foot.stroke()
        }

        // 长形蛋身
        let body = NSBezierPath(ovalIn: NSRect(x: 4.2, y: 5.6, width: 20.2, height: 8.8))
        black.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 6.4, y: 6.2, width: 12.4, height: 6.4)).fill()

        // 鳍
        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: 2.6, y: 7.4, width: 2.2, height: 5.2)).fill()
        NSBezierPath(ovalIn: NSRect(x: 24.8, y: 7.4, width: 2.2, height: 5.2)).fill()

        // 橙嘴
        orange.setFill()
        let beak = NSBezierPath()
        beak.move(to: NSPoint(x: 23.6, y: 9.8))
        beak.line(to: NSPoint(x: 26.2, y: 9.3))
        beak.line(to: NSPoint(x: 23.6, y: 8.8))
        beak.close()
        beak.fill()

        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 22.4, y: 10.0, width: 1.3, height: 1.5)).fill()
        cg.restoreGState()
    }

    private func drawStanding(frame: Int) {
        let blink = (frame == 2)
        let sway = CGFloat(frame % 2) * 0.25

        let body = NSBezierPath(ovalIn: NSRect(x: 4.2, y: 5.2, width: 20.2, height: 9.6))
        black.setFill(); body.fill()
        outline.setStroke(); body.lineWidth = 0.7; body.stroke()
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 6.4, y: 5.8, width: 12.4, height: 7.0)).fill()

        black.setFill()
        NSBezierPath(ovalIn: NSRect(x: 2.4 - sway, y: 6.6, width: 2.4, height: 6.0)).fill()
        NSBezierPath(ovalIn: NSRect(x: 25.0 + sway, y: 6.6, width: 2.4, height: 6.0)).fill()

        orange.setFill()
        let beak = NSBezierPath()
        beak.move(to: NSPoint(x: 23.6, y: 9.6))
        beak.line(to: NSPoint(x: 26.2, y: 9.1))
        beak.line(to: NSPoint(x: 23.6, y: 8.6))
        beak.close()
        beak.fill()
        NSBezierPath(ovalIn: NSRect(x: 6.6, y: 4.8, width: 2.8, height: 1.2)).fill()
        NSBezierPath(ovalIn: NSRect(x: 19.6, y: 4.8, width: 2.8, height: 1.2)).fill()

        if blink {
            white.setStroke()
            let line = NSBezierPath()
            line.move(to: NSPoint(x: 22.5, y: 10.4))
            line.line(to: NSPoint(x: 23.6, y: 10.4))
            line.lineWidth = 0.5
            line.lineCapStyle = .round
            line.stroke()
        } else {
            white.setFill()
            NSBezierPath(ovalIn: NSRect(x: 22.4, y: 9.7, width: 1.3, height: 1.5)).fill()
        }
    }
}
