你是一个“模板仓库产品经理 + 工程体系设计师 + bash 自动化工程师”。你正在维护仓库 verified-delivery-protocol（VDP），目标是：让任何陌生 agent/开发者打开仓库的第一眼就明白——这是一个【项目模板仓库】而不是一个具体业务项目；并且通过“Template Source / Project Instance 双模式”机制，做到：
- 模板源仓库保持纯模板占位与规范；
- 新项目实例必须显式切换为实例模式，自动触发更严格的“占位符已替换/关键事实已填写”检查；
- 任何人不需要额外口头说明，也不会把 VDP 当成“项目名”而混淆。

############################################
0) 不可妥协目标（Non-negotiables）
############################################
A. 必须实现【双模式】机制（重点）：Template Source vs Project Instance（第5点）。
B. README/入口文档必须“强前置”说明模板属性，降低误用概率。
C. scripts/test.sh（及 build-complete.sh 如适用）必须保持可运行；新增规则必须可机器检查。
D. 保持仓库“模板”属性：不引入特定语言/框架依赖；默认不需要联网。
E. 不提问、不等澄清：遇到不确定点采用“最小但正确”的实现，并在变更报告中说明假设。

############################################
1) 核心设计：.vdp-mode 双模式（必须实现）
############################################
新增根目录文件：
- `.vdp-mode` （被 git 跟踪，纯文本，只有一行）
允许值仅两种（严格匹配）：
- `template-source`
- `project-instance`

默认值要求：
- 在本仓库（模板源仓库）中：`.vdp-mode` 默认必须是 `template-source`

行为要求：
- scripts/test.sh 必须读取 `.vdp-mode` 并执行 mode-specific 检查
- 如果 `.vdp-mode` 不存在或值非法：test 必须 FAIL，并输出如何修复（写明允许值）

新增文档说明（至少一个位置，建议两个）：
- 在 README 顶部加入醒目的模板声明块，明确 `.vdp-mode` 的意义与切换方式
- 新增 `docs/MODES.md`（或同等路径）：详细说明两种模式的意图、检查差异、切换步骤、常见坑

############################################
2) 必须新增的脚本：一键初始化项目实例
############################################
新增脚本（被 git 跟踪，可执行）：
- `scripts/vdp-init-project.sh`

功能要求（非交互式，输出指令即可；可接受参数但不强制）：
1) 把 `.vdp-mode` 从 `template-source` 切换为 `project-instance`
2) 生成/更新一个“实例初始化清单”（最小可用即可）：
   - 在终端输出下一步：需要修改哪些文件（例如 README 标题、docs/PROJECT.md、docs/ACCEPTANCE.md、docs/STATE.md 等）
   - 可选：在 `evidence/` 或 `docs/` 写一个 `INIT_CHECKLIST.md`（若你觉得对可审计更好）
3) 提供“可选清理模板维护目录”的能力：
   - 如果检测到 `.repo-meta/` 存在，提示可删除，并提供参数例如：
     - `--remove-repo-meta`：执行 rm -rf .repo-meta
   - 注意：不能默认就删（避免误删）；但必须提供明确通道

脚本质量要求：
- bash + `set -euo pipefail`
- 输出统一前缀，例如 `VDP-INIT:`，让日志可 grep

############################################
3) scripts/test.sh：加入 mode-specific 强制检查（重点）
############################################
更新 `scripts/test.sh`（或新增 `scripts/vdp-check.sh` 并由 test.sh 调用；任选其一，但最终必须保证 `./scripts/test.sh` 一条命令可完成所有检查）：

### 3.1 通用检查（两种 mode 都要执行）
- `.vdp-mode` 必须存在且值合法
- 必须存在关键制度文件（按你仓库现状列出最核心的；至少 ENGINEERING.md、AGENTS.md、WORKFLOW.md）
- 禁止异常占位符/非法标记（你之前已经做过清理的话，这里要继续保留硬拦截）
- 如果你的 v1.1 已引入 scripts/bench.sh，则检查它存在且可执行（保持你 v1.1 的一致性）

### 3.2 template-source 模式检查（目标：保持“模板纯净”）
在 `.vdp-mode=template-source` 时，至少检查以下“模板纯净性”：
- README 仍然是模板形态：标题/项目名处允许占位（例如“项目名称”/placeholder），并且必须包含【模板声明块】（见第4节）
- 项目事实类文档允许 TBD/占位：例如 docs/PROJECT.md、docs/ACCEPTANCE.md、docs/STATE.md 允许未填满，但必须存在
- 必须存在 `.repo-meta/README.md`（因为这是模板源仓库维护说明；但如果你认为不该强制，也可以仅提示 WARN，不 fail——由你权衡；权衡写入变更报告）

关键点：template-source 不应因为“没填真实项目信息”而 fail。

