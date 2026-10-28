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

## 维护纪律

- 提交信息使用清晰的 conventional 风格（如 `docs: ...`、`fix: ...`），正文说明"改了什么、为什么"。
- 本目录之外不得添加本仓库特有的状态、日志或项目信息。
- 秘密（token / 凭据）不得写入任何文件；推送认证走 Git Credential Manager。
- 远端：`https://github.com/shadownaked/verified-delivery-protocol.git`
