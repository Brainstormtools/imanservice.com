# Sales List, first-response timer and weighted forecast

This increment is prepared for tested PR/merge and production release. Do not infer live release or client acceptance until the verified release checkpoint is recorded in the requirement documents.

## List controls

Open Product sales boards and choose List. Existing board/search/stage/owner/source/attention filters still apply. **List columns, sorting and additional filters** adds created-from/to UTC dates (inclusive whole days), one complete tag (case-insensitive), estimated-value minimum/maximum and currency. Value bounds apply per row in that row's currency; choose one currency when comparing like amounts. Invalid ranges show an error and select/export no rows. No currency conversion is assumed.

Choose visible columns or click a column heading to sort ascending/descending. Name stays visible so records can still be opened. Missing values sort last. **Export visible columns** follows the visible columns and filtered sorted rows; **Export selected rows** includes only selected rows that are still visible. **Select filtered rows** selects only current filtered records; changing filters never makes hidden selections eligible for a bulk change. Existing saved views include the new List options; older saved views still load with their original filters.

Sales users can edit an open authorized deal's estimated value and follow-up directly in its row. The current deal version, stage, actual meeting and loss fields are retained; existing server stage and quotation prerequisites still apply. No change bypasses Won conversion or reopens a closed deal.

## Explicit bulk changes

Select actual visible deals, choose one action, enter actual values and a reason, then review the named records and confirm. Up to 100 open deals save in one transaction; one stale deal/lead, revoked permission or missing stage prerequisite rejects the entire selection. The reviewed record/version snapshots stay frozen until cancelled or submitted; refresh and prepare again after a conflict.

Only Admin/Sales Manager may reassign commercial ownership. The target must be an actual active sales account with membership in every active product board (Admin remains globally eligible). Lead and Deal owners change together; product specialist assignments are not changed.

A stage change uses the existing checked stage workflow for every selected deal. Follow-up, logged activity, value, meeting, current published quotation, configured Lost reason/explanation and accepted-quotation Won conversion rules remain applicable. Won is unavailable through bulk stage changes. Closed/converted deals and inactive product boards are rejected. Add-tag keeps existing tags, respects the existing 20-tag/40-character limits and does not duplicate an existing case-insensitive match.

A stable request ID makes an exact uncertain retry safe; changing its meaning is rejected. Actor, server time, explicit reason and before/after evidence are private and immutable. Per-deal activity records show the action/reason to currently authorized staff. No bulk configuration, owner, tag, stage or business fixture is seeded.

## First-response elapsed timer

The Raw Lead List and Kanban show elapsed calendar minutes from the actual lead creation timestamp to the first logged **Call or Meeting**. A Note, status change, assignment or imported contact does not prove a customer response and does not stop the timer. Earlier-than-creation, invalid and future activity timestamps are ignored. If no qualifying event exists, **Waiting** continues and refreshes once a minute while the page is open. Missing creation times are disclosed rather than guessed.

This is the documented measurable-event default. It does not introduce response targets, SLA breaches, working-hour calendars or notification policies. External email/SMS/WhatsApp delivery is still excluded.

## Weighted open product forecast

For the currently filtered open deals, each active product-line estimate is multiplied by the current probability of that exact product board's shared stage. Dropped products and Won/Lost deals are excluded; a selected board restricts the calculation to that board. Each board/currency is shown separately; no full Deal value is duplicated across boards and no currencies are added together.

Calculation retains exact decimal cents and percentage fractions, without an invented rounding policy. Missing/invalid amounts or probabilities are counted as excluded, not assumed. This forecast does not create a financial document, revenue recognition, budget or assignment.

## Remaining Phase 1 work

Stage-entry action configuration and actual review tasks, lead-detail private files, history-preserving product/board changes, quotation requirement-to-code/test mapping and other final SRS audit findings remain open. Calendar view is recommended in the SRS, not silently treated as mandatory closure. Actual Meta account authorization remains unavailable. All 41 client-owned live acceptance items remain pending.
