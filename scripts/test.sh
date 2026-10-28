#!/usr/bin/env sh
# VDP — 体系自身完整性自检（铁律 F1 的"绿基线"入口）
#
# 用途：校验本模板包自身没有被改坏。改了任何规范文件后跑一次：
#   sh scripts/test.sh
#
# 设计原则（体系 §"把制度落实成机械约束"）：
#   这些检查项原本是文档里的清单，这里把它们变成脚本。
#   Agent 不必"记住"铁律编号连续性，脚本会替它发现。
#
# 可移植性：只用 POSIX sh + grep/wc/find（BusyBox 兼容）；
#   不用 `grep -r --include`（GNU 扩展，BusyBox grep 不支持，曾导致检查[5]恒红）。
#
# 退出：全部通过 0；任一检查失败非 0，并打印 FAIL 行。
# 结果状态：PASS / FAIL / BLOCKED（缺少必需命令时）

set -u

cd "$(dirname "$0")/.."

PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
no()   { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
chk()  { if [ "$2" = "$3" ]; then ok "$1 ($2)"; else no "$1 (实际 $2 / 期望 $3)"; fi }

# ---- 前置：必需命令 ----
for cmd in grep wc find; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'BLOCKED  缺少必需命令: %s\n' "$cmd"
        exit 2
    fi
done

# 模板主体范围：排除本地目录（.git / dist 产物 / .repo-meta 仓库管理元信息 /
# .screenshots 本地截图 / .artifacts 本地运行产物——它们不属于模板本体）
SCOPE_MD="$(find . -name "*.md" -not -path "./.git/*" -not -path "./dist/*" -not -path "./.repo-meta/*" -not -path "./.screenshots/*" -not -path "./.artifacts/*" | sort)"

echo "=== VDP 体系自检 ==="
echo

# ---- 1. 核心文件存在（缺一个宪法就无从执行） ----
echo "[1] 核心文件存在性"
CORE="ENGINEERING.md AGENTS.md STATE.md README.md CHANGELOG.md .gitignore"
CORE="$CORE docs/PROJECT.md docs/ACCEPTANCE.md docs/BASELINES.md docs/ROADMAP.md docs/RUNBOOK.md docs/BACKLOG.md docs/DESIGN.md"
CORE="$CORE docs/AUTHZ.md docs/AUTHZ.yaml"
CORE="$CORE docs/engineering/WORKFLOW.md docs/engineering/QUALITY.md docs/engineering/FILES.md docs/engineering/BOOTSTRAP_PROMPT.md docs/engineering/OPERATIONS.md docs/engineering/SECURITY.md"
CORE="$CORE docs/bench/benchmarks.yml"
CORE="$CORE scripts/test.sh scripts/build-complete.sh scripts/bench.sh"
CORE="$CORE evidence/README.md evidence/operations/slo.md evidence/operations/error-budget.md evidence/security/threat-model.md evidence/security/dependency-audit.md"
for f in $CORE; do
    if [ -f "$f" ]; then ok "存在 $f"; else no "缺失 $f"; fi
done
echo

# ---- 2. 铁律 F1–F20 连续无缺号 ----
echo "[2] 铁律编号完整性"
N_LAW=$(grep -cE '^- \*\*F[0-9]+' ENGINEERING.md || true)
chk "铁律条数" "$N_LAW" "20"
MISSING_LAW=""
i=1
while [ "$i" -le 20 ]; do
    grep -qE "^- \*\*F$i " ENGINEERING.md || MISSING_LAW="$MISSING_LAW F$i"
    i=$((i+1))
done
if [ -z "$MISSING_LAW" ]; then ok "F1–F20 无缺号"; else no "缺号:$MISSING_LAW"; fi
echo

# ---- 3. 阶段 P0–P7 ----
echo "[3] 阶段编号完整性"
N_P=$(grep -cE '^\| \*\*P[0-9]' ENGINEERING.md || true)
chk "阶段数" "$N_P" "8"
MISSING_P=""
i=0
while [ "$i" -le 7 ]; do
    grep -qE "^\| \*\*P$i " ENGINEERING.md || MISSING_P="$MISSING_P P$i"
    i=$((i+1))
done
if [ -z "$MISSING_P" ]; then ok "P0–P7 无缺号"; else no "缺号:$MISSING_P"; fi
echo

# ---- 4. 门禁清单与发布清单项数 ----
echo "[4] 清单项数（防止有人悄悄删门禁项）"
chk "门禁清单项数" "$(grep -c '^- \[ \]' ENGINEERING.md || true)" "11"
chk "发布清单项数" "$(grep -c '^  - \[ \]' ENGINEERING.md || true)" "5"
echo

# ---- 5. VDP 标识全覆盖（新增文件必须带上体系标识） ----
echo "[5] VDP 标识覆盖（模板主体范围内全部 md）"
TOT=0
HIT=0
MISSING_ID=""
for f in $SCOPE_MD; do
    TOT=$((TOT+1))
    if grep -q "Verified Delivery Protocol" "$f"; then
        HIT=$((HIT+1))
    else
        MISSING_ID="$MISSING_ID $f"
    fi
done
if [ -z "$MISSING_ID" ]; then ok "VDP 标识覆盖 ($HIT/$TOT)"; else no "VDP 标识覆盖 ($HIT/$TOT)，缺标识:$MISSING_ID"; fi
echo

# ---- 6. 合并版产物与源文件一致性（产物过期会被抓出来） ----
echo "[6] 合并版产物新鲜度"
OUT="dist/verified-delivery-protocol-complete.md"
if [ ! -f "$OUT" ]; then
    no "产物不存在（跑 sh scripts/build-complete.sh）"
else
    ok "产物存在"
    # 若任一源文件比产物新，说明产物过期
    STALE=""
    for f in ENGINEERING.md AGENTS.md docs/engineering/WORKFLOW.md docs/engineering/QUALITY.md docs/engineering/OPERATIONS.md docs/engineering/SECURITY.md docs/AUTHZ.md _PACKAGE_README.md; do
        if [ "$f" -nt "$OUT" ]; then STALE="$STALE $f"; fi
    done
    if [ -z "$STALE" ]; then ok "产物未过期"; else no "产物已过期，源更新于:$STALE"; fi
    chk "产物内嵌入文件数" "$(grep -c '<!-- ============ FILE:' "$OUT" || true)" "30"
fi
echo

# ---- 7. 无空壳目录（体系明令禁止预建空目录；仅检查模板主体） ----
echo "[7] 空目录检查（模板主体）"
EMPTY=$(find . -type d -empty -not -path "./.git/*" -not -path "./.repo-meta/*" -not -path "./.screenshots/*" -not -path "./.artifacts/*" 2>/dev/null | tr '\n' ' ')
if [ -z "$EMPTY" ]; then ok "无空目录"; else no "存在空目录:$EMPTY"; fi
echo

# ---- 8. 禁止残留旧名（改名同步的回归保护） ----
echo "[8] 旧名残留（回归保护：改名后不得留旧称）"
OLD=0
for f in $SCOPE_MD; do
    N=$(grep -c "统一开发体系" "$f" || true)
    OLD=$((OLD + N))
done
chk "旧名'统一开发体系'残留数" "$OLD" "0"
echo

# ---- 9. bench 入口契约（scripts/bench.sh 是硬依赖，QUALITY.md §8） ----
echo "[9] bench 入口契约"
if [ -f scripts/bench.sh ]; then ok "存在 scripts/bench.sh"; else no "缺失 scripts/bench.sh"; fi
TMPD=".artifacts/.bench-contract-check"
rm -rf "$TMPD"
mkdir -p "$TMPD"
VDP_BENCH_EVIDENCE_ROOT="$TMPD" sh scripts/bench.sh >"$TMPD/stdout.txt" 2>&1
BENCH_RC=$?
if grep -q '^BENCH:' "$TMPD/stdout.txt"; then
    ok "bench 输出契约（含 BENCH: 前缀行）"
else
    no "bench 输出缺少 BENCH: 前缀行（输出见 $TMPD/stdout.txt）"
fi
case "$BENCH_RC" in
    0|1|2) ok "bench 退出码契约 ($BENCH_RC ∈ {0,1,2})" ;;
    *) no "bench 退出码违约 ($BENCH_RC 不在 {0,1,2})" ;;
esac
if [ "$BENCH_RC" -eq 2 ]; then
    if grep -qE 'NO_BENCHMARKS_CONFIGURED|BLOCKED' "$TMPD/stdout.txt"; then
        ok "bench 未配置时拒绝理由明确"
    else
        no "bench 退出 2 但未说明 NO_BENCHMARKS_CONFIGURED/BLOCKED"
    fi
fi
rm -rf "$TMPD"
echo

# ---- 10. 异常占位标记（孤立的空内联代码；合法代码围栏不误报） ----
echo "[10] 异常占位标记"
BAD_MARK=""
for f in $SCOPE_MD; do
    if grep -qE '(^|[^`])``($|[^`])' "$f"; then BAD_MARK="$BAD_MARK $f"; fi
done
if [ -z "$BAD_MARK" ]; then
    ok '无孤立双反引号标记（占位请用 [[TODO: 说明]]，约定见 FILES.md §2）'
else
    no "孤立双反引号标记出现在:$BAD_MARK"
fi
echo

# ---- 11. 证据目录与忽略策略（evidence/ 入库，.artifacts/ 忽略） ----
echo "[11] 证据目录与忽略策略"
if grep -q '^\.artifacts/' .gitignore; then ok ".artifacts/ 已忽略"; else no ".gitignore 未忽略 .artifacts/"; fi
if grep -qE '^/?evidence/?$' .gitignore; then
    no "evidence/ 被忽略（长期证据必须入库，见 evidence/README.md）"
else
    ok "evidence/ 未被忽略（长期证据入库）"
fi
echo

# ---- 汇总 ----
echo "=== 汇总 ==="
echo "PASS: $PASS    FAIL: $FAIL"
if [ "$FAIL" -ne 0 ]; then
    echo "结果: FAIL —— 禁止在红基线上叠加改动（铁律 F1）"
    exit 1
fi
echo "结果: PASS"
exit 0
