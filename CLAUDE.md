# FieldLog

현장 인력(주 타겟: 50+ 사용자)이 배너/현수막 사진을 찍으면 위치·시간을 자동으로 기록해 지도에 표시하는 iOS 앱. 개발 목적 겸 취업 포트폴리오 — 기술 결정에는 항상 "왜"가 있어야 하고, 그 근거를 CLAUDE.md와 블로그에 남긴다.

## Environment

- Swift 6.3, SwiftUI, SwiftData, MapKit, CoreLocation, ImageIO, PhotosUI
- Min deployment: iOS 17
- SPM만 사용한다. CocoaPods/Carthage 금지
- Xcode 26.6, macOS Tahoe
- 빌드/테스트는 Xcode GUI에서 Cmd+R / Cmd+U로 한다. 터미널 명령어(xcodebuild 등)는 사용하지 않는다

## Model 전략

- 기본 세션(구현/코드 작성)은 Sonnet을 쓴다
- 아키텍처 설계, 레이어 경계 결정, 코드 리뷰처럼 트레이드오프 판단이 필요한 작업은 `architect` 서브에이전트(`.claude/agents/architect.md`, model: opus)에 위임한다. "설계 검토해줘", "이 방식이 맞는지 봐줘" 같은 요청 시 Claude가 자동으로 위임하거나, `/agents`로 직접 호출한다

## Architecture — Butterfly Architecture (Clean Architecture)

Domain을 중심(몸통)으로 Presentation과 Data가 좌우 날개처럼 대칭적으로, 서로 완전히 독립적으로 뻗어나가는 구조.

**의존성 규칙 (반드시 지킨다):**
- Domain은 Data와 Presentation 둘 다 모른다 — 프레임워크 import 금지, 순수 Swift만
- Presentation → Domain에만 의존한다. Data를 직접 import하지 않는다
- Data → Domain에만 의존한다 (Domain이 정의한 Repository protocol을 구현). Presentation을 직접 import하지 않는다
- Data와 Presentation은 서로를 전혀 모른다 — 둘 다 Domain을 통해서만 간접적으로 이어지고, 실제 객체 연결은 컴포지션 루트(App 진입점)에서 DI로 한다

**레이어별 구성:**
- **Domain**: Entity, Model, UseCase, Repository protocol(인터페이스), Domain 유닛 테스트
- **Presentation**: View, ViewModel — Domain의 UseCase/Repository protocol에만 의존
- **Data**: Repository 구현체 + Data 내부용 인터페이스. 추후 Persistence(로컬 저장소, SwiftData)와 Network로 나뉜다 — 이 둘은 서로 모른다. Data의 Repository 구현체가 Persistence/Network를 조합해서 사용한다

새 기능은 "Domain(Entity + UseCase + Repository protocol) → Data(Repository 구현체 + mapper) → Presentation(ViewModel)" 순서로 만들되, Data와 Presentation 코드는 서로 import하지 않는다.

## SwiftData

- Repository 구현체는 클래스 전체에 `@MainActor`를 붙인다. 백그라운드 스레드 진입점이 없는 한 메서드별 actor hopping을 하지 않는다
- 스키마 버전이 바뀌면 `VersionedSchema`를 사용하고 마이그레이션 plan을 명시한다

### View 리프레시 전략: 명시적 재조회 (확정)
mutation(추가/삭제/수정) 후 Repository의 fetch 함수를 다시 호출해서 상태를 동기화한다. `ModelContext` 알림 기반 자동 스트리밍(AsyncStream/Combine)은 쓰지 않는다.

## 사진/앨범

- PHAsset + `itemIdentifier` 방식은 Limited Photo Library Access 상태에서 조용히 실패한다. `Data` + `ImageIO` 방식(권한 상태 무관)을 사용한다

## UI / Liquid Glass

- Xcode 26 SDK로 빌드하면 표준 SwiftUI 컴포넌트(NavigationStack, toolbar, sheet 등)는 iOS 26 기기에서 별도 코드 없이 자동으로 Liquid Glass 스타일을 받는다
- 커스텀 뷰에 `.glassEffect()` 등 iOS 26 전용 API를 직접 쓸 경우 `@available(iOS 26, *)` 가드와 iOS 17 fallback을 반드시 넣는다

## Xcode 관련 주의사항

- Claude Code가 새로 만든 파일은 `.xcodeproj` 타겟에 자동으로 추가되지 않는다 — 수동으로 타겟 멤버십을 추가한다
- 새 폴더는 Xcode의 "New Folder"(파란 아이콘, 실제 파일시스템 폴더)를 사용한다. "New Group" 금지 — Clean Architecture 레이어 구조가 GitHub/블로그에서도 그대로 보여야 한다

## Commit

- Conventional Commits 형식(`feature:`, `fix:`, `refactor:` 등)을 따르고, 설명은 한국어로 작성한다. 변경 이유를 포함한다

## Coding Principles (Karpathy 4 Principles)

Behavioral guidelines to reduce common LLM coding mistakes. **Tradeoff:** these guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes
**Touch only what you must. Clean up only your own mess.**
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused. Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution
**Define success criteria. Loop until verified.**
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
