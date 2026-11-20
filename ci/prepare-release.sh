#!/usr/bin/env bash
# Analysis-Tool 的 semantic-release prepare 钩子：
#   $1=VERSION  $2=GIT_TAG  $3=<PROJECT>；release notes 从 stdin 读入。
# 1) notes(Markdown) -> changelog.txt（纯文本，保留 emoji 分组标题）
# 2) 调 pack-all.sh 完成 8 平台打包
set -Eeuo pipefail
shopt -s inherit_errexit

VERSION=${1:?version required}
GIT_TAG=${2:?gitTag required}
PREFIX=${3:?project prefix required}
BUILD_ID="${GITHUB_RUN_NUMBER:-1}"

# notes 经 stdin 传入；先落临时文件再交给 Python，避免与 python3 heredoc 的 stdin 冲突
# （旧版直接 sys.stdin.read() 读到的是 python heredoc 内容，导致 changelog.txt 永远只有空行）。
NOTES_RAW=$(mktemp)
trap 'rm -f "$NOTES_RAW"' EXIT
cat > "$NOTES_RAW"

python3 - "$NOTES_RAW" <<'PYEOF'
import re, sys
raw = open(sys.argv[1], encoding="utf-8").read()
lines = []
for line in raw.splitlines():
    s = line.strip()
    if not s or s.startswith("## "):
        continue
    s = re.sub(r"^###\s+", "", s)
    s = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", s)
    s = s.replace("**", "")
    lines.append(s)
open("changelog.txt", "w", encoding="utf-8").write("\n".join(lines) + "\n")
PYEOF
test -s changelog.txt || { echo "::error::empty changelog.txt"; exit 1; }

bash "$(dirname "$0")/pack-all.sh" "$VERSION" "$BUILD_ID" "$PREFIX"
