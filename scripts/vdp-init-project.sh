#!/usr/bin/env bash
# VDP — 从模板初始化项目实例（Template Source -> Project Instance）
#
# 用途：把复制来的 VDP 模板切换为项目实例模式，并输出"必须填什么"的清单。
#   1) 把 .vdp-mode 从 template-source 切换为 project-instance
#   2) 终端输出实例初始化清单（必改文件 + 判定规则，scripts/test.sh 会强制检查）
#   3) 可选：--remove-repo-meta 删除模板维护目录 .repo-meta/（绝不默认执行）
#
# 用法：sh scripts/vdp-init-project.sh [--remove-repo-meta]
# 退出：成功 0；缺少 .vdp-mode、.vdp-mode 值非法或未知参数 非 0。
#   .vdp-mode 值非法时**拒绝执行且不修改文件**——非法值意味着检出物处于未知状态，
#   静默覆盖等于未经确认改写用户文件（见 docs/MODES.md §2）。
#
# 可移植性：目标 bash；纯 POSIX sh 亦可运行——pipefail 仅在 shell 支持时启用
#   （本脚本没有依赖管道退出码的路径，不支持时跳过不降低严格性）。
# 输出统一前缀 VDP-INIT: ，便于日志 grep。

set -eu

if (set -o pipefail) 2>/dev/null; then
    set -o pipefail
fi

cd "$(dirname "$0")/.."

PREFIX="VDP-INIT:"
MODE_FILE=".vdp-mode"

usage() {
    cat <<EOF
$PREFIX 用法: sh scripts/vdp-init-project.sh [--remove-repo-meta]
$PREFIX   --remove-repo-meta  删除模板维护目录 .repo-meta/（不可恢复，确认后才使用）
$PREFIX   -h | --help          显示本帮助
EOF
}

REMOVE_REPO_META=0
for arg in "$@"; do
    case "$arg" in
        --remove-repo-meta) REMOVE_REPO_META=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf '%s 未知参数: %s\n' "$PREFIX" "$arg" >&2; usage >&2; exit 1 ;;
    esac
done

if [ ! -f "$MODE_FILE" ]; then
    printf '%s FAIL: 缺少 %s —— 本目录不是完整的 VDP 模板（应从模板源仓库完整复制，含 .vdp-mode）\n' "$PREFIX" "$MODE_FILE" >&2
    exit 1
fi

CUR_MODE="$(head -n 1 "$MODE_FILE" | tr -d '\r')"
case "$CUR_MODE" in
    project-instance)
        printf '%s 已是 project-instance 模式（幂等：不重复切换，仅输出清单）\n' "$PREFIX"
        ;;
    template-source)
        printf 'project-instance\n' > "$MODE_FILE"
        printf '%s .vdp-mode 已切换: template-source -> project-instance\n' "$PREFIX"
        ;;
    *)
        # 非法值意味着检出物处于未知状态（可能是手工写坏、也可能是误把模板源当项目用）。
        # 静默覆盖等于未经确认改写用户文件：拒绝执行，保持文件原样，交由人判断。
        printf '%s ERROR: .vdp-mode 值非法 "%s"，未做任何修改\n' "$PREFIX" "$CUR_MODE" >&2
        printf '%s   允许值：template-source / project-instance（严格匹配，无空白容忍）\n' "$PREFIX" >&2
        printf '%s   修复：手工把 .vdp-mode 改为上述之一后重跑本脚本（语义见 docs/MODES.md §2）\n' "$PREFIX" >&2
        exit 1
        ;;
esac

# 实例初始化清单：只输出到终端，不落文件——避免给项目增加额外清理负担；
# 判定规则与常见坑集中在 docs/MODES.md（单一事实源，避免两处漂移）。
printf '%s 下一步：把模板占位替换为项目事实。scripts/test.sh 在 project-instance 模式强制检查以下必改项：\n' "$PREFIX"
cat <<EOF
$PREFIX [必改] README.md          — 标题 "# 项目名称" 换成真实项目名；删除 TEMPLATE REPO 声明块，
$PREFIX                              并保留一句"本项目由 VDP v1.2 管理 / This project is managed by VDP v1.2"
$PREFIX [必改] docs/PROJECT.md    — 填写目标/使用者/范围，至少一条 REQ-xxx 冒号后有实际内容
$PREFIX [必改] docs/ACCEPTANCE.md — "## 1. KPI 表" 至少一行真实 KPI（定义/测量方法/红线）
$PREFIX [必改] STATE.md           — "当前阶段" 填 P0–P7 之一；"下一步" 至少一条具体动作
$PREFIX [应改] docs/ROADMAP.md    — 里程碑与当前阶段对齐
$PREFIX [应改] docs/AUTHZ.md + docs/AUTHZ.yaml — 模板默认授权表换成项目实际策略（两者同提交）
$PREFIX [应改] CHANGELOG.md       — 从 Unreleased 开始建立你的版本历史
$PREFIX 两种模式的检查差异与常见坑：docs/MODES.md
EOF

if [ -d .repo-meta ]; then
    if [ "$REMOVE_REPO_META" = "1" ]; then
        rm -rf .repo-meta
        printf '%s 已删除 .repo-meta/（模板维护元信息，项目实例无需保留）\n' "$PREFIX"
    else
        printf '%s 检测到 .repo-meta/（模板维护元信息，非项目交付内容，项目实例通常可删除）\n' "$PREFIX"
        printf '%s 确认删除后运行: sh scripts/vdp-init-project.sh --remove-repo-meta\n' "$PREFIX"
    fi
else
    printf '%s 未检测到 .repo-meta/（无需清理）\n' "$PREFIX"
fi

printf '%s 完成填写后运行: sh scripts/test.sh（instance 模式检查更严格，占位未替换会 FAIL）\n' "$PREFIX"
printf '%s 初始化清单输出完毕。\n' "$PREFIX"
exit 0
