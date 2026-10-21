# BOQ adoption rules and supported execution

Confirmed by the user on 21 October 2026. These decisions supersede earlier statements that adoption awaits finance/execution policy. They do not turn an accepted offer into an automatic invoice adjustment or automatically change assignments.

## Finance policy

Issued invoices are never edited. Adjustments are separate documents linked to the original invoice and change order. Removal/reduction uses a credit note: reduce unpaid balance first; excess becomes client credit, applied to future invoices by default. Cash refunds require a client request and Owner/Director approval. Additions/increases use a debit note (supplementary invoice) for the difference. Cancel/rebill is allowed only with no payments; retain the original as Cancelled, never delete it.

Credit/debit notes use the original lines' tax rates. Accounts enters WHT adjustments manually with a WHT certificate reference; no automatic WHT reversal. Accounts prepares, Manager approves credit/debit notes, and Owner/Director approves requested cash refunds. Actual role designations remain manual. The existing general credit workflow is capped by unpaid balance after pending/verified payments; this increment does not relax that safeguard or claim the complete new settlement policy is implemented.

## Execution policy

Completed tasks and recorded timesheets, issued material and expenses are never changed or deleted by adoption. Removed unstarted tasks become **Cancelled – change order** and remain in history. For started work, PM proposes **Stopped – change order** with actual quantity/work done; Operations Manager approves the change. Installed material removal needs a new removal task; unused issued material follows Site Return Note. Replacements create new tasks from the new item's template. Existing costs stay on the project as change-order cost and become billable only when the change order explicitly says so. Existing Admin BOQ adoption approval remains required.

## Supported increment: unstarted task removal

Open the frozen BOQ line revision register in the existing BOQ workflow. An internal PM/Admin can load **Unstarted task removal adoption** only for a client-Accepted Remove revision. The server rechecks the exact reviewed proposal, Approved change, accepted original baseline, company/sale/project and active project without released handover. It rejects retired or superseded sources. Expiry of the offer after a valid terminal acceptance does not erase that acceptance.

The PM manually selects actual generated tasks belonging to the original removed item and explains the mapping. Tasks are not inferred from matching wording or quantities. Nothing is preselected. The server freezes the accepted evidence, task/plan/checklist/history, actual proposer and server time. Admin reviews that exact mapping and records the adoption reason. A changed task/source, revoked proposer authority or newly linked operational record prevents adoption. An old stale proposal remains immutable; submit a fresh proposal using current evidence.

Only To do tasks with untouched checklists, no dependent tasks, no reviewed phase and no linked operational/financial record are supported. The conservative operational check includes draft records and schedules, not only posted costs. Existing planning history is preserved. Selection can cover only a subset of the removed item's tasks: it is an execution action for those tasks, not a declaration that the whole line is financially or operationally settled.

Adoption atomically records immutable evidence and sets selected tasks to **Cancelled – change order**. It edits no invoice, payment, tax/WHT, original quotation, cost, stock or activity record. Cancelled tasks cannot be edited, reopened or deleted, and cannot receive new work/child records or become new dependencies. Task row locks serialize child writes against cancellation. Private proposals/adoption receipts and safe CSV are visible only to current project managers/Admin; client publication remains sanitized. No business records or assignments are seeded.

## Precise resume point

Line-linked credit/debit preparation and explicit independent Manager approval using original invoice tax rates and manual WHT certificate evidence are implemented in migration 141; see [financial adjustment guide](boq-financial-adjustment-guide.md). Approval is not issuance/posting. Next implement approved-document posting, separate excess client-credit accounting/application and manual WHT ledger entries. Keep legacy unpaid-balance limits until the complete new balance path is tested. Follow with requested-refund approval and no-payment cancellation/rebill. Separately implement PM/Operations Manager started-work proposals, actual quantities, retained cost/billability attribution, removal/return tasks and replacement template adoption, retaining final Admin adoption approval. Reconcile dependency, phase and handover treatment before allowing cancellation to count as completed work; this release does not waive existing completion gates.

DEV-028 remains in progress. Catalogue: 50 open packages (six in progress, 44 not started), eight development complete. All 41 client acceptance items remain pending. The client owns signed-in workflow/browser/export/device acceptance.

## Validation and release

PR #217 / migration 140: 8,210 checks across 146 suites, TypeScript and production build passed. Both requirement documents preserve the exact tested head, migration, production and source/result verification checkpoint. This remains execution-only adoption and leaves the policy extensions listed above pending.
