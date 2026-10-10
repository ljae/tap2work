2026-10-10 통합 검증 완료/배포 인계: Node372·Flutter545통과/3web-onlyskip, analysis0, UI75/Edge/7x990번역/초대PGliteSQL 통과. 초기photo fixture실패는 실제행존재모델·안전재기준비교로보완했고 전체재검증통과. 추가소스보안review의 stock완료우회/원본lazy캡처/명시null연결해제/openissue보관/사진·보고권한차이를수정했다. .local/audit-todo-release의검증본을 Sol low가 SQL→operations→web→iOS12/Android11 순서로배포·제출하며 아직운영배포결과는미기록이다. D124~128정책과상세감사표를따르고 rootdirty나실계정데이터를임의초기화하지않는다.

2026-10-10 최신 TODO 구현 중: 격리 .local/audit-todo-release에서 A02~20의 주요 수정과 D-124~128 정책(실제 초대/수행 불가만 차단/기본 vs운영 준비/담당 이상 사진/부분 입고)을 구현했다. 실제 초대 SQL을 operations 배포 전에 적용하고 서명 사진 receipt와 membership직책/퇴사 CAS를 함께 검증한다. Node372·UI75·Edge·7x990준비번역·초대SQL 통과; 초기 Flutter542+3skip+1fixture 실패는 보완 후 관련9통과/수동설정pollrace통과, 최종전체재검증 진행. source는격리branch가검증본, rootdirty초안은덮어쓰지않는다. Sol low가web/native 배포준비, 아직이후속배포완료아님. 상세진행표 RESTAURANT_OWNER_CREW_AUDIT_TODO_2026-10-10.md. 별도실제크루로그인/실카메라HEIC/원어민/외부주문·급여지급/부분입고대기앱재시작영속화는후속이다.

2026-10-10 최신 감사 완료: 요청 계정의 단독 매장 5개를 비공개 백업 후 초기화하고 인증을 보존했다. Ego Lite에서 새 가상 Audit Kitchen을 구성했다. 단독 사용자 409의 JSONB 키 순서 비교 오류만 수정·Sol low 배포(c165363 / operations v59 ACTIVE), Node335·UI69·인증 Edge 통과 및 운영 웰컴 저장/반복 GET revision 안정 확인. 상세는 `RESTAURANT_OWNER_CREW_AUDIT_TODO_2026-10-10.md`의 A01~A20. A02~A20은 미수정; 특히 주말 마감 변경 시 교대 경계 재계산, 신규 테이블 재편집 시 floor 유실, 미실측 재고 부족 표시를 후속 해결한다. 사진은 합성 도식 1개 웹 등록·1280×800 JPEG 29,917B private 저장 확인. 실크루 계정 연결/실카메라/외부 연동 미검증. 배치도 저장 실패·초안 취소, 최종 장소6개는 미배치. 계정 식별자·운영 백업은 버전 관리 밖에 보관한다. 이번 후속은 서버 수정이며 웹/네이티브 재빌드 없음.

2026-10-10 RELEASED: web36bf8a7 / Pages38047892523 verified (14 live SHA256 matches). Operationsv58 live. iOS11 VALID and WAITING_FOR_REVIEW / AFTER_APPROVAL; Android10 internal+alpha API completed. Flutter500+Node333 passed; 7x990 prepared translations, paid Google runtime disabled. D-119~123 and SHARED_PARTNER_LANGUAGE_RELEASE_2026-10-10.md are current. Some deep admin labels, native-speaker and physical-device review remain follow-up; M-033 PiP/audio/reminder phases remain unfinished. Root dirty work preserved; released source is isolated worktree, not old root HEAD.

2026-10-10 최신 구현 중: D-119~123에 따라 사장님·크루 공통 웰컴/업무/매뉴얼과 공유 진행 기록, 8개 안내 언어를 적용한다. 신규 크루는 국적 필수·안내 언어 별도 선택이며 본인 언어 설정이 우선한다. 최신 사용자 선택은 기존 공용 매뉴얼 사전 번역 + 수정 항목만 번역 필요 표시 + 직접 등록/JSON 가져오기다. Google 실시간 유료 번역은 비활성화한다. 웹·iOS·Android 배포는 Sol low 담당으로 승인되어 있으며 실제 결과는 프로젝트 이력/SHARED_PARTNER_LANGUAGE_RELEASE_2026-10-10.md를 확인한다. 원어민 검수 및 배포 완료로 미리 표시하지 않는다.

