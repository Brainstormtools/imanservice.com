# Private office cost allocation drafts

Open Finance → Expenses as an active administrator or team member with Accounts finance.manage permission.

1. Choose New office cost allocation draft and select an actual Approved general office expense. Project/task expenses use their separate workflow.
2. Choose each existing PKR project/product workstream and manually enter its split amount. Add/remove rows as needed, up to 100 distinct workstreams. Source category and amount remain fixed.
3. Enter the actual draft reason and save. Partial allocations retain an explicit unallocated amount. These are private proposals; saving does not apply overhead to project financials or pay money.
4. To revise, open the existing draft, enter actual amounts and a new reason, and save the displayed version. Source expense cannot be changed. Refresh after a source/version change; a changed original category/amount requires separate reconciliation.
5. Export the individual draft or its immutable revision history CSV. Archives retain full original source, actual target project/product identities, requests, reasons and actual actor/time.

Failed saves preserve inputs and retry identity; a changed request receives a new identity. Refresh clears old private state after read/download failures or permission changes. Only Accounts/admin can read these drafts; direct mutation and history deletion are blocked.

Office draft review/return and application/withdrawal are separate manual decisions. The private Office product report partitions existing costs; broader project/product financial reporting remains pending. No automatic distribution weights, reviewers or project-profit rules are configured. Client live/export/device acceptance remains pending.

## Review or return an exact draft version

Use Review this office allocation version or Return this office allocation version and enter the actual decision reason. Reviewed requires the exact current Approved office expense, refreshed source version/evidence and matching current PKR target project/product identities. A separate payment/version change requires refreshing the draft before review even when the cost is unchanged.

Returned records actual corrections against the displayed version and preserves full original draft and actual current source evidence, including stale source changes. Review/return does not apply office costs to projects or alter profit/cash. A new draft revision needs fresh review.

Export office allocation review CSV retains immutable original allocation, actual source-at-action, actor/time/reason and canonical request. Exact retries preserve the original event; changed requests require new identities. Later decisions never rewrite earlier archives.

## Apply or withdraw reviewed Office costs

After saving and reviewing the exact current draft, choose Apply reviewed office allocation version and enter the actual reason. The server checks the displayed draft version, latest Reviewed event, current Approved no-project/no-task source (including version/evidence), latest application predecessor and current PKR project/product identities. No automatic weights or allocations are calculated.

Office costs by project and product shows each current Approved Office expense once, its frozen applied manual target splits, and its unallocated General office remainder. Splits may span multiple projects; the Office source is never repeated for each target. Export office product costs CSV retains category, frozen project/product/workstream, source expense, application ID and classification state. Target names remain frozen at application. Later draft revisions or review returns do not replace an applied classification; a new Reviewed draft needs explicit replacement application.

Withdraw applied office classification with an actual reason to return its entire current cost to the Office remainder. Withdrawal accepts the exact latest application even if the source has changed; it archives the original applied split and actual current source. Export office classification history CSV retains immutable application/review versions, full frozen draft, source at action, actual account/server time, reason and canonical request. Failed actions keep reason and retry identity; changed requests use a fresh identity.

Changed economic amount/category makes an existing applied classification require reconciliation and presents current cost entirely unallocated. An unapproved, project-linked or task-linked source is excluded from this Office report. A separate cash-only/version change leaves an already applied economic split intact, but new application requires refreshing/reviewing current full evidence. This report does not move cash, move the source expense into a project, change recorded project totals or calculate product revenue/profit. Broader product financials remain separate DEV-042 work. All signed-in/live/export/device acceptance remains client-owned and pending.
