#!/usr/bin/env bash
# Analysis-Tool 的 semantic-release publish 钩子：
#   $1=VERSION  $2=branch  $3=<PROJECT>
# 映射通道与产物变量后调用仓库自带的 upload-openlist.sh（它接受 ARTIFACT_DIR/PREFIX/PRIMARY）。
set -Eeuo pipefail
shopt -s inherit_errexit

VERSION=${1:?version required}
BRANCH=${2:?branch required}
PREFIX=${3:?project prefix required}

case "$BRANCH" in
  main)   CHANNEL=stable ;;
  beta)   CHANNEL=beta ;;
  *)      CHANNEL="$BRANCH" ;;
esac

export VERSION CHANNEL
export BUILD_ID="${GITHUB_RUN_NUMBER:-1}"
export ARTIFACT_DIR=output
export ARTIFACT_PREFIX="$PREFIX"
export PRIMARY_ARTIFACT=Linux-x86_64

bash "$(dirname "$0")/upload-openlist.sh"
