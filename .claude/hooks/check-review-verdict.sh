#!/usr/bin/env bash
# TaskCompleted hook (Agent Team) — code-reviewer.md는 되돌릴 수 없는
# 결함을 발견하면 응답에 정확히 "치명적 오류"라는 문구를 남기도록
# 지시받는다. 이 훅은 그 문구가 담긴 채 태스크가 완료 처리되는 것을
# 지침이 아니라 강제로 막는다(강의 9.4절 품질 게이트 패턴).
#
# TaskCompleted 이벤트의 정확한 JSON 필드명(결과 텍스트가 어디에
# 담기는지)은 실험적 기능이라 문서화가 얕으므로, 특정 키에 의존하지
# 않고 stdin 전체에서 문구를 검색해 스키마 변경에도 견고하게 만든다.
set -euo pipefail

input="$(cat)"

if printf '%s' "$input" | grep -q "치명적 오류"; then
  echo "리뷰에서 '치명적 오류'가 발견되어 이 태스크를 완료 처리할 수 없습니다. 코드 작성자에게 재작업을 요청하세요." >&2
  exit 2
fi

exit 0
