#!/usr/bin/env bash
# OpenList 通道回滚（由 .github/workflows/rollback-openlist.yml 调用）。
# 回滚 = 把通道指针重新指向一个已存在的不可变版本目录，绝不重新构建、不覆盖产物。
# 对标 2026 最佳实践：预检目标产物 → 备份当前指针 → 原子切换 → 外部 HTTP 验证 →
# 失败自动恢复 → 审计日志；删除一律先归档，不做不可逆 rm -rf。
#
# 用法（全部经 env 传入，禁止把外部输入拼进 shell）：
#   CHANNEL=stable TARGET_VERSION=1.2.3 [DROP_VERSION=1.2.4] \
#   [DRY_RUN=true] [PURGE=true] [CONFIRM=ROLLBACK] \
#   SERVER_HOST=.. SERVER_USER=.. SERVER_SSH_KEY=.. OPENLIST_STORAGE_DIR=.. \
#   bash ci/rollback-openlist.sh
set -Eeuo pipefail
shopt -s inherit_errexit

: "${SERVER_HOST:?SERVER_HOST is required}"
: "${SERVER_USER:?SERVER_USER is required}"
: "${SERVER_SSH_KEY:?SERVER_SSH_KEY is required}"
: "${OPENLIST_STORAGE_DIR:?OPENLIST_STORAGE_DIR is required}"
: "${CHANNEL:?CHANNEL is required}"
: "${TARGET_VERSION:?TARGET_VERSION is required}"
SSH_PORT="${SSH_PORT:-22}"
DRY_RUN="${DRY_RUN:-false}"
PURGE="${PURGE:-false}"
CONFIRM="${CONFIRM:-}"
DROP_VERSION="${DROP_VERSION:-}"
PRODUCT="ColorApkExtractor"
BASE_STORAGE="$OPENLIST_STORAGE_DIR/$PRODUCT"
TARGET_DIR="$BASE_STORAGE/$CHANNEL"
ARCHIVE_DIR="$TARGET_DIR/以前的版本"
AUDIT_LOG="$BASE_STORAGE/rollback.log"

fail() { echo "::error::$1" >&2; exit 1; }

# ---- 1. 输入校验（白名单，拒绝路径穿越与注入）----
case "$CHANNEL" in beta|stable) ;; *) fail "CHANNEL 必须是 beta 或 stable，收到: $CHANNEL" ;; esac
VER_RE='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'
[[ "$TARGET_VERSION" =~ $VER_RE ]] || fail "TARGET_VERSION 格式非法: $TARGET_VERSION"
if [ -n "$DROP_VERSION" ]; then
  [[ "$DROP_VERSION" =~ $VER_RE ]] || fail "DROP_VERSION 格式非法: $DROP_VERSION"
  [ "$DROP_VERSION" != "$TARGET_VERSION" ] || fail "DROP_VERSION 不能等于 TARGET_VERSION"
  [ "$CONFIRM" = "ROLLBACK" ] || fail "删除版本需要 CONFIRM=ROLLBACK（防误删）"
fi

KEY="$RUNNER_TEMP/openlist_key"
install -m 600 /dev/null "$KEY"
printf '%s\n' "$SERVER_SSH_KEY" > "$KEY"
trap 'rm -f "$KEY" "$RUNNER_TEMP/rollback-verify.txt"' EXIT
# SSH 主机密钥：优先用 SERVER_KNOWN_HOSTS secret 严格校验；未配置时本 run 内
# 用 ssh-keyscan 生成临时 known_hosts 并严格校验（TOFU 一次，避免 accept-new 的无校验风险）。
# 建议后续补 SERVER_KNOWN_HOSTS secret 以做跨 run 的固定校验。
KNOWN="$RUNNER_TEMP/known_hosts"
if [ -n "${SERVER_KNOWN_HOSTS:-}" ]; then
  printf '%s\n' "$SERVER_KNOWN_HOSTS" > "$KNOWN"
else
  ssh-keyscan -p "$SSH_PORT" -T 10 "$SERVER_HOST" 2>/dev/null > "$KNOWN" || fail "无法获取 $SERVER_HOST 主机密钥"
  echo "::warning::SERVER_KNOWN_HOSTS 未配置，本次用 ssh-keyscan 临时校验；建议补该 secret"
