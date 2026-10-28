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
# 退出：全部通过 0；任一检查失败非 0，并打印 FAIL 行。
# 结果状态：PASS / FAIL / BLOCKED（缺少必需命令时）

set -u

cd "$(dirname "$0")/.."

PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
no()   { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
chk()  { if [ "$2" = "$3" ]; then ok "$1 ($2)"; else no "$1 (实际 $2 / 期望 $3)"; fi; }

# ---- 前置：必需命令 ----
for cmd in grep wc find; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'BLOCKED  缺少必需命令: %s\n' "$cmd"
        exit 2
    fi
done

echo "=== VDP 体系自检 ==="
echo

# ---- 1. 核心文件存在（缺一个宪法就无从执行） ----
echo "[1] 核心文件存在性"
CORE="ENGINEERING.md AGENTS.md STATE.md README.md CHANGELOG.md .gitignore"
CORE="$CORE docs/PROJECT.md docs/ACCEPTANCE.md docs/BASELINES.md docs/ROADMAP.md docs/RUNBOOK.md docs/BACKLOG.md docs/DESIGN.md"
CORE="$CORE docs/engineering/WORKFLOW.md docs/engineering/QUALITY.md docs/engineering/FILES.md docs/engineering/BOOTSTRAP_PROMPT.md"
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
echo "[5] VDP 标识覆盖"
TOT=$(find . -name "*.md" -not -path "./dist/*" | wc -l | tr -d ' ')
HIT=$(grep -rl "Verified Delivery Protocol" --include="*.md" . 2>/dev/null | grep -v "^./dist/" | wc -l | tr -d ' ')
chk "含 VDP 标识的 md 文件数" "$HIT" "$TOT"
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
    for f in ENGINEERING.md AGENTS.md docs/engineering/WORKFLOW.md docs/engineering/QUALITY.md _PACKAGE_README.md; do
        if [ "$f" -nt "$OUT" ]; then STALE="$STALE $f"; fi
    done
    if [ -z "$STALE" ]; then ok "产物未过期"; else no "产物已过期，源更新于:$STALE"; fi
    chk "产物内嵌入文件数" "$(grep -c '<!-- ============ FILE:' "$OUT" || true)" "27"
fi
echo

# ---- 7. 无空壳目录（体系明令禁止预建空目录） ----
echo "[7] 空目录检查"
EMPTY=$(find . -type d -empty -not -path "./.git/*" 2>/dev/null | tr '\n' ' ')
if [ -z "$EMPTY" ]; then ok "无空目录"; else no "存在空目录:$EMPTY"; fi
echo

# ---- 8. 禁止残留旧名（改名同步的回归保护） ----
echo "[8] 旧名残留（回归保护：改名后不得留旧称）"
OLD=$(grep -rn "统一开发体系" --include="*.md" . 2>/dev/null | grep -v "^./dist/" | wc -l | tr -d ' ')
chk "旧名'统一开发体系'残留数" "$OLD" "0"
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
