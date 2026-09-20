# Product working brief

## Purpose

Help a small Korean food and beverage business coordinate people, daily work, stock, and procurement in one approachable phone app. The user explicitly expanded the initial onboarding-only scope on 2026-09-19. The first hour still prepares a new person to participate alongside a buddy: an approximate learning plan, not a countdown or a guarantee of readiness.

Kitchen prep and dishwashing remain the starting jobs. Each worker needs their own learning progress and confirmations; tomorrow's new hire reuses the same workplace materials without inheriting someone else's completion status. Shared operational tasks are different: one coworker's inventory check is visible to the whole team and should not be duplicated.

## Brand artwork

The current repository-root `tap2work.png` is a newly generated horizontal doodle logo, requested by the user to carry forward the original's comforting, messy-but-charming blob characters. A tired blue character holds hands with a cheerful yellow companion beside “tap2.work” and “we all need a minute”. The earlier supplied artwork is preserved in `docs/branding/tap2work-original.png`; generation prompts and provenance are in `docs/branding/README.md`. Flutter headers (operations and first-shift guide), the public review portal, local developer console and web favicons use the new artwork. `scripts/sync-branding.mjs` copies it verbatim into Flutter assets before both web builds; native launcher icons remain unchanged.

## Phone experience

| Person | Primary action | Supporting actions |
| --- | --- | --- |
| New worker | Open the next small task | See shift and buddy; ask for help |
| Buddy | Demonstrate and observe practice | Confirm a step; respond to help |
| Owner/manager | Prepare a reusable role template | Invite workers; assign buddies and shifts |

The app has five destinations: 오늘, 할 일, 재고/발주, 우리 팀, 매장 지도. The existing first-shift guide (오늘, 일하는 법, 근무표, 도움) is accessible from 오늘. Administrative actions are separate from worker actions. Use short Korean text, large touch targets, restrained friendly emojis, and descriptive labels rather than emoji-only controls. The first-shift guide keeps text placeholders for demonstrations. The user has now selected short manuals per activity and tap-to-check confirmation; the guide’s video/photo format remains deferred in D-007.

The latest user request brings staff operations and procurement into the prototype now. Recruiting remains a later phase; do not introduce a job marketplace as a prerequisite.

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

The layout is a configurable schematic, not a measured architectural plan. It now shows the whole restaurant with table count, total configured seats and major equipment count. Owners/managers can set a layout name and grid (8–30 columns/rows), add up to 80 tables/equipment/storage/entrances/areas, change names/notes/position/size and table capacity (1–20), move a selected object by tapping an empty cell or using arrow buttons, and delete unlinked objects. Overview supports pinch zoom and a full-size item list. Existing example routes remain available only when every referenced place still exists; they are not obstacle-aware or validated safety/emergency guidance.

Editing uses a separate draft and the opening revision; polling cannot replace the draft, cancellation discards it, and stale saves fail with an explicit reload option. The server validates permissions, unique IDs/table names, integer geometry, bounds, seats and overlap. Areas may overlap as backgrounds; other objects may not. Places linked by inventory or current/historical tasks cannot be deleted or reclassified. The old kitchen sketch upgrades once while preserving IDs, names and notes, adding six sample dining tables (24 seats). Table count and capacity reflect configuration, not live occupancy or a POS table assignment. Public reviewers can experiment with a disposable draft but cannot save or call write APIs. Floorplan image uploads, real measurements, walls/multiple floors, configurable route authoring, production identity and live occupancy remain unimplemented.

## Checklist groups, activities and short manuals

The user requested a hierarchy of **folder → task → multiple actions → short manual** on 2026-09-20, and later the same day asked for a redesign: intuitive drag and drop and tap-to-check for the CEO and workers, more specific real-world checklists, and a first focus on a restaurant selling 뼈찜 (the 산뼈찜 blog post was the reference). The data model is unchanged; the vocabulary in the app is now **폴더 → 그룹 → 활동**: a group is a bundle of activities done by the same rank in the same time bucket, and each activity carries its own manual and tip.

Worker/CEO view (할 일): a progress card counts today's activities, time-bucket chips (오픈·준비·피크·브레이크·마감) show remaining counts, and each group is a card with an emoji, rank, place and a completion ring. Tapping the circle left of an activity confirms it in one tap with haptic feedback; tapping the activity name reveals the manual and tip. Finished groups fold away. Non-leaders get an “내 담당만” filter and see a lock on groups of another rank; they can still read the manuals. A mis-tap can be reversed: the person who tapped it, or an owner/manager, confirms a dialog and the server reopens the activity (and the group) for today only, recording the reversal in the shared activity feed. Stock checks stay a separate card with the physical-quantity flow. In the public review build, tapping a circle shows the check on that device only, labelled “체험 · 저장 안 됨”, with a one-time notice that nothing is saved; a tap blocked by rank explains itself in a snackbar instead of doing nothing.

Editor (체크리스트 편집, owner/manager): groups reorder with a drag handle, and a long press on a group drops it on a folder chip; activities reorder with their own handle, and a long press drops an activity on another group's header. Every drag has a menu or button equivalent. Group info (icon, name, time bucket, rank, place) is a bottom sheet; an activity opens a full-screen manual editor with discard protection. Saving validates the entire draft first and names the group and activity that still needs text, both inline and as a snackbar. Drafts stay isolated until a revision-checked save; public reviewers can experiment but not save.

