#!/bin/bash
set -e

echo "📖 Read It Later 一键安装"
echo "=========================="
echo ""

# Check Command Line Tools
if ! xcode-select -p &>/dev/null; then
    echo "📦 正在安装 Command Line Tools..."
    xcode-select --install 2>/dev/null || true
    echo "⚠️  请先完成 Command Line Tools 安装，然后重新运行此命令"
    exit 1
fi

# Clone or use existing
REPO_DIR="$HOME/read-it-later"
if [ -d "$REPO_DIR" ]; then
    echo "📂 目录已存在，正在更新..."
    cd "$REPO_DIR"
    git pull --ff-only
else
    echo "📥 正在下载..."
    git clone https://github.com/Alephzz/read-it-later.git "$REPO_DIR"
    cd "$REPO_DIR"
fi

echo "🔨 正在编译...（首次约 1-2 分钟）"
cd ReadItLater
swift build -c release

echo "📦 正在打包 .app..."
APP_DIR="$HOME/Applications/Read It Later.app/Contents/MacOS"
mkdir -p "$APP_DIR"
cp .build/release/ReadItLater "$APP_DIR/ReadItLater"

# Ensure Info.plist exists
if [ ! -f "$HOME/Applications/Read It Later.app/Contents/Info.plist" ]; then
    mkdir -p "$HOME/Applications/Read It Later.app/Contents/Resources"
    cat > "$HOME/Applications/Read It Later.app/Contents/Info.plist" << 'PLIST'
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
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "🔧 下一步："
echo "   open ~/Applications        # 双击 Read It Later.app 启动"
echo ""
echo "💡 开机自启：系统设置 → 通用 → 登录项与扩展 → 添加 Read It Later.app"
