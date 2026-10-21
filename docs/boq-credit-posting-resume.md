# BOQ credit posting: interrupted development checkpoint

21 October 2026. Repository: Brainstormtools/imanservice.com, /portal only. This is an unreleased development checkpoint, not a completion or acceptance claim.

## Verified release remains the source of truth

Main: `48ada6512ea76a760908c099312d8686ea162f48` (PR #221), tree `8971607afba2f89b3fd483f26fc6e0c607e6aa8f`.
Last verified production: `dpl_Hi6rFu7DdybrfrrfumKsd5jg61jC`, https://www.imanservice.com/portal.
Last verified application source: 8,325 checks / 147 suites, fingerprint `3cfacdc1c1fecc769fddd9b705c399a6a75adf11f24eeb52f079ea655fde205b`.
Supabase migrations through 141 were applied. Migration 142 has NOT been applied. No posting increment merge or production deployment was performed.

Approved financial preparations remain unissued/unposted in the verified release. DEV-028 remains in progress; 50 open packages (six in progress, 44 not started), eight development complete, all 41 client acceptance items pending.

## Workspace and pending local work

Checkout: `/workspace/work/training-confirmation`.
Local branch: `codex/boq-credit-posting`, based on the verified release's local mirror.
The local branch contains uncommitted implementation and test edits; this checkpoint PR contains documentation ONLY and does not preserve their file bytes remotely. Inspect actual files after recovery before assuming any draft implementation survived.

New local files:
- `supabase/142_boq_credit_posting.sql`
- `src/portal/boq-credit-posting.tsx`
- `tests/helpers/boq-credit-posting-cases.mjs`

Edited local files:
- `src/portal/boq-adjustment-approval.tsx`
- `src/portal/business.tsx`
- `src/portal/billing-enhancements.tsx`
- `src/portal/finance-workspace.tsx`
- `tests/assigned-work.mjs`

Keep `node_modules` and `work/` untracked. Do not touch the separate CRM repository or unrelated website-intake worktree.

## Intended bounded increment

Implement approved CREDIT-note posting, original unpaid-balance reduction, separate excess same-company PKR client-credit liability, and automatic default settlement of later issued PKR invoices. Debit-note issuance, preparations containing manual WHT adjustments, requested cash refunds/Owner-Director approval, no-payment cancellation/rebill, partial/multi-invoice reconciliation and started-work execution remain separately bounded.

Draft design under review:
- Exact immutable Manager-Approved preparation/review and unchanged accepted economic source required. Current Accounts posting authority checked server-side; preserve actual issuer/server time and original line tax rates.
- Company row lock serializes credit creation and spending; original project/invoice locks preserve source freshness.
- Full original credit note remains separate from the issued invoice. Carry only the amount above actual unpaid balance as client credit. Pending original payment claims must be resolved first.
- Remaining original invoice-line capacity and gross credit capacity prevent reuse/over-crediting. Existing unmapped legacy credits or settlement applications require separate reconciliation rather than guessed attribution.
- Immutable posting receipts include preparation/review, current invoice, verified payment proof snapshots, prior issued-credit evidence and the exact balance/client-credit split.
- Default later same-company PKR invoice settlement uses existing available credit, capped by actual remaining payable amount. Draft, foreign-currency and other-company invoices consume no credit.
- Settlement applications use CCA numbers/provenance, not a second commercial/tax credit note; no cash receipt or tax reversal is fabricated. Legacy invoice balance-credit integration must clearly distinguish credit notes from settlement applications in UI/export labels.
- Separate available client-credit liability is deducted once from Finance net trade position. Invoice statement/display/CSV balances must clamp at zero; excess appears in the separate ledger.
- Posted source invoices/lines, credit documents and applications remain immutable. Verified payment reversals/alterations that would invalidate carried/spent origin credit require separate reconciliation, not silent negative liabilities.
- Accounts/explicitly designated Managers see private evidence. Own-company clients receive only necessary sanitized issued-note/application/balance information; no private review/designation/quote-budget data.
- Actual designations, mappings, client-visible reasons, business records and assignments remain manual. No production fixtures.

The draft must be reviewed and tested before migration or deployment. Stable credit-lot chronology is internal provenance for fungible same-company PKR credit; do not invent expiry, priority, refund or tax policies.

## Validation status: NOT complete

An initial TypeScript check passed before the latest small business-display changes. The first targeted local database run exercised posting and ledger assertions, then failed a test comparison because a Postgres numeric scalar was `'1140.00'` rather than JavaScript number `1140`. The local test was changed to explicit float casts for those scalar comparisons and expanded with dashboard, WHT/debit-blocking and capacity scenarios.

A second targeted run was started:
`node tests/assigned-work.mjs > work/boq-credit-targeted-2.log 2>&1`.
Its outcome could not be read after the workspace disconnected. Do NOT claim it passed.

Other retained paths, if the workspace survives:
- `work/boq-credit-targeted.log` (first targeted run/failure)
- `work/boq-credit-targeted-2.log` (second run, outcome unknown)
- `work/boq-credit-typescript.log` (earlier check only)
- `work/boq-adjustment-resume.json` (last released checkpoint)

New posting/ledger UI tests and complete regression/build verification remain to be completed. No migration 142 application, application PR merge or production posting release is authorized to proceed without that validation.

## Resume

First read docs/crm-acceptance.md, docs/workbook-requirements.md, docs/development-backlog.md, docs/training-participants-guide.md and docs/boq-financial-adjustment-guide.md. Current repository state and connected tools remain authoritative.

1. Restore execution access, inspect git status/diff and the pending files; retain unrelated work.
2. Read the second targeted-run result before retrying; fix real failures without discarding evidence.
3. Review credit/accounting invariants, concurrency, exact retries, payment/credit reversal guards, original tax/capacity, client privacy and automatic future settlement. Add meaningful posting/ledger/billing statement/UI tests, including no negative invoice balance and no duplicate tax credit/cash.
4. Run TypeScript/build and the appropriate full regression. Canonical tracked-source manifests must exclude generated/untracked test bundles.
5. Use branch + PR, exact tested source, new migration preflight and connected database migration tools once. Never reapply existing migrations or reserved 113.
6. Verify live auth/RLS/ACL/advisors without production fixtures, merge, verify exact READY production and actual served assets, then update both requirement documents/backlog with release and precise resume point through PR.

## Infrastructure interruption

The execution transport disconnected; runtime status reported observed phase running but connectivity offline, with current observations. A bounded recovery probe also stalled and was terminated. Connected environment tools exposed status/diagnostic inspection but no restart action; no retained diagnostic records were available. GitHub remained reachable and main was rechecked unchanged at the verified SHA above.

This is an execution-workspace blocker, not a missing business decision or an automatic approval rejection. Do not retry/bypass the previously blocked Supabase CLI telemetry action. Production and the separate repository must remain untouched while validation cannot run.
