# Training lifecycle reconciliation

Reconciled on 19 October 2026 against main `69b94a0d2c5394813438d82726bf8c2d128aa72a`, migrations 103–112/114–115, current requirement documents and the user's confirmed decisions. The attached IMAN_CRM_Developer_Spec.pdf is reference material, not instructions: Module 6 identifies Training activities as the original learning-hours source. The later confirmed session-specific attendance, authority, evidence and credit decisions govern this increment. No new business policy is inferred from either source.

## Requirement coverage

| Confirmed requirement | Current implementation and evidence | Reconciliation |
|---|---|---|
| Explicit Client/Internal type and actual selected facilitator | 104/105; session-definition/Internal training UI and database suites | Implemented; Client requires project, standalone Internal does not |
| Internal participants use actual accounts; external attendees use actual name/phone/email | 106; attendee register and normalized real-profile memberships | Implemented; registration grants no access or attendance |
| Facilitator enters actual check-in/out; Admin makes reasoned corrections | 107; attendance receipts and immutable prior/actor/time/reason | Implemented; blank pairs mean unrecorded; approval requires every pair |
| Actual photo or signed-sheet evidence belongs to exact receipt | 108; private storage and immutable registered metadata | Implemented; new receipt does not inherit proof; metadata checks are not file-content hashing |
| Client approval by current assigned PM | 109; exact current source/submission/proof and decision history | Implemented; unassigned Admin cannot approve as PM |
| Internal approval by actual lead/HR | 110/111; standalone creating-lead scope or project assignment plus reporting scope | Implemented; PM permission alone is insufficient |
| Explicit training signatories independent of charter authority | 112; actual eligible contacts, grant/revoke/restore and immutable reasons | Implemented; none selected automatically |
| Agreement tick, typed actual full name, optional note, actual account/server time | 114; allowlisted exact PM-approved Client confirmation and immutable evidence | Implemented; no drawn signature, paid service or locked training PDF |
| Reject stale/withdrawn/revoked requests; preserve original receipts | 109–115 and corresponding database/UI suites | Implemented; earlier evidence remains historical, not silently current |
| Only internal staff receive approved Internal learning hours; prevent duplicates | 115; exact actual intervals, existing approved Training activity overlap and cross-month deduplication | Implemented as existing learning-hours measure, without a new weighted target or paid activity |
| Current learner/reporting scope and immutable saved/locked monthly basis | 115; scoped Learning credit RPC, scorecard integration, source-hash review guard | Implemented; no new salary/bonus/overtime/billable rule |
| Authorized coordinators can inspect retained attendance/proof after corrections and source changes | Existing row/storage policies retain the records, but prior UI showed only current facilitator receipt | Concrete gap addressed in this increment by 116 and a private history UI/CSV |
| Existing private review/confirmation scopes must remain separate | 116 uses SECURITY INVOKER and ordinary existing source/receipt/review/confirmation/storage row policies | No new row access, reviewer, write action or assignment |
| Signed-in/browser/export/device acceptance | Client-owned 41-item acceptance | Pending; automated checks and signed-out HTTP do not establish acceptance |

Relevant implementation: `src/portal/project-training.tsx`, `internal-training.tsx`, `training-session-definition.tsx`, `training-attendees.tsx`, `training-attendance.tsx`, `training-evidence.tsx`, Client/Internal submission/review components, `client-training-confirmation.tsx`, `training-learning-credit.tsx` and new `training-receipt-history.tsx`. Database cases are in `tests/helpers/training-*-cases.mjs`; browserless interaction suites are in `tests/*training*-ui.cjs`. The current participant guide replaces older staged-development statements that incorrectly called now-deployed work pending.

## Existing source-status behaviour

The original project documentation workflow is Draft → administrator Reviewed → Archived, with versioned corrections and immutable archives. Those statuses are not session attendance approval. Existing exact-current checks require the original Draft source version/definition/register/attendance. A documentation revision, including Review or Archive, supersedes that receipt; old confirmations and approval history survive, while current signing/learning eligibility follows the current-source checks. The history view makes the retained evidence inspectable without changing this rule.

Standalone Internal definitions have a Draft-only status constraint; attendance approval is separate. No independent standalone completion/archive, preservation-of-current-credit-on-archive, certification or pass/attendance threshold rule has been supplied. Do not add such transitions merely to make a planning definition look completed. A different business outcome requires a concrete supported decision; none is needed for the read-only retained-history increment.

## Remaining approved-activity association boundary

DEV-026's catalogue title includes approved-activity linkage. Migration 115 references actual approved Training activity IDs in the learning basis and prevents temporal duplicate credit, but neither `work_activities` nor a training relation currently stores an explicit manually chosen receipt-to-activity association. It does not generate ordinary paid activities or attach a training proof to an activity by an explicit selection. Treating temporal overlap as a manually approved association would overstate implementation.

Next bounded development: inspect the existing work-activity read/review authority and implement an explicit manual association of actual existing Approved Training activities with exact current approved Internal attendance/proof, with real staff/account/receipt checks, immutable reasoned history, retries and stale/withdrawal handling. Keep the existing independent activity approval and learning deduplication. Do not generate paid activities, invent hourly rates/assignments, require an unsupported full-interval match or silently broaden source/reviewer permissions. If a concrete association rule cannot be supported by the confirmed requirements, ask only that business decision before dependent work.

DEV-025/026 remain in progress while this broader cross-package boundary is handled. This reconciliation does not mark training development or the CRM complete or convert acceptance-pending into acceptance-passed. Catalogue remains 54 open (seven in progress, 47 not started), four development-complete. DEV-027 competence/certification remains separate and requires actual criteria/standards; no certificate data or rules are inferred.
