# 可移植回归测试

从仓库根目录运行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1`；Bypass 仅作用于当前测试进程，不改变系统 / 用户策略。已安装 PS7 时可换成 `pwsh.exe`。无需 Pester 或额外模块。请分别使用新进程，避免旧 C# 类型复用影响结果。目标为 Windows x64。

默认不联网，不执行游戏入口，不操作现有 MML 数据目录、不修改注册表或 JAVA_HOME。通过 AST 只加载生产初始化和函数；HTTP 测试桩从同一 C# 核心替换客户端 / 缩短超时得到，生产文件不修改。测试会在系统 TEMP 下创建带 GUID 的专属目录及少量文件 / junction，保留便于检查，不自动递归删除。

覆盖 SHA1 / SHA256、格式拒绝、8 / 4 并发上限、批次去重、热缓存、流式 Hash、重试 / 中断 / 超时 / 文件占用、重定向白名单及跳转上限、失败不替换、临时文件清理、ZIP / exclude / junction、Rules、UUID、参数 / 路径、自动变量、注册表搜索和 Java 缺失流程。后两项为明确的受控桩，不代表本机真实注册表或真实 Java 安装验收。

`-Online` 额外获取官方 Manifest、1.20.1 版本 JSON 和 Assets 索引，下载其中 4 个资源并增加一个重复引用，验证去重、Hash 和重复执行缓存。它不下载完整 Minecraft 或 Java，也不保证当前最新正式版可启动。

测试结果与历史记录的区别、未覆盖场景见 [测试说明](../docs/TESTING.md)。测试桩和测试脚本是开发材料，不是运行启动器所需的依赖。
