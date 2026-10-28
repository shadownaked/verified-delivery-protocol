# 双模式机制（MODES）— Template Source 与 Project Instance

> **Verified Delivery Protocol (VDP) · 可验证交付体系 · v1.2**

> VDP 是"协议 / 交付体系"的名称，**不是任何业务项目的名字**。
> 本文件说明 `.vdp-mode` 两种模式的意图、检查差异、切换步骤与常见坑。
> 对应铁律：F1 绿基线、F5 不谎报、F15 不用占位冒充。

## 1. 为什么需要双模式

VDP 模板源仓库与"复制模板而生的项目实例"对占位符的合法性判定相反：

- **模板源（template-source）**：占位符是本体。`README` 标题 `# 项目名称`、
  空 KPI 表、空 STATE 都是**正确形态**，不得因为"没填真实项目信息"而判红。
- **项目实例（project-instance）**：占位符是未完成。"用模板开了项目但没替换
  占位"必须被 `scripts/test.sh` 判红，防止占位逻辑冒充真实项目（F15）。

同一条检查无法同时服务两种相反的判定，因此用 `.vdp-mode` 显式声明当前身份，
由 `scripts/test.sh` 据此切换检查集。

## 2. `.vdp-mode` 文件

- 位置：仓库根目录；git 跟踪；纯文本，仅一行。
- 允许值（严格匹配，无空白容忍）：`template-source` 或 `project-instance`。
- 缺失或值非法：`scripts/test.sh` 检查 [0] 直接 FAIL，并输出允许值与修复方式。
- 模板源仓库默认 `template-source`；实例化切换只通过 `scripts/vdp-init-project.sh`。
- `vdp-init-project.sh` 对**非法值拒绝执行**（`VDP-INIT: ERROR`，exit 1）且不改文件：
  非法值意味着检出物处于未知状态，静默覆盖等于未经确认改写用户文件。修正方式为
  手工把 `.vdp-mode` 改为允许值之一后重跑脚本。

## 3. 检查差异（scripts/test.sh）

### 3.1 通用检查（两种模式都执行）

| 检查 | 所在检查项 |
|---|---|
| `.vdp-mode` 存在且值合法 | [0] |
| 核心制度文件存在（ENGINEERING / AGENTS / WORKFLOW / MODES 等） | [1] |
| 铁律 F1–F20、阶段 P0–P7、门禁与发布清单项数 | [2] [3] [4] |
| VDP 标识覆盖与主体规模下限 | [5] |
| 空目录 / 旧名残留 / bench 入口契约 / 异常占位标记 / 证据目录策略 | [7]–[11] |

合并版产物（[6]）两种模式语义不同：

- **template-source**：必须存在且新鲜；清单源数固定为 38，产物内嵌数量必须与清单相等（硬断言）。
- **project-instance**：dist 不是实例的维护义务，**所有** dist 相关判定统一为提示——
  缺失计 N/A；数量不一致、源文件缺失、产物过期均 WARN。它们通常是同一根因
  （裁剪文档后未重生成）的不同表现，单独判硬失败会把诊断指向错误方向。
  需要便携快照时重跑 `sh scripts/build-complete.sh`，不需要可删除 `dist/`。

### 3.2 template-source 专属（目标：模板纯净性）

| 检查 | 规则 |
|---|---|
| README 标题保持占位 | 第一个 `# ` 标题必须仍是 `# 项目名称`（**精确相等**） |
| README 含模板声明块 | 必须包含 `TEMPLATE REPO` 声明块，且说明 `.vdp-mode` |
| `.repo-meta/README.md` | 存在则 PASS；不存在仅 **WARN**（不计 FAIL），权衡理由见 §6 |

标题检查**刻意严于审计**（审计只要求"允许占位"）：`# 项目名称` 是实例侧识别
"标题未替换"的唯一锚点，锚点漂移会让实例检查同时失效（假绿）。代价是
"保留 template-source 但改了标题"的 fork 会判红——这属于刻意的显式 diff：
要改标题就应实例化（跑 `vdp-init-project.sh`），而不是停在模板源身份下改形态。

template-source 模式**不会**因为项目事实文档（PROJECT / ACCEPTANCE / STATE 等）
未填写而 FAIL——它们存在即可（存在性由检查 [1] 覆盖）。

### 3.3 project-instance 专属（目标：防止占位未替换）

| 检查 | 机器可判定的最小规则 |
|---|---|
| README 标题已替换 | 第一个 `# ` 标题不得仍是 `# 项目名称` |
| README 模板声明块已移除 | 不得再包含 `TEMPLATE REPO` 声明块 |
| README 保留 VDP 归属 | README 内必须出现字符串 `VDP`（审计 §4 要求落一句"本项目由 VDP 管理"；只查归属字符串，不绑定措辞与版本号） |
| PROJECT.md 有实料 | 至少一行 `- REQ-编号：` 冒号后有非空内容（MUST 要求已开始填写） |
| ACCEPTANCE.md 有实料 | `## 1. KPI 表` 分节内至少一行：首列非空且非表头/非分隔线的表格行，或带内容的列表项 |
| STATE.md 指明阶段 | 存在 `## 当前阶段：P0`–`P7` 之一的行 |
| STATE.md 有下一步 | `## 下一步` 分节内至少一条冒号/点号后有内容的编号项 |

