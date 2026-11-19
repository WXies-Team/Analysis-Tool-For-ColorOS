#!/usr/bin/env bash
# Determine CHANNEL / VERSION / Build ID for one CI run — the single source of truth that
# replaces the inline "Determine channel and version" step in build.yml (VERSIONING §2–§6).
#
# Inputs (GitHub env, with local-test fallbacks):
#   GITHUB_REF      refs/tags/<name> for a manual tag push, else refs/heads/main
#   GITHUB_SHA      HEAD commit (tag path points at the tag's commit)
#   GITHUB_ENV      when set, KEY=VALUE lines are appended (CI); otherwise printed to stdout.
#
# Channel routing (unattended):
#   refs/tags/*                       -> the tag is authoritative: CHANNEL by suffix, VERSION=$TAG
#                                        (manual tag path kept for rollback / hotfix)
#   HEAD subject "chore(release): beta"  -> beta,  VERSION=<target>-beta.N
#   HEAD subject "chore(release): stable"-> stable, VERSION=<target>
#   any other push                    -> alpha,  VERSION=<target>-alpha.N
#
# <target> = next-version.sh BASE "<BASE>..HEAD" where BASE = last stable tag (immutable), so
# the target is always derived from merged commits, never from a hand-edited VERSION file.
# Beta/alpha ordinals auto-increment: beta N = max same-target beta tag + 1 (reset to 1 on a
# new target); alpha N = build-triggering commits since BASE (min 1).
set -Eeuo pipefail
shopt -s inherit_errexit

BUILD_ID=${BUILD_ID:-${GITHUB_RUN_NUMBER:-1}}
GITHUB_REF=${GITHUB_REF:-refs/heads/main}
RELEASE=0

# Last stable tag = most recent immutable X.Y.Z tag; this is the version baseline.
BASE=$(git tag --list '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1 || true)
if [ -z "$BASE" ]; then
  # No stable tag yet (initial development): fall back to VERSION, then to 0.1.0.
  BASE=$(tr -d '[:space:]' < VERSION 2>/dev/null || true)
  [ -n "$BASE" ] || BASE=0.1.0
fi

if [[ "$GITHUB_REF" == refs/tags/* ]]; then
  TAG=${GITHUB_REF#refs/tags/}
  if [[ ! "$TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-(alpha|beta)\.[0-9]+)?$ ]]; then
    echo "::error::[determine-version] illegal tag '$TAG'" >&2; exit 1
  fi
  VERSION="$TAG"
  case "$TAG" in
    *-beta.*)  CHANNEL=beta ;;
    *-alpha.*) CHANNEL=alpha ;;
    *)         CHANNEL=stable ;;
  esac
  RELEASE=1
  echo "[determine-version] manual tag path: channel=$CHANNEL version=$VERSION"
else
  SUBJECT=$(git log -1 --format=%s HEAD)
  case "$SUBJECT" in
    'chore(release): beta')  CHANNEL=beta;  RELEASE=1 ;;
    'chore(release): stable') CHANNEL=stable; RELEASE=1 ;;
    *) CHANNEL=alpha ;;
  esac

  RANGE="$BASE..HEAD"
  git rev-parse --verify -q "$BASE" >/dev/null || RANGE="HEAD"
  TARGET=$(bash "$(dirname "$0")/next-version.sh" "$BASE" "$RANGE")

  if [ "$CHANNEL" = "alpha" ]; then
    if [ "$RANGE" = "HEAD" ]; then
      COUNT=$(git rev-list --count HEAD -- . \
        ':(exclude)docs/**' ':(exclude)*.md' ':(exclude).github/**')
    else
      COUNT=$(git rev-list --count "$BASE..HEAD" -- . \
        ':(exclude)docs/**' ':(exclude)*.md' ':(exclude).github/**')
    fi
    VERSION="$TARGET-alpha.$(( COUNT > 0 ? COUNT : 1 ))"
  elif [ "$CHANNEL" = "beta" ]; then
    MAX_N=$(git tag --list "${TARGET}-beta.*" --sort=-v:refname \
      | grep -E "^${TARGET}-beta\.[0-9]+$" | sed -E 's/.*\.([0-9]+)$/\1/' | head -n 1 || true)
    N=$(( ${MAX_N:-0} + 1 ))
    VERSION="${TARGET}-beta.$N"
  else
    VERSION="$TARGET"
  fi
  echo "[determine-version] marker path: channel=$CHANNEL version=$VERSION (base=$BASE target=$TARGET)"
fi

if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "CHANNEL=$CHANNEL"
    echo "VERSION=$VERSION"
    echo "BUILD_ID=$BUILD_ID"
    echo "VERSION_CODE=$BUILD_ID"
    echo "RELEASE=$RELEASE"
    echo "ORG_GRADLE_PROJECT_VERSION_NAME=$VERSION"
    echo "ORG_GRADLE_PROJECT_VERSION_CODE=$BUILD_ID"
  } >> "$GITHUB_ENV"
else
  echo "CHANNEL=$CHANNEL"
  echo "VERSION=$VERSION"
  echo "BUILD_ID=$BUILD_ID"
  echo "VERSION_CODE=$BUILD_ID"
  echo "RELEASE=$RELEASE"
fi
echo "Channel: $CHANNEL / Version Name: $VERSION / Build ID = Version Code: $BUILD_ID"
