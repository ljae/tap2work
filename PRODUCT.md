## 임시 공용 로그인·저장 최적화 · 2026-09-29

사용자 승인으로 지정한 기존 계정의 매장을 모든 방문자가 함께 조회·수정한다. 고정 아이디와 마스킹 필드는 서버 세션 발급 진입점이며 실제 비밀번호를 배포하지 않는다. 로그인 버튼 후 Supabase 세션을 유지해 재방문 자동 로그인한다. SSO는 앱 등록 시 적용한다. 이전 D-051 무로그인 샘플 자동 진입을 대체하며 별도 샘플 둘러보기만 읽기 전용이다.

설정은 영역별 문서와 매장 revision으로 저장한다. 활성 화면에서 30초 간격 변경 확인, 동일 revision/권한/매장/시간창에서는 전체 상태를 전송하지 않는다. [데이터 계약·한계](docs/DATABASE_AND_PERFORMANCE.md).

# Product working brief

## 공통 가독성·시작 로딩 · 2026-09-28

매뉴얼·시급 정산을 포함한 편집 UI는 줄바꿈 제목, 읽기 폭 제한, 섹션 카드, 명확한 입력 라벨과 하단 저장 동작을 공통화한다. 개선 패턴은 기존 화면에도 적용한다. 앱 다운로드·초기화·매장 읽기 동안 일관된 로딩과 실패 재시도를 제공한다. 현재는 D-051에 따라 로그인 없이 샘플로 자동 진입하며 아래의 인증 진입 정책은 임시 플래그 해제 시 적용된다. [구현·검증 기준](docs/UI_READABILITY_2026-09-28.md).

## 앱 전체 모션 · 2026-09-28

버튼·선택 컨트롤·메뉴 전환·시트·확인창·진행률에 공통 모션을 적용한다. 토스 UX 가이드의 예측 가능한 흐름을 참조하며 구체적인 시간과 곡선은 자체 토큰으로 관리한다. 동작 줄이기를 지원하고 서버 저장 성공 전에 완료 효과를 보여주지 않는다. [적용 범위와 스킬 출처](docs/MOTION_GUIDE.md).

## 정산 설정과 Supabase 저장 · 2026-09-28

IMG_6093의 지급 주기(월급/주급), 정산 시작일, 시간 반올림, 사업장 규모, 주휴수당 포함을 매장 공통 설정으로 적용한다. 기존 크루별 지급 주기와 주간별 사업장 규모 선택을 대체한다. 주휴 OFF는 발생 주수를 유지하고 예상 합계에서 금액을 제외한다. 과거 출퇴근 원본·지급 기록을 바꾸지 않는다. 고정 월급 계약 계산과 실제 급여 이체는 별도다.

배포 앱은 로그인부터 시작한다. 인증된 매장의 구현된 설정은 Supabase operations 함수와 revision 검증 RPC를 거쳐 저장하며 재접속 시 불러온다. 비로그인 미리보기를 기본 화면으로 제공하지 않는다. 계정 생성 후 빈 매장 또는 샘플 매장을 선택한다. 외부 POS·위치 인증·보건증 보관은 아직 미연동이다. 로고의 앱/웹 PNG 외곽은 투명하다.

## 파트 중심 운영·근무표 · 2026-09-28

[지속 관리 아키텍처](docs/ARCHITECTURE.md)를 구현과 UI/UX 변경의 기준으로 사용한다. 직원 메뉴는 달력 아이콘의 **근무표**로 바꾸고, 사람의 제품 용어는 **크루**로 통일한다. 기존 직무 분류는 **파트 관리**로 대체한다. 주간표는 왼쪽 시간축, 요일별 파트 세부열, 충분한 열 폭과 가로 스크롤을 제공한다. 영업시간대에서 슬롯이 생성되며 클릭해 해당 날짜의 시간·크루를 조정한다. 기존 배정은 영업시간 수정으로 덮어쓰지 않는다.

업무 메뉴에서 TAP그룹 필터를 제거한다. 주문처리 시스템 연결 설정은 우리매장에 있고 기본 OFF이며 ON일 때만 주문 보드를 표시한다. 외부 시스템은 미연결로 명시한다. 선택 컨트롤은 파트 필터와 같은 pill 방식으로 통일한다. 저장 API의 과거 크루 키/ID는 기록 호환을 위해 유지하되 사용자 화면에 노출하지 않는다.

## 스크린샷 기반 다크 UI · 2026-09-28

사용자가 제공한 IMG_6081–6096의 화면과 기능을 참조해 Flutter 앱을 재설계했다. 현재 UI는 차콜 배경·짙은 카드·밝은 글자·pill 선택·청록 버튼과 초록/코랄 상태색을 사용한다. 앞선 흰 카드 팔레트를 대체하며 Pretendard, 공통 간격·시트·motion, 업무·매뉴얼·근무표·우리매장 4개 메뉴를 유지한다.

우리매장에 실제 상태 기반 준비 목록·본인 출퇴근 카드·파트 관리·요일별 시간대·직책별 제한 설정을 추가했다. 직원은 간결한 목록에서 정보·근태·일정·파트/시간대 시트로 열린다. 파트 ID로 업무·크루·근무를 직접 연결하며 직책 권한과 구분한다. 설정은 기존 revision 검증을 사용하고 실패 시 초안을 보존한다. 기존 인건비 계산과 첫 근무 연습·버디 확인은 유지한다.

