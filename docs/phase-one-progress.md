# Phase 1 — leads, deals and quotations

The client has requested sequential development by the six **build phases** in the uploaded 41-page SRS. Seven modules are not seven build phases. Complete and release Phase 1 before starting further later-phase development. Client-owned live/browser/export/device acceptance is tracked separately; none of the 41 acceptance items is passed by automated tests.

The client authorizes reasonable documented assumptions instead of waiting for unanswered business questions. Previously confirmed decisions still take precedence. Configurable defaults are preferred. Actual people, assignments, credentials, contacts, transactions and business records are not invented. External email/SMS/WhatsApp delivery remains excluded. This instruction does not make a missing external-provider authorization available.

## Current Phase 1 development status: in progress

| SRS Phase 1 requirement | Repository status / next action |
| --- | --- |
| Manual lead entry and mapped CSV/Excel import | Existing implementation; included in regression verification. |
| Normalization, phone/email deduplication and repeat enquiry history | Existing manual/import path; website path being reconciled and tested. Preserve actual ownership and original acquisition. Conflicting contacts/customer matches require private review. |
| Website enquiry capture | Development implementation released through PR #234; exact production deployment/domain/assets verified. Actual live business acceptance remains client-owned. |
| API-key lead capture | DEV-003 implementation released: actual Administrator source creation/revocation/history, guarded server intake and immutable receipts. No source/key seeded. See [API guide](lead-api-intake-guide.md). |
| Facebook/Instagram lead-ad intake | DEV-002 in progress: signed capture, bounded Graph retrieval, immutable receipts and reasoned private review deployed. Actual Meta credentials/authorization remain unconfigured; no operational provider connection claimed. See [Meta guide](meta-lead-intake-guide.md). |
| Optional administrator-configured automatic routing | DEV-004 implementation released: actual explicit rules/boards/fixed or ordered round-robin owners, eligibility checks and immutable configuration/outcomes. Zero rules seeded; no existing lead reassigned. See [routing guide](lead-routing-guide.md). |
| Raw Lead Board statuses, List/Kanban, filters, saved views and bulk assignment | Existing implementation; verify detailed SRS behavior before phase closure. |
| Product boards, memberships, stage rules, activities, multi-product deals and Won/Lost | DEV-059 actual board creation/per-board fields released through PR #236; product changes and other detailed SRS audit findings remain open. |
| Product catalogue, combined quotation/BOQ, document versions and roles | Existing core implementation; detailed Phase 1 requirement-to-test audit remains open. Later project execution/finance adoption work is not substituted for this audit. |

This is the initial Phase 1 map, not a claim that the four intake packages cover every sentence of the SRS. Check the detailed module 1/2 and quotation requirements before declaring Phase 1 complete. Record newly discovered development gaps explicitly.

## Website increment assumptions and boundaries

Website forms retain their existing validation and actual raw phone text. Only unambiguous international numbers become structured phone identities; an ambiguous local phone is not guessed. Email is normalized, genuine repeat enquiries retain their own source/form/UTM/message history, identical retries are idempotent, and no public contact lookup/lead ID is returned. Receipt and origin-limit tables remain private with RLS/no browser writes.

Technical abuse default: 20 new enquiries per server-derived origin fingerprint in ten minutes, configurable through server-only `WEBSITE_INTAKE_WINDOW_LIMIT` (1–100). Exact confirmed retries do not consume another budget. Raw IPs and service keys are not stored in the limiter or returned to the browser. The limiter's inactive buckets expire after a day; business enquiry receipts are retained independently.

New unassigned website enquiries notify existing active Admin/Sales Manager accounts with actual current sales permissions and enabled portal reminders. Repeat enquiries notify the actual existing eligible owner. These notifications do not create assignments. No external delivery is enabled; optional legacy consultation-webhook behavior is preserved, and no webhook binding was present during inspection.

The earlier hosted-only `capture_website_crm_lead` function and private receipt table were inspected read-only. Their objects existed, but no website-intake migration history entry was present. The new CLI-generated reconciliation migration records the supported schema, preserves existing receipts and adds the bounded v2 endpoint. Existing migration 141 and all prior migrations must not be reapplied. Held finance migrations 142–148/PRs #223–229 stay separate and unapplied.

## Closure rule

Say **“Phase 1 development is complete and live on the portal”** only after its remaining SRS requirements are implemented, tested, merged through PRs, deployed to the intended production project, and the exact release is verified. Provider setup that remains unavailable must be disclosed; a READY build alone does not verify an operational Meta connection. Client acceptance stays separate.

