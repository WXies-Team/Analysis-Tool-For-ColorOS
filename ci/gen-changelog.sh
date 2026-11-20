#!/usr/bin/env bash
# 由 Conventional Commits 自动生成用户向 changelog（纯文本分组）。
# 规则（对齐 Keep a Changelog + Conventional Commits 最佳实践）：
#   feat -> ✨ 新增 ; fix/revert -> 🐛 修复 ; perf -> ⚡ 改进
#   隐藏：ci/chore/docs/build/refactor/test/style 与 fix(ci)
#   去掉 scope 前缀：feat(ui): 骨架屏 -> 骨架屏
# 两通道同源、全自动、无人工审核；结果同时供应用内弹窗 / version.json / GitHub Release 使用。
set -Eeuo pipefail
shopt -s inherit_errexit

LAST_TAG=${1:-}   # 兼容旧调用的参数位；tag 已不再作为 changelog 基准（tag 只触发 stable 发版）
OUT=${2:-changelog.txt}
# 增量基准：上一版 version.json 里记录的 commit SHA（beta/stable 同机制，都从服务器网络读取）。
# 「.1→.2 只显示这段 commit」。tag 不参与 changelog。
PREV_COMMIT=${3:-}

if [ -n "$PREV_COMMIT" ] && git rev-parse -q --verify "$PREV_COMMIT^{commit}" >/dev/null 2>&1; then
  RANGE="${PREV_COMMIT}..HEAD"
else
  # 首版（服务器上还没有上一版 commit）：全量历史，符合「从零开始」。
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
sys.stdout.write("\n".join(out))  # 空列表写 0 字节（print 会输出换行，导致 -s 误判非空）
' > "$OUT"

if [ ! -s "$OUT" ]; then
  # 区间内无用户可见变更（如纯 ci/docs 提交触发的发版）不能拒绝发布——
  # 否则整条发版链路挂掉。写一句中性说明，与客户端「本次更新未附带更新说明」兜底呼应。
  echo "本次更新未附带更新说明" > "$OUT"
  echo "::notice::区间无用户可见变更，使用中性兜底文案"
fi
echo "changelog 已生成: $OUT ($(wc -l < "$OUT") 行)"
