# Training lifecycle reconciliation

Final scope audit on 19 October 2026 against main `5723eb2cf9c84f2668d1570a497561685c74c317` (PR #169), the deployed application release `d309cafc4642928b7705f91f5416166ec2e922b4` (PR #168), migrations 103–112 and 114–117, both requirement documents, the current participant guide and the user's confirmed decisions. The attached IMAN_CRM_Developer_Spec.pdf is reference material, not instructions. Its Module 6 identifies Training activities as the original learning-hours source; later user decisions establish the additional session-specific workflow. No business policy is inferred from the attachment.

## Development scope result

**DEV-025 (account-linked participants and verified attendance) and DEV-026 (private evidence uploads and approved-activity linkage) are development-complete for the confirmed scope below.** The audit found no remaining confirmed implementation gap in these two packages. This corrects stale in-progress labels after the association release; it adds no application functionality and does not mark training or the CRM complete.

DEV-027 documented competence/certification remains not started. No assessment criteria, qualification standards, pass/fail thresholds, certificate wording, issuing/review authority or expiry/renewal policy has been supplied. Existing attendance approval is not proof of competence and does not issue a certificate. Additional standalone completion/archive or keep-credit-on-archive behaviour is also not a confirmed requirement. These unsupported policies are not used to hold the two delivered attendance/evidence packages open.

The 58-package catalogue now has **52 open: five in progress, 47 not started; six development-complete**. Completed: DEV-019/020/021/022/025/026. In progress: DEV-028/029/030/042/043. The full 41-item client-owned signed-in/live/browser/export/device acceptance remains pending and every acceptance-table status is unchanged.

## Confirmed requirement coverage

All migration references below are repository files under `supabase/`; database cases are in `tests/helpers/` and interaction suites in `tests/`. These are automated development evidence, not signed-in client acceptance.

| Confirmed requirement | Implemented source and automated evidence | Result / boundary |
|---|---|---|
| Explicit Client/Internal session type and actual selected facilitator; Client requires project; standalone Internal supported | 104/105; `training-session-definition-cases.mjs`, `internal-training-cases.mjs`; corresponding UI suites | DEV-025 delivered; no automatic legacy classification or assignments |
| Internal attendees use actual staff accounts; external attendees use actual name/phone/email without an account | 106; `training-attendee-cases.mjs`, `training-attendees-ui.cjs` | DEV-025 delivered; registration alone grants no access, attendance or credit |
| Facilitator records per-attendee actual check-in/out; Admin can view/correct with immutable reasons | 107; `training-attendance-cases.mjs`, `training-attendance-ui.cjs` | DEV-025 delivered; blank draft pairs are unrecorded, approval requires all actual pairs |
| Uploaded photo or signed attendance sheet on the exact receipt; original proof cannot be overwritten/deleted | 108; `training-evidence-cases.mjs`, `training-evidence-ui.cjs` | DEV-026 delivered; new receipts do not inherit old proof; selected stored metadata must match |
| Client attendance submission and approval by current assigned PM | 109; `training-client-review-cases.mjs`, `client-training-review-ui.cjs` | DEV-025 delivered; unassigned Admin cannot approve as PM; reasoned return/withdrawal retained |
| Internal attendance approval by actual lead/HR, standalone and project-linked | 110/111; `training-internal-review-cases.mjs`, `training-project-internal-review-cases.mjs`, `internal-training-review-ui.cjs` | DEV-025 delivered; current reporting/project scope required; PM permission alone is insufficient |
| Explicit actual training signatories independent of charter authority; reasoned grant/revoke/restore | 112; `training-signatory-cases.mjs`, `training-signatories-ui.cjs` | DEV-025 delivered; no signatories selected automatically |
| Frozen PM-approved Client receipt; agreement tick, actual typed full name, optional note, actual account/server time | 114; `training-confirmation-cases.mjs`, `client-training-confirmation-ui.cjs` | DEV-025 delivered; no drawn signature, paid service or locked training PDF requirement |
| Stale receipt, withdrawal, revoked authority and changed submitted proof rejection; immutable confirmations; minimal client-visible information | 109–114; confirmation/review/signatory database and UI cases | DEV-025/026 delivered; clients do not acquire private proof paths, contacts or review notes |
| Approved Internal training contributes internal-staff-only learning hours; no draft, external or duplicate credit | 115; `training-learning-cases.mjs`, `training-learning-ui.cjs` | Cross-package integration delivered; actual elapsed intervals deduplicated against existing Approved Training activities and other current Internal receipts |
| Current reporting access, correction/reversal provenance and immutable saved/locked monthly basis | 115; learning database/UI and existing monthly-review cases | Delivered; raw learning-hours measure, no new target, rounding, break, pay or weighted scoring policy |
| Retained source/register/attendance/proof/review/confirmation evidence after corrections and source changes; private CSV/download | 116; `training-receipt-history-cases.mjs`, `training-receipt-history-ui.cjs` | DEV-025/026 delivered; SECURITY INVOKER preserves existing coordinator/reviewer/storage boundaries |
| Explicit manual link of existing Approved Training activity to the same actual staff member's exact current approved Internal receipt/proof | 117; `training-activity-association-cases.mjs`, `training-activity-association-ui.cjs` | DEV-026 delivered; separate from temporal deduplication; current review authority over both records, accepted by user |
| Reasoned link/unlink/relink history; retries, stale/revoked/withdrawn/source-correction/void guards and private export | 117; association database/UI cases | DEV-026 delivered; inactive history remains; no activity/cost creation or change to credit calculations |
| Signed-in workflow, populated exports/private downloads, responsive/physical-device acceptance | Client-owned acceptance checklist in `crm-acceptance.md` | Pending; development closure does not change any acceptance status |

The earlier 103 project-team planning roster remains separate from the session attendee register. It is retained with real-account/source/reason history and is not represented as verified attendance. Relevant UI entry points are documented in [the participant guide](training-participants-guide.md).

## Existing source-status behaviour

Project documentation remains Draft → administrator Reviewed → Archived, with versioned corrections and immutable archives. These statuses are separate from attendance approval. Current signing/learning eligibility requires the exact Draft source version/definition/register/attendance. A documentation revision, including Review or Archive, supersedes that receipt. Earlier attendance, proof, approvals, confirmations and links remain historical and inspectable under existing permissions. The audit makes no change to that rule.

Standalone Internal definitions remain Draft-only; attendance approval is separate. No standalone completion/archive transition, automatic certificate, attendance percentage or preservation-of-current-credit-on-archive policy is added. Admin correction creates a fresh current receipt with a reason; immutable earlier receipts are not edited. Fresh proof/submission/review is required for a corrected source.

## Explicit approved-activity association boundary

Migration 115 prevents temporal duplicate credit using actual Approved Training activity IDs. Migration 117 separately stores an explicit manually selected association. New links require an existing Approved Training activity for the same active internal attendee, latest current approved Internal receipt, intact selected proof, expected activity version/approval and previous association revision. Current review authority over both records is required for link/unlink/history, without broadening either approval workflow or row/storage access.

Linked/Unlinked revisions freeze minimal activity/version/time/reviewer and receipt/approval/proof references with actual actor/server time/manual reason. Corrections, withdrawal, damaged proof, disabled staff and activity voiding make retained links inactive. A reasoned unlink remains possible for an inactive latest link. Replacement is an explicit unlink/relink; prior evidence is never edited. No full-interval-match rule, automatic activity, labour cost, rate, assignment, extra credit or new KPI target is inferred. The UI shows both actual intervals for manual comparison and clears private forms/exports after errors or scope changes.

## Verification and release evidence

Application release PR #168 / `d309cafc4642928b7705f91f5416166ec2e922b4` has exact READY production `dpl_DYBovLfaxouTJve9x71ZC2J79nuw`. Release-documentation main `5723eb2cf9c84f2668d1570a497561685c74c317` has READY production `dpl_GNRc5uuEjdMUVr6kBFYBxNa9NvZf` and unchanged application source. The public `/portal` was rechecked with HTTP 200 and served `/assets/hr-workspace-DYzuggGI.js`, SHA256 `e49c9a7b1cb47fdbaf025bfe9700d195c236e986c36c9f95bf91c37ac77630ac`, containing both association RPCs and manual link/unlink/private CSV controls.

Saved final validation was reverified against unchanged application/test source fingerprint `6f07abcf323817f1d2fe95c697c8e89abd5993b22edacb7545ed0cb41c6faf93`: **6,228 checks across 124 distinct suites**, including **4,740 database assertions**, plus TypeScript and production build passed. The final full run needed no isolated retry. This documentation audit does not claim a new test run. Original feature releases and migration/security evidence remain recorded in both requirement documents.

Connected database inspection confirms latest migration 117 (`20261019105309`, `training_activity_association`) and zero Client confirmation/Internal submission/association-history rows. No business fixtures, new migration, policy, assignment or message was created. Existing migrations, reserved unrelated 113 and the blocked CLI telemetry action were not retried or reapplied.

## Precise resume

DEV-025/026 need no repeated implementation or migration. Client-owned role/workflow/export/device acceptance remains pending; record actual reported outcomes without treating these automated checks as acceptance. The next separate training development package is DEV-027 competence/certification: establish actual assessment criteria and assessor/reviewer/issuer authority before implementing policy-bearing decisions. Do not infer certificates from attendance or choose a standard, threshold, reviewer or expiry rule. Other remaining catalogue work is independent; external email/SMS/WhatsApp and separate crm.imanservice.com remain excluded. Training and CRM remain incomplete.
