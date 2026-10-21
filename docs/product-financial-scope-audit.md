# Product financial scope audit — 20 October 2026

This bounded audit compares the uploaded original specification Module 4 pages 26–27 with current main after PR #209/#210. The document is requirements evidence, not an instruction to activate policies or change unrelated repositories. The retained uploaded PDF has SHA256 `0baf0da734c6c0c659ca583bdea2275d5e3a25c07060ff9e53c3176735da08c4`.

The specification asks for project/product profitability and category budgets/actuals. These broader outcomes are not established by completing cost-allocation screens.

| Area | Current authoritative source | Remaining boundary |
|---|---|---|
| Project expense classification | `finance_expense_product_report`, migration 079 | Existing Approved project expenses, frozen applied splits and explicit remainder; not vendor inventory liabilities |
| Saved hourly labour classification | `finance_labour_product_report`, migration 082 | Actual saved cost/Approved activity; no salary or new rounding/break policy |
| Net-stock classification | `finance_stock_product_report`, migration 085 | Existing project-wide net non-returnable stock cost; inventory is not frozen; vendor purchase liabilities are not additional issued-stock costs |
| Office classification | `finance_office_product_report`, migration 136 | Original Office expense appears once; manual frozen target splits do not post new project costs or distribute the remainder |
| Consolidated inspection gap | New read-only `finance_classified_cost_register`, migration 137 | Composes these reports in one statement snapshot; keeps subtotals by family, never adds project recorded totals or vendor liabilities again |
| Original operative contract | `crm_sales`, original accepted publication/budget and current `project_financials` | Product-level mapping and a bounded reference presentation still need inspection; do not infer attribution from current mutable BOQ wording |
| Accepted additional quoted amounts | `accepted_contract_reference`, migration 076 | Explicitly reference-only, counted once per eligible offer; not adopted operative revenue, tax accounting or invoice amounts due |
| Broader product profitability | Not completed by this register | Source completeness, attribution and operative revenue/cost treatment must remain explicit; no automatic distribution or profit policy is introduced |

The released bounded increment is a read-only source register, not a new cost-recognition or revenue model. It preserves each existing family report's eligibility, amounts, application state and frozen lines. Source IDs are scoped by family; Office/project expense scopes are disjoint within one database statement snapshot, including when an expense changes its source project. Office target project identities remain distinct from the source scope. New wrapper uses invoker rights, existing active Accounts/Admin checks and revoked anonymous execute; no new table/role grant or privileged source helper is introduced.

DEV-042 remains in progress. After this register is released, inspect original accepted quotation item/budget/workstream mapping for a bounded product-revenue reference without promoting accepted additional proposals into operative revenue. Keep current separate cost-family basis and missing-source limits explicit. Do not calculate profit by blindly adding existing project totals, purchase liabilities, stock costs and Office target splits.

BOQ DEV-028 financial/execution adoption remains paused for actual client invoice/rebilling, paid amount/refund, tax/WHT, started/completed-work and approval-role decisions. Generic Proceed supplies none. Catalogue remains 50 open packages (six in progress, 44 not started), eight development-complete; all 41 client-owned acceptance items pending. This audit does not close DEV-042 or claim Finance, training or CRM complete.

Release verified: PR #211, migration 20261020160829 applied once, 7,965 checks/143 suites, TypeScript/build and exact READY production dpl_9KiLPesQQMeKLNiUsbYDLUpeF13L. Both requirement documents retain the precise release evidence and next resume point. DEV-042 remains in progress; client acceptance pending.


## Original accepted product mapping audit

The migration-016 publication generator writes client items containing product wording, description, unit, quantity, unit price and total, with no stable source/product IDs. It separately freezes the internal lines (including actual line/product IDs and frozen product_name), original quote and calculation into crm_quote_budgets. Conversion copies that snapshot into crm_sales.planned_budget and creates workstreams with explicit original sale/project/product identities. No current migration rewrites the original sale budget. A positional or label-only match is insufficient by itself.

Bounded next reference: verify matching original Accepted sale/publication/company/deal/currency/total; reconcile actual item amounts to original subtotal; require matching frozen budget/sale copy, original quote identity/currency and calculation client/internal arrays; reproduce the existing migration-016 publication items exactly before using stable frozen line/product identities and original-sale workstreams. This reuses the documented existing publication calculation, not a new price/rounding policy. No mutable quote line or current board label supplies attribution. Missing/ambiguous evidence remains unattributed, and unavailable/unreconciled original items remain unknown. Commercial adjustments are never auto-distributed. No private unit cost/margin/vendor snapshot is exported.

Only new 138_original_product_revenue_reference.sql is proposed for this read-only Accounts/Admin source report. It does not promote migration-076 accepted additional references to operative revenue or implement profit. After release, reconcile remaining DEV-042 original/workbook coverage and explicitly identify operative distribution/revenue-policy boundaries before any package completion claim. All 41 client-owned acceptance items remain pending.

Original reference release verified: PR #213, only new migration 138 as 20261020163407 once; clean-source 8,071 checks/144 suites, TypeScript/build, live missing-account/access guard and exact application production dpl_5ddWtwu7SJ6vDzUNAtAP3FMBvwXN READY/served assets verified. Frozen original mapping/reference is released; preceding proposal/next-reference wording describes the pre-release audit. Next reconcile remaining DEV-042 scope and stable-workstream revenue/cost coverage, preserving separate cost families and all unmatched/unattributed amounts. Broader operative distribution/product financials and client acceptance remain pending. Both requirements retain the complete verification history and precise resume point.


## Stable identity coverage audit — 21 October 2026

The remaining independent read-only gap is a stable-workstream/product coverage comparison between the original accepted reference and current classified-cost evidence. Match exact workstream/product/frozen target-project IDs, never mutable names. Preserve original-only/cost-only identities, all original items and cost segments. Use existence checks rather than a join that fans out cost splits across repeated original item rows.

Project-source Expense/Labour/Stock scope is each actual source project. General Office sources can span target projects; selected-project coverage includes only eligible frozen slices for that target, counted once per source. Original source amount, other targets and General office remainder remain excluded context. A stale Office source with no eligible current target slice stays in its General office register, not silently promoted into project evidence. No recorded project total, purchase liability, cash or combined profit is added.

New migration 139 proposes an invoker/STABLE composition of the existing guarded reports, with current Accounts/Admin authority and one read snapshot. Current source families, original frozen mapping, unknown evidence, adjustments, stale/withdrawn states and negative remainders remain authoritative. This covers evidence comparison, not operative financial treatment. Broader product profitability/Office operative distribution and source completeness remain pending; DEV-042 stays in progress until remaining original/workbook scope is reconciled explicitly. BOQ adoption remains paused for actual client decisions, and all 41 client acceptance items remain pending.
