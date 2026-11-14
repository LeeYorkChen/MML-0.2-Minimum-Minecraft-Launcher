# 版权与来源审查（发布门禁）

审查对象为全部候选文件，不包含 .git 内部元数据；清单见 PUBLISHING.md。生产源码与原最终 0.2.5 的 SHA-256 相同：`31728321D2B89F07566BF4AAEEF544BBDD897E81B43999120FB651CFFE5C595F`。

## 已查证与限制

- 人工阅读生产脚本、测试和文档，检查文件类型、版权头、依赖、网址、个人路径和认证信息；未发现打包的第三方源码库、二进制、游戏资源、私钥或真实认证 Token。
- 本地迭代记录可见 PowerShell / .NET 实现逐步演化，测试核心从当前生产源码派生，HTTP 桩来自本地开发测试。它说明本地演化关系，不能独立证明最初代码来源。
- 技术思路（并发 Worker、HashSet、流式 Hash）、标准算法（OfflinePlayer UUID）及官方元数据字段相同，本身不是直接复制源码的证据；变量改名、跨语言翻译也不能自动排除改编。
- 已核对 [HMCL 仓库与许可证](https://github.com/HMCL-dev/HMCL)、[HMCL Arguments 源文件](https://github.com/HMCL-dev/HMCL/blob/main/HMCLCore/src/main/java/org/jackhuang/hmcl/game/Arguments.java) 和 [SJMCL 仓库声明](https://github.com/UNIkeEN/SJMCL)。它们声明 GPLv3 及附加要求，不能把其中受保护代码直接改标 MIT。没有对它们全部历史源码进行穷尽相似性比对。
- 作者提供准确链接 [sammwyy/InlineMC](https://github.com/sammwyy/InlineMC)，并确认项目从零创建、主要由本助手编写，作者本人没有复制第三方代码。这是开发来源陈述，不是对 AI 输出原创性的自动保证。
- 已阅读 InlineMC 的 launch.ps1，核对提交 `e97354fc1cbc8311867d423da96312375912d2a8`。它依赖服务端计划文件；MML 直接解析官方 JSON，下载、参数与解压实现不同。未发现长度至少 45 字符的相同去首尾空白行；这只是辅助筛查，不是版权鉴定。GitHub 返回 license=null，根目录未见 LICENSE，不能将它当作可任意复制的 MIT 项目。参考源码仅留在非发布工作目录，未执行或收录。
- 本地未发现能具体归属 HMCL / SJMCL 的复制片段；没有据此写“保证不存在第三方代码”。AI 生成也不证明原创性，搜索引擎不能覆盖私有、未索引、历史或改名的代码。

## 原待核实范围与当前结论

| 路径 | 待核实内容 / 片段 | 可能来源与许可证 | 当前决定 |
| --- | --- | --- | --- |
| src/mml.ps1 | 最初实现、Quote-Argument、UUID、Rules、Java 与下载核心 | 本地演化记录及作者从零开发陈述；未找到可归属的第三方复制片段 | 原样保留，当前证据未发现必须单独停发的片段 |
| tests/fixtures/HttpStub.cs | HTTP 故障桩 | 本地开发测试，未发现外部依赖、第三方版权头或复制片段 | 原样纳入候选 |
| tests/TestHelpers.ps1、tests/run-tests.ps1、tests/safety-cases.ps1 | 派生测试及本地逻辑 | 本地项目与本轮整理 | 原样纳入候选 |

当前没有确证的第三方组件需要新增 NOTICE，没有为规避版权问题删除、重写或重新许可片段。MIT 不是重授权第三方 GPL / LGPL / MPL 内容的依据。作者陈述、实际阅读及定向核查支持继续本地发布准备；不能保证排除全部未知来源风险，也不是法律鉴定。如后续出现具体复制或授权疑点，立即暂停相关文件发布交作者决定。公开仍须最终清单批准。

## 授权范围

作者确认版权署名为 `leeyorkchen`，年份 2026。MIT 只适用于 MML 有权授权的实现和文档。Minecraft、Mojang、Microsoft 的商标及其他知识产权不由此授权；运行时下载的 Minecraft、Assets、Libraries、Native 和 Java 没有包含在候选仓库中，各自许可不变。

LICENSE 使用标准 MIT 正文，参照 [SPDX MIT 文本](https://raw.githubusercontent.com/spdx/license-list-data/main/text/MIT.txt)，仅替换版权行。无第三方许可证被主动删除或改写。
