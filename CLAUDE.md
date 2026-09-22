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

Domain을 중심(몸통)으로, 왼쪽 날개는 UI → Presentation → Domain, 오른쪽 날개는 Domain ← Data ← Storage/Network. 각 레이어는 바로 안쪽 레이어만 의존하고, 두 단계 이상 건너뛰거나 반대 방향으로 의존하지 않는다.

```
UI → Presentation → Domain ← Data ← Storage
                                  ← Network
```

**의존성 규칙 (반드시 지킨다):**
- **Domain**: 아무것도 모른다. 프레임워크 import 금지, 순수 Swift만
- **Presentation(ViewModel)**: Domain에만 의존한다. UI와 Data를 모른다
- **UI(View)**: Presentation에만 의존한다. Domain·Data를 직접 모른다
- **Data(Repository)**: Domain에만 의존한다. Storage와 Network를 직접 import하지 않는다 — DataSource protocol을 정의하고, 구현체는 컴포지션 루트(App 진입점)에서 DI로 주입받는다
- **Storage(Persistence)**: Data가 정의한 DataSource protocol을 구현한다. Network를 모른다
- **Network**: Data가 정의한 DataSource protocol을 구현한다. Storage를 모른다
- Storage와 Network는 서로를 전혀 모른다
- 모든 레이어 간 실제 객체 연결은 컴포지션 루트(App 진입점)에서만 한다

**레이어별 구성:**
- **Domain**: Entity, UseCase, Repository protocol — 순수 Swift
- **Presentation**: ViewModel — Domain UseCase에만 의존, View (SwiftUI) — Presentation에만 의존
    - 다만 View와 ViewModel은 세트로 판단할 수 있기 때문에, Presentation 안에 각 UI별로 View와 ViewModel은 묶어서 관리한다.
- **Data**: Repository 구현체 + DataSource protocol(내부 인터페이스) — Domain에만 의존
- **Storage(Persistence)**: DataSource protocol 구현체 (SwiftData 등) — Data에만 의존
- **Network**: DataSource protocol 구현체 (URLSession 등) — Data에만 의존

새 기능 구현 순서: Domain(Entity → UseCase → Repository protocol) → Data(Repository 구현체 → DataSource protocol) → Storage(DataSource 구현체) → Presentation(ViewModel) → UI(View). 각 레이어는 인접 안쪽 레이어 외에는 import하지 않는다.

**오른쪽 날개 계층 깊이 판단 기준:**

오른쪽 날개가 **상태 있는 저장소(CRUD)**일 때만 Repository/DataSource 5계층을 쓴다. `RepositoryImpl`이 존재하는 이유는 local/remote DataSource를 조합하는 조율자 역할 때문이다. 따라서 조합할 DataSource가 하나뿐이고 상태가 없는 **순수 변환(`Data → 값`)**이라면 5계층은 투기적 계층이다.

이 경우 **Domain protocol → 날개 구현체의 3계층으로 축소**하고, protocol 이름을 `...Repository`가 아닌 `...Extracting`/`...ing`(서비스)으로 두어 저장소가 아님을 드러낸다.

- **5계층 적용:** "합성할 DataSource가 둘 이상 생길 여지가 있는가?" → YES (예: FieldRecord — local SwiftData + 추후 remote API)
- **3계층 적용:** "합성할 DataSource가 둘 이상 생길 여지가 있는가?" → NO (예: EXIF 추출 — ImageIO 외 대안 없음)

3계층 구조:
```
Domain:  SomeValueExtracting (protocol) + SomeEntity + ExtractSomethingUseCase
날개:    FrameworkSomeExtractor (implements SomeValueExtracting)
```
의존성 방향과 컴포지션 루트 DI 원칙은 5계층과 동일하다. 계층 수만 다를 뿐이다.

## SwiftData

- Repository 구현체와 Storage DataSource 구현체 모두 클래스 전체에 `@MainActor`를 붙인다. 백그라운드 스레드 진입점이 없는 한 메서드별 actor hopping을 하지 않는다
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
