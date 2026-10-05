# CRM acceptance checklist

Source: IMAN CRM Developer Spec dated 5 October 2026. Target: website repository and `/portal`. External email, SMS and WhatsApp delivery excluded. Native mobile app deferred as specified. A source implementation, a passing unit test and a visible export button are not sufficient evidence of complete live acceptance.

Acceptance for each item: specification fields; workflow transitions and history; validation; database and API authorization; administrator, staff and client visibility as applicable; responsive usability; exports where required; recorded tests and live evidence. Mark blocked browser checks pending.

| ID | Page or module | Status |
|---|---|---|
| 01 | Dashboard | Partial |
| 02 | Clients and contacts | Partial |
| 03 | Projects | Partial |
| 04 | Project tasks | Partial |
| 05 | Project milestones | Partial |
| 06 | Project files and discussion | Live role verification pending |
| 07 | My tasks and calendar | Partial |
| 08 | Estimates and proposals | Partial |
| 09 | Contract documents | Partial |
| 10 | Orders and catalogue | Partial |
| 11 | Invoices and payments | Partial |
| 12 | Client sites | Partial |
| 13 | IT assets | Partial |
| 14 | AMC and SLA | Partial |
| 15 | AMC renewals | Partial |
| 16 | Maintenance visits | Partial |
| 17 | Preventive maintenance | Partial |
| 18 | Network audits | Partial |
| 19 | Support and SLA | Partial |
| 20 | Reports | Partial; live downloads pending |
| 21 | Notifications | Partial |
| 22 | Attendance | Partial |
| 23 | Clients and team access | Partial |
| 24 | Raw Lead Board | Core implemented; acceptance partial |
| 25 | Product sales boards | Core implemented; acceptance partial |
| 26 | Deal detail | Core implemented; acceptance partial |
| 27 | Won conversion | Core implemented; acceptance partial |
| 28 | Project Configurator | Template planning implemented; acceptance partial |
| 29 | Execution and handover | Nodes, punch, phases and electronic handover implemented; live walkthrough pending |
| 30 | Supply Chain | Core request-to-delivery implemented; acceptance partial |
| 31 | Payables and expenses | Matched payables and approved expenses implemented; acceptance partial |
| 32 | Loans and advances | Separate principal ledgers implemented; acceptance partial |
| 33 | Project Financials | Recorded costs, invoices and cash implemented; provisional labour and acceptance pending |
| 34 | Daily activity log | Missing |
| 35 | HR performance | Missing |
| 36 | Administration configuration | Foundation implemented; acceptance partial |
| 37 | PWA | Missing |
| 38 | Shared customer timeline | Foundation implemented; acceptance partial |
| 39 | Department roles and teams | Foundation implemented; acceptance partial |
| 40 | Design system alignment | Partial |
| 41 | End-to-end live acceptance | Blocked by browser runtime |

The first audit listed 37 page/module rows. Items 38–41 make the shared customer, permissions, design and live verification requirements explicit to keep the agreed total of 41 auditable.

## Existing evidence

599 automated checks across 22 suites passed for the existing portal. Production migrations 012 and 013 applied. Transactional live database checks passed for assignment, mutation denial, submit, publish, confirm and revocation; test records rolled back. Administrator dashboard, four reminders and report tables observed live. Browser download attempt and technician/client walkthrough blocked by native credential runtime protection. These results do not establish acceptance of missing modules.

## Implementation order

1. Shared customer history, department roles, teams and configuration.
2. Lead intake, six sales boards, multi-product deals and quotation/BOQ.
3. Atomic Won conversion, configurator and phases 0–5 execution.
4. Supply chain and full finance.
5. Help desk, activity logs, attendance and performance.
6. Reporting, design, PWA and all live acceptance evidence.

## Foundation increment

Migration 014 adds audited teams, department memberships, twelve role definitions and versioned shared categories. Staff capability resolution is limited to the current active account. Customer history uses security-invoker queries so assignment, publication and commercial policies remain enforced. New department permissions do not grant legacy administrator powers. CRM configuration is administrator-only; Customer history is visible to authorized staff and administrators. Leads, deals, stock, HR and finance expansion remain pending.

## Sales intake increment

Migration 015 adds manual and mapped CSV/XLSX intake, contact deduplication, six configurable boards, shared multi-product deals, board membership policies, checked stage transitions, section ownership, activity history, saved filters and CSV exports. Follow-ups use portal reminders; lost deals create dated re-engagement tasks. 676 automated checks across 24 suites, TypeScript and production build passed before release. Board revocation also removes assigned contact and reminder access.

