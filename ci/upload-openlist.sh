#!/usr/bin/env bash
# 严格遵循 ~/.config/opencode/docs/versioning.md 规范
# 将构建产物与更新日志上传至服务器 OpenList 目录，并按通道策略自动归档与清理旧版本。
# 通道保留策略：
#   alpha  : 保留最新 1 版
#   beta   : 保留最新 2 版
#   stable : 保留最新 3 版
set -Eeuo pipefail
shopt -s inherit_errexit

: "${SERVER_HOST:?SERVER_HOST is required}" \
  "${SERVER_USER:?SERVER_USER is required}" \
  "${SERVER_SSH_KEY:?SERVER_SSH_KEY is required}" \
  "${CHANNEL:?CHANNEL is required}" \
  "${VERSION:?VERSION is required}" \
  "${BUILD_ID:?BUILD_ID is required}" \
  "${OPENLIST_STORAGE_DIR:?OPENLIST_STORAGE_DIR is required}"

SSH_PORT=${SSH_PORT:-22}
# OPENLIST_STORAGE_DIR 是 OpenList 存储根（Actions secret SERVER_OPENLIST_DIR），
# 本项目的分发目录 Analysis-Tool-For-ColorOS 与遗留垃圾目录 storage 都挂在它下面。
BASE_STORAGE="$OPENLIST_STORAGE_DIR/Analysis-Tool-For-ColorOS"
TARGET_DIR="$BASE_STORAGE/$CHANNEL"
VERSION_DIR="$TARGET_DIR/$VERSION"

# 构建产物：Analysis-Tool-For-ColorOS-<version>-<Platform>-<arch>.zip
ARTIFACT_PREFIX=${ARTIFACT_PREFIX:-Analysis-Tool-For-ColorOS}
ARTIFACT_DIR=${ARTIFACT_DIR:-.}
# version.json 里作为默认下载的那个产物（Linux x86_64 覆盖面最大）
PRIMARY_ARTIFACT=${PRIMARY_ARTIFACT:-Linux-x86_64}

case "$CHANNEL" in
  alpha)  KEEP_VERSIONS=1 ;;
  beta)   KEEP_VERSIONS=2 ;;
  stable) KEEP_VERSIONS=3 ;;
  *)      KEEP_VERSIONS=3 ;;
esac

SSH_OPTS=(-i "$RUNNER_TEMP/openlist_key" -p "$SSH_PORT" -o StrictHostKeyChecking=accept-new -o BatchMode=yes)
run_ssh() { ssh "${SSH_OPTS[@]}" "$SERVER_USER@$SERVER_HOST" "bash -c $(printf '%q' "$1")"; }
run_scp() { scp -i "$RUNNER_TEMP/openlist_key" -P "$SSH_PORT" -o StrictHostKeyChecking=accept-new -o BatchMode=yes "$@"; }

cleanup_key() { rm -f "$RUNNER_TEMP/openlist_key"; }
cleanup_key
trap cleanup_key EXIT

install -m 600 /dev/null "$RUNNER_TEMP/openlist_key"
printf '%s\n' "$SERVER_SSH_KEY" > "$RUNNER_TEMP/openlist_key"

echo "== [OpenList] 准备版本目录: $VERSION_DIR =="
run_ssh "mkdir -p '$VERSION_DIR'"
# Legacy junk directory cleanup is opt-in: some projects legitimately keep storage/.
if [ "${OPENLIST_CLEAN_LEGACY_STORAGE:-0}" = "1" ]; then
  run_ssh "if [ -d '$OPENLIST_STORAGE_DIR/storage' ]; then rm -rf '$OPENLIST_STORAGE_DIR/storage'; fi" || true
fi

# 1. 上传构建产物至版本号文件夹
echo "== [OpenList] 上传构建产物至 $VERSION_DIR =="
# 版本目录由 CI 独占：先清掉该目录下已有的 zip（历史命名、重传残留），
# 保证目录内容与本次产物逐字一致——否则改名/重跑会出现新旧两套文件。
run_ssh "rm -f '$VERSION_DIR'/*.zip"
shopt -s nullglob
ARTIFACTS=("$ARTIFACT_DIR/$ARTIFACT_PREFIX-$VERSION"-*.zip)
if [ "${#ARTIFACTS[@]}" -eq 0 ]; then
  echo "::error::未找到待上传的产物: $ARTIFACT_DIR/$ARTIFACT_PREFIX-$VERSION-*.zip"
  exit 1
fi
run_scp "${ARTIFACTS[@]}" "$SERVER_USER@$SERVER_HOST:$VERSION_DIR/"

# 2. 将 release.md 同步为该版本目录及通道目录的 README.md，供 OpenList 自动渲染
if [ -f release.md ]; then
  echo "== [OpenList] 同步 release.md 为 README.md =="
  run_scp release.md "$SERVER_USER@$SERVER_HOST:$VERSION_DIR/README.md"
  run_scp release.md "$SERVER_USER@$SERVER_HOST:$TARGET_DIR/README.md"
fi

# 2.5 生成并上传 version.json 元数据（供网页 / 检查更新直接拉取）
echo "== [OpenList] 生成 version.json =="
VERSION_JSON_TMP="$RUNNER_TEMP/version.json"
FILE_NAME="$ARTIFACT_PREFIX-$VERSION-$BUILD_ID-$PRIMARY_ARTIFACT.zip"
DOWNLOAD_URL="https://storage.horatio.cn/Analysis-Tool-For-ColorOS/$CHANNEL/$VERSION/$FILE_NAME"

