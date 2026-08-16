import AppKit

/// 10 种高人气猫品种（萌系卡通化）。
enum CatBreed: String, CaseIterable {
    case ragdoll, british, american, siamese, persian, mainecoon, fold, sphynx, bengal, golden

    var displayName: String {
        switch self {
        case .ragdoll:   return "布偶猫"
        case .british:   return "英短蓝猫"
        case .american:  return "美短虎斑"
        case .siamese:   return "暹罗猫"
        case .persian:   return "波斯猫"
        case .mainecoon: return "缅因猫"
        case .fold:      return "折耳猫"
        case .sphynx:    return "斯芬克斯"
        case .bengal:    return "豹猫"
        case .golden:    return "金渐层"
        }
    }
}

/// 品种外观配置：配色、花纹、耳朵与体型。
struct BreedConfig {
    enum EarStyle { case standard, fold, tufted, big, tiny }

    var body: NSColor
    var outline: NSColor = NSColor(calibratedWhite: 0.12, alpha: 1)
    var eye: NSColor
    var earInner: NSColor = NSColor(calibratedRed: 0.96, green: 0.66, blue: 0.69, alpha: 1)
    var mask: NSColor?       // 重点色（暹罗/布偶：面部+耳朵+尾巴）
    var belly: NSColor?      // 浅肚皮（金渐层）
    var stripes: NSColor?    // 条纹（美短/缅因）
    var spots: NSColor?      // 斑点（豹猫）
    var headScale: CGFloat = 1.0
    var bodyW: CGFloat = 1.0 // 蓬松度（宽）
    var bodyH: CGFloat = 1.0 // 蓬松度（高）
    var tailWidth: CGFloat = 2.1
    var earStyle: EarStyle = .standard
    var ruff = false         // 围脖蓬毛
}

extension CatBreed {
    var config: BreedConfig {
        switch self {
        case .ragdoll:
            return BreedConfig(body: NSColor(calibratedRed: 0.95, green: 0.90, blue: 0.83, alpha: 1),
                               eye: NSColor(calibratedRed: 0.30, green: 0.52, blue: 0.84, alpha: 1),
                               mask: NSColor(calibratedRed: 0.29, green: 0.21, blue: 0.16, alpha: 1),
                               headScale: 1.06, bodyW: 1.08, tailWidth: 2.7, ruff: true)
        case .british:
            return BreedConfig(body: NSColor(calibratedRed: 0.55, green: 0.62, blue: 0.68, alpha: 1),
                               eye: NSColor(calibratedRed: 0.80, green: 0.55, blue: 0.24, alpha: 1),
                               headScale: 1.16, bodyW: 1.10, tailWidth: 2.4)
        case .american:
            return BreedConfig(body: NSColor(calibratedRed: 0.74, green: 0.77, blue: 0.80, alpha: 1),
                               eye: NSColor(calibratedRed: 0.74, green: 0.55, blue: 0.25, alpha: 1),
                               stripes: NSColor(calibratedRed: 0.27, green: 0.29, blue: 0.32, alpha: 1))
        case .siamese:
            return BreedConfig(body: NSColor(calibratedRed: 0.95, green: 0.91, blue: 0.84, alpha: 1),
                               eye: NSColor(calibratedRed: 0.25, green: 0.45, blue: 0.83, alpha: 1),
                               mask: NSColor(calibratedRed: 0.25, green: 0.19, blue: 0.16, alpha: 1),
                               headScale: 0.97, bodyW: 0.94, tailWidth: 1.9)
        case .persian:
            return BreedConfig(body: NSColor(calibratedRed: 0.97, green: 0.95, blue: 0.92, alpha: 1),
                               eye: NSColor(calibratedRed: 0.80, green: 0.55, blue: 0.24, alpha: 1),
                               headScale: 1.20, bodyW: 1.26, bodyH: 1.12, tailWidth: 2.9,
                               earStyle: .tiny, ruff: true)
        case .mainecoon:
            return BreedConfig(body: NSColor(calibratedRed: 0.55, green: 0.42, blue: 0.29, alpha: 1),
                               eye: NSColor(calibratedRed: 0.74, green: 0.55, blue: 0.25, alpha: 1),
                               stripes: NSColor(calibratedRed: 0.30, green: 0.21, blue: 0.14, alpha: 1),
                               headScale: 1.10, bodyW: 1.20, tailWidth: 2.9,
                               earStyle: .tufted, ruff: true)
        case .fold:
            return BreedConfig(body: NSColor(calibratedRed: 0.61, green: 0.66, blue: 0.70, alpha: 1),
                               eye: NSColor(calibratedRed: 0.80, green: 0.55, blue: 0.24, alpha: 1),
                               headScale: 1.10, bodyW: 1.05, earStyle: .fold)
        case .sphynx:
            return BreedConfig(body: NSColor(calibratedRed: 0.92, green: 0.74, blue: 0.65, alpha: 1),
                               eye: NSColor(calibratedRed: 0.85, green: 0.62, blue: 0.30, alpha: 1),
                               headScale: 0.95, bodyW: 0.90, bodyH: 0.95, tailWidth: 1.4,
                               earStyle: .big)
        case .bengal:
            return BreedConfig(body: NSColor(calibratedRed: 0.86, green: 0.64, blue: 0.37, alpha: 1),
                               eye: NSColor(calibratedRed: 0.38, green: 0.62, blue: 0.35, alpha: 1),
                               spots: NSColor(calibratedRed: 0.30, green: 0.20, blue: 0.13, alpha: 1),
                               bodyW: 0.98, tailWidth: 2.0)
        case .golden:
            return BreedConfig(body: NSColor(calibratedRed: 0.90, green: 0.77, blue: 0.49, alpha: 1),
                               eye: NSColor(calibratedRed: 0.38, green: 0.62, blue: 0.35, alpha: 1),
                               belly: NSColor(calibratedRed: 0.96, green: 0.90, blue: 0.75, alpha: 1),
                               headScale: 1.08, bodyW: 1.05)
        }
    }
}