以上是**下限不是上限**：实例项目仍应按 `docs/PROJECT.md`、`docs/ACCEPTANCE.md`
的完整模板填写；机器检查只兜住"完全没填就宣称开工"的假绿。
FAIL 输出附带最短修复路径：`sh scripts/vdp-init-project.sh`（重新查看清单）
与逐文件的 Edit 提示。

## 4. 切换步骤（Template Source -> Project Instance）

1. 完整复制或 clone 模板源仓库（含 `.vdp-mode`）。
2. 运行 `sh scripts/vdp-init-project.sh`：
   - `.vdp-mode` 切换为 `project-instance`（若原值非法则报错退出、不改文件，见 §2）；
   - 终端输出必改文件清单（README / PROJECT / ACCEPTANCE / STATE 优先）。
3. 按清单把模板占位替换为项目事实；README 保留一句
   "本项目由 VDP v1.2 管理 / This project is managed by VDP v1.2"。
4. 运行 `sh scripts/test.sh`，全绿后才进入正常开发循环（AGENTS.md §4）。

可选清理：`sh scripts/vdp-init-project.sh --remove-repo-meta`
删除模板维护目录 `.repo-meta/`。该操作不可恢复，脚本**绝不默认执行**。

反向切换（instance 改回 template-source）：直接编辑 `.vdp-mode` 即可，
但已填入的项目事实不会被自动还原——需要还原请走 git 历史。

## 5. `.repo-meta/` 的边界

- 只应存在于模板源仓库，存放模板自身的维护说明与修订依据。
- **不属于模板主体，也不是项目交付内容**；项目实例可整体删除。
- 其中的本地过程文件通过 `.gitignore` 排除（如 `.repo-meta/.local-agent-docs/`），
  保持仓库干净；入库部分（如 `README.md`、审计依据）是模板源的维护记录。
- 删除它不影响 `scripts/test.sh` 判定：template-source 模式下缺
  `.repo-meta/README.md` 只提示 WARN（见 §6）。

## 6. 已知权衡与常见坑

- **`.repo-meta/README.md` 判 WARN 不判 FAIL**：`.repo-meta/` 被明确设计为
  可删除的维护目录，模式契约只约束模板主体；若判 FAIL，会强迫"fork 后仍当
  模板源用"的仓库保留一个文档里声明可删的目录，规则自相矛盾。
- **合并版 [6] 在 instance 模式全部降为提示**：实例填写 PROJECT / ACCEPTANCE /
  STATE 等文件后，这些源文件必然新于模板携带的 `dist/` 快照——若照搬
  template-source 的严格判定，实例将永远红基线。合并版是模板源的交付物，
  实例缺失计 N/A；数量不一致、源缺失、过期**均**为 WARN。数量不一致与
  "过期"是同一根因（裁剪后未重生成）的不同表现，因此不做部分硬判——
  否则同一次操作会得到互相矛盾的诊断信号。
- **SCOPE_MIN_FILES = 30**：实例项目裁剪文档后，主体 md 数量可能低于下限，
  检查 [5] 会 FAIL。这是**刻意的显式 diff**：裁剪文档属于收紧模板范围，
  应同步调整 `scripts/test.sh` 中的 `SCOPE_MIN_FILES` 并在提交信息里说明，
  不允许静默降级。
- **占位符格式**：统一用 `[[TODO: 说明]]`（约定见
  `docs/engineering/FILES.md` §2）。机器检查只覆盖关键文件的关键占位，
  不追求全量替换检测。
- **README 声明块的替换**：实例应把 TEMPLATE REPO 声明块改写为一句话，
  例如"本项目由 VDP v1.2 管理 / This project is managed by VDP v1.2"——
  VDP 是协议名，不是项目名。该句由检查强制要求（只查 `VDP` 字符串，
  不校验版本号与措辞）。
  该断言是**下限**，独立检出力有限：检查 [5] 本就要求各 md 含
  `Verified Delivery Protocol`，而模板 README 的协议行同时含 `(VDP)`，
  因此沿用协议行、不写任何归属句的实例也会通过；断言只兜住"保留全称、
  删掉缩写"一类漏写。归属句的措辞质量仍需人工审查。
- **`.vdp-mode` 与"项目名"无关**：它声明的是"这份检出物是谁"（模板源还是
  实例），不是项目叫什么；项目名在 README 与 `docs/PROJECT.md` 里。
- **测试替身不适用**：模式检查读取的是仓库静态事实，无需运行环境；
  不要为了"让实例检查通过"去改 `.vdp-mode` 回 template-source——那是把
  未完成伪装成合法，违反 F15。
