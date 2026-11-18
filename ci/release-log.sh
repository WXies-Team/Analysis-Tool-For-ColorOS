#!/usr/bin/env bash
# 生成 Release Log：alpha 纯自动汇总，beta 以 release-notes.md 为主并附自动明细，stable 只取 release-notes.md。
# 用法: ci/release-log.sh <range>     例: ci/release-log.sh 372b302..HEAD  /  ci/release-log.sh HEAD
# 环境: VERSION / BUILD_ID / CHANNEL 必填；OPENLIST_BASE_URL 可选
#       （设置后在 Markdown 头注入 OpenList 下载链接）
#
# 一次生成两份文件（见 ~/.config/opencode/RELEASE-PIPELINE.md §1）：
#   release.md    Markdown，供 OpenList README 与 GitHub Release notes 渲染（含版本标题与下载链接）
#   changelog.txt 纯文本，供 version.json 的 changelog 字段（无版本头、无标记、无横幅；首行即亮点）
#
# 自动部分只收 feat/fix/perf：docs/chore/ci/test/style/build/refactor/revert 等一律过滤，
# 未带前缀的裸文本也不进日志（人工摘要由 release-notes.md 负责）。
set -Eeuo pipefail
shopt -s inherit_errexit

RANGE=${1:?用法: ci/release-log.sh <range>}
: "${VERSION:?VERSION is required}"
: "${BUILD_ID:?BUILD_ID is required}"
: "${CHANNEL:?CHANNEL is required}"
OPENLIST_BASE_URL=${OPENLIST_BASE_URL:-}

case "$CHANNEL" in
  alpha)  CHANNEL_LABEL="内测版"; BANNER="内测自动构建，可能不稳定，欢迎反馈" ;;
  beta)   CHANNEL_LABEL="公测版"; BANNER="候选版本，功能可能调整，欢迎反馈" ;;
  stable) CHANNEL_LABEL="正式版"; BANNER="" ;;
  *)      CHANNEL_LABEL="$CHANNEL"; BANNER="" ;;
esac

NOTES_FILE="release-notes.md"
if [ "$CHANNEL" != "alpha" ] && { [ ! -f "$NOTES_FILE" ] || [ ! -s "$NOTES_FILE" ]; }; then
  echo "::error::$CHANNEL 构建需要非空 $NOTES_FILE，规范见 ~/.config/opencode/templates/release-notes-style.md"
  exit 1
fi

BODY_TMP=$(mktemp)
trap 'rm -f "$BODY_TMP"' EXIT

# 两段输入用 sentinel 隔开：先读提交主题（自动明细），再读 release-notes.md（人工撰写）。
# 用 sentinel 而不是 NR==FNR，是为了在提交区间为空时也能正确区分两段。
{
  if [ "$CHANNEL" != "stable" ]; then
    git log --pretty=format:'%s' "$RANGE" || true
  fi
  printf '\n===RELEASE_NOTES===\n'
  if [ "$CHANNEL" != "alpha" ]; then cat "$NOTES_FILE"; fi
} | awk \
  -v OUT="$BODY_TMP" \
  -v channel="$CHANNEL" \
  '
  BEGIN { phase = 0; split("新增 改进 修复", cats, " ") }
  /^===RELEASE_NOTES===$/ { phase = 1; next }
  {
    if (phase == 0) {
      # 只认三种用户可见类型；其余前缀（含 docs/chore/ci/test/style/build/refactor/revert）与裸文本都跳过
      cat = ""
      if ($0 ~ /^feat(\([^)]*\))?:/) cat = "新增"
      else if ($0 ~ /^perf(\([^)]*\))?:/) cat = "改进"
      else if ($0 ~ /^fix(\([^)]*\))?:/) cat = "修复"
      if (cat == "") next
      s = $0
      sub(/^[A-Za-z]+(\([^)]*\))?:[ \t]*/, "", s)
      if (s == "" || (s in seen)) next
      seen[s] = 1
      auto[cat, ++nauto[cat]] = s
      next
    }
    # release-notes.md 骨架：首行一句话摘要 + 新增/改进/修复 三个平铺分类（无 Markdown 标题）
    line = $0
    if (line ~ /^[[:space:]]*$/) next
    if (summary == "" && line != "新增" && line != "改进" && line != "修复" && line !~ /^-/) {
      summary = line
      next
    }
    if (line == "新增" || line == "改进" || line == "修复") { cur = line; next }
    if (line ~ /^-[[:space:]]+/) {
      s = line
      sub(/^-[[:space:]]+/, "", s)
      if (cur != "" && s != "") notes[cur, ++nnotes[cur]] = s
      next
    }
    extra[++nextra] = line
  }
  END {
    if (summary != "") { print summary > OUT; print "" > OUT }
    for (i = 1; i <= nextra; i++) print extra[i] > OUT
    if (nextra) print "" > OUT
    if (channel == "alpha") {
      # 内测没有人工说明，分类里放自动汇总的提交
      for (k = 1; k <= 3; k++) {
        c = cats[k]
        if (!nauto[c]) continue
        print c > OUT
        for (i = 1; i <= nauto[c]; i++) print "- " auto[c, i] > OUT
        print "" > OUT
      }
    } else {
      # Beta/Stable 以人工说明为主；beta 的自动提交另起一节，避免和精选条目看起来重复
      for (k = 1; k <= 3; k++) {
        c = cats[k]
        if (!nnotes[c]) continue
        print c > OUT
        for (i = 1; i <= nnotes[c]; i++) print "- " notes[c, i] > OUT
        print "" > OUT
      }
      if (channel == "beta") {
        m = 0
        for (k = 1; k <= 3; k++)
          for (i = 1; i <= nauto[cats[k]]; i++) detail[++m] = auto[cats[k], i]
        if (m) {
          print "详细提交" > OUT
          for (i = 1; i <= m; i++) print "- " detail[i] > OUT
          print "" > OUT
        }
      }
    }
  }
  '

cp "$BODY_TMP" changelog.txt

# Markdown 版只多一层标题与元信息；分类标签升级成带 emoji 的三级标题，其余原样透传。
{
  echo "# ColorOS $VERSION"
  echo
  echo "> $(date -u +%F) · Build $BUILD_ID · $CHANNEL_LABEL"
  if [ -n "$OPENLIST_BASE_URL" ]; then
    echo ">"
    echo "> 📥 [前往 OpenList 下载${CHANNEL_LABEL}](${OPENLIST_BASE_URL}/${CHANNEL}/)"
  fi
  if [ -n "$BANNER" ]; then
    echo ">"
    echo "> $BANNER"
  fi
  echo
  awk '
    $0 == "新增" { print "### ✨ 新增"; next }
    $0 == "改进" { print "### 🔄 改进"; next }
    $0 == "修复" { print "### 🐛 修复"; next }
    $0 == "详细提交" { print "### 📝 详细提交"; next }
    { print }
  ' "$BODY_TMP"
} > release.md
