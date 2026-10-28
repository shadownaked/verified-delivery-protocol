# .repo-meta — 仓库管理元信息（非模板内容）

> 本目录及其中所有文件**不属于模板主体**。
> 模板本体是仓库根目录下的 `AGENTS.md`、`ENGINEERING.md`、`STATE.md`、`docs/`、`scripts/` 等交付物。
> 使用方项目复制本模板后，可直接删除本目录。

## 本仓库的特殊属性：模板源仓库

- 本仓库的内容是 **Verified Delivery Protocol (VDP) 模板**，供其他项目复制使用。
- 因此与普通项目相反：**文件本体必须永远保持模板形态**——保持占位符、空白模板、通用措辞，
  不得填入本仓库自身的阶段、进展、基线、任务记录或任何具体项目信息。
- 允许修改模板内容（完善规范、补充模板、修复文档错误），但修改结果必须仍是"模板"。

## 进展记录方式：只写 commit message

- 本仓库的修改与进展**只体现在 git commit message 中**，commit 历史就是本仓库的 STATE.md。
- 该规则覆盖 `AGENTS.md` 中"收工写 STATE.md"（铁律 F20）的默认要求：
  F20 在本仓库的唯一合法载体是 commit 历史；`STATE.md` 等模板文件保持空白，不填内容。

### 明确禁止写入本仓库历史的模板文件（记录类 / 事实类）

以下文件是**给使用方项目填写**的占位模板，必须保持骨架与占位符，**不得**填入本仓库自身的
版本史、阶段、基线、任务或变更记录：

| 文件 | 保持形态 |
|---|---|
| `STATE.md` | 空白状态机（当前阶段 P_、下一步空、绿色基线空） |
| `CHANGELOG.md` | `## Unreleased` 空分节 + `## <version> - <YYYY-MM-DD>` 占位条目 |
| `docs/PROJECT.md`、`docs/ACCEPTANCE.md`、`docs/BASELINES.md`、`docs/ROADMAP.md`、`docs/RUNBOOK.md`、`docs/BACKLOG.md`、`docs/DESIGN.md` | 空表格 / 空条目 / 待填字段 |
| `evidence/**` | 模板骨架，不含本仓库的真实测量数据 |
| `docs/releases/`、`docs/tasks/`、`docs/decisions/`、`docs/incidents/`、`docs/journal/` | 不预建、不写入本仓库过程记录 |

**本仓库自己的版本变更史**（v1.0 → v1.1 → v1.1.1 → v1.1.2 …）只允许出现在两类位置：
commit message，或本目录（`.repo-meta/`）下的说明文件。**禁止**写入 `CHANGELOG.md` 或任何模板正文。

## 维护纪律

- 提交信息使用清晰的 conventional 风格（如 `docs: ...`、`fix: ...`），正文说明"改了什么、为什么"。
- 本目录之外不得添加本仓库特有的状态、日志或项目信息。
- 秘密（token / 凭据）不得写入任何文件；推送认证走 Git Credential Manager。
- 远端：`https://github.com/shadownaked/verified-delivery-protocol.git`
