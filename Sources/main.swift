import AppKit

// 图标生成模式: RunCat --gen-icon <输出PNG路径>
let args = CommandLine.arguments
if let idx = args.firstIndex(of: "--gen-icon"), args.count > idx + 1 {
    let icon = CatPainter(breed: .ragdoll).appIcon()
    if let tiff = icon.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: args[idx + 1]))
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
