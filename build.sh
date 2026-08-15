#!/bin/bash
# 构建 ZoomCat.app：编译 -> 生成图标 -> 打包 -> 签名
set -euo pipefail
cd "$(dirname "$0")"

APP="ZoomCat.app"
BIN="$APP/Contents/MacOS/ZoomCat"

echo "==> 清理旧构建..."
rm -rf "$APP" build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build

echo "==> 编译 Swift 源码..."
swiftc -O -swift-version 5 -o "$BIN" Sources/*.swift Sources/SMC.c

echo "==> 生成应用图标..."
"$BIN" --gen-icon build/icon_master.png
mkdir -p build/icon.iconset
for s in 16 32 64 128 256 512; do
    sips -z "$s" "$s" build/icon_master.png --out "build/icon.iconset/icon_${s}x${s}.png" >/dev/null
    d=$((s * 2))
    sips -z "$d" "$d" build/icon_master.png --out "build/icon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns build/icon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

echo "==> 写入 Info.plist..."
cp Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP/Contents/Info.plist"

echo "==> 签名..."
codesign --force --deep --sign - "$APP"

echo "==> 完成: $(pwd)/$APP"
