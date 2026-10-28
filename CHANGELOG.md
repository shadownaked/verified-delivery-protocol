# Changelog

> **Verified Delivery Protocol (VDP) · 可验证交付体系 · v1.1**

记录使用者可感知的变化，不复制全部提交历史。
每条含**动机与回滚点**。逐条功能细节见 `docs/releases/`。

## Unreleased

### Added
### Changed
### Fixed
### Deprecated
### Removed
### Security

## v1.1 - 2026-10-28

依据外部监督审计（`.repo-meta/.web-supervisor-audit/`，模板仓库的仓库管理元信息）进行的体系修订。

### Added
- `scripts/bench.sh`：补齐 optimization 流程（ENGINEERING.md §3.3）缺失的测量硬依赖。契约：未配置基准 → `BENCH: NO_BENCHMARKS_CONFIGURED` 退出码 2（诚实拒绝）；基准失败退出 1；全部成功退出 0；每次运行证据落盘 `.artifacts/bench/<UTC时间戳>/`（meta.json + summary.md + 各基准日志）。
- `docs/bench/benchmarks.yml`：bench 基准声明占位配置（最小 YAML 子集，默认未配置）。
- 长期证据机制 `evidence/`（入库）：`evidence/README.md` 定义临时层（`.artifacts/`）与长期层（`evidence/`）的边界、晋级规则与脱敏要求；预置 operations / security 证据模板 4 份。
- `docs/engineering/OPERATIONS.md`：SLI / SLO / Error Budget 模板化定义；错误预算耗尽 → 变更冻结/仅修复模式及解除条件；P0–P7 与 G0–G6 的映射。
- `docs/engineering/SECURITY.md`：P0–P7 阶段化安全活动（威胁建模、依赖/供应链、密钥、最小权限、审计日志、漏洞响应、发布前检查），MUST/SHOULD/MAY 分级。
- `docs/AUTHZ.md` + `docs/AUTHZ.yaml`：Agent 授权边界三级（allow / ask / never），默认策略 ask；机器可读版与文档版同提交同步。

### Changed
- `scripts/test.sh`：新增 [9] bench 入口契约、[10] 异常占位标记硬拦截、[11] 证据目录与忽略策略；[1] 核心文件清单扩充；[6] 嵌入文件数 27→30。
- `docs/templates/release.md`：新增 §5"构建与供应链透明度"（构建输入、环境摘要、SBOM、Provenance/Attestation、关键依赖风险提示），后续章节顺延重编号。
- `docs/BASELINES.md`：新增 §5 工程健康基线（交付频率、变更失败率、恢复时间、前置时间）及固定测量口径规则。
- `AGENTS.md`：阅读顺序加入 AUTHZ（第 4 位）与 OPERATIONS/SECURITY；工作循环加入"查授权边界"（第 2 步）与"证据落盘晋级"（第 8 步）；停止条件加入授权不足、bench 未配置、证据缺失。
- `docs/engineering/FILES.md`：§2 新增统一占位符约定 `[[TODO: ...]]`；§6 重写为双层证据制度。
- `docs/engineering/QUALITY.md`：§8 补充 bench 入口契约。
- `README.md` / `_PACKAGE_README.md` / `scripts/build-complete.sh`：索引、目录总览、合并清单纳入新文档；协议版本升为 v1.1。

### Fixed
- 预置红基线（开箱即红）：
  - `scripts/test.sh` [5] 使用 GNU 专有 `grep -r --include`，在 BusyBox grep 下静默失败导致 VDP 标识覆盖恒为 0/28；[8] 同样问题造成旧名残留检查假通过。改用 `find` + 逐文件 `grep`（POSIX 可移植）。
  - [7] 空目录检查把本地工作目录（`.repo-meta/`、`.screenshots/` 等）误判为模板空目录；现仅检查模板主体范围。
  - [5]/[7]/[8]/[10] 扫描范围统一排除 `.git`、`dist`、`.repo-meta`、`.screenshots`、`.artifacts`（模板主体 vs 本地目录分离）。

### Compatibility
- `scripts/test.sh` 检查更严（新增 [9][10][11]）。下游项目若沿用本 test.sh，需同步引入 `scripts/bench.sh`、`docs/bench/benchmarks.yml`、`evidence/` 模板与 OPERATIONS/SECURITY/AUTHZ 三份文档；按需裁剪检查项必须记录理由，不得静默删除。
- `scripts/bench.sh` 未配置时退出码 2 属新行为：接入 CI 时应将该步骤配置为"允许退出码 2"（视为 BLOCKED），或先配置真实基准。
- `release.md` 模板章节号 5–12 → 6–13：引用其章节号的下游文档需同步（本包内无外部引用）。

### Known limitations
- `scripts/bench.sh` 的 YAML 解析只支持 `benchmarks.yml` 头部注释声明的最小子集（`- name:` / `run:`），不是通用 YAML 解析器。
- AUTHZ.yaml 尚无工具链自动执行（agent 靠阅读遵守）；机器可读版本先落格式契约。

### Rollback
- 回退到 v1.0 提交（0b0f8ed..9420fe6 范围）；`dist/` 由 `sh scripts/build-complete.sh` 重生成，无需手工恢复。

### Release evidence
- 自检：`sh scripts/test.sh` 全绿（见 `.repo-meta/.local-agent-docs/` 交付总结）；bench 契约三路径（未配置/成功/失败）实测通过。

## v1.0 - 2026-10-28

### Added
- 初始模板包：工程宪法（铁律 20 条 + 八阶段七门 + 四类任务流程）、Agent 入口、状态机、项目事实文档、工程展开（WORKFLOW/QUALITY/FILES/BOOTSTRAP）、任务模板 ×8、`scripts/test.sh` + `scripts/build-complete.sh`、合并版产物。
- 合并自两套体系：[A] 通用项目开发作业规范 v1.0 + [B] 工程宪法体系（裁决记录见 `_MERGE_NOTES.md`）。
