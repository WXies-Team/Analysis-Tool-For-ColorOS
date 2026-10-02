#!/usr/bin/env bash
# 生成 Release Log（Conventional Commits 分类），日志区间由调用方计算后传入。
# 用法: ci/release-log.sh <range>     例: ci/release-log.sh 372b302..HEAD  /  ci/release-log.sh HEAD
# 环境: VERSION / BUILD_ID / CHANNEL 必填；PRODUCT_NAME / OPENLIST_BASE_URL 可选
#       （OPENLIST_BASE_URL 设置后在 Markdown 头注入 OpenList 下载链接）
#
# 一次生成两份文件（见 docs/VERSIONING.md §26）：
#   release.md    Markdown，供 OpenList README 与 GitHub Release notes 渲染（含版本标题与下载链接）
#   changelog.txt 纯文本，供 version.json 的 changelog 字段
#
# 过滤规则：docs/chore/ci/test/style/build 不入日志；完全相同的消息只保留一条。
set -euo pipefail

RANGE=${1:?用法: ci/release-log.sh <range>}
: "${VERSION:?VERSION is required}"
: "${BUILD_ID:?BUILD_ID is required}"
: "${CHANNEL:?CHANNEL is required}"
PRODUCT_NAME=${PRODUCT_NAME:-Analysis Tool For ColorOS}
OPENLIST_BASE_URL=${OPENLIST_BASE_URL:-}

case "$CHANNEL" in
  alpha)  CHANNEL_LABEL="内测版" ;;
  beta)   CHANNEL_LABEL="公测版" ;;
  stable) CHANNEL_LABEL="正式版" ;;
  *)      CHANNEL_LABEL="$CHANNEL" ;;
esac

git log --pretty=format:'%s' "$RANGE" | awk \
  -v VERSION="$VERSION" \
  -v BUILD_ID="$BUILD_ID" \
  -v CHANNEL="$CHANNEL" \
  -v CHANNEL_LABEL="$CHANNEL_LABEL" \
  -v PRODUCT="$PRODUCT_NAME" \
  -v OPENLIST="$OPENLIST_BASE_URL" \
  -v DATE="$(date -u +%F)" '
  /^feat(\([^)]*\))?:/ { s = $0; sub(/^[A-Za-z]+(\([^)]*\))?:[ \t]*/, "", s); if (s in seen) next; seen[s] = 1; a[++na] = s; next }
  /^fix(\([^)]*\))?:/  { s = $0; sub(/^[A-Za-z]+(\([^)]*\))?:[ \t]*/, "", s); if (s in seen) next; seen[s] = 1; f[++nf] = s; next }
  {
    s = $0
    if ($0 ~ /^[A-Za-z]+(\([^)]*\))?:/) sub(/^[A-Za-z]+(\([^)]*\))?:[ \t]*/, "", s)
    # 非用户可见变更（文档/杂务/CI/测试/样式/构建）不入日志
    if ($0 ~ /^(docs|chore|ci|test|style|build)(\([^)]*\))?:/) { next }
    # 完全相同的消息只保留一条
    if (s in seen) { next }
    seen[s] = 1
    if (CHANNEL == "stable") { p[++np] = s }
    else if ($0 ~ /^[A-Za-z]+(\([^)]*\))?:/) { c[++nc] = s }
    else { o[++no] = s }
  }
  END {
    MD = "release.md"; TXT = "changelog.txt"
    # Markdown 头：OpenList / GitHub 渲染用（版本大标题 + 元信息 + 可选下载链接）
    print "# " PRODUCT " " VERSION > MD
    print "" > MD
    print "> " DATE " · Build " BUILD_ID " · " CHANNEL_LABEL > MD
    if (OPENLIST != "") {
      print ">" > MD
      print "> 📥 [前往 OpenList 下载" CHANNEL_LABEL "](" OPENLIST "/" CHANNEL "/)" > MD
    }
    print "" > MD
    # 纯文本无头：版本号已在别处展示，这里不再重复
    # 分组标题中文化（Keep a Changelog 分类的中文对应），Stable 与非 Stable 统一
    empty = 1
    if (na) {
      empty = 0
      print "### ✨ 新增" > MD; print "新增" > TXT
      for (i = 1; i <= na; i++) { print "- " a[i] > MD; print "- " a[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (nc) {
      empty = 0
      print "### 🔄 变更" > MD; print "变更" > TXT
      for (i = 1; i <= nc; i++) { print "- " c[i] > MD; print "- " c[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (np) {
      empty = 0
      print "### ⚡ 优化" > MD; print "优化" > TXT
      for (i = 1; i <= np; i++) { print "- " p[i] > MD; print "- " p[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (nf) {
      empty = 0
      print "### 🐛 修复" > MD; print "修复" > TXT
      for (i = 1; i <= nf; i++) { print "- " f[i] > MD; print "- " f[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (no) {
      empty = 0
      print "### 🧰 其他" > MD; print "其他" > TXT
      for (i = 1; i <= no; i++) { print "- " o[i] > MD; print "- " o[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (empty) {
      # 无用户可见变更时按同格式输出兜底条目（业界惯例 Bug fixes and improvements），
      # 避免日志出现开发向措辞
      print "### 🐛 修复" > MD; print "修复" > TXT
      print "- 修复了一些已知问题" > MD
      print "- 修复了一些已知问题" > TXT
      print "" > MD; print "" > TXT
    }
  }
'
