# vibe-coding-notes

PARA 방법론 위에 Claude Code 하네스(CLAUDE.md·SKILL·서브에이전트·Agent Team·훅)를 얹어, 바이브 코딩의 기획·구현·리뷰 과정과 그 결과 지식이 자동으로 쌓이는 Obsidian 볼트입니다.

## 폴더 구조

```
vibe-coding-notes/
├── CLAUDE.md              하네스가 매 세션 읽는 프로젝트 규칙
├── README.md               (이 파일)
├── 00-Inbox/                세션 중 캡처한 미분류 메모
├── 01-Projects/{프로젝트명}/  실제 소스코드. 바이브 코딩 팀이 여기서 작업
├── 02-Areas/                 지속 관리 영역
├── 03-Resources/             재사용 가능한 에러/프롬프트 패턴 (weekly-review가 자동 생성)
├── 04-Archives/              완료/중단된 프로젝트 (수정 금지)
├── Sessions/                 세션 로그. 개인 세션은 YYYY-MM-DD-{프로젝트명}.md,
│                             팀 세션은 YYYY-MM-DD-{프로젝트명}-{기획|구현|리뷰}.md
├── Templates/                Templater 템플릿
├── private/                  민감 정보 전용, AI 접근 차단(훅으로 강제)
└── .claude/                  하네스 구성 요소
    ├── agents/                서브에이전트 정의
    ├── skills/                슬래시 커맨드로 호출되는 절차
    └── hooks/                 결정론적으로 실행되는 자동화
```

## 하네스 구성 요소

| 구성 요소 | 이름 | 역할 |
|---|---|---|
| 지침 | `CLAUDE.md` | 폴더 구조, 노트 컨벤션, 하지 말아야 할 것 |
| 스킬 | `tag-session` | 00-Inbox/의 미분류 메모에 태그를 붙이고 01-Projects/로 분류 |
| 스킬 | `weekly-review` | 최근 7일 세션을 회고로 정리하고, 반복 패턴을 03-Resources/에 자동 기록 |
| 스킬 | `vibe-coding-team` | 기획자·코드 작성자·코드 리뷰어 Agent Team을 스폰해 한 번에 진행 |
| 서브에이전트 | `session-searcher` | 볼트 전체에서 과거 관련 세션을 검색 (기획자가 작업 전에 항상 먼저 호출) |
| 서브에이전트 | `planner` | 기획자 — 계획 수립 전용, 코드 수정 불가 |
| 서브에이전트 | `coder` | 코드 작성자 — 01-Projects/{프로젝트명}/에 실제 구현 |
| 서브에이전트 | `code-reviewer` | 코드 리뷰어 — 계획과 대조해 검토, "치명적 오류" 발견 시 명시 |
| 훅(PostToolUse) | `ensure-frontmatter.sh` | 새 노트 저장 시 project/tags/created 필드 자동 보강 |
| 훅(PreToolUse) | `block-private-access.sh` | private/ 하위 파일에 대한 모든 도구 호출을 강제 차단 |
| 훅(TaskCompleted) | `check-review-verdict.sh` | 리뷰에 "치명적 오류"가 남아있으면 해당 태스크 완료를 강제 차단 |

지침(CLAUDE.md·스킬·서브에이전트)은 모델에게 방향을 주지만 100% 보장되지 않고, 훅만이 모델의 판단과 무관하게 항상 같은 방식으로 동작합니다 — private/ 차단과 리뷰 품질 게이트가 훅으로 만들어진 이유입니다.

## 바이브 코딩 시작 프롬프트 예시

1. **새 프로젝트를 기획→구현→리뷰까지 한 번에**
   `/vibe-coding-team recipe-app "재료 검색 필터 기능 추가"`
   → `vibe-coding-team` 스킬이 Agent Team을 스폰. 기획자가 `session-searcher`로 과거 기록을 먼저 찾고, 코드 작성자가 01-Projects/recipe-app/에 구현, 코드 리뷰어가 검토. 세 역할 모두 Sessions/에 자기 노트를 남김.

2. **특정 역할만 단독으로 위임**
   "code-reviewer 서브에이전트로 01-Projects/recipe-app/의 최근 변경사항만 봐줘"
   → `code-reviewer` 서브에이전트가 격리된 컨텍스트에서 검토 결과만 반환.

3. **작업 중 세션 캡처**
   "방금 겪은 에러랑 어떻게 고쳤는지 세션 노트에 추가해줘: [에러 메시지 + 해결 프롬프트]"
   → 노트가 저장되는 순간 `ensure-frontmatter.sh` 훅이 frontmatter를 자동 보정.

4. **정리 자동화**
   "오늘 세션 노트들 정리해줘"
   → `tag-session` 스킬이 00-Inbox/의 메모에 프로젝트·기술·상태 태그를 붙이고 01-Projects/로 이동.

5. **주간 회고**
   "이번 주 바이브 코딩 회고 만들어줘"
   → `weekly-review` 스킬이 최근 7일 세션을 요약하고, 반복되는 에러/패턴이 있으면 03-Resources/에 노트를 직접 생성.

## 알아둘 점

- Agent Team은 실험적 기능이라 팀원마다 독립된 컨텍스트를 쓰므로 토큰 비용이 단일 세션보다 훨씬 큽니다. 가벼운 위임이면 2번처럼 서브에이전트 단독 호출을 우선 고려하세요.
- `private/`는 `.gitignore` 대상이자 훅으로 접근이 차단되어 있습니다. 민감한 내용(.env 값, API 키, 사내 로직)은 반드시 이 폴더에 두세요.
- MCP(옵시디언 심화 연동)와 Hermes Agent(상시 실행 독립 에이전트)는 이번 세팅 범위 밖입니다.
