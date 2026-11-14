# MML-0.2-Minimum-Minecraft-Launcher

MML 是一个单文件的 Minecraft Java 版启动器，使用 PowerShell 和 C# 编写，支持自动安装 Java、下载游戏及其依赖。将脚本粘贴到 Windows 自带的 PowerShell 中即可运行，无需管理员权限或额外模块。

**启动器的全部逻辑都包含在本地脚本中。** MML 运行时不会从远程服务器下载或执行额外的启动脚本，也不依赖第三方服务器生成启动计划。联网用于获取官方版本元数据，以及游戏、依赖、资源和 Java 等安装运行所需的文件。

A single-file Minecraft Java Edition launcher for Windows, written in PowerShell and C#.

当前版本为 **0.2.5**。这是 0.2 系列最后的功能版本，后续仅修复 Bug 和严重安全问题。

## 功能

- 安装 Minecraft 1.20.1 及之后的正式版，识别并复用 MML 自己安装的版本。
- 自动检测 Java，缺少所需版本时从 Adoptium 下载。
- 并发下载游戏文件、依赖库和资源，复用已通过校验的缓存。
- 支持 SHA-1 / SHA-256 校验、下载重试和 Native Libraries 解压。
- 使用离线用户名启动游戏，自动生成 UUID 和启动参数。

## 使用限制

- **不能选择游戏路径。** 游戏和下载缓存固定保存在 `%LOCALAPPDATA%\MML0.2`，MML 下载的 Java 也放在这个目录下，目前不能更改数据目录。
- **只识别 MML 自己安装的游戏。** 不支持导入已有的 `.minecraft` 目录，也不会扫描或复用其他启动器安装的游戏。
- **不能手动指定 Java 路径。** Java 由程序自动检测或下载；仍会检查 `JAVA_HOME`、注册表和 `PATH` 等来源，具体搜索范围见下文。
- 不支持 Microsoft 账号登录，无法完成正版服务器或 Realms 的身份认证。
- 不提供模组和整合包管理。

## 运行要求

- Windows x64，使用 64 位 PowerShell。
- Windows PowerShell 5.1；也已在 Windows 上的 PowerShell 7.6.9 中测试。
- 能够访问 Mojang、Adoptium 和 GitHub Release 下载服务的网络。

无需预先安装 Java。PowerShell 7 的其他版本尚未逐一测试；具体结果见[测试记录](docs/TESTING.md)。

## 使用方法

1. 用文本编辑器打开 [src/mml.ps1](src/mml.ps1)，复制完整源码。
2. 打开 Windows PowerShell，粘贴源码并执行。
3. 选择 Minecraft 版本，输入用户名，等待安装完成。

用户名支持 3–16 位英文字母、数字或下划线，直接回车使用 `Steve`。脚本会先检查 Java，再下载游戏文件，最后启动游戏。

升级脚本后仍使用 `%LOCALAPPDATA%\MML0.2`，MML 已下载的文件会在校验后复用。游戏日志在其中的 `logs` 目录。

当前 JVM 内存参数固定为 `-Xms512M -Xmx2G`，没有设置菜单。

## Java 与文件下载

MML 会搜索自有 Java、`JAVA_HOME`、常见厂商安装目录、JavaSoft 注册表和 `PATH`，并运行候选程序检查主版本和 x64 架构。放在其他位置、也未登记到上述来源的 Java 可能无法被发现。

找不到匹配版本时，脚本从 Adoptium 下载 Windows x64 JRE，必要时改用 JDK，校验并解压后再次检查。

程序使用以下官方来源：

- **Mojang**：`piston-meta.mojang.com`、`piston-data.mojang.com`、`launchermeta.mojang.com`、`launcher.mojang.com`、`libraries.minecraft.net` 和 `resources.download.minecraft.net`，用于版本元数据、游戏客户端、依赖库、资源及日志配置。
- **Adoptium**：`api.adoptium.net`，用于查询和下载所需 Java。
- **Adoptium / Temurin 的 GitHub Release**：Java 下载可能跳转至 `github.com/adoptium/temurin*-binaries/releases/download/`，以及 `objects.githubusercontent.com`、`release-assets.githubusercontent.com` 文件存储域名。

文件下载使用内嵌 C# 核心，默认最多 8 路下载、4 路本地校验。Mojang 文件使用 SHA-1，Java 压缩包使用 SHA-256；新文件在下载时计算 Hash，通过校验后才替换目标文件。下载失败最多尝试 3 次。

下载地址、重定向和 ZIP 路径均有检查，但仍有 JSON 自动重定向、目录竞争和解压中断等已知边界，详见[安全审查](docs/SECURITY-REVIEW.md)。本机 Java 和数据目录应来自可信来源。

## 文档与反馈

[更新日志](CHANGELOG.md) · [实现说明](docs/ARCHITECTURE.md) · [测试记录](docs/TESTING.md) · [安全问题报告](SECURITY.md)

报告问题时，请提供 PowerShell 版本、Minecraft 版本、错误信息和复现步骤。分享日志前请移除个人路径和其他隐私。开发测试的运行方法见 [tests/README.md](tests/README.md)；测试不启动游戏，也不操作现有游戏数据。

作者已在 Windows PowerShell 5.1 和 PowerShell 7.6.9 中实测，使用 Java 25 下载并启动 Minecraft 26.3 均正常。其他游戏版本和 Windows 环境尚未全面验证。

## 许可证

MML 使用 [MIT License](LICENSE)，Copyright (c) 2026 leeyorkchen。许可证仅适用于本项目有权授权的内容；第三方组件遵循各自许可证。

Minecraft、游戏资源和 Java 不包含在本仓库中，也不纳入 MML 的 MIT 授权。该许可证不授予 Minecraft、Mojang 或 Microsoft 的商标及其他知识产权使用权。

MML is NOT an official Minecraft product and is NOT approved by or associated with Mojang or Microsoft.
