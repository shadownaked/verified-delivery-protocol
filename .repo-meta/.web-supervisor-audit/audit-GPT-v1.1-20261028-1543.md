## 给本地 Agent 的完整 Prompt
你现在在一个 GitHub 模板仓库中工作：`verified-delivery-protocol`（VDP）。该仓库的目标是：成为本地 agent 管理真实项目的“科学化工程交付操作系统”，覆盖全生命周期（从立项→设计→实现→验证→发布→运维→维护/关闭），并通过**不可绕过的规则、阶段门禁（gates）、证据（evidence）、脚本检查**防止“假完成/漂移/不可复现”。

### 你的任务（必须全部完成）
你需要对仓库进行一次**v1.1 修订**，重点解决已知设计漏洞，并补齐“科学化管理骨架”。你必须**直接修改仓库内容**（新增/修改脚本与文档），并保证仓库自洽、可运行、可检查。

---

# A. 非协商原则（Non‑negotiables）
1. **不允许编造**：所有新增流程必须能落到具体文件、脚本、检查点、输出证据上。
2. **不破坏模板的通用性**：VDP是模板仓库，不假设特定语言/框架；脚本要尽量 POSIX shell 兼容（bash 可用但避免依赖冷门工具）。
3. **“证据优先”**：凡是你要求执行的动作（测试/基准/发布准备/风险评估），都要定义“证据应放哪里、长什么样、如何复查”。
4. **“硬依赖必须存在”**：仓库文档中标记为 hard dependency 的脚本/文件，仓库必须真实存在；否则这是系统性缺陷。
5. **完成后必须运行本仓库已有的检查脚本**（如 `scripts/test.sh`，以及任何你新增的检查/生成脚本），并把运行方式写入交付总结。

---

# B. 现存已知缺陷（你要修复）
## B1) `scripts/bench.sh` 缺失（硬缺陷）
仓库文档（如质量/优化相关文档或模板）把 `scripts/bench.sh` 当作硬依赖，但仓库中缺失该文件。你必须：
- 新增 `scripts/bench.sh`（可先做“严格 stub”，但要可执行、可产出证据、可被调用）
- 更新/增强 `scripts/test.sh`：当仓库宣称 `scripts/bench.sh` 为 hard dependency 时，必须检查该文件存在且可执行；必要时也检查它的基本输出契约（见下方“Bench 契约”）
- 对应更新相关文档，保证“硬依赖”表述与现实一致

### Bench 契约（必须实现）
`./scripts/bench.sh` 至少支持以下行为（保持最小可用、跨项目通用）：
- **默认行为**：运行“基准测试入口”，若仓库未配置任何可运行的基准项，必须输出清晰的 `BLOCKED` 或 `NO_BENCHMARKS_CONFIGURED` 信息，并**返回非 0**（建议 exit code 2）——避免“假绿”。
- **证据落盘**：无论成功/失败，都要把一次运行的元信息写入 `.artifacts/bench/` 下的时间戳目录，例如：
  - `.artifacts/bench/2026-10-28T12-30-00Z/meta.json`
  - `.artifacts/bench/2026-10-28T12-30-00Z/summary.md`
- **可被 CI/脚本消费**：标准输出要有稳定前缀（例如 `BENCH:`），失败要有明确原因。
- **可扩展**：允许未来通过一个简单配置文件启用真实基准（例如 `docs/bench/benchmarks.yml` 或 `docs/BASELINES.md` 中的约定路径）。你这次可以只定义契约 + 占位配置文件格式，不要求实现具体语言的基准执行。

> 目标：让优化/性能验证链条不再断裂，并且不会因为“脚本存在但什么都没做”而欺骗 gate。

---