/// 萌系卡通猫绘制器：10 种品种，大头圆眼、高光眼神、粉鼻腮红。
struct CatPainter {
    let breed: CatBreed

    private var cfg: BreedConfig { breed.config }

    // MARK: - 几何（30×18 宽扁画布，参考 RunCatNeo 精灵比例）

    private struct Geo {
        var body: NSRect
        var head: NSPoint
        var headR: CGFloat
        var hipY: CGFloat
        var footY: CGFloat
        var backX: (CGFloat, CGFloat)
        var frontX: (CGFloat, CGFloat)
        var tailAmp: CGFloat
    }

    private struct SitGeo {
        var haunch: NSRect
        var body: NSRect
        var frontXs: [CGFloat]
        var footY: CGFloat
    }

    /// 头部基准：大头萌系（相对 30×18 画布）
    private func headRadius() -> CGFloat { 3.9 * cfg.headScale }

    private func headCenter() -> NSPoint {
        let r = headRadius()
        return NSPoint(x: 23.8 + (r - 3.9) * 0.4, y: 10.4)
    }

    private func runningGeo() -> Geo {
        let r = headRadius()
        let head = headCenter()
        let bw = cfg.bodyW, bh = cfg.bodyH
        // 长身体、低重心：贴近地面，横向舒展
        let w = 19.0 * bw, h = 6.6 * bh
        let body = NSRect(x: 4.0 - (w - 19.0) / 2, y: 6.0 - (h - 6.6) / 2, width: w, height: h)
        return Geo(body: body, head: head, headR: r,
                   hipY: body.minY + 0.6, footY: 4.3,
                   backX: (body.minX + 3.0, body.minX + 5.0),
                   frontX: (body.maxX - 3.4, body.maxX - 1.6),
                   tailAmp: cfg.tailWidth > 2.4 ? 2.0 : 2.4)
    }

