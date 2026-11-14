# MML — Minimum Minecraft Launcher

轻量级、单文件的 Minecraft Java Edition 启动器，基于 Windows PowerShell 与 .NET。

**当前版本：0.2.5。** 这是 0.2 系列的最终功能版本，后续仅计划修复 Bug 和严重安全问题。本仓库为发布前整理的候选稳定快照；许可证与公开发布尚待项目所有者确认。

MML is a lightweight, single-file Minecraft Java Edition launcher for Windows, built with PowerShell and .NET. It detects or installs Java and downloads vanilla releases and their dependencies. Microsoft account authentication is not implemented.

## 功能与范围

- 动态读取 Mojang 官方 Manifest，选择 1.20.1 及之后的正式版；识别本启动器已经安装的版本。
- 下载 Client、Libraries、Assets、Native Libraries 与日志配置，复用已通过完整性校验的缓存。
- 内嵌 C# 下载核心：共享 HttpClient、最多 8 个下载 Worker、最多 4 路本地文件校验、Assets Hash 去重。
- Mojang 文件 SHA-1、Java 压缩包 SHA-256；下载过程中计算 Hash，有限重试，同目录临时文件及校验成功后替换。
- URL 白名单、二进制下载逐级重定向检查、路径边界和 Reparse Point 检查、ZIP 安全解压。
- 自动寻找匹配版本的 Windows x64 Java，必要时从 Adoptium 下载并验证安装；保留 JavaSoft 注册表检测。
- 离线用户名和 UUID、Rules、Classpath、JVM / Game Arguments、Windows 参数转义及游戏日志。

**不支持 Microsoft 正版账号登录。** 离线身份不能完成正版服务器或 Realms 身份认证；脚本中的 `MML_OFFLINE` 是占位值，不是正版 Access Token。游戏的使用权及相关条款仍由用户自行遵守。

目前不提供 Mod / 整合包管理、其他启动器目录复用、GUI、服务器管理或自动更新。MML 不是 Mojang / Microsoft 的官方产品，仓库不附带游戏文件或 Java 安装包。

## 使用

1. 使用 Windows x64，打开普通权限的 **64 位 Windows PowerShell 5.1**。无需管理员权限，也无需另装模块、SDK 或编译器。
2. 用文本编辑器打开 [src/mml.ps1](src/mml.ps1)，复制完整内容，粘贴到 PowerShell，按回车执行。
3. 选择版本，输入 3–16 位英文字母、数字或下划线组成的用户名；直接回车使用 Steve。
4. 等待 Java 检查、下载与校验完成，随后脚本启动游戏。

首次运行需要能访问 Mojang、Adoptium 及其 GitHub Release 下载链路的网络；磁盘空间取决于版本。脚本目前固定使用 `-Xms512M -Xmx2G`。复制粘贴运行不需要修改系统执行策略。同一窗口可以再次粘贴运行，已编译的版本化 C# 类型会复用。

数据目录始终是 `%LOCALAPPDATA%\MML0.2`，包含 `assets`、`libraries`、`versions`、`java`、`natives`、`instances`、`cache` 和 `logs`。升级不会改用新目录。排查错误可查看其中的游戏日志；分享前应清除个人路径、用户名和其他隐私。

## 兼容性与验证边界

| 环境 | 已完成的检查 | 仍未验证 |
| --- | --- | --- |
| Windows PowerShell 5.1.22621.2428 / .NET Framework | 本仓库语法、C# 编译、重复初始化、下载 / Hash / 安全回归；历史记录还包含完整安装入口模拟 | 本次没有实际启动 Minecraft；未穷举 Windows 安装环境 |
| Windows PowerShell 7.6.9 / .NET 10 | 本仓库相同回归；已保留 Add-Type 引用修复；历史记录包含入口模拟 | 所有其他 PS7 小版本、Linux / macOS、真实游戏窗口 |

**主要支持目标仍是 Windows PowerShell 5.1；PS7 仅对上述实测环境作兼容说明。** 本次整理不更改启动器的功能或参数。详细证据、历史测试和本次测试分别见 [测试说明](docs/TESTING.md)。

## 维护与源码

```text
MML/
├── README.md
├── CHANGELOG.md
├── .gitignore
├── src/mml.ps1          # 唯一生产脚本，单独复制即可运行
├── tests/              # 无外部模块的回归测试与本地 HTTP 桩
└── docs/               # 架构、审查、测试、许可证比较与发布准备
```

[版本记录](CHANGELOG.md) · [实现说明](docs/ARCHITECTURE.md) · [源码与安全审查](docs/SECURITY-REVIEW.md) · [文件整理记录](docs/PROJECT-AUDIT.md) · [发布准备](docs/PUBLISHING.md)

测试不会启动游戏，不操作现有 MML 数据目录。开发测试可在仓库根目录运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
# 可选：额外联网获取官方版本元数据，并下载少量 Assets 到临时目录
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1 -Online
# 如果已经安装 PowerShell 7，可在相同目录运行
pwsh.exe -NoProfile -File .\tests\run-tests.ps1
```

测试命令中的 Bypass 仅用于当前测试进程，不更改系统或用户执行策略；受组织策略约束时请遵循本机规则。运行启动器仍可采用上面的完整源码粘贴方式。

## 许可证状态

**尚未选择许可证，没有添加 LICENSE，也没有授予开源许可证。** 目前不能把本仓库视为已经完成开源授权的项目。MIT、Apache-2.0、GPL-3.0 的区别及建议见 [许可证选择](docs/LICENSE-OPTIONS.md)，等待项目所有者决定后再更新本节。
