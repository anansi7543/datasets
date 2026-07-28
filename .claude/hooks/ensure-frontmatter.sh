#!/usr/bin/env bash
# PostToolUse hook (matcher: Write)
# CLAUDE.md 컨벤션: 모든 노트는 frontmatter에 project, tags, created 필드를 포함해야 한다.
# 이 훅은 Write 직후 대상 파일을 검사해 누락된 필드만 채운다. 기존 값은 절대 덮어쓰지 않는다.
set -euo pipefail

# Windows Git Bash에서는 "python3"가 MS Store stub으로 연결되어 아무 동작도
#하지 않을 수 있으므로, 실제로 실행되는 인터프리터를 찾아서 사용한다.
PY=""
for cand in python3 python; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c "" >/dev/null 2>&1; then
    PY="$cand"
    break
  fi
done
[ -z "$PY" ] && exit 0

input="$(cat)"

file_path="$(printf '%s' "$input" | "$PY" -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(data.get("tool_input", {}).get("file_path", ""))
')"

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

case "$file_path" in
  *.md) ;;
  *) exit 0 ;;
esac

# CLAUDE.md의 "하지 말아야 할 것" / 구조상 손대면 안 되는 경로는 건너뛴다.
case "$file_path" in
  */04-Archives/*)        exit 0 ;;  # 보관 노트는 내용(프론트매터 포함) 수정 금지
  */private/*|*/private)  exit 0 ;;  # private/ 는 읽지도 쓰지도 않는다
  */Templates/*)          exit 0 ;;  # 템플릿은 실제 노트가 아니므로 대상 아님
  */.obsidian/*|*/.smart-env/*|*/.git/*|*/.cluade/*|*/.claude/*)
                           exit 0 ;;  # 시스템/설정 파일
  */README.md|README.md|*/CLAUDE.md|CLAUDE.md)
                           exit 0 ;;  # 볼트/프로젝트 메타 문서는 PARA 노트가 아님
esac

"$PY" - "$file_path" <<'PYEOF'
import re
import sys
from datetime import date

# Windows 콘솔 기본 코드페이지(cp949 등)에서 한글 출력이 깨지는 것을 방지.
try:
    sys.stdout.reconfigure(encoding="utf-8")
except AttributeError:
    pass

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

fm_match = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n?", content, re.DOTALL)
body = content[fm_match.end():] if fm_match else content
fm_body = fm_match.group(1) if fm_match else ""
fm_lines = fm_body.splitlines() if fm_body else []

existing_keys = {
    line.split(":", 1)[0].strip().strip('"')
    for line in fm_lines
    if re.match(r'^"?[A-Za-z0-9_-]+"?\s*:', line)
}

# 01-Projects/{프로젝트명}/... 형태 경로나 Sessions/YYYY-MM-DD-{프로젝트명}.md
# 파일명 컨벤션에서 프로젝트명을 유추한다. 못 찾으면 빈 문자열로 둔다.
project = ""
parts = path.replace("\\", "/").split("/")
for base in ("01-Projects", "02-Areas"):
    if base in parts:
        idx = parts.index(base)
        if idx + 1 < len(parts) - 1:  # 폴더 하위에 있고, 그 자체가 파일명이 아닐 때
            project = parts[idx + 1]
        break
if not project:
    fname = parts[-1]
    m = re.match(r"^\d{4}-\d{2}-\d{2}-(.+)\.md$", fname)
    if m:
        project = m.group(1)

new_lines = list(fm_lines)
if "project" not in existing_keys:
    new_lines.append(f'project: "{project}"')
if "tags" not in existing_keys:
    new_lines.append("tags: []")
if "created" not in existing_keys:
    new_lines.append(f"created: {date.today().isoformat()}")

if new_lines == fm_lines:
    sys.exit(0)  # 이미 필요한 필드가 모두 있음 — 변경 없음

new_fm = "\n".join(new_lines)
new_content = f"---\n{new_fm}\n---\n{body}"

with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(new_content)

print(f"ensure-frontmatter: {path} 의 frontmatter를 보강했습니다.")
PYEOF
