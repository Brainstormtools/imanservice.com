# Client cash-refund requests and Owner/Director approval — prepared increment

This increment depends on prepared PR #224 and its credit-posting dependency PR #223. Migrations 142, 143 and 144 remain unapplied. Production remains at migration 141 and the existing production deployment. This guide describes prepared request/approval functionality, not a live refund-payment service or client acceptance.

## Designate actual authority manually

In **Finance & expenses → Client refund requests**, select **Load current refund access and requests**. An administrator uses **Actual refund Owner/Director designations** to explicitly select the actual active internal account, actual Owner or Director authority, grant/restore or revoke action, and reason. Nothing starts preselected. Exact prior revisions, actual actor and server time are retained immutably. No Owner or Director is seeded or inferred from Admin, Accounts, PM or financial Manager permissions. Refund designation grants this workflow only, not general Finance access, project membership or Manager authority.

## Record the actual client request

Active clients open Billing and select **Load current refund access and requests**. Choose the actual own-company issued credit note, enter the actual cash-refund amount and reason, and explicitly check the cash-refund request statement. Source, amount and agreement start blank/unchecked. Available credit is checked again against the server's exact current issued-credit/application evidence. A request cannot exceed available carried credit; zero, negative and fractional-cent amounts are rejected. An internal account cannot manufacture a client request.

The actual requesting account, its account name at request time, server date/time, amount, reason, confirmation and current credit evidence are retained. An unchanged uncertain submission retains its request identity. An undecided or current approved request blocks another request for that same credit. The original requesting account may withdraw its undecided request with the exact request receipt and a reason. Same-company contacts cannot withdraw another account's request. Earlier requests and terminal decisions are never overwritten or deleted.

## Review the request as the actual Owner/Director

A currently explicitly designated Owner/Director opens **Finance → Client refund requests**. Accounts can inspect refund evidence but cannot approve without the separate actual designation. Select **Load exact Owner/Director review evidence** to load the actual request, available credit and current designation. Approval requires this exact fresh evidence, current client eligibility and enough remaining credit. Choose Approved or Returned, enter the private actual decision reason and explicitly confirm the review. Approval freezes the actual Owner/Director authority receipt, reviewer account and server date/time. A returned request can be replaced by a fresh actual client request; a terminal review is immutable. A stale request can still be returned using its exact original request receipt.

Clients see the necessary outcome, actual decision account and server time. They do not receive private reviewer reasons or authority/designation snapshots. Administrators and authorized internal reviewers retain their permitted private evidence and designation history.

## Approval is separate from payment

This increment creates no cash entry, bank movement, payment claim, paid/refunded status, invoice adjustment or reservation of client credit. The existing automatic same-company PKR settlement of later issued invoices continues by default. If that consumes credit, the previous approval is explicitly historical/stale. A fresh actual client request may be submitted against remaining available credit; earlier approval evidence stays immutable. Any future cash payout must check the exact current available credit and approved request again and record actual payout evidence atomically with the credit-liability reduction. Approval alone never proves a refund was paid.

For example, a client requests PKR 200 from PKR 570 available credit, and an actual designated Director approves it. If a later issued invoice uses PKR 500, the remaining credit is PKR 70 and the earlier approval is stale. The system records no fictitious PKR 200 payout and does not allow a future payout to rely on that old credit basis.

## View and export current evidence

Use **Export refund request and approval evidence CSV** after explicitly loading current authorized data. Clients receive their own company's necessary credit/request/decision evidence. Accounts and designated Owner/Director reviewers receive private review receipts; designation history is Admin-only. Other companies and unrelated staff cannot read the register. Account/company/permission changes, parent blocking and failed requests clear old evidence and exports; late responses cannot restore earlier scope.

## Precise resume and limits

The request/approval workflow is prepared for the grouped release and is not merged or applied to production. The next refund increment is actual Accounts payout evidence and cash/client-credit accounting against exact current Owner/Director approval, without inventing bank accounts or assignments. No-payment cancellation/rebilling must retain the original as Cancelled, never delete it. Partial/multi-invoice and legacy-credit reconciliation, WHT financial settlement and PM/Operations Manager execution changes remain separate. All 41 client acceptance items are pending; DEV-028 stays in progress and the package catalogue is unchanged.

Prepared follow-up: [actual approved refund payout records and cash/client-credit accounting](client-refund-payout-guide.md). That stacked increment remains unmerged/unapplied; approval itself still creates no payment.