2026-10-10 최신 진행 중: 사용자 직원교육·일상 루틴·정기관리 중심 매뉴얼 상세화/마켓 UI 개선 요청 후 자리 비움으로 MD 인계 요청. `MANUAL_ROUTINE_TODO_2026-10-10.md`부터 재개한다. 루트5개 소스 구현 초안, 18매뉴얼84단계는 `MANUAL_ROUTINE_CONTENT_DRAFT_2026-10-10.md`에 보관. 콘텐츠 미적용, 분석/테스트/배포 미실시. D-109 요구 confirmed, 구현안 미완료. 기존 dirty tree 보존.

2026-10-10 최신: 문의메일 tap2work.dev@gmail.com으로소스/웹/Play·IARC/ASC ko,en-US·심사연락처/Google OAuth지원·개발자통일. 웹 a35827b Actions38016182177 성공·실제정책SHA일치. 새iOS10 VALID/WAITING_FOR_REVIEW/AFTER_APPROVAL·내부그룹연결, Android9 내부available/Alpha inreview. 이전심사용로그인/계정소유자/공급자·불변이력은보존. D-093 갱신, 검증/초기400·409복구는최신history. `.local/native-release-20261010/` 이메일후속JSON참조.

2026-10-10 최신 완료: 사용자가심사용정보입력후재개. restricted access/Google절차저장, KR국가·기존Android8 Alpha·크몽(doply)44목록을연결하고13변경심사제출. Changes in review/managed publishing off 확인(02:05Z). 승인/실기기/MFA/실제opt-in미검증. `.local/native-release-20261010/alpha-submission.json` 참조. 이하blocked상태는이후속에서해결(실기기검증제외).

2026-10-10 Ego 후속: 사용자44명 Alpha 출시 선택.18+·데이터보안11종 정정 저장(심사 미제출), 내부8 active/기존1명 opt-in완료·다운로드404. Alpha44목록저장/no release, KR국가저장미확인, 앱액세스No오류는심사용상세부재로수정미저장. Ego space2 사용자제어 hard stop; 명시재개전 takeover금지. `.local/native-release-20261010/ego-play-followup.json` 참조.

2026-10-10 네이티브 후속: iOS9 API 확인 VALID/WAITING_FOR_REVIEW/AFTER_APPROVAL, Android8 내부 active. Play Business·광고ID 미사용 저장, 데이터보안 초안만 저장. 심사용 인증 편집 접근 미제공/브라우저 연결 끊김으로 audience/declaration/Alpha 미완료. 데이터보안13종 초안 중 기기ID/주소록/진단은 소스 근거 재검토·정정 전 제출 금지. `.local/native-release-20261010/follow-up-report.md` 참조. 재업로드/Apple심사 취소 불필요.

2026-10-10 완료: 웹 c8c96a9 / Actions37948946797 성공, operations·catalog-admin 배포 및 운영 stable109개(revision2) 발행. 사용자가 추가 동의 없이 반영을 명시하여 이번 발행은 DB 관리자 직접 작업으로 기록했다. 독립 검토 계정을 가장하거나 승인 이력을 생성하지 않았다. 새 원본 업데이트 정책은 미정으로 유지한다.

2026-10-09 구현 후속: 사용자 일괄 적용·웹 배포 요청으로 매뉴얼 조건 구성/공통 장소/수정 배지와 공간·장비 목록/선택 층별 배치도를 구현했다. MANUAL_SPACE_RELEASE_2026-10-09.md의 계약과 한계를 따른다. 후보109개 DB 초안 저장/지정 계정 reviewer 등록 완료, 인증된 독립 검토·stable 발행은 아직 미완료. 아래 연구 당시 proposed/미구현은 이 후속 구현 범위에서 갱신되며 새 업데이트 정책은 여전히 미정이다.

