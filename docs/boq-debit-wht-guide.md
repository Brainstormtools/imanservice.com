# Supplementary invoices and manual WHT evidence — prepared increment

This increment depends on prepared credit-posting PR #223 and migrations 142 then 143. Both migrations remain unapplied; production remains at migration 141. This is prepared functionality held for the grouped release, not live client acceptance or completion of DEV-028.

## Issue the approved increase

Accounts prepares the exact accepted increase against explicitly selected original invoice lines. The independent explicitly designated Manager approves that preparation using the existing workflow. The accepted original-invoice/change-order source must still be current at issue time; a supplementary invoice cannot be reused as an original source for another posting.

Under **Approved supplementary invoice**, manually enter the actual supplementary issue date, due date and bank instructions. Dates and bank instructions start blank. Select **Load supplementary invoice preview or receipt**. The server checks the exact Manager approval, current accepted commercial source, invoice mapping, net difference and original tax rates. Editing payment details clears the previous preview.

Enter the actual client-visible reason, explicitly check the displayed evidence, then choose **Issue approved BOQ supplementary invoice**. Accounts issuance atomically creates a separate Issued invoice for the approved increase and original-rate tax, its actual project link, original-invoice/change-order provenance and immutable approval/posting receipt. No invoice is assigned or amount inferred from a description. The original invoice and its lines remain unchanged. Unchanged uncertain requests retain their identity; altered input uses a new request. Current Manager-only access permits inspection, not issuance.

For example, an approved PKR 1,000 increase allocated as PKR 600 at 10% and PKR 400 at 20% produces a PKR 1,140 supplementary invoice. It does not rebill the original amount. Any available same-company PKR client credit settles the new invoice through the separately numbered CCA application mechanism introduced in PR #223; it does not change the supplementary gross or create another tax credit note.

## Retain actual manual WHT

The optional signed manual WHT amount and actual certificate reference already entered by Accounts and approved with the preparation are retained atomically when the related credit note or supplementary invoice is issued. They are never calculated from quote percentages, inherited as automatic reversal, inferred from a receipt or entered by the issuer without a new approved preparation. A negative signed amount remains the explicitly entered negative amount; its financial meaning is not silently inferred.

This is an immutable manual tax-evidence register. It creates no payment claim, bank/cash receipt, invoice balance credit or automatic WHT reversal. The gross credit/debit calculation and client-credit split/application are unchanged by this evidence. Operational WHT settlement, broader tax accounting and reconciliation remain separate development; this increment must not be described as that work being complete.

## Inspect evidence and preserve history

Under BOQ adjustments or Billing, select **Load supplementary invoices and WHT evidence**, then **Export supplementary invoice and WHT ledger CSV**. The view and export distinguish issued supplementary invoices from manual tax evidence, and retain actual issuer/recorder accounts and server times. Accounts and explicitly designated Managers receive private approval/posting receipts. Active clients receive only their own company's necessary commercial invoice/tax evidence, with no private approval designation, payment proofs or internal quote costs. Account, company and permissions changes, parent blocking and failed reads clear old evidence/export; late reads cannot restore another scope.

Issued original/supplementary headers, lines, project attribution, posting receipts and WHT evidence cannot be changed or deleted through legacy actions. Corrections require separately supported adjustment/reconciliation workflows. No staff, Manager designation, bank instructions, business fixture or actual document is seeded.

## Precise remaining work

Keep both PRs unmerged and migrations 142/143 unapplied until the grouped release. Before that release, verify the stacked source, ordered schema preflight, access/immutability checks, preview build and exact production deployment/assets. Signed-in workflow/export/device acceptance belongs to the client and remains pending.

Next confirmed development: requested cash refunds with actual client request and Owner/Director approval; no-payment cancellation/rebilling retaining the original as Cancelled; partial/multi-invoice and legacy-credit reconciliation. Manual WHT financial settlement/broader tax accounting remains open. PM/Operations Manager started-work changes, removal/return/replacement execution and final Admin adoption remain separate. Catalogue remains 50 open packages (six in progress, 44 not started), eight development complete; all 41 acceptance items pending.

Prepared follow-up: [actual client refund request and Owner/Director approval](client-refund-approval-guide.md). This follow-up records approval only; cash payout/client-credit accounting remains separate.
