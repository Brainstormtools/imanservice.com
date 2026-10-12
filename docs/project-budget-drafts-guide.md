# Private additional-scope budget drafts

Administrator → Project configurator → Private additional-scope budget drafts.

Choose an exact client-Accepted additional BOQ offer. Currency is fixed from that source. Enter the draft title, optional internal notes and actual cost lines manually: existing quotation block (Material, Labour, Inventory or TADA), description, unit, positive quantity and nonnegative planned unit cost. No quantity, rate, cost block, salary, tax or reviewer is prefilled. Explicit zero cost is accepted when the administrator intentionally records it; unknown values should not be represented as an inferred zero.

Save with a reason. The server rounds each quantity × unit-cost amount, sums the draft and existing block totals, freezes the exact accepted source and original conversion budget, and records the actual actor/time. A source has one versioned draft. Revisions require the displayed current version and a new reason; every before/after record is retained. Exact creation/revision retries return the same ID, including a delayed creation retry after later draft revisions; changed/stale retries cannot revert current costs or duplicate a proposal. Failed saves keep entered fields. Refresh reloads access and discards the current editor.

The private register exposes current cost lines/totals, original baseline/source and reasoned revision history. Its CSV contains only the administrator-visible cost drafts and actual creators/reasons. Clients, assigned managers, workers and disabled/anonymous users have no access to these new cost tables or controls.

This bounded increment records **unreleased cost drafts**. It does not review/release a budget, allocate money, change the original sale/budget, change supplier approval limits/material-request generation, calculate operative project profit, issue invoices, change salaries or alter client-approved selling scope. Tax/charge treatment, catalogue/product allocation, review/release and integration with finance/procurement consumers remain pending DEV-029 work. The client owns actual signed-in/browser/download/device acceptance.
