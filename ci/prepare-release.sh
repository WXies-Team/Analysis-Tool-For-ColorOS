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
LAST_STABLE=$(git tag --list '*.*.*.0' --sort=-v:refname | head -1 || true)
bash "$DIR/gen-changelog.sh" "$LAST_STABLE" changelog.txt
cp changelog.txt release.md

# pack-all.sh 现在接收四段 VERSION（产物名 <PREFIX>-<VERSION>-<platform>.zip）
bash "$DIR/pack-all.sh" "$VERSION" "$PREFIX"
echo "8 平台产物就绪 (channel=$CHANNEL versionCode=$VERSION_CODE)"
