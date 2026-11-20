#!/usr/bin/env bash
# Analysis-Tool 上传：8 平台 zip -> OpenList，生成 Wails 式 version.json（artifacts[] 8 条）+ 签名。
# 通道 beta / stable（无 alpha）。产物名 ColorApkExtractor-<四段VERSION>-<Platform>.zip。
set -Eeuo pipefail
shopt -s inherit_errexit

: "${SERVER_HOST:?SERVER_HOST is required}" \
  "${SERVER_USER:?SERVER_USER is required}" \
  "${SERVER_SSH_KEY:?SERVER_SSH_KEY is required}" \
  "${CHANNEL:?CHANNEL is required}" \
  "${VERSION:?VERSION is required (X.Y.Z.BUILD)}" \
  "${VERSION_CODE:?VERSION_CODE is required}" \
  "${OPENLIST_STORAGE_DIR:?OPENLIST_STORAGE_DIR is required}" \
  "${UPDATER_PRIVATE_KEY:?UPDATER_PRIVATE_KEY is required}"

case "$CHANNEL" in
  beta)   KEEP_VERSIONS=2 ;;
  stable) KEEP_VERSIONS=3 ;;
  *) echo "::error::CHANNEL 必须是 beta 或 stable"; exit 1 ;;
esac

SSH_PORT=${SSH_PORT:-22}
BASE_STORAGE="$OPENLIST_STORAGE_DIR/ColorApkExtractor"
TARGET_DIR="$BASE_STORAGE/$CHANNEL"
VERSION_DIR="$TARGET_DIR/$VERSION"
ARTIFACT_PREFIX=${ARTIFACT_PREFIX:-ColorApkExtractor}
ARTIFACT_DIR=${ARTIFACT_DIR:-.}

SSH_OPTS=(-i "$RUNNER_TEMP/openlist_key" -p "$SSH_PORT" -o StrictHostKeyChecking=accept-new -o BatchMode=yes)
run_ssh() { ssh "${SSH_OPTS[@]}" "$SERVER_USER@$SERVER_HOST" "bash -c $(printf '%q' "$1")"; }
run_scp() { scp -i "$RUNNER_TEMP/openlist_key" -P "$SSH_PORT" -o StrictHostKeyChecking=accept-new -o BatchMode=yes "$@"; }
trap 'rm -f "$RUNNER_TEMP/openlist_key"' EXIT
install -m 600 /dev/null "$RUNNER_TEMP/openlist_key"
printf '%s\n' "$SERVER_SSH_KEY" > "$RUNNER_TEMP/openlist_key"

echo "== [OpenList] 准备版本目录: $VERSION_DIR =="
run_ssh "mkdir -p '$VERSION_DIR'"
run_ssh "rm -f '$VERSION_DIR'/*.zip"

shopt -s nullglob
ARTIFACTS=("$ARTIFACT_DIR/$ARTIFACT_PREFIX-$VERSION"-*.zip)
if [ "${#ARTIFACTS[@]}" -eq 0 ]; then
  echo "::error::未找到产物: $ARTIFACT_DIR/$ARTIFACT_PREFIX-$VERSION-*.zip"; exit 1
fi
run_scp "${ARTIFACTS[@]}" "$SERVER_USER@$SERVER_HOST:$VERSION_DIR/"
echo "上传产物 $(printf '%s\n' "${ARTIFACTS[@]}" | wc -l) 个"

if [ -f release.md ]; then
  run_scp release.md "$SERVER_USER@$SERVER_HOST:$VERSION_DIR/README.md"
  run_scp release.md "$SERVER_USER@$SERVER_HOST:$TARGET_DIR/README.md"
fi

