# Claude ↔ GPT/Codex 작업 인계

작성: 2026-10-05. 같은 저장소를 계속 사용한다. 앱 코드 이동·중복 구현은 하지 않았다.
현재 기준은 로컬 작업 트리이며 HEAD `c53290e`만으로 현재 코드를 복원할 수 없다. 이미 많은 수정/미추적 파일이 있었다. 전체 stage/reset/clean 또는 이전 커밋으로 덮어쓰지 않는다.

## 시작 순서

1. 루트 `AGENTS.md` — 공통 규칙. Claude는 `CLAUDE.md`에서 같은 파일을 import한다.
2. 이 문서와 `BACKEND_WATCH_HANDOFF.md` — 현재 구조와 작은 후속 작업.
3. `project-state.json`의 해당 결정과 최신 history, `../PRODUCT.md`, `ARCHITECTURE.md` — 정식 판단 근거.
4. UI 변경이면 `UI_UX_GUIDELINES.md`, 새 화면/변경 화면은 `TOSS_UI_PROMPT_TEMPLATE.md`, 설정 연결이면 `UI_SETTINGS_RELATIONSHIP_MAP.md`.
5. 필요한 파일만 추가로 읽고 한 작업 단위씩 구현·검증한다. `.agents/skills/`의 Flutter 스킬은 두 도구가 같은 원본을 사용할 수 있다.

별도의 Claude 설정/메모리 파일은 이 저장소 검색에서 발견되지 않았다. 사용자 홈의 비공개 Claude 대화·설정은 검색하거나 복사하지 않았다. 기존 Codex 실행 보조는 `scripts/codex-tap2work.sh`에 있다. 이 인계는 특정 모델명·개인 MCP 설정을 강제로 지정하지 않는다.

## 파일 구조와 수정 위치

```text
tap2work/
├── AGENTS.md / CLAUDE.md     공통 규칙 / Claude 진입
├── app/                     주 앱: Flutter
│   ├── lib/main.dart        초기화·앱 진입
│   ├── lib/ui/              화면과 공통 디자인 컴포넌트
│   ├── lib/state/           OperationsController, ScheduleController 등
│   ├── lib/domain/          repository 계약·순수 계산·모델
│   ├── lib/data/            HTTP·인증·기기 백업 저장소
│   ├── assets/              서체·브랜딩·달력
│   ├── test/                위젯·도메인·동기화 검증
│   ├── tool/                UI 검토/캡처 도구
│   └── android/ ios/ web/ … 플랫폼 진입
├── developer/               Node 콘솔·공유 운영 도메인
│   ├── server.mjs           로컬 서버 및 API 라우팅
│   ├── store.mjs            프로젝트 결정 저장
│   ├── operations.mjs      운영 상태·액션·권한 투영
│   ├── supabase_backend.mjs 인증 클라우드 HTTP 경계
│   ├── section_storage.mjs 변경 영역 diff
│   └── test/               Node 및 SQL 검증
├── supabase/                SQL 이관과 Edge Functions
├── docs/                    결정·아키텍처·가이드·계획
│   ├── project-state.json   버전 관리되는 결정/이력 원본
│   └── market/              공용 TAP 원본·불변 발행본
├── scripts/                 빌드·배포·연결 검사·콘텐츠 생성
├── .agents/skills/          저장소 공통 Flutter 스킬
├── site/                    공개 리뷰 포털
├── .github/workflows/       GitHub Pages 빌드·배포
└── index.html app.js …      이전 참조 프로토타입
```

| 작업 | 먼저 볼 파일 |
|---|---|
| HTTP/폴링/충돌 | `app/lib/state/operations_controller.dart`, `app/lib/data/http_operations_repository.dart`, `developer/supabase_backend.mjs` |
| 근무 배정/파트 | `developer/staff.mjs`, `parts.mjs`, `default_assignments.mjs`, `workplace.mjs`; `app/lib/domain/part_schedule.dart` |
| 영업일/야간/예외 | `developer/business_day.mjs`, `business_breaks.mjs`, `schedule_exceptions.mjs` |
| TAP 정책/실행 | `developer/tap_policy.mjs`, `task_settings.mjs`, `checklists.mjs`, `work_assignments.mjs` |
| 공용 콘텐츠/백업 | `developer/manual_market.mjs`, `manual_catalog_schema.mjs`, `app/lib/data/checklist_backup_repository.dart`, `docs/market/README.md` |
| 저장 구조/비용 | `docs/DATABASE_AND_PERFORMANCE.md`, `developer/section_storage.mjs`, `supabase/migrations/20260929010000_section_storage.sql` |
| UI 공통 | `app/lib/ui/design_tokens.dart`, `design_system.dart`, `components.dart`, `app_motion.dart` |

