# 源码与安全审查

审查日期：2026-11-14。以下为源码审查与受控测试的结果，不是独立渗透测试或“绝对安全”保证。

对应生产源码 `src/mml.ps1` 的 SHA-256：

```text
31728321D2B89F07566BF4AAEEF544BBDD897E81B43999120FB651CFFE5C595F
```

## 已有保护

| 范围 | 实际实现 |
| --- | --- |
| 文件下载 URL | HTTPS、默认端口、无 UserInfo、精确域名白名单；GitHub 路径仅限 adoptium/temurin*-binaries/releases/download/ |
| 文件重定向 | HttpClient 禁止自动重定向，逐级执行同样检查，最多 5 次跳转 |
| Hash | 严格十六进制 40 / 64 位；Mojang SHA-1、Java SHA-256；不匹配不提交 |
| 缓存与提交 | 本地先验证；下载时 Hash；同目录唯一临时文件；成功后 Move / Replace；有限重试并清理临时文件 |
| 路径 | 拒绝绝对相对参数、冒号 / ADS、规范化后越界；逐级检查已存在路径的 Reparse Point；文件提交前再次检查 |
| ZIP | 每个条目先做上述路径检查；保留 exclude；归档 finally 释放 |
| Java | 自有目录、JAVA_HOME、厂商目录、JavaSoft、PATH；实际执行检查主版本、架构和退出码；安装包 SHA-256；安全解压后再次探测 |
| 身份与参数 | 标准 OfflinePlayer UUID v3 规则；无登录凭据采集；未知占位符拒绝；保留 Windows 参数转义 |
| PowerShell | 无 `$home` / `$HOME` 写入；没有向 Host、PID、Error、Matches、Input、PROFILE 等自动变量赋值的命名冲突；`$Matches` 可由正则运算自然更新，不应把这种系统行为当作冲突 |

白名单共 10 个精确域名：`piston-meta.mojang.com`、`piston-data.mojang.com`、`launchermeta.mojang.com`、`launcher.mojang.com`、`libraries.minecraft.net`、`resources.download.minecraft.net`、`api.adoptium.net`、`github.com`、`objects.githubusercontent.com`、`release-assets.githubusercontent.com`。未使用任意 `*.githubusercontent.com` 通配放行。

## 已知问题与维护建议

| 编号 / 优先级 | 问题和适用条件 | 建议 |
| --- | --- | --- |
| S1 / 中 | `Get-Json` 只对白名单初始 URL 调用 Url，随后 Invoke-RestMethod 自动跟随重定向；JSON 获取没有与二进制相同的逐级白名单边界。这不代表二进制下载绕过白名单。 | 建议为 JSON 请求增加同等的手动重定向限制，并回归 Manifest / Adoptium API。 |
| S2 / 中，需本地竞争条件 | 路径检查与实际目录创建 / 提取 / 文件提交之间存在时间间隔。若另一个本地进程能同时把目录换成 junction，字符串检查无法完全消除 TOCTOU。 | 保持数据目录仅可信用户可写；更强防护需基于句柄和权限的设计，单独评估体积、兼容和回归成本。 |
| S3 / 低，可靠性 | Native / Java 按条目覆盖解压，整个目录不是事务式提交；中断可能留下部分提取内容。下次按现有流程重新解压，不能宣称整目录原子安装。 | 若实际出现损坏问题，评估完整性标记或临时目录提交，同时考虑实现复杂度和既有缓存兼容性。 |
| S4 / 信任边界 | Java 安装 ZIP 校验不等于每次执行都验证已解压 java.exe 的供应商签名 / Hash。外部 Java 来源本就由本机配置提供。Probe-Java 会执行这些候选文件。 | 文档明确本机 Java / 数据目录需可信；不要将其描述为沙盒或防恶意 Java 执行机制。 |

本次未发现明文认证密钥或能在正常静态路径场景绕过 ZIP 根目录边界的问题；测试覆盖范围见 [测试说明](TESTING.md)。不据此声称排除全部严重漏洞。

## 其他边界

- SHA-1 在这里用于兼容官方内容寻址及损坏检测，不应描述为抗恶意碰撞的签名机制。元数据和预期 Hash 来自 HTTPS 官方链路，Manifest 没有独立签名验证。
- 官方 GitHub Release 文件域名是共享存储域；安全设计依赖完整下载链、官方元数据和预期 Hash，不是仅靠域名就证明每个文件来源。
- 当前无 ZIP 解压容量配额或文件签名验证；归档来自已校验的官方元数据下载链。程序不是处理任意不可信 ZIP 的通用安全工具。
- 无 Microsoft OAuth，不收集真实账号密码，不保证离线身份可连接任何特定服务器。
- 当前默认下载并发为 8 路，本地文件校验并发为 4 路。
- PS7 补丁不意味着跨平台支持；Windows 路径、注册表和 java.exe 等实现仍是 Windows 专用。

后续维护应优先评估 S1 的 JSON 重定向检查，并持续关注文件系统竞争和解压中断的影响。任何修复都应保留现有安全检查，验证缓存兼容性，并在 Windows PowerShell 5.1 和受支持的 PowerShell 7 环境中完成回归测试。
