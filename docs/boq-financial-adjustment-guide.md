# BOQ financial adjustment preparation and Manager approval

Open **Finance & expenses → BOQ adjustments**. This is a private preparation/review workflow for an exact client-Accepted original-line Remove or Replace revision. **Approved preparation is not an issued credit/debit note and does not post any balance, client credit, WHT or cash movement.** Existing credit/invoice safeguards remain in force. Financial posting is the next increment.

## Actual approval authority

Accounts uses existing `finance.manage` preparation authority (including existing Admin finance access). Financial Manager authority is separate: Admin must explicitly choose an actual active internal account and grant/revoke/restore the designation with a reason. No people are selected or seeded by development. PM, Team Lead, Sales Manager, Admin and Accounts status alone do not imply this Manager approval designation. It grants no general Accounts access, project membership or refund authority.

The designation keeps immutable revisions, actual administrator, reason and server time. A revoked/inactive Manager cannot read the private register or approve. Restoration creates a new designation receipt; an old receipt cannot be reused. A preparer cannot approve or return their own preparation, even if they also hold a Manager designation. Cash refunds still require the separately confirmed client request and Owner/Director approval; that workflow is pending.

## Accounts preparation

Load current access, then explicitly choose the actual Accepted BOQ line revision and original Issued PKR project invoice. Choices start blank. Additional-offer invoices, another company/project/currency, ambiguous cross-project invoice links, stale/retired/superseded commercial evidence, an inactive project and released handover are rejected. The original quotation and issued invoice are never edited by this workflow.

The server calculates the net difference from the exact accepted original line total and the replacement quantity × unit price (or zero replacement scope for Remove). Reduction/removal produces a credit-note preparation; increase produces a debit-note preparation for the difference. A zero difference does not create a financial adjustment. The register excludes internal quote budgets/costs and publication snapshots; it retains necessary commercial/invoice evidence only.

Conversion invoices can contain combined first-payment lines rather than a BOQ line per item. Accounts therefore explicitly maps actual portions of the difference to actual original invoice lines and explains the mapping. The mapping is never inferred from wording or unit prices. Portions must sum to the full accepted net difference; duplicate/foreign/unknown invoice lines are rejected. Credit portions cannot exceed the original mapped invoice-line net. The current increment supports a complete difference mapped within **one** original project invoice. Partial/unbilled or multi-invoice differences that cannot satisfy those guards require subsequent integration; they are not silently allocated or credited.

Each portion copies its original invoice line's tax rate. Existing invoice cent precision and per-line tax calculation are retained; callers cannot enter a replacement tax rate. Accounts calculates and reviews a frozen preview before submitting. Editing any amount or WHT evidence clears the old preview.

Optional signed WHT amount and actual certificate reference are entered manually together. Blank WHT remains unentered; there is no inferred reversal, automatic sign or deduction from the displayed gross adjustment. These fields are proposed evidence only until the later manual WHT posting increment.

Submission freezes the public accepted source/decision, exact change order, original invoice/header/items, original tax rates, manually mapped amounts, net/tax/gross, optional WHT evidence, explanation, actual Accounts preparer and server time. It creates an immutable preparation record, not an issued financial document.

## Manager review and correction

A currently designated different Manager reviews the exact frozen preparation and records Approved or Returned with an actual reason. Approval rechecks current Accounts preparer authority, the exact active accepted commercial basis and original Issued invoice/items/tax rates. Source changes require return and fresh preparation. Payment activity alone does not rewrite the original commercial/tax basis; because this increment does not post, a fully paid invoice may be prepared and reviewed without creating client credit or a refund.

A Returned preparation can be corrected only by creating a new immutable revision naming the exact latest Returned predecessor. Pending/Approved preparations block duplicate financial proposals for the same accepted revision. Returns can resolve stale/closed source evidence without treating it as current approval. Approvals/retries cannot rewrite previous decisions.

The private CSV retains source, original invoice, change order, line/tax/WHT evidence, immutable revisions, actual actors/server times, decision reasons and review receipts. Admin's export also retains designation history. Clients and unrelated staff cannot read internal preparations/reviews; no client invoice/credit document is published by this release.

## Precise next increment

Post approved adjustments through separate immutable documents linked to the original invoice and change order, rechecking current source and avoiding duplicate posting. Implement the confirmed unpaid-balance/client-credit split and default future-invoice application before relaxing the old unpaid-balance-only credit safeguard. Integrate debit supplementary invoices, manual WHT ledger entries/certificate evidence, requested cash refunds with Owner/Director approval and no-payment Cancelled-original rebilling. Reconcile partial/multi-invoice billing and reporting explicitly. Started-work, retained change-order costs/billability, removal/returns and replacement-template execution remain separate under the confirmed [adoption rules](boq-adoption-rules.md).

DEV-028 stays in progress; 50 open packages (six in progress, 44 not started), eight development complete. All 41 client acceptance items remain pending. Actual mappings/designations remain manual; signed-in browser/workflow/export/device acceptance belongs to the client.

## Release checkpoint

PR #219 / migration 141: 8,324 checks across 147 suites, TypeScript and production build passed. Both requirement documents preserve exact tested/merged source, migration, READY production and served-asset verification. All saved results/source hashes were reverified unchanged. No actual Manager designations, preparations, reviews, invoices or business fixtures were inserted. Posting/client credit and the integrations listed above remain pending.

PR #220 corrects the designation-only CSV to place Manager history under the twentieth header. Corrected-source full validation: 8,325 checks/147 suites, TypeScript/build; source/result hashes reverified unchanged. Migration 141 was not reapplied. Both requirement documents preserve the follow-up deployment checkpoint and precise posting/client-credit resume point.
