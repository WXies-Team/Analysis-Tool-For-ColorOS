#!/usr/bin/env bash
# 确定本次发版的 VERSION_NAME（四段 X.Y.Z.BUILD）与 versionCode（hybrid 7 位）。
# 真相源：
#   - stable：人工打的 git tag，格式 X.Y.Z.0（BUILD 必须为 0）
#   - beta  ：仓库根目录 VERSION 文件（X.Y.Z，手动维护）+ 服务器当前 beta 的第四位 BUILD + 1
# versionCode = MAJOR*1_000_000 + MINOR*10_000 + PATCH*100 + BUILD（每段 0-99）。
set -Eeuo pipefail
shopt -s inherit_errexit

CHANNEL=${1:?channel required (beta|stable)}
PROJECT=${2:?project prefix required}
VERSION_FILE=${3:-VERSION}
GIT_TAG=${4:-}

fail() { echo "::error::$1" >&2; exit 1; }

case "$CHANNEL" in
  beta|stable) ;;
  *) fail "CHANNEL 必须是 beta 或 stable，收到: $CHANNEL" ;;
esac

if [ "$CHANNEL" = "stable" ]; then
  [ -n "$GIT_TAG" ] || fail "stable 发版必须提供 git tag"
  [[ "$GIT_TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.0$ ]] || fail "stable tag 必须是 X.Y.Z.0，收到: $GIT_TAG"
  VERSION_NAME="$GIT_TAG"
else
  [ -f "$VERSION_FILE" ] || fail "缺少 $VERSION_FILE（内容应为 X.Y.Z，如 1.0.0）"
  XYZ=$(tr -d '[:space:]' < "$VERSION_FILE")
  [[ "$XYZ" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "$VERSION_FILE 必须是 X.Y.Z，收到: $XYZ"

  # beta 的 BUILD 真相源在服务器 beta/version.json。用 flock 包住「读→+1」临界区，
  # 防止同一 self-hosted runner 上并发 push 拿到相同 BUILD（workflow concurrency 之外的双保险）。
  LOCK_FILE="${TMPDIR:-/tmp}/${PROJECT}-beta-build.lock"
  exec 9>"$LOCK_FILE"
  flock -x 9

  # 不能直连 https://storage.horatio.cn/<PROJECT>/beta/version.json —— 那是 OpenList/AList 的
  # SPA 路由，返回的是前端 HTML（HTTP 200 但非 JSON），解析失败会让 BUILD 永远回退到 1。
  # 正确做法（AList `POST /api/fs/get` 返回 `data.raw_url` 签名字段，见 OpenList 文档与
  # server/handles/fsread.go 的 FsGetResp.RawURL）：先取 raw_url，再读真正的 version.json。
  RAW_URL=$(curl -fsS --max-time 20 \
    "https://storage.horatio.cn/api/fs/get?path=/$PROJECT/beta/version.json" 2>/dev/null \
    | python3 -c 'import sys,json
try:
 print(json.load(sys.stdin)["data"]["raw_url"])
except Exception:
 print("")' 2>/dev/null || true)

  CURRENT_NAME=""
  if [ -n "$RAW_URL" ]; then
    CURRENT_NAME=$(curl -fsS --max-time 20 "$RAW_URL" 2>/dev/null \
      | python3 -c 'import sys,json
try:
 print(json.load(sys.stdin).get("versionName",""))
except Exception:
 print("")' 2>/dev/null || true)
  fi

  if [[ "$CURRENT_NAME" == "$XYZ."* ]]; then
    BUILD=${CURRENT_NAME##*.}
    [[ "$BUILD" =~ ^[0-9]+$ ]] || fail "服务器当前 beta 版本第四位非法: $CURRENT_NAME"
    BUILD=$(( BUILD + 1 ))
  else
    BUILD=1
  fi
  [ "$BUILD" -ge 1 ] && [ "$BUILD" -le 99 ] || fail "BUILD 超出 1-99（当前 $BUILD）：请手动提升 $VERSION_FILE 的 PATCH 后重发"
  VERSION_NAME="$XYZ.$BUILD"
fi

IFS='.' read -r MAJ MIN PAT BLD <<< "$VERSION_NAME"
for seg in "$MAJ" "$MIN" "$PAT" "$BLD"; do
  [[ "$seg" =~ ^[0-9]+$ ]] && [ "$seg" -le 99 ] || fail "版本号每段必须 0-99: $VERSION_NAME"
done
VERSION_CODE=$(( MAJ * 1000000 + MIN * 10000 + PAT * 100 + BLD ))

# 单调校验：新版本必须严格大于同通道上一个已发布版本。
if [ "${SKIP_MONOTONIC_CHECK:-0}" != "1" ]; then
  if [ "$CHANNEL" = "beta" ] && [ -n "${CURRENT_NAME:-}" ]; then
    OLD_CODE=$(python3 - "$CURRENT_NAME" <<'PY'
import sys
try:
    a,b,c,d=(int(x) for x in sys.argv[1].split("."))
    print(a*1000000+b*10000+c*100+d)
except Exception:
    print(-1)
PY
)
    [ "$VERSION_CODE" -gt "$OLD_CODE" ] || fail "versionCode 回退: $VERSION_CODE <= $OLD_CODE ($CURRENT_NAME)"
  fi
  if [ "$CHANNEL" = "stable" ]; then
    PREV_TAG=$(git tag --list '*.*.*.0' --sort=-v:refname | grep -v "^${GIT_TAG}$" | head -1 || true)
    if [ -n "$PREV_TAG" ]; then
      OLD_CODE=$(python3 - "$PREV_TAG" <<'PY'
import sys
try:
    a,b,c,d=(int(x) for x in sys.argv[1].split("."))
    print(a*1000000+b*10000+c*100+d)
except Exception:
    print(-1)
PY
)
      [ "$VERSION_CODE" -gt "$OLD_CODE" ] || fail "stable versionCode 回退: $VERSION_CODE <= $OLD_CODE ($PREV_TAG)"
    fi
  fi
fi

echo "channel=$CHANNEL version_name=$VERSION_NAME version_code=$VERSION_CODE"
if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "CHANNEL=$CHANNEL"
    echo "VERSION=$VERSION_NAME"
    echo "VERSION_NAME=$VERSION_NAME"
    echo "VERSION_CODE=$VERSION_CODE"
  } >> "$GITHUB_ENV"
fi
