# Verified Delivery Protocol（VDP）· 可验证交付体系 — 模板包说明

> **Verified Delivery Protocol (VDP) · 可验证交付体系 · v1.1**

> 本文件是**模板包自身的说明**，不属于规范体系，进项目后可删除。
> 合并自两套体系：[A] 通用项目开发作业规范 v1.0 + [B] 工程宪法体系。
> **每项取舍与新增内容见 `_MERGE_NOTES.md`。**

---

## 一、设计哲学

1. **把判断变成程序**：能写成脚本检查的，不写成清单；能写成清单的，不靠 agent 临场发挥。本地 agent 不缺代码能力，缺的是"纪律外置"。
2. **唯一证据是运行结果**：测试输出、日志、测量数字。模型的自我评估（"我觉得修好了""应该更快了"）一律不算证据。
3. **仓库永远绿色可交付**：系统任何时刻都处于"可演示"状态，而不是"快好了"状态。

---

## 二、目录总览

```text
project-root/
├── README.md                  # 面向使用者的现状与快速开始（必须与实际一致）
├── ENGINEERING.md             # 【宪法】铁律 20 条 + 八阶段 + 四类流程 + 门禁（agent 每次必读）
├── AGENTS.md                  # 【入口】阅读顺序、工作循环、停止条件、完成汇报
├── STATE.md                   # 【状态机】当前阶段 / 进行中 / 下一步 / 阻塞 / 绿色基线
├── CHANGELOG.md               # 面向人的变更史（每条含动机与回滚点）
├── .gitignore
├── <语言/框架配置文件>、<依赖锁文件>
│
├── src/                       # 按语言惯例；技术栈有原生布局时优先用原生
├── tests/
│   ├── unit/  integration/  acceptance/  regression/
│   └── golden/                # 黄金回归场景（只增不减）
├── scripts/                   # 【硬依赖】setup / dev / test / bench / release
│
├── docs/
│   ├── PROJECT.md             # 项目合同（已并入 charter 立项书）
│   ├── ACCEPTANCE.md          # 验收 KPI 与红线（可测量的 Done）
│   ├── BASELINES.md           # 指标基线记录表（含工程健康基线；反退化数据基础）
│   ├── DESIGN.md              # 设计说明（简单项目可并入 PROJECT）
│   ├── ROADMAP.md             # 八阶段与门的状态
│   ├── RUNBOOK.md             # 运行 / 测试 / 发布 / 回滚手册（须演练）
│   ├── BACKLOG.md             # 一切"顺手想到的"都进这里，不进代码
│   ├── AUTHZ.md               # Agent 授权边界（allow / ask / never）
│   │                          #   机器可读版：AUTHZ.yaml（两者同提交同步改）
│   │
│   ├── bench/
│   │   └── benchmarks.yml     # bench 基准声明（scripts/bench.sh 输入；默认未配置）
│   │
│   ├── engineering/
│   │   ├── WORKFLOW.md        # 阶段展开（含 S→P 映射表、存量接入协议）
│   │   ├── QUALITY.md         # 质量与验证展开（含 bench 入口契约）
│   │   ├── FILES.md           # 文件系统、命名、Git、依赖、秘密、双层证据制度
│   │   ├── OPERATIONS.md      # 运营与可靠性（SLI / SLO / Error Budget）
│   │   ├── SECURITY.md        # 安全工程（P0–P7 阶段化安全活动）
│   │   └── BOOTSTRAP_PROMPT.md  # 启动指令（新项目 / 存量接入 / 精简模式）
│   │
│   ├── templates/
│   │   ├── task-feature.md
│   │   ├── task-bugfix.md
│   │   ├── task-optimization.md
│   │   ├── task-refactor.md
│   │   ├── adr.md
│   │   ├── incident.md
│   │   ├── release.md
│   │   └── journal.md
│   │
│   ├── tasks/                 # TASK-001-短横线名.md（按需创建）
│   ├── decisions/             # ADR-0001-短横线名.md
│   ├── incidents/             # INC-0001-短横线名.md
│   ├── releases/              # v0.1.0.md
│   └── journal/               # YYYY-MM-DD.md
│
├── evidence/                  # 长期证据（入库；本模板预置 README 与 operations/security 模板）
│
├── dist/                      # 生成产物：完整合并版（便携快照，可由主文件重生成）
│   └── verified-delivery-protocol-complete.md
│
└── .artifacts/                # 本地运行产物（bench 证据等），通常不纳入 Git
    ├── logs/  test-results/  benchmarks/  bench/
```

