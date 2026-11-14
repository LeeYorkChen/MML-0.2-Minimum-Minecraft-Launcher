# 实现说明

生产入口只有 `src/mml.ps1`，无需仓库的其他文件即可运行。数据根目录固定为 `%LOCALAPPDATA%\MML0.2`，不扫描或迁移其他启动器目录。

## PowerShell

负责版本菜单、官方 JSON 解析、Rules、Java 搜索 / 安装流程、Libraries 与 Native 列表、ZIP 安全解压、Classpath、离线 UUID、参数替换 / 转义以及启动。Rules 按匹配顺序覆盖 allow / disallow，检查 Windows、x64、OS 正则和版本范围；当前启动器未启用可选 features。

顺序是：选择版本及用户名 → 校验版本 JSON → 确定所需 Java → 检测或安装 Java → Client / Libraries 批量处理 → Native 解压 → Assets 索引与对象 → 日志配置 → 参数 → 启动。

`Probe-Java` 实际运行候选可执行文件，异步读取标准输出 / 错误，等待上限 15 秒，要求退出码为零、主版本精确匹配且架构为 amd64 / x86_64。不是只检查路径存在，也不会全盘搜索任意位置的 Java。未进入自有目录、JAVA_HOME、常见厂商目录、注册表或 PATH 的独立 Java 路径可能无法被发现。

## MMLCore025

- `Job`：URL、绝对目标路径、预期 Hash。
- `Url` / `PathIn`：官方域名与路径边界、已有 Reparse Point 检查。
- `Valid`：校验已有文件。40 位十六进制选择 SHA-1，64 位选择 SHA-256，拒绝其他格式。
- `Batch`：先规范化 / 去重目标路径并拒绝冲突 Hash，再以最多 4 路读取校验缓存，把缺失或损坏项放入队列，以最多 8 个 Task Worker 下载。单文件入口使用 1 路。
- `Assets`：HashSet 内容 Hash 去重后进入 Batch。Libraries / Client 同样使用 Batch；下载顺序不决定 Classpath 顺序。
- `Fetch`：共享 HttpClient，ResponseHeadersRead，关闭自动跳转，最多 5 次手动跳转，每一级校验；每次尝试 120 秒，最多 3 次，失败后等待 1 / 2 秒。

流式 Hash：每次读取最多 64 KiB，调用 `TransformBlock` 同时写入同目录 GUID `.part` 文件；结束后 `TransformFinalBlock` 比较预期值。新文件不再重读；已有缓存仍需读取验证。只有校验成功才 `File.Move` 或 `File.Replace`。失败会清理临时文件；批次等待全部 Worker 结束再汇总异常，不存在同步备用下载与旧任务竞争。

Native ZIP 的每个条目先经过 PathIn，再按 exclude 前缀忽略文件并提取；没有 Native 解压缓存或事务性整目录替换。

## 编译与兼容

内嵌代码使用 C# 5 语法及系统 .NET API，无 NuGet、下载 DLL、SDK 或额外模块。先检查类型是否存在，再 Add-Type；同一窗口重复执行复用类型。修改内嵌 C# 后测试应使用新进程，以免复用旧类型。

Windows PowerShell Desktop 显式补充 System.Net.Http.dll。PowerShell Core 使用 Add-Type 默认程序集引用，避免显式引用覆盖默认集合导致缺失 Concurrent 等命名空间；仅 Core 传 `/nowarn:SYSLIB0014` 处理保留的 ServicePointManager 旧 API 诊断。API 使用与安全边界见 [审查](SECURITY-REVIEW.md)，实测环境见 [测试](TESTING.md)。
