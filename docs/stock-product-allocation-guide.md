# Private net-stock product allocation drafts

Accounts/administrator → Finance → Expenses → Private stock cost product allocation drafts.

Choose a positive net-stock source for an existing PKR project. It uses the existing financial report basis: non-returnable Issue costs minus Site return credits, rounded once across the entire project. Tool custody and purchase/receipt/bill/transfer values are excluded. Per-row quantity/unit/rate and source issue/return links remain frozen in the source JSON; different item units are not combined into a single quantity.

Manually choose existing same-project product workstreams, enter actual positive amounts up to two decimals and provide an actual reason. New inputs are blank. One row per workstream; totals cannot exceed the current net source cost. Partial allocation leaves an explicit unallocated remainder. One versioned proposal exists per project pool. No rate, quantity, percentage, distribution weight or assignment is supplied automatically.

A new issue/return or changed source evidence changes the fingerprint. Refresh and deliberately revise the split amounts with a new reason; the server will not proportionally rebase them. Zero/nonpositive pools cannot take positive allocations. Source freshness is checked against the observed snapshot during save; concurrent/later stock changes can make it stale immediately. The draft does not lock inventory against later movements. Future review/application will need current-source revalidation.

Inspect frozen amounts/splits and export scoped current or immutable revision-history CSV. Full ledger, item/unit/tracking and source-document provenance plus actual actor/time/reason are retained. Unchanged retries preserve identity while the source still matches; stale/changed fingerprints require refresh. Read/permission changes clear private state; refresh closes unsaved editors. Only active Accounts/admin can access these drafts. They do not review/apply classification, move stock, add costs again, pay cash or assign work. Stock review/application/reporting and office distribution remain later increments; client live acceptance remains pending.
