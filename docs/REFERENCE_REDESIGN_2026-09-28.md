# Screenshot-led Flutter redesign · 2026-09-28

Reference: the user's local `IMG_6081.PNG` through `IMG_6096.PNG` (16 screens). All were inspected. The source screenshots and their personal/store details are not copied into the repository.

## Visual direction

Charcoal canvas `#101112`, dark cards `#181A1C`, elevated controls `#222528`, light foreground `#F0F2F4`, muted secondary text, teal primary buttons, green/coral status accents, rounded cards, pill choices, and bottom sheets. Shared typography, 24px horizontal spacing, reduced motion, and the four destinations remain. This supersedes the light palette in D-045; it does not replace Flutter or revert restaurant operations to onboarding only.

The shared tokens/theme and the work board, manuals, calendar, staff, store dashboard, first-shift guide, layout, forms, loading, and navigation use the new surfaces. Existing TAP/Task completion, inventory/order deadlines, labor calculations and buddy confirmation remain.

## Screen and function mapping

| Reference | Current implementation | Boundary |
| --- | --- | --- |
| 6081: weekday shift splitting | Our Store → 영업 시간대; individual/all-day saves, one/two/three-band presets, editable 30-minute boundaries, closed days; calendar displays selected day's bands | Same-day bands only. Existing overnight store hours and actual shift assignments remain separate. Custom boundaries work; arbitrary band-count creation is not included. |
| 6082, 6089: parts | Part add/rename/reorder/hide, role mapping; task-board and staff part filters | Parts preserve IDs and cannot be deleted; hiding preserves references. Worker assignments are in profiles. |
| 6083–6085: people | Compact avatar cards, staff profile sheets, part/time-band assignment, visible attendance and schedules, owner-only pay/settings links | Join dates and certificate status are not invented. Certificate screen reports secure-storage integration missing. |
| 6086–6088: invitations | Demo role codes, seven-day expiry display, rotation, revocation, clipboard copy, scannable QR containing the demo code | Explicitly demo-only. No identity verification, actual membership join, link sharing, use redemption or messaging. Authenticated workspaces cannot generate demo codes. |
| 6090–6091: role permissions | Owner can restrict task management/completion, schedule edits, stock counts, and procurement writes per existing role; server enforces restrictions and projects completion availability | Enabling never expands the pre-existing role baseline. Payroll remains owner-only. Per-person overrides, announcements and approval workflows remain unimplemented. |
| 6092: clock verification | A dedicated integration-status screen; existing server-recorded clock events stay functional | GPS radius enforcement and native Wi-Fi verification are not implemented; no misleading enabled switch. |
| 6093: settlement | Existing owner-only hourly rate/payment period and weekly labor views use the redesign; accessible from employee profiles | No change to calculation rules, no new store-wide rounding/start-day/automatic clock-out behavior, no destructive store deletion. |
| 6094: schedule | Dark weekly/monthly calendar, date navigation, coverage, recurring shifts and weekday band entry | Existing Monday-first coverage layout is retained, not copied into a separate conflicting roster. |
| 6095–6096: home | Store preparation checklist based on actual state, collapse/expand, shortcuts, own attendance card and work status | Lives under Our Store to retain four destinations. No invented news, alerts or document completion. |

The exact color values, default part-role mapping, three supported band presets and demo invitation expiry are implementation choices, not newly confirmed business policies. D-008 and D-018 remain proposed. The reference's unrelated features are not represented as production integrations.

## Persistence and checks

`developer/workplace.mjs` adds revision-checked actions through the existing operations store. No external service is contacted by these actions. Public previews do not POST or save; restricted salaries remain excluded from non-owner responses. New editors capture the opening actor and revision, keep the draft on a conflict, and ask before discarding edits. Unsaved writable day/role edits must be saved before switching; preview edits remain unsaved.

Validation completed:

- Flutter full suite: 117 tests passed, including 320/390/1200px new sheets at 1.5× text size and stale-revision draft retention.
- Node full suite: 81 tests passed, including durable part assignments, preservation/rejection cases, independent/all-day band updates, permission enforcement, and demo code rotation/revocation/projection.
- `npm run check`, `git diff --check`, and `npm run build:app` passed. Local `/app/` returns HTTP 200.
- Bundled-font capture test passed at 390/1200px; work, store, manuals, schedule, pay, settings, staff and invitation screens captured under `.local/reference-ui-review/`. Phone captures were visually reviewed.
- Initial failures: old white-card expectation, lazy-list test scrolling, lazily captured editor revision, and analyzer brace lint. These were corrected. A remaining white manual panel found during visual inspection was corrected.

Native builds, physical-device checks, authenticated real-account writes and production deployment were not performed. The broader reference feature rollout remains in progress because real invitations, secure documents and clock verification need integration work.


## Part-centric follow-up and deployment · 2026-09-28

The later user request supersedes the earlier role-mapping editor and folder filters described above. Parts now directly classify tasks, crew and shifts. The third destination is 근무표 with a calendar icon; crew is the shared product term. The weekly grid fixes the left time axis and groups part columns under each weekday, derives requirements from business hours and supports dated time overrides, assignment, repeat shifts and unassignment. All form and workspace selectors use shared pills. Order processing is hidden until the owner enables its setting; external systems remain explicitly unconnected. The continuously maintained contract is [ARCHITECTURE.md](ARCHITECTURE.md).

Final verification: 115 Flutter regression tests plus one bundled-font capture test (116 total), 85 server tests, clean Flutter analysis, JavaScript checks and both web builds. Phone and desktop schedule captures were inspected; weekday headings were aligned to remain visible on a phone and overlapping assignments retain readable widths. GitHub Pages release `936d9c919791c73a3931c73ebbfe439482c87d02` and Supabase operations deployed successfully. [Deployment workflow](https://github.com/ljae/tap2work/actions/runs/36417158071). Live root HTTP 200, new bundle feature markers, part-aware public sample and unauthenticated API 401 were verified. Native devices and authenticated writes involving real crew were not tested.
