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

The next bounded increment is a read-only source register, not a new cost-recognition or revenue model. It preserves each existing family report's eligibility, amounts, application state and frozen lines. Source IDs are scoped by family; Office/project expense scopes are disjoint within one database statement snapshot, including when an expense changes its source project. Office target project identities remain distinct from the source scope. New wrapper uses invoker rights, existing active Accounts/Admin checks and revoked anonymous execute; no new table/role grant or privileged source helper is introduced.

DEV-042 remains in progress. After this register is released, inspect original accepted quotation item/budget/workstream mapping for a bounded product-revenue reference without promoting accepted additional proposals into operative revenue. Keep current separate cost-family basis and missing-source limits explicit. Do not calculate profit by blindly adding existing project totals, purchase liabilities, stock costs and Office target splits.

BOQ DEV-028 financial/execution adoption remains paused for actual client invoice/rebilling, paid amount/refund, tax/WHT, started/completed-work and approval-role decisions. Generic Proceed supplies none. Catalogue remains 50 open packages (six in progress, 44 not started), eight development-complete; all 41 client-owned acceptance items pending. This audit does not close DEV-042 or claim Finance, training or CRM complete.