    private func sittingGeo() -> (SitGeo, Geo) {
        let g = runningGeo()
        let bw = cfg.bodyW, bh = cfg.bodyH
        let hw = 6.2 * bw, hh = 6.0 * bh
        let haunch = NSRect(x: 5.2 - (hw - 6.2) / 2, y: 5.6 - (hh - 6.0) / 2, width: hw, height: hh)
        let bw2 = 13.5 * bw, bh2 = 6.0 * bh
        let body = NSRect(x: 8.6 - (bw2 - 13.5) / 2, y: 7.4 - (bh2 - 6.0) / 2, width: bw2, height: bh2)
        return (SitGeo(haunch: haunch, body: body,
                       frontXs: [body.maxX - 2.3, body.maxX - 0.1], footY: 4.9), g)
    }

    // MARK: - 帧生成

    /// 奔跑：16 帧（两个步伐周期，两拍略有差异，循环更长更自然）。
    func runningFrames() -> [NSImage] {
        (0..<16).map { i in
            FrameRenderer.makeImage { drawRunning(frame: i) }
        }
    }

    /// 端坐：4 帧（摇尾 + 眨眼）。
    func sittingFrames() -> [NSImage] {
        (0..<4).map { i in
            let tailUp = (i % 2 == 0)
            let blink = (i == 2)
            return FrameRenderer.makeImage { drawSitting(tailUp: tailUp, blink: blink) }
        }
    }

    /// 睡觉姿势：4 帧（呼吸起伏 + Zzz 漂移）。
    func sleepingFrames() -> [NSImage] {
        (0..<4).map { i in
            FrameRenderer.makeImage { drawSleeping(frame: i) }
        }
    }

    func appIcon() -> NSImage {
        FrameRenderer.makeImage(ptW: 512, ptH: 512, pixelScale: 1) {
            let cg = NSGraphicsContext.current!.cgContext
            // 将 30×18 的坐姿居中放入方形画布
            let s: CGFloat = 512 / 30
            cg.translateBy(x: 0, y: (512 - 18 * s) / 2)
            cg.scaleBy(x: s, y: s)
            let bg = NSBezierPath(roundedRect: NSRect(x: 0.8, y: 0.8, width: 28.4, height: 16.4),
                                  xRadius: 4.6, yRadius: 4.6)
            let top = cfg.body.blended(withFraction: 0.35, of: .white) ?? cfg.body
            let bottom = cfg.body.blended(withFraction: 0.25, of: .black) ?? cfg.body
            let grad = NSGradient(starting: top, ending: bottom) ?? NSGradient(colors: [top, bottom])!
            grad.draw(in: bg, angle: -90)
            drawSitting(tailUp: true, blink: false)
        }
    }

    // MARK: - 睡觉姿态