## Historical website release checkpoint

PR #230 is merged at `40ee65207a834a2fffb833b91360e6770a2fcf16`; 8,364 automated checks/149 suites and TypeScript/build pass. Migration version `20261022005821` (`phase_one_website_intake`) is applied once; do not reapply the source scaffold. Exact preview `dpl_E5vgWkPLyBjXTuGiar36QQhCmqh5` is READY and its portal/form guards were verified. The manual deployment API and Git-based production status both report the provider daily build/deployment limit. Production remains the previous release; Phase 1 is not complete. Continue remaining Phase 1 development while waiting for provider capacity.

The API increment aligns the tracked website migration filename to its actual applied version (`20261022005821`) with identical SQL bytes; it does not reapply that migration. No actual API sources/keys are seeded or created as production fixtures.

## Historical Meta increment resume checkpoint

API intake is preserved in draft PR #232 at `ac8c2648b9fad1375fe25050d24cf2e7e5e2bbcb`. Meta intake passed 8,527 checks/155 suites on a separate stacked branch, with missing/conflicting contacts retained for actual Administrator correction rather than guessed. Both new migrations remain unapplied; Meta activation and production release remain unavailable. Continue explicit Administrator routing and the detailed SRS audit after saving this tested increment. Phase 1 and client acceptance remain open.

## Detailed Phase 1 audit findings to carry forward

The original 58-package catalogue is not a fresh complete SRS audit. Its current 50-open count does not imply only the four intake packages remain in Phase 1. The following findings stay open after the Meta increment:

| SRS behavior | Current evidence / remaining work |
| --- | --- |
| Create additional product boards and per-board custom fields | `configure_sales_board` in `supabase/015_crm_sales.sql` updates an existing exact-version board; `crm-sales.tsx` renders existing boards. DEV-059 actual Admin creation/definition register and private board-scoped value receipts are now implemented/tested/released through PR #236. No seeded business content. |
| Spreadsheet-style List: sorting, column chooser, inline changes, bulk owner/stage/tag/export and date/tag/value filters | The current product List in `src/portal/crm-sales.tsx` is a fixed five-column table. Existing raw bulk product assignment is not evidence of all listed List actions. Add and test the missing actions with the same current role/version/stage safeguards. |
| Raw Lead first-response elapsed timer | The sales lead records/history currently expose creation time; ticket-specific first-response tables belong to a later module and do not implement a Raw Lead timer. Define a documented measured-event default rather than invent a response target or business-hour policy. |
| Configurable stage-entry actions | Current stage configuration handles names/order/probabilities and fixed system stages. A general stage-entry action/review-task configuration was not found. Require actual Admin configuration and actual eligible recipients; no invented manager assignment. |
| Lead-detail files, product changes, weighted forecast and calendar recommendation | Trace these against the detailed SRS before closing the phase. Project-linked file features do not prove lead-file support. Existing estimated pipeline totals do not prove probability-weighted forecast. Distinguish required behavior from the SRS's explicitly recommended calendar view. |
| Quotation warnings, product sections, alternatives, accepted versions and client-safe PDF | Existing quotation/BOQ implementation needs its own requirement-to-code/test mapping. Later finance/change-order drafts do not close these Phase 1 checks. External email/WhatsApp sending remains expressly excluded by the user. |

Resume order: explicit actual Administrator routing, then these sales/quotation gaps in bounded tested increments. Reconcile newly scoped package counts explicitly when breaking these findings into development packages. None is silently marked complete by intake regression or a provider preview.

## Historical routing increment resume checkpoint

Meta intake is saved in draft PR #233 at `071f8053cb4482385ecd6d0df7b0dfda16169b1e`; routing is a separate tested increment (8,605 checks/157 suites). API/Meta PRs are now merged and their new migrations applied once at database versions `20261022103801`/`20261022103855`; routing remains unapplied pending merge and production remains the earlier verified release. New read-only checks found both exact API/Meta automatic previews READY; normal Git-based production release is being verified after final regression and merge. Next actual board creation/custom fields and advanced List actions, then the remaining detailed quotation audit. Do not declare Phase 1 or client acceptance complete.

## Latest production checkpoint — supersedes historical release holds above

