#!/usr/bin/env bash
# 严格遵循 docs/VERSIONING.md 规范
# 将构建产物与更新日志上传至服务器 OpenList 目录，并按通道策略自动归档与清理旧版本。
# 通道保留策略：
#   alpha  : 保留最新 1 版
#   beta   : 保留最新 2 版
#   stable : 保留最新 3 版
set -euo pipefail

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
run_ssh "if [ -d '$OPENLIST_STORAGE_DIR/storage' ]; then rm -rf '$OPENLIST_STORAGE_DIR/storage'; fi" || true

# 1. 上传构建产物至版本号文件夹
echo "== [OpenList] 上传构建产物至 $VERSION_DIR =="
mapfile -t ARTIFACTS < <(ls "$ARTIFACT_DIR/$ARTIFACT_PREFIX-$VERSION"-*.zip 2>/dev/null || true)
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

# changelog 优先取纯文本 changelog.txt（避免与日志开头重复）；
# 缺失时回退 release.md 全文，再回退默认文案
CHANGELOG_ESCAPED="\"$VERSION 更新\""
if [ -f changelog.txt ]; then
  CHANGELOG_ESCAPED=$(cat changelog.txt | python3 -c 'import sys, json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"$VERSION 更新\"")
elif [ -f release.md ]; then
  CHANGELOG_ESCAPED=$(cat release.md | python3 -c 'import sys, json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"$VERSION 更新\"")
fi

cat << EOF > "$VERSION_JSON_TMP"
{
  "channel": "$CHANNEL",
  "version_name": "$VERSION",
  "version_code": $BUILD_ID,
  "build_id": $BUILD_ID,
  "file_name": "$FILE_NAME",
  "download_url": "$DOWNLOAD_URL",
  "changelog": $CHANGELOG_ESCAPED,
  "updated_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF

run_scp "$VERSION_JSON_TMP" "$SERVER_USER@$SERVER_HOST:$TARGET_DIR/version.json"
run_scp "$VERSION_JSON_TMP" "$SERVER_USER@$SERVER_HOST:$VERSION_DIR/version.json"
rm -f "$VERSION_JSON_TMP"

# 3. 维护项目根目录的版本选择美化卡片 README.md，供 OpenList 自动渲染
echo "== [OpenList] 维护 Analysis-Tool-For-ColorOS 根目录版本选择卡片 README.md =="
run_ssh "mkdir -p '$BASE_STORAGE/alpha' '$BASE_STORAGE/beta' '$BASE_STORAGE/stable'"
INDEX_README_TMP="$RUNNER_TEMP/hyperos_index_readme.md"
cat << 'EOF' > "$INDEX_README_TMP"
<div style="max-width: 780px; margin: 0 auto; padding: 4px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
<div style="text-align: center; margin: 16px 0 20px 0;">
<div style="font-size: 22px; font-weight: 700; margin-bottom: 6px;">🔧 Analysis Tool For ColorOS 下载中心</div>
<div style="font-size: 13px; opacity: 0.75;">根据使用需求选择对应版本通道 · 各通道独立保留与更新</div>
</div>
<div style="display: flex; flex-direction: column; gap: 14px;">
<a href="/Analysis-Tool-For-ColorOS/stable/" style="display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-radius: 14px; border: 1px solid rgba(125,125,125,0.22); background: rgba(125,125,125,0.05); text-decoration: none; color: inherit; box-sizing: border-box;">
<div style="display: flex; flex-direction: column; gap: 6px; min-width: 0;">
<div style="display: flex; align-items: center; gap: 8px;">
<span style="font-size: 16px; font-weight: 600;">📁 正式版 (Stable)</span>
<span style="font-size: 11px; padding: 2px 8px; border-radius: 20px; background: rgba(34,197,94,0.18); color: #16a34a; font-weight: 600;">推荐日常</span>
</div>
<div style="font-size: 13px; opacity: 0.75; line-height: 1.4;">经过充分验证的稳定版本，功能完善且经过多轮测试 · 保留最新 3 版</div>
</div>
<div style="font-size: 13px; font-weight: 600; color: #16a34a; white-space: nowrap; margin-left: 16px; flex-shrink: 0;">进入通道 →</div>
</a>
<a href="/Analysis-Tool-For-ColorOS/beta/" style="display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-radius: 14px; border: 1px solid rgba(125,125,125,0.22); background: rgba(125,125,125,0.05); text-decoration: none; color: inherit; box-sizing: border-box;">
<div style="display: flex; flex-direction: column; gap: 6px; min-width: 0;">
<div style="display: flex; align-items: center; gap: 8px;">
<span style="font-size: 16px; font-weight: 600;">📁 公测版 (Beta)</span>
<span style="font-size: 11px; padding: 2px 8px; border-radius: 20px; background: rgba(234,88,12,0.18); color: #ea580c; font-weight: 600;">先行尝鲜</span>
</div>
<div style="font-size: 13px; opacity: 0.75; line-height: 1.4;">包含已进入公测候选的新特性与界面交互，欢迎体验与反馈 · 保留最新 2 版</div>
</div>
<div style="font-size: 13px; font-weight: 600; color: #ea580c; white-space: nowrap; margin-left: 16px; flex-shrink: 0;">进入通道 →</div>
</a>
<a href="/Analysis-Tool-For-ColorOS/alpha/" style="display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-radius: 14px; border: 1px solid rgba(125,125,125,0.22); background: rgba(125,125,125,0.05); text-decoration: none; color: inherit; box-sizing: border-box;">
<div style="display: flex; flex-direction: column; gap: 6px; min-width: 0;">
<div style="display: flex; align-items: center; gap: 8px;">
<span style="font-size: 16px; font-weight: 600;">📁 内测版 (Alpha)</span>
<span style="font-size: 11px; padding: 2px 8px; border-radius: 20px; background: rgba(147,51,234,0.18); color: #9333ea; font-weight: 600;">每日构建</span>
</div>
<div style="font-size: 13px; opacity: 0.75; line-height: 1.4;">主分支自动化 CI 每次构建，提供全平台压缩包 · 仅保留最新 1 版</div>
</div>
<div style="font-size: 13px; font-weight: 600; color: #9333ea; white-space: nowrap; margin-left: 16px; flex-shrink: 0;">进入通道 →</div>
</a>
</div>
</div>
EOF

run_scp "$INDEX_README_TMP" "$SERVER_USER@$SERVER_HOST:$BASE_STORAGE/README.md"
rm -f "$INDEX_README_TMP"

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
