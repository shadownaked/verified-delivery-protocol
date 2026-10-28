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
# 可移植性：只用 POSIX sh + grep/wc/find/awk（BusyBox 兼容）；
#   不用 `grep -r --include`（GNU 扩展，BusyBox grep 不支持，曾导致检查[5]恒红）。
#
# 反"假绿"约束（v1.1.1）：
#   任何依赖"枚举集合"的检查（[5][7][8][10]）在集合为空或枚举能力失效时
#   不得判 PASS，必须 FAIL 或 BLOCKED——否则检查器本身会空转成假绿。
#
# 双模式检查（v1.2）：
#   [0] 读取 .vdp-mode（template-source / project-instance）并执行模式专属检查。
#   模板源：占位符是本体，不得因未填写项目事实而 FAIL；
#   项目实例：占位未替换必须 FAIL（防"用模板开项目但没填事实"，F15）。
#   语义与规则见 docs/MODES.md（单一事实源，避免两处漂移）。
#
# 退出：全部通过 0；任一检查失败非 0；缺少必需能力时 2（BLOCKED）。
# 结果状态：PASS / FAIL / BLOCKED / N/A（不适用，仅明示，不计入通过数）
#           另有 WARN：明示但不计 FAIL、不影响退出码（仅 template-source 模式使用）

set -u

cd "$(dirname "$0")/.."

PASS=0
FAIL=0
NA=0
WARN=0

ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
no()   { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
na()   { NA=$((NA+1)); printf 'N/A   %s\n' "$1"; }
warn() { WARN=$((WARN+1)); printf 'WARN  %s\n' "$1"; }
chk()  { if [ "$2" = "$3" ]; then ok "$1 ($2)"; else no "$1 (实际 $2 / 期望 $3)"; fi }

# 模板主体 md 数量下限：低于此值视为"文档缺失或枚举机制失效"（防止空集/半空集假绿）。
# 下游项目裁剪文档后应同步调整该值——这是显式 diff，不允许静默降级。
SCOPE_MIN_FILES=30

git_ok() {
    command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# ---- 前置：必需命令 + 能力探测 ----
for cmd in grep wc find awk; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'BLOCKED  缺少必需命令: %s\n' "$cmd"
        exit 2
    fi
done

# find 能力探测：-name / -not -path 是 GNU 与 BusyBox 共有、Windows find.exe 没有。
# 若 PATH 被 Windows find.exe 抢占，检查 [7] 会静默失效——先探测，探测失败直接 BLOCKED。
if ! find . -name "*.md" -not -path "./dist/*" >/dev/null 2>&1; then
    printf 'BLOCKED  find 缺少 -name / -not -path 能力（可能被非 POSIX 的 find 抢占 PATH）\n'
    exit 2
fi

# 模板主体 md 枚举：
#   有 git 时用 `git ls-files`（受控文件 + 未被忽略的新文件）；无 git 时用 find 全量枚举。
#   两条分支**共用同一份排除表** SCOPE_EXCLUDE_RE，避免"git 分支排除了、find 分支没排除"的语义漂移。
#   注意：`--exclude-standard` 只遵守 git 忽略规则，**不会**天然排除 node_modules/vendor——
#   第三方目录必须由下面的排除表兜底（无论是否被 ignore）。
SCOPE_EXCLUDE_RE='(^|/)(node_modules|vendor|\.crush|\.screenshots|\.artifacts|\.repo-meta|\.git)(/|$)|^dist/'

list_scope_md() {
    if git_ok; then
        git ls-files --cached --others --exclude-standard -- "*.md" 2>/dev/null \
            | grep -vE "$SCOPE_EXCLUDE_RE" | sort
    else
        find . -name "*.md" -not -path "./.git/*" \
            | sed 's|^\./||' | grep -vE "$SCOPE_EXCLUDE_RE" | sort
    fi
}

SCOPE_MD="$(list_scope_md)"
N_SCOPE=$(printf '%s\n' "$SCOPE_MD" | grep -c . || true)

if [ "${N_SCOPE:-0}" -eq 0 ]; then
    printf 'BLOCKED  模板主体 md 枚举为空（git/find 枚举机制失效，禁止对空集判绿）\n'
    exit 2
fi

echo "=== VDP 体系自检 ==="
echo

# ---- 0. 运行模式（.vdp-mode：template-source / project-instance） ----
# 规则单一事实源：docs/MODES.md §3。缺失/非法值必须 FAIL 并给出允许值与修复路径。
# MODE_FAIL 只标记"模式自身不可用"（文件缺失/值非法）；模板源/实例分支里的具体
# 检查失败不算模式问题，汇总段不得把它们误导向"去改 .vdp-mode"。
echo "[0] 运行模式（.vdp-mode）"
VDP_MODE=""
MODE_FAIL=0
if [ ! -f ".vdp-mode" ]; then
    no "缺少 .vdp-mode（修复：模板源 printf 'template-source\\n' > .vdp-mode；项目实例运行 sh scripts/vdp-init-project.sh）"
    printf '      允许值：template-source / project-instance（语义见 docs/MODES.md）\n'
    MODE_FAIL=1
else
    VDP_MODE="$(head -n 1 ".vdp-mode" | tr -d '\r')"
    case "$VDP_MODE" in
        template-source|project-instance)
            ok "模式合法 ($VDP_MODE)"
            ;;
        *)
            no "模式值非法 \"$VDP_MODE\"（允许值：template-source / project-instance；修复：编辑 .vdp-mode，或项目实例运行 sh scripts/vdp-init-project.sh）"
            VDP_MODE=""
            MODE_FAIL=1
            ;;
    esac
