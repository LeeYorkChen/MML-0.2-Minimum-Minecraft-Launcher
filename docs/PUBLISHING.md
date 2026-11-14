# v0.2.5 公开发布准备

仅完成本地准备。历史从初始化提交 `324fea2` 继续，不覆盖旧提交或候选标签 `v0.2.5-rc.1`。本次新增发布准备提交和本地 `v0.2.5` 标签，不执行远程写入。

作者确认的版权署名为 `leeyorkchen`。已检查 Git 2.56.0.windows.4、GitHub CLI 2.104.0，活动账户 `LeeYorkChen` 与作者提供的 GitHub 名一致。拟建 `LeeYorkChen/MML`，Public，默认 main；Description：`A minimal PowerShell-based Minecraft Java Edition launcher.`。目标只读查询返回 404；创建前复查，若占用停止，不改名或覆盖。

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
- PS5.1 / PS7.6.9 回归通过；真实官方元数据 / 4 个 Assets。Java 注册表与缺失流程使用桩；未重装真实 Java、未实际启动游戏、未验证全部 PS7。
- S1（JSON 自动重定向）、本地目录竞争及非事务解压边界仍在。批准清单时应明确接受按当前源码发布，或先另做安全修复；本次没有静默修改。
- 拟只附同源 mml.ps1 为 Release 附件；GitHub 自动源码归档只含跟踪文件，不附任何游戏或 Java 文件。
- SECURITY 私密报告入口须创建仓库后检查 / 启用，目前不声称已启用，不编造邮箱。

必须先展示账户、全部文件、完整 LICENSE、审查、测试及提交，再等待作者明确回复 **确认公开发布**，才创建 Public 仓库、Push main / v0.2.5、发布公开 Release。禁止强制 Push、覆盖历史或未经批准变更现有仓库可见性。当前没有已发布地址。

本地准备提交使用中性身份 `MML local preparation <mml-local@localhost>`，不是作者真实邮箱，版权署名与 Git 提交身份不同。没有修改全局 Git 配置。旧开发目录、原文件和历史均保留。0.2.5 后仅计划修复 Bug 和严重安全问题。