2026-10-09 최신 후속: 충분한 식당 업무 범위·설정 재입력 최소화·매장 수정 구별 요구. MANUAL_COVERAGE_AND_SETTINGS_2026-10-09.md와 독립 시안 참조. 요구는 confirmed, 14영역/조건 계약/코랄 배지는 proposed. 원본 관계·업데이트 미정. 앱/DB 적용·카탈로그 완성 발행은 아직 아니다.

# Claude ↔ GPT/Codex 작업 인계

2026-10-09 최신 후속: 미니멀 로그인·공통 UI 웹 배포는 code36685c6 / Actions37932033230 성공이며 공개 파일은 실제 CI artifact와 SHA256 일치한다. 첫 CI는 테스트의 불필요 import로 실패했고 제거 후 통과했다. 기존 작업 트리는 보존했으며 `.local/store-setup-web-release`의 별도 배포 브랜치만 push했다.

사용자의 다음 과제는 외식업 공통/맞춤 매뉴얼의 원점 재설계다. [Ego Lite 조사·상세 비교표](MANUAL_STRUCTURE_RESEARCH_2026-10-09.md)를 읽는다. 확인한 선택은 외식업 전반 및 크루에게 홀 마감 하나로 표시하는 방식이다. 독립 사본/원본 연결·업데이트·수정 범위는 사용자가 비교표를 읽은 뒤 결정한다고 답했으므로 질문을 반복하거나 추천을 confirmed로 바꾸지 않는다. 현재 앱/DB/공용 카탈로그를 새 구조로 초기화/발행하지 않았다.

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


## 2026-10-08 하루 업무 흐름 조사·질의 준비

최신 요청은 새 크루에게 일과를 매뉴얼/체크리스트로 알려주는 상황의 실제 업무 조사부터 진행하고 질의로 상세 최적화하는 것이다. [조사 문서](DAILY_WORKFLOW_RESEARCH_2026-10-08.md)에 12개 핵심 출처, 가상 식당 파트별 하루, W01–W60, 신입 보조의 하루, 인계/사건/반복 구분, 타 업종 비교와 질의를 기록했다. 실매장 관찰·실측 통계가 아니라 공개 직무/운영 자료의 재구성이다. 상세 TAP 및 양방향 인계·의존성·신입 표시 제안은 proposed. 별도 강좌/시험/교육 진도 기능을 확정하지 않았다. 대표 업종·인원/겸무·신입 첫날 담당 범위부터 답변을 받아 구체화한다. 앱 구현/콘텐츠 발행/배포는 이번에 수행하지 않았다.

## 2026-10-10 매뉴얼 업무 내비게이션 계획·사용자 답변

[상세 계획](MANUAL_NAVIGATION_WORK_PLAN_2026-10-10.md)의 C01–C12를 따른다. 외식 공통+설거지/주방 보조, 수동 업무 ON/근태 분리, 매뉴얼·시간별 체크 우선과 네이티브 병렬 실험. 일반 본인 체크/핵심 버디 확인, 버디 부재 시 사유 있는 본인 최종 완료. 사장님 공통·파트 리마인드 선택/크루 묶음 확인, 사장님·권한 있는 매니저의 매장 공통본 편집. 첫 근무/사장님 지정 중요 변경의 웰컴 재확인 요청은 업무 진입을 막지 않는다.

새 원본 정책은 이제 확정: 사장님이 개선을 보고 TAP별 선택 적용, 매장 수정 충돌은 확인 후 교체. 기존 D-081 자동 갱신 코드는 미변경이며 정책 이관은 P2다. 모든 생성 실행(미시작 포함)을 보존한다. Android PiP/iPhone 잠금화면·Dynamic Island와 명시적 이어폰 듣기부터 실험하며 동일 범용 PIP를 약속하지 않는다.

기준 감사: revision270, 기존 5개 코드 초안/18개84절차는 미검증·미적용. 84개 ID가 `{sid}`, 본문700자 제한과 실제 크루 계정/버디 연결 공백을 먼저 확인한다. BACKEND_WATCH_HANDOFF.md는 현재 트리에서 찾지 못했으므로 과거 B-01을 현재 재현 오류라고 보고하지 않는다. 이번 변경은 계획/기록이며 앱·DB·배포·네이티브 검증을 하지 않았다. 남은 질문은 계획 §11. 기존 미커밋 작업을 보존한다.

