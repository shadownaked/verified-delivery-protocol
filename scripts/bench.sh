#!/usr/bin/env sh
# VDP — 性能基准入口（ENGINEERING.md §3.3 optimization 流程的测量硬依赖）
#
# 契约（详见 docs/engineering/QUALITY.md §8）：
#   - 未配置任何可运行基准 -> 输出 BENCH: NO_BENCHMARKS_CONFIGURED，退出码 2
#     （诚实拒绝：既不是成功，也不是失败；optimization 任务在此状态下不得宣称完成测量）
#   - 已配置基准但执行失败 -> 输出 BENCH: FAIL <名称>，退出码 1
#   - 全部基准执行成功     -> 输出 BENCH: OK <名称>，退出码 0
#   - 每次运行（无论成败）证据落盘：<root>/<UTC时间戳>/{meta.json,summary.md,*.log}
#     root 默认 .artifacts/bench，可用环境变量 VDP_BENCH_EVIDENCE_ROOT 覆盖
#   - 基准通过 docs/bench/benchmarks.yml 声明（格式见该文件头部注释）
#
# 用法：sh scripts/bench.sh
# 退出：0 全部成功；1 有基准失败；2 未配置；3 本脚本自身用法错误
#
# 说明：不用 `set -o pipefail`（非 POSIX，BusyBox sh 不保证支持）；本脚本也无管道依赖。
#       重复次数与中位数规则（≥3 次取中位数）由调用方（optimization 流程）负责，
#       本脚本每次调用执行一遍全部已配置基准。

set -eu

cd "$(dirname "$0")/.."

CONFIG="docs/bench/benchmarks.yml"
EVIDENCE_ROOT="${VDP_BENCH_EVIDENCE_ROOT:-.artifacts/bench}"
TS="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
OUT_DIR="$EVIDENCE_ROOT/$TS"

# 当前提交（证据可追溯用；git 不可用时记 unknown，不阻断）
COMMIT="unknown"
if command -v git >/dev/null 2>&1; then
    COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
fi

mkdir -p "$OUT_DIR"

# ---- 读取基准配置 -------------------------------------------------------
# 只解析 benchmarks.yml 的最小子集（- name: X / run: "Y"），不依赖 YAML 解析器。
# 输出：每行 "name<TAB>run"；name 清洗为 [A-Za-z0-9._-]；run 仅去掉成对包裹引号。
if [ -f "$CONFIG" ]; then
    PAIRS="$(awk -v q="'" '
        function stripq(s,   f, l) {
            if (length(s) >= 2) {
                f = substr(s, 1, 1); l = substr(s, length(s), 1)
                if (f == l && (f == "\"" || f == q)) s = substr(s, 2, length(s) - 2)
            }
            return s
        }
        function flush() { if (cur != "") printf "%s\t%s\n", cur, run }
        /^[[:space:]]*-[[:space:]]*name:[[:space:]]*/ {
            flush()
            cur = $0
            sub(/^[[:space:]]*-[[:space:]]*name:[[:space:]]*/, "", cur)
            cur = stripq(cur)
            gsub(/[^A-Za-z0-9._-]/, "_", cur)
            run = ""
            next
        }
        /^[[:space:]]*run:[[:space:]]*/ {
            s = $0
            sub(/^[[:space:]]*run:[[:space:]]*/, "", s)
            run = stripq(s)
            next
        }
        END { flush() }
    ' "$CONFIG")"
else
    PAIRS=""
fi

TAB="$(printf '\t')"
TOTAL=0        # 声明的条目数
CONFIGURED=0   # run 非空的条目数
FAILURES=0
RESULTS=""     # 每行 "name|PASS或FAIL|秒"

# ---- 执行已配置基准 -----------------------------------------------------
while IFS="$TAB" read -r name run; do
    [ -n "$name" ] || continue
    TOTAL=$((TOTAL + 1))
    [ -n "$run" ] || continue
    CONFIGURED=$((CONFIGURED + 1))
    echo "BENCH: RUN $name"
    T0=$(date +%s)
    if sh -c "$run" >"$OUT_DIR/$name.log" 2>&1; then
        T1=$(date +%s)
        D=$((T1 - T0))
        echo "BENCH: OK $name (${D}s) log=$OUT_DIR/$name.log"
        RESULTS="$RESULTS$name|PASS|$D