초대 코드·QR은 명시적인 체험 기능이다. 실제 계정 가입, 보건증 보안 저장, GPS/Wi-Fi 출퇴근 검증은 미연동으로 표시한다. 임의 밴드 수, 개별 권한 override, 새 소식/요청 결재, 자동퇴근 정책은 아직 구현하지 않았다. 전체 참조 기능 rollout은 진행 중이다. [화면별 구현·제한·검증](docs/REFERENCE_REDESIGN_2026-09-28.md).

## 주간 배정과 인건비 · 2026-09-27

직원 기본 화면은 월–일과 직무별 필요 시간 슬롯의 주간 배정표다. 요일별 슬롯 설정, 교대 분할 충족률·미배정 시간, 날짜별 상세 시트를 제공한다. 매뉴얼과 우리매장 운영 현황·재고와 발주·직원·인건비·배치도 상세도 바텀 시트로 연다.

사용자가 대한민국 기준 주휴·연장·야간·휴일 수당 및 앱 내 주간 확인 목록을 선택했다. 사장님이 확인한 주간 계약 조건을 기준으로 시급제 인건비 예상과 근태 기준 계산을 구분한다. 미확인 조건이나 지원 범위 밖 연속근무는 합계를 보류한다. 이 기능은 표준 성인·고정 근로시간·시급제의 예상액이며 확정 급여/이체가 아니다. 고정 월급·특례 계약·세금/보험은 별도다. [계산 기준·공식 출처·범위](docs/WEEKLY_LABOR_2026-09-27.md).

## 공통 UI 규칙 · 2026-09-27

사용자가 요청한 토스 스타일 규칙을 적용한다. Pretendard 제목 24/Bold, 본문 16/Medium, 설명 13/Regular, 기본 글자 #191F28, 화면 좌우 24px, 세로 섹션 32px를 사용한다. 배경은 #F2F4F6, 기본 카드는 흰색·16px 모서리·4% 그림자로 구분한다. 강조색은 사용자 답변에 따라 기존 초록·코랄을 유지한다. 설정·편집·상세는 상단 모서리 24px와 회색 핸들이 있는 바텀 시트로 열고 네 주요 메뉴는 유지한다. 편집 시트의 외부 탭·드래그 닫기는 비활성화해 기존 취소 확인을 보존한다. 최초 로딩은 shimmer 스켈레톤, 일반 버튼은 0.95배 눌림과 복원, 주요 화면 이동은 Cupertino 전환을 사용하며 동작 줄이기를 따른다. 새 화면 개발의 고정 가이드는 [Toss UI 프롬프트 템플릿](docs/TOSS_UI_PROMPT_TEMPLATE.md)이다.

## 매뉴얼 디렉토리와 명칭 · 2026-09-27

앱의 구조와 명칭은 **TAP그룹 → TAP → Task**다. 기존 BIG TAP은 TAP그룹, Small TAP은 Task로 변경했다. 매뉴얼은 Task에 연결된다. 과거 변경 이력과 저장용 필드/API 이름은 호환성을 위해 그대로 보존한다.

매뉴얼 메뉴는 넓은 화면에서 왼쪽 디렉토리 트리와 오른쪽 Task 목록을 보여준다. 휴대폰은 같은 트리와 목록을 전환하고, 매뉴얼 본문은 모든 화면에서 바텀 시트로 연다. 상단 공통 검색은 그룹명·TAP명·Task명·매뉴얼·연관어를 검색하며 선택한 디렉토리 안으로 범위를 좁힐 수 있다. 사장님/매니저는 구조 편집 모드에서 TAP그룹/TAP/Task의 순서 또는 소속을 드래그와 이동 메뉴로 바꿀 수 있다. 기준 Task의 매뉴얼·설정은 함께 이동하고 오늘 업무의 저장된 매뉴얼·완료 기록은 보존한다. 공개 미리보기의 이동은 화면 내 체험이며 서버에 저장하지 않는다. [구현·검증 기록](docs/MANUAL_DIRECTORY_2026-09-27.md).

주문처리 매뉴얼은 주문 건수나 수량별로 복제하지 않는다. 메뉴 카탈로그의 활성 메뉴마다 대표 TAP 하나와 같은 이름의 Task 하나를 두고 해당 메뉴의 매뉴얼을 연결한다. 기존 실주문 TAP과 그 완료 기록은 그대로 유지한다. 대표 매뉴얼은 자동으로 오늘 업무가 되지 않는다. Task 예상 소요시간은 매장 관리자가 설정하며, 미설정 값은 추측하지 않는다. 매뉴얼 Task 카드에는 소요시간만 보조 표시하고, TAP 트리와 업무 TAP 카드에는 설정된 Task 시간의 합을 표시한다. 일부만 설정됐으면 `+`로 부분 합계임을 나타낸다.

## 공통 메뉴 구성과 완료 전환 수정 · 2026-09-27

네 기본 메뉴는 같은 상단 구조를 사용한다: 하단 메뉴명과 동일한 제목(업무·매뉴얼·근무표·우리매장), 매뉴얼 검색, 본문. 모든 메뉴에서 검색할 수 있고 검색 결과도 같은 최대 폭을 사용한다. 메뉴 제목의 장식 라벨·설명 문구, 반복 안내와 Task의 중복 방법 보기 문구를 제거했다. 오류·저장 상태·권한·실제 업무 매뉴얼 내용은 유지한다.