**不要为了符合目录树生成大量空目录、空模块、空文档。** 上述 `tasks/`、`decisions/`、`incidents/`、`releases/`、`journal/`、`golden/`、`.artifacts/` 在本包中均**未预建**。

**唯一例外是 `scripts/`**：它是硬依赖，进项目第一件事就该建（最小可只含一条命令）。

---

## 三、文件清单

| 文件 | 性质 | 说明 |
|---|---|---|
| `ENGINEERING.md` | 固定制度·核心 | 铁律 F1–F20、P0–P7、四类任务流程、收敛协议、会话协议、门禁清单 |
| `AGENTS.md` | 固定制度 | 入口、阅读顺序、工作循环（含授权检查与证据落盘）、停止条件、完成汇报 |
| `STATE.md` | 项目事实 | 状态机，开工读、收工写 |
| `README.md` / `CHANGELOG.md` / `.gitignore` | 项目事实 | 面向使用者 |
| `docs/PROJECT.md` | 项目事实 | 合同 + charter |
| `docs/ACCEPTANCE.md` | 项目事实 | KPI 与红线（3–8 个） |
| `docs/BASELINES.md` | 项目事实 | 基线记录表 + 工程健康基线 |
| `docs/AUTHZ.md` + `docs/AUTHZ.yaml` | 固定制度 | Agent 授权边界（allow / ask / never；人读 + 机器可读） |
| `docs/DESIGN.md` / `ROADMAP.md` / `RUNBOOK.md` / `BACKLOG.md` | 项目事实 | 按需填 |
| `docs/engineering/WORKFLOW.md` | 固定制度 | 阶段展开 |
| `docs/engineering/QUALITY.md` | 固定制度 | 质量验证展开（含 bench 入口契约） |
| `docs/engineering/FILES.md` | 固定制度 | 文件与命名（含双层证据制度） |
| `docs/engineering/OPERATIONS.md` | 固定制度 | SLI / SLO / Error Budget 与变更冻结规则 |
| `docs/engineering/SECURITY.md` | 固定制度 | P0–P7 阶段化安全活动 |
| `docs/engineering/BOOTSTRAP_PROMPT.md` | 固定制度 | 三种启动指令 |
| `docs/bench/benchmarks.yml` | 项目事实 | bench 基准声明（默认未配置） |
| `evidence/README.md` + `evidence/*` 模板 | 固定制度·模板 | 长期证据目录与 operations / security 证据模板 |
| `scripts/test.sh` / `scripts/bench.sh` / `scripts/build-complete.sh` | 固定制度·硬依赖 | 绿基线自检 / 性能基准入口 / 合并版重生成 |
| `docs/templates/*` ×8 | 模板 | feature/bugfix/optimization/refactor/adr/incident/release/journal |
| `dist/verified-delivery-protocol-complete.md` | **生成产物** | 上述全部内容的单文件合并版（便携快照），由主文件重生成，非权威源 |
| `_MERGE_NOTES.md` | 包说明 | 合并裁决，供复核 |
| `_PACKAGE_README.md` | 包说明 | 本文件 |

### 为什么合并版放 `dist/` 而不是根目录、为什么叫 complete 不叫 spec

- **不叫 `-spec.md`**：会与 `ENGINEERING.md` 争夺权威位置。宪法只有一个，再来一个 spec，冲突时 agent 不知道听谁的，违反 §"文档事实的唯一来源"。
- **不叫 `-menu.md`**：menu 是索引，但它是全文，名实不符。
- **叫 `complete`**：准确描述"多文件合并成一份"，一眼看出是派生物而非新权威。
- **放 `dist/`**：它是生成产物不是源码，按 `FILES.md` §1 应与源码分离、可再生。权威源始终是根目录与 `docs/` 下的主文件。

