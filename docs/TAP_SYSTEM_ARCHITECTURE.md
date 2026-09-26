# Tap2.work system architecture · proposed implementation contract

## Shared demo implementation · 2026-09-24

The Flutter review uses seven BIG TAP groups as filters on one board. The working hierarchy is TAP → Small TAP: fixed TAP lanes (`todo`, `processing`, `done`) open one Small TAP list with a selected manual. A BIG TAP group is not a parent screen or a third completion level. The Node demo keeps template IDs separate from dated task IDs and records a bulk TAP completion on the remaining steps. It stores TAP moves and daily Small TAP order under optimistic revision checks. `주문처리` menu TAPs derive from synthetic tickets and move as order-number groups; they are not real POS orders; the preparation groups hold prep work. The [menu research](SAN_BONEJJIM_TAP_RESEARCH_2026-09-24.md) documents observations and conflicting reports.

The app header keeps a global manual search visible while each page scrolls. The search projection includes Small TAPs and their manuals across the store, independent of the active board group and destination. Opening a result reads the manual without checking the action. Small TAP related terms are persisted with the manual and must remain attached through template propagation and revision-checked edits. Demo POS references identify the vendor and product variant and link to [official illustrated procedures](POS_MANUAL_REFERENCES_2026-09-26.md); they are examples rather than a live POS connection.

The demo staffing data has separate Tapper IDs, rank, employment type, R&R, structured shifts, attendance events and hourly pay estimates. `clock_in`, `break_start`, `break_end` and `clock_out` use server time and reject invalid transitions. Calendar houses crew registration, a weekly 30-minute time grid and a monthly overview. Owner Status shows labor amounts and payment actions; non-owner projections omit pay data. Pay period, statutory premiums, withholding, payable closure and verified employee identity need a confirmed store policy and production implementation. Demo actor headers do not authenticate a worker. Place uses integer grid cells and rectangle, L or U orthogonal footprints for placement, overlap and route obstacles; the physical size of a cell is unspecified.

This is the target architecture for the 2026-09-23 request. The Flutter app and local Node JSON server remain a **demo**, not an authenticated POS, payroll, notification, or marketplace service. The existing first-shift guide, inventory ordering/receipt rule, and shared checklist history remain in scope.

## Product objects

| Object | Required durable fields | Rules |
| --- | --- | --- |
| BIG TAP group | `id`, `store_id` or global template scope, `name`, `description`, `creator_id`, `is_published`, `version`, `created_at` | A grouping/filter for TAPs, not an executable parent step. A future published version may package TAP/Small TAP/Menu definitions and a manifest; import remaps IDs and validates references. Marketplace listing, license, price and revenue share are separate proposed records. |
| TAP template | `id`, `group_id`, `name`, `trigger_source`, `ui_color`, `sound_url`, `concurrency_mode`, `max_concurrent`, `linked_menu_id`, `linked_place_id`, `linked_timeslot`, `version` | `group_id` categorizes the TAP and does not add a navigation level. `max_concurrent` is 1–99. Sound URLs must refer to approved assets. Templates never contain customer memos or live assignees. |
| Tap instance | `id`, `template_id`, `store_id`, `status`, `customer_memo`, `source_order_id`, `assigned_tappers`, `accepted_at`, `started_at`, `completed_at`, `revision` | Customer memo comes from a verified inbound order and has a display length limit. Completion and undo are touch actions with actor/time audit events. |
| Small Tap template/instance | `id`, `parent_tap_id`, `action_name`, `type`, `estimated_minutes`, `manual_url`, `is_checked`, `checked_at`, `checked_by` | One-time and routine completion are distinct; the current shared checklist may be migrated to this hierarchy without losing check history. |
| Menu | `id`, `name`, `total_estimated_minutes` | Standard time is a fixed, versioned operational estimate. Actual work time is recorded separately; edits do not rewrite old orders. |
| Place | `id`, `layout_id`, `kind`, grid cells/orthogonal polygon, `name`, `version` | Preserve existing zone IDs and references during migration. Validate polygon closure, right angles, bounds and collisions server-side. Tables carry configured seats, never assumed occupancy. |

`linked_timeslot`: `open`, `prep`, `peak`, `break`, `close`, `slow`, `custom`. UI labels are 오픈, 준비, 피크, 브레이크, 마감, 여유, 별도지정. Store-local clock ranges and exception days need configuration; they are not implied by these labels.

## Order path

`POST /v1/webhooks/{provider}` is a separate production service with provider-specific signature verification, timestamp/replay checks, schema validation, and a provider/store/external-order unique key. Credentials are kept outside the app and repository. A Redis `SET key value NX EX` claim reduces duplicate processing, while a PostgreSQL unique constraint on `(store_id, provider, external_delivery_id)` is the durable authority. In one database transaction: upsert accepted order, create the TAP and Small TAP instances from pinned TAP template versions, assign their BIG TAP group IDs, and write an outbox event. An outbox worker publishes assignment and notification events with retry/dead-letter handling. A repeated delivery returns the existing order ID and never creates another TAP. Conflicting payloads with the same external ID are quarantined for review.

