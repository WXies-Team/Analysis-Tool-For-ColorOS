#!/usr/bin/env bash
# Human-facing release trigger (run LOCALLY, not in CI). One command starts a beta/stable
# release; CI does the version math, build, tag and publish (fully unattended afterwards).
#
# Usage: ci/release-tag.sh <beta|stable>
#   beta   -> writes VERSION=<target>, commits "chore(release): beta", pushes main
#   stable -> writes VERSION=<target>, commits "chore(release): stable", pushes main
#
# <target> is computed from the last stable tag via next-version.sh, so the version number is
# NEVER chosen by hand. The VERSION file is only a human-readable record of the target and the
# commit-message marker is the signal CI reads; the authoritative baseline remains the tag.
set -Eeuo pipefail
shopt -s inherit_errexit

CHANNEL=${1:?usage: ci/release-tag.sh <beta|stable>}
case "$CHANNEL" in beta|stable) ;; *) echo "::error::channel must be beta or stable" >&2; exit 1 ;; esac

git diff --quiet && git diff --cached --quiet || {
  echo "::error::working tree is dirty; commit or stash before releasing" >&2; exit 1
}

BASE=$(git tag --list '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1 || true)
[ -n "$BASE" ] || BASE=$(tr -d '[:space:]' < VERSION 2>/dev/null || true)
[ -n "$BASE" ] || BASE=0.1.0

TARGET=$(bash "$(dirname "$0")/next-version.sh" "$BASE" "$BASE..HEAD")
printf '%s\n' "$TARGET" > VERSION
git add VERSION
# --allow-empty so consecutive beta markers (same target, VERSION unchanged) still create the
# marker commit that triggers CI; CI derives the incrementing beta N from existing tags.
git commit --allow-empty -m "chore(release): $CHANNEL"
git push origin HEAD

echo "[release-tag] pushed chore(release): $CHANNEL with VERSION=$TARGET"
echo "[release-tag] CI will compute the final version, tag and publish — no further action needed."
