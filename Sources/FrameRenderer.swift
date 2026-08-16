import AppKit

/// 通用帧渲染器：22×22 点坐标系，按目标尺寸缩放（2x 像素）。
enum FrameRenderer {
    static func makeImage(ptSize: CGFloat = 22, pixelScale: CGFloat = 2, _ draw: () -> Void) -> NSImage {
        let px = Int(ptSize * pixelScale)
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        let image = NSImage(size: NSSize(width: ptSize, height: ptSize))
        image.addRepresentation(rep)
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return image }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        let s = pixelScale * ptSize / 22.0
        ctx.cgContext.scaleBy(x: s, y: s)
        draw()
        NSGraphicsContext.restoreGraphicsState()
        return image
    }

    /// 带缩放动画的绘制包装（如奔跑弹跳）。
    static func withBounce(_ amount: Double, phase: Double, _ draw: () -> Void) {
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        cg.translateBy(x: 0, y: CGFloat(amount * abs(sin(phase * 4 * .pi))))
        draw()
        cg.restoreGState()
    }
}
