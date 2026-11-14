# 版本记录

以下概括本地迭代记录，并与实际源码核对；这些版本号不代表已经发布 GitHub Release。0.2 系列在 0.2.5 后进入维护阶段，仅计划修复 Bug 与严重安全问题。

## 0.2.5 — 候选稳定快照

- 首次公开发布准备：MIT、署名 leeyorkchen，补充 SECURITY、版权审查与 Release 说明；复跑 PS5.1 / PS7.6.9 回归。生产脚本不变，远程发布仍待最终批准。

- 合并 Java 寻找与缺失时安装流程，继续实际执行 Java 校验主版本和 x64 架构；保留自有 Java、JAVA_HOME、厂商目录、JavaSoft 注册表和 PATH 搜索。
- 注册表直接收集 JavaHome 属性，不向 `$home` / `$HOME` 赋值，保留之前的自动变量冲突修复。
- 精简 Rules、ZIP / Native、参数替换、版本选择与公共资源获取的重复逻辑，保留路径、校验及错误边界。
- 批量下载失败异常增加目标文件路径，所有 Worker 结束后汇总错误。
- PS7 兼容补丁：Desktop 版显式引用 System.Net.Http.dll；Core 版采用默认引用，并定向处理 SYSLIB0014 编译诊断。保留版本化类型 MMLCore025 与重复执行保护。
- 补丁后正式源码为 349 行、20,062 字符、20,065 个 UTF-8 字节（含 BOM）。旧的 346 行 / 19,886 字符数据属于补丁前版本。
- 本次仓库初始化只整理文档和可移植测试，`src/mml.ps1` 与本地最终 0.2.5 原文件逐字节相同；不新增功能、不更改数据目录。

## 0.2.4 — 核心简化

- 使用只读字段的 Job 结构统一描述 URL、路径、Hash，减少中间包装与重复函数。
- 精简文件检查、Hash 比较、Java 候选集合与 JSON 读取；保留共享 HttpClient、8 路下载、4 路校验、有限重试与流式 Hash。
- 保留逐块 ReadAsync / TransformBlock / WriteAsync / TransformFinalBlock 流程；未采用未能证明稳定收益的 CryptoStream、Lazy 或更高框架要求方案。

## 0.2.3 — PowerShell 外壳与 C# 下载核心

- 引入 C# 5 兼容的内嵌静态类，以共享 HttpClient、固定 Task Worker、ConcurrentQueue 与 Parallel.ForEach 统一文件下载和已有文件校验。
- Client、Libraries、Assets、Java 共用重试、临时文件、SHA 和成功提交逻辑；下载时流式计算 Hash。
- Assets 内容 Hash 去重；默认 8 路下载、4 路已有文件校验；Libraries / Client 批量处理且 Classpath 保留原依赖顺序。
- 二进制下载关闭自动重定向，逐级检查官方域名、HTTPS、端口、UserInfo 和跳转次数。
- Java 检测 / 安装前置；不支持的 Assets 布局在对象下载前拒绝。继续复用 `%LOCALAPPDATA%\MML0.2`。

## 0.2.2 — PowerShell 与 .NET 文件系统优化

- 用系统 .NET 文件系统 API 减少 PowerShell Provider 调用，并合并公共资源下载入口。
- 保留原路径边界和 Reparse Point 检查；当时仍是串行完整性校验、8 路 Assets 异步下载，尚未引入 C# 下载核心。

## 更早版本

0.2 / 0.2.1 完成基础下载、安装、启动与初步精简；修复过 `$home` 与 PowerShell 只读自动变量 `$HOME` 的冲突。历史脚本、备份和原始测试完整保留在本地原项目，不进入本仓库初始提交。