"
    else
        RC=$?
        T1=$(date +%s)
        D=$((T1 - T0))
        echo "BENCH: FAIL $name (exit=$RC, ${D}s) log=$OUT_DIR/$name.log"
        RESULTS="$RESULTS$name|FAIL|$D
"
        FAILURES=$((FAILURES + 1))
    fi
done <<EOF
$PAIRS
EOF

if [ "$CONFIGURED" -eq 0 ]; then
    STATUS="NO_BENCHMARKS_CONFIGURED"
elif [ "$FAILURES" -eq 0 ]; then
    STATUS="OK"
else
    STATUS="FAIL"
fi

# ---- 证据落盘：meta.json -------------------------------------------------
{
    printf '{\n'
    printf '  "schema": "vdp-bench/1",\n'
    printf '  "timestamp": "%s",\n' "$TS"
    printf '  "commit": "%s",\n' "$COMMIT"
    printf '  "config": "%s",\n' "$CONFIG"
    printf '  "config_exists": %s,\n' "$([ -f "$CONFIG" ] && echo true || echo false)"
    printf '  "declared": %d,\n' "$TOTAL"
    printf '  "configured": %d,\n' "$CONFIGURED"
    printf '  "failed": %d,\n' "$FAILURES"
    printf '  "status": "%s",\n' "$STATUS"
    printf '  "results": ['
    first=1
    while IFS='|' read -r n st d; do
        [ -n "$n" ] || continue
        if [ "$first" -eq 1 ]; then first=0; else printf ','; fi
        printf '\n    {"name": "%s", "status": "%s", "seconds": %d}' "$n" "$st" "$d"
    done <<EOF
$RESULTS
EOF
    if [ "$first" -eq 0 ]; then printf '\n  '; fi
    printf ']\n}\n'
} > "$OUT_DIR/meta.json"

# ---- 证据落盘：summary.md -------------------------------------------------
{
    echo "# BENCH 运行摘要 — $TS"
    echo
    echo "- 验证对象：性能基准入口 scripts/bench.sh（全部已配置基准）"
    echo "- 代码提交：$COMMIT"
    echo "- 配置文件：$CONFIG（$([ -f "$CONFIG" ] && echo 存在 || echo 不存在)；声明 $TOTAL 项，已配置 $CONFIGURED 项）"
    echo "- 结果状态：$STATUS"
    echo "- 证据目录：$OUT_DIR"
    echo
    if [ "$CONFIGURED" -eq 0 ]; then
        echo "未配置任何可运行基准（$CONFIG 缺失或所有 run 为空）。"
        echo "此状态视同 BLOCKED：optimization 任务（ENGINEERING.md §3.3）不得宣称完成测量。"
        echo "配置方式见 docs/bench/benchmarks.yml 头部注释。"
    else
        echo "| 基准 | 结果 | 耗时(s) |"
        echo "|---|---|---|"
        while IFS='|' read -r n st d; do
            [ -n "$n" ] || continue
            echo "| $n | $st | $d |"
        done <<EOF
$RESULTS
EOF
    fi
} > "$OUT_DIR/summary.md"

# ---- 退出 ---------------------------------------------------------------
if [ "$CONFIGURED" -eq 0 ]; then
    echo "BENCH: NO_BENCHMARKS_CONFIGURED — 在 $CONFIG 声明基准（格式见该文件注释）；契约见 docs/engineering/QUALITY.md §8"
    exit 2
fi
if [ "$FAILURES" -ne 0 ]; then
    echo "BENCH: FAIL — $FAILURES/$CONFIGURED 个基准失败；证据：$OUT_DIR"
    exit 1
fi
echo "BENCH: OK — $CONFIGURED 个基准全部成功；证据：$OUT_DIR"
exit 0
