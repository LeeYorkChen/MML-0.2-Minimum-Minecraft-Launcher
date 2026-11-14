# MML v0.2.5

MML（Minimum Minecraft Launcher）首次正式公开版本的发布说明草稿。公开动作尚未执行。

单文件 Windows PowerShell / 内嵌 C# 原版 Minecraft Java Edition 启动器，支持 1.20.1 及之后正式版的动态选择、自动 Java 管理与依赖下载。无需管理员权限或额外模块。

- 共享 HttpClient、8 路下载 Worker、4 路已有文件校验、Assets Hash 去重。
- SHA-1 / SHA-256、下载时流式 Hash、有限重试、校验成功后安全替换。
- 保留 Native 安全解压、JavaSoft 检测、离线 UUID、Rules、Classpath 和参数构造。
- 保留 PS7 Add-Type 引用修复；数据目录继续使用 `%LOCALAPPDATA%\MML0.2`。

使用：下载仓库中的 `src/mml.ps1`，在普通权限的 64 位 Windows PowerShell 5.1 中粘贴完整源码执行。正式发布时可仅附同一份 `mml.ps1`；不附带游戏、Assets、Libraries 或 Java 文件。

许可：MIT，Copyright (c) 2026 leeyorkchen，仅适用于项目有权授权的内容。第三方内容遵循其自身条款。

不支持 Microsoft 账号登录。MML is NOT an official Minecraft product and is NOT approved by or associated with Mojang or Microsoft.

兼容性、实测与未测项目见 docs/TESTING.md；安全边界见 SECURITY.md 和 docs/SECURITY-REVIEW.md。没有实际启动游戏验收或穷举全部 PS7 / Windows 环境。本次只整理发布材料，不修改启动器业务逻辑。

0.2.5 是 0.2 系列最终功能版本，后续仅计划修复 Bug 和严重安全问题。