# version.json：每个 zip 一条 artifact，platform 为 Wails 风格 os-arch（小写）
echo "== [OpenList] 生成并签名 version.json =="
[ -s changelog.txt ] || { echo "::error::missing/empty changelog.txt"; exit 1; }
NOTES_JSON=$(python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' < changelog.txt)
VERSION_JSON_TMP="$RUNNER_TEMP/version.json"
# 记录构建该版本时的 commit，供下次发版算增量 changelog（不打 tag 方案的基准）。
# 用 CI 注入的 GITHUB_SHA（网络/CI 侧事实），不读本地 git —— 换 runner/环境无需改脚本。
: "${GITHUB_SHA:?GITHUB_SHA is required (CI injects it)}"
COMMIT_SHA="$GITHUB_SHA"
python3 - "$VERSION_JSON_TMP" "$ARTIFACT_DIR" "$ARTIFACT_PREFIX" "$VERSION" "$VERSION_CODE" "$CHANNEL" "$NOTES_JSON" "$COMMIT_SHA" <<'PY'
import hashlib, json, os, sys
out, adir, prefix, version, code, channel, notes, commit_sha = sys.argv[1:9]
BASE = "https://storage.horatio.cn/ColorApkExtractor"
# 平台目录名 -> Wails 风格 os-arch
PLAT = {
    # 平台名已是规范 os-arch（小写 + x86_64/arm64），直接作为 platform；未知值兜底小写
}
arts = []
needle = prefix + "-" + version + "-"
for fn in sorted(f for f in os.listdir(adir) if f.startswith(needle) and f.endswith(".zip")):
    tail = fn[len(needle):-4]              # 平台名
    platform = tail.lower()
    data = open(os.path.join(adir, fn), "rb").read()
    arts.append({
        "platform": platform, "fileName": fn,
        "url": f"{BASE}/{channel}/{version}/{fn}",
        "sha256": hashlib.sha256(data).hexdigest(), "size": len(data),
    })
if not arts:
    raise SystemExit("no artifact found")
doc = {
    "schemaVersion": 1, "versionName": version, "versionCode": int(code),
    "channel": channel, "publishedAt": os.popen("date -u +%Y-%m-%dT%H:%M:%SZ").read().strip(),
    # 构建该版本的 commit（npm provenance 的 Source Commit 同类做法），
    # 下次发版读它当 git log <prev>..HEAD 的增量基准；客户端验签忽略此未知字段。
    "commit": commit_sha,
    "notes": json.loads(notes), "artifacts": arts,
}
open(out, "w", encoding="utf-8").write(json.dumps(doc, ensure_ascii=False, indent=2) + "\n")
print(f"version.json: {version} code={code} artifacts={len(arts)}")
PY
bash "$(dirname "$0")/sign-manifest.sh" "$VERSION_JSON_TMP"
for DEST in "$TARGET_DIR" "$VERSION_DIR"; do
  run_scp "$VERSION_JSON_TMP" "$SERVER_USER@$SERVER_HOST:$DEST/version.json"
  run_scp "$VERSION_JSON_TMP.sig" "$SERVER_USER@$SERVER_HOST:$DEST/version.json.sig"
done
rm -f "$VERSION_JSON_TMP" "$VERSION_JSON_TMP.sig"

# 维护根目录卡片 + 归档清理
run_ssh "mkdir -p '$BASE_STORAGE/beta' '$BASE_STORAGE/stable'"
run_scp "$(dirname "$0")/storage-project-readme.md" "$SERVER_USER@$SERVER_HOST:$BASE_STORAGE/README.md"
ARCHIVE_SCRIPT=$(cat << 'EOF'
TARGET_DIR="$1"; CURRENT_VERSION="$2"; KEEP_VERSIONS="$3"
ARCHIVE_DIR="$TARGET_DIR/以前的版本"
rm -f "$TARGET_DIR"/*.zip "$TARGET_DIR"/*.txt 2>/dev/null || true
for dir in "$TARGET_DIR"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  if [ "$name" != "$CURRENT_VERSION" ] && [ "$name" != "以前的版本" ]; then
    mkdir -p "$ARCHIVE_DIR"; rm -rf "$ARCHIVE_DIR/$name"; mv "$dir" "$ARCHIVE_DIR/"
  fi
done
MAX_ARCHIVED=$((KEEP_VERSIONS - 1))
if [ "$MAX_ARCHIVED" -le 0 ]; then rm -rf "$ARCHIVE_DIR"
elif [ -d "$ARCHIVE_DIR" ]; then
  mapfile -t OLD_DIRS < <(ls -1td "$ARCHIVE_DIR"/*/ 2>/dev/null || true)
  COUNT="${#OLD_DIRS[@]}"
  if [ "$COUNT" -gt "$MAX_ARCHIVED" ]; then
    for ((i=MAX_ARCHIVED; i<COUNT; i++)); do rm -rf "${OLD_DIRS[i]}"; done
  fi
fi
EOF
)
run_ssh "bash -s -- '$TARGET_DIR' '$VERSION' '$KEEP_VERSIONS'" <<< "$ARCHIVE_SCRIPT"
echo "== [OpenList] 完成 =="
