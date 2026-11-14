# 安全问题报告

0.2.5 为 0.2 系列的最终功能版本，后续仅计划修复 Bug 和严重安全问题。支持目标为 Windows PowerShell 5.1；PowerShell 7 兼容性限于实测环境，见 docs/TESTING.md。

拟发布仓库为 `LeeYorkChen/MML`。公开后，若仓库启用了 GitHub Private vulnerability reporting，请通过仓库 **Security → Advisories → Report a vulnerability** 私密报告。该入口在仓库创建及功能启用后才可用，当前尚未验证或启用。

若私密报告入口不可用，请先开一个不包含技术细节的 Issue，仅请求维护者提供私密联系方式；在获得渠道前不要上传漏洞利用、凭据、私人路径、日志或受影响存档。本项目目前没有另行确认的安全联络邮箱，也不承诺固定响应时限。

报告请包含版本、Windows / PowerShell 版本、影响范围、最小复现和已脱敏的必要证据。普通安装问题可用公开 Issue；可利用的漏洞细节应走私密渠道。

现有保护包括下载源限制、二进制逐级重定向检查、SHA 校验、临时文件及路径 / ZIP 检查。这不是专业安全认证，也不保证绝对安全。已知边界见 [安全审查](docs/SECURITY-REVIEW.md)，包括 JSON 自动重定向、文件系统竞争条件及非事务式解压。
