#!/usr/bin/env bash
# Generate Release Log with the hybrid policy (see ~/.config/opencode/RELEASE-PIPELINE.md §1):
#   alpha  -> auto from commits only (feat/fix/perf) + banner
#   beta   -> release-notes.md (AI-written, per templates/release-notes-style.md) for the
#             highlight, plus auto-generated grouped details appended
#   stable -> release-notes.md required (CI fails without it), used as primary notes + details
# There is NO "修复了一些已知问题" fallback: with nothing qualifying, emit only the honest
# highlight (first auto detail for alpha, notes first line for beta/stable).
#
# Usage: ci/release-log.sh <range>   e.g. ci/release-log.sh 372b302..HEAD  /  ci/release-log.sh HEAD
# Env: VERSION / BUILD_ID / CHANNEL required; OPENLIST_BASE_URL optional
#      (injects an OpenList download link into the Markdown header).
#
# Outputs (RELEASE-PIPELINE §1):
#   release.md    Markdown for OpenList README / GitHub Release notes (version heading + link)
#   changelog.txt plain text for version.json.changelog -> in-app dialog (no header, no markup,
#                 no banner; first line = the highlight shown as "本次亮点")
#
# Porting: ColorOS is the Chinese product name in the Markdown heading (keep placeholder).
# Classification: only feat -> "新增", fix -> "修复", perf -> "改进". docs/chore/ci/test/style/build/
# refactor/revert and every other prefix (plus untyped text) are excluded; identical messages deduped.
set -Eeuo pipefail
shopt -s inherit_errexit

RANGE=${1:?usage: ci/release-log.sh <range>}
: "${VERSION:?VERSION is required}"
: "${BUILD_ID:?BUILD_ID is required}"
: "${CHANNEL:?CHANNEL is required}"
OPENLIST_BASE_URL=${OPENLIST_BASE_URL:-}

case "$CHANNEL" in
  alpha)  CHANNEL_LABEL="内测版"; BANNER="内测自动构建，可能不稳定，欢迎反馈"; NEED_NOTES=0 ;;
  beta)   CHANNEL_LABEL="公测版"; BANNER="候选版本，功能可能调整，欢迎反馈"; NEED_NOTES=1 ;;
  stable) CHANNEL_LABEL="正式版"; BANNER=""; NEED_NOTES=1 ;;
  *)      CHANNEL_LABEL="$CHANNEL"; BANNER=""; NEED_NOTES=0 ;;
esac

NOTES_FILE="release-notes.md"
if [ "$NEED_NOTES" -eq 1 ] && { [ ! -f "$NOTES_FILE" ] || [ ! -s "$NOTES_FILE" ]; }; then
  echo "::error::$CHANNEL requires a non-empty release-notes.md (format: templates/release-notes-style.md)"
  exit 1
fi

# Auto details from the commit range -> two temp files (Markdown / plain), categories "新增"/"改进"/"修复".
DETAILS_MD=$(mktemp)
DETAILS_TXT=$(mktemp)
trap 'rm -f "$DETAILS_MD" "$DETAILS_TXT"' EXIT

git log --pretty=format:'%s' "$RANGE" | awk \
  -v mdFile="$DETAILS_MD" -v txtFile="$DETAILS_TXT" '
  function clean(s) { sub(/^[A-Za-z]+(\([^)]*\))?!?:[ \t]*/, "", s); return s }
  function add(group, s) {
    s = clean(s)
    if (s == "" || (s in seen)) return
    seen[s] = 1
    if (group == "new") newItems[++nNew] = s
    else if (group == "perf") perfItems[++nPerf] = s
    else fixItems[++nFix] = s
  }
  # Breaking markers (!) stay in the group of their base type — see COMMITTING.md section 2.
  /^feat(\([^)]*\))?!?:/ { add("new", $0); next }
  /^perf(\([^)]*\))?!?:/ { add("perf", $0); next }
  /^fix(\([^)]*\))?!?:/  { add("fix", $0); next }
  END {
    if (nNew) { print "### ✨ 新增" > mdFile; print "新增" > txtFile
      for (i = 1; i <= nNew; i++) { print "- " newItems[i] > mdFile; print "- " newItems[i] > txtFile }
      print "" > mdFile; print "" > txtFile }
    if (nPerf) { print "### ⚡ 改进" > mdFile; print "改进" > txtFile
      for (i = 1; i <= nPerf; i++) { print "- " perfItems[i] > mdFile; print "- " perfItems[i] > txtFile }
      print "" > mdFile; print "" > txtFile }
    if (nFix) { print "### 🐛 修复" > mdFile; print "修复" > txtFile
      for (i = 1; i <= nFix; i++) { print "- " fixItems[i] > mdFile; print "- " fixItems[i] > txtFile }
      print "" > mdFile; print "" > txtFile }
  }
'

MD=release.md
TXT=changelog.txt

# ---- release.md: version heading + metadata + optional download link + banner + notes + collapsible details ----
echo "# ColorOS $VERSION" > "$MD"
echo "" >> "$MD"
echo "> $(date -u +%F) · Build $BUILD_ID · $CHANNEL_LABEL" >> "$MD"
if [ -n "$OPENLIST_BASE_URL" ]; then
  echo ">" >> "$MD"
  echo "> 📥 [前往 OpenList 下载${CHANNEL_LABEL}](${OPENLIST_BASE_URL}/${CHANNEL}/)" >> "$MD"
fi
echo "" >> "$MD"
if [ -n "$BANNER" ]; then
  echo "> $BANNER" >> "$MD"
  echo "" >> "$MD"
fi
if [ "$NEED_NOTES" -eq 1 ]; then
  cat "$NOTES_FILE" >> "$MD"
  echo "" >> "$MD"
fi
if [ -s "$DETAILS_MD" ]; then
  echo "<details>" >> "$MD"
  echo "<summary>变更明细</summary>" >> "$MD"
  echo "" >> "$MD"
  cat "$DETAILS_MD" >> "$MD"
  echo "</details>" >> "$MD"
fi

# ---- changelog.txt: no banner; first line = notes first line (beta/stable) or auto detail (alpha) ----
: > "$TXT"
if [ "$NEED_NOTES" -eq 1 ]; then
  HIGHLIGHT=$(awk 'NF{print; exit}' "$NOTES_FILE")
  printf '%s\n\n' "$HIGHLIGHT" >> "$TXT"
fi
cat "$DETAILS_TXT" >> "$TXT"

if [ ! -s "$TXT" ]; then
  # An alpha range with only non-user-facing commits has no detail lines. Emit a factual
  # channel label instead of an empty in-app highlight — not a "various fixes" filler.
  echo "内测自动构建" >> "$TXT"
fi

echo "===== release.md ====="
cat "$MD"
echo "===== changelog.txt ====="
cat "$TXT"
