# Flutter UI/UX audit · 2026-09-30

## Scope and ownership

Audit against `UI_UX_GUIDELINES.md`, AGENTS, PRODUCT, project-state, ARCHITECTURE, TOSS_UI_PROMPT_TEMPLATE, UI_SETTINGS_RELATIONSHIP_MAP and the existing September 29 sheet audit. This is a local, concurrent-work snapshot, not an app-wide accessibility certification or release approval.

Applied skills: `flutter-build-responsive-layout` (available width, wrapping and constrained forms) and `flutter-add-widget-test` (real interactions and widget assertions). Read `a11y-checker`; its HTML/JSX scanner is inapplicable to Flutter and was not run.

Changes owned here: `components.dart`, `design_system.dart`, `store_dashboard.dart`, `store_profile_screen.dart`, `operations_screen.dart`, the profile tab label in `settings_sheet_audit_test.dart`, new `ui_ux_*` tests/capture tool and `test/support/ui_ux_audit_cases.dart`, and this document. Existing edits in the common files were preserved. No edits to workplace_screens, time_band_editor, tap_settings_screen, tap_workspace, crew_pattern_screen, shift_change_panel, calendar_screen or backend. No project-state/architecture/relationship-map updates, per the explicit document restriction. No commit, deployment, live store writes or external messages. Mock save tests do not contact a store.

## Common fixes

| Finding | Change and evidence |
|---|---|
| SectionHeading differs from shared typography | Uses AppText.section (18px); existing dashboard/floor-plan tests rerun. |
| KPI values shrink in narrow cards | Replace FittedBox with wrapping Text, keep 24px and scale column minimum widths with text scale. Long 1,234,567,890,123원 tested/captured at 320/390/1200 and 1.5x. |
| Visible 직원 labels differ from product terminology | Profile and operations labels now use 크루, including validation/help text; no field IDs changed. Existing profile-tab audit expects 크루. |
| Fixed-height bottom menu truncates enlarged labels | Minimum 60px instead of fixed height, natural wrapped text and equal-height slots. 320px/2x text regression checks that all four labels remain complete, tap still selects, and Tab→Enter activates the first destination. |
| Account action artwork defines only a 44×44 child | Increase common account target to 48×48; existing popup callback remains in its owning screen. Size assertion added. |
| Chip's inherited one-line text silently fades long assignment options | Common AppPillField/AppSegmented/AppChoiceGroup labels reset inherited maxLines/softWrap. Reproduced visually in Task settings at 320px/1.5x; regression checks all three families at constrained width. Explicitly constrained labels supplied by callers and raw FilterChips remain caller-owned. |
| Long AppStatusPill label overflows horizontally | Flexible text wraps. Before fix, a 180px/1.5x test reproduced a 200px RenderFlex overflow. This shared component currently has no external call sites; this is a component regression fix, not a claimed screen incident. |
| AppSheetPanel loses Text.rich title because Text.data is null | Fall back to textSpan.toPlainText; preserve the standard heading typography and header semantics. Regression checks heading remains visible. No existing rich-title call-site incident claimed. |
| AppPicker rejects null onChanged although underlying AppPillField supports disabled state | Nullable callback passes through, enabling the new replacement sheet to disable selection during save. Regression checks retained selection, disabled tap and subsequent enabled selection. No selection/save mapping changed. |

Relationship-map impact: E05 retains the same four destination indices/callbacks; U01 retains sheet content/footer callbacks; U02 retains choice values and forwards null for disabled state. Source → control → action → consumer paths are unchanged. `check:ui-links` passed (30 links/manual route). The separate relationship document was deliberately not edited.

## Executed coverage

All sizes below are Flutter logical pixels, DPR 1. Tests use mock HTTP and memory learning storage.