PR #234 merged at `8c56b52297a6533111440036e733262468a47400`; exact production `dpl_956wrMDekweeTMWWb3nGMS6H7SVq` READY, www alias and actual portal assets verified. Website/API/routing implementation is deployed; Meta code is deployed but actual provider activation is unavailable. 8,605 checks/157 suites, TypeScript/build passed before the current filename-only migration alignment; final aligned-source verification is recorded in both requirement documents.

API/Meta/routing migrations applied once at actual database versions `20261022103801`, `20261022103855`, `20261022104422`. Source migration filenames are aligned to those versions with identical SQL bytes; never reapply them or website `20261022005821`. No actual sources/rules/business fixtures were inserted. Finance migrations 142–148 remain held. Catalogue 47 open (seven in progress, 40 not started), 11 development complete; this is not an exhaustive Phase 1 gap count. Resume actual board creation/custom fields, then advanced List actions and detailed sales/quotation audit. Phase 1 and all 41 client-owned acceptance items remain open.

Final filename-aligned source: 8,605 checks/157 suites passed again; all 665 source/test/config hashes and saved results verified unchanged at `706b666db75d992c19c2f0f82dc271b8a64585588d542d65ef9eb0b8a0534417`. All renamed SQL bytes are identical; no SQL reapplied and no application change. The next increment is actual board creation/custom fields, then advanced List behavior.

## Current board/field increment

DEV-059 is the newly recorded SRS gap package, prepared on a branch from the verified PR #235 source. Admin manually enters actual board metadata, selects an exact existing stage snapshot and confirms; no members/fields/values/templates copied. Optional fields are actual typed definitions; values are board-scoped product-line receipts with exact schema/current authority and immutable history. Shared Deal access does not expose another board's values. New migration scaffold `20261022105756` remains unapplied pending full regression and merge. See [board/field guide](product-board-fields-guide.md).

The catalogue explicitly expands from the historical 58 to 59 packages: 48 open (eight in progress/40 not started), 11 complete while DEV-059 is release-pending. This does not close other Phase 1 gaps or client acceptance. Next advanced List actions and the remaining audit after this bounded release.

Board/field final validation: 8,689 checks/159 suites, TypeScript/build passed; all 670 source/test/config hashes and saved results reverified unchanged at `6ca858fade47347464785dc23c6598ba8e676990072a0a64b3bac235a6a60410`. New migration remains unapplied until the tested PR merges.

## Latest board/field production checkpoint

PR #236 merged at `8677f76765c57a7dff30a5f1f2a90316070f15df`; production `dpl_HCiQfUgmVtYVXi7grAvwWZkSboji` READY, alias/portal/assets verified. DEV-059 is development-complete: exact-stage actual board creation, optional typed definitions and board-scoped actual product-line receipts, private immutable history/CSV, current-authority/stale-value guards. 8,689 checks/159 suites and TypeScript/build passed; final filename-aligned source validation is recorded in both requirement documents.

New migration applied once at database version `20261022111906`, original CLI scaffold `20261022105756`, source filename now aligned with identical SQL bytes. No SQL rerun; prior migrations and held finance 142–148 remain untouched. Seven existing boards remain; zero new board/field/value records inserted. Catalogue explicitly 59 packages: 47 open (seven in progress/40 not started), 12 complete. Actual Meta activation remains unavailable, Phase 1 incomplete, all 41 client acceptance items pending. Next advanced List features, then remaining lead timer/stage actions and sales/quotation audit.

Final board/field aligned source passed 8,689 checks/159 suites again; all 670 source/test/config hashes and saved results verified unchanged at `f9c49080a6b6514e8870b0a06c30e35fdc807e3baf87d6f10b7227c4d68f533d`. One SQL filename and local test reference aligned; SQL bytes/application sources unchanged, no SQL reapplied. Resume advanced List features.

Board-field precision follow-up: browser/server reject unsafe numeric conversions instead of silently changing actual digits. Text preserves exact long identifiers. New migration scaffold `20261022112524` is prepared; existing applied `20261022111906` is filename-aligned only, not rerun. The follow-up is undergoing complete regression before PR/merge/release; Phase 1 and client acceptance remain open.

Exact-number follow-up validation passed 8,701 checks/160 suites, TypeScript/build; all 673 source/test/config hashes and saved results verified unchanged at `fbb5e8fe052f899497fcd68ba297aff4c4120eac86b9533d80e8a6e03284d2eb`. New precision migration `20261022112524` is still unapplied pending tested PR merge.
