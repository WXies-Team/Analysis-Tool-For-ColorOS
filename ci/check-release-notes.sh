#!/usr/bin/env bash
# Validate the AI-written release notes for tagged channels (beta / stable).
# Alpha ships auto-generated logs only, so this script is a no-op for alpha (and when no
# channel is supplied) and always exits 0. Called by build.yml before "Generate release log".
# Format contract: templates/release-notes-style.md.
# Usage: ci/check-release-notes.sh <channel>   (CHANNEL env is also accepted)
set -Eeuo pipefail
shopt -s inherit_errexit

: "${CHANNEL:?CHANNEL is required}"
NOTES_FILE="release-notes.md"
BANNED="修复了一些已知问题"

if [ "$CHANNEL" = "alpha" ]; then
  echo "[check-release-notes] channel=$CHANNEL: auto-generated log, no notes file required."
  exit 0
fi

fail() { echo "::error::[check-release-notes] $1" >&2; exit 1; }

[ -f "$NOTES_FILE" ] || fail "$NOTES_FILE is missing for $CHANNEL (format: templates/release-notes-style.md)"
[ -s "$NOTES_FILE" ] || fail "$NOTES_FILE is empty for $CHANNEL"

# No raw Conventional Commit prefixes — the notes file is user-facing Chinese copy, not git log.
# Include the breaking-change marker (!) so `feat!:` / `fix(scope)!:` cannot slip through.
if grep -nEq '^[[:space:]]*(feat|fix|perf|docs|chore|ci|test|style|build|refactor|revert)(\([^)]*\))?!?:' "$NOTES_FILE"; then
  fail "$NOTES_FILE contains raw commit prefixes; rewrite them as user-facing copy"
fi

if grep -qF "$BANNED" "$NOTES_FILE"; then
  fail "$NOTES_FILE contains the banned filler '$BANNED'"
fi

# "No fallback filler" also bans the obvious equivalents (VERSIONING.md section 9.2).
if grep -nEq '修复(了)?(一些|若干|部分)(已知)?问题|解决(了)?(一些|若干|部分)(已知)?问题|其他优化|若干优化' "$NOTES_FILE"; then
  fail "$NOTES_FILE contains filler shorthand; write concrete user-facing changes"
fi

# First non-empty line must be the one-sentence "why update" highlight (dialog "本次亮点"),
# not a Markdown header. release-log.sh reuses this exact line as changelog.txt's first line.
FIRST=$(awk 'NF{print; exit}' "$NOTES_FILE")
case "$FIRST" in
  ''|\#*|'>'*|'-'*|'*'*|新增|改进|修复)
    fail "first non-empty line of $NOTES_FILE must be a one-sentence 'why update' highlight, not a header, quote, list item or category name" ;;
esac

echo "[check-release-notes] $NOTES_FILE validated for $CHANNEL; highlight: $FIRST"