fi

if [ "$VDP_MODE" = "template-source" ]; then
    # 模板源专属：占位符是本体。不因项目事实未填写而 FAIL（由 [1] 保证事实文档存在即可）。
    # 标题判定刻意严于审计（审计只要求"允许占位"）：精确要求 `# 项目名称`，
    #   因为该字符串是 instance 模式识别"未替换标题"的唯一锚点——锚点漂移会让
    #   实例侧检查同时失效（假绿）。理由与代价见 docs/MODES.md §3.2。
    README_H1="$(grep -m1 '^# ' README.md 2>/dev/null || true)"
    if [ "$README_H1" = "# 项目名称" ]; then
        ok "README 标题保持模板占位"
    else
        no "README 标题已偏离模板占位（实际 ${README_H1:-<无一级标题>} / 期望 # 项目名称；修复：把一级标题恢复为 '# 项目名称'——它是实例侧判定未替换的锚点；若本检出物要当项目用，改跑 sh scripts/vdp-init-project.sh 并换成真实项目名）"
    fi
    if grep -q 'TEMPLATE REPO' README.md 2>/dev/null; then
        ok "README 含模板声明块（TEMPLATE REPO）"
    else
        no "README 缺少模板声明块（修复：按 docs/MODES.md §6 在 README 顶部恢复 TEMPLATE REPO 声明块）"
    fi
    if grep -q '\.vdp-mode' README.md 2>/dev/null; then
        ok "README 说明 .vdp-mode"
    else
        no "README 未说明 .vdp-mode（修复：在模板声明块中说明两种模式，见 docs/MODES.md）"
    fi
    # 权衡：判 WARN 不判 FAIL——.repo-meta/ 被明确设计为可删除的维护目录（docs/MODES.md §6）
    if [ -f ".repo-meta/README.md" ]; then
        ok ".repo-meta/README.md 存在（模板维护说明）"
    else
        warn ".repo-meta/README.md 不存在（模板维护说明缺失；仅提示——项目实例删除 .repo-meta/ 属预期，见 docs/MODES.md §5）"
    fi
