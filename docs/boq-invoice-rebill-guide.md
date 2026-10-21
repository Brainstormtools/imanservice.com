# Approved no-payment invoice cancellation and rebilling — prepared increment

This increment depends on prepared payout PR #226 and its stacked predecessors #225/#224/#223. Migrations 142–146 remain unapplied; production remains at migration 141. It is prepared functionality for the grouped release, not live client acceptance or completion of commercial change management.

## Select the supported alternative

Accounts first uses the existing BOQ adjustment preparation workflow to manually map the exact accepted change to actual original invoice lines. A different explicitly designated Manager approves the frozen preparation. Under the Approved preparation, **No-payment cancellation / exact rebill** is an alternative to issuing a credit/debit note; it cannot be used after posting that note.

Select **Load cancellation and rebill preview or receipt**. The original must be the exact current Issued PKR project invoice for the same company. This bounded workflow rejects all payment-claim history, including pending/rejected/reversed claims, all credit-note history, posted adjustments, recurring source/run links and previous rebill chains. Such cases require separate reconciliation. Manual WHT and inconsistent invoice/line rounding are also rejected. A no-payment invoice alone is not sufficient if one of those unsupported histories exists.

The preview shows retained original gross, remaining line allocations, original tax rates and exact remaining net/tax/gross. The remaining totals must equal original totals plus or minus the independently approved difference. Untouched lines retain original description, quantity, unit price and tax. Changed allocations use quantity one and the adjusted net as their monetary billing amount; this does not edit physical work quantities. Accepted replacements use their actual client-accepted replacement description. The invoice notes explicitly explain the monetary allocation basis. The server does not guess new tax rates, billable work, material return policy or product assignments.

## Confirm cancellation and the exact remaining invoice

For a positive remaining amount, manually enter actual replacement issue/due dates and bank instructions. Enter the actual client-visible cancellation/rebill reason and explicitly confirm the displayed source and remaining amounts. **Confirm approved cancellation and rebill** creates a separate Issued replacement invoice linked to the actual original project and accepted change, and changes only the original's status to **Cancelled**. Original number, amounts, dates, notes and invoice lines are retained. Actual Accounts actor, server time, original source/approval and replacement evidence are immutable.

For example, an original PKR 3,240 invoice with an approved PKR 1,140 reduction becomes retained Cancelled history plus a separate PKR 2,100 replacement. It does not become PKR 2,100 plus an extra credit note. Issued receivable/project reports exclude the Cancelled original and count the replacement once. Existing same-company client credit may settle the newly issued replacement through the existing separate CCA application mechanism.

If approved remaining scope is zero, the operation cancels the original and creates no zero-value invoice. No replacement dates/bank details are collected for this case. A stable unchanged request can be retried; duplicate or changed immutable requests are rejected. A late payment/credit/source change invalidates the preview. The original invoice lock serializes payment claims and credit posting against cancellation.

## Inspect retained history

Accounts and explicitly designated Managers can inspect permitted private source/approval receipts. Active clients explicitly load **Retained cancelled invoices & rebills** in Billing and receive only own-company commercial cancellation/replacement evidence. **Export cancellation and rebill history CSV** retains original/replacement numbers, actual reason, change identifier and actual account/server time. Other companies and unrelated staff cannot read private evidence. Account/company/permission changes, parent blocking and failed reads clear earlier evidence and exports; late responses cannot restore revoked context.

The Cancelled original remains visible as history with zero collectible balance. It cannot accept payment claims, be changed to Void, be deleted, or be used to start a recurring schedule. Original/replacement line and project attribution evidence is immutable. Replacement invoices cannot be used as new original sources for another adjustment or recurring run until change-chain reconciliation is supported. Ordinary note posting and cancellation/rebill cannot consume the same approved original twice. No task, timesheet, material, expense or execution approval is changed.

## Precise resume and release status

Keep the stacked PRs unmerged and migrations 142–146 unapplied for the grouped release. Ordered migration/security/source preflight, preview build and exact production deployment/domain/assets verification remain required. No actual customer invoice, approval, business fixture, assignment or payment detail was inserted.

Next development: partial/multi-invoice, legacy-credit, rounding and repeated-change-chain reconciliation; WHT financial settlement; refund correction/reversal, staged partial payouts and dedicated refund file attachments. PM proposes started-work changes with actual work/quantities, Operations Manager approval and final Admin adoption remaining separate. Client-owned signed-in workflow/export/device acceptance remains pending. Catalogue unchanged: 50 open packages, eight development complete; DEV-028 and all 41 client acceptance items remain open.

Prepared follow-up: [private billed/unbilled invoice allocation and independent review](boq-invoice-allocation-guide.md). This records allocation evidence only; split-document issuance and reconciliation remain separate.
