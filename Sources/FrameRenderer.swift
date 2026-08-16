import AppKit

/// 通用帧渲染器：30×18 宽扁画布（与 RunCatNeo 精灵比例一致），2x 像素。
enum FrameRenderer {
    static func makeImage(ptW: CGFloat = 30, ptH: CGFloat = 18,
                          pixelScale: CGFloat = 2, _ draw: () -> Void) -> NSImage {
        let pw = Int(ptW * pixelScale)
        let ph = Int(ptH * pixelScale)
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pw, pixelsHigh: ph,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        let image = NSImage(size: NSSize(width: ptW, height: ptH))
        image.addRepresentation(rep)
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return image }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        ctx.cgContext.scaleBy(x: pixelScale, y: pixelScale)
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
