#!/usr/bin/env bash
# 发布前校验人工撰写的 release-notes.md；alpha 内测自动构建不读该文件，直接跳过。
# 规范见 ~/.config/opencode/templates/release-notes-style.md。
set -Eeuo pipefail
shopt -s inherit_errexit

: "${CHANNEL:?CHANNEL is required}"
NOTES_FILE="release-notes.md"

if [ "$CHANNEL" = "alpha" ]; then
  echo "[release-notes] alpha 通道跳过校验"
  exit 0
fi

if [ ! -f "$NOTES_FILE" ]; then
  echo "::error::$CHANNEL 构建缺少 $NOTES_FILE，请先按 ~/.config/opencode/templates/release-notes-style.md 编写"
  exit 1
fi
if ! grep -q '[^[:space:]]' "$NOTES_FILE"; then
  echo "::error::$NOTES_FILE 为空或只有空白字符"
  exit 1
fi

if grep -nE '^[[:space:]]*(feat|fix|perf)(\([^)]*\))?:' "$NOTES_FILE"; then
  echo "::error::$NOTES_FILE 含原始提交前缀（feat:/fix:/perf:），请改写成用户能看懂的描述"
  exit 1
fi
if grep -nF '修复了一些已知问题' "$NOTES_FILE"; then
  echo "::error::$NOTES_FILE 含禁用空话「修复了一些已知问题」，请写明具体变更"
  exit 1
fi

# 首行必须是普通句子：一句话说明本次更新，不能是 Markdown 标题、列表或分类名。
FIRST=$(grep -m1 '[^[:space:]]' "$NOTES_FILE" | sed 's/^[[:space:]]*//' || true)
case "$FIRST" in
  \#*|'>'*|'-'*|'*'*|新增|改进|修复)
    echo "::error::$NOTES_FILE 首行须为普通句子，不能是标题/列表/分类名：$FIRST"
    exit 1
    ;;
esac

echo "[release-notes] $CHANNEL 校验通过"
