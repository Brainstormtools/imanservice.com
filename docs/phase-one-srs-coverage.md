# Phase 1 SRS implementation and release coverage

## Phase 1 final implementation merged; production held — 23 October 2026

[PR #243](https://github.com/Brainstormtools/imanservice.com/pull/243) merged at `69de53f7b1815797bf83725896cb52f4f5506cac`, tested head `4033846f2a1c32f3acd8b663f7d602cb3c5bb3bd`, exact tree `3d31ad3d330f2e65d242091f40accdd9937fbcef`; tested head → merge has zero changed files. Final implementation passed **9,016 checks / 174 suites**, TypeScript and production build. Original tested fingerprint including actual logo: `d0f419d49669eccc31c5f17b9a3986f8b43e605c5b014aabb12a46e4ceb886c7` (705 files). The release checkpoint aligns only the newly applied migration filename/test reference; final aligned fingerprint is `84d8bc36490477a86027136509d388598abc18d522c7f89e1cc5984f6c65d15e`. See [SRS coverage](phase-one-srs-coverage.md) for precise implementation boundaries.

Quote-scope/current-authority guard applied **once** as `20261022223747`, name `phase_one_quote_scope_versions`; original scaffold `20261022193927`, unchanged SQL SHA256 `124d573c89bedf2caf1bb1e932872140ecad862a923835d4f10f32c8221f2e1d`. Native checks confirmed current Deal/product authority guards, active-scope/catalog duplicate checks and unchanged empty search paths. This checkpoint aligns its filename/test reference without another SQL application. Earlier intake/routing/board/List/stage/product/file migrations remain applied once; do not reapply. Finance 142–148 remain held/unapplied. No actual business fixtures, assignments, external deliveries or client acceptance records were created.

**Phase 1 is not yet complete and live.** Vercel reports `failure` / `build-rate-limit` for the final implementation head; no exact-main production deployment is visible. Last verified production remains cumulative PR #240, main `2b7eb47dfe1de396d581a51a8058a50639e7b962`, deployment `dpl_DtZQL78piBP9dSNnxjRkHpTU86dj`. Product-scope, lead-file and final closure increments remain release-pending. No billing/protection changes, capped manual deployment retries or Preview promotion were performed.

Precise resume: verify the final checkpoint's saved regression/source results, then let ordinary Git production deployment resume when provider capacity permits; verify exact final main READY, production alias and portal/logo assets before marking the software released. Actual Meta app/Page/account authorization remains unavailable and **all 41 client-owned live/browser/export/device acceptance checks remain pending**. Catalogue remains **66 packages: 50 open (ten in progress, 40 not started), 16 development complete** until release verification. Do not claim training, later phases or the CRM complete; finish Phase 1 delivery before starting Phase 2.


This maps the uploaded SRS's **Phase 1 — Leads, deals & quotation** to current implementation and automated evidence. Completion of the software implementation is separate from actual business setup, external account activation and client-owned live acceptance. Final release status is recorded at the top of both requirement documents and `phase-one-progress.md`; do not infer production release from a prepared branch or a READY preview.

| Phase 1 behavior | Implementation | Automated evidence |
| --- | --- | --- |
| Manual enquiry fields, conditional phone/email, actual source/campaign and original message | `crm-sales.tsx`; `capture_crm_lead` | `crm-sales-ui.cjs`, `assigned-work.mjs` |
| CSV/Excel mapping, atomic imports, normalization, duplicate/repeat enquiry history and ownership preservation | Sales importer and guarded intake functions | `crm-sales-ui.cjs`, `assigned-work.mjs`, intake DB suites |
| Website enquiries, actual origin/form/UTM history, conflict review and bounded abuse protection | `api/contact.ts`, `api/proposal.ts`, `server/website-lead-intake.ts`, website intake migration/guide | `website-lead-intake.cjs`, `website-lead-intake-db.mjs` |
| Actual Admin-created/revoked API sources, server authentication, immutable intake receipts | API source UI/API intake implementation and guide | API intake DB/UI/server suites |
| Facebook/Instagram signed capture, bounded Graph retrieval, immutable receipts and actual correction/review | Meta API/review implementation and guide | Meta intake server/DB/UI suites; actual Meta account authorization remains unavailable |
| Optional explicit fixed/round-robin routing with actual eligible boards/staff and preserved existing ownership | Routing configuration/server decisions and guide | Routing DB/UI suites |
| Raw Lead New/Contacted/Ready/Junk/Duplicate List/Kanban and actual multi-product bulk assignment | Sales board UI/checked assignment RPCs | `crm-sales-ui.cjs`, `assigned-work.mjs` |
| First-response elapsed display | Actual creation → earliest logged Call/Meeting, calendar minutes; Notes/status changes do not establish response | `sales-list-model.cjs`, sales UI suites |
| Actual board creation with exact stage source, no copied business content/assignments | Board definition register/creation RPC and guide | `board-fields-db.mjs`, `board-fields-ui.cjs` |
| Per-board optional typed fields, actual values, immutable history/CSV, stale/current authority and number precision | Board field functions/UI and precision guard | Board field DB/UI and number suites |
| Board teams and configurable names/order/probabilities; fixed system Won/Lost | Existing checked board/stage/member configuration | `assigned-work.mjs`, board field suites |
| One shared Deal/customer/stage/value with separate product estimates/owners | Shared Deal/product-line model | `assigned-work.mjs`, `crm-sales-ui.cjs` |
| Own-board specialist editing with other product sections read-only; commercial ownership/status controls separate | Existing server permissions and scoped editor controls | Sales/quote UI suites; integrated closure DB suite |
| List sorting, column chooser, inline value/follow-up, owner/stage/source/created/tag/value/currency filters | Sales List model/UI | `sales-list-model.cjs`, `sales-list-ui.cjs` |
| Explicit reviewed bulk owner/stage/tag changes, atomic snapshots/history and safe exact retry; visible/selected CSV | Guarded sales List action RPC and UI | `sales-list-db.mjs`, `sales-list-ui.cjs` |
| Saved filter/List combinations | Existing own-user saved views plus bounded List option restoration | Sales/List DB/UI/model suites |
| Kanban drag/stage controls, counts, exact totals by currency, product badges/readiness and days in stage | Sales board cards/header; no mixed-currency sum | Sales UI/loading/model suites |
| No-next-step/due/inactivity filters and actual configured inactivity highlighting | Existing follow-up guards and exact configured elapsed interval | Sales model/UI/loading suites |
| Lead/Deal detail, contact, stage bar and actual activity timeline | Sales detail and checked stage/activity functions | Sales UI/assigned-work/closure DB suites |
| Actual private lead/Deal files with current authority, authenticated downloads, non-overwrite, retention, reasoned exclude/restore and history paging/CSV | Private lead-file register/Storage guards and guide | `lead-files-db.mjs`, `lead-files-ui.cjs` |
| Configurable stage-entry review tasks and actual in-portal reminder recipients | Stage action register/trigger, scoped task completion and guide | `stage-actions-db.mjs`, `stage-actions-ui.cjs` |
| Lost reason/explanation, optional actual re-engagement date and follow-up task handling | Existing Lost/re-engagement workflow | `assigned-work.mjs` and reminder suites |
| Pre-Won product additions/moves/drop/restore; preserve original BOQ, fields, flags and frozen versions; no automatic reassignment/copy | Product scope RPC, existing product editor with quote-version integrity guard and immutable status evidence | `product-scope-db.mjs`, `product-scope-ui.cjs`, `phase-one-closure-db.mjs` |
| Probability-weighted open product forecast, correct board stage/active scope and separate currencies | Exact integer-decimal calculation; no invented financial allocation | Sales List/closure model suites |
| Source/owner outcomes, recorded shared-stage → current Won and actual lost/dropped product reasons, filtered CSV | Read-only current visible-cohort report | `sales-closure-model.cjs`, `sales-insights-ui.cjs` |
| Product Catalog category/brand/model/unit/actual rate and Admin margin slabs, prefill | Existing catalog/BOQ editor and server validation | `crm-quotes-ui.cjs`, `crm-quote-cases.mjs` via assigned-work and integrated closure DB |
| Material/Labour/Inventory/TADA cost blocks, tax/charges, actual fuel/crew parameters | Existing guarded quote calculator/builder | Integrated quotation DB baseline covers all blocks, bank/contingency, WHT and invalid planner inputs |
| Default/line margins, manual final total and resulting cost/profit/margin | Existing server calculator and actual quote settings | Quotation baseline and integrated closure DB |
| Product sections and distinct solution alternatives | Existing quote option/publication model and grouped PDF | Quote DB/UI and integrated closure suites |
| Every publication creates an immutable revision; only actual client's accepted solution is eligible for conversion; other open options withdrawn | Existing publication/private budget/decision/conversion guards | Quotation baseline, planning suites and integrated closure DB |
| Sending validation: nonpositive quantity rejected; missing rates/matching labour/duplicate descriptions or catalogue items warn; acknowledgement required | Existing validation plus active-scope duplicate warning guard | Integrated closure DB suite |
| Actual company logo, sections, totals, withholding and terms in client-safe PDF | Existing sanitized publication plus actual same-origin logo rendering; no internal costs/vendors emitted | `crm-quotes-ui.cjs`, actual-binary `quotation-pdf-brand.cjs` |
| Failed/delayed reads, inactive/revoked access and no stale private export snapshots | Scoped component guards, post-lock Deal/product permission checks and sales load epoch/clear behavior | Sales loading, private file, field and stage UI/DB suites |

## Documented assumptions and boundaries

- First response is measured from actual timestamps to the first recorded Call/Meeting. No response target, working-hour calendar or SLA policy is inferred. Duration display is not learning/KPI credit.
- Stage tasks are actual Admin-configured fixed-recipient tasks with an explicit calendar-day due interval. New actions are inactive and blank; no reviewers, memberships or assignments are seeded. Revoked required recipient authority rejects entry until actual configuration is corrected/disabled.
- Product changes preserve history and require actual reasons/current snapshots. Current published quotations are explicitly withdrawn before changing scope; accepted/converted/Won scope stays in its separate approved change workflow. No issued invoices, recorded work or project costs are edited by Phase 1 changes.
- Sales report conversion means observed shared-Deal stages → current Won in the **current active-product cohort**, using current stages and actual logged transitions. Skipped stages and historical board membership are not reconstructed. Counts and estimates are not posted revenue, financial margin allocation or performance targets. Later finance reports retain their own manual attribution rules.
- Zero quantity is rejected rather than merely warned; duplicate warnings require explicit review and may be acknowledged for a legitimate repeated item. Retained dropped-product BOQ rows do not count as active duplicates.
- Calendar view is explicitly recommended in the SRS, not a mandatory Phase 1 closure condition. The broader condition/action builder is recommended for Phase 2. Project execution/configurator/team calendar/PWA, supply chain/finance, field service, contract renewal lifecycle and HR/KPI packages stay in their later SRS build phases. Existing later-phase code does not establish their completion. Contract-specific renewal opportunity automation is assessed with the support/contract lifecycle, not invented from absent business contracts here.
- External email/SMS/WhatsApp delivery remains excluded by the user. Meta software is implemented but actual app/Page/account authorization is still required before that channel is operational. No provider credentials or actual lead data are invented.

## Verification and ownership

The existing in-portal reminder schedule is active (`iman-portal-web-push`, every 15 minutes); read-only metadata confirms required worker URL/secret/push-key bindings exist. No secret values were retrieved or printed and no production notifications or test fixtures were generated to exercise delivery. Actual signed-in/browser/export/device behavior and delivery acceptance remain client-owned.

All new business setup remains manual. Seven actual hosted boards were preserved. Native metadata during release verified zero new stage rules/tasks, List action receipts, product-scope changes or customer file objects registered by this development work. Automated positive/negative business fixtures are isolated local databases/browser models only.

**All 41 client-owned acceptance items remain pending. The CRM and its later phases are not declared complete.** A final verified production release may establish Phase 1 software-development completion while explicitly leaving actual Meta activation and client acceptance open.