The demo store is now a 뼈찜·뼈곰탕 sample restaurant (우리뼈찜 · 서정리, fictional). A fresh demo starts with the 뼈찜 collection: 11 groups and 52 activities from 출근·개인 위생 and 홀·셀프바 오픈 through 등뼈 전처리 (핏물·초벌·헹굼·소분), 육수와 기본 뼈곰탕 국물, 양념·사리·특제소스, peak kitchen and hall service, 포장·배달, 브레이크타임, and 주방·홀 마감. Group place and rank hints from the library are applied when the store has that place. Existing demo files keep their own lists and can import the collection. Sample menus and ingredient names follow the 뼈찜 store, with stable item IDs and illustrative prices.

The built-in library now contains **뼈찜·감자탕 전문점 plus 25 industries and a shared F&B collection, 64 groups and 211 activities** with 24 references. The 뼈찜 content is grounded in the visit report (menu, self-bar, 기본 국물, 특제소스 rule, business hours and break time), 식품안전나라 operator obligations, 생활법령정보 health-check rules, the 식약처 delivery packaging guidance as quoted by 배민외식업광장, and one community answer on bone preparation that is explicitly marked unofficial. Times, temperatures, portion weights and recipes are written as “매장 기준” placeholders for the owner to confirm; the content remains a proposal (D-026), not an approved procedure.

[Checklist wiki](docs/wiki/CHECKLISTS.md) and the app use `docs/wiki/checklist-library.json`; run `npm run build:wiki` after editing it. The Aside exec agent returned 402 insufficient credits again on 2026-09-20; the blog was read as public web text and the five other sources were read with Aside REPL direct browser snapshots. The 배달음식점 self-inspection PDF attachment was not opened.

## Restaurant overview and sales prototype

The user requested menu-level revenue, menu orders, and restaurant-wide status together on 2026-09-19. 오늘 now opens 매장 한눈에: net sales, order count, average paid order, active order count, all-menu sales/order ranking (including zero-order menus), search/category/sort, hourly chart, current kitchen queue, and inventory/procurement/tasks/staff summaries. Wide screens use two columns; phones keep the same information in one scrollable page. The first-shift guide, map, shared activity and owner memo remain accessible.

Sales are synthetic samples, not imported POS data. `developer/sales.mjs` seeds 7 days of restaurant tickets once, independently of supplier purchase orders. Existing demo state is upgraded without replacing stock/orders/history or resetting sample tickets each day. Snapshots aggregate today or the last 7 Korean calendar days, by all/dine-in/takeout/delivery. Net sales use paid non-cancelled lines at their recorded unit price, less line discounts and refunds; unpaid orders still count as orders. Average is net sales divided by paid non-cancelled ticket count (including refunded tickets). Revenue and refunds are attributed to the original order's Korean date/hour; this is not a payment-settlement or accounting report. Tax, platform fees, partial payment, refund event dates, and real POS ingestion are not implemented. No menu sale automatically consumes ingredients without recipes and validated integration.

The active queue retains unfinished orders from earlier days, independent of period/channel reporting filters, and supports status filtering. Its age is since order acceptance, not a promised prep time or SLA. The sample is read-only for restaurant orders. Staff summaries indicate scheduled shifts, not measured attendance. Financial dashboard fields and raw priced tickets are stripped server-side for non-owner demo roles; exact production visibility is still proposed. Public review builds always generate fresh synthetic samples and block writes. POS/delivery integrations, exact accounting definitions and production authorization remain proposed pending actual store requirements.

## Current storage and integration boundaries

### Public development review

The user selected `https://github.com/ljae/tap2work` for development and registered `tap2.work` through Namecheap. The user will share the site with a specific CEO, who can ask direction questions, request new features, and suggest improvements to the work experience. Do not impersonate the CEO or treat AI recommendations as their feedback.

The public review page shows product questions, versioned decisions, milestones, and GitHub Issue links for feedback. GitHub Issues is the initial implemented feedback mechanism: the reviewer logs in and explicitly submits a public issue. This is not an anonymous feedback inbox. Feedback does not automatically change confirmed decisions; agreed changes are recorded in the canonical file with reasons and history.

GitHub Pages hosts a separate static Flutter review build with fresh code-generated role samples. Operational writes are blocked in this build, and there is no shared public operations API. Onboarding practice remains browser-local. The localhost console and its editable canonical decisions stay local. Public hosting is a development preview, not production deployment of staff operations.

- `developer/operations.mjs`: local shared state, serialized mutations, atomic JSON persistence, revision conflicts, role projections and demo action guards.
- `.local/operations-demo.json`: generated sample state, separate from development decisions; no production employee data.
- Flutter `OperationsController`: same-origin HTTP web API, 5-second refresh, explicit error/conflict state, no offline success simulation.
- Existing `WorkController`: device-local individual onboarding demo. It is not yet connected to authenticated personal assignments.
- `docs/project-state.json`: canonical product decisions and append-only change history, visible in the developer console.

No supplier messages, real orders/payments, accounts, push notifications, payroll calculations, timekeeping, contracts, or production deployment have been connected. The local server binds loopback only. The user confirmed support for BOTH existing-supplier messaging/email workflows and food-supply platforms (D-016). Specific suppliers/platforms, delivery mechanisms, production backend and authentication remain undecided.

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

The user selected Flutter on 2026-09-19. The primary app lives in `app/` and targets Android and iOS; a Flutter web build is used for development review. The original root HTML prototype remains a reference. The canonical decisions and history live in `docs/project-state.json`; `developer/` provides the local web workspace for reviewing and recording decisions.

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