| Surface | Conditions and actual checks | Limits |
|---|---|---|
| 업무·매뉴얼·근무표·우리매장 | New `ui_ux_audit_test.dart`: each destination at 320/390/1200×840, 1.5x text, reduced motion; actual menu tap, title, focused manual search and results with 280px keyboard inset; 12 cases/24 captures. Phone manual results require switching from directory to results. Bundled Pretendard/icons loaded and logo precached. GET-only mock assertion. | Sparse synthetic fixture: empty work board and no densely populated roster. Initial and search states, not every tab, task expansion or lower-store control. OS keyboard pixels are not rendered. |
| Original 22 settings families | Existing `settings_sheet_audit_test.dart`: all 3 widths, 1.5x text, reduced motion, 280px inset, one lower scroll, footer above y=560 where present; profile tabs POS/배달/직원/운영/기본. Prepared save conflict, original revision, draft and omitted menu links tested. | Opening a sheet directly does not prove every upstream navigation link. A single 1200px drag is a lower-content sample, not proof that every final field was reached. |
| Settings captures | Existing `settings_sheet_review.dart`: 66 captures, normal text/no keyboard. New `ui_ux_audit_review.dart`: 1.5x/reduced motion initial + keyboard/lower-scroll at all three widths. | PNG generation is not visual approval of every image. No golden baselines. |
| New assignment families | New capture fixture includes BandWorkLinks, scheduled TAP assignment (real WorkAssignmentField), TimeBandEditor, alongside the original 22 cases. Uses a synthetic saved opening band and kitchen part. Footer geometry checked with keyboard. | Does not enumerate every assignment mode, many-band/crew names, replacement vacancy, nested picker or error combination. |
| TAP dirty guard | `ui_ux_assignment_audit_test.dart`: 320/390/1200, 1.5x/reduced motion; close seeded band draft → continue → selected band retained → close/discard; GET-only assertion ensures no save. | Explicit close tested, not OS back gesture or all save-failure states. |
| Existing assignment tests | `work_assignment_ui_test.dart`: canonical TAP save and Task inheritance, actual crew badges/mine filter at 3 widths/1.5x, anyone/inherit selection. | These five tests were supplied by the assignment owner; no claim that this audit implemented those features. |
| Common behavior/motion | `ui_ux_common_test.dart`, design_system, startup_and_sheet, app_motion, motion, menu_layout tests. Wrapping, touch size, disabled state, keyboard activation, draft protection, reduced bounce/shimmer/transitions and startup covered. | Screen-reader navigation and all focus return paths not manually tested. |
| Broader existing source/data | Static inventory of UI Dart files: sheet routes, icons, ellipsis, FittedBox, small text; existing full Flutter suite attempted once. Existing reference capture tool also ran with `_site/review-data/owner.json` synthetic public seed. | Concurrent edits are not an atomic checkout. Reference seed dated September 29 and is not freshly rebuilt. |

Original 22 families: hours, parts, permissions, person, invite, verification, certificate, settlement, order-system, prepared-add/edit/count, profile, payroll, tap, task, manual, patterns, hiring, catalog, labor-review, actions. The extended capture run adds band-work-links, assignment-scheduled, time-band and assignment-crew (26 families × 3 widths × 2 states = 156 images; assignment-crew is the additional 26th family).

## Visual review and remaining issues

Directly inspected the new captures for work 320 initial; manual 390 keyboard; schedule 1200 initial; store 320 initial; prepared-add 320 keyboard/lower scroll; payroll 390 keyboard/lower scroll; hours 320 initial; person 320 keyboard/lower scroll; profile 1200 initial; Task 320 initial; patterns 390 initial; actions 320 keyboard/lower scroll. Text/headers generally wrap; forms are constrained on desktop; persistent actions remain above the simulated keyboard. The Task capture exposed the common Chip fade fixed above.

Open findings/proposed follow-up (not user-approved decisions):

- `floor_plan.dart` map labels retain spatial scaling as requested. Each place has a tooltip and selection opens the readable inspector/details; crowded maps and real keyboard/touch discovery still need device review. Dashboard KPI scaling was fixed in this work.
- BrandLogo intentionally uses FittedBox; very narrow/large-text header branding can shrink. Account target corrected without redesigning the header.
- WorkAssignmentField raw FilterChip labels were fixed by its owning agent, not this audit. This audit now verifies 40-character band and crew labels at 320/390/1200 and 1.5x, including paragraph height versus measured wrapped text. All six stress cases pass. Raw chips elsewhere remain outside this specific regression.
- At 320px/1.5x, fixed editor headings can consume several lines and leave little body space. The tested 840px height with 280px inset passes; short landscape windows/larger keyboards remain unverified.
- Direct read-only capture may show owner-oriented edit affordances alongside a public-preview banner. No authenticated server write or permission correctness is inferred from their appearance.

Computed opaque token pair contrast (sRGB relative luminance): ink/paper 16.84:1; muted/surface 7.18:1; white/primary 5.02:1; green/lime 5.98:1; accent/accentSoft 6.89:1. This is a sample calculation, not a full audit of disabled/hover/focus overlays, images or every theme state.

