# Product working brief

## Purpose

Help a small Korean food and beverage business coordinate people, daily work, stock, and procurement in one approachable phone app. The user explicitly expanded the initial onboarding-only scope on 2026-09-19. The first hour still prepares a new person to participate alongside a buddy: an approximate learning plan, not a countdown or a guarantee of readiness.

Kitchen prep and dishwashing remain the starting jobs. Each worker needs their own learning progress and confirmations; tomorrow's new hire reuses the same workplace materials without inheriting someone else's completion status. Shared operational tasks are different: one coworker's inventory check is visible to the whole team and should not be duplicated.

## Phone experience

| Person | Primary action | Supporting actions |
| --- | --- | --- |
| New worker | Open the next small task | See shift and buddy; ask for help |
| Buddy | Demonstrate and observe practice | Confirm a step; respond to help |
| Owner/manager | Prepare a reusable role template | Invite workers; assign buddies and shifts |

The app has five destinations: 오늘, 할 일, 재고/발주, 우리 팀, 매장 지도. The existing first-shift guide (오늘, 일하는 법, 근무표, 도움) is accessible from 오늘. Administrative actions are separate from worker actions. Use short Korean text, large touch targets, restrained friendly emojis, and descriptive labels rather than emoji-only controls. The current guide includes text placeholders for demonstrations; actual learning format is deferred by the user in D-007 until the manual strategy is defined.

The latest user request brings staff operations and procurement into the prototype now. Recruiting remains a later phase; do not introduce a job marketplace as a prerequisite.

## Integrated operations prototype

| Destination | Main question | Implemented sample interaction |
| --- | --- | --- |
| 오늘 | How is the restaurant doing? | Menu sales/order dashboard, period/channel filters, active kitchen queue, stock/tasks/shifts, first-shift guide |
| 할 일 | What should we check, and who has done it? | Opening/prep/peak/closing filters, rank filter, recurring task creation, actor/time completion |
| 재고/발주 | What do we have and what should we order? | Physical count, minimum threshold, review interval, grouped supplier cart, demo order, separate receipt |
| 우리 팀 | Who is working and where is there a gap? | Shared sample shifts, leave status changes, coverage requests and manager acceptance |
| 매장 지도 | Where do I go or find equipment? | Sample floor layout, fridge/storage/stove/prep/sink locations, three numbered routes, editable location notes |

Inventory flow: **check actual stock → collect needed items → review quantities grouped by supplier → one demo order → acknowledge receipt → later inventory check**. An order never increases on-hand quantity; receipt applies exactly once. An open order blocks duplicate orders for the same item. Partial deliveries, cancellations, price/tax validation and real supplier integration are not implemented.

The user selected a fixed delay after ordering (D-017). Each material retains a configurable N-day delay and minimum quantity. One review is due N days after the latest order; an intermediate physical count or receipt does not postpone it. Completing that review does not start another repeating review; the next order starts a new schedule. The current implementation uses elapsed 24-hour days from the order timestamp. A new order supersedes unfinished reviews from older orders without deleting their records. Changing N recalculates unfinished review dates from the same order. Exact default delays per material still need owner input.

API reads materialize due tasks; polling is not a production scheduler or push service. Checks store actual quantity, actor and timestamp. Daily routine templates still generate new tasks at Korean date boundaries. Initial time buckets are labels, not configurable clock ranges. Managers can define templates by bucket, rank and place. Exact time ranges, exception days, individual assignees and overdue escalation need further design.

Shared information includes names, roles, shift hours, leave status, coverage status, work completion, and stock counts. Private leave reasons are not collected in the shared demo. Owner-only sample labor estimate and memo are stripped from non-owner API responses; purchasing prices are available to owner/manager, not crew/cook. This is an initial permission proposal, not approved production policy. Demo actor selection is intentionally impersonable and therefore **not security for real employee information**.

The layout is schematic sample data. Location names/notes can change, but actual floorplan uploading, geometry editing, machine-specific instructions and route validation remain pending. Never describe sample routes as validated safety or emergency guidance.

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
