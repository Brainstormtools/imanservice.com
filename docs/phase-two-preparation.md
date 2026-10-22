# Phase 2 preparation — projects and team calendar

Prepared 22 October 2026 from the uploaded SRS (suggested build phases, page 37), current main `8287ef63560931122f522b8a513222152d167f97`, both requirement documents, development backlog and training guide. This is a preparation plan, not implementation or acceptance evidence. The numbered build phases are separate from project execution phases 0–5.

## Release gate and resume point

Phase 1 implementation is merged in PRs #243/#244. All 9,016 checks / 174 suites and unchanged 705-file source were verified at fingerprint `84d8bc36490477a86027136509d388598abc18d522c7f89e1cc5984f6c65d15e`. Database safeguards are applied, including `20261022223747`; do not reapply existing migrations. The user's manual Vercel attempt returned `api-deployments-free-per-day` and “try again in 24 hours.” That is provider guidance, not a promised reset time.

Keep the tested Phase 1 main as the deployment target while this preparation remains a draft PR. After provider capacity returns, deploy that main to Production and verify exact source, READY state, domain and actual portal/logo assets. Only then begin Phase 2 application changes. Last verified live release remains PR #240 / `dpl_DtZQL78piBP9dSNnxjRkHpTU86dj`. Actual Meta account authorization and all 41 client-owned live/browser/export/device acceptance items remain pending. No phase, training module or CRM-wide completion is claimed.

## Current implementation and audit map

Existing files and test suites are evidence that functionality exists; each workflow still needs a requirement-level gap audit. Backlog statuses below are carried forward, not newly completed.

| Scope | Existing source to audit | First verification and likely extension |
| --- | --- | --- |
| Won conversion, customer, sale, project and first invoice draft | `crm-project-planning.tsx`, `convert_crm_won` in conversion migrations; assigned-work and quote suites | Trace latest applied overrides; preserve current accepted publication/private budget, exact-version authority, atomicity and retry behavior. Audit DEV-005/006/007: later payment drafts, actual Accounts routing and duplicate-safe customer creation/linking. |
| Task library, templates, parameters and go-live | `task-library.tsx`, `task-library-import.tsx`, `task-standard-import.ts`, `task-standard-reuse.ts`, `crm-project-planning.tsx` | DEV-008/009/015: reviewed QA/SOP sources, project-specific criteria and reviewed parameterized imports. No seeded standards, crews, rates or assignments. |
| Execution phases 0–5, workstreams, nodes, checklist, punch and sign-off | Existing project/task and assigned-work workflows; charter and communication guides | Audit actual transitions, evidence, independent approvals where already required, client/staff scope and immutable history. DEV-010/011/012: route/containment, device attributes and route-linked work. |
| Task scope and schedule | `project-schedule.ts`, `project-task-adjustments.tsx`, `task-plan-proposals.tsx`, `work-schedules.tsx` | DEV-013/014: parent-child/dependencies, explicit schedule baseline/revisions and approved rescheduling; retain started/completed work and recorded costs. |
| People, skills, capacity and physical tools | `project-resource-allocation.tsx`, `project-skill-suggestions.tsx`, tool availability/booking/request components | DEV-016/017/018: actual tool identities, cross-project allocation and actual availability. Retain existing certificate-backed skills; suggestions require manual confirmation. |
| Team calendar | `calendar-estimates.tsx`, `work-schedules.tsx`, existing task/calendar tests | Audit Month/Week/Day/Team board, project/team filters, actual linked Project/Ticket/Deal/Internal visits, conflict warnings and rescheduling; confirmed work must reconcile with activities. |
| Daily activity | `activity-log.tsx`, location/evidence/TADA components and work-activity functions | Audit planned-to-actual linkage, actual start/end-derived duration, partial/not-done/rescheduled outcomes, delay/blocker evidence and current approval scope. DEV-053 legacy timesheet reconciliation is a separately reviewed import, never duplicate labour credit. |
| Field-staff PWA | `pwa.tsx`, `public/portal/sw.js`, manifest and offline fallback | Current worker deliberately caches only the public fallback/icons; private pages/API/evidence are not cached. Installation support does not prove offline work capture/sync. Audit SRS web-PWA scope before any offline design; do not represent Phase 6 native mobile/offline sync as completed. |

## Bounded implementation order after the gate

1. **Won conversion audit and smallest supported gap.** Follow the latest function definitions, UI and isolated integration tests end to end. Map DEV-005/006/007 individually before choosing the first change. Keep existing invoice creation behavior; audit later scheduled payment drafts separately from Phase 3 posting/tax accounting. Actual customer conflicts require explicit review; never silently merge accounts or assign an Accounts person.
2. **Project standards and execution evidence.** Close reviewed template/criteria/import gaps, then route/device-linked work and actual checklist/punch/sign-off gaps. Freeze source versions and preserve manual content and prior evidence.
3. **Task and schedule changes.** Add missing hierarchy/dependency and baseline/revision capabilities with stale-source protection and explicit approval. Completed tasks/work/costs stay intact.
4. **Resource suggestions and bookings.** Use actual staff roles, valid skills, configured working calendars, confirmed assignments and actual physical tools. No assumed shifts, holidays, capacity, speed rankings or cost rates. If data is absent, show that limitation instead of inventing availability.
5. **Calendar and activity continuity.** Close missing view/link/conflict/reschedule behavior and prove confirmed assignments become the correct person's planned activity without duplicate time/cost. Existing TADA interim Deal rule stays Office / “Pre-sales / Survey” with manual Deal reference; first-class Deal attribution and auto-move remain future work.
6. **Field PWA verification.** Audit installation/update/reconnect, permissions, photo/file handling and device behavior. Preserve credential protection. Broader offline mutation/sync requires explicit conflict, account-switch, retention and duplicate-side-effect design before implementation.

Each increment must identify exact SRS rows, existing behavior and changed behavior, then use branch → PR → merge with meaningful isolated model/UI/DB tests, TypeScript/build where applicable, necessary new migrations applied once, and exact production verification when deployment is available. Update both requirement documents and the backlog with the released behavior and next resume point. Client acceptance remains client-owned.

## Boundaries

- This plan adds no application code, migrations, production fixtures, assignments, credentials or business records. It changes no catalogue counts or package statuses.
- Actual PMs, Accounts recipients, employees, customers, standards, tools, prices and operating calendars stay manual. Reasonable technical assumptions must be documented; do not invent business policy to fill missing configuration.
- Project phase 0–5 delivery is in Phase 2; the SRS's six build phases are not seven business modules.
- Existing project/training/charter work is reused and audited; accepted training attendance/learning and certificate evidence must not be duplicated.
- Phase 3 financial/supply-chain work, including held finance migrations 142–148 and draft PRs #223–#229, is not resumed here. User-approved credit/debit/refund and started-work rules remain recorded requirements for their proper increments.
- Google Calendar push is optional and external delivery is excluded in this session. No email/SMS/WhatsApp is sent.
- Automation learning-loop/KPI policy belongs to later SRS phases; no targets, salaries, automatic standard changes or performance rankings are invented.
