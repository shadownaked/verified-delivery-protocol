#!/usr/bin/env sh
# VDP — 重生成 dist/verified-delivery-protocol-complete.md
#
# 用途：把分散的规范文件合并成一份便携快照，便于
#   - 一次性投喂给本地 agent
#   - 通过 Gist / 私有仓传输（单文件最稳）
#
# 性质：产物，不是权威源。权威源始终是仓库根目录与 docs/ 下的主文件。
#       改了主文件请重跑本脚本；不要直接编辑 dist/ 下的产物。
#
# 用法：sh scripts/build-complete.sh
# 退出：成功 0；产物缺失、为空或过小则非 0（合理性校验：拒绝异常小的"成功"）

set -eu

cd "$(dirname "$0")/.."

OUT="dist/verified-delivery-protocol-complete.md"
MIN_BYTES=50000

FILES="
ENGINEERING.md
AGENTS.md
STATE.md
docs/engineering/WORKFLOW.md
docs/engineering/QUALITY.md
docs/engineering/FILES.md
docs/engineering/BOOTSTRAP_PROMPT.md
docs/PROJECT.md
docs/ACCEPTANCE.md
docs/BASELINES.md
docs/DESIGN.md
docs/ROADMAP.md
docs/RUNBOOK.md
docs/BACKLOG.md
docs/templates/task-feature.md
docs/templates/task-bugfix.md
docs/templates/task-optimization.md
docs/templates/task-refactor.md
docs/templates/adr.md
docs/templates/incident.md
docs/templates/release.md
docs/templates/journal.md
README.md
CHANGELOG.md
.gitignore
_PACKAGE_README.md
_MERGE_NOTES.md
"

# 前置检查：所有源文件必须存在，缺一个就报 BLOCKED 式的明确失败，不静默产出残缺品
MISSING=""
for f in $FILES; do
    [ -f "$f" ] || MISSING="$MISSING $f"
done
if [ -n "$MISSING" ]; then
    echo "FAIL: 缺少源文件 ->$MISSING" >&2
    exit 1
fi

mkdir -p dist

# 头部：声明性质、权威源、重生成方式
cat > "$OUT" <<'HEADER'
# Verified Delivery Protocol (VDP) · 可验证交付体系 · v1.0
## 完整合并版（便携快照）

> **本文件是生成产物，不是权威源。**
>
> - **权威源**：仓库根目录的 `ENGINEERING.md` / `AGENTS.md` / `STATE.md` 与 `docs/` 下各主文件。
> - **本文件的作用**：把上述文件按阅读优先级合并成一份，便于一次性投喂给 agent 或单文件传输。
> - **重生成**：`sh scripts/build-complete.sh`（改了主文件后必须重跑）。
> - **不要直接编辑本文件**：改了会被下次生成覆盖。
>
> 冲突时以 `ENGINEERING.md` 为准 —— 宪法只有一个。

---

## 目录（按阅读优先级）

1. `ENGINEERING.md` — 工程宪法（铁律 F1–F20、P0–P7、四类流程、门禁）**每次开工必读**
2. `AGENTS.md` — Agent 入口与阅读顺序
3. `STATE.md` — 项目状态机
4. `docs/engineering/WORKFLOW.md` — 阶段展开
5. `docs/engineering/QUALITY.md` — 质量与验证
6. `docs/engineering/FILES.md` — 文件系统与命名
7. `docs/engineering/BOOTSTRAP_PROMPT.md` — 三种启动指令
8. `docs/PROJECT.md` → `BACKLOG.md` — 项目事实文件与模板
9. `README.md` / `CHANGELOG.md` / `.gitignore`
10. `_PACKAGE_README.md` / `_MERGE_NOTES.md` — 包说明与合并裁决

---
HEADER

# 逐个追加，带分隔标记
for f in $FILES; do
    printf '\n\n<!-- ============ FILE: %s ============ -->\n\n' "$f" >> "$OUT"
    cat "$f" >> "$OUT"
done

# 合理性校验：非空、大小合理、结构可解析
SIZE=$(wc -c < "$OUT" | tr -d ' ')
N_MARK=$(grep -c '<!-- ============ FILE:' "$OUT" || true)
N_FILES=$(echo "$FILES" | grep -c . || true)

if [ ! -s "$OUT" ]; then
    echo "FAIL: 产物为空" >&2
    exit 1
fi
if [ "$SIZE" -lt "$MIN_BYTES" ]; then
    echo "FAIL: 产物过小（${SIZE}B < ${MIN_BYTES}B），疑似合并失败" >&2
    exit 1
fi
if [ "$N_MARK" -ne "$N_FILES" ]; then
    echo "FAIL: 分隔标记数 ${N_MARK} != 源文件数 ${N_FILES}" >&2
    exit 1
fi

echo "PASS: $OUT"
echo "  字节数: ${SIZE}"
echo "  嵌入文件: ${N_MARK}/${N_FILES}"
