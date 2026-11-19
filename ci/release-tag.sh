#!/usr/bin/env bash
# Human-facing release trigger (run LOCALLY, not in CI). One command starts a beta/stable
# release; CI does the version math, build, tag and publish (fully unattended afterwards).
#
# Usage: ci/release-tag.sh <beta|stable>
#   beta   -> writes a release request (target + channel), commits, pushes main
#   stable -> writes a release request (target + channel), commits, pushes main
#
# <target> is computed from the last stable tag via next-version.sh, so the version number is
# NEVER chosen by hand. The authoritative baseline remains the tag; VERSION is a human-readable
# record and release-request.json is the machine-readable signal for CI.
#
# WHY a real file write: build.yml uses `paths-ignore` for docs/*.md/.github; an empty commit
# ("git commit --allow-empty") would be SKIPPED by GitHub (docs: "If there are no files changed,
# the workflow will not run"). Writing release-request.json guarantees a non-ignored diff so the
# marker commit always triggers CI — even for consecutive betas with the same target.
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
printf '{"channel":"%s","target":"%s","requested_at":"%s"}\n' \
  "$CHANNEL" "$TARGET" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > release-request.json
git add VERSION release-request.json
git commit -m "chore(release): $CHANNEL"
git push origin HEAD

echo "[release-tag] pushed chore(release): $CHANNEL with VERSION=$TARGET"
echo "[release-tag] CI will compute the final version, tag and publish — no further action needed."
