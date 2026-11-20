#!/usr/bin/env bash
# Analysis-Tool 发版 prepare（由 release.yml 在 determine-version 之后调用）：
#   $1=<PROJECT>  $2=CHANNEL  $3=VERSION_NAME  $4=VERSION_CODE
# 生成 changelog.txt / release.md，调 pack-all.sh 打包 8 平台。
set -Eeuo pipefail
shopt -s inherit_errexit

PREFIX=${1:?project prefix required}
CHANNEL=${2:?channel required}
VERSION=${3:?version required}
VERSION_CODE=${4:?version code required}

DIR=$(dirname "$0")
# beta 不打 tag，增量基准 = 服务器当前通道 version.json 里记录的上一版 commit（见 upload-openlist-tool.sh）。
# 走 OpenList API 拿签名 raw_url 再读 JSON（直连页面路径会命中 SPA HTML）。
# 读不到（首版 / 服务器故障）→ PREV_COMMIT 为空 → gen-changelog 回退全量。
PREV_COMMIT=""
RAW_URL=$(curl -fsS --max-time 20 \
  "https://storage.horatio.cn/api/fs/get?path=/$PREFIX/$CHANNEL/version.json" 2>/dev/null \
  | python3 -c 'import sys,json
try:
 print(json.load(sys.stdin)["data"]["raw_url"])
except Exception:
 print("")' 2>/dev/null || true)
if [ -n "$RAW_URL" ]; then
  PREV_COMMIT=$(curl -fsS --max-time 20 "$RAW_URL" 2>/dev/null \
    | python3 -c 'import sys,json
try:
 print(json.load(sys.stdin).get("commit", ""))
except Exception:
 print("")' 2>/dev/null || true)
fi
# tag 只用来触发 stable 编译发版，不参与 changelog：基准一律走服务器 commit sha。
bash "$DIR/gen-changelog.sh" "" changelog.txt "$PREV_COMMIT"
cp changelog.txt release.md

# pack-all.sh 现在接收四段 VERSION（产物名 <PREFIX>-<VERSION>-<platform>.zip）
bash "$DIR/pack-all.sh" "$VERSION" "$PREFIX"
echo "8 平台产物就绪 (channel=$CHANNEL versionCode=$VERSION_CODE)"
