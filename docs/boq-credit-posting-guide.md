# BOQ credit posting and client-credit application — prepared increment

This increment is prepared for the grouped release. It has not been merged, migration 142 has not been applied, and production remains at migration 141. This guide describes the prepared implementation, not live acceptance. DEV-028 and all 41 client acceptance items remain open.

## Issue a supported approved credit

Accounts first prepares the full accepted reduction against manually selected original invoice lines using the existing BOQ adjustments workflow. A different explicitly designated Manager approves the exact preparation. Approval itself never posts an invoice adjustment.

On an Approved credit preparation, Accounts selects **Load credit posting preview or receipt**. The server checks the exact original-invoice/change-order source again, original-line credit capacity, current payments and prior credits. Resolve Pending payment claims before posting. Enter the actual client-visible reason and explicitly check agreement to the displayed evidence. **Issue approved BOQ credit note** creates a separate immutable credit note linked to the original invoice, accepted change order, preparation and Manager approval. The actual Accounts account and server time are retained. The issued invoice and its original lines/tax rates remain unchanged. An unchanged uncertain submission retains its retry identity; altered evidence needs a fresh preview.

For example, an approved gross reduction of PKR 1,140 against an original unpaid balance of PKR 570 issues the full PKR 1,140 commercial credit note: PKR 570 reduces the invoice balance, and PKR 570 becomes available client credit. The invoice balance is zero; the excess is not displayed as a negative invoice balance or a cash receipt.

## Apply available credit to later invoices

When a later invoice is issued, available same-company PKR client credit is applied automatically up to its outstanding amount, after existing Pending/Verified payment claims and issued balance credits. Drafts, other companies and other currencies do not consume that credit. Existing already-issued invoices are not retroactively changed by this increment. Each application retains its source credit, target invoice, actual issuer, server time and before/after evidence. Chronological source tracking provides deterministic provenance; it introduces no expiry or commercial priority policy.

A **CCA** application is settlement evidence, not another commercial tax credit note. It transfers no cash and creates no new tax reduction. The existing invoice balance mechanism includes these settlement applications, so balance-credit report totals must not be treated as tax credit-note totals. The Finance dashboard separately shows remaining unapplied PKR client credit and deducts that liability once from net trade position. Broader project contract/profit and tax-accounting development remains open.

## Inspect retained evidence

Use **Load issued credits and applications** under BOQ adjustments or Billing, then **Export issued client-credit ledger CSV**. Issued commercial notes and settlement applications are labelled separately. Accounts and explicitly designated Managers can inspect private approval/posting evidence. Active clients see only their own company's necessary commercial documents, credit balance and settlement evidence; they receive no private preparation, Manager designation, payment-proof or quote-cost snapshots. Changing account/company/permissions, blocking the parent workflow or a failed read clears previous evidence and exports.

Posted credit notes, their applications, original invoice financial headers/lines and retained posting evidence cannot be changed or deleted. Verified source payments that created carried credit require a separate reconciliation workflow before reversal or financial alteration. This increment does not silently invalidate spent credit.

## Explicit remaining limits

Supported posting is a full accepted single-invoice PKR reduction with no manual WHT adjustment. A stacked prepared increment in [supplementary/WHT guide](boq-debit-wht-guide.md) adds supplementary issuance and immutable manual WHT tax evidence. Manual WHT settlement, cash refunds, no-payment cancellation/rebilling, partial/multi-invoice reconciliation and existing unmapped legacy credit/application reconciliation remain separate work. Unsupported sources are rejected; neither amounts nor assignments are guessed. No automatic WHT reversal occurs. Cash refunds still require actual client request and Owner/Director approval when implemented. Started-work adoption/removal/return/replacement remains separately governed by PM, Operations Manager and final Admin approvals.

No actual Manager, invoice, payment, credit note, business fixture or assignment is seeded. Local automated fixtures do not constitute production or signed-in client acceptance.