---

## 四、落地步骤

### 新项目
模板入库 → 建 `scripts/test.sh`（哪怕只含一条命令）→ 填 `PROJECT.md`、`ACCEPTANCE.md`（过 G0/G1）→ 走 P2 骨架。

### 存量项目（半路接手，"越改越烂"的局面）——接入协议
1. 若当前 HEAD 已经烂：先切回最稳的 commit/tag。
2. **资产盘点**：跑一遍，列出真正能跑的功能，每条变成一个粗粒度 golden 测试。
3. 粗测当前 KPI，全部记入 `BASELINES.md` —— 第一个可对比基线。
4. 全绿后打 `stable-接盘日期`。
5. 已知坏处与缺失 → 缺陷清单，按收敛协议"修 / 降 / 砍"三选一。
6. 建立真实验证入口（`scripts/test.sh`、`scripts/bench.sh`）。
7. 从此一切变更只走四类任务流程。

详细 11 步见 `WORKFLOW.md` §12。

### 给本地 agent 的启动指令
见 `docs/engineering/BOOTSTRAP_PROMPT.md`，三种场景各一份（新项目 / 存量接入 / 精简模式）。

### 精简模式（小脚本 / 原型）
至少保留 **F1 绿基线、F3 先证伪、F14 卡住即停、F2 回滚优先** + `scripts/test.sh` + `CHANGELOG.md` + `STATE.md`，其余可裁。

---

## 五、痛点 → 机制对应表

| 你遇到的 | 对应机制 |
|---|---|
| 越优化越倒退 | optimization 流程强制 before/after 数字（≥3 次取中位数），无改善即 revert；KPI 恶化 >[10%] 门禁直接不通过 |
| 以前解决的异常处理又丢了 | F11 疤痕不可抠 + golden 只增不减 + F12 断言不许削弱 |
| 卡住只会傻等空耗 | F13 等待必有界（门禁里有 grep sleep/wait/retry/timeout 检查项）+ golden 场景"卡死必须触发恢复路径" |
| 无法收敛、交付不了 | 收敛协议（修/降/砍 + 时间盒）+ P5 阶段禁止新功能 |
| agent 像失忆、降智 | F20 状态外置 + 会话开/收工协议 + journal：不靠记忆，靠 STATE.md |
| 勉强能用就急着"优化" | P3 阶段禁止优化任务；优化是独立任务类型，自带测量义务 |
| 顺手改出一堆无关 diff | F8 一次一事 + BACKLOG 承接新想法 + 门禁 diff 自查 |
| 说"修好了"其实没验证 | F3 先证伪 + F5 不谎报 + 验证结果状态强制 PASS/FAIL/BLOCKED/NOT_RUN/WAIVED |
| 本地跑通就算交付 | F5 + 门 G6：必须用真实交付物在干净环境验收，"代码已 push"不算交付 |
| 多 agent 并行互相踩 | WORKFLOW P4 并行规则：文件所有权 + 隔离分支 + 集成负责人 |

---

## 六、完成判定标准

一个项目不是因为"代码写完了"而完成，而是因为以下问题有明确答案：

1. **目标：**解决谁的什么问题？
2. **范围：**本版本承诺什么，不承诺什么？
3. **合同：**什么结果才算正确？
4. **实现：**是否是真实实现，而非占位或演示？
5. **验证：**有哪些实际执行的证据？
6. **回归：**原本有效的关键能力是否保留？
7. **失败：**异常时是否有边界、明确结果和恢复路径？
8. **交付：**别人能否获取、安装并实际使用？
9. **维护：**出了问题谁接手、依据什么定位？
10. **收敛：**满足什么条件后停止修改并发布？

**把"已验证、可交付、可恢复"作为进度单位，而不是把"又改了多少代码"作为进度单位。**