Sales acceptance remains partial. Website/Meta/API intake, routing automation and atomic Won conversion remain pending. The subsequent quotation increment releases proposal/negotiation only with a current published quotation. Won remains blocked. Live browser verification remains blocked by the protected browser runtime.

## Quotation increment

Migration 016 adds a cost catalogue, administrator-defined gross-margin slabs, product-section BOQ edits, material/labour/inventory/TADA costs, returnable tools, fuel/crew planning, explicit service tax bases, WHT withholding, bank charges, contingency and final-price overrides. Separate client publication resources exclude cost, vendor, internal labour and travel data. Every publication has an immutable revision and private budget snapshot. Client acceptance chooses one solution and locks its budget and product scope. Proposal/negotiation require a current published quotation; Won remains gated pending template-backed conversion.

721 automated checks across 25 suites passed, plus TypeScript and production build. A 90-row quotation PDF was verified across six pages with the final row, terms and private-data exclusion. Database tests cover stale versions, wrong-company decisions, specialist edits, board revocation, cost privacy, NaN/zero rejection, server fuel calculation and margin configuration. Live browser acceptance remains pending; this increment does not establish acceptance of all 41 items.

## Project planning and Won increment

Migration 017 adds versioned product templates, bounded quantity formulas, site factors, crew-based man-hours, checklists, tools, readiness notes and predecessor validation. Template edits preserve existing project plans. Atomic conversion requires the accepted quotation, current templates for all active project products and valid payment/SLA terms. It creates one sale, one mixed-product project with workstreams and phases 0–5, an optional support contract and the first draft invoice, or a contract without a project for SLA-only deals. Invoice lines preserve the services tax basis. Repeat conversion returns the existing sale; converted deals cannot reopen. Assigned project managers can read their saved budget, and revocation removes access.

Validation: 761 checks across 26 suites, TypeScript and production build. Coverage includes failed preflight, late invoice failure with rollback, duplicate retry, stale templates, immutable live plans, wrong-client access, budget revocation and SLA-only monthly invoices. Production transactional verification and browser acceptance are separate release checks.

Configurator acceptance remains partial: a standalone task library, node-list import, project-specific plan edits, resource allocation, actual-time learning and phase execution gates are pending. Later scheduled payment drafts, Accounts routing and customer creation during conversion remain pending; this flow uses the customer already linked to the accepted quotation. Generated task dates are an initial sequential schedule for manager review. No templates are activated automatically; administrators must enter and approve their standards.

## Node execution and phase review increment

Migration 018 adds project-scoped node registers, mapped CSV/XLSX import with atomic validation and batch idempotency, six quality checks with server-attributed identity/time and evidence, administrator publication/return, punch findings and reviewed closure, ordered phase review gates and scoped progress. Task-only technicians cannot read or alter nodes belonging to other tasks, including published nodes. Clients see only published results for their company. Submitted punch corrections are hidden until review. Node registers lock when phase review starts. Phase review requires prior phase publication, reviewed Pass checks, approved planned-task completion and evidence; phase 5 also requires all punch items closed. Internal task approval completes generated internal work without exposing its records or files. Execution exports use authorized records and published quality results. The screen loads on demand.

799 checks across 27 suites, TypeScript and production build passed. Coverage includes wrong task/project access, private draft results, import rollback/retry, actor history, private internal-task evidence, phase ordering, incomplete phase gates and reviewed punch closure. Live browser checks remain pending. Contractor/consultant/client handover signatures, stored signed PDFs and final project closure will be implemented separately; phase publication does not close the project.


## Handover and closure increment

Migration 019 adds immutable handover revisions released by an administrator after all six phases, reviewed Pass device checks, approved planned-task checklists and closed punch findings. Three distinct active designated accounts record their own authenticated electronic sign-off (contractor, consultant and client), with account/name/consent/time and the fixed scope hash. Change requests stop signing; cancellation retains history and replacement revisions need fresh signatures. Execution records and project identity lock while a revision is released or closed.

Administrator PDF review/archive stores immutable certificate bytes and their SHA-256 hash. The archive validates the current signed revision marker and rechecks readiness and signer access. PDF storage and project closure commit atomically; direct completion/reopening bypasses are blocked. Own-company clients download the original stored certificate through a checked function and verify its hash. Linked draft support contracts start at handover, preserving their duration, and are linked to the closed project. Portal-only signature reminders respect opt-out. Signatures are authenticated portal sign-off, without an external certificate/signature provider.

