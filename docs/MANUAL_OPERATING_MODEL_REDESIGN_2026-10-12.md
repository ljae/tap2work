# 매뉴얼 분류·가상 매장 본보기·업무 안내 재설계

상태: 사용자 요구 확정, 구현 진행 중. 아래 상세 구현·화면은 아직 완료 검증 전이다.

## 사용자 요구

- 매뉴얼을 처음 설정, 정기 관리, 루틴 업무, 레시피 등 실제 사용 시점으로 구분한다.
- 직원의 일상 체크는 루틴 업무 중심이다. 처음 설정·레시피·교육은 방법을 찾는 매뉴얼이 기본이고, 정기 관리는 필요한 일정에만 할 일이 된다.
- 레시피와 매일 수행할 행동이 같은 화면의 같은 의미로 섞이지 않도록 한다.
- 가상 매장의 상세한 운영 매뉴얼을 마켓에 제공해 사용자가 정리 깊이와 구성 방법을 배울 수 있게 한다. 실제 운영 중인 식당의 사례로 주장하지 않는다.
- 폴더 → TAP → 할 일 → 매뉴얼 내용의 연결을 구조·전환·애니메이션으로 이해할 수 있게 한다.
- 사용자가 지정한 보존 계정의 매뉴얼·할 일·완료 기록은 유지한다. 다른 계정의 매뉴얼·할 일 데이터 정리는 사용자 허용 범위다. 보존 계정 식별자는 비공개 실행 설정으로 관리하며 source/history에 이메일을 기록하지 않는다.

## 구현 방향

### 분류와 실행 정책

분류는 찾기 위한 축, 사용 방법은 실행을 만들기 위한 정책이다. 폴더의 이름이나 메뉴 이름만으로 업무 생성 정책을 추정하지 않는다. 기존 `menuManualId`, `knowledge`, `settings.usage`, 반복·파트·시간대 설정을 재사용하고 안정적인 ID를 유지한다. 기존 교육·참고 콘텐츠도 접근 경로를 보존한다. 카테고리 선택은 업무 ON 또는 완료가 아니다.

| 분야 | 기본 읽기/사용 방식 | 직원 할 일 연결 |
|---|---|---|
| 처음 설정 | 매장 설정·기준·처음 준비를 읽고 구성 | 매일 생성하지 않음; 필요한 초기 작업은 별도 명시 설정 |
| 정기 관리 | 담당자와 주기·대상을 확인 | 선택한 주/월 일정에만 생성 |
| 루틴 업무 | 오픈·영업·교대·마감의 핵심 행동과 방법 | 기존 실제 파트·시간대·배정에 연결 |
| 레시피 | 분량·도구·공정·품질·보관·실패 대응 참고 | 메뉴 주문/배치가 필요할 때 연결하는 별도 작업에서 참조 |
| 교육·참고 | 첫 근무·문제 대응·필요할 때 찾기 | 열람과 수행·버디 확인을 구별 |

### 가상 매장 본보기

가상 외식 매장 하나를 기준으로 운영시간·파트·장소·담당 역할·오픈/교대/마감·주간/월간 관리·메뉴 레시피를 일관되게 구성한다. 각 TAP에 목적, 적용 시점, 관련 장소/도구, 행동, 실제 확인 기준, 방법, 이상 발생 시 조치와 연결 매뉴얼을 포함한다. 상세 수치와 배합은 가상 예시 또는 매장 확인값으로 구분한다. 안전 기준은 식약처 등 확인 가능한 공식 자료를 근거로 하며, 현장 공정 검증을 완료했다고 하지 않는다.

마켓에서는 먼저 전체 구조와 분야별 깊이를 읽을 수 있고, 필요한 TAP만 선택해 가져온다. 가져온 문서는 기존 매장 업무를 자동 활성화하지 않는다. 공급자 콘텐츠와 매장 실제 담당/시간표를 분리한다.

### 화면과 모션

분류 화면 → 폴더 목록 → TAP의 핵심 할 일 → 할 일과 방법을 함께 보는 상세 흐름을 만든다. 상단의 현재 위치와 이전 위치가 이어지며 되돌아갈 때 폴더/목록 위치와 선택을 유지한다. 업무 실행에는 원본 폴더·TAP의 경로와 현재 할 일·진행을 표시하고, 방법 열람과 완료를 구분한다. 완료 이동은 서버 저장 성공 뒤만 실행한다.

공통 `AppMotion`의 160/260/340ms와 초록·코랄, 네 주요 목적지, 공통 텍스트·카드·시트를 재사용한다. 필수 확인 행동을 애니메이션 종료에 묶지 않는다. 동작 줄이기에서는 정지/즉시 전환이며 키보드·명시적 뒤로가기·다음/이전 동작을 함께 제공한다.

