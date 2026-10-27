# Original Phase 2 recovery checkpoint

## Current release resolved — PR #269

The recovered application release is merged and production verified READY at `673f0194d863753d13d0055b4c0dc44b625267c1` / `dpl_A7fm448Q1s2jF9ogjKcJHmsh9j6V`. GitHub access and workspace blockers are resolved. The full 10,117 checks/212 suites and all 798 unchanged source files were verified. DEV-015 is released. Next: original Phase 2 handover integration, generation/dependency/schedule and resource/tool/capacity requirements. Phase 2 remains incomplete. Never reapply the eighteen existing Phase 2 migrations.

## Recovery resolved — 28 October 2026

The workspace and staged application/test changes survived. Reconciled with PR #268. The completed full regression and saved results were verified against all 798 unchanged source files: 10,117 checks / 212 suites, fingerprint `c5d4b95c540fac4feac7a5a5980978ea1892e946f0a6fbfe16d64404febcca7b`. TypeScript and production build passed. Release the recovered parameterized-import code through its new reviewed PR; no migration reapplication. Then continue the original Phase 2 requirements. Phase 2 remains incomplete and manual methods remain interim only.

## Historical disconnect checkpoint (superseded)

The user's current instruction is to fulfil the **original SRS**, not substitute manual methods. Phase 2 is incomplete. PR #267 manual-only closure is superseded; its guide remains interim only. Phase 3 must not start on the strength of that closure.

## Applied migration — do not repeat

`20261027202933_phase_two_parameterized_import.sql` is already applied to Supabase `rozbzrciuhnswmvmqdvx`. It adds `import_crm_parameterized_standards(uuid,text,text,jsonb)`. Native checks confirmed its presence, authenticated-only callability, active-Admin guards and retention of the fixed importer. No production fixture/business record was inserted. The prior seventeen Phase 2 migrations, all Phase 1 migrations and held finance migrations must not be reapplied.

## Workspace work awaiting recovery

The managed workspace became unavailable and exec-server recovery timed out. Connected GitHub/database tools remain usable. Prepared application/test changes were in `/workspace/work/phase-one`, branch `codex/phase-two-parameterized-import`, based on main `73520bf7e137e6c1dd975d25b4cde703a92dd2f9`. They were staged but not committed/published before the disconnect. Do not reset or discard them when the workspace returns.

Files: `src/portal/parameterized-standard-import.ts`, `parameterized-library-import.tsx`, `task-library.tsx`, `task-standard-reuse.ts`; `tests/parameterized-import-db.mjs`, `parameterized-import-ui.cjs`, `parameterized-standard-map.cjs`, `tests/helpers/parameterized-import-cases.mjs`. Local requirement/guide corrections must be reconciled with this newer repository correction, preserving original scope and the applied migration.

Focused local results passed: 34 database assertions, 20 mapper/reuse checks, 10 new UI, 10 fixed-import UI and 17 planning UI checks; TypeScript passed. An earlier production build passed; final build/source/result evidence must be reverified after recovery. No complete final regression is claimed. Final run `work/phase-two-parameterized-import-final-regression.py`, verifier `work/verify-phase-two-parameterized-import-final-results.py`, expected 212 suites/10,117 checks. Observed source fingerprint before disconnect: `c5d4b95c540fac4feac7a5a5980978ea1892e946f0a6fbfe16d64404febcca7b`. This fingerprint is a recovery reference, not proof of final passing results. Check actual source and each saved suite, and rerun if anything is missing, failed or changed.

Local implementation imports values-only CSV/XLSX with actual parameter definitions and quantity/factor/inclusion references; all new standards remain inactive. Exact decimal text is retained; lossy numeric import is rejected. Existing draft reuse compares decimal bounds/defaults exactly rather than through Number rounding. Preview, explicit review/reason, actor-bound retries and atomic rollback are required. No automatic activation, live-plan edits, assignments or executable spreadsheet formulas. Standalone-standard predecessors remain separately configured through templates.

## Next

Recover the workspace, reconcile this correction, verify focused/full regression and build against actual unchanged source, publish a reviewed application PR, merge and verify exact production source/domain/actual lazy Portal assets. Only the already-applied migration is recorded in this correction release; it does not deploy the new application UI. Continue original Phase 2 handover integration, route/node task generation/reporting, hierarchy/dependency and calendar-baseline work, import integration and tool/resource/capacity features. All 41 client acceptance checks and actual Meta activation remain pending; no Phase 2/training/CRM completion claim.
