# tab2work development continuity

Before making product or architecture changes, read `docs/project-state.json` and `PRODUCT.md`. `docs/project-state.json` is the canonical, versioned project decision and development history file. `RESEARCH.md` contains the scoped competitor research.

- The user has selected Flutter. The application source is `app/`. Root HTML/JS files are the original reference prototype, not the primary app.
- Initial users: Korean small F&B kitchen prep/dishwashing workers, already hired. After roughly one hour they work with a buddy. Future recruiting belongs in the roadmap, not the first-release critical path.
- Scope expanded by the user on 2026-09-19: integrated staff operations, shared timed/rank-based checklists, inventory, grouped procurement, and restaurant layout/routes. Preserve the first-shift guide within this broader app; do not revert the expansion to onboarding-only.
- Shared operations demo state lives in `.local/operations-demo.json` and is served by `developer/operations.mjs`. It is separate from canonical project decisions and device-local learning progress. Demo actor headers are not production identity/authentication. Never send real supplier orders without an approved integration and clear user action.
- Orders do not increase stock until receipt. The user selected inventory checks N days after the latest order (D-017), once per order, NOT a recurring interval from physical count. Intermediate checks/receipt must not postpone the deadline. Preserve prior records when new orders supersede pending checks. Use version checks to prevent silent overwrites; maintain Korean date boundaries and server-side demo role projections in tests.
- Design for short, low-pressure phone interactions. Preserve separate worker practice and buddy confirmation. Do not describe prototype actions as real notifications, authenticated actions, or payroll.
- Keep unresolved product choices marked `proposed`; do not turn recommendations into user approval. User instructions in the conversation take precedence.
- Record significant changes and actual verification in `docs/project-state.json`. Preserve earlier history entries. For a decision change include the previous and next values and the reason; increment `revision`. The developer console records these automatically when edited through its UI.
- Read the latest file before changing it; preserve changes the user may have saved through the console. The console uses revision checks to prevent stale writes.
- Keep milestones honest about work that is implemented, in progress, or planned. List failed or unperformed checks clearly. Do not report a native build based only on a Flutter web build.
- Developer console source: `developer/`. Start with `npm run dev:console`; Flutter preview is served from `app/build/web` at `/app/` after `npm run build:app`.
- Run Flutter analysis and relevant tests for app changes. Run `npm run test:console` when changing decision persistence or APIs. Use `npm run check` for JavaScript checks.
- Never place production employee data or credentials in the demo state, development history, or source files.
- Development repository: `https://github.com/ljae/tab2work`; requested domain: `tab2.work` (Namecheap). `site/` is the public review portal; `.github/workflows/pages.yml` builds and deploys GitHub Pages. `npm run build:site` creates a separate read-only Flutter review build and freshly seeded samples; never publish `.local/` or expose the local write APIs.
- The user will share the portal with a specific CEO for direction questions, new features and improvements. GitHub issue forms collect explicitly submitted public feedback. Do not invent CEO feedback or automatically convert requests into confirmed product decisions.

Routine reversible implementation work remains authorized. These instructions do not impose an extra approval process.
