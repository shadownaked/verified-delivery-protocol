# 项目名称

> **Verified Delivery Protocol (VDP) · 可验证交付体系 · v1.2**

> **TEMPLATE REPO / 模板仓库声明**
>
> - **本仓库是模板源仓库（TEMPLATE REPO），不是业务项目本体**：内容是可复制的
>   工程规范模板。VDP 是协议 / 交付体系的名称，**不是你的业务项目名**。
> - **用本模板开新项目**：复制或 clone 本仓库后运行 `sh scripts/vdp-init-project.sh`
>   （切换模式并输出必改文件清单），随后按 `docs/MODES.md` 填写项目事实。
> - **`.vdp-mode`**：单行模式开关——`template-source`（模板源，占位符合法）
>   或 `project-instance`（项目实例，`scripts/test.sh` 强制检查占位已替换、
>   关键事实已填写）。
> - **`.repo-meta/`**：模板维护元信息，不属于模板主体，项目实例可删除
>   （边界见 `docs/MODES.md` §5）。
> - 项目实例应把本声明块替换为一句话：**本项目由 VDP v1.2 管理**
>   （This project is managed by VDP v1.2）。

一句话说明：它为谁解决什么问题。

## 状态

- 开发协议：**VDP v1.2**（Verified Delivery Protocol / 可验证交付体系）
- 当前版本：
- 当前阶段：P_
- 当前成熟度：实验 / 可试用 / 已发布 / 停止维护
- 支持环境：
- 主要限制：

## 能做什么

-

## 不做什么

-

## 快速开始

### 前置条件

列出真实需要的运行环境、权限和依赖。

### 安装

填写已经实际验证的命令，不保留伪命令。

### 配置

说明配置来源、必需项、默认值和秘密信息处理方式。

### 最小使用示例

给出一个可直接验证的真实场景。

### 预期结果

说明成功后应看到什么。

## 常见使用方式

-

## 错误、超时与失败

- 如何识别失败：
- 错误信息或退出状态：
- 哪些情况可以重试（有次数上限）：
- 哪些情况需要人工处理：
- 如何避免重复副作用：

## 数据与安全

- 保存哪些数据：
- 保存在哪里：
- 哪些内容会发送到外部：
- 如何清理：
- 需要哪些权限：

## 验证与开发

| 操作 | 实际命令 | 包含范围 |
|---|---|---|
| 安装依赖 | _（本模板包无运行时依赖，仅需 sh / grep / find / wc）_ | — |
| 全量测试 | `sh scripts/test.sh` | 运行模式（.vdp-mode 分支检查：模板纯净性 / 实例占位已替换）、核心文件存在性、铁律 F1–F20 连续、阶段 P0–P7、门禁/发布清单项数、VDP 标识覆盖与主体规模下限、产物新鲜度（覆盖全部清单源）、空目录、旧名残留、bench 入口契约（隔离配置，不跑真实基准）、异常占位标记、证据目录与忽略策略 |
| 构建合并版 | `sh scripts/build-complete.sh` | 重生成 `dist/verified-delivery-protocol-complete.md` |
| 初始化项目实例 | `sh scripts/vdp-init-project.sh` | 切换 `.vdp-mode` 为 `project-instance` 并输出必改文件清单；`--remove-repo-meta` 可选清理模板维护目录 |
| 性能测量 | `sh scripts/bench.sh` | bench 契约入口：未配置基准时输出 `BENCH: NO_BENCHMARKS_CONFIGURED` 并以退出码 2 诚实拒绝（本包为文档型体系，无可测运行时性能，属预期状态）；基准声明见 `docs/bench/benchmarks.yml` |

说明哪些验证需要真实环境或额外权限：**本包全部验证均离线可执行，无需真实环境或额外凭据。**

`scripts/test.sh` 即铁律 F1 所指的"绿基线"入口——改任何规范文件后先跑它，红了先修再前进。

## 升级与回退

-

## 故障排查

按症状给出具体检查步骤，不只写"重新安装试试"。详见 `docs/RUNBOOK.md`。

## 已知限制

-

## 项目文档

- 工程宪法：ENGINEERING.md
- Agent 入口：AGENTS.md
- 当前状态：STATE.md
- 双模式机制：docs/MODES.md（template-source / project-instance）
- 授权边界：docs/AUTHZ.md（机器可读版：docs/AUTHZ.yaml）
- 项目合同：docs/PROJECT.md
- 验收 KPI：docs/ACCEPTANCE.md
- 指标基线：docs/BASELINES.md
- 路线图：docs/ROADMAP.md
- 运行手册：docs/RUNBOOK.md
- 安全工程：docs/engineering/SECURITY.md
- 运营可靠性：docs/engineering/OPERATIONS.md
- 长期证据：evidence/README.md
- 版本变化：CHANGELOG.md
- 完整合并版（便携快照）：dist/verified-delivery-protocol-complete.md

## 维护与许可

只声明已明确授权的许可和维护承诺。