완료한 TAP은 원래 열에서 글줄이 내려가 사라지는 동안 위치를 유지하고 전환 후 완료 열로 이동한다. 별도 텍스트 오버레이를 제거해 중복 표시를 막았다. TAP 열기는 새 본문만 아래에서 나타나며 서로 다른 높이의 보드가 겹치지 않는다. 동작 줄이기는 즉시 결과를 보여주고 컨트롤러 생성·해제도 검증했다. 선택 버튼에도 Pretendard를 명시 적용했다.

## TAP 전환과 한국어 서체 보완 · 2026-09-27

공개 미리보기에서도 성공한 TAP/Task 완료에 짧은 아래 방향 글줄 전환을 보여 준다. 완료 TAP이 보드의 다른 열로 이동할 때는 출발 카드 위치에서 글줄이 내려가며 사라지고, 완료 열에는 완료 상태가 남는다. TAP을 열면 제목과 Task 본문이 펼쳐진다. 동작 줄이기 설정에서는 전환을 생략한다. 기본 한국어 서체는 무료 OFL 라이선스의 Pretendard로 교체했다. 이 동작은 Flutter 위젯 프레임 테스트로 검증했으며 네이티브 실기기 검증은 별도다.

## 업무·매뉴얼·근무표·우리매장 개선 · 2026-09-27

The main Flutter app now uses **업무 / 매뉴얼 / 직원 / 우리매장**. Work retains the TAP → Task hierarchy, TAP그룹 filters and the existing order/todo/done board. Manuals have a dedicated destination; Staff contains schedules, training and owner-only hiring drafts; Our Store contains settings, layout and access to sales, stock and procurement.

Initial registration requires only store name and industry. Optional POS, delivery platform and staffing details use toggles and pickers and can be changed later. POS/delivery scope covers configuration and relevant task template suggestions; live order integration is separate. Task configuration starts from work-type templates and supports TAP role/place/repeat/time bucket/bulk completion and Task manual/quantity/unit/estimated time/order rules. Photo evidence, manager approval and running timers are later work.

The visual direction emphasizes readable Korean type, restrained color/transparency and compact default content. Opening a TAP should reveal its Task structure; a successful completion should briefly move the text row down and fade into a readable completed state, preserving records, permitted undo and reduced-motion support. Hiring scope is required headcount, roles and job-post drafts; external publishing and applicant management remain later work.

See the [detailed improvement method](docs/APP_IMPROVEMENT_METHOD_2026-09-27.md) and [Sol implementation handoff](docs/SOL_IMPLEMENTATION_HANDOFF_2026-09-27.md). Field names and implementation defaults proposed in those documents are distinguished from the explicit user decisions. The current implementation stores optional profile sections, validates TAP/Task completion rules on the server and keeps existing task snapshots when templates change. External hiring publication, applicant management, POS order synchronization, photo evidence, administrator approval and running timers remain later work.

## UX and integration groundwork · 2026-09-27

The user selected task/manual UX improvements and order integration groundwork, preserving the existing order/todo/done lanes and TAP → Task hierarchy. Card drag, completion and detail controls now have minimum 48 logical pixel targets. Large text uses a compact detail arrow; a tooltip exposes the full title. Manuals show their parent TAP and a separate tip surface.

OperationsRepository now separates HTTP, JSON and authentication headers from controller state. JSON snapshots and some presentation rules remain; this is an incremental boundary extraction, not a completed Clean Architecture migration. Timers, offline writes, state management package replacement and live POS integration remain future proposals. See the [report review and architecture proposals](docs/UX_ARCHITECTURE_REVIEW_2026-09-27.md).

## Purpose

Help a small Korean food and beverage business coordinate people, daily work, stock, and procurement in one approachable phone app. The user explicitly expanded the initial onboarding-only scope on 2026-09-19. The first hour still prepares a new person to participate alongside a buddy: an approximate learning plan, not a countdown or a guarantee of readiness.

Kitchen prep and dishwashing remain the starting jobs. Each worker needs their own learning progress and confirmations; tomorrow's new hire reuses the same workplace materials without inheriting someone else's completion status. Shared operational tasks are different: one coworker's inventory check is visible to the whole team and should not be duplicated.

The [restaurant operations scenario review](docs/RESTAURANT_SCENARIOS_2026-09-25.md) walks through 22 opening, service, stock, staffing, closing and failure scenarios, with implemented behavior, tests and remaining gaps. Its three reproduced defects and a public-preview parity issue received focused fixes; the review does not turn the remaining proposed workflows into confirmed decisions.

## Brand artwork

The current `tap2work.png` is a new route-shaped 2 mark: a cream path and coral endpoints on deep green. `app/assets/branding/generate_brand.py` generates the app asset, repository-root logo, web favicon/PWA icons and Android/iOS launcher images from the same geometry. The Flutter header pairs the icon with a live text wordmark. The earlier user-supplied circle and raster wordmark remain in Git history; the menu artwork remains bundled separately. Native icon builds have not been verified.

