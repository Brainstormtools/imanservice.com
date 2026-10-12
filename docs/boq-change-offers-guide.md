# Additional BOQ change offers

Additional-item offers on an existing converted project support existing workstreams and active new project products, frozen client approval and separately created fixed invoice drafts. The original accepted quotation stays intact. Reviewed new-product workstream application is available as a separate action below. Reviewed additional-task extensions for existing workstreams are available as a separate action below. Replacing/removing original items, adopting dropped products and updating budgets/contracts remain pending development.

## Manager: prepare a draft

Open **Project configurator → Project BOQ change offers → New additional BOQ offer**. Select an existing Approved internal change request for a converted project.

| Field | Who enters it | Meaning |
|---|---|---|
| Approved internal change request | Manager/admin | The existing approved scope request authorizing preparation of this offer. |
| Currency | System | Fixed to the original converted sale; not a new currency choice. |
| Offer title | Manager/admin | A clear client-visible title for the additional scope. |
| Valid until | Manager/admin | Last business date on which the open offer can be approved. |
| Existing product workstream or new project product | Manager/admin | Choose an existing workstream in this project, or an active new Project product without a workstream here. |
| Description and unit | Manager/admin | Exactly what extra item/work is offered and how it is measured. |
| Additional quantity and selling unit price | Manager/admin | Positive explicit values for the additional items, not replacements for original lines. |
| PRA services tax %, taxable services amount and WHT % | Manager/admin | Actual applicable values. Enter 0 explicitly when none applies; the portal does not select the rate for you. |
| Terms | Manager/admin | The client-visible terms for this offer. |
| Draft revision reason | Manager/admin | Internal explanation retained in history; not shared with the client. |
| Offer number and history identity/time | System | Generated reference and authenticated audit evidence. |

Add more items as needed (up to 100). Use distinct item descriptions/units within the selected product scope; combine the quantity instead of duplicating the same item. Save the draft. Failed saves keep your entered fields for correction/retry. Refresh discards the current editor and reloads current access/data.

The server calculates each additional line amount, subtotal, tax, total, WHT and net payment. Taxable services amount cannot exceed the additional subtotal. Selling prices are entered explicitly; this increment does not expose private original costs or calculate a new project budget/profit.

## Administrator: publish or withdraw

Review the exact draft items, prices, tax inputs and client-visible terms. Tick the review acknowledgement, enter an internal publication reason and select **Publish BOQ offer to client portal**. Only the latest draft for a request can be published.

Publishing freezes that offer. To correct an open offer, create a new draft linked to the same Approved request and publish it; the earlier open publication becomes Superseded. Every draft/publication/history record remains. An administrator can withdraw an open publication with a client-visible reason. An Accepted offer cannot be withdrawn, edited or superseded; further scope needs a new internal request.

## Client: approve or decline

Open **My quotations → My BOQ change offers**. Review the additional items, totals, validity and terms. Choose Approve or Decline explicitly. Approval requires the consent checkbox. Decline requires a reason. Submit the decision; the portal records the actual account, time and exact offer version.

Only active clients of the same company can decide. Expired, superseded, withdrawn or already decided offers cannot receive a new decision. A manager/administrator cannot approve on behalf of the client through this workflow.

The displayed offer can be downloaded as PDF; a summary CSV is available. These exports contain public offer content, not internal draft reasons, request evidence or original private costs. Actual browser/download/device acceptance is performed by the client's team.

## What the recorded approval means

It records approval of this exact additional BOQ offer. It does not silently update the original quotation, project budget, contract, tasks, stock requests or invoice. Those changes must use their separately developed, controlled application workflows. Completed projects and released handovers block new drafts, publication and client decisions; administrator withdrawal remains available for an obsolete open offer. No external email/SMS/WhatsApp is sent.

## Invoice drafts from accepted additional offers

In Project BOQ change offers, an administrator opens an **Accepted** offer and enters the invoice date, due date, actual bank transfer instructions and internal reason. Create accepted BOQ invoice draft creates one Draft invoice linked to that exact client-approved publication and project finance view. The original sale, budget and invoice stay unchanged. Managers see only the linked invoice number/status/dates/amount; clients see the link only after issuance.

The accepted gross subtotal, explicit service-tax basis/rate and gross total are fixed. Invoice lines summarize the scope outside that tax basis and taxable services; they do not guess a tax allocation for individual BOQ items. The accepted offer remains the itemized scope and complete commercial terms. Large amounts split into exact summary buckets within existing invoice-line limits. WHT is referenced in invoice notes but creates no receipt, credit or automatic net settlement; recording/reconciling withholding remains a separate finance gap.

