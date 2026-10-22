# Phase 1 — leads, deals and quotations

The client has requested sequential development by the six **build phases** in the uploaded 41-page SRS. Seven modules are not seven build phases. Complete and release Phase 1 before starting further later-phase development. Client-owned live/browser/export/device acceptance is tracked separately; none of the 41 acceptance items is passed by automated tests.

The client authorizes reasonable documented assumptions instead of waiting for unanswered business questions. Previously confirmed decisions still take precedence. Configurable defaults are preferred. Actual people, assignments, credentials, contacts, transactions and business records are not invented. External email/SMS/WhatsApp delivery remains excluded. This instruction does not make a missing external-provider authorization available.

## Current Phase 1 development status: in progress

| SRS Phase 1 requirement | Repository status / next action |
| --- | --- |
| Manual lead entry and mapped CSV/Excel import | Existing implementation; included in regression verification. |
| Normalization, phone/email deduplication and repeat enquiry history | Existing manual/import path; website path being reconciled and tested. Preserve actual ownership and original acquisition. Conflicting contacts/customer matches require private review. |
| Website enquiry capture | Contact/proposal handlers and browser submission identity restored from an earlier unreleased branch, reconciled through a new migration. New durable abuse limiting and eligible in-app notification. PR #230 merged; migration applied once. Exact preview verified. Production build is blocked by the Vercel daily limit, so this is not live-complete. |
| API-key lead capture | DEV-003 source creation/revocation/history, guarded server-to-server capture and immutable receipts passed 8,453 checks across 152 suites, TypeScript and production build. Saved results were verified against unchanged source. See [API intake guide](lead-api-intake-guide.md). Not deployed; new API migration remains unapplied. |
| Facebook/Instagram lead-ad intake | DEV-002 in progress: signed capture, bounded Graph retrieval, immutable receipts and reasoned private contact review passed 8,527 checks/155 suites, TypeScript and production build; source/saved results reverified unchanged. See [Meta setup/review guide](meta-lead-intake-guide.md). No Meta credential bindings were found in the target Vercel project; actual provider activation requires an authorized account/app connection. |
| Optional administrator-configured automatic routing | DEV-004 in progress: actual Administrator rules, fixed or explicit ordered round-robin owners, immutable configuration/outcomes and private CSV passed 8,605 checks/157 suites, TypeScript and build; saved results/source reverified unchanged. See [routing guide](lead-routing-guide.md). No rules or assignments seeded; migration unapplied, release pending. |
| Raw Lead Board statuses, List/Kanban, filters, saved views and bulk assignment | Existing implementation; verify detailed SRS behavior before phase closure. |
| Product boards, memberships, stage rules, activities, multi-product deals and Won/Lost | Existing core implementation; detailed SRS audit remains open, including board creation/custom fields and product changes. |
| Product catalogue, combined quotation/BOQ, document versions and roles | Existing core implementation; detailed Phase 1 requirement-to-test audit remains open. Later project execution/finance adoption work is not substituted for this audit. |

This is the initial Phase 1 map, not a claim that the four intake packages cover every sentence of the SRS. Check the detailed module 1/2 and quotation requirements before declaring Phase 1 complete. Record newly discovered development gaps explicitly.

## Website increment assumptions and boundaries

Website forms retain their existing validation and actual raw phone text. Only unambiguous international numbers become structured phone identities; an ambiguous local phone is not guessed. Email is normalized, genuine repeat enquiries retain their own source/form/UTM/message history, identical retries are idempotent, and no public contact lookup/lead ID is returned. Receipt and origin-limit tables remain private with RLS/no browser writes.

Technical abuse default: 20 new enquiries per server-derived origin fingerprint in ten minutes, configurable through server-only `WEBSITE_INTAKE_WINDOW_LIMIT` (1–100). Exact confirmed retries do not consume another budget. Raw IPs and service keys are not stored in the limiter or returned to the browser. The limiter's inactive buckets expire after a day; business enquiry receipts are retained independently.

New unassigned website enquiries notify existing active Admin/Sales Manager accounts with actual current sales permissions and enabled portal reminders. Repeat enquiries notify the actual existing eligible owner. These notifications do not create assignments. No external delivery is enabled; optional legacy consultation-webhook behavior is preserved, and no webhook binding was present during inspection.

The earlier hosted-only `capture_website_crm_lead` function and private receipt table were inspected read-only. Their objects existed, but no website-intake migration history entry was present. The new CLI-generated reconciliation migration records the supported schema, preserves existing receipts and adds the bounded v2 endpoint. Existing migration 141 and all prior migrations must not be reapplied. Held finance migrations 142–148/PRs #223–229 stay separate and unapplied.

