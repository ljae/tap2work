# Work Studio redesign — 2026-10-11

The user requested a coherent full-app redesign for a younger adult audience, including motion, loading, transitions, brightness and time controls, followed by an Apple simulator demonstration handled by GPT-6.1 Sol.

## Implemented design

| Layer | Previous | Work Studio |
| --- | --- | --- |
| Canvas / card / control | #101112 / #181A1C / #222528 | #171C1C / #232B2A / #303B38 |
| Text / secondary text | #F0F2F4 / #A0A7AF | #F2F5EF / #ADBAB4 |
| Selection / primary action | Mixed white, teal and green | Mint #79E2BA with dark foreground |
| Attention / changes | Coral #FF9986 | Coral #FFA28E; icon and text retained |
| Button feedback | 0.95 scale, spring-like return | 0.975 scale, 80ms press / 220ms ease-out return |
| Content transition | 240ms / 10px | 260ms / 6px, only current content remains interactive |
| Sheets | 360ms / 220ms | 340ms / 220ms |
| Navigation | Independent colored cells | Shared moving mint capsule, explicit selected semantics |
| Time selection | Two plain wheels | Large tabular draft, labeled wheels, +/-30-minute controls |

Pretendard and existing language fallbacks, four main destinations, green/coral identity, 48px targets, wrapping text and existing operational permissions remain the shared foundation. Brightness refers to the app palette; this does not introduce device brightness control or a light/dark preference.

Native review found that 580px preferred sheet height hid the quick controls below the viewport. Preferred height is now 680px (clamped to available space), with scrolling retained for larger text/short screens. Full-page AppEditorScaffold now honors the top safe area; sheet-provided safe areas remove that inset to prevent duplication.

Time tools retain the 24-hour/half-hour contract. Wheels and quick controls share one local draft, including midnight wrap. Apply returns a time to the parent draft; cancel returns no value. The parent form still owns final saving, revision checks and overnight business-day calculations. Controller lifetime now belongs to the sheet widget, including its closing transition. Fixed labels cover all eight existing locales.

The existing TAP Water animation receives a quiet ambient surface. Skeleton colors follow the palette and run at 1800ms, stopping for reduced motion and disabled TickerMode. Existing readiness, 12-second slow state, retry and error behavior remains authoritative. No fake percentages or mandatory animation delay.

## Verification

- Focused motion, time, overnight business hours and responsive-layout tests: 37 passed.
- New draft cancel/apply, midnight wrap, wheel synchronization, landscape/large text, rapid navigation and contrast tests initially passed (4); iPhone safe-area regressions added during native review.
- Representative text/secondary text/mint on all three shared surfaces and action foregrounds meet calculated 4.5:1 contrast. This is not a full accessibility certification.
- Responsive capture tool: 21 screenshots of the four actual app destinations and time tools at 320/390/1200px, including 1.5x text, plus loading. Capture test passed.
- Relevant server/startup/asset tests: 20 passed. UI relationship checker: 75 links verified.
- Final full Flutter regression:554 passed,3 browser-only skipped. Final Flutter analysis:No issues found. UI links75 and relevant Node20 passed.

Public fictitious fixtures only. The simulator entrypoint is under `app/tool/`, separate from production startup/authentication. It uses read-only operations and a local fixture transport, with no real account or operational writes. Simulator execution is not physical-device performance or App Store deployment evidence.

Existing unrelated dirty work is preserved. Source snapshots and logs: `.local/studio-redesign/`.

Initial full Flutter run:551 passed,3 browser-only skips,1 expected-visual assertion failed because completed cards now recede to AppColors.paper. The assertion was updated to the intended new surface; partial-progress checks remain intact. The final full run passed554 with3 browser-only skips. Initial analyzer found deprecation/unnecessary-import and capture-tool interpolation lint; corrected before final analysis.


## Final native review by GPT-6.1 Sol

Actual iPhone17Pro / iOS26.5 simulator debug native build, installation and execution completed. Final incremental Xcode build26.6s; harness analysis0issues. Four destinations used actual Simulator pointer touches. Welcome/loading/time screens use the production widgets opened by the isolated tool. The loading screen is a visual demonstration, not a network performance measurement. Actual quick controls changed09:00 ->09:30 ->09:00 and dragging the hour wheel changed09:00 ->11:00.

Native-discovered fixes were rechecked: welcome title clears the status bar and time quick controls stay above the fixed footer. Regression tests reproduce native safe areas. Final responsive capture tool passed again after both fixes.

Evidence: `.local/studio-redesign/simulator/native-demo.mp4` (36.4967s,1206x2622,H.264); screenshots01-work through10-time-wheel-touch; `verification.json` includes hashes and actual commands. Live local fixture server is GET-only on127.0.0.1:3197; POST405 verified. No production auth or operational writes. No new web/store deployment; physical devices, Android native execution, release/profile frame performance and native-speaker review were not performed.