While Draft, the administrator may use **Save draft payment details** here to change only due date and bank instructions with a reason. The previous/current values, actor and time are retained privately. Concurrent stale revisions require Refresh BOQ offers. Failed actions retain the entered fields. Generic invoice editing cannot alter the source, amount or items. Go to **Invoices** to issue or void using the existing controls. Creating a draft does not issue it or send a message. A repeated identical creation returns the existing invoice; a voided source cannot automatically generate a replacement. Replacement/rebilling is a separate pending workflow.

Client live acceptance: approve an actual agreed offer; ask the administrator to create and issue its invoice; confirm the issued invoice and source reference under the correct client company, amounts, bank instructions and exports. The client owns these signed-in/browser/device checks; automated development checks do not mark them passed.

## Adding a new project product after Won

Each additional item now lets the manager choose either an existing project workstream or an active new project product. New choices come from the configured project-product boards; inactive products, contract products and products with an existing workstream in that project are excluded. Enter description, unit, positive quantity and selling price manually, together with the offer's explicit tax inputs, terms, date and reason. Mixing existing and new products in one offer is supported.

The administrator reviews and publishes the exact draft. Publication rechecks product eligibility and freezes the current product name with the itemized scope; later catalog changes do not rewrite a published or accepted offer. The client explicitly approves/declines that frozen offer. A separately created invoice draft follows the existing accepted-offer billing workflow. No new Deal is created.

Commercial publication/approval alone does not add a Deal product line, choose a template, create an executable workstream, assign people or release a budget. Use the separately reviewed workstream application below. Existing-line replacement/removal and dropped-product adoption remain pending DEV-028 work. If eligibility changes before publication, refresh and revise the draft to the current correct scope.

## Applying a reviewed new-product workstream

An accepted new-product offer now has **Accepted new-product workstreams** controls for assigned managers/administrators. Choose its frozen product name and a current active configured template, enter every parameter and the planning start date manually, and calculate the preview. Template defaults are not silently used. Review task quantities, dates, minutes, crew requirements, dependencies, checklists, tools and conditions against the accepted scope. Parameters are not inferred from commercial item quantities; reviewed mapping remains a human decision.

Only an active administrator can tick the exact-review checkbox, enter an application reason and apply. The server recomputes and compares the exact preview, checks the accepted source/current template/project/handover state, then atomically adds the new product line, workstream, internal tasks, checklists and dedicated phase milestones. The product line uses its accepted item subtotal without allocating shared tax by guesswork. Tasks are **unassigned**; manually assign people later in Tasks. Dates use the existing serial eight-hour planning convention and do not prove worker capacity or resource reservations.

Original sale, accepted budget, original workstream plans, project deadline and existing milestone dates are preserved. The new workstream has its own milestone dates. Invoice creation/issuance, budget releases and project deadline revisions remain separate actions. Frozen application receipts keep accepted source/version/consent, template/parameters/plan, actual task and milestone IDs, reason and actual actor/time. Later task revisions do not rewrite this receipt. Exact retries return the original workstream; competing/changed applications cannot duplicate it. An existing/dropped Deal product or existing project workstream requires a separate reviewed adoption/extension path; it is not silently revived.

## Adding tasks to an existing workstream

For an accepted offer containing existing-workstream items, **Accepted existing-workstream additions** offers the separate extension workflow. Choose the frozen accepted product/workstream, a current active template for that product, every explicit parameter and a manual planning start date. Review the exact calculated tasks, dates, quantities, crew requirements, dependencies and QA conditions. Only an active administrator applies the reviewed additional tasks with a reason.

Each added task has an offer-specific identity, so configured template task names can repeat without overwriting original task keys. Dependencies resolve only within that added task set; cross-links to original tasks need a separate reviewed dependency change. Multiple separately accepted offers can add task sets to the same workstream. Each offer/workstream pair applies once; retries cannot duplicate work.

Original workstream plan, original task IDs/status/assignees/dates, product-line value, sale/budget and project deadline remain intact, including already-started work. New tasks are internal and unassigned, with dedicated milestone dates. Assign people manually later. Application receipts freeze the accepted source, original workstream baseline, exact extension plan, actual task/milestone IDs and reason/actor/time. Invoice/budget releases, existing-task scope replacement/removal, dropped-product adoption, automatic rescheduling and detailed receipt history/export remain separate.