## 확인한 근거

- [Flutter navigation](https://docs.flutter.dev/ui/navigation), [MediaQueryData.disableAnimations](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html): 기존 Navigator와 플랫폼·접근성 설정을 재사용한다.
- [FSA SFBB](https://www.gov.uk/government/publications/safer-food-better-business-sfbb/safer-food-better-business-sfbb): 방법 문서와 일상/추가 점검 일지를 분리하는 구조 참고. 한국 법정 기록으로 간주하지 않는다.
- [식약처 대량조리음식 식중독 주의요령](https://www.mfds.go.kr/brd/m_827/view.do?seq=3607): 가상 국물/육류 준비의 안전 원칙 참고. 특정 매장 보관기한이나 레시피 안전성을 새로 인증하지 않는다.

## 수용 검증

- 레시피/초기 설정이 일일 체크로 자동 생성되지 않음; 정기 관리는 실제 반복일에만 생성.
- 분류·폴더·TAP·할 일·방법의 같은 ID 연결, 사용자 보존 계정의 과거 실행·완료 보존.
- 마켓 본보기의 실제 카탈로그 투영·읽기·부분 선택 가져오기와 활성화 분리.
- 320/390/1200px, 확대 글자, 동작 줄이기, 되돌아가기·목록 위치·검색, 저장 실패·매장/크루 전환 검사.
- 새 표시 문구와 기본 분류를 지원 8개 언어에 연결하고 AI 초안 상태 유지.

## 2026-10-13 Implementation and verification

Five categories are implemented with a separate manualCategoryOverride; existing source IDs, names, policies and execution histories remain intact. Setup, recipe and reference documents are excluded from daily generation; periodic work requires a weekly/monthly schedule.

The explicitly fictional Soldam restaurant has26 TAPs,108 detailed sections,15 folders,4 parts,5 time bands,15 places and20 configured seats. Structure/setup/example-day views connect related recipes and support selecting only needed TAPs. Import stays pending and OFF. No live account data was deleted. The protected identifier is only in private local configuration.

Folder/TAP/action-or-content/method navigation shares actual IDs. Recipes open for reading before separate editing. Actual task checks keep save-success advancement and identity/workspace protection. Reduced motion bypasses animated layout.

Root and isolated release worktree: Flutter604pass/3browser-only skip,Node388pass,analysis0issues,UI81,JS,135catalog,7x1971translation,DenoEdge and5isolatedPostgreSQL checks passed. An initial accidental Node execution of the Edge smoke failed after Buffer removal; its intended Deno execution passed. AI semantic review corrected estimated completion,buddy confirmation and temporary-location handling in7languages. All translations remain ai-draft without native-speaker review.

Web deployment and new catalog publication remain pending. The user requested gpt-6.1-sol low deployment; the assigned agent prepared the workflow. Existing supplier JWT and distinct reviewer exact-hash approval sessions are absent. Do not reuse the previous one-off DB-admin publication exception. No new native build is claimed; prior iOS20/Android19 releases are separate.

Final selected source verification: isolated Flutter605pass/3browser-onlyskip and analysis0, including the regression for current translated TAP labels without source rewriting. Production review build and freshly seeded read-only sample passed. Actual anonymous Chrome390px showed the draft label and26TAP/108sections; folder/TAP/method,setup/example-day were viewed on phone and8locale structure screens on1200px with reduced motion. Browser automation retries used explicit close controls instead of Escape; these were locator limitations, not successful evidence. Screenshots/logs are private local artifacts. Deployment remains pending in this entry.

First web release2c8127a /Pages38282802152 succeeded: operations65/catalog-admin7 active,267/267 public artifact hashes matched, actual anonymous390px sample showed26TAP/108sections andAI draft label. LiveDB stable109/revision2 was preserved without new publication. Follow-up compact phone navigation addresses320x740 Nepali labels:48px dropdowns and scrollable count/draft metadata maintain the list viewport. Larger screens keep choice chips. Its final verification/deployment is in progress; the initial asset-await test harness was corrected to a versioned fully translated fixture.

Compact follow-up ready: isolated analysis0 and50 relevant widget tests passed (including translated Nepali320x740 with1.3text scale,list minimum96px,reachable folder and view-selector change). Production build passed; actual anonymous320px Nepali root folder and dropdown -> setup transition verified using the browser menuitem role. Screenshots compact-final-ne-320.png and compact-final-setup-ne-320.png are private local evidence. First release605full tests remain baseline; new full606 validation awaits follow-up CI.
