---
name: restaurant-service-improvement
description: Review TAP Work service feedback and rehearsal or handover failures, distinguish operational causes, and prepare verifiable manual improvements for a requested restaurant service review.
---

Use this skill for a requested review of restaurant service problems or TAP Work manual improvements. Read the current `docs/project-state.json`, `PRODUCT.md`, `docs/ARCHITECTURE.md` and `docs/SERVICE_OPERATING_DIRECTION_2026-10-14.md` in the project root before changing product decisions. The root `AGENTS.md` governs implementation and release work.

## Evidence and diagnosis

Use the application's `serviceWorkflow.records` as observations, with `manual.id/version/hash`, `cause`, `outcome`, shift/business date and handover resolution where relevant. Practice and buddy confirmation are separate events. Briefing acknowledgement is reading, not proficiency, attendance or task completion. `unmeasured` must stay unmeasured; record counts are not customer satisfaction.

Before giving an AI runner an input, remove employee/customer identities and sensitive details from free text. The application's notice does not automatically redact personal information. Keep store-specific evidence out of the public catalogue and development history. Work from an explicitly scoped, fixed input and record which manual version was observed.

Distinguish staffing, stock shortages, equipment, handover/communication, unclear policy and learning needs. A complaint is an observation, not proof of its cause or of an employee's attitude. Check public sources for claims that need external evidence, keep applicability and actual retrieval status, and prefer the relevant regulator/manufacturer for safety or equipment. Never turn repeated model agreement into verification.

## Reviewable improvement

Produce the previous text, proposed text, reason, affected roles, observed evidence, source/applicability and a short rehearsal/observation criterion. Preserve stable manual/action IDs and already generated execution history. Include effects on translations and printed copies. Reuse existing CS reference manuals before adding duplicates. Keep rehearsal guides out of automatic per-customer tasks.

Where the user has authorized implementation, make the concrete change and perform the checks required by `AGENTS.md`. For content application follow the current owner review/selection and revision contracts. An earlier one-release review exception is not standing permission to publish all future content. Keep reusable skill guidance concise and change it only when a real failure or result supports the correction.

## Existing tooling

Read `docs/CONTENT_IMPROVEMENT.md` for the current ContentMemory contract. For a requested research run, a curated gap can be submitted using `npm run content:memory -- add-gap --file <private-gap.json>`, then the existing `content:cycle run --request <stable-id>` workflow. This requires valid existing published `sourceIds`; a store-only CS guide does not acquire a public source ID by inference. Keep unlinked/store-only improvements in the store review path.

Execute a research cycle only when the user requests that work; the app feedback screen does not run it automatically. Current runs produce review drafts. Use the existing feedback CLI only for an ingested actual job, with its genuine sources and outcomes. Fixtures and this skill's existence do not establish accuracy or usefulness.

## Verification and follow-through

Compare the targeted service/hand-over behavior and crew burden before and after the change. `docs/SERVICE_PILOT_2026-10-14.md` supplies the field protocol. If no field results exist, deliver the implemented change and validation with field effectiveness marked unverified. Recommend retaining, revising or reverting based on observed results. Do not silently modify automatic execution, publish content, send messages or deploy code merely because feedback was recorded.