elif [ "$VDP_MODE" = "project-instance" ]; then
    # 项目实例专属：占位未替换必须 FAIL（F15 不用占位冒充）。
    README_H1="$(grep -m1 '^# ' README.md 2>/dev/null || true)"
    if [ "$README_H1" = "# 项目名称" ] || [ -z "$README_H1" ]; then
        no "README 标题仍是占位符（修复：Edit README.md，把 '# 项目名称' 换成真实项目名）"
    else
        ok "README 标题已替换 ($README_H1)"
    fi
    if grep -q 'TEMPLATE REPO' README.md 2>/dev/null; then
        no "README 仍含 TEMPLATE REPO 模板声明块（修复：删除该块，改写为'本项目由 VDP v1.2 管理'一句话，见 docs/MODES.md §6）"
    else
        ok "README 模板声明块已移除"
    fi
    # 审计 §4 的下限要求：实例 README 必须落一句"本项目由 VDP 管理"。
    # 只查字符串 VDP（不绑定具体措辞/版本号），尊重实例自选的表述。
    if grep -q 'VDP' README.md 2>/dev/null; then
        ok "README 保留 VDP 归属说明"
    else
        no "README 无 VDP 归属说明（修复：在 README 顶部加一句'本项目由 VDP v1.2 管理 / This project is managed by VDP v1.2'，见 docs/MODES.md §4）"
    fi
    # 注意：全角冒号必须用字面量匹配——放进方括号表达式会被字节级引擎拆成单字节集合，
    # 冒号自身的剩余字节会被 [^[:space:]] 误判为"已填写内容"（v1.2 演示中实证过的假绿）。
    if grep -qE '^- REQ-[0-9]+：[[:space:]]*[^[:space:]]' docs/PROJECT.md 2>/dev/null \
        || grep -qE '^- REQ-[0-9]+:[[:space:]]*[^[:space:]]' docs/PROJECT.md 2>/dev/null; then
        ok "PROJECT.md 至少一条 MUST 已填写"
    else
        no "PROJECT.md 无已填写的 MUST（修复：Edit docs/PROJECT.md，为 REQ-xxx 填写实际要求）"
    fi
    N_ACC=$(awk '
        /^## 1\. KPI 表/ { f=1; next }
        /^## / { f=0 }
        f && /^\|/ {
            line=$0; sub(/^\|/, "", line); cell=line; sub(/\|.*/, "", cell)
            gsub(/^[ \t]+|[ \t]+$/, "", cell)
            if (cell != "" && cell !~ /^-+$/ && cell != "KPI") n++
            next
        }
        f && (/^- +[^ \t]/ || /^[0-9]+\. +[^ \t]/) { n++ }
        END { print n+0 }' docs/ACCEPTANCE.md 2>/dev/null || true)
    if [ "${N_ACC:-0}" -ge 1 ]; then
        ok "ACCEPTANCE.md 至少一条验收条件 ($N_ACC 条)"
    else
        no "ACCEPTANCE.md 无已填写的验收条件（修复：Edit docs/ACCEPTANCE.md，在 '## 1. KPI 表' 填至少一行真实 KPI 或一条带内容的列表项）"
    fi
    if grep -qE '^## 当前阶段：P[0-7]' STATE.md 2>/dev/null; then
        ok "STATE.md 已指明当前阶段"
    else
        no "STATE.md 未指明当前阶段（修复：Edit STATE.md，'当前阶段' 填 P0–P7 之一）"
    fi
    N_NEXT=$(awk '
        /^## 下一步/ { f=1; next }
        /^## / { f=0 }
        f && /^[0-9]+\. +[^ \t]/ { n++ }
        END { print n+0 }' STATE.md 2>/dev/null || true)
    if [ "${N_NEXT:-0}" -ge 1 ]; then
        ok "STATE.md 下一步非空 ($N_NEXT 条)"
    else
        no "STATE.md 下一步为空占位（修复：Edit STATE.md，至少填一条可执行动作）"
    fi
    printf '      最短修复路径：sh scripts/vdp-init-project.sh（重看清单）；逐文件 Edit 提示见上方各行\n'
fi
echo

# ---- 1. 核心文件存在（缺一个宪法就无从执行） ----
echo "[1] 核心文件存在性"
CORE="ENGINEERING.md AGENTS.md STATE.md README.md CHANGELOG.md .gitignore .vdp-mode"
CORE="$CORE docs/PROJECT.md docs/ACCEPTANCE.md docs/BASELINES.md docs/ROADMAP.md docs/RUNBOOK.md docs/BACKLOG.md docs/DESIGN.md"
CORE="$CORE docs/AUTHZ.md docs/AUTHZ.yaml docs/MODES.md"
CORE="$CORE docs/engineering/WORKFLOW.md docs/engineering/QUALITY.md docs/engineering/FILES.md docs/engineering/BOOTSTRAP_PROMPT.md docs/engineering/OPERATIONS.md docs/engineering/SECURITY.md"
CORE="$CORE docs/bench/benchmarks.yml"
CORE="$CORE scripts/test.sh scripts/build-complete.sh scripts/bench.sh scripts/vdp-init-project.sh scripts/complete-sources.txt"
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

# ---- 5. VDP 标识覆盖 + 主体规模下限（空集/半空集不得判绿） ----
echo "[5] VDP 标识覆盖与主体规模"
TOT=0
HIT=0
MISSING_ID=""
while IFS= read -r f; do
    [ -n "$f" ] || continue
    TOT=$((TOT+1))
    if grep -q "Verified Delivery Protocol" "$f"; then
        HIT=$((HIT+1))
    else
        MISSING_ID="$MISSING_ID $f"
    fi
done <<EOF
$SCOPE_MD
EOF
if [ -z "$MISSING_ID" ]; then ok "VDP 标识覆盖 ($HIT/$TOT)"; else no "VDP 标识覆盖 ($HIT/$TOT)，缺标识:$MISSING_ID"; fi
if [ "$TOT" -ge "$SCOPE_MIN_FILES" ]; then
    ok "主体 md 数量 ($TOT >= $SCOPE_MIN_FILES)"
else
    no "主体 md 数量 ($TOT < 下限 $SCOPE_MIN_FILES；文档缺失或枚举失效)"
fi
echo

# ---- 6. 合并版产物与源文件一致性（比对集合来自清单单一事实源） ----
# template-source：产物必须存在且新鲜（合并版是模板交付物之一）。
# project-instance：合并版可选——缺失 N/A；数量不一致 / 过期 / 缺源**全部**仅 WARN
#   （实例不应承担维护模板快照的义务；需要时可重生成或删除 dist/，见 docs/MODES.md §3.1）。
echo "[6] 合并版产物新鲜度"
OUT="dist/verified-delivery-protocol-complete.md"
SRC_LIST="scripts/complete-sources.txt"
IS_INSTANCE=0
[ "$VDP_MODE" = "project-instance" ] && IS_INSTANCE=1
if [ ! -f "$OUT" ]; then
    if [ "$IS_INSTANCE" = "1" ]; then
        na "产物不存在（instance 模式不强制维护合并版；需要时跑 sh scripts/build-complete.sh）"
    else
        no "产物不存在（跑 sh scripts/build-complete.sh）"
    fi
elif [ ! -f "$SRC_LIST" ]; then
    no "缺失合并清单 $SRC_LIST（无法判定产物覆盖范围）"
else
    ok "产物存在"
    N_SRC=$(grep -c . "$SRC_LIST" || true)
    N_EMB=$(grep -c '<!-- ============ FILE:' "$OUT" || true)
    if [ "$IS_INSTANCE" = "1" ]; then
        # 实例可裁剪清单与文档，且 dist 不是实例的维护义务（docs/MODES.md §3.1）。
        # 因此 dist 相关的**全部**判定在实例模式统一为提示——数量不一致与"源缺失/过期"
        # 是同一根因（裁剪后未重生成）的不同表现，单独判硬失败会让诊断指向错误方向。
        if [ "$N_EMB" = "$N_SRC" ]; then
            ok "产物与清单数量一致 ($N_EMB/$N_SRC)"
        else
            warn "产物与清单数量不一致（实际 $N_EMB / 清单 $N_SRC；instance 模式仅提示——重生成 sh scripts/build-complete.sh 或删除 dist/）"
        fi
    else
        chk "清单源文件数" "$N_SRC" "38"
        chk "产物内嵌入文件数" "$N_EMB" "$N_SRC"
    fi
    # 清单内任一源文件比产物新 -> 产物过期；缺失的源文件单列
    STALE=""
    MISSING_SRC=""
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        if [ ! -f "$f" ]; then
            MISSING_SRC="$MISSING_SRC $f"
        elif [ "$f" -nt "$OUT" ]; then
            STALE="$STALE $f"
        fi
    done <"$SRC_LIST"
    if [ -z "$MISSING_SRC" ]; then
        ok "清单源文件均存在"
    elif [ "$IS_INSTANCE" = "1" ]; then
        warn "清单源文件缺失（instance 模式仅提示，实例可裁剪文档）:$MISSING_SRC"
    else
        no "清单源文件缺失:$MISSING_SRC"
    fi
    if [ -z "$STALE" ]; then
        ok "产物未过期（全部 $N_SRC 个源比对）"
    elif [ "$IS_INSTANCE" = "1" ]; then
        warn "产物已过期（instance 模式仅提示；重生成 sh scripts/build-complete.sh 或删除 dist/）:$STALE"
    else
        no "产物已过期，源更新于:$STALE"
    fi
fi
echo

# ---- 7. 无空壳目录（体系明令禁止预建空目录；仅检查模板主体） ----
# 注意：除排除目录内容外，还要排除本地目录**本身**——否则本脚本 [9] 清理后留下的空
# `.artifacts/` 会被自己判为空壳目录（自造假红）。
echo "[7] 空目录检查（模板主体）"
EMPTY=$(find . -type d -empty \
    -not -path "./.git/*" -not -path "./.repo-meta/*" -not -path "./.screenshots/*" \
    -not -path "./.artifacts/*" -not -path "*/node_modules/*" -not -path "*/vendor/*" \
    -not -path "./.repo-meta" -not -path "./.screenshots" -not -path "./.artifacts" \
    2>/dev/null | tr '\n' ' ')
if [ -z "$EMPTY" ]; then ok "无空目录"; else no "存在空目录:$EMPTY"; fi
echo

# ---- 8. 禁止残留旧名（改名同步的回归保护） ----
echo "[8] 旧名残留（回归保护：改名后不得留旧称）"
OLD=0
while IFS= read -r f; do
    [ -n "$f" ] || continue
    N=$(grep -c "统一开发体系" "$f" || true)
    OLD=$((OLD + N))
done <<EOF
$SCOPE_MD
EOF
chk "旧名'统一开发体系'残留数" "$OLD" "0"
echo

# ---- 9. bench 入口契约（只验证契约，不执行项目真实基准） ----
echo "[9] bench 入口契约（隔离配置，不跑真实基准）"
for s in scripts/bench.sh scripts/test.sh scripts/build-complete.sh scripts/vdp-init-project.sh; do
    if [ -f "$s" ]; then ok "存在 $s"; else no "缺失 $s"; fi
done

# 9.1 执行位：优先用 git 索引模式（跨平台可靠）；无 git 时用 -x；不可判定则明示 N/A
if git_ok; then
    for s in scripts/bench.sh scripts/test.sh scripts/build-complete.sh scripts/vdp-init-project.sh; do
        MODE="$(git ls-files -s -- "$s" 2>/dev/null | awk '{print $1}')"
        if [ -z "$MODE" ]; then
            na "执行位 $s（未被 git 索引，无法判定）"
        elif [ "$MODE" = "100755" ]; then
            ok "执行位 $s (100755)"
        else
            no "执行位 $s ($MODE，期望 100755；修复：git update-index --chmod=+x $s)"
        fi
    done
else
    for s in scripts/bench.sh scripts/test.sh scripts/build-complete.sh scripts/vdp-init-project.sh; do
        if [ -x "$s" ]; then ok "可执行 $s"; else no "不可执行 $s"; fi
    done
fi

# 9.2 契约三路径：未配置 / 通过 / 失败（全部用临时合成配置，绝不触碰项目真实基准）
TMPD=".artifacts/.bench-contract-check"
rm -rf "$TMPD"
mkdir -p "$TMPD"
printf 'benchmarks:\n  - name: contract-pass\n    run: "true"\n' >"$TMPD/pass.yml"
printf 'benchmarks:\n  - name: contract-fail\n    run: "exit 1"\n' >"$TMPD/fail.yml"

VDP_BENCH_CONFIG="$TMPD/missing.yml" VDP_BENCH_EVIDENCE_ROOT="$TMPD/ev-u" \
    sh scripts/bench.sh >"$TMPD/unconfigured.txt" 2>&1
RC_U=$?
VDP_BENCH_CONFIG="$TMPD/pass.yml" VDP_BENCH_EVIDENCE_ROOT="$TMPD/ev-p" \
    sh scripts/bench.sh >"$TMPD/pass.txt" 2>&1
RC_P=$?
VDP_BENCH_CONFIG="$TMPD/fail.yml" VDP_BENCH_EVIDENCE_ROOT="$TMPD/ev-f" \
    sh scripts/bench.sh >"$TMPD/fail.txt" 2>&1
RC_F=$?

chk "未配置时退出码" "$RC_U" "2"
chk "全部成功时退出码" "$RC_P" "0"
chk "基准失败时退出码" "$RC_F" "1"

for f in "$TMPD/unconfigured.txt" "$TMPD/pass.txt" "$TMPD/fail.txt"; do
    if grep -q '^BENCH:' "$f"; then ok "输出契约 BENCH: 前缀（$(basename "$f")）"; else no "输出缺少 BENCH: 前缀（$f）"; fi
done

for d in "$TMPD/ev-u" "$TMPD/ev-p" "$TMPD/ev-f"; do
    if grep -q '"schema": "vdp-bench/1"' "$d"/[0-9]*/meta.json 2>/dev/null; then
        ok "证据落盘 meta.json（$(basename "$d")）"
    else
        no "证据未落盘 meta.json（$d）"
    fi
    if grep -q '^# BENCH 运行摘要' "$d"/[0-9]*/summary.md 2>/dev/null; then
        ok "证据落盘 summary.md（$(basename "$d")）"
    else
        no "证据未落盘 summary.md（$d）"
    fi
done

if grep -qE 'NO_BENCHMARKS_CONFIGURED|BLOCKED' "$TMPD/unconfigured.txt"; then
    ok "未配置时拒绝理由明确"
else
    no "退出 2 但未说明 NO_BENCHMARKS_CONFIGURED/BLOCKED"
fi
if grep -q '^BENCH: OK' "$TMPD/pass.txt"; then ok "成功路径标注 BENCH: OK"; else no "成功路径缺少 BENCH: OK"; fi
if grep -q '^BENCH: FAIL' "$TMPD/fail.txt"; then ok "失败路径标注 BENCH: FAIL"; else no "失败路径缺少 BENCH: FAIL"; fi

# 9.3 错误路径一：配置存在但无法解析 -> exit 3（"配置坏了"不等于"还没配"）
printf 'this is not yaml at all\n' >"$TMPD/bad.yml"
VDP_BENCH_CONFIG="$TMPD/bad.yml" VDP_BENCH_EVIDENCE_ROOT="$TMPD/ev-b" \
    sh scripts/bench.sh >"$TMPD/bad.txt" 2>&1
RC_B=$?
chk "不可解析配置退出码" "$RC_B" "3"
if grep -q '^BENCH: ERROR' "$TMPD/bad.txt"; then ok "不可解析配置标注 BENCH: ERROR"; else no "不可解析配置未标注 BENCH: ERROR"; fi

# 9.4 错误路径二：证据目录不可创建 -> exit 3（证据链断裂 ≠ 基准失败）
: >"$TMPD/not-a-dir"
VDP_BENCH_CONFIG="$TMPD/pass.yml" VDP_BENCH_EVIDENCE_ROOT="$TMPD/not-a-dir/sub" \
    sh scripts/bench.sh >"$TMPD/evi.txt" 2>&1
RC_E=$?
chk "证据链断裂退出码" "$RC_E" "3"
if grep -q '^BENCH: ERROR' "$TMPD/evi.txt"; then ok "证据链断裂标注 BENCH: ERROR"; else no "证据链断裂未标注 BENCH: ERROR"; fi

rm -rf "$TMPD"
rmdir ".artifacts" 2>/dev/null || true
echo

# ---- 10. 异常占位标记（孤立的空内联代码；合法代码围栏不误报） ----
echo "[10] 异常占位标记"
BAD_MARK=""
while IFS= read -r f; do
    [ -n "$f" ] || continue
    if grep -qE '(^|[^`])``($|[^`])' "$f"; then BAD_MARK="$BAD_MARK $f"; fi
done <<EOF
$SCOPE_MD
EOF
if [ -z "$BAD_MARK" ]; then
    ok '无孤立双反引号标记（占位请用 [[TODO: 说明]]，约定见 FILES.md §2）'
else
    no "孤立双反引号标记出现在:$BAD_MARK"
fi
if [ "$N_SCOPE" -lt "$SCOPE_MIN_FILES" ]; then
    no "占位标记扫描范围不足（$N_SCOPE 个文件 < 下限 $SCOPE_MIN_FILES）"
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
echo "PASS: $PASS    FAIL: $FAIL    N/A: $NA    WARN: $WARN"
if [ "$FAIL" -ne 0 ]; then
    echo "结果: FAIL —— 禁止在红基线上叠加改动（铁律 F1）"
    if [ "$MODE_FAIL" = "1" ]; then
        echo "修复入口: 模式问题 -> 编辑 .vdp-mode（允许值 template-source / project-instance）"
    else
        echo "修复入口: 按上方各 FAIL 行的提示逐项处理"
        if [ "$VDP_MODE" = "project-instance" ]; then
            echo "          实例初始化清单: sh scripts/vdp-init-project.sh"
        fi
    fi
    exit 1
fi
echo "结果: PASS"
exit 0