읽기/쓰기: Flutter UI → controller → repository → 로컬 OperationsStore 또는 인증 Supabase handler → 공통 도메인 → revision/CAS 저장. 공개 리뷰 읽기 전용 경로와 기기 첫 근무 학습 진도는 별개다.

## 오래된 설명과 최신 결정 구분

- D-095: 한 계정의 복수 매장. `WorkspaceMenu`/`OperationsController.workspaceId`가 전역 매장 범위이며 모든 API·캐시·권한·삭제 scope가 이를 따른다. 계정당 단일 매장이라는 과거 설명은 폐기했다. 초대 연결은 아직 범위 밖이다.
- D-073: 신규 TAP에서 파트·시간대·운영 정책을 설정한다. Task별 배정으로 되돌리지 않는다. v1 실행은 호환/기록 보존 대상이다.
- D-075/076: 기본 크루 설정은 인원 배치 테이블로 통합했다. 과거 문서의 별도 크루 배정·기간 적용 동선을 재구현하지 않는다.
- D-080: 2026-10-06 사용자 수정: 기본 인원 설정은 만료 없이 지속 적용하며 명시적 저장은 영향 요일의 오늘 이후 모든 기존 미래 계획/미세 조정을 재반영한다. 조회 기간은 scheduleFrom/scheduleTo로 요청하고 90일은 서버 작업 캐시다. 실제·과거·승인·대기 기록은 보호한다. 평소 조회는 미세 조정을 보존한다.
- D-081: 공용 연결 TAP 자동 업데이트와 개인화/JSON 백업은 이미 구현됐다. 상세 계획 §21의 미구현 설명보다 §22와 최신 결정이 우선한다. 3-way 비교 UI는 확정 정책이 아니다.
- D-078: 자동 출근은 선호 저장만 구현. D-079 자동 퇴근은 proposed. 실제 감지/인증/알림으로 소개하지 않는다.
- 지난 배포 성공 기록은 현재 작업 트리 테스트 결과를 대체하지 않는다. 이번 기준 결과는 오류 인계 문서에 있다.

## 로컬 명령

루트: `npm run dev:console` (기본 3100), `npm run check`, `npm run test:console`, `npm run check:ui-links`.
`app/`: `flutter analyze`, `flutter test`.
웹 미리보기 빌드: 루트 `npm run build:app`, 콘솔 `/app/`.
이번 확인 환경: Node v22.21.1, Flutter 3.41.2, Dart 3.11.0. 버전 강제 업그레이드는 하지 않았다.
`backend:deploy`는 실제 외부 배포 명령이며 로컬 검증 명령이 아니다.

## 파일 구조 복사본

`.local/ai-handoff-2026-10-05/source.tar.gz`는 현재 소스와 이 인계 문서를 원래 상대 경로로 복사한 로컬 아카이브다. 포함 파일/해시는 같은 폴더의 `manifest.json`, 테스트 기록은 `verification/`에 있다.
Git 추적 파일과 무시되지 않은 미추적 파일을 기준으로 복사하며 `.git`, `.env`/개인 설정, `.local`, 빌드·캐시·의존성·플랫폼 생성 파일은 제외한다. Git 이력·운영 DB·자격증명 백업은 아니다. 복원 시 빈 디렉토리에 풀고 의존성을 설치한다. 현재 작업 폴더 위에 풀지 않는다.

## 후속 모델 시작 프롬프트

> AGENTS.md와 docs/AI_HANDOFF.md, docs/BACKEND_WATCH_HANDOFF.md를 읽어라. 현재 작업 트리의 기존 수정은 보존하라. 먼저 B-01의 실패를 재현하고 최신 결정과 테스트의 충돌을 확인하라. 제품 권한을 임의로 바꾸거나 기대값만 400→409로 치환하지 말라. 한 작업씩 최소 수정하고 관련 검사 결과·미실시 항목을 기록하라. Watch 항목은 의미 확인 전 다른 오류로 단정하지 말라. 이번 요청에 없는 운영 데이터 변경이나 배포를 하지 말라.

## 2026-10-07 매뉴얼/체크리스트 설계 인계

최신 사용자 수정: 별도 교육 없음. 매뉴얼과 체크리스트에 집중한다. 교육 과제·진도·평가·learning 테이블을 만들지 않는다. 목표는 사장 부재 시 품질 지원, 외부 조사/관리 공백 기반 콘텐츠 개선, DB 공용 발행이다. `CONTINUOUS_OPERATIONS_ARCHITECTURE.md` P1의 요청당 동일 catalog 주입, 조회/가져오기/동기화/taxonomy/캐시 일관성부터 구현한다. 이번 작업은 코드 검토와 설계 문서 개선이며 신규 DB/CMS/에이전트 팀은 미구현. ID/개인화/생성 실행/매장 권한 보존. 팀 구성과 정기 실행은 이후 사용자 요청으로 진행한다.