A token bucket at the gateway is scoped by verified provider and store, with separately configured sustained rate and burst capacity. Exhaustion returns a retryable response; the upstream provider's retry contract must be tested before setting limits. The ingest route never accepts demo actor headers as identity. No real delivery or POS provider has been selected or connected.

## Planning and routing

The user removed the five-minute plan on 2026-09-24. Its UI, planner and task scheduling endpoint have been removed. Staffing uses revision-checked 30-minute shifts and bounded weekday repetition (up to 90 days). The server validates qualifications and overlap across each proposed date, including overnight boundaries, before applying the set. Existing unrelated shifts are retained. Unfilled slots suggest qualified crew or link to an external HR site marked as an unfinished integration. No messages or requests are sent automatically.

The routing service rasterizes validated orthogonal Place footprints into blocked grid cells. A* uses Manhattan distance and four-way moves; routes are recomputed when layout versions change. A route is an efficiency suggestion, not an emergency or food-safety instruction. PostgreSQL/PostGIS geometry and GiST indexes support spatial lookup of places/obstacles; the pathfinder operates on the rasterized grid. Recheck any route when the map is edited. Current demo layout is a schematic with rectangular zones; L/U polygons and persisted obstacle paths are future production work.

## Shifts and payroll

Weekly/monthly calendar: proposed swap → target employee acceptance → manager approval or rejection. Acceptance is not approval. A server job expires unapproved requests at the earlier of the configurable deadline and shift start. Every transition stores actor, timestamp, old/new shift IDs, and the policy version used for warnings. Rest-gap and work-hour warnings are computed before approval; the manager sees the affected shifts and must explicitly resolve or reject. Do not label this audit trail a guaranteed legal defense.

Payroll separates scheduled hours, verified attendance, premium-eligible minutes, base rate, approved adjustments, paid amount, and remaining amount. Planned staffing hours do not establish payable hours. Jurisdiction, employer size, contract terms, breaks, rounding, overtime eligibility, premium rates and pay periods require store-specific legal/payroll review before any statutory calculation is enabled. The requested `1.5x` is a configurable policy candidate, not a universal legal constant. No live payroll values should be displayed to workers from the current demo shift strings.

## Device and marketplace boundaries

Touch handles completion and undo. A production identity service binds each Tapper to a personal device and verified store membership; push events contain minimal information and resolve to authenticated in-app details. Sound delivery depends on platform notification permissions and OS behavior, so the app must offer a visible in-app queue as the reliable fallback. No shared POS tablet or voice hardware is required.

Marketplace packages are versioned and signed, with validation on import, preview of changed menus/tasks, licensing, creator payout records, refund handling, and a separate operator-defined revenue-share agreement. Publication is an explicit manager/creator action. Reputation metrics and weekly thumbs-up prompts require voluntary, purpose-specific consent, withdrawal, deletion/anonymization workflow, and role-limited visibility. A manual thumbs-up is human input; it does not by itself establish compliance with any employment or privacy law or prove improved retention. Recruiting and external hiring references remain later-phase work.

## Delivery sequence

1. Formalize TAP/Small TAP schema and BIG TAP grouping with stable historical IDs; ship grouped menu TAPs, popup manuals and staffing calendars against store data.
2. Add production identity, tenant isolation, PostgreSQL/PostGIS, Redis, event outbox, provider adapters and verified webhook tests. Select real POS/delivery partners and obtain their contracts/specifications.
3. Add order-based assignment, personal push, versioned layout routing, and shift swap workflow with a real scheduler.
4. Validate attendance/payroll rules per location and employer, then add an auditable calculator. Add consent/reputation and marketplace commerce only after their policies and provider requirements are agreed.

Production release gates include provider retry/idempotency tests, load/burst tests, tenant authorization tests, timezone/shift-boundary tests, route validation after layout changes, and native device notification checks. No step in this document authorizes placing supplier orders or publishing employee performance data.

## Prepared portions and menu usage · 2026-09-24

The user requested the reusable prepared output workflow described in [Prepared workflow](PREPARED_WORKFLOW.md). It keeps menu finishing steps separate from advance preparation. Configurable prepared items map stable menu IDs to per-menu use and generate one replenishment TAP at or below a shortage point. A signed prepared count and attributed movement ledger preserve unmet demand. Batch output uses actual completed quantity exactly once; corrections require a reason. Existing order evidence is retained through migration. This is a sample operations ledger, not purchased raw-material inventory or validated food-safe production control.