## Closure rule

Say **“Phase 1 development is complete and live on the portal”** only after its remaining SRS requirements are implemented, tested, merged through PRs, deployed to the intended production project, and the exact release is verified. Provider setup that remains unavailable must be disclosed; a READY build alone does not verify an operational Meta connection. Client acceptance stays separate.

## Current release checkpoint

PR #230 is merged at `40ee65207a834a2fffb833b91360e6770a2fcf16`; 8,364 automated checks/149 suites and TypeScript/build pass. Migration version `20261022005821` (`phase_one_website_intake`) is applied once; do not reapply the source scaffold. Exact preview `dpl_E5vgWkPLyBjXTuGiar36QQhCmqh5` is READY and its portal/form guards were verified. The manual deployment API and Git-based production status both report the provider daily build/deployment limit. Production remains the previous release; Phase 1 is not complete. Continue remaining Phase 1 development while waiting for provider capacity.

The API increment aligns the tracked website migration filename to its actual applied version (`20261022005821`) with identical SQL bytes; it does not reapply that migration. No actual API sources/keys are seeded or created as production fixtures.

## Meta increment resume checkpoint

API intake is preserved in draft PR #232 at `ac8c2648b9fad1375fe25050d24cf2e7e5e2bbcb`. Meta intake passed 8,527 checks/155 suites on a separate stacked branch, with missing/conflicting contacts retained for actual Administrator correction rather than guessed. Both new migrations remain unapplied; Meta activation and production release remain unavailable. Continue explicit Administrator routing and the detailed SRS audit after saving this tested increment. Phase 1 and client acceptance remain open.

## Detailed Phase 1 audit findings to carry forward

The original 58-package catalogue is not a fresh complete SRS audit. Its current 50-open count does not imply only the four intake packages remain in Phase 1. The following findings stay open after the Meta increment:

| SRS behavior | Current evidence / remaining work |
| --- | --- |
| Create additional product boards and per-board custom fields | `configure_sales_board` in `supabase/015_crm_sales.sql` updates an existing exact-version board; `crm-sales.tsx` renders existing boards. No board-creation or per-board custom-field path was found in the sales schema/UI. Implement actual Admin-entered definitions without seeded business content. |
| Spreadsheet-style List: sorting, column chooser, inline changes, bulk owner/stage/tag/export and date/tag/value filters | The current product List in `src/portal/crm-sales.tsx` is a fixed five-column table. Existing raw bulk product assignment is not evidence of all listed List actions. Add and test the missing actions with the same current role/version/stage safeguards. |
| Raw Lead first-response elapsed timer | The sales lead records/history currently expose creation time; ticket-specific first-response tables belong to a later module and do not implement a Raw Lead timer. Define a documented measured-event default rather than invent a response target or business-hour policy. |
| Configurable stage-entry actions | Current stage configuration handles names/order/probabilities and fixed system stages. A general stage-entry action/review-task configuration was not found. Require actual Admin configuration and actual eligible recipients; no invented manager assignment. |
| Lead-detail files, product changes, weighted forecast and calendar recommendation | Trace these against the detailed SRS before closing the phase. Project-linked file features do not prove lead-file support. Existing estimated pipeline totals do not prove probability-weighted forecast. Distinguish required behavior from the SRS's explicitly recommended calendar view. |
| Quotation warnings, product sections, alternatives, accepted versions and client-safe PDF | Existing quotation/BOQ implementation needs its own requirement-to-code/test mapping. Later finance/change-order drafts do not close these Phase 1 checks. External email/WhatsApp sending remains expressly excluded by the user. |

Resume order: explicit actual Administrator routing, then these sales/quotation gaps in bounded tested increments. Reconcile newly scoped package counts explicitly when breaking these findings into development packages. None is silently marked complete by intake regression or a provider preview.

## Routing increment resume checkpoint

Meta intake is saved in draft PR #233 at `071f8053cb4482385ecd6d0df7b0dfda16169b1e`; routing is a separate tested increment (8,605 checks/157 suites). API/Meta PRs are now merged and their new migrations applied once at database versions `20261022103801`/`20261022103855`; routing remains unapplied pending merge and production remains the earlier verified release. New read-only checks found both exact API/Meta automatic previews READY; normal Git-based production release is being verified after final regression and merge. Next actual board creation/custom fields and advanced List actions, then the remaining detailed quotation audit. Do not declare Phase 1 or client acceptance complete.
