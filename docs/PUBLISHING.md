# v0.2.5 公开发布准备

历史从初始化提交 `324fea2` 继续，保留本地准备记录。作者已创建公开仓库，并在审阅 README 后授权 Push。首次上传使用 main，保留提交历史，不强制覆盖远程内容。Release 说明仍为本地草稿。

作者确认的版权署名为 `leeyorkchen`。GitHub 账户为 `LeeYorkChen`，仓库为 [MML-0.2-Minimum-Minecraft-Launcher](https://github.com/LeeYorkChen/MML-0.2-Minimum-Minecraft-Launcher)，由作者创建，访问级别为 Public。首次 Push 前已检查仓库为空。

## 全部拟公开文件

```text
.gitattributes
.gitignore
LICENSE
README.md
CHANGELOG.md
SECURITY.md
src/mml.ps1
tests/README.md
tests/TestHelpers.ps1
tests/run-tests.ps1
tests/safety-cases.ps1
tests/fixtures/HttpStub.cs
docs/ARCHITECTURE.md
docs/COPYRIGHT-REVIEW.md
docs/LICENSE-OPTIONS.md
docs/PROJECT-AUDIT.md
docs/PUBLISHING.md
docs/RELEASE-v0.2.5.md
docs/SECURITY-REVIEW.md
docs/TESTING.md
```

仅以上 20 文件及现有提交历史。没有游戏、存档、Java / Libraries 二进制、缓存、备份、历史记录、原始日志、个人路径或真实认证信息。测试使用相对 / 环境路径或虚构向量。Git 自带示例 hooks 不属于跟踪文件，不作为源码上传。提交逐项指定文件，不使用 git add .。

完整 MIT 正文在根目录 LICENSE，版权行 `Copyright (c) 2026 leeyorkchen`，仅授权项目有权授权的内容。来源核查与限制见 COPYRIGHT-REVIEW.md；没有确证的第三方组件需要增加 NOTICE。

## 确认前审阅事项

- 生产脚本与原最终 0.2.5 字节不变，SHA-256 见 PROJECT-AUDIT.md。
- PS5.1 / PS7.6.9 自动回归通过；作者另确认在两个环境中使用 Java 25 正常下载并启动 Minecraft 26.3。模拟测试和作者实际测试分别记录，详见 TESTING.md。
- S1（JSON 自动重定向）、本地目录竞争及非事务解压边界仍在。批准清单时应明确接受按当前源码发布，或先另做安全修复；本次没有静默修改。
- 拟只附同源 mml.ps1 为 Release 附件；GitHub 自动源码归档只含跟踪文件，不附任何游戏或 Java 文件。
- SECURITY 私密报告入口须创建仓库后检查 / 启用，目前不声称已启用，不编造邮箱。

作者本次授权上传已审阅的项目文件。禁止强制 Push、覆盖远程历史或变更仓库可见性。公开 Release 另行处理，不因本次 Push 自动发布。

本地准备提交使用中性身份 `MML local preparation <mml-local@localhost>`，不是作者真实邮箱，版权署名与 Git 提交身份不同。没有修改全局 Git 配置。旧开发目录、原文件和历史均保留。0.2.5 后仅计划修复 Bug 和严重安全问题。
