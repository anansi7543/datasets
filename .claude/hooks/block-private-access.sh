#!/usr/bin/env bash
# PreToolUse hook (matcher: Read|Grep|Glob|Write|Edit|mcp__.*)
# CLAUDE.md: "private/ 폴더가 있다면 절대 읽거나 인용하지 않는다."
# 이 훅은 지침이 아니라 강제다 — private/ 하위 경로를 대상으로 하는
# 도구 호출은 모델의 판단과 무관하게 항상 차단한다.
set -euo pipefail

PY=""
for cand in python3 python; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c "" >/dev/null 2>&1; then
    PY="$cand"
    break
  fi
done
[ -z "$PY" ] && exit 0

input="$(cat)"

is_private="$(printf '%s' "$input" | "$PY" -c '
import json, sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool_input = data.get("tool_input", {}) or {}

# Read/Write/Edit -> file_path, Grep/Glob -> path, 그 외 도구 대비 폭넓게 검사
candidates = []
for key in ("file_path", "path", "notebook_path", "directory"):
    value = tool_input.get(key)
    if isinstance(value, str):
        candidates.append(value)

normalized = [c.replace("\\", "/") for c in candidates]

def hits_private(p):
    p = p.strip()
    stripped = p.rstrip("/")
    return (
        "/private/" in p
        or stripped == "private"
        or stripped.endswith("/private")
        or p.startswith("private/")
    )

blocked = any(hits_private(c) for c in normalized)
print("1" if blocked else "0")
')"

if [ "$is_private" = "1" ]; then
  echo "private/ 폴더는 AI 접근이 금지되어 있습니다 (CLAUDE.md 참고)." >&2
  exit 2
fi

exit 0