    private func drawSleeping(frame: Int) {
        let bodyC = cfg.body
        let outlineC = cfg.outline
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        // 呼吸起伏（4 帧：吸-呼-吸-微呼）
        let breath: [CGFloat] = [1.0, 1.05, 1.0, 1.035]
        let s = breath[frame % breath.count]
        cg.translateBy(x: 14, y: 8.0)
        cg.scaleBy(x: s, y: s)
        cg.translateBy(x: -14, y: -8.0)

        // 尾巴绕到身前
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: 5.4, y: 7.4))
        tail.curve(to: NSPoint(x: 9.0, y: 4.4),
                   controlPoint1: NSPoint(x: 3.4, y: 6.2),
                   controlPoint2: NSPoint(x: 5.8, y: 3.6))
        tail.lineWidth = cfg.tailWidth
        tail.lineCapStyle = .round
        (cfg.mask ?? bodyC).setStroke()
        tail.stroke()

        // 身体（蜷成一团，长形）
        let body = NSBezierPath(ovalIn: NSRect(x: 4.0, y: 3.8, width: 20.0, height: 8.8))
        bodyC.setFill(); body.fill()
        outlineC.setStroke(); body.lineWidth = 0.7; body.stroke()

        // 头（贴在右侧）
        let headC = NSPoint(x: 21.4, y: 8.6)
        let r: CGFloat = 3.3
        let head = NSBezierPath(ovalIn: NSRect(x: headC.x - r, y: headC.y - r, width: r * 2, height: r * 2))
        bodyC.setFill(); head.fill()
        outlineC.setStroke(); head.lineWidth = 0.7; head.stroke()

        // 耳朵（小三角）
        for side: CGFloat in [-1, 1] {
            let ear = NSBezierPath()
            ear.move(to: NSPoint(x: headC.x + side * r * 0.5, y: headC.y + r * 0.55))
            ear.line(to: NSPoint(x: headC.x + side * r * 0.75, y: headC.y + r * 1.15))
            ear.line(to: NSPoint(x: headC.x + side * r * 0.15, y: headC.y + r * 0.8))
            ear.close()
            bodyC.setFill(); ear.fill()
            outlineC.setStroke(); ear.lineWidth = 0.6; ear.stroke()
        }

        // 闭眼（向下弧线）
        outlineC.setStroke()
        for side: CGFloat in [-1, 1] {
            let eye = NSBezierPath()
            eye.move(to: NSPoint(x: headC.x + side * r * 0.62, y: headC.y + r * 0.12))
            eye.curve(to: NSPoint(x: headC.x + side * r * 0.05, y: headC.y + r * 0.12),
                      controlPoint1: NSPoint(x: headC.x + side * r * 0.45, y: headC.y + r * 0.32),
                      controlPoint2: NSPoint(x: headC.x + side * r * 0.22, y: headC.y + r * 0.32))
            eye.lineWidth = 0.5
            eye.stroke()
        }

        // Zzz（随帧漂移上浮）
        outlineC.withAlphaComponent(0.5).setStroke()
        let drift = CGFloat(frame % 4) * 0.4
        let zx = headC.x + 2.0
        let zy = headC.y + r * 1.2 + drift
        let z = NSBezierPath()
        z.move(to: NSPoint(x: zx, y: zy + 1.6))
        z.line(to: NSPoint(x: zx + 2.2, y: zy))
        z.line(to: NSPoint(x: zx, y: zy))
        z.lineWidth = 0.6
        z.lineCapStyle = .round
        z.lineJoinStyle = .round
        z.stroke()
        // 第二个 z（更小更靠上）
        if frame % 4 >= 2 {
            let z2 = NSBezierPath()
            z2.move(to: NSPoint(x: zx + 1.5, y: zy + 2.6))
            z2.line(to: NSPoint(x: zx + 3.3, y: zy + 1.6))
            z2.line(to: NSPoint(x: zx + 1.5, y: zy + 1.6))
            z2.lineWidth = 0.5
            z2.lineCapStyle = .round
            z2.lineJoinStyle = .round
            z2.stroke()
        }

        cg.restoreGState()
    }

    // MARK: - 奔跑姿态

    /// frame: 0..<16；每 8 帧一个步伐周期，两拍尾部/弹跳略有差异。
    private func drawRunning(frame: Int) {
        let g = runningGeo()
        let phase = Double(frame % 8) / 8.0
        let stride = Double(frame / 8)
        let phi = phase * 2 * .pi
        let tailColor = cfg.mask ?? cfg.body

        // 奔跑弹跳：两拍幅度略不同，循环更长更自然
        let bounce = (0.5 - 0.12 * stride) * abs(sin(phi * 2))
        let tailAmp = g.tailAmp * (1 + 0.18 * stride)
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        cg.translateBy(x: 0, y: bounce)

        // 尾巴
        let tailStart = NSPoint(x: g.body.minX + 0.3, y: g.body.midY + 0.7)
        let tailTip = NSPoint(x: g.body.minX - 2.6,
                              y: g.body.midY + 0.5 + tailAmp * sin(phi + 1.3 + 0.7 * stride))
        let tail = NSBezierPath()
        tail.move(to: tailStart)
        tail.curve(to: tailTip,
                   controlPoint1: NSPoint(x: g.body.minX - 0.9, y: g.body.midY + 2.4),
                   controlPoint2: NSPoint(x: g.body.minX - 3.4, y: g.body.midY + 2.8))
        tail.lineWidth = cfg.tailWidth
        tail.lineCapStyle = .round
        tailColor.setStroke()
        tail.stroke()

        // 后腿
        drawLeg(hip: NSPoint(x: g.backX.0, y: g.hipY), offset: phi + .pi)
        drawLeg(hip: NSPoint(x: g.backX.1, y: g.hipY), offset: phi)

        // 身体
        let bodyPath = NSBezierPath(ovalIn: g.body)
        cfg.body.setFill(); bodyPath.fill()
        drawBelly(g.body)
        drawBodyStripes(g.body)
        drawBodySpots(g.body)
        cfg.outline.setStroke(); bodyPath.lineWidth = 0.7; bodyPath.stroke()

        // 前腿
        drawLeg(hip: NSPoint(x: g.frontX.0, y: g.hipY), offset: phi)
        drawLeg(hip: NSPoint(x: g.frontX.1, y: g.hipY), offset: phi + .pi)

        // 围脖
        if cfg.ruff { drawRuff(g) }

        // 头
        drawHead(g)

        // 耳朵
        drawEars(g)

        // 脸（眼睛/鼻子/嘴/腮红/胡须）
        drawFace(g)

        cg.restoreGState()
    }

    // MARK: - 端坐姿态

    private func drawSitting(tailUp: Bool, blink: Bool) {
        let (s, g) = sittingGeo()
        let tailColor = cfg.mask ?? cfg.body

        // 尾巴绕到身前
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: s.haunch.minX + 0.4, y: 11.6))
        tail.curve(to: NSPoint(x: s.haunch.minX + 0.8, y: tailUp ? 7.8 : 5.8),
                   controlPoint1: NSPoint(x: s.haunch.minX - 2.8, y: 10.2),
                   controlPoint2: NSPoint(x: s.haunch.minX - 2.8, y: tailUp ? 8.8 : 6.4))
        tail.lineWidth = cfg.tailWidth
        tail.lineCapStyle = .round
        tailColor.setStroke()
        tail.stroke()

        // 后臀
        let haunchPath = NSBezierPath(ovalIn: s.haunch)
        cfg.body.setFill(); haunchPath.fill()
        cfg.outline.setStroke(); haunchPath.lineWidth = 0.7; haunchPath.stroke()

        // 身体
        let bodyPath = NSBezierPath(ovalIn: s.body)
        cfg.body.setFill(); bodyPath.fill()
        drawBelly(s.body)
        drawBodyStripes(s.body)
        drawBodySpots(s.body)
        cfg.outline.setStroke(); bodyPath.lineWidth = 0.7; bodyPath.stroke()

        // 前腿
        for x in s.frontXs {
            let leg = NSBezierPath()
            leg.move(to: NSPoint(x: x, y: s.body.minY))
            leg.line(to: NSPoint(x: x, y: s.footY))
            leg.lineWidth = 2.0
            leg.lineCapStyle = .round
            cfg.body.setStroke()
            leg.stroke()
        }

        // 围脖
        if cfg.ruff { drawRuff(g) }

        // 头 / 耳朵 / 脸
        drawHead(g)
        drawEars(g)
        drawFace(g, blink: blink)
    }

    // MARK: - 头部与五官

    private func drawHead(_ g: Geo) {
        let headRect = NSRect(x: g.head.x - g.headR, y: g.head.y - g.headR,
                              width: g.headR * 2, height: g.headR * 2)
        let headPath = NSBezierPath(ovalIn: headRect)
        cfg.body.setFill(); headPath.fill()
        drawHeadMask(g)          // 重点色面罩（暹罗/布偶）
        drawHeadStripes(g)       // 头顶"M"纹（美短/缅因）
        cfg.outline.setStroke(); headPath.lineWidth = 0.7; headPath.stroke()
    }

    private func drawEars(_ g: Geo) {
        let earColor = cfg.mask ?? cfg.body
        switch cfg.earStyle {
        case .standard, .big, .tiny:
            let s: CGFloat = cfg.earStyle == .big ? 1.35 : (cfg.earStyle == .tiny ? 0.6 : 1.0)
            drawStandEar(g, side: -1, scale: s, color: earColor)
            drawStandEar(g, side: 1, scale: s, color: earColor)
        case .tufted:
            drawStandEar(g, side: -1, scale: 1.0, color: earColor)
            drawStandEar(g, side: 1, scale: 1.0, color: earColor)
            drawTufts(g)
        case .fold:
            drawFoldEar(g, side: -1, color: earColor)
            drawFoldEar(g, side: 1, color: earColor)
        }
    }

    private func drawStandEar(_ g: Geo, side: CGFloat, scale: CGFloat, color: NSColor) {
        let r = g.headR * scale
        let dx1 = side * 0.72, dy1: CGFloat = 0.55
        let dx2 = side * 0.95, dy2: CGFloat = 1.30
        let dx3 = side * 0.18, dy3: CGFloat = 0.85
        let ear = NSBezierPath()
        ear.move(to: NSPoint(x: g.head.x + r * dx1, y: g.head.y + r * dy1))
        ear.line(to: NSPoint(x: g.head.x + r * dx2, y: g.head.y + r * dy2))
        ear.line(to: NSPoint(x: g.head.x + r * dx3, y: g.head.y + r * dy3))
        ear.close()
        color.setFill(); ear.fill()
        cfg.outline.setStroke(); ear.lineWidth = 0.7; ear.stroke()
        // 粉色内耳（近侧）
        if side > 0 {
            cfg.earInner.setFill()
            let inner = NSBezierPath()
            inner.move(to: NSPoint(x: g.head.x + r * 0.30, y: g.head.y + r * 0.78))
            inner.line(to: NSPoint(x: g.head.x + r * 0.62, y: g.head.y + r * 1.08))
            inner.line(to: NSPoint(x: g.head.x + r * 0.55, y: g.head.y + r * 0.80))
            inner.close()
            inner.fill()
        }
    }

    private func drawFoldEar(_ g: Geo, side: CGFloat, color: NSColor) {
        let r = g.headR
        let flap = NSBezierPath()
        let baseX = g.head.x + side * r * 0.55
        let baseY = g.head.y + r * 0.72
        let tipX = g.head.x + side * r * (side > 0 ? 0.95 : 0.15)
        let tipY = g.head.y + r * 0.42
        flap.move(to: NSPoint(x: baseX, y: baseY))
        flap.curve(to: NSPoint(x: tipX, y: tipY),
                   controlPoint1: NSPoint(x: g.head.x + side * r * 0.60, y: g.head.y + r * 0.45),
                   controlPoint2: NSPoint(x: g.head.x + side * r * 0.78, y: g.head.y + r * 0.40))
        flap.curve(to: NSPoint(x: baseX, y: baseY),
                   controlPoint1: NSPoint(x: g.head.x + side * r * 0.50, y: g.head.y + r * 0.60),
                   controlPoint2: NSPoint(x: g.head.x + side * r * 0.40, y: g.head.y + r * 0.68))
        flap.close()
        color.setFill(); flap.fill()
        cfg.outline.setStroke(); flap.lineWidth = 0.6; flap.stroke()
    }

    private func drawTufts(_ g: Geo) {
        // 缅因猫耳尖簇毛
        cfg.outline.setStroke()
        let paths: [(NSPoint, NSPoint)] = [
            (NSPoint(x: g.head.x - g.headR * 0.95, y: g.head.y + g.headR * 1.30),
             NSPoint(x: g.head.x - g.headR * 1.20, y: g.head.y + g.headR * 1.55)),
            (NSPoint(x: g.head.x - g.headR * 0.85, y: g.head.y + g.headR * 1.38),
             NSPoint(x: g.head.x - g.headR * 1.02, y: g.head.y + g.headR * 1.62)),
            (NSPoint(x: g.head.x + g.headR * 0.95, y: g.head.y + g.headR * 1.30),
             NSPoint(x: g.head.x + g.headR * 1.20, y: g.head.y + g.headR * 1.55)),
            (NSPoint(x: g.head.x + g.headR * 0.85, y: g.head.y + g.headR * 1.38),
             NSPoint(x: g.head.x + g.headR * 1.02, y: g.head.y + g.headR * 1.62)),
        ]
        for (a, b) in paths {
            let line = NSBezierPath()
            line.move(to: a)
            line.line(to: b)
            line.lineWidth = 0.6
            line.lineCapStyle = .round
            line.stroke()
        }
    }

    private func drawFace(_ g: Geo, blink: Bool = false) {
        let r = g.headR
        let h = g.head

        if blink {
            // 闭眼：向下弧线
            cfg.outline.setStroke()
            for side: CGFloat in [-1, 1] {
                let eye = NSBezierPath()
                eye.move(to: NSPoint(x: h.x + side * r * 0.55, y: h.y + r * 0.12))
                eye.curve(to: NSPoint(x: h.x + side * r * 0.10, y: h.y + r * 0.12),
                          controlPoint1: NSPoint(x: h.x + side * r * 0.40, y: h.y + r * 0.34),
                          controlPoint2: NSPoint(x: h.x + side * r * 0.25, y: h.y + r * 0.34))
                eye.lineWidth = 0.5
                eye.lineCapStyle = .round
                eye.stroke()
            }
        } else {
            // 眼睛：大圆眼 + 高光
            let eyeW = r * 0.60, eyeH = r * 0.72
            let leftC = NSPoint(x: h.x - r * 0.36, y: h.y + r * 0.10)
            let rightC = NSPoint(x: h.x + r * 0.30, y: h.y + r * 0.10)
            for c in [leftC, rightC] {
                let eye = NSBezierPath(ovalIn: NSRect(x: c.x - eyeW / 2, y: c.y - eyeH / 2,
                                                      width: eyeW, height: eyeH))
                cfg.eye.setFill(); eye.fill()
                cfg.outline.setStroke(); eye.lineWidth = 0.4; eye.stroke()
                NSColor.white.setFill()
                NSBezierPath(ovalIn: NSRect(x: c.x - eyeW * 0.10, y: c.y + eyeH * 0.14,
                                            width: eyeW * 0.34, height: eyeH * 0.30)).fill()
            }
        }

        // 粉色小鼻子
        let noseC = NSPoint(x: h.x + r * 0.50, y: h.y - r * 0.16)
        let nose = NSBezierPath()
        nose.move(to: NSPoint(x: noseC.x - r * 0.11, y: noseC.y - r * 0.05))
        nose.line(to: NSPoint(x: noseC.x, y: noseC.y + r * 0.10))
        nose.line(to: NSPoint(x: noseC.x + r * 0.11, y: noseC.y - r * 0.05))
        nose.close()
        cfg.earInner.setFill(); nose.fill()

        // 微笑小嘴
        cfg.outline.setStroke()
        let mouth = NSBezierPath()
        mouth.move(to: NSPoint(x: noseC.x - r * 0.10, y: noseC.y - r * 0.08))
        mouth.curve(to: NSPoint(x: noseC.x + r * 0.10, y: noseC.y - r * 0.08),
                    controlPoint1: NSPoint(x: noseC.x, y: noseC.y - r * 0.17),
                    controlPoint2: NSPoint(x: noseC.x, y: noseC.y - r * 0.17))
        mouth.lineWidth = 0.35
        mouth.stroke()

        // 腮红
        let blush = NSColor(calibratedRed: 0.98, green: 0.55, blue: 0.60, alpha: 0.30)
        blush.setFill()
        NSBezierPath(ovalIn: NSRect(x: h.x + r * 0.12, y: h.y - r * 0.40,
                                    width: r * 0.55, height: r * 0.30)).fill()
        NSBezierPath(ovalIn: NSRect(x: h.x - r * 0.70, y: h.y - r * 0.40,
                                    width: r * 0.55, height: r * 0.30)).fill()

        // 胡须
        cfg.outline.withAlphaComponent(0.45).setStroke()
        for dy in [0.0, 0.14] {
            let whisker = NSBezierPath()
            whisker.move(to: NSPoint(x: noseC.x + r * 0.05, y: noseC.y - r * 0.10 + CGFloat(dy) * r))
            whisker.line(to: NSPoint(x: noseC.x + r * 0.65, y: noseC.y - r * 0.02 + CGFloat(dy) * r))
            whisker.lineWidth = 0.3
            whisker.lineCapStyle = .round
            whisker.stroke()
        }
    }

    // MARK: - 花纹装饰

    private func drawBelly(_ body: NSRect) {
        guard let belly = cfg.belly else { return }
        belly.setFill()
        NSBezierPath(ovalIn: NSRect(x: body.midX - body.width * 0.42, y: body.minY + body.height * 0.08,
                                    width: body.width * 0.84, height: body.height * 0.55)).fill()
    }

    private func drawBodyStripes(_ body: NSRect) {
        guard let stripes = cfg.stripes else { return }
        stripes.setStroke()
        for x in [body.minX + 2.6, body.minX + 4.8, body.minX + 7.0] {
            let p = NSBezierPath()
            p.move(to: NSPoint(x: x, y: body.maxY - 1.0))
            p.curve(to: NSPoint(x: x, y: body.maxY - 3.3),
                    controlPoint1: NSPoint(x: x + 0.35, y: body.maxY - 1.0),
                    controlPoint2: NSPoint(x: x + 0.35, y: body.maxY - 3.3))
            p.lineWidth = 0.9
            p.lineCapStyle = .round
            p.stroke()
        }
    }

    private func drawHeadStripes(_ g: Geo) {
        guard let stripes = cfg.stripes else { return }
        stripes.setStroke()
        for dx in [-1.2, 0.0, 1.2] {
            let p = NSBezierPath()
            p.move(to: NSPoint(x: g.head.x + dx, y: g.head.y + g.headR * 0.72))
            p.curve(to: NSPoint(x: g.head.x + dx * 0.6, y: g.head.y + g.headR * 0.30),
                    controlPoint1: NSPoint(x: g.head.x + dx + (dx >= 0 ? 0.35 : -0.35), y: g.head.y + g.headR * 0.72),
                    controlPoint2: NSPoint(x: g.head.x + dx * 0.6 + (dx >= 0 ? 0.35 : -0.35), y: g.head.y + g.headR * 0.30))
            p.lineWidth = 0.8
            p.lineCapStyle = .round
            p.stroke()
        }
    }

    private func drawBodySpots(_ body: NSRect) {
        guard let spots = cfg.spots else { return }
        spots.setFill()
        // 豹猫玫瑰纹：实心点 + 空心圈
        NSBezierPath(ovalIn: NSRect(x: body.midX - 1.1, y: body.maxY - 2.2, width: 0.9, height: 0.9)).fill()
        NSBezierPath(ovalIn: NSRect(x: body.minX + 2.2, y: body.midY - 0.4, width: 0.9, height: 0.9)).fill()
        NSBezierPath(ovalIn: NSRect(x: body.maxX - 3.6, y: body.midY + 0.4, width: 0.9, height: 0.9)).fill()
        let ring = NSBezierPath(ovalIn: NSRect(x: body.maxX - 4.4, y: body.minY + 1.4, width: 1.5, height: 1.5))
        spots.setStroke(); ring.lineWidth = 0.5; ring.stroke()
    }

    private func drawHeadMask(_ g: Geo) {
        guard let mask = cfg.mask else { return }
        mask.setFill()
        // 重点色面罩：脸的前部
        NSBezierPath(ovalIn: NSRect(x: g.head.x + g.headR * 0.15, y: g.head.y - g.headR * 0.45,
                                    width: g.headR * 1.05, height: g.headR * 1.05)).fill()
    }

    private func drawRuff(_ g: Geo) {
        cfg.body.setFill()
        let ruff = NSBezierPath(ovalIn: NSRect(x: g.head.x - g.headR * 1.15, y: g.head.y - g.headR * 0.85,
                                               width: g.headR * 1.5, height: g.headR * 1.15))
        ruff.fill()
        cfg.outline.setStroke(); ruff.lineWidth = 0.6; ruff.stroke()
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
        cfg.body.setStroke()
        leg.stroke()
    }
}
