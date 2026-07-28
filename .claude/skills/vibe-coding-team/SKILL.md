---
name: vibe-coding-team
description: 기획자·코드 작성자·코드 리뷰어 3명으로 구성된 Agent Team을
  스폰해 프로젝트를 기획→구현→리뷰까지 한 번에 진행한다.
  "/vibe-coding-team {프로젝트명} {작업 설명}"으로 명시 호출.
disable-model-invocation: true
argument-hint: [프로젝트명] [작업 설명]
---

# 바이브 코딩 팀 실행

$ARGUMENTS를 프로젝트명과 작업 설명으로 해석해 아래 절차를 진행한다.

1. `01-Projects/{프로젝트명}/`이 없으면 생성한다.
2. Agent Team을 스폰해 3명의 팀원을 만든다(활성화에는
   `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 환경변수가 필요하며,
   `.claude/settings.json`에 이미 설정되어 있다):
   - **기획자**: `.claude/agents/planner.md`의 역할 정의를 스폰
     프롬프트에 그대로 인용한다. 첫 작업으로 반드시
     `session-searcher` 서브에이전트를 호출해 과거 관련 세션을
     찾도록 지시한다.
   - **코드 작성자**: `.claude/agents/coder.md`의 역할 정의를 인용한다.
   - **코드 리뷰어**: `.claude/agents/code-reviewer.md`의 역할 정의를
     인용한다.
3. 공유 태스크 리스트에 3개 태스크를 등록하고 의존성을 건다:
   기획 태스크(선행 조건 없음) → 구현 태스크(기획 완료에 의존) →
   리뷰 태스크(구현 완료에 의존).
4. 각 팀원은 자기 작업이 끝나면 `Templates/team-session.md` 형식으로
   `Sessions/{오늘날짜}-{프로젝트명}-{기획|구현|리뷰}.md` 노트를 새로
   생성한다(다른 팀원의 파일은 건드리지 않는다 — 동시 편집 충돌
   방지). 이전 단계 노트가 있으면 frontmatter의 `related`에
   `[[파일명]]`으로 링크한다.
5. 리뷰 태스크가 "치명적 오류" 문구를 포함한 채 완료 처리되려 하면
   `check-review-verdict.sh` 훅이 자동으로 완료를 막는다 — 이 경우
   팀은 코드 작성자에게 재작업을 요청한다.
6. 전원 완료 후, 팀 리드가 세 노트의 핵심을 종합해 사용자에게
   우선순위가 매겨진 결과 요약을 보고한다.