## Commands, results and limitations

- Initial existing targeted run: 26 passed.
- After final common wrapping changes: targeted common + original settings sheets + design system + menu layout + startup + app motion + motion: **31 passed**.
- New main matrix + initial extended capture runner (before assignment-family extension): **13 passed** (12 matrix cases + one capture test).
- Existing `tool/settings_sheet_review.dart`: **1 passed**, 66 PNGs in `.local/settings-sheet-review/`.
- Existing `tool/reference_ui_review.dart`: **1 passed**, 26 PNGs in `.local/reference-ui-review/` (390/1200, normal text; main screens, labor and settings, including transition captures).
- Full suite attempted once before the final common Chip wrapper and assignment audit additions: **194 passed, 2 failed**. Both failures: `workplace_test.dart:55`, expected text `오픈` absent at 320/390. This was an intermediate failure, superseded by the user-reported combined run below. Per subsequent user instruction, this audit did not rerun the full suite.
- Intermediate analyzer/build attempts encountered other-agent API mismatches/incomplete replacement-sheet writes. Own transient test syntax/import errors were corrected. These intermediate failures are not hidden by targeted success.
- Analyzer snapshot before final additions: no compiler errors, four style infos in shift_change_panel/shift_replacement_sheet. Final scoped results recorded below.

This audit did not perform a native/web build, browser/device run, VoiceOver/TalkBack, physical keyboard/IME, notch/system SafeArea matrix, non-Korean language, network latency, production authorization, real notifications/payroll/order integration or backend tests. Separate integrated server results are attributed below. Normal-motion behavior uses existing focused tests; screenshots use reduced motion. New fixture matrix is owner-oriented and is not an all-roles permission audit. The previous complete test suite does include mock crew/read-only/save/conflict flows, but is not a full cross-product of roles × screens × sizes × input modes.

Reproduce from `app/`:

```sh
flutter test --no-pub test/ui_ux_common_test.dart test/ui_ux_audit_test.dart test/ui_ux_assignment_audit_test.dart
flutter test --no-pub --dart-define=UI_AUDIT_CAPTURE=true test/ui_ux_audit_test.dart
flutter test --no-pub tool/ui_ux_audit_review.dart
flutter test --no-pub test/settings_sheet_audit_test.dart test/work_assignment_ui_test.dart
```

Captures are local only: `.local/ui-ux-audit-2026-09-30/` (24 main images plus 3 long-KPI images) and its `settings/` subdirectory (156 extended settings images). Existing normal-size/reference captures remain in their existing directories. Audit tests/tools are opt-in for writing PNGs, except the capture tools themselves. No images are published.


## Final scoped handoff

- Additional screen/common/assignment tests: **50 passed** (`ui_ux_common`, `ui_ux_assignment_audit`, dashboard, floor_plan, settings_screens, settings_sheet_audit, operations).
- New main/KPI capture test: **15 passed**; 24 main captures + 3 long-KPI captures.
- After the last text-scale-aware KPI column adjustment, main/KPI + existing dashboard tests: **20 passed**.
- Final affected sheet capture run: **1 passed**, regenerated profile/tap/task/assignment-scheduled/assignment-crew/band-work-links/time-band only, 42 images. Other images retain their preceding successful 25-family run; this is not a claim that every image was recaptured after unrelated agent changes. Total current settings images: 156.
- Final analyzer: **No issues found**. `check:ui-links`: 30 links/manual route pass. Scoped diff whitespace check passed.
- Final review additionally inspected 320px long KPI, long crew choice, time-band entry, scheduled assignment keyboard/footer, and 390px profile (크루 tab). Task common choice text now visibly wraps rather than fading. Two-line/multiline numeric KPI text is intentional; at enlarged text mobile metrics use one column.
- First long-label/dirty-guard attempts exposed a test expectation for the old band label (the owner added weekday text); changed to prefix matching and explicit scrolling. A stronger Chip height assertion also exposed Material default checkmark sizing; the common label test now uses the app's actual no-checkmark/padded chip policy. Arbitrary external Chip themes are not certified.
- Prior full-suite failures above are historical local results. The user subsequently reported the final combined run: **221 Flutter tests passed and 142 server tests passed**. These are user-reported integration results, not runs independently performed by this audit. They supersede the earlier reported 211-test Flutter run.

