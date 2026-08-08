#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_DIR="$HOME/Applications/Read It Later.app/Contents"

echo "🔨 Building..."
cd "$PROJECT_DIR"
swift build -c release

echo "📦 Packaging..."
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Resources"
cp "$BUILD_DIR/ReadItLater" "$APP_DIR/MacOS/ReadItLater"

cat > "$APP_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Read It Later</string>
    <key>CFBundleDisplayName</key>
    <string>Read It Later</string>
    <key>CFBundleIdentifier</key>
    <string>com.readitlater.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>ReadItLater</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "✅ Done! Launch: open ~/Applications"
echo ""
echo "💡 To auto-start on login:"
echo "   System Settings → General → Login Items → add 'Read It Later.app'"