### 3.3 project-instance 模式检查（目标：防止“用模板开项目但没替换占位”）
在 `.vdp-mode=project-instance` 时，必须更严格，至少检查：
- README 标题不能仍然是占位符（例如不能是“项目名称”）
- docs/PROJECT.md 中“项目名称/目标/范围/MUST”至少有一项不再是占位（你定义一个简单可检查的规则即可，比如检测 [[TODO]] 或 “TBD” 的数量阈值）
- docs/ACCEPTANCE.md 至少存在 1 条明确可验证的验收条件（允许简单的 markdown 列表）
- docs/STATE.md（或你仓库约定的状态文件）必须明确当前阶段（P0–P7 之一）和下一步动作（不是空占位）

实现建议（避免复杂解析）：
- 采用 “禁止占位符字符串” + “要求包含某些关键字段标识且字段非空” 的组合
- 如果你在仓库中已有占位符统一格式（例如 `[[TODO: ...]]`），可以基于它做 grep 规则

输出要求：
- FAIL 时必须给出“最短修复路径”，例如：
  - `Run: ./scripts/vdp-init-project.sh`
  - `Edit: README.md (replace title), docs/PROJECT.md, docs/ACCEPTANCE.md, docs/STATE.md`

############################################
4) README 与入口文档：把“模板属性”前置（必须做）
############################################
更新根目录 README.md：在最顶部加入醒目的模板声明块，必须包含：
- 这是 TEMPLATE REPO（模板仓库），不是业务项目本体
- 生成新项目的推荐路径（Use this template / clone 后 init）
- `.vdp-mode` 的解释：template-source vs project-instance
- `.repo-meta/` 的解释：模板维护用；新项目可删除
- 一句话澄清“VDP 是协议/交付体系，不是你的业务项目名”
  - 推荐表述： “本项目由 VDP v1.1 管理 / This project is managed by VDP v1.1”

同时更新 AGENTS.md（或你的 agent 入口文档）：
- 在阅读顺序中加入 “先识别 .vdp-mode” 的步骤
- 在工作循环中加入：若 project-instance 模式且发现占位未替换，必须停并报告（不要继续编码）

可选但加分：
- 新增 `docs/TEMPLATE.md`（或在 docs/MODES.md 中包含）：集中写“如何从模板生成实例项目”的操作手册（含命令）

############################################
5) .repo-meta 的定位与 gitignore（与你当前做法兼容）
############################################
你目前用 D:\AI\Dev\verified-delivery-protocol\.repo-meta 存放模板修订过程文件并排除过程文件：保持此策略，但要在文档中解释清楚边界：
- `.repo-meta/` 可以存在于模板源仓库中（用于维护模板本身）
- 新项目实例可以删除 `.repo-meta/`
- `.repo-meta/` 中的“过程文件”可以通过 .gitignore 排除（保持仓库干净）
实现要求：
- 确保仓库里至少有 `.repo-meta/README.md`（说明用途与删除策略）
- 更新 FILES.md 或 README 中的“目录说明”，明确 `.repo-meta` 是模板维护元信息而非项目交付内容

############################################
6) 交付物与验收（你最终必须输出）
############################################
你完成后必须提交以下内容（实际改动到仓库）：
新增/修改文件至少包含：
- `.vdp-mode`
- `scripts/vdp-init-project.sh`
- `docs/MODES.md`（或同等文档）
- README.md（模板声明块 + mode说明）
- scripts/test.sh（加入 mode-specific 检查）
- 视情况更新：AGENTS.md / FILES.md / 任何索引文件（保证新文档可达）

并在最终回复中给我一份“PR 风格交付总结”，包含：
1) 变更摘要（为什么改、解决什么困惑）
2) 文件清单（新增/修改）
3) 关键规则说明：两种 mode 各自检查点列表（简明表格最好）
4) 验证方式（可复制命令）：
   - `./scripts/test.sh`
   - `cat .vdp-mode`
   - `./scripts/vdp-init-project.sh`（演示输出）
5) 演示：把 .vdp-mode 改成 project-instance 后，哪些检查会从 PASS 变为 FAIL（用示例说明即可）
6) Known gaps（如果仍有你没覆盖的边界，列出来）

验收标准（任何一条不满足都算未完成）：
- `.vdp-mode` 缺失/非法时，`./scripts/test.sh` 不会失败并提示：不通过
- `project-instance` 模式下仍允许关键占位符不替换并通过：不通过
- README 顶部仍不能一眼看出“这是模板仓库”：不通过
- 没有提供一键 init 脚本或 init 没有指导下一步：不通过
- scripts/test.sh 被破坏无法运行：不通过

现在开始执行：先实现 .vdp-mode + test.sh 分支检查 + vdp-init-project.sh，然后再补文档与 README 串联。