# version.json 的 sha256 必须对 **download_url 指向的那个产物** 算——校验的正是
# 用户下载下来的文件，算成别的包就永远对不上。
# 算不出来 = 没有它客户端就不再走自动更新，发布出去只会让用户卡在更新页，
# 所以这里直接让这一步失败，而不是留个空值发布出去。
ARTIFACT_SHA256=""
if [ -f "$ARTIFACT_DIR/$FILE_NAME" ]; then
  ARTIFACT_SHA256=$(sha256sum "$ARTIFACT_DIR/$FILE_NAME" | cut -d' ' -f1)
fi
if [ -z "$ARTIFACT_SHA256" ]; then
  echo "::error::未找到 $ARTIFACT_DIR/$FILE_NAME，无法生成 version.json 的 sha256"
  exit 1
fi

# 默认下载产物的字节数，供客户端展示下载体积；与 sha256 取自同一个文件。
ARTIFACT_SIZE=$(stat -c%s "$ARTIFACT_DIR/$FILE_NAME")

# changelog must come from plain-text changelog.txt. release.md is Markdown and must never
# leak into the in-app dialog; a missing changelog is a release bug, not a reason for filler copy.
if [ ! -s changelog.txt ]; then
  echo "::error::missing or empty changelog.txt — refusing to publish filler update copy"
  exit 1
fi
CHANGELOG_ESCAPED=$(python3 -c 'import sys, json; print(json.dumps(sys.stdin.read()))' < changelog.txt)

cat << EOF > "$VERSION_JSON_TMP"
{
  "channel": "$CHANNEL",
  "version_name": "$VERSION",
  "version_code": $BUILD_ID,
  "build_id": $BUILD_ID,
  "file_name": "$FILE_NAME",
  "download_url": "$DOWNLOAD_URL",
  "sha256": "$ARTIFACT_SHA256",
  "size_bytes": $ARTIFACT_SIZE,
  "changelog": $CHANGELOG_ESCAPED,
  "updated_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF

run_scp "$VERSION_JSON_TMP" "$SERVER_USER@$SERVER_HOST:$TARGET_DIR/version.json"
run_scp "$VERSION_JSON_TMP" "$SERVER_USER@$SERVER_HOST:$VERSION_DIR/version.json"
rm -f "$VERSION_JSON_TMP"

# 3. 维护项目根目录的版本选择卡片 README.md，供 OpenList 自动渲染。
#    卡片内容统一由 ci/storage-project-readme.md 提供（registry.yaml 分发），
#    不再在各仓库脚本内重复内嵌 HTML，避免风格漂移与过时文案。
echo "== [OpenList] 维护项目根目录版本选择卡片 README.md =="
run_ssh "mkdir -p '$BASE_STORAGE/alpha' '$BASE_STORAGE/beta' '$BASE_STORAGE/stable'"
run_scp "$(dirname "$0")/storage-project-readme.md" "$SERVER_USER@$SERVER_HOST:$BASE_STORAGE/README.md"

# 4. 归档与清理旧版本：将同通道下的历史版本移入「以前的版本」，并按 1/2/3 策略保留
echo "== [OpenList] 归档旧版本至 以前的版本/ 并清理 (通道: $CHANNEL, 总保留数: $KEEP_VERSIONS) =="
ARCHIVE_SCRIPT=$(cat << 'EOF'
TARGET_DIR="$1"
CURRENT_VERSION="$2"
KEEP_VERSIONS="$3"
ARCHIVE_DIR="$TARGET_DIR/以前的版本"

# 清理同级目录下遗留的旧散落文件（若有）
rm -f "$TARGET_DIR"/Analysis-Tool-For-*.zip "$TARGET_DIR"/Analysis-Tool-For-*.txt 2>/dev/null || true

# 将当前通道根目录下非当前版本的版本号文件夹移入「以前的版本」
for dir in "$TARGET_DIR"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  if [ "$name" != "$CURRENT_VERSION" ] && [ "$name" != "以前的版本" ]; then
    echo "归档旧版本目录: $name -> 以前的版本/$name"
    mkdir -p "$ARCHIVE_DIR"
    rm -rf "$ARCHIVE_DIR/$name"
    mv "$dir" "$ARCHIVE_DIR/"
  fi
done

# 计算「以前的版本」中允许保留的旧版本数量
MAX_ARCHIVED=$((KEEP_VERSIONS - 1))

if [ "$MAX_ARCHIVED" -le 0 ]; then
  # Alpha（仅保留最新 1 版）：无需归档旧版，清理「以前的版本」目录
  if [ -d "$ARCHIVE_DIR" ]; then
    echo "通道 $TARGET_DIR 仅保留最新 1 版，清理整个 以前的版本 目录"
    rm -rf "$ARCHIVE_DIR"
  fi
else
  # Beta（保留 2 版）、Stable（保留 3 版）：保留最新归档，超出部分清理
  if [ -d "$ARCHIVE_DIR" ]; then
    mapfile -t OLD_DIRS < <(ls -1td "$ARCHIVE_DIR"/*/ 2>/dev/null || true)
    COUNT="${#OLD_DIRS[@]}"
    echo "当前「以前的版本」中已有旧版本数: $COUNT，允许归档数: $MAX_ARCHIVED"
    if [ "$COUNT" -gt "$MAX_ARCHIVED" ]; then
      for ((i=MAX_ARCHIVED; i<COUNT; i++)); do
        echo "清理超出保留期限的旧版本: ${OLD_DIRS[i]}"
        rm -rf "${OLD_DIRS[i]}"
      done
    fi
  fi
fi
EOF
)
run_ssh "bash -s -- '$TARGET_DIR' '$VERSION' '$KEEP_VERSIONS'" <<< "$ARCHIVE_SCRIPT"

echo "== [OpenList] 同步、归档与清理全部完成 =="
