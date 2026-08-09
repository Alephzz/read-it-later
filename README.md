# Read It Later 📖

Mac 刘海区"稍后再看"插件 — 一键保存链接，刘海区管理你的阅读列表。不用打开浏览器书签、不用翻聊天记录，链接就在你眼前。

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ 功能特点

- 🎯 **刘海交互** — 鼠标移到刘海区域或按 `⌘⇧R` 展开/收起面板
- 🔗 **多种添加方式** — Chrome 扩展一键保存、手动粘贴
- 📊 **自动分组** — 按域名自动归类（GitHub / 微信 / Twitter 等）
- 🏷️ **状态管理** — 未读 → 在读 → 已读
- 🚦 **陈旧提醒** — <7天绿色、7-30天黄色、>30天红色
- 🔍 **搜索** — 按标题、URL、域名快速搜索
- 🌐 **自动抓取** — 保存时自动获取网页标题、摘要和图标
- 🔒 **隐私安全** — 所有数据纯本地存储

---

## 📥 安装

打开终端，复制下面这一行，回车：

```bash
curl -fsSL https://alephzz.github.io/read-it-later/install.sh | bash
```

等待 1-2 分钟，编译完成后打开访达 → 前往 `~/Applications` → 双击 **Read It Later.app** 即可运行。

> 首次运行会提示 Command Line Tools 安装（系统自动弹出）。如果遇到"无法验证开发者"，去**系统设置 → 隐私与安全性** → 点击「仍要打开」。

**没有任何窗口弹出是正常的**。这是一个常驻后台的应用，刘海区域会出现 📖 图标。

💡 **开机自启动**：系统设置 → 通用 → 登录项与扩展 → 点击 `+` → 选择 `Read It Later.app`

---

## 🧩 安装 Chrome 扩展

安装扩展后，可以在浏览器里一键把当前网页存到刘海面板中。

1. 打开 Chrome，地址栏输入 `chrome://extensions/`，回车
2. 打开右上角「**开发者模式**」开关
3. 点击左上角「**加载已解压的扩展程序**」
4. 找到项目里的 `chrome-extension` 文件夹，点「选择」
5. 搞定！Chrome 工具栏会出现 📖 图标

> ⚠️ 扩展需要 macOS 应用**正在运行**才能保存链接。先确保 `.app` 已双击启动，再用扩展。

---

## 📋 日常使用

### 保存链接

| 方式 | 怎么操作 |
|------|----------|
| **Chrome 扩展**（推荐） | 浏览网页时点工具栏 📖 图标 → 点「保存到 Read It Later」 |
| **刘海面板手动加** | 鼠标移到刘海 → 面板展开 → 点右上角 `+` → 输入 URL → 保存 |
| **快捷键** | 按 `⌘⇧R` 打开面板 → 粘贴 URL |

### 查看和管理

- **展开面板**：鼠标移到刘海区域（或按 `⌘⇧R`）
- **打开链接**：点一下链接，浏览器打开并标记为「在读」
- **标记已读**：右键链接 → 「标记为已读」
- **查看详情**：右键链接 → 「查看详情」（可以改标题、打标签）
- **按来源筛选**：点面板顶部的域名标签（如 github.com、微信）
- **搜索**：面板顶部搜索框输入关键词
- **删除**：右键链接 → 「删除」

### 颜色含义

- 🟢 绿色圆点 = 最近 7 天存的，还新鲜
- 🟡 黄色圆点 = 存了 7-30 天了，该看看了
- 🔴 红色圆点 = 存了超过 30 天，压箱底了！

---

## ⚙️ 设置

打开刘海面板 → 点右上角 ⚙️ 图标，可以调整：

- **显示摘要预览** — 列表里是否显示网页摘要文字
- **HTTP 端口** — Chrome 扩展通信用的端口（一般不用改）
- **自动抓取** — 保存链接时是否自动获取标题和摘要
- **陈旧提醒天数** — 自定义变黄/变红的天数

---

## 🧑‍💻 开发者看这里

### 更新后重新打包

```bash
cd ~/Projects/read-it-later
./Scripts/package-app.sh
```

### 技术栈

- Swift + SwiftUI + AppKit
- SQLite3（系统自带，零外部依赖）
- Network.framework（本地 HTTP 服务）
- Carbon.HIToolbox（全局快捷键）

### 项目结构

```
read-it-later/
├── ReadItLater/           # macOS 应用
│   ├── Package.swift
│   └── Sources/ReadItLater/
│       ├── App/           # 应用入口
│       ├── Models/        # 数据模型 + SQLite
│       ├── Views/         # SwiftUI 视图
│       └── Services/      # 刘海窗口、HTTP 服务、网页抓取
├── chrome-extension/      # Chrome 扩展
│   ├── manifest.json
│   ├── popup.html/js      # 弹窗
│   ├── background.js      # 后台
│   └── options.html/js    # 设置
└── Scripts/               # 打包脚本
    └── package-app.sh
```

### 开发路线

**Phase 1 ✅**
- [x] 刘海窗口、SQLite、Chrome 扩展、自动抓取、域名分组、状态管理、去重

**Phase 2（P1）**
- [ ] 陈旧链接闪烁动画

**Phase 3（P2）**
- [ ] Chrome 扩展关闭标签页提示
- [ ] 每日摘要推送、标签筛选、Markdown 笔记、导出

---

## 📝 License

MIT