The previous 2026-09-27 visual direction used pale gray surfaces, white cards with light shadows, #191F28 text, green navigation and coral primary actions, following the 2026-09-27 UI prompt template. The earlier warm paper surfaces and default card borders are superseded. Functional navigation and task cards use Cupertino glyphs rather than colorful emoji; actual dish art remains where it identifies a menu item. The public domain root serves the Flutter app directly. The public build excludes the development journal and project decision/history files; the local developer console remains a development tool.

The [2026-09-25 UI design system](docs/UI_DESIGN_SYSTEM_2026-09-25.md) refines this direction with a darker, more legible coral action color, shared heading and card treatments, labeled controls, and text-plus-icon status. On phones, Status places immediate work and shortages before shortcuts and reports; the prepared-inventory detail starts collapsed. Calendar gives each half-hour row a larger touch area, Place separates table/seat/equipment totals, and login makes password visibility and submission progress explicit. The visual revision does not change demo permissions, inventory rules, staffing records or first-shift confirmations.

Design references reviewed through Aside CLI on 2026-09-25: [Trello navigation](https://support.atlassian.com/trello/docs/navigation-in-trello/) for its floating desktop navigation and aligned cards; [Trello mobile Planner](https://support.atlassian.com/trello/docs/use-trello-planner-on-mobile/) for persistent labeled phone destinations; [Asana board view](https://help.asana.com/s/article/board-view?language=en_US) for card rhythm; and [7shifts task lists](https://kb.7shifts.com/hc/en-us/articles/32201612821139-View-overdue-task-lists) for compact restaurant task rows. The floating phone pill is our design choice; the inspected Trello phone reference uses a fixed bottom bar.

## Phone experience

| Person | Primary action | Supporting actions |
| --- | --- | --- |
| New worker | Open the next small task | See shift and buddy; ask for help |
| Buddy | Demonstrate and observe practice | Confirm a step; respond to help |
| Owner/manager | Prepare a reusable role template | Invite workers; assign buddies and shifts |

The app has four destinations in this order: 업무, 매뉴얼, 직원, 우리매장. A floating bottom menu shows these Korean labels alongside icons; selection remains visible and each target fills an equal-width slot. 우리매장 provides inventory, procurement, layout and operating overview entry points. The existing first-shift guide (오늘, 일하는 법, 근무표, 도움) remains accessible through 직원 > 교육. Administrative actions are separate from worker actions. Use short Korean text and large touch targets. First-shift guide media remains deferred in D-007; operational Task manuals now support external video/photo links.

The current hierarchy remains TAP / Task. Parts are the sole work-board filter. Folder IDs remain for manuals and template organization. The order-processing lane is opt-in through store settings; OFF hides order cards without deleting history. Existing order-wide progress, independent card actions and stock rules remain.

The schedule now uses a fixed time axis with weekday groups and part subcolumns. Business-hour templates, dated slot adjustments and crew assignments are separate. Clicking a slot edits times or assigns crew; assignments support editing, removal and 4/12-week weekday repetition. Server validation includes membership and overnight overlap. Owner-only labor and payment records remain separate. See [current architecture](docs/ARCHITECTURE.md); earlier calendar and folder-filter descriptions are superseded.

The latest user request brings staff operations and procurement into the prototype now. Recruiting remains a later phase; do not introduce a job marketplace as a prerequisite.

## Menu TAPs, lightweight manuals and staffing calendar · 2026-09-24

Customer tickets create one TAP per menu line (quantity remains on that TAP), each with Task for order work only. These menu TAPs appear together under the order number and drag together between folders, positions and states. Individual menu completion does not complete the ticket until all menus finish. Existing whole-order TAPs are archived during migration, preserving prior evidence. Unfinished orders keep all menu members visible across Korean midnight. Recipe examples are proposals: owners must fill in approved quantities, timing and temperatures.

Task manuals have text, one HTTPS video link and one HTTPS image/album link. Managers can edit directly from a manual popup or in the existing checklist editor using plain text and links from tools such as YouTube or Drive. Media is opened externally, not uploaded or bundled in the app. A linked recipe edit updates its template for future orders; current/completed snapshots are retained, and saves use the opening revision. The entire five-minute planning feature and its scheduling endpoint are removed; independent grid routing remains.

Calendar provides a weekly date strip with a selected-day timeline and a monthly overview. Daily required staffing defaults to three configurable role/time slots (a demo starting point, not a confirmed requirement for every store). Existing extra shifts remain visible. Register crew through HR Pool → crew management, drag a person into an empty slot, or drag an assigned shift to move it. Touch uses long press and empty-slot tapping provides an alternative. Server checks role qualification, occupied slots, overlapping shifts, permissions and revisions. Slot configuration preserves existing shifts rather than deleting them. Suggestions list qualified crew without an overlapping planned shift; availability still needs direct confirmation. The Albamon external link is explicitly labeled HR integration under construction. No invitations, recruiting applications or messages are sent.

Calendar references: [crew calendar design review](docs/CALENDAR_DESIGN_REFERENCES_2026-09-25.md) records official Homebase, When I Work, 7shifts and Deputy phone and desktop patterns reviewed through Aside CLI. The selected-day timeline supports dragging; the monthly overview retains its existing slot interactions. A required `빈 슬롯` is an unassigned place in the plan, not a published offer. Public previews cannot save staffing assignments.

## Prepared output and order usage · 2026-09-24

The order TAP now contains only order verification, finishing/plating from ready portions and handoff. The previous duplication of bone/noodle advance preparation Task is removed from unfinished orders with the old step evidence archived; completed order history stays intact. Stable menu IDs, rather than name matching, connect menus to configurable prepared items. Each prepared item has a unit, current balance, shortage point, target, usual batch quantity, short method, folder/place and per-menu use. One prepared item can serve many menus, and one menu can use many prepared items. This structure fits sauces, dough, portioned vegetables and other restaurant preparations as well as 뼈찜.

Starting menu cooking uses its configured ready portions once. A shortage creates one preparation TAP; completing it asks for the actual finished amount and adds that once. If the amount is still short, another TAP is created. Physical count corrections record who and why. The signed balance can show a shortage without pretending that unmade portions are available. Open preparation TAPs carry across Korean midnight. Existing active orders are not retroactively deducted when a store upgrades to this count model. Supplier-purchased raw inventory and its D-017 order-based review deadline are separate. See [Prepared workflow](docs/PREPARED_WORKFLOW.md) for event, migration and limits.

The demo's 뼈찜 sample begins with an illustrative count and sample menu usage; the store must confirm actual portions, yields, storage and recipes before using these as operational facts. Current sales orders are synthetic, with no POS or automatic supplier order integration.

The operations and first-shift screens share a 72 px warm neutral header with a fine bottom border. The new 44 px mark and live tap2work wordmark scale together on narrow phones. A single 44 px account action opens a contextual menu. Their content uses matching 20 px phone gutters, readable supporting text and the same floating bottom menu. In a preview with Auth available, that menu offers login and clearly labeled demo roles; local preview offers demo roles. Once authenticated, it shows the account and server-provided role without a demo role selector. The account dialog retains login/logout, and role or email text stays inside the menu to prevent duplicate profile controls on phones.

The four operations destinations now share a 1240 px maximum content width with 20 px side gutters. Page titles use one eyebrow/title/supporting-text rhythm, and section headings use a smaller shared scale. Choice controls use white outlined idle states and deep green selected states; choices in a group take equal widths and wrap on narrow phones. Labeled pickers use the same bordered surface and rounded menu. Coral remains the primary action color. Weekly/monthly calendar views are exclusive choices. The selected-day staffing timeline is always visible in the weekly view; personal-assignment filters remain independent controls where shown.

## Integrated operations prototype

| Destination | Main question | Implemented sample interaction |
| --- | --- | --- |
| 오늘 | How is the restaurant doing? | Menu sales/order dashboard, period/channel filters, active kitchen queue, stock/tasks/shifts, first-shift guide |
| 할 일 | What should we check, and who has done it? | Group cards with tap-to-check activities and manuals, time-bucket tabs, undo, drag-and-drop editor, industry library, actor/time per activity |
| 재고/발주 | What do we have and what should we order? | Physical count, minimum threshold, review interval, grouped supplier cart, demo order, separate receipt |
| 우리 팀 | Who is working and where is there a gap? | Shared sample shifts, leave status changes, coverage requests and manager acceptance |
| 매장 지도 | How many tables/seats do we have, and where is each device? | Whole-restaurant grid, table/seat/equipment counts, configurable tables/equipment/storage/entrances/areas, shared layout save |

Inventory flow: **check actual stock → collect needed items → review quantities grouped by supplier → one demo order → acknowledge receipt → later inventory check**. An order never increases on-hand quantity; receipt applies exactly once. An open order blocks duplicate orders for the same item. Partial deliveries, cancellations, price/tax validation and real supplier integration are not implemented.

The user selected a fixed delay after ordering (D-017). Each material retains a configurable N-day delay and minimum quantity. One review is due N days after the latest order; an intermediate physical count or receipt does not postpone it. Completing that review does not start another repeating review; the next order starts a new schedule. The current implementation uses elapsed 24-hour days from the order timestamp. A new order supersedes unfinished reviews from older orders without deleting their records. Changing N recalculates unfinished review dates from the same order. Exact default delays per material still need owner input.

API reads materialize due tasks; polling is not a production scheduler or push service. Checks store actual quantity, actor and timestamp. Daily routine templates still generate new tasks at Korean date boundaries. Initial time buckets are labels, not configurable clock ranges. Managers can define templates by bucket, rank and place. Exact time ranges, exception days, individual assignees and overdue escalation need further design.

Shared information includes names, roles, shift hours, leave status, coverage status, work completion, and stock counts. Private leave reasons are not collected in the shared demo. Owner-only sample labor estimate and memo are stripped from non-owner API responses; purchasing prices are available to owner/manager, not crew/cook. This is an initial permission proposal, not approved production policy. Demo actor selection is intentionally impersonable and therefore **not security for real employee information**.

The layout is a configurable schematic, not a measured architectural plan. It now shows the whole restaurant with table count, total configured seats and major equipment count. Owners/managers can set a layout name and grid (8–30 columns/rows), add up to 80 tables/equipment/storage/entrances/areas, change names/notes/position/size and table capacity (1–20), drag an object with integer grid snapping, resize it with the selected corner handle, or move it by tapping an empty cell or using arrow buttons, and delete unlinked objects. Overview supports pinch zoom and a full-size item list. Existing example routes remain available only when every referenced place still exists. Their display now uses four-way A* over open schematic cells, treating other tables/equipment/storage as blocked; an unreachable segment is not drawn. They are not measured walking distances or validated safety/emergency guidance.

Editing uses a separate draft and the opening revision; polling cannot replace the draft, cancellation discards it, and stale saves fail with an explicit reload option. The server validates permissions, unique IDs/table names, integer geometry, bounds, seats and overlap. Areas may overlap as backgrounds; other objects may not. Places linked by inventory or current/historical tasks cannot be deleted or reclassified. The old kitchen sketch upgrades once while preserving IDs, names and notes, adding six sample dining tables (24 seats). Table count and capacity reflect configuration, not live occupancy or a POS table assignment. Public reviewers can experiment with a disposable draft but cannot save or call write APIs. Floorplan image uploads, real measurements, walls/multiple floors, configurable route authoring, native identity integration and live occupancy remain unimplemented.

## Checklist groups, activities and short manuals

The user requested **folder → task → multiple actions → short manual** on 2026-09-20, then asked for intuitive drag and drop, tap-to-check and more specific 뼈찜 restaurant checklists. The 2026-09-26 clarification makes the working structure **TAP → Task**: a TAP is one job, each Task is an action with its manual and tip, and TAP그룹 groups jobs on the board. Existing `folderId`, task and step IDs remain stable.

Worker/CEO Todo view: customer orders, ordinary prework and finished work occupy the fixed 주문처리중 / 할일 / 완료 columns. Internal processing state remains for the one-time prepared-item debit and is independent of the visible order column. TAP그룹 chips name and filter groups without creating a hierarchy step. TAP cards explicitly open their Task actions; the detail path returns directly to the preserved TAP board. Task stay in one list; phones open the manual in a bottom-sheet popup and wider screens show it beside the list. TAP completion checks all remaining Task in one server mutation; stock checks keep their separate physical quantity input. Read-only public preview changes remain on the device and send no POST request. The order-work examples and preparation manuals are proposals grounded in [the 산뼈찜 source review](docs/SAN_BONEJJIM_TAP_RESEARCH_2026-09-24.md); public visitor reports are not a confirmed restaurant recipe or service rule.

The global manual search stays below the app header while the page scrolls and remains available in Status, Todo, Calendar and Place, including inside a TAP. It searches all visible Task manuals independently of the current TAP그룹 group and board status. Results identify the Task and its parent TAP, show a short excerpt and #related terms, and open the manual without changing completion. Owners and managers can edit related terms on each Task; spelling normalization helps with common queries such as 결재/결제 and 메뉴얼/매뉴얼. A blank real store has no invented operational manuals. The seeded demo uses an OKPOS sample guide with text instructions and official links; see [POS manual sources](docs/POS_MANUAL_REFERENCES_2026-09-26.md). A store must confirm its OKPOS device version and its own cancellation, rider, recipe and storage procedures before using those instructions for work.

Editor (체크리스트 편집, owner/manager): groups reorder with a drag handle, and a long press on a group drops it on a folder chip; activities reorder with their own handle, and a long press drops an activity on another group's header. Every drag has a menu or button equivalent. Group info (icon, name, time bucket, rank, place) is a bottom sheet; an activity opens a full-screen manual editor with discard protection. Saving validates the entire draft first and names the group and activity that still needs text, both inline and as a snackbar. Drafts stay isolated until a revision-checked save; public reviewers can experiment but not save.

The demo store is now a 뼈찜·뼈곰탕 sample restaurant (우리뼈찜 · 서정리, fictional). A fresh demo starts with the 뼈찜 collection: 11 groups and 52 activities from 출근·개인 위생 and 홀·셀프바 오픈 through 등뼈 전처리 (핏물·초벌·헹굼·소분), 육수와 기본 뼈곰탕 국물, 양념·사리·특제소스, peak kitchen and hall service, 포장·배달, 브레이크타임, and 주방·홀 마감. Group place and rank hints from the library are applied when the store has that place. Existing demo files keep their own lists and can import the collection. Sample menus and ingredient names follow the 뼈찜 store, with stable item IDs and illustrative prices.

The built-in library now contains **뼈찜·감자탕 전문점 plus 25 industries and a shared F&B collection, 64 groups and 211 activities** with 24 references. The 뼈찜 content is grounded in the visit report (menu, self-bar, 기본 국물, 특제소스 rule, business hours and break time), 식품안전나라 operator obligations, 생활법령정보 health-check rules, the 식약처 delivery packaging guidance as quoted by 배민외식업광장, and one community answer on bone preparation that is explicitly marked unofficial. Times, temperatures, portion weights and recipes are written as “매장 기준” placeholders for the owner to confirm; the content remains a proposal (D-026), not an approved procedure.

[Checklist wiki](docs/wiki/CHECKLISTS.md) and the app use `docs/wiki/checklist-library.json`; run `npm run build:wiki` after editing it. The Aside exec agent returned 402 insufficient credits again on 2026-09-20; the blog was read as public web text and the five other sources were read with Aside REPL direct browser snapshots. The 배달음식점 self-inspection PDF attachment was not opened.

## Restaurant overview and sales prototype

The user requested menu-level revenue, menu orders, and restaurant-wide status together on 2026-09-19. 오늘 now opens 매장 한눈에: net sales, order count, average paid order, active order count, all-menu sales/order ranking (including zero-order menus), search/category/sort, hourly chart, current kitchen queue, and inventory/procurement/tasks/staff summaries. Wide screens use two columns; phones keep the same information in one scrollable page. The first-shift guide, map, shared activity and owner memo remain accessible.

Sales are synthetic samples, not imported POS data. `developer/sales.mjs` seeds 7 days of restaurant tickets once, independently of supplier purchase orders. Existing demo state is upgraded without replacing stock/orders/history or resetting sample tickets each day. Snapshots aggregate today or the last 7 Korean calendar days, by all/dine-in/takeout/delivery. Net sales use paid non-cancelled lines at their recorded unit price, less line discounts and refunds; unpaid orders still count as orders. Average is net sales divided by paid non-cancelled ticket count (including refunded tickets). Revenue and refunds are attributed to the original order's Korean date/hour; this is not a payment-settlement or accounting report. Tax, platform fees, partial payment, refund event dates, and real POS ingestion are not implemented. No menu sale automatically consumes ingredients without recipes and validated integration.

The active queue retains unfinished orders from earlier days, independent of period/channel reporting filters, and supports status filtering. Its age is since order acceptance, not a promised prep time or SLA. The sample is read-only for restaurant orders. Staff summaries indicate scheduled shifts, not measured attendance. Financial dashboard fields and raw priced tickets are stripped server-side for non-owner demo roles; exact production visibility is still proposed. Public review builds always generate fresh synthetic samples and block writes. POS/delivery integrations, exact accounting definitions and production authorization remain proposed pending actual store requirements.

## Current storage and integration boundaries

### Public app and local development workspace

The user selected `https://github.com/ljae/tap2work` for development and registered `tap2.work` through Namecheap. The user will share the site with a specific CEO, who can ask direction questions, request new features, and suggest improvements to the work experience. Do not impersonate the CEO or treat AI recommendations as their feedback.

The public domain root serves the read-only Flutter app with synthetic samples. It does not publish the development journal, decision history, or project status. The local developer console remains available for development; any product feedback or future CEO direction must still be explicitly provided by the user and recorded as a decision only after confirmation.

GitHub Pages hosts a separate static Flutter review build with fresh code-generated role samples. Operational writes are blocked in this build, and there is no shared public operations API. Onboarding practice remains browser-local. The localhost console and its editable canonical decisions stay local. Public hosting is a development preview, not production deployment of staff operations.

- `developer/operations.mjs`: local shared state, serialized mutations, atomic JSON persistence, revision conflicts, role projections and demo action guards.
- `.local/operations-demo.json`: generated sample state, separate from development decisions; no production employee data.
- Flutter `OperationsController`: same-origin HTTP web API, 5-second refresh, explicit error/conflict state, no offline success simulation.
- Existing `WorkController`: device-local individual onboarding demo. It is not yet connected to authenticated personal assignments.
- `docs/project-state.json`: canonical product decisions and append-only change history, visible in the developer console.

No supplier messages, real orders/payments, accounts, push notifications, payroll calculations, timekeeping, contracts, or production deployment have been connected. The local server binds loopback only. For CEO demos the user chose (2026-09-20) a tunnel from their Mac: `npm run dev:shared` allows the tap2.work origins to call only `/api/operations` through a cloudflared quick tunnel, and the public app connects when opened with `?api=<tunnel>` (remembered in that browser, cleared with `?api=off`). Members then share one demo state and see each other's checks within the 5-second refresh. Console pages and decision APIs stay loopback-only; demo roles remain impersonable and anyone with the link can change the sample state, so no real employee data belongs there. The user confirmed support for BOTH existing-supplier messaging/email workflows and food-supply platforms (D-016). Specific suppliers/platforms, delivery mechanisms, production backend and authentication remain undecided.

## Confirmed procurement direction and next design proposal

Support both traditional suppliers and food-supply platforms without forcing the owner to change all purchasing relationships. The choice confirms channel coverage, not any specific vendor, API availability, or permission to transmit real orders.

Proposed UX: keep one common cart and history, group lines by supplier, and show each group's delivery method and progress separately. A prepared message, opening another app, or a share-sheet action must not be labeled as a successfully received order. Distinguish draft/prepared, delivery unverified, sent, supplier accepted, and received where evidence supports those states; manually recorded confirmations should name the recorder. Mixed-channel actions may partially succeed, so retries must target only the failed groups and avoid duplicate orders. These states and integrations are not implemented yet.

Next input needed: names of actual suppliers/platforms and how orders are currently placed. Check supported integration mechanisms before promising automatic sending or payment. Preserve the current demo-only boundary until a real integration is implemented and explicitly used.

## First hour

| Approximate duration | Activity | Evidence before confirmation |
| --- | --- | --- |
| 5 minutes | Meet buddy and tour kitchen | Worker identifies their work area and who to ask |
| 10 minutes | Workplace hygiene and safety introduction | Buddy observes the workplace's actual preparation procedure |
| 15 minutes | One dishwashing cycle | Worker completes a supervised cycle using workplace procedures |
| 15 minutes | One simple prep task | Buddy checks the result and permitted task scope |
| 10 minutes | Practice communication | Worker can report completion and ask for help |
| 5 minutes | Check-in and next steps | Both understand the next supported task and shift |

The workplace must validate actual content and procedures before use. Orientation completion must not automatically authorize independent use of equipment or imply that statutory training, eligibility, or documentation requirements have been met. Country-specific employment, privacy, and food-safety requirements remain a research task before production use.

## Learning state

`Not started → Worker practiced → Buddy observed and confirmed`

Allow repeated practice and additional support without penalizing the worker. A production record should include worker, buddy, workplace, step version, and timestamp. Editing a template must not silently rewrite past records. Define when changed content requires renewed practice.

## Proposed production data structure

| Entity | Purpose |
| --- | --- |
| Workplace | Team, location, timezone (Asia/Seoul initially) |
| Membership | Person's workplace role and access scope |
| Job template | Reusable prep/dishwashing orientation |
| Lesson version | Demonstration, captions, practice instructions, observation criteria |
| Onboarding assignment | A specific worker's copy of a versioned learning plan |
| Practice and sign-off | Separate worker and buddy actions with timestamps |
| Buddy assignment | Named support person for each shift or orientation |
| Shift | Start/end, workplace, worker, buddy, acknowledgement |
| Help request | Requester, recipient, status, acknowledgement; no promise of urgent response |
| Team notice | Store-wide operational information |

Add InventoryItem, StockCheck, Supplier, PurchaseOrder/Line/Receipt, TaskTemplate/Occurrence/Completion, CoverageRequest, Zone/Equipment/Route and AuditEvent to the production model. The operations demo implements a simplified JSON subset, not this production database. Production access must be scoped by workplace and authenticated role. A self-selected demo role must never become the production authorization model.

## Access and communication proposal

The user selected Flutter on 2026-09-19. The primary app lives in `app/` and targets Android and iOS; the same Flutter app is served from `https://tap2.work/`. The original root HTML prototype remains a reference. The canonical decisions and history live in `docs/project-state.json`; `developer/` provides the local web workspace for reviewing and recording decisions.

A worker could start from a manager invitation. Joining, deep links, authentication, invitation expiry, shared phones, app installation, and account recovery need decisions before implementation. Do not put private employee data behind a publicly reusable store QR code. The exact invitation and installation experience is still proposed, not confirmed.

Prefer task-specific help and clear shift notices before introducing a general chat channel. During urgent situations, communicate directly on site. Real notifications require a delivery and acknowledgement strategy; the prototype only simulates the request state on one device.

## Delivery sequence to discuss

1. Validate this first-hour flow with one owner, one buddy, and a new kitchen worker.
2. Capture the actual workplace's short demonstrations and observation criteria.
3. Implement invitations, authenticated memberships, persistent assignments, and buddy records.
4. Validate integrated tasks, stock, ordering and coverage with the owner's actual suppliers, role policy and restaurant plan; then implement authenticated shift assignment and operational communication.
5. Extend into recruiting, employment documents, attendance, and payroll only after their requirements are agreed.

## Pilot questions

- Can a new worker join and find the next step without assistance?
- Does the buddy have enough uninterrupted time to demonstrate and observe?
- Which instructions still need verbal explanation or translation?
- Does the worker know when to stop and ask for help?
- Can the owner prepare tomorrow's onboarding without rebuilding today's plan?

Track time to supported participation, requests for help, repeated steps, and buddy effort. Faster completion alone is not a success metric.

## Supabase workspaces (2026-09-24)

The public app supports email signup/login through Supabase Auth. Signed-in accounts receive a separate cloud workspace seeded with synthetic examples; operation saves use an Edge Function with verified membership and role projection, RLS-protected JSONB state and revision compare-and-swap. Service keys stay server-side. Anonymous use remains an unsaved public preview. The existing local actor-switchable demo is separate. See [Supabase setup and limitations](docs/SUPABASE.md).

Active synthetic Home tickets now create order-linked Taps with the same number, channel, table and menu quantities. Completing an order Tap completes all its Task and removes the ticket from Home's active queue; reopening returns it to that queue. Preparation groups remain reusable templates. Public preview changes are shared across Home and Todo in memory.

Current cloud scope is one workspace per account and self-owned signup. Team registration stores a roster; invitations connecting other Auth users to that store and multiple-workspace switching remain unimplemented. Attendance and wage estimates are persisted, but legal pay rules remain proposed and no actual payments/orders are sent.

### Owner setup and real store catalogs (2026-09-26 implementation)

A first authenticated login now asks the owner to choose an empty store or a synthetic sample. GET alone no longer creates a sample store. An empty store starts with no fictional staff, tickets, stock, checklists, prepared stock or mapped places, and later reads do not seed them. The owner can edit the store name and note; the store catalog editor adds, edits and archives ingredients and menus. New ingredient quantity starts at zero and a physical count remains a separate recorded action. Ingredient settings include unit, supplier, price, minimum, usual order quantity, post-order review days and optional mapped place. Menu settings include name, category and listed price. IDs remain stable through edits, and archiving hides a current catalog entry while keeping prior order/receipt and sales-line snapshots. Pending receipts and stock tasks block ingredient archiving; active tickets and prepared-item usage block menu archiving. These writes use authenticated membership and revision checks.

Existing sample workspaces keep their current data until the owner explicitly chooses to store that state and open an empty store. The stored sample backup is kept server-side and omitted from all app views; the current app does not provide a restore control. Restaurant layouts and checklist editors remain available for an empty store, but the owner must add mapped places before assigning a place to work. The inventory order control still records an internal order/receipt only; it does not contact a supplier. A blank store has no POS tickets or real sales ingest. Auth invitations, shared editing by additional real accounts, live supplier orders and production payroll remain outside this owner setup implementation.