841 automated checks across 28 suites, TypeScript and production build passed. Tests cover assignment/company boundaries, explicit consent, impersonation, stale versions, changes/cancellation, revoked signers, wrong certificates, direct completion, immutable closure, download integrity and linked support activation. An eight-page certificate with 75 devices was rendered and visually checked. Browser role walkthrough and full 41-item CRM acceptance remain pending.

Migration 019 applied to production. Transactional live checks passed for own-account signatures, impersonation denial, atomic PDF archive/closure, certificate integrity and other-company download denial; temporary records rolled back. Security advisors retain the existing authenticated checked-function/password-protection notices; the certificate byte table intentionally has no direct Data API grants or policies.

Migration 020 checks both the source and destination when moving execution records, preventing reassignment from evading the signed scope lock.


## Supply chain core increment

Migration 021 connects shared quotation catalogue items, assessed vendors and stock locations to project/task or office MRs, stock reservations, shortfall PRs, RFQ comparison, separate PO approval, inbound tracking, IGP/QC/GRN records, partial/rejected receipts, material issue value approval, DC/OGP dispatch, authenticated site receiving and documented returns. All documents have linked numbers and immutable actor history. Serial receipts/issues/returns preserve unit custody. Returnable items require an accountable person and due date; project closure waits for open requests and tool check-in.

On hand and valuation are ledger sums. Available stock subtracts reservations. Accepted receipts reserve stock for their MR; issues charge weighted-average material cost to projects and site returns credit the original issue cost. Transfers preserve total valuation. Physical counts need separate administrator approval, reject stale balances and cannot consume reserved quantities. Used item units and tracking types are fixed across both inventory and quotation editing. Supply valuation is PKR; projects in another currency are blocked pending currency-aware purchasing.

Department permission checks and RLS keep purchase/valuation documents private. Task-only technicians bind requests to assigned tasks and use a sanitized receiving view. Revocation removes access. Requesters cannot approve their own PRs, PO creators cannot approve or receive their own PO, and logistics permission alone does not grant site receiving authority. Budget approval checks serialize on the project. Project overruns require distinct PM and administrator steps. Vendor-count, amount thresholds and price-jump controls are versioned administrator settings; zero approval thresholds require an administrator. No external vendor messaging occurs.

The menu provides Requests, Stock, Sourcing, Purchase Orders, Inbound, Outbound, Returns, Vendors and Reports, with department starting queues, structured multi-item requests, PO PDFs and stock/report CSV/PDF exports. Explicit accepted-BOQ request creation is idempotent and requires all accepted material lines already mapped to active catalogue items. Existing project permissions are not expanded by supply roles.

Supply-chain acceptance remains partial: automatic go-live BOQ requests and mapping of legacy unmapped accepted lines, reorder-generated PRs, rate contracts, multi-line PO headers/amendments, standalone logistics/inspection approvals, direct-to-site combined receipt/issue, vendor RMA/debit-note execution and store sales are pending. Three-way vendor bill matching and payables follow in the finance increment. Full project financials and browser role/download walkthrough remain pending.

903 checks across 29 suites, TypeScript and the production build passed. Migration 021 applied to production. A live rollback transaction verified stock-first shortfall sourcing, separate approval and receipt actors, partial/rejected GRNs, weighted-average valuation, issue/delivery, return credit and client isolation; all temporary records and role assignments were rolled back. Browser walkthrough remains pending.


## Vendor bills and payables increment

Migration 022 links PKR material-only vendor invoices to an approved PO and selected accepted GRN quantities. Exact PO rate, approved ordered quantity and net accepted receipt allocations are checked under a PO lock. Rejected and returned quantities cannot be paid, and matched receipts cannot be invoiced twice. Mismatches remain Held for Purchase to review and Accounts to revise. Vendor invoice numbers and payment references are normalized for duplicate prevention. Matched bills require a separate administrator from both the creator and matcher; the approver cannot record the payment. Direct bill, allocation, payment and history writes are denied.

Accounts records full or partial payments already made, with business date, method, reference and evidence document reference. No bank transfer or external message is initiated. Outstanding balances use unreversed payments, payment retries use the current bill version, and payments cannot exceed the balance or be future dated. A separate administrator can record a reasoned reversal while retaining the original payment and evidence. Cancellation requires an unpaid bill. Vendor returns cannot invalidate quantities committed to matched or approved bills; paid-return credit notes are pending.