## 2026-10-10 비용을 줄이는 단계별 시안 검토

사용자는 주요 내용을 하나씩 빠르고 적은 비용으로 미리 보고 결정하도록 요청했다. [검토 순서](MANUAL_NAVIGATION_REVIEW_SEQUENCE_2026-10-10.md)의7회차를 사용한다. 매회 작은 시안·동작 검증·질문1개·답변 반영 후 다음 내용으로 진행한다. 새 이미지 생성·전체 Flutter 빌드 대신 HTML/기존 글꼴/정지 그림을 먼저 쓴다.

01의 A/B 비교 원본은 `docs/prototypes/manual-navigation-review.html`. 사용자 **A 별도 웰컴 화면** 확정. 기존 첫 근무/중요 변경/평소 다시보기와 진입 허용 정책을 따른다. 사용자에게 넘긴 Ego space6을 새 공간으로 대체하지 않는다. 로컬8767 서버에서 시안만 제공하고 원본 앱/DB 저장은 없다. 검증5개와320/390/1200px·확대 글자 근사 검사 통과. 다음은 세척 구역 준비1건의 체크 단위·딥다운 설명을 미리 보여주는02회차다.

02 시안은 `docs/prototypes/manual-task-review.html`, localhost8767/review-02.html. A핵심행동3체크/B전체1체크와 동일 딥다운 설명을 비교한다. 읽기·체크·되돌리기·상세 왕복의 실제 브라우저 동작 및320/390/1200px·390px확대글자 근사 검증 통과. 선택 질문1개를 제시했고 답변 전에는 정책을 확정하지 않는다. Ego space6을 사용자에게 넘겼으며 앱/API/DB 변경 없음.


## 2026-10-10 통합 행동 슬라이드·자동 다음 이동

사용자는 핵심 행동·설명·사진 링크/첨부·체크를 한 화면에 담고 슬라이드로 다음 행동을 보는 방향으로02를 수정했다. 잔반 배출→접시/그릇/컵/수저 반납 분류→거름망/배수 확인→종류별 건조의4장 예시를 작성했다. 실제 사진은 미제공이어서 도식 기본, 파일 사진은 브라우저 임시URL로만 체험한다. 사진의 생산 저장·실매장 분류는 미구현/미확정.

**최신 수정: 완료 체크하면 다음 행동으로 자동 이동.** 앞선 체크/넘기기 별도 조작 선택은 대체했다. 체크 없이도 슬라이드 탐색 가능하며 탐색/사진보기는 완료를 만들지 않는다. 마지막 행동 완료는 그대로 표시, 되돌리기는 이동하지 않는다. 실제 앱은 서버 저장 성공 뒤 이동해야 한다. 시안은 docs/prototypes/manual-action-slides-review.html, localhost8767/review-02-slides.html. 실제 Flutter/API/DB 변경 없음.

사진 후속: 사용자는 바로 촬영·업로드 전 자동 화질/용량 변환을 요청했다. 시안에 camera capture/앨범 및 Canvas JPEG 변환 추가. 목표 긴변1280px·150KB목표/250KB상한은 proposed 기술값. 합성큰/복잡/작은이미지·손상파일·실제파일선택 변환검증 통과. 실제앱은 기존350KB초과거절/dataURL저장이며 자동변환·운영Storage는 미구현. 실제촬영·HEIC·EXIF/GPS·권한은 후속 실기기 검증. 생산은 원본 미보관·변환본/썸네일·매장별사진참조/권한·고아정리·과거참조보존을 함께 구현한다. Ego space6을 사용자에게 다시 넘겼다.

