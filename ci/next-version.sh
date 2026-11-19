#!/usr/bin/env bash
# Compute the next semantic target version from the commits in a revision range.
# Pure function: no git state mutation, no output except the resulting version on stdout.
#
# Usage: ci/next-version.sh <base> <range>
#   base  : current MAJOR.MINOR.PATCH (the last stable version)
#   range : git revision range whose commits decide the bump (e.g. "1.0.0..HEAD")
#
# Bump rules (Conventional Commits -> SemVer, highest wins; see COMMITTING.md §2):
#   feat! / fix! / BREAKING CHANGE: footer  -> MAJOR
#   feat                                    -> MINOR
#   fix / perf                              -> PATCH
#   everything else (docs/chore/ci/...)     -> no bump
# Lower fields reset to 0 on a higher bump. With no qualifying commit the base is returned.
set -Eeuo pipefail
shopt -s inherit_errexit

BASE=${1:?usage: ci/next-version.sh <base> <range>}
RANGE=${2:?usage: ci/next-version.sh <base> <range>}

if [[ ! "$BASE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::[next-version] base must be MAJOR.MINOR.PATCH, got '$BASE'" >&2
  exit 1
fi
IFS='.' read -r MAJOR MINOR PATCH <<<"$BASE"

# Regexes in variables so bash does not misparse the parens in [[ =~ ]].
RE_BREAKING='BREAKING[[:space:]]CHANGE:'
RE_MAJOR='^[a-z]+(\([^)]*\))?!:'
RE_FEAT='^feat(\([^)]*\))?:'
RE_FIX='^(fix|perf)(\([^)]*\))?:'

bump=none
# Read subject AND body so a `BREAKING CHANGE:` footer is detected.
while IFS= read -r line; do
  if [[ "$line" =~ $RE_BREAKING ]] || [[ "$line" =~ $RE_MAJOR ]]; then
    bump=major
    break
  elif [[ "$line" =~ $RE_FEAT ]]; then
    [[ "$bump" == "minor" ]] || bump=minor
  elif [[ "$line" =~ $RE_FIX ]]; then
    [[ "$bump" == "minor" || "$bump" == "major" ]] || bump=patch
  fi
done < <(git log --pretty=format:'%s%n%b' "$RANGE")

case "$bump" in
  major) printf '%d.0.0\n' "$((MAJOR + 1))" ;;
  minor) printf '%d.%d.0\n' "$MAJOR" "$((MINOR + 1))" ;;
  patch) printf '%d.%d.%d\n' "$MAJOR" "$MINOR" "$((PATCH + 1))" ;;
  none)  printf '%s\n' "$BASE" ;;
esac
