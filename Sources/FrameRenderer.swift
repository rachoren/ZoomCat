import AppKit

/// 通用帧渲染器：30×18 宽扁画布（与 RunCatNeo 精灵比例一致），2x 像素。
/// 自动适配：先渲染一遍测量内容包围盒，再按比例缩放并居中重绘，
/// 使四周留出统一边距（margin），解决内容贴边/不居中的问题。
enum FrameRenderer {
    static func makeImage(ptW: CGFloat = 30, ptH: CGFloat = 18,
                          pixelScale: CGFloat = 2, margin: CGFloat = 1.5,
                          _ draw: () -> Void) -> NSImage {
        let pw = Int(ptW * pixelScale)
        let ph = Int(ptH * pixelScale)

        // 第一遍：渲染到临时 rep，测量内容包围盒
        let measureRep = makeRep(pw: pw, ph: ph)
        render(into: measureRep, pixelScale: pixelScale, tx: 0, ty: 0, draw: draw)
        guard margin > 0 else { return makeImage(from: measureRep, ptW: ptW, ptH: ptH) }

        let box = measureBBox(measureRep, pw: pw, ph: ph)
        guard box.maxX > box.minX, box.maxY > box.minY else {
            return makeImage(from: measureRep, ptW: ptW, ptH: ptH)
        }

        // 换算到绘制坐标（绘制坐标系 y 向上，像素行 0 在顶部 → y 翻转）
        let dW = CGFloat(box.maxX - box.minX) / pixelScale
        let dH = CGFloat(box.maxY - box.minY) / pixelScale
        let dMinX = CGFloat(box.minX) / pixelScale
        let dMinY = (CGFloat(ph) - CGFloat(box.maxY)) / pixelScale

        // 按比例缩放，使内容四周留出 margin，并居中
        let scale = min((ptW - margin * 2) / dW, (ptH - margin * 2) / dH, 1.0)
        let outW = dW * scale
        let outH = dH * scale
        let tx = (ptW - outW) / 2 - dMinX * scale
        let ty = (ptH - outH) / 2 - dMinY * scale

        // 第二遍：渲染到全新 rep（带缩放与居中）
        let finalRep = makeRep(pw: pw, ph: ph)
        render(into: finalRep, pixelScale: pixelScale * scale,
               tx: tx * pixelScale, ty: ty * pixelScale, draw: draw)
        return makeImage(from: finalRep, ptW: ptW, ptH: ptH)
    }

    /// 带缩放动画的绘制包装（如奔跑弹跳）。
    static func withBounce(_ amount: Double, phase: Double, _ draw: () -> Void) {
        let cg = NSGraphicsContext.current!.cgContext
        cg.saveGState()
        cg.translateBy(x: 0, y: CGFloat(amount * abs(sin(phase * 4 * .pi))))
        draw()
        cg.restoreGState()
    }

    // MARK: - 内部工具

    private static func makeRep(pw: Int, ph: Int) -> NSBitmapImageRep {
        NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pw, pixelsHigh: ph,
                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                         isPlanar: false, colorSpaceName: .deviceRGB,
                         bytesPerRow: 0, bitsPerPixel: 0)!
    }

    private static func makeImage(from rep: NSBitmapImageRep, ptW: CGFloat, ptH: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: ptW, height: ptH))
        image.addRepresentation(rep)
        return image
    }

    private static func render(into rep: NSBitmapImageRep, pixelScale ps: CGFloat,
                               tx: CGFloat, ty: CGFloat, draw: () -> Void) {
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return }
        let cg = ctx.cgContext
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        cg.saveGState()
        cg.translateBy(x: tx, y: ty)
        cg.scaleBy(x: ps, y: ps)
        draw()
        cg.restoreGState()
        NSGraphicsContext.restoreGraphicsState()
    }

    /// 快速扫描 alpha 通道（RGBA 每像素 4 字节，alpha 在偏移 3）。
    private static func measureBBox(_ rep: NSBitmapImageRep, pw: Int, ph: Int)
        -> (minX: Int, minY: Int, maxX: Int, maxY: Int) {
        guard let data = rep.bitmapData else { return (pw, ph, -1, -1) }
        let bpr = rep.bytesPerRow
        let bpp = rep.bitsPerPixel / 8
        var minX = pw, minY = ph, maxX = -1, maxY = -1
        for y in 0..<ph {
            let row = data + y * bpr
            for x in 0..<pw {
                if row[x * bpp + 3] > 8 { // alpha > 0.03
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }
        return (minX, minY, maxX, maxY)
    }
}