2026-10-10 매뉴얼 고도화 실제 구현: 사용자가 역할별 AI 모델 에이전트를 구성해 진행하도록 요청했다. 총괄+GPT-6.1 Sol 화면/사진+GPT-6 Astra 데이터로 실제 Flutter 행동 슬라이드와 촬영/JPEG 최적화, authenticated private Storage 소스·삭제 재시도 경로를 구현했다. [MANUAL_NAVIGATION_AGENT_DELIVERY_2026-10-10.md](MANUAL_NAVIGATION_AGENT_DELIVERY_2026-10-10.md)와 최신 canonical history의 검증 결과를 우선한다. 업무 Task 진입의 설명/사진/체크 통합과 저장 성공 후 자동 다음 이동, 매뉴얼/장소 사진 등록이 첫 묶음이다. 매장 원본 수정이 이미 생성된 실행을 재작성하지 않도록 기존 경계를 유지한다. 사용자 후속 확정: 설거지 시작 준비·교대·마감 체크/영업 중 필요 시 안내, 다른 매장 백업 복원은 본문 유지·private 사진 재등록. 실제 일정 일괄 변경은 하지 않았다.

사진 upload는 기본 비활성. bucket+삭제 outbox migration, operations/account 배포, service cleanup 스케줄 준비 후 Edge TAP2WORK_MANUAL_MEDIA_ENABLED를 켠다. 이번 작업은 운영 DB/Storage 생성·업로드/배포/스케줄/네이티브 빌드 없이 로컬 코드·검증이다. 기존 같은 매장 참조와 HTTPS는 유지하며 PDF는 private 사진을 앱에서 확인하라는 안내를 출력한다. 저장 취소 orphan 자동정리/사진PDF내장/실제 카메라·HEIC·현장 가독성은 후속. 나머지 웰컴·시간 안내·버디·원본 선택 적용·리마인드·PiP/음성은 여전히 계획 단계이며 이번 첫 묶음 완료와 혼동하지 않는다. 큰 기존 dirty tree는 보존했다.


2026-10-10 D-118 후속: 사용자가 웹 선행 사진 활성화를 선택했다. Storage/삭제 outbox+managed cron 및 operations/account/cleanup Edge를 배포하고 합성 사진의 실제 비공개 접근·예약 정리 왕복을 검증했다. 웹 배포 진행 중이며 최종 history가 기준이다. 구버전 네이티브의 새 private 사진 표시/일부 편집 제한은 다음 업데이트 대상이다. 웹 Blob 회수/중복 디코딩 방지, 인쇄 snapshot scope 초기화를 추가했다. 기존 전체 내비게이션 로드맵은 여전히 후속.


## 2026-10-10 웹 배포 완료

https://tap2.work/ — 코드 `135f8ef6739c8d4a96703d28a3fe616c2dbf742a`, [Actions38044078051](https://github.com/ljae/tap2work/actions/runs/38044078051) build/deploy 성공. Flutter435통과/브라우저전용3skip, 별도Chrome3통과, Node317통과, 분석·UI64·Edge·SQL 통과. 공개 index/버전 bootstrap/main/owner샘플/정책/계정삭제/주소검색7파일이 CI artifact SHA256과 일치한다. 실제 공개 Flutter 화면도 브라우저에서 열었고 Ego space6에 결과 페이지를 남겼다.

별도 새 빌드에서 실제 `image/*,capture=environment` 파일 선택→합성 사진 자동변환→미리보기와 체크→자동 다음→이전 완료 상태 유지까지 확인했다. 합성 사진 초안은 저장하지 않고 버렸다. 실제 폰 카메라·HEIC·운영 사용자 인증 사진 업로드·현장 사용성 검증은 별도이며 native 빌드/업로드도 하지 않았다. 구버전 native private 사진 표시/일부 편집 제한은 사용자 D-118에 따라 다음 업데이트 대상이다.

운영 Storage/삭제 outbox/cron/operations/account/cleanup Edge와 업로드 활성화 완료. 자동 cron 실행 성공도 확인했다. 실제 크루/매장 일정/공용 카탈로그를 변경하지 않았다. 전체 웰컴·시간 안내·버디·원본 선택 업데이트·리마인드·PiP/음성 및18/84콘텐츠는 후속이며 M-033은 in_progress다. 검증 산출물: `.local/manual-navigation-deployment/public-verification.json`, `backend-verification.json`, `ci.log`; 배포 작업 폴더 `.local/manual-navigation-web-release`. 원래 작업 폴더의 미커밋 변경은 보존했다.
