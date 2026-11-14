# MML v0.2.5

发布说明草稿，尚未公开发布。

MML 是一个单文件 Minecraft Java 版启动器，支持自动安装 Java、下载游戏及其依赖，可直接粘贴到 Windows PowerShell 5.1 运行。

## 本版内容

- 支持 Minecraft 1.20.1 及之后的正式版，自动检测或安装对应 Java。
- 默认 8 路下载、4 路文件校验，复用已有缓存。
- 支持 SHA-1 / SHA-256、流式 Hash、失败重试和 ZIP 路径检查。
- 修复 PowerShell 7 下 C# 核心的编译问题。
- 使用 MIT 许可证，版权署名为 leeyorkchen。

## 使用

打开 `src/mml.ps1`，将完整源码粘贴到普通权限的 64 位 Windows PowerShell 中执行，按提示选择版本和用户名。无需预先安装 Java。数据目录仍为 `%LOCALAPPDATA%\MML0.2`，已有缓存可以继续使用。

## 注意事项

- 仅支持离线用户名，不支持 Microsoft 账号登录，也不提供模组或整合包管理。
- PS5.1 和 Windows 上 PowerShell 7.6.9 的脚本、编译及下载回归已通过。作者另已在两个环境中使用 Java 25 正常下载并启动 Minecraft 26.3；其他游戏版本和 Windows 环境尚未全面验证。
- JSON 重定向、目录竞争和非事务解压等问题见[安全审查](SECURITY-REVIEW.md)，具体测试见[测试记录](TESTING.md)。

0.2.5 是 0.2 系列最后的功能版本，后续仅修复 Bug 和严重安全问题。

MIT 仅适用于本项目有权授权的部分，不包含游戏、Java 和第三方资源。

MML is NOT an official Minecraft product and is NOT approved by or associated with Mojang or Microsoft.
