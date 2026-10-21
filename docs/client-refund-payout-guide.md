# Actual client refund payout records — prepared increment

This increment is stacked on prepared refund request/approval PR #225, supplementary/WHT PR #224 and credit-posting PR #223. Migrations 142–145 remain unapplied; production remains at migration 141. It records actual payments already made. It does not send money, connect to a bank or constitute live client acceptance.

## Record the actual approved payment

Accounts opens **Finance & expenses → Client refund requests** and explicitly loads current refund access and requests. Only a current Approved request with exact current client-credit evidence and no recorded payout exposes **Accounts: record an actual paid client refund**. Owner/Director approval alone does not grant Accounts payout capability.

Select **Load exact approved refund payout evidence**. The server checks the immutable actual client request, actual Owner/Director approval/designation at decision time, requesting client's current eligibility and exact current source-credit balance/application/payout evidence. The preview shows the original credit note/invoice, approved amount, available credit and actual approval account/time. If later invoices or another refund have changed that basis, obtain a fresh actual request/approval; the old approval cannot authorize payment against changed credit.

Manually enter actual payment date, actual payment method, actual payment reference and private actual evidence reference. These fields start blank. Confirm that this exact refund was actually paid. The supported methods match the existing cash workflow: Cash, Bank transfer, Cheque and Mobile wallet. The date cannot be future or precede the actual refund approval. The amount is the complete approved request amount and cannot be edited during payout recording; staged/partial payment of one approved request remains separate work.

**Record actual approved refund cash out** atomically creates one immutable RFND cash-out record and consumes that amount of carried PKR client credit. The record retains request/approval/source-credit/project links, actual payment details, private proof reference, exact before/after evidence, actual Accounts recorder and server recording time. An unchanged uncertain request retains its identity. Reusing a paid approval or changing an existing payout request is rejected. No expense or loan is manufactured, and no original invoice, commercial tax credit note, WHT evidence or customer receipt is edited.

## Reconcile cash and credit

For example, an actual approved PKR 200 payment from PKR 570 available credit leaves PKR 370. Future invoices can apply at most that remaining PKR 370, never the refunded amount. Client-credit views and the dashboard subtract refunded amounts from available liability. The dashboard separately reports client refund cash out and includes it in the actual PKR payment month. Net trade position releases the settled credit liability once; this does not create another invoice credit or reduce the original gross receipt.

Project cash and portfolio reports attribute the cash out to the original credit's project, subtracting it once from operating cash and cash including loans. The separate refund figure is visible in project metrics and the portfolio **Cash and commitments** view/export. Work costs, profit/cost inputs, loan principal, supplier/expense payments, original invoices and gross verified customer receipts stay as their own records.

Use **Cash records → Open client refund cash history** to reach this separate cash ledger. Recorded RFND records remain immutable. Generic expense/loan cash reversal does not reverse them. A dedicated reasoned reconciliation/reversal workflow is separate remaining work; do not imply that an actual bank payment was undone by changing application data.

## Inspect the retained record

The request view labels the actual recorded payment separately from unpaid or stale approval. **Export refund request and approval evidence CSV** includes the authorized payout receipt. Clients receive only their own company's necessary payment number, amount/date/method/reference and actual recorder/server time. Private proof references, Owner/Director designation receipts and internal approval/payment snapshots stay internal to authorized Accounts/refund reviewers. Other companies and unrelated staff cannot read private payout tables or preview/post APIs.

Account/company/permission changes, failed reads and parent blocking clear prior evidence and exports. Revoked Accounts access cannot post. Late preview responses cannot restore controls after their scope is removed. Current credit consumption and refund recording use the same company lock, preventing a refund and future-invoice application from spending the same credit.

Required evidence here is a manually entered actual private proof reference. This new payout source does not inherit the existing expense/loan Cash evidence-file upload/download widget. Dedicated refund file attachments and reasoned refund reversal/reconciliation remain explicit future work; prior DEV-048 source coverage is not proof of this new source's file support.

## Precise resume

Keep the stacked PRs unmerged and migrations 142–145 unapplied for the grouped release. Ordered schema/deployment preflight and exact preview/production verification remain required; actual business content and assignments stay manual.

Next: no-payment cancellation/rebilling retaining the original as **Cancelled**, never deleted; then partial/multi-invoice/legacy-credit reconciliation and WHT financial settlement. Refund correction/reversal, staged partial payouts and dedicated payout file attachments remain open. PM/Operations Manager started-work changes retain separate final Admin adoption. DEV-028 and the complete CRM are not finished. Catalogue unchanged: 50 open packages, eight development complete; all 41 client acceptance items remain pending.

Prepared follow-up: [supported no-payment cancellation and exact rebilling](boq-invoice-rebill-guide.md). This remains a stacked, unmerged/unapplied increment with explicit reconciliation limits.
