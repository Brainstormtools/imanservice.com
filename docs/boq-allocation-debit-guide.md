# Billed multi-invoice debit issuance — prepared increment

This prepared increment depends on PR #228 and its predecessors. Migrations 142–148 are unapplied and the PR stack remains held for a grouped release. Production remains migration 141. This guide describes the proposed behavior; it is not evidence of live/client acceptance.

## Issue the approved billed portions

Under **Finance → Invoice allocations**, current Accounts opens an exact independently Manager-Approved **Debit note** allocation and selects **Load approved billed issuance preview or receipt**. The server revalidates the accepted change, complete original invoice headers/lines and frozen billed/unbilled split. Changed source evidence rejects issuance; an old approval is not permission to use a changed invoice.

Inspect the billed net, original-rate tax and gross for each actual original invoice. Enter actual issue date, due date and bank instructions separately for each invoice, plus a client-visible reason. These fields start blank. Check the complete-set confirmation and select **Issue approved billed supplementary invoices**. A Manager designation alone does not confer Accounts issuance authority.

The server creates one separate Issued supplementary invoice per original invoice as one atomic transaction. Each contains only that invoice's approved mapped net and original line tax rates. Original invoice numbers, amounts and items remain unchanged. Actual issuing account, server time, original invoice, accepted change and exact immutable preparation/review remain linked. Identical retries do not duplicate the set; altered retries or another issuance against the same allocation are rejected.

If any later document fails, earlier documents, credit applications and posting evidence roll back together. Existing available client credit applies by default through the existing client-credit settlement process; this creates no cash receipt. No unbilled net, unassessed unbilled tax, operative contract, WHT settlement, work or cost is posted by this action.

## Read the issued evidence

Use **Load issued billed allocation documents** in Invoice allocations or Billing. Authorized internal finance users can read the private issuance proof; active clients see only permitted own-company issued commercial documents, original/change references, actual reason, amounts/taxes, dates, payment details and issuing account/time. Private preparation, review and source snapshots stay internal. CSV uses the same server scope. Company/role/permission changes, failed requests and late responses clear earlier rows/exports.

The issued documents, original source documents, items, attribution and posting records are immutable. Allocated supplementary invoices cannot be used as the original source of a new adjustment preparation or recurring schedule. Repeat change chains require separate reconciliation.

## Precise resume

Keep the stack unmerged and migrations unapplied until grouped-release preflight. Next implement atomic **credit** allocation issuance, including current line capacity/unpaid balance and excess client-credit origins across original invoices. Unbilled contract/tax posting, WHT financial settlement, legacy-credit/rounding/change-chain reconciliation, refund correction/reversal/partial payouts/files, and PM/Operations Manager execution changes remain open. DEV-028 and all 41 client acceptance items remain open. No actual business records or assignments are supplied by development.