Latest copy in TAP settings (`설정 저장`, assignment affecting today's unstarted work while other rules affect future work) is owned by the assignment agent and appears in regenerated captures. This audit did not change timing semantics.


## Final integration boundary

After the combined 221-test run, the user reported one subsequent source change: the main TAP board's `matchesPart` uses the actual assignment part instead of legacy `task.partId`, with a targeted regression test to be run by the integrator. That test's result was not yet supplied at this handoff; the 221-test result must not be represented as verification of this later change.

Capture updates are complete: 27 main/KPI and 156 settings PNGs remain in the local paths above, including the refreshed phone time-band/settings captures. They predate the subsequent `matchesPart` change. In particular, the sparse main-screen capture fixture does not demonstrate assignment-part filtering; that behavior belongs to the integrator's targeted regression, not the screenshots. No further capture refresh is claimed.

This final follow-up changed only this audit document. **No further source-code or test-code changes are pending from the UI/UX audit owner.** Source integration, final targeted verification and deployment remain with the user; this audit did not commit or deploy.

## 통합 검증

서버 142개, Flutter 전체 221개 테스트 통과. 마지막 담당 파트 필터 수정 후 관련 19개 테스트 재통과. Flutter analysis, npm run check, UI 연결 30개 검증 통과. 네이티브 빌드·실기기 스크린리더 검증은 미수행. 배포 검증은 별도 기록한다.

## 배포 및 실제 웹 검증

- 최종 웹: `ce87cce5459dd4b6096305efa8822fc470ff765e`, [배포 CI](https://github.com/ljae/tap2work/actions/runs/36707128826) 성공. Operations 서버 함수 배포 완료.
- CI 서버 142개 / Flutter 222개 테스트, 정적 분석, UI 연결 검사, 웹 빌드 통과.
- 첫 웹 검증에서 시간대 ID 난수 범위의 `1 << 32`가 웹에서 0으로 컴파일되는 오류 발견. 명시적 상수로 수정하고 최종 배포본에서 새 시간대 추가 정상 확인.
- 390×844 Chrome에서 로그인 → 근무표 → 영업시간·인원 → 새 시간대 → 연결 업무 → TAP 설정 → 변경 버리기 확인. 시간대·파트 자동 배정, 파트, 시간대의 선택 상태는 접근성 트리와 화면으로 확인.
- 검증 자료는 브라우저 GET 응답에만 주입. 저장 요청 0건, 브라우저 오류 0건. 실제 매장 저장 동작은 서버/위젯 테스트로 검증했으며 운영 데이터 쓰기는 하지 않았다.
- 모든 권한·입력 조합, 네이티브 빌드 및 실기기 VoiceOver/TalkBack은 미검증.

## 숫자 휠·요일별 영업시간 후속 검증 · D-064

- 영업시간·시간대·반복 배정·날짜별 근무·OFF/단축 신청의 시각 입력을 공통 24시간/30분 숫자 휠로 통일했다. 휠은 내용에 맞춘 높이를 사용하고 취소는 초안을 반영하지 않는다.
- 요일별 시간표는 기본 설정과 별도 편집 시트에서 열린다. 공통/파트별 시간을 전환하고 시작·종료 손잡이를 독립 조정한다. 고정 시간축, 가로 스크롤, 겹침 레인과 합집합 기준 빈 구간을 제공한다. 저장은 상위 영업시간 설정의 단일 revision 저장이다.
- 마지막 로컬 검증: 서버147/147, Flutter227/227, 분석 오류 없음, JS/UI 연결30 통과, 웹 release 빌드 성공. 320/390/1200px 확대 글자 및 드래그 회귀 검증 포함.
- 첫 시각 확인 후 휠의 빈 공간과 과도한 시간표 확대를 줄였다. 후속 확대 글자 테스트에서 발견한 요일 머리글 overflow를 고쳤으며 최종 전체 테스트에서 재확인했다.
- 390px 웹 번들 미리보기에서 휠 열기/취소, 요일별 시간표 열기/돌아가기 성공. GET fixture만 사용했고 저장 요청0·브라우저 오류0. 실제 운영 설정 저장, 네이티브 빌드와 물리 기기 스크린리더는 검증하지 않았다.

최종 배포: `4ddff51dcd3011afc4e053c8ee6b88fffdae12c1`, [CI36719478274](https://github.com/ljae/tap2work/actions/runs/36719478274) 성공. 실제 tap2.work 배포본에서 숫자 휠/취소, 요일별 시간표/돌아가기 확인. 검증 중 저장 요청0·브라우저 오류0.