fi
SSH_OPTS=(-i "$KEY" -p "$SSH_PORT" -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$KNOWN")
run_ssh() { ssh "${SSH_OPTS[@]}" "$SERVER_USER@$SERVER_HOST" "bash -s" "$@"; }

echo "== [Rollback] product=$PRODUCT channel=$CHANNEL target=$TARGET_VERSION dry_run=$DRY_RUN =="
if [ "$DRY_RUN" = "true" ]; then
  echo "== [Rollback] DRY RUN：仅预检，不修改任何文件 =="
fi

# ---- 2. 远端预检 + 执行（单一 ssh 会话，脚本从 stdin 读入，参数用 argv 传递）----
run_ssh "$TARGET_DIR" "$ARCHIVE_DIR" "$TARGET_VERSION" "$DROP_VERSION" "$DRY_RUN" "$PURGE" "$AUDIT_LOG" "$PRODUCT" "$CHANNEL" <<'REMOTE'
set -Eeuo pipefail
TARGET_DIR="$1"; ARCHIVE_DIR="$2"; TARGET_VERSION="$3"; DROP_VERSION="$4"
DRY_RUN="$5"; PURGE="$6"; AUDIT_LOG="$7"; PRODUCT="$8"; CHANNEL="$9"
SNAPDIR="$TARGET_DIR/$TARGET_VERSION"
ARCHIVED="$ARCHIVE_DIR/$TARGET_VERSION"

# 2a. 预检目标版本目录：归档原件优先（含产物），其次通道根现有完整目录
RESTORE_SRC=""
if [ -d "$ARCHIVED" ]; then
  RESTORE_SRC="$ARCHIVED"
elif [ -f "$SNAPDIR/version.json" ] && [ -n "$(ls -A "$SNAPDIR"/*.apk "$SNAPDIR"/*.zip 2>/dev/null)" ]; then
  RESTORE_SRC="$SNAPDIR"
else
  echo "::error::目标版本 $TARGET_VERSION 在归档与通道根均不存在或产物缺失，拒绝回滚"; exit 1
fi
test -f "$RESTORE_SRC/version.json" || { echo "::error::目标缺 version.json"; exit 1; }
test -f "$RESTORE_SRC/README.md"   || { echo "::error::目标缺 README.md"; exit 1; }

# 2b. 解析目标产物文件名（新 schema：artifacts[].fileName；不信任其内容，做白名单校验）
APK_NAME=$(python3 -c 'import json,sys,re; d=json.load(open(sys.argv[1])); arts=d.get("artifacts",[]); n=arts[0].get("fileName","") if arts else ""; print(n if re.fullmatch(r"[0-9A-Za-z._-]+",n) else "")' "$RESTORE_SRC/version.json")
[ -n "$APK_NAME" ] || { echo "::error::version.json 的 artifacts[0].fileName 非法"; exit 1; }

echo "[rollback] 目标来源: $RESTORE_SRC / 产物: $APK_NAME"
[ "$DRY_RUN" = "true" ] && { echo "[rollback] DRY RUN 预检通过，未修改"; exit 0; }

# 2c. 备份当前指针（供失败恢复），并记录回滚前版本用于审计
BACKUP="$ARCHIVE_DIR/.rollback-backup-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$BACKUP"
OLD_VER=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("versionName","?"))' "$TARGET_DIR/version.json" 2>/dev/null || echo '?')
for f in version.json version.json.sig README.md; do [ -f "$TARGET_DIR/$f" ] && cp -p "$TARGET_DIR/$f" "$BACKUP/$f" || true; done

restore_pointer() {
  for f in version.json version.json.sig README.md; do [ -f "$BACKUP/$f" ] && mv -f "$BACKUP/$f" "$TARGET_DIR/$f" || true; done
  echo "[rollback] 已恢复回滚前指针"
}
trap 'restore_pointer' ERR

# 2d. 恢复目标版本目录（归档 → 通道根），再原子切换通道指针
if [ "$RESTORE_SRC" = "$ARCHIVED" ]; then
  rm -rf "$SNAPDIR" && mv "$ARCHIVED" "$SNAPDIR"
fi
for f in version.json version.json.sig README.md; do
  [ -f "$SNAPDIR/$f" ] || continue
  cp "$SNAPDIR/$f" "$TARGET_DIR/$f.tmp.$$" && mv -f "$TARGET_DIR/$f.tmp.$$" "$TARGET_DIR/$f"
done
trap - ERR

# 2e. 外部验证：下载链接必须能拿到真实文件（模拟客户端更新路径）
URL="https://storage.horatio.cn/$PRODUCT/$CHANNEL/$TARGET_VERSION/$APK_NAME"
if ! curl -fsS --max-time 20 -o /dev/null "$URL"; then
  echo "::error::切换后验证失败：下载链接不可用 $URL，已自动恢复指针"; restore_pointer; exit 1
fi
CURRENT_VER=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("versionName",""))' "$TARGET_DIR/version.json")
[ "$CURRENT_VER" = "$TARGET_VERSION" ] || { echo "::error::指针版本不一致，已恢复"; restore_pointer; exit 1; }

# 2f. 删除被撤回版本：默认仅归档，PURGE=true 才彻底删
if [ -n "$DROP_VERSION" ] && [ "$DROP_VERSION" != "$TARGET_VERSION" ]; then
  for loc in "$TARGET_DIR/$DROP_VERSION" "$ARCHIVE_DIR/$DROP_VERSION"; do
    [ -e "$loc" ] || continue
    if [ "$PURGE" = "true" ]; then
      rm -rf "$loc"; echo "[rollback] 已彻底删除 $loc"
    else
      mkdir -p "$ARCHIVE_DIR/已撤回"; mv "$loc" "$ARCHIVE_DIR/已撤回/$(basename "$loc")-$(date -u +%Y%m%dT%H%M%SZ)"
      echo "[rollback] 已归档撤回版本 $loc（未彻底删除）"
    fi
  done
fi

# 2g. 审计日志
printf '%s\t%s\t%s\t%s->%s\tdrop=%s\tpurge=%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${GITHUB_ACTOR:-local}" "$CHANNEL" "$OLD_VER" "$TARGET_VERSION" "$DROP_VERSION" "$PURGE" >> "$AUDIT_LOG"
echo "[rollback] 完成: $PRODUCT/$CHANNEL -> $TARGET_VERSION；审计已写入 $AUDIT_LOG"
REMOTE

echo "== [Rollback] 全部完成 =="
