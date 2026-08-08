# Read It Later 📖

Mac 刘海区"稍后再看"插件 — 一键保存链接，刘海区管理你的阅读列表。

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ 功能特点

- 🎯 **刘海交互** — 鼠标移到刘海区域或按 `⌘⇧R` 展开/收起面板
- 🔗 **多种添加方式** — Chrome 扩展一键保存、全局快捷键、手动粘贴
- 📊 **自动分组** — 按域名自动归类（GitHub / 微信 / Twitter / 其他）
- 🏷️ **状态管理** — 未读 → 在读 → 已读，点击链接自动标记已读
- 🚦 **陈旧提醒** — <7天绿色、7-30天黄色、>30天红色，防止链接过期
- 🔍 **搜索** — 按标题、URL、域名快速搜索
- 🌐 **自动抓取** — 保存时自动获取网页标题、摘要和图标
- 🔒 **隐私安全** — 所有数据纯本地存储，零外部依赖

## 🏗️ 技术架构

```
read-it-later/
├── ReadItLater/           # macOS 原生应用（Swift + SwiftUI）
│   ├── Package.swift      # 零外部依赖，使用系统原生框架
│   └── Sources/
│       ├── App/           # 应用入口
│       ├── Models/        # 数据模型 + SQLite
│       ├── Views/         # SwiftUI 视图
│       └── Services/      # 刘海窗口、HTTP 服务、网页抓取
└── chrome-extension/      # Chrome 扩展
    ├── manifest.json
    ├── popup.html/js      # 一键保存弹窗
    ├── background.js      # 后台服务
    └── options.html/js    # 设置页
```

**零外部依赖**，全部使用 macOS 原生框架：
- **SQLite3** — 系统自带 C 库，数据持久化
- **Network.framework** — 原生 HTTP 服务，与 Chrome 扩展通信
- **Carbon.HIToolbox** — 原生全局快捷键注册
- **SwiftUI + AppKit** — UI 框架 + 刘海浮动窗口

## 🚀 快速开始

### 构建 macOS 应用

```bash
cd ReadItLater
swift build
```

构建产物在 `.build/debug/ReadItLater`

### 运行

```bash
swift run
```

或在 Xcode 中打开 `Package.swift` 直接运行。

启动后：
1. 刘海区域会出现折叠态的 Read It Later
2. 鼠标移到刘海区域 → 自动展开
3. 按 `⌘⇧R` → 手动展开/收起

### 安装 Chrome 扩展

1. 打开 Chrome → `chrome://extensions/`
2. 开启右上角「开发者模式」
3. 点击「加载已解压的扩展程序」
4. 选择 `chrome-extension/` 目录
5. 扩展安装完成，点击工具栏图标即可一键保存

## 📋 使用方式

### 保存链接

| 方式 | 操作 |
|------|------|
| Chrome 扩展 | 点击工具栏图标 → "保存到 Read It Later" |
| 全局快捷键 | `⌘⇧R` 打开面板 → 粘贴 URL → 回车保存 |
| 手动添加 | 展开面板 → 点击 `+` → 输入 URL |

### 管理列表

- **展开面板**：查看所有保存的链接
- **点击链接**：在浏览器中打开并自动标记已读
- **右键菜单**：标记在读 / 查看详情 / 删除
- **域名筛选**：点击顶部的域名标签快速筛选
- **搜索**：顶部搜索框按标题/URL/域名搜索

### 陈旧度指示

- 🟢 **绿色**：保存 < 7 天
- 🟡 **黄色**：保存 7-30 天
- 🔴 **红色**：保存 > 30 天（该去读了！）

## ⚙️ 配置

- **HTTP 端口**：默认 `19623`，可在 `SettingsView.swift` 中修改
- **快捷键**：`⌘⇧R`，可在 `NotchManager.swift` 中修改
- **陈旧天数**：可在设置中调整

## 🗺️ 开发路线

### Phase 1 ✅（已完成）
- [x] 刘海窗口（鼠标+快捷键触发）
- [x] SQLite 数据持久化
- [x] 自动抓取网页标题+摘要+图标
- [x] 域名自动分组
- [x] 状态管理（未读/在读/已读）
- [x] URL 重复检测
- [x] Chrome 扩展一键保存
- [x] 本地 HTTP 服务

### Phase 2（P1）
- [ ] 陈旧链接视觉提醒增强（闪烁动画）

### Phase 3（P2）
- [ ] Chrome 扩展关闭标签页提示
- [ ] 每日摘要推送
- [ ] 手动标签
- [ ] Markdown 笔记模式
- [ ] 导出（Markdown/JSON）

## 🔧 构建说明

### 环境要求

- macOS 13+
- Swift 5.9+
- Xcode 15+（推荐）

### 使用 Xcode 构建

```bash
open ReadItLater/Package.swift   # 在 Xcode 中打开
# 选择 "My Mac" 作为运行目标
# Cmd+R 运行
```

### 打包为 .app

```bash
cd ReadItLater
swift build -c release

# 复制到 Applications
cp .build/release/ReadItLater /Applications/ReadItLater.app
```

### Chrome 扩展图标

`chrome-extension/icons/` 目录下已包含生成的图标。如需自定义，替换为同等尺寸的 PNG 文件。

## 📝 License

MIT