## 2026-10-07 DB/팀 구현 인계

콘텐츠 migration/초기86 TAP seed·operations DB 연결·catalog-admin API를 구현했다. `.agents/content-team/`와 `scripts/content-team.mjs`의 역할/해시/큐/실행/초안 export를 사용한다. `DB_CATALOG_OPERATIONS.md`에서 공급자 계정 등록·독립검토·CAS 발행을 따른다. 실제 제공자 계정은 임의 등록하지 않았다. 팀의 fixture 결과는 실제 조사/생산 승인/발행이 아니며 정기 실행 미활성. 교육 기능은 제외한다. 이전 설계의 미구현 문구보다 최신 구현/검증 history를 따른다.

## 2026-10-07 접속 오류 후속

DB 카탈로그 검증의 전역 Buffer는 운영 Edge에서 인증 조회500을 일으켰다. TextEncoder로 수정·서버/웹배포 후 실제 로그인GET200/기존37양식/18오늘업무와 화면복구 확인. `npm run test:edge`는 Node 전역 없이 DB카탈로그를읽는 인증된전체handler경로를 Deno에서검사하며 CI에포함한다. 신규API 미인증401만으로 운영조회성공이라고 판단하지 않는다. 데이터초기화/복원은수행하지않았다. 앱/매장조회 로딩단계와 지연/오류재시도, 초기화attempt응답순서보호를 적용했다.

## 2026-10-07 요청 기반 팀 개선

사용자 최종 선택은 정기 실행 없이 직접 요청. launchd 등록 제거, content-cycle default manual/enabled:false. ContentMemory는 .local/content-team/.learning/events의 불변 사건/출처·분쟁·검토/QA/실행실패·평가를 새 job 고정 learning snapshot으로 전달한다. `CONTENT_IMPROVEMENT.md`의 수동run/피드백/점검을 따른다. 반복 검색·AI 동의를 정확도로 집계하지 않는다. 첫 실제연구는 출처4/메모12를 누적하고 검토 보완으로 blocked, 운영 발행 없음. 해당job의 완료 role은 재실행하지 않으며 다음 명시적 요청에서 새job으로 수정한다. 기존 fixture는 기억/평가에 제외한다. 실제 평가율은 현재 null이다.

## 2026-10-08 신규 매장 등록·설정 정리

`StoreSetupScreen`은 첫 매장/헤더 추가 공통 13~14단계 초안이며 마지막 create_workspace.setup으로 원자 생성한다. `developer/business_types.mjs`의 14업종 metadata와 `store_setup.mjs`의 요청당 catalog 선택/검증을 사용한다. 돈까스는 기존 튀김 공통 TAP/Task 재사용을 표시한다. 업무 사용 기본OFF, 켜면 선택한 영업 요일로 반복. 실제 크루/근무를 자동 생성하지 않는다.

기존 StoreProfileScreen은 basic/pos/delivery 직접 진입으로 바뀌고 선언 크루 수/채용 필요 인원 UI·운영/주문 연결 중복을 제거했다. 영업시간/필요 인원은 workplace.days/breaks/headcounts 단일 원본. legacy profile.hours/staffing 데이터는 삭제하지 않는다. profile.businessTypeId 변경만으로 기존 매뉴얼을 교체하지 않는다. 우리매장 목록은 실제 저장값 요약을 표시한다.

API는 인증 사용자+requestId가 이미 생성됐으면 기존 매장부터 찾아 권한 재검증 후 반환한다. 생성 전 검증 실패에만 setupRejected=true를 반환해 UI 재편집을 허용한다. 전송 실패는 같은 payload를 재시도한다. 새 migration 없음. 이번 변경의 외부 배포·네이티브 빌드는 수행하지 않았다. 최종 검증은 project-state 최신 history와 [점검 기록](STORE_SETUP_AUDIT_2026-10-08.md)을 따른다. 배포 시 앱과 operations API 모두 필요하다.

## 2026-10-08 웹 배포 후속

사용자 요청으로 웹과 필요한 operations API를 배포했다. 코드 460533ec1b3c31f75a333913b1d24ab438f540d8, Actions 37759423579 build/deploy success. 공개 root/index·버전 bootstrap/main이 CI artifact와 SHA256 일치, 정책/계정삭제 페이지200. 네이티브 빌드/업로드·DB migration·운영 데이터 생성 없음. 실제 인증 세션의 매장 생성은 미실시이며 API 미인증401 확인을 기능 검증으로 간주하지 않는다.

## 2026-10-08 업종별 초기 묶음 후속

