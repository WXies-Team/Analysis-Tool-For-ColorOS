#!/usr/bin/env bash
# 由 Conventional Commits 自动生成用户向 changelog（纯文本分组）。
# 规则（对齐 Keep a Changelog + Conventional Commits 最佳实践）：
#   feat -> ✨ 新增 ; fix/revert -> 🐛 修复 ; perf -> ⚡ 改进
#   隐藏：ci/chore/docs/build/refactor/test/style 与 fix(ci)
#   去掉 scope 前缀：feat(ui): 骨架屏 -> 骨架屏
# 两通道同源、全自动、无人工审核；结果同时供应用内弹窗 / version.json / GitHub Release 使用。
set -Eeuo pipefail
shopt -s inherit_errexit

LAST_TAG=${1:-}
OUT=${2:-changelog.txt}

if [ -n "$LAST_TAG" ] && git rev-parse -q --verify "$LAST_TAG" >/dev/null; then
  RANGE="${LAST_TAG}..HEAD"
else
  RANGE="HEAD"
fi

git log --no-merges --pretty=format:'%s%n%b%x00' "$RANGE" \
  | python3 -c '
import sys
raw = sys.stdin.read()
segs = [s.strip() for s in raw.split("\0") if s.strip()]
sections = {"feat": [], "fix": [], "perf": []}
import re
for seg in segs:
    lines = seg.splitlines()
    if not lines:
        continue
    subject = lines[0].strip()
    m = re.match(r"^([a-z]+)(?:\([^)]*\))?(!)?:\s*(.+)$", subject)
    if not m:
        continue
    typ, bang, desc = m.group(1), m.group(2), m.group(3).strip()
    # 隐藏非用户可见类型；fix(ci) 单独隐藏（scope 在冒号前的括号里）
    scope_m = re.match(r"^[a-z]+\(([^)]*)\)", subject)
    scope = scope_m.group(1) if scope_m else ""
    if typ in {"ci","chore","docs","build","refactor","test","style"}:
        continue
    if typ == "fix" and scope == "ci":
        continue
    if typ not in sections:
        continue
    text = desc
    if bang:
        text = "【破坏性变更】" + text
    sections[typ].append(text)

order = [("feat","✨ 新增"),("fix","🐛 修复"),("perf","⚡ 改进")]
out = []
for key, label in order:
    if sections[key]:
        out.append(label)
        seen = set()
        for t in sections[key]:
            if t not in seen:
                seen.add(t)
                out.append("- " + t)
print("\n".join(out))
' > "$OUT"

if [ ! -s "$OUT" ]; then
  echo "::error::生成的 changelog.txt 为空（该区间无用户可见变更），拒绝发布空文案"
  exit 1
fi
echo "changelog 已生成: $OUT ($(wc -l < "$OUT") 行)"