Finance navigation and the lazy-loaded screen provide an Accounts overview, held/matched/approved bill queues, invoice revision and GRN allocation, payment/reversal history, payable schedule and vendor statements with CSV/PDF exports. Purchase can inspect bill mismatches but cannot certify the match, approve bills, read payment evidence or make payments. Clients, technicians, disabled accounts and anonymous callers cannot access payables. Report aging uses the Asia/Karachi business date and buckets Current, 1–30, 31–60, 61–90 and 90+. Held/draft/cancelled amounts are excluded from approved outstanding and overdue totals. Project/vendor identities are separate fields.

975 automated checks across 30 suites, TypeScript and the production build passed. A five-page 52-row statement layout was rendered and visually checked, including repeated headers and normal body rows after page breaks. Migration 022 applied to production. A live transaction verified held/corrected matching, duplicate GRN denial, separate approval, partial/full payment, reversal, billed-return protection and client/Purchase isolation; all temporary records and memberships rolled back. Security advisor categories remain the existing checked-function, intentionally private-table and password-protection notices.

Payables/finance acceptance remains partial: tax/charge invoice components, evidence file uploads (current evidence is a document reference), supplier advances, credit/debit notes, expense approval/ledger, loans/advances, bank reconciliation, project financials, combined receivable/payable cash flow and one-time opening-balance imports are pending. Browser role/download walkthrough and full 41-item acceptance remain pending.


## Expenses, loans/advances and recorded project financials increment

Migration 023 adds configured expense categories, project/task-scoped or authorized office expenses, immutable submitted/approved details, administrator approval/rejection separate from the requester, bounded partial/full expense payments and documented separate-actor reversals. Task-only staff bind expenses to their assigned task; revocation removes access to both records and history. Accounts can route office/project expenses. Vendor-linked invoice references are checked in both expense and purchase entry points under a vendor lock to prevent the same invoice being recorded twice. Evidence currently uses a document reference; file upload remains pending.

Loans Given, Loans Taken and Staff advances have a separate approved principal ledger with a staff recipient or lender/borrower, project link, agreement, due date, terms and evidence reference. Draws cannot exceed the approved principal and repayments cannot exceed the disbursed outstanding. Server code derives cash direction, requires chronological entries and prevents reversals from leaving a repayment without prior funding, even if the final balance would be positive. Approvers cannot record cash for their own approved record. Original cash and audit history remain intact after reversal. Loan/advance balances and cash are excluded from customer receivables, trade payables and project expense costs.

Accounts has company finance totals, customer receivables separated by currency, vendor/expense payables, net PKR trade position, separate principal outstanding and monthly recorded cash movements. Assigned project managers have checked project reports only; clients and technicians cannot see internal profitability or company ledgers. Explicit customer-and-currency-checked invoice links supplement automatic Sale/order and recurring invoice links. Links cannot move an invoice to a different project and repeat links are idempotent.

Project Financials appears in the project tab and Finance workspace, with CSV/PDF exports. It combines accepted Sale/BOQ values, linked issued invoices, verified collections and credits, purchase commitments, vendor bill liabilities, net non-returnable stock issues/site returns, approved additional expenses, and separate supplier/expense/loan cash. Material vendor bills are shown as purchase liabilities and not added again to issued material cost. Returnable tool custody is excluded from consumed material. Missing accepted contract/budget values remain unknown. Remaining cost, utilisation and profitability explicitly refer to recorded costs; hourly labour, other unrecorded costs, tax treatment, released/revised budgets, product allocations and final profitability remain pending. This is a provisional recorded-cost view, not final project P&L acceptance.

The prior Vendor Payables menu routing gap is fixed. Integration tests now click actual portal navigation into Vendor Payables, Accounts Finance and the project Financials tab. Administration configuration filters category arrays instead of treating the supply control object as category options. The finance workspace and reports load on demand.

1061 automated checks across 31 functional suites, TypeScript and production build passed. A three-page project financials export was rendered and visually checked, including continued tables and the report-basis note. Migration 023 applied to production. Live rollback checks passed for assigned expense submission, separate approval/payment/reversal, separate given/taken principal, project invoice/collection totals, unknown legacy revenue, client/technician isolation and assignment revocation; all temporary records and memberships rolled back. Advisor categories remain the existing checked-function, intentionally private-table and password-protection notices.

Finance acceptance remains partial: hourly labour from approved activity logs, released/revised budgets, product allocations, evidence uploads, staff advance settlement against expenses/payroll, interest, tax/charge handling, supplier credit/debit notes, bank reconciliation and opening-balance imports remain pending. Full browser role/download walkthrough and 41-item acceptance remain pending. Next is the daily activity log and approved hourly project costing, followed by HR performance/payout summaries.