## B2) 清理文档中异常占位标记（硬缺陷）
仓库中存在一些非常规的占位/标记（例如孤立的 `` 这类非标准 Markdown 结构），会干扰阅读、渲染、agent 解析与工具链。你必须：
- 全仓搜索并定位这些异常标记出现的位置（包括但不限于 `_PACKAGE_README.md`、`docs/PROJECT.md` 等）
- 明确它们原本意图：如果是占位符，用**统一、可读、可脚本检测**的占位格式替代（建议用 `[[TODO: ...]]` 或 `<!-- TODO: ... -->`）
- 更新 `scripts/test.sh`（或新增 `scripts/vdp-check.sh` 并由 `scripts/test.sh` 调用）：
  - 禁止再次出现该异常标记（用 grep 规则硬拦截）
  - 同时允许合法的 Markdown 代码块（不要误杀正常的 ```）

> 目标：模板可读、可扩展、可被脚本严格校验。

---

## B3) 证据保全（Evidence retention）不足（结构性缺陷）
当前 `.artifacts/` 更像临时目录，缺少“长期可复查证据”的规定，会破坏科学化可复现与审计能力。你必须补齐一套**最小但完整**的证据保全机制：

- 新增一个长期证据目录（建议：`evidence/` 或 `docs/evidence/`），并写明：
  - 哪些证据必须长期保存（例如：发布基线、验收记录、风险评估摘要、关键实验结论摘要、性能基线摘要、变更窗口/冻结记录）
  - 哪些证据可以临时（`.artifacts/` 原始输出）
  - 从 `.artifacts/` 到长期证据的“摘要提取规则”（例如脚本生成 `evidence/releases/<version>/` 的 summary）
- 更新 `FILES.md`（以及必要的工程文档）来反映该机制，并说明“为什么这样设计（可审计、可复现、可复查）”

> 目标：把“做过”变成“可复查地做过”。

---

# C. 把 VDP 升级为“科学化全生命周期骨架”（新增三块核心能力）
你需要新增/补齐以下三个模块（文档为主，但要能落到 gate/检查/证据）：

## C1) 运营/可靠性：SLO / Error Budget（必须新增）
新增 `docs/engineering/OPERATIONS.md`（或等价路径，保持风格一致），内容必须包含：
- SLI / SLO / Error Budget 的定义（模板化，不绑定具体技术栈）
- **把“速度 vs 稳定性”变成规则**：当错误预算耗尽时，进入变更冻结/仅修复模式（并说明如何解除冻结）
- 与 VDP phases/gates 的映射：例如在 P5/P6 必须确认监控/告警/回滚/演练证据
- 最小证据模板：例如 `evidence/operations/slo.md`、`evidence/operations/error-budget.md` 的占位模板

## C2) 安全工程：按阶段落地（必须新增）
新增 `docs/engineering/SECURITY.md`，要求：
- 以“阶段化安全活动”写法映射到 P0–P7：立项威胁建模、依赖/供应链、密钥与配置、最小权限、审计日志、漏洞响应、发布前安全检查
- 明确哪些项属于 MUST / SHOULD / MAY（和 VDP 风格一致）
- 给出可落盘证据路径建议（例如 `evidence/security/threat-model.md`、`evidence/security/dependency-audit.md`）

## C3) Agent 授权边界：机器可读（必须新增）
新增 `docs/AUTHZ.md`（并建议同时新增 `docs/AUTHZ.yaml` 或 `docs/AUTHZ.json` 作为机器可读版本），内容必须包含：
- **Allowed without approval**（允许 agent 自动做的事）
- **Requires human approval**（必须人工批准：发布生产、花钱、删除数据、接触真实凭证、对外沟通等）
- **Never**（禁止项：外传 secrets、破坏性操作、绕过 gate 伪造证据等）
- 与 `AGENTS.md` 的工作循环对齐：让 agent 在执行任何高风险动作前先检查 AUTHZ

> 目标：把“安全边界”从口头变成硬约束，减少越权与不可控风险。

---

# D. 发布与供应链透明度（最小占位但要自洽）
你需要把发布流程增强为“第三方可验证”的方向（先做模板与字段，不要求集成真实签名系统）：

- 更新发布模板（例如 `docs/templates/release.md` 或现有 release 相关文件）加入字段：
  - 构建输入（commit/tag）
  - 构建环境摘要（可复现性提示）
  - SBOM（占位：路径/生成工具/生成时间）
  - Provenance/Attestation（占位：是否生成、存放路径）
  - 关键依赖/风险提示
- 更新 `docs/BASELINES.md`：除了产品 KPI/性能基线，也要有**工程健康基线**占位（例如交付频率、变更失败率、恢复时间、前置时间等；用“如何测量/证据在哪里”写清楚）

---

# E. 脚本与检查（让规则可被机器执行）
你必须至少完成这些工程化动作：

## E1) 强化 `scripts/test.sh`（或拆分出 `scripts/vdp-check.sh`）
加入/实现以下检查项（以不引入复杂依赖为前提）：
- 确认 `scripts/bench.sh` 存在、可执行（当文档宣称 hard dependency 时）
- 禁止异常占位标记（你要定义明确的禁用模式）
- 检查新引入的关键文档存在：`docs/engineering/OPERATIONS.md`、`docs/engineering/SECURITY.md`、`docs/AUTHZ.md`（以及机器可读 authz 文件，如果你新增了）
- 如果仓库有“完整文档生成”（如 `scripts/build-complete.sh` 生成 `dist/verified-delivery-protocol-complete.md`），你要确保新增文档能被纳入或至少在 README/索引中可达

## E2) 证据目录与忽略策略
- 为 `.artifacts/` 与长期 `evidence/` 设计清晰的 `.gitignore` 策略：
  - `.artifacts/` 通常忽略（可选保留结构）
  - `evidence/` 默认应被版本控制（至少保留模板与示例摘要），但避免放入敏感信息
- 在相关文档中明确“敏感信息禁止入库”的规则

---

# F. 文档串联（让新人/agent 读得懂）
你必须更新 `AGENTS.md`（或等效入口文档），把阅读顺序与执行循环补齐：
- 在 reading order 中加入 AUTHZ / SECURITY / OPERATIONS
- 在工作循环中加入“先检查授权边界，再执行动作；动作产生证据并落盘；最后更新项目事实文档”的强制步骤
- 明确 stop conditions：当 bench 未配置、证据缺失、授权不足时必须停并报告（而不是继续“假完成”）

---

# G. 交付物（你最终必须输出的内容）
你完成修改后，需要给出一个“PR 风格”的交付总结（写在最终回复里），格式必须包含：

1) **变更摘要（What & Why）**：按主题分组说明为什么改、解决了什么漏洞  
2) **文件清单（Changed files）**：列出新增/修改的文件路径  
3) **如何运行验证（How to verify）**：提供可复制的命令清单，例如：
   - `./scripts/test.sh`
   - `./scripts/bench.sh`（展示未配置时的 BLOCKED 行为）
   - `./scripts/build-complete.sh`（如果适用）
4) **证据产物说明（Evidence outputs）**：说明 bench/test 会在 `.artifacts/` / `evidence/` 生成什么  
5) **兼容性说明（Compatibility / Migration notes）**：如果你引入了更严格的检查，说明对现有使用者的影响与迁移策略（但不允许弱化原则）

---

# H. 实施顺序（按这个顺序做，避免返工）
1. 修复硬缺陷：补 `scripts/bench.sh` → 强化 `scripts/test.sh` 检查  
2. 清理异常标记并加脚本硬拦截  
3. 证据保全机制：引入 `evidence/` + 更新 `FILES.md` + 忽略策略  
4. 新增三大模块文档：OPERATIONS / SECURITY / AUTHZ(+yaml/json)  
5. 更新 release/BASELINES 模板（供应链透明度、工程健康基线）  
6. 更新 `AGENTS.md` 串联全链路  
7. 运行所有检查脚本并在交付总结中写清楚结果与命令

---

## 额外硬要求（写代码/脚本时）
- shell 脚本请使用：`set -euo pipefail`（如兼容性允许），输出清晰错误信息
- 输出要可读、可 grep（例如统一前缀：`VDP:` / `BENCH:` / `CHECK:`）
- 不要引入需要联网才能运行的步骤（除非是可选项，并明确标记 OPTIONAL）
- 所有新增文档要有“与 P0–P7 / G0–G6 的映射”小节（哪怕简短）

---

把上述任务全部完成后，再给出最终交付总结（按 G 的格式）。
因为本项目的主体是“模版”项目，因此对“模版”的修改记录不进入“模版”，而单独使用D:\AI\Dev\verified-delivery-protocol\.repo-meta目录（相关文件同理，以便保持“模版”是“模版”属性）。
因此交付总结放入
D:\AI\Dev\verified-delivery-protocol\.repo-meta\.local-agent-docs
其他过程文件酌情在D:\AI\Dev\verified-delivery-protocol\.repo-meta目录下创建