최신 사용자 지시: 표준주소 검색/선택, 파트 직접 추가, POS·배달앱 초기 설정 제외, 업종별 매뉴얼/체크리스트/메뉴/재료/레시피와 기존 편집 연결. `developer/store_bundle.mjs`가 13업종×2 기본 후보 및 버전 계약, `applyStoreSetup`이 customParts ID를 기존 파트 mutation으로 발급/인원 매핑한다. `StoreAddressField`는 새 등록/기존 매장 정보 공통이며 웹 공식 postcode iframe과 표준주소/상세주소 분리. 기존 클라이언트/매장 데이터를 보존한다. 레시피는 구체 배합/온도/시간을 추정하지 않은 초안이다. `scripts/content-team.mjs run --runner aside`는 researcher만 공개 자료 조사하고 기존 큐의 편집/검토/QA를 따른다. 실제 Aside 조사와 미확인 사항은 `STORE_BUNDLE_RESEARCH_2026-10-08.md`. 정기 실행/자동 발행 없음.

웹 배포 완료: 49f3028 / GitHub Actions 37765154721 성공. 공개 https://tap2.work/ 앱·주소 검색 파일의 SHA256이 CI artifact와 일치한다. 검증 로그 `.local/store-bundle-web-artifact/verification.json`. API도 배포했으며 네이티브/DB migration/공용 콘텐츠 발행/실제 매장 생성은 하지 않았다. 서버275 테스트, CI Flutter 전체검사 통과. 실제 Aside researcher 1단계 및 Flutter 웹 주소 선택 왕복·다른 창 메시지 거절을 검증했다. 최초 주소 브리지 오류로 37763814173 배포는 중단하고 package:web로 수정했다. 기본 레시피는 매장 기준 확인용 초안이다.


## 2026-10-08 TAP Water loading deployment

Web deployed: b19d775 / Actions 37771127850 succeeded. Initial inline SVG and Flutter TapWaterLoading share a 3.2-second faucet/cup activity loop, reduced-motion/error pause, and short-screen scrolling. Real readiness/retry controls remain authoritative; no artificial delay or measured percentage. Full CI passed; public index and hashed bootstrap/main match artifact SHA256 (.local/water-loading-deploy/verification.json). Existing tool/loading_review.dart preserves startup/store/error captures; tool/tap_water_loading_review.dart captures the new animation. No backend/native/data changes.


## 2026-10-08 매뉴얼 지식·실행 분리 설계

사용자는 브레이크 공통/뼈찜 혼합 정리, 피로도 낮은 매뉴얼↔할 일 설정, 기본 레시피와 보관 노하우 축적의 조사·설계를 요청했다. [설계안](MANUAL_KNOWLEDGE_TASK_DESIGN_2026-10-08.md)에 소스 감사/공식 근거/분류·계약·UI·이관·검증을 기록했다. 브레이크 원본은 common이 아니라 bonejjim/break이며 공통판은 없음. 운영 DB 원인까지 확인한 것은 아니다. researcher/editor/reviewer/qa 지침을 보강했고 출력스키마/예약/발행은 변경하지 않았다. 실제 앱·카탈로그 수정/배포·신규 사건 엔진은 미실시다. 세부 제안은 confirmed로 바꾸지 말 것.


## 2026-10-08 매뉴얼·업무 연결 구현

사용자가 D-104 설계에 따른 구현을 요청했다. knowledge_work.mjs와 ManualWorkScreen, TAP usage/표시 진단, 배치별 수동 실행·증거·이상처리, 참고문서 snapshot, 명시적 브레이크 분리를 구현했다. 원본91개는 [검토안](MANUAL_RELEASE_REVIEW_2026-10-08.md). 운영 stable86개는 미발행 상태로 보존하고 새 코드로 실제 read/해시검증에 성공했다. 공급자 역할은 등록돼 있지만 CATALOG_ACCESS_TOKEN은 미설정이며 독립 정확해시 검토를 수행하지 않았다. service key로 역할·승인을 위조하거나 seed로 업데이트를 우회하지 않는다. 코드 배포와 공용 발행은 구분한다. 기존 source/content/personalization/실행 snapshot 보존. 신규 메뉴/재료에 수치를 추정해 넣지 않았다.


웹 배포 완료: c0263eb / Actions 37780306822 성공, operations API 배포 완료. CI Flutter378·Node285·정적분석·UI57·Deno·SQL 검사 통과. 초기 백업검증 실패는 reference/event의 잘못된 반복값을 검증 전에 정규화하던 문제로, c0263eb에서 원본 입력 검증으로 수정했다. 공개 index/해시 bootstrap/main/owner sample이 artifact SHA256과 일치하며 샘플은91개다. 검증 산출물은 `.local/store-setup-web-release/.local/manual-knowledge-web-artifact/verification.json`. 운영 stable86은 유지되고 콘텐츠 발행은 미실시다. 공통 브레이크 분리 버튼은 새 replacement 발행 이후 사용 가능하다. 실제 운영 배치 생성/완료, native, schema migration은 수행하지 않았다.
