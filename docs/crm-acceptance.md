# CRM acceptance checklist

Source: IMAN CRM Developer Spec dated 5 October 2026. Target: website repository and `/portal`. The client requires all 41 items implemented and verified before calling the portal complete. Partial releases are checkpoints. Attached workbook requirements and source issues are tracked in `workbook-requirements.md`. External email, SMS and WhatsApp delivery excluded. Native mobile app deferred as specified. A source implementation, a passing unit test and a visible export button are not sufficient evidence of complete live acceptance.

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
| 33 | Project Financials | Approved hourly labour, recorded costs, invoices and cash implemented; final costing and acceptance pending |
| 34 | Daily activity log | Assigned actuals, review and hourly costing implemented; scheduling and acceptance partial |
| 35 | HR performance | KPI scorecards, overtime, leave/balances, salary proration and configured deductions implemented; acceptance partial |
| 36 | Administration configuration | Foundation implemented; acceptance partial |
| 37 | PWA | Installation, camera capture and opt-in web push implemented; physical-device acceptance pending |
| 38 | Shared customer timeline | Foundation implemented; acceptance partial |
| 39 | Department roles and teams | Foundation implemented; acceptance partial |
| 40 | Design system alignment | Partial |
| 41 | End-to-end live acceptance | Signed-in administrator, technician and client walkthroughs pending |

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


## Daily activity and hourly labour increment

Migration 024 adds own-account Project/task, Ticket, Deal and Internal activity records with site/location, task type, given-by account, planned and actual timestamps, calculated duration, Done/Partly done/Not done/Rescheduled outcomes, completed quantity, crew context, configured delay reasons, lost minutes, blockers, remarks and evidence references. Midnight-crossing work stays on its original Asia/Karachi working date. Future, infinite, zero/overlong, overlapping and more than sixteen combined working-day hours are denied. Late planned work and lost time require a configured reason and explanation. Every crew member logs their own hours; crew size does not multiply cost.

Own drafts can be edited and submitted. A distinct administrator or currently assigned project manager reviews project/ticket work; an authorized sales manager can review accessible deal surveys. Internal work is reviewed by a distinct administrator. Rejected work can be revised; approved actuals and audit snapshots are immutable. Voiding requires a distinct administrator from both the employee and approver, a current version and a reason. Original approved cost evidence remains, while voided cost stops contributing. Assignment and disabled-account revocation remove employee/manager read access, and approval rechecks the employee's current assignment. Clients and anonymous callers have no activity or internal cost access.

Administrator-configured, effective-dated PKR hourly rates are private to Accounts/administrators. Approval requires an explicit effective rate, including an explicitly configured zero rate, and saves its hours/rate/cost snapshot. Later salary changes cannot rewrite previous approvals. Approved Project and Ticket hours feed Project Financials once, separated from material issues and additional expenses; Deal/Internal hours do not invent a project allocation. CSV/PDF project financial exports include approved hourly labour. Signed/released or completed projects cannot acquire or alter activity costs; handover readiness waits for review or cancellation of open project activity logs.

The lazy-loaded Daily activity log screen provides own work, scoped manager review and monthly team reports, activity history, CSV/PDF exports and private rate configuration. Existing shared delay reasons are reused. Actual Pakistan time is converted explicitly, and the integrated portal navigation has a click-through test.

1127 automated checks across 32 suites, TypeScript and the production build passed. A three-page 38-row activity PDF was rendered and visually checked, including repeated headers and the final row. Migration 024 applied to production. Live rollback verification passed for task-only assignment, overlap denial, cross-midnight duration, separate review, crew-independent project costs, private rates and saved cost snapshots, reasoned voiding, client isolation and assignment revocation. All temporary activity/rate/project records and memberships rolled back. Security advisor categories remain the existing intentionally private-table, authenticated checked-function and password-protection notices.

Daily activity acceptance remains partial: calendar-driven scheduled entries and planned-time prefill, team board/drag rescheduling, saved location lookup, evidence/photo uploads, connected TADA claim creation, overtime rules/approval, attendance/leave integration and configurator learning remain pending. Hourly labour is a recorded-cost allocation, not a payroll payment or assurance that all work has been logged. Profitability remains provisional for unrecorded costs, overtime premiums, tax treatment and budget revisions. HR performance/payout summaries, PWA and the full live browser acceptance review remain pending.


## Overtime, performance and reviewed salary summaries increment

Migration 025 adds immutable effective-dated role/default shift policies, grace and full-day thresholds, explicit off-days and manually confirmed holiday dates, fixed or salary-hourly overtime rates, separate off-day/holiday multipliers, five supported role-weighted KPIs and score-to-PKR bonus bands. Administrator policies require supported weights totalling 100; missing weighted evidence leaves the score, bonus and final salary summary unavailable. No shift, holiday, salary, deduction or bonus values are activated automatically.

HR configures employee salary, monthly working hours, performance-policy role and two distinct designated reviewers. Terms derive the matching effective project hourly cost rate, reject a conflicting previously configured rate and preserve all approved activity cost snapshots. Salary records are scoped to the employee, their current designated reviewers, HR and Accounts. New current reviewer assignments immediately remove the former supervisor's access, even to past summaries. Performance-role selection does not grant department permissions.

Daily calculations merge completed attendance and approved activity intervals so shared hours are counted once. Only actual worked intervals beyond shift end count on normal days; off-days/holidays count the merged recorded intervals. Overnight work stays on its start date and gaps are not invented as paid hours. Own overtime submission carries the working date; hours/rate/pay are derived on the server. A distinct designated lead or manager approves or rejects with a reason, and stale time/policy sources require rejection and resubmission. A distinct administrator can void an unlocked approved entry while keeping its history. Only approved overtime enters a monthly salary summary.

Monthly evidence includes recorded attendance, check-in-based punctuality, current outcomes of tasks due that month, approved Project/Ticket utilisation, approved activity report discipline and training hours. Unavailable task or check-in evidence is not treated as success. The highest applicable configured bonus threshold supplies the bonus. Historical on-time completion, ticket SLA/complaint KPIs and CSAT remain pending; unsupported metrics cannot silently earn a score.

HR prepares a completed-month snapshot with explicit documented deductions. Distinct designated Team lead and Manager reviews precede a separate Accounts lock; the employee can acknowledge the reviewed scorecard. Preparation/review and beneficiary/reviewer separation are enforced, current versions are required, and changed source evidence requires return and rebuild. Accounts cannot lock while score/pay is unknown or activity, attendance or recorded overtime remains unresolved. Locking freezes attendance and activity time sources for that employee/month and retains the immutable task outcomes and salary/score basis. Later salary changes do not rewrite the locked report. Every action retains actor, note and evidence history.

The lazy Overtime & performance workspace includes own overtime, designated review queues, monthly scorecards, saved daily evidence, effective private terms, administrator policies and scoped CSV/PDF salary-summary exports. Net salary is basic salary plus approved overtime and bonus minus explicit deductions. TADA outstanding is shown separately at review and stays payable in Finance; it is not counted again as salary or marked paid by this workflow. These are reviewed summaries for payroll export, not payroll execution or recorded bank transfers.

1187 automated checks across 33 suites, TypeScript and the production build passed. A three-page 44-row salary-summary PDF was rendered and visually checked, including repeated headers, unavailable values and the final row. Migration 025 applied to production. Transactional live checks verified overnight overtime, separate review, salary-to-hourly synchronization, lead/manager/Accounts monthly lock, employee acknowledgment, frozen time sources, private salary data and current-supervisor revocation; all temporary records, salary rules and memberships rolled back. Advisor categories remain the existing intentionally private-table, authenticated checked-function and password-protection notices.

HR acceptance remains partial: leave requests/balances, employment-day and salary proration, automatic absence/late deductions, percentage/project-completion bonus rules, historical on-time/SLA/CSAT metrics, scheduled payroll/advance settlement, project allocation of overtime premiums, holiday calendar feeds and full live browser acceptance remain pending. Administrators must configure their actual policies, salaries and distinct authorized reviewers. PWA remains missing; calendar scheduling, file uploads, other module gaps and all 41 live acceptance checks remain on the checklist.


## Combined trade aging and workbook comparison increment

All 63 sheets in the nine supplied workbooks were inspected read-only for fields, formulas, validations and workflows. The comparison records the existing implementation, remaining features and source issues; source balances and task standards were not imported or activated. Project workbook formula-column mismatches, dates, closure mappings and mixed trade/loan labels require review before legacy import. The full 41-item completion target remains open.

Migration 026 adds an Accounts-only current receivables/payables report from issued invoices, verified receipts and issued credits, approved vendor bills and approved expenses less unreversed payments. Draft, held, cancelled and unverified values are excluded. Loans/advances stay separate. Currency totals are never combined or converted. Five exact aging buckets, open document counts, overdue totals and overlapping due-today/7/30-day windows reconcile to document balances using the Asia/Karachi business date. It does not claim historical balances or forecast actual cash collection.

Finance navigation includes Receivables & payables, currency/direction/due-status filters, eligible document detail and scoped CSV/PDF exports. Document filters do not change clearly labelled all-record currency totals. Payment evidence is omitted. Accounts revocation, disabled accounts, clients, technicians, project managers and anonymous access are checked.

1222 checks across 33 suites, TypeScript and production build passed. A six-page 44-document PDF was visually reviewed, including repeated headers, the final row and the report basis. Migration 026 applied to production. Live rollback verification passed for receipt/credit balance calculation, reversals, due today, exact seven-day dates, currency separation, private evidence and Accounts revocation. All QA records and memberships rolled back. Browser acceptance, PWA and the other documented module gaps remain pending.


## PWA and device notifications increment

Portal-scoped installation includes 192/512 PNG icons, an explicit browser installation button and iOS instructions. A service worker stores only public icons and a generic reconnect page. Project HTML, API/authentication responses, storage objects and uploads remain network-only; unsent work is not retained offline. This is the web PWA bridge, not the deferred native offline mobile app.

Project Files & approvals now has a phone-camera capture control. It shares the existing 10 MB JPG/PNG upload pipeline, storage authorization, orphan cleanup and technician-private publication workflow. Captured evidence must be uploaded before leaving the project, then selected in the existing work completion form. No camera permission is requested automatically.

Notifications includes per-device opt-in, opt-out and unsupported-browser guidance. Browser permission is requested only on explicit opt-in. Notifications contain generic text and open the portal inbox; project, customer, contact and salary details are excluded. Subscriptions are private to the active owner, capped at five devices and expire after 30 days. Opt-out removes the subscription and closes device notifications. Account changes reconcile ownership; sign-out attempts subscription cleanup and always clears the login session.

Migration 027 adds the private subscription/lease queue. The scheduler checks active profiles, reminder preferences, unread state and current project/task/ticket/job/contract/deal visibility before claiming deliveries. Its private predicate mirrors reminder RLS from 013 and 015; permission-policy changes must update and test both. Old reminders and pre-opt-in history are excluded. A maximum of twenty deliveries is claimed per run, four provider requests run concurrently, and retries stop after three attempts. Expired provider endpoints are removed. Claims/acknowledgements require service-role authorization and matching leases. Delivery is at least once: a crash between provider acceptance and database acknowledgement can cause a duplicate generic reminder; one notification tag replaces earlier portal reminders.

Migration 028 schedules a custom-authenticated Supabase Edge Function every 15 minutes, one minute after the existing database reminder scan. The private VAPID key and scheduler credential are in Vault; only the public VAPID key is a production Vercel variable. Email, SMS and WhatsApp delivery remain excluded. A live scheduler invocation returned HTTP 200 with configured=true and zero deliveries, as no device has opted in yet. This confirms worker wiring, not receipt on a physical phone.

Physical Android/iOS installation, notification permission/delivery, actual camera capture and signed-in administrator/technician/client evidence publication walkthroughs remain pending. All other documented module gaps remain on the 41-item checklist. The current cloud browser opens the portal login page; earlier browser-runtime failures are historical and do not establish a current runtime block.

Validation: 1,277 automated checks across 35 suites, TypeScript and the production build passed. Live scheduler privilege checks confirmed authenticated and anonymous accounts cannot execute queue, acknowledgement, identity-scope, key-configuration or scheduler functions. The security advisor still reports the existing three categories: intentionally inaccessible private RLS tables, explicitly granted checked definer functions, and the previously documented leaked-password setting. No claim of full acceptance is made.

Live rollback verification also passed for assigned/unassigned reminders, assignment revocation, reminder opt-out, inactive accounts and identity restoration. All QA users, projects, subscriptions and reminders were rolled back.


## Leave requests and balances — migration 029

Employees request annual, sick, casual or unpaid leave against explicit HR allocations. Requests reserve balances; only the employee’s current designated manager can approve or reject them. Cancellation retains approved usage until reviewed. Half-day requests specify morning or afternoon, exclude holidays/off-days, and cannot overlap recorded work. Direct table writes, self-approval, stale updates and unassigned access are blocked by database permissions. Accounts sees attendance and salary basis without private leave reasons.

Approved leave excuses the appropriate attendance/reporting units; remaining half-day work is allowed only outside the approved leave interval. Pending leave decisions block monthly locking, and locked months reject backdated requests and cancellations. Balances have CSV export and changes have immutable history.

This increment completes the leave workflow implementation, not all 41 acceptance items. Employment-day/salary proration, automatic absence/late deductions, the other documented module gaps and signed-in browser/device acceptance remain pending. Full payroll processing remains outside the specification; reviewed payout summaries and exports are in scope. Administrators must enter actual entitlements and designate separate reviewers.

Validation: 1,319 checks across 36 suites, TypeScript and production build passed. Migration 029 applied to production. Live rollback verification covers balance reservation, separate manager review, private attendance classification, cancellation and half-day work. Temporary QA records are rolled back. Existing security-advisor categories remain unchanged.


## Salary proration and configured deductions — migration 030

HR confirms an employee’s actual employment start/end dates with versioned history. Administrators define immutable role/default payout policies effective from a month’s first day. No business values are activated automatically. Calendar-day proration includes employed calendar days; working-day proration uses the applicable shift’s full-month working-day count excluding confirmed holidays/off-days. Effective salary changes contribute at each day’s rate, and a mid-month hire does not require fictitious earlier salary terms. Days outside employment are excluded from attendance expectations and salary.

Automatic absence deductions use the explicit fraction, exclude approved leave, and credit recorded half-days. Unpaid leave is deducted once at the applicable daily salary rate. Configured late penalties use completed check-in evidence after the monthly allowance per payout policy; they can be a fixed PKR amount or a salary-day fraction. Missing required check-in evidence blocks Accounts locking. HR’s additional documented deductions are added to the automatic total and remain separately identifiable in the snapshot, UI and CSV export. Total deductions cannot exceed gross salary. Existing unconfigured employees retain their legacy manual basis; using the new basis requires both employment dates and an effective payout policy.

Employment changes cannot exclude recorded work or active leave and cannot alter employment-day eligibility in a locked month. New attendance, activity and leave outside configured employment are rejected. Existing separate Lead → Manager → Accounts review, stale-source detection and immutable locked snapshots remain in force. Full payroll processing and payment execution are outside scope; this is a reviewed payout summary.

Validation: 1,356 automated checks across 37 suites, TypeScript and production build passed. Migration 030 applied to production. Live rollback verification, running as authenticated staff, confirmed an explicit mid-month salary of PKR 16,000, absence/late deductions, a separate manual deduction, three distinct reviewers, net PKR 5,850, locked employment protection and employee RLS boundaries. All temporary records were rolled back. Existing advisor categories remain unchanged.

Administrator browser page-loading review has started: 31 sidebar views plus the Projects and HR workspaces were inspected with no observed alert messages. This is not full workflow acceptance. Technician/client role flows, live export/download checks and physical-device PWA tests remain pending, as do other documented module gaps and advanced bonus/SLA/CSAT rules. Real employment dates, salaries, deduction policies and authorized reviewers must be supplied by the administrator.

Migration 031 fixes legacy locked-month compatibility: first-time employment configuration is allowed when every day of an already locked legacy month remains employed. Excluding any of those days remains blocked. The complete affected database suite passed 703 checks, including both compatibility regressions; the preceding full run passed 1,356 checks across 37 suites. The published Salary basis screen was verified in the signed-in administrator browser; no real employment dates or deduction policies were configured.

The live salary-screen check identified an employment-loader error: employment rows have user_id as their primary key, while the shared pagination helper assumed id. The loader now sorts employment by user_id and retains id for other tables. A regression exercises the actual helper, and the workspace UI suite, TypeScript and production build passed after this correction.

## Daily activity evidence — 2026-10-09

Migration 032 adds private file/photo attachments to daily activity records, including Internal and Deal work. Only the current assigned author may attach or remove evidence on an unlocked Draft/Rejected activity. Authorized reviewers can download private files; clients and Accounts without review scope cannot read the file metadata or objects. Uploads use a separate private bucket and authenticated downloads. Registered objects cannot be replaced or deleted by the uploader; removal retains the private file, reason and history while updating the active file list. Limits are 10 active files, 20 registered attachments per activity and 10 MB per file.

Attachments and removals increment the activity version. Retrying an attachment after a lost response reuses the same object and metadata. Submission and approval reject missing or changed registered objects; approved history records the exact file IDs. General activity history excludes private filenames and paths. Assignment revocation removes author evidence access. Existing HR month locks, independent review and approved labour costing remain enforced. CSV adds filenames only from the caller's authorized evidence rows. Reference text remains supported.

Validation: 1,389 checks across 38 suites, TypeScript and production build passed. Database tests exercise authenticated storage RLS, assignment revocation, stale versions, retry idempotence, immutable registered objects, retained removal history, missing-object submission and approval snapshots. UI tests cover private upload, retry without duplicate upload, submitted read-only controls and mobile camera input. Migration 032 applied successfully. Physical-device camera capture and the complete live multi-role upload/review workflow remain acceptance tasks. Calendar scheduling automation, other documented module gaps and full 41-item workflow acceptance remain pending.

## Assigned work scheduling and calendar prefill — 2026-10-09

Migration 033 adds private assigned work schedules for Project, Ticket, Deal and Internal activities. Administrators and current authorized project/sales managers schedule workers who hold the relevant work assignment. Technicians can read their own currently assigned plans but cannot alter a manager's plan or record another worker's schedule. Clients and unrelated Accounts have no schedule access. Scheduling supports explicit location, work description/type, worker, planned interval, revision/cancellation reason and history; overlapping plans for a worker are rejected. An administrator/authorized manager can cancel an unused plan after the worker is deactivated.

Plans automatically appear in My tasks & calendar. Daily activity log → Work schedule lets the assigned worker record actual work with the original scope, site, description, assigning person and planned interval prefilled. Actual start/end remain blank until explicitly entered. The database supplies the planned fields and rejects stale, cancelled, revoked or already-recorded schedules. One activity per schedule and immutable source snapshots prevent duplicate actuals and plan rewrites after recording. Later activity revisions preserve the original planned interval and assigning person. Independent approval continues to cost actual hours, not planned hours. These records do not automatically finish a task or publish client results.

Validation: 1,429 checks across 39 suites, TypeScript and production build passed. The test environment lacked its default temporary directory; the successful complete run used a workspace temporary directory. Database tests cover staff/client/Accounts RLS, assignment revocation, immutable scope, stale versions, cancellation, overlap, duplicate prevention, scheduled source snapshots and approved actual-hour costing. UI tests cover manager forms, timezone conversion, fixed prefill, explicitly entered actuals, calendar details and exclusion of staff queries from client calendars. Migration 033 applied successfully. Live authenticated rollback acceptance verified a project manager's assignment, worker/client RLS, revocation, exact source snapshot, duplicate prevention, separate manager approval and PKR 240 for two actual hours; all synthetic records rolled back.

Schedule-driven calendar display and activity prefill are implemented. Schedule-specific notification delivery, structured location lookup, advanced KPI/SLA/CSAT/bonus rules, other documented module gaps, physical-device camera/PWA checks and the complete 41-item multi-role browser acceptance remain pending. External email/SMS/WhatsApp delivery remains excluded. No real employment terms or business policies were created.

## Schedule reminders and saved-site lookup — 2026-10-09

Migration 034 extends the existing 15-minute portal reminder scanner with assigned work schedules due within 24 hours, including overdue plans for up to 24 hours after planned end. Each worker/plan revision receives at most one generic reminder. The inbox and push eligibility both recheck the current worker assignment, active account, plan version/status and whether an activity already records that plan. Revocation, cancellation, revision, expiry or recording actual work hides obsolete reminders and blocks queued push eligibility. Reminder preferences apply to enqueueing and push. Schedule reminders open Daily activity log; Work schedule contains the assigned plans. The existing cron calls the same public scanner. Existing task, sales, visit, review, SLA and renewal workflows remain in the scanner.

Daily activity and work schedule forms now offer a saved-site lookup. It reads the existing RLS-protected client_sites table, offers only active sites, and filters Project/Ticket choices to the selected project's company. Scheduled recording retains the fixed planned location. Choosing a site copies its name/address into the editable location text; the saved record is a text snapshot, not a live site association. Manual locations remain available for travel, office work and other places. No site permissions are expanded.

Validation: 1,459 checks across 40 suites, TypeScript and production build passed. Database checks cover scanner authorization, deduplication, notification privacy, revisions, assignment revocation, cancellation, opt-out, recorded activity, future windows, scheduler identity restoration and service-role push claims. UI checks cover active company-filtered site choices, copying the address, stable location text, fixed scheduled location and no client lookup queries. Migration 034 applied successfully. Live authenticated rollback tests verified scanner/deduplication, generic titles/destination, assigned and unassigned site access, worker/client boundaries, revocation, revision, opt-out and cancellation. All synthetic data and preference changes were rolled back. Real device push/camera tests, advanced KPI/SLA/CSAT/bonus rules, remaining documented module gaps and full 41-item multi-role browser acceptance remain pending. External email/SMS/WhatsApp delivery remains excluded.


## Percentage bonus bands (migration 035)

Administrators can save either fixed PKR or salary-percentage score bands in effective shift/KPI policies. Percentage bands are bounded to 0–100 with two decimal places. The highest applicable score threshold wins; numerically duplicate thresholds are rejected. Old bands without a calculation mode remain fixed PKR. The percentage base is the calculated prorated basic salary before deductions, excluding overtime and TADA. Missing weighted KPI evidence still leaves score and bonus unknown. Scorecards and saved review details expose the selected band and exact salary base.

The monthly source hash includes the selected band and calculated salary base. Changed effective policy invalidates pending review until HR rebuilds the draft. Locked summaries keep their immutable snapshot. Existing Lead → Manager → Accounts separation, net deduction bounds and salary payment exclusions remain in force. Existing unlocked drafts created before this migration must be returned/rebuilt before further review. No real salary, KPI policy or bonus settings were created.

Historical on-time task metrics, ticket SLA/CSAT/repeat-complaint metrics, optional on-time/within-budget project-completion bonuses, remaining module gaps and full 41-item multi-role browser acceptance remain pending.

Validation: 1,477 checks across 40 suites, TypeScript and production build passed. New authenticated database checks cover percentage bounds/precision/mode, duplicate thresholds, prorated base, stale review, fixed-band compatibility, saved net, locked snapshots and client privacy. UI checks verify fixed/percentage policy submissions and the displayed salary-base explanation. Migration 035 applied successfully; live authenticated rollback QA verified 12.5% of PKR 30,000 = PKR 3,750, the prorated mid-month base, unauthorized configuration and the percentage ceiling. All synthetic fixtures were rolled back.


## Historical on-time task KPI (migration 036)

Submission history now saves the task deadline and server submission time. Publish/internal Approve history copies the matching submission revision into permanent timing evidence. Monthly scorecards count the latest reviewed completion per task in the review month, attributed to the recorded worker. On-time means submission by the saved deadline using Pakistan calendar dates. Reassignment, later deadline edits and reopening do not rewrite this evidence. Direct Done edits without reviewed completion are excluded. No legacy timestamps/deadlines are invented: missing timing evidence in the review cohort leaves the metric unknown. This is review-month reporting, not a reconstruction of every historical assignment.

Administrators may explicitly weight the On-time reviewed tasks metric. Weighted score, fixed/percentage bonus and gross/net projections are recalculated together; incomplete weighted evidence leaves score/bonus unknown. Existing authorization, source-change review gates and immutable locked snapshots remain. Older unlocked drafts must be returned/rebuilt when their source changes. No actual KPI weights or company bonus policies were configured.

Validation: 1,494 checks across 40 suites, TypeScript and production build passed; the affected HR UI suite also passed after its new weight assertion. Authenticated database checks cover empty/missing evidence, deadline-date boundary, lower/higher percentage bands, deadline edits, reassignment/reopening, historical privacy, private helper access and unchanged locked legacy snapshots. Migration 036 applied; authenticated live rollback QA verified captured deadlines, late work despite deadline extension, bonus integration and retained evidence after reassignment. All synthetic fixtures rolled back.

Next: fixed ticket resolution/SLA evidence and explicit worker attribution, client CSAT capture and attribution, repeat-complaint metrics. Optional project-completion bonuses, other documented module gaps, real-device testing and the full 41-item multi-role browser acceptance remain pending.


## Ticket resolution SLA and service CSAT (migration 037)

Administrators can designate a performance owner who already has assigned ticket/project access. This attribution setting grants no access. Version checks prevent stale changes, and reasons/actors/times are retained in ownership history. Each transition to Resolved captures a numbered immutable revision with its owner, server resolution time, contract deadline and SLA note. Reopening/reassignment cannot rewrite a prior revision. No legacy resolution evidence is fabricated.

New service sign-offs bind to the exact captured resolution revision. The client who accepted that sign-off may optionally submit one permanent 1–5 customer rating while the same resolution remains current. Staff, other companies, pending/correction decisions and old/reopened revisions cannot rate it. An identical retry is idempotent; revisions cannot rewrite or duplicate a resolution rating. Client rating visibility is limited to their own accessible ratings; staff resolution/ownership history remains private.

Monthly employee scorecards support explicitly configured ticket resolution SLA and normalized customer-rating weights. SLA uses captured owner/resolution-month evidence (latest resolution per ticket for that employee in the month); any missing contract deadline leaves the cohort unknown. CSAT uses ratings submitted in the month, attributed to the captured resolution owner, and displays the raw 1–5 average/count; normalized score is average / 5 × 100. Unrated work is not zero, and unassigned resolutions receive no invented employee credit. The existing weighted score, percentage/fixed bonus, source-change review and immutable locked snapshots remain intact. No actual owners, salaries, weights, targets or customer ratings were configured.

Contract SLA clocks remain the existing 24/7 clocks: waiting-on-client pause policies, response-time KPI, project-handover CSAT, repeat-complaint metrics, optional project-completion bonuses, other documented gaps, device testing and full 41-item multi-role browser acceptance remain pending. Ticket service CSAT is not project-handover CSAT.

Validation: 1,530 checks across 40 suites, TypeScript and production build passed. Database checks cover authorized/stale ownership, assigned-record privacy, fixed attribution, resolution revisions, missing SLAs, pending/reopened/old sign-offs, staff/other-company rating denial, immutable/idempotent ratings and weighted score/percentage bonus. UI checks cover ownership submission, accepted-client numeric rating, saved rating display and absence of staff ownership controls for clients. Migration 037 applied. Authenticated live rollback QA verified SLA 100%, rating 4/5 normalized to 80%, equal weights yielding score 90 and PKR 6,000 bonus on PKR 30,000; client privacy, unchanged attribution after reassignment and distinct same-transaction resolution revisions also passed. All synthetic fixtures rolled back. The new authenticated RPCs are intentional authorization-checked definer functions; private helpers are not callable directly.

Production browser follow-up: administrator sign-in restored securely. The initial browser walkthrough caught ownership-table loading ordered by nonexistent id; the loader now uses ticket_id, with a schema-aware UI regression check. No actual owner, rating, salary or policy was entered in the browser.


## Waiting-on-client SLA clocks (migration 038)

New measured tickets capture pause rules at creation. Entering Waiting on client freezes unfinished clocks at the server timestamp. Leaving the wait extends unfinished deadlines by the recorded duration; multiple waits accumulate. A shared first staff reply during a wait completes and extends only the response deadline, leaving resolution paused. Resolving from waiting extends the resolution deadline before its immutable performance snapshot is recorded. Direct browser updates cannot forge pause timestamps, durations, clock rules or deadlines.

Overdue scanners, escalations, portal reminders, dashboard warnings and CSV/PDF report results compare unfinished deadlines to pause entry while waiting. Breaches that occurred before waiting remain overdue. Completed responses never receive another extension. Existing tickets retain their original 24/7 terms and historical results; no earlier waiting durations are invented. The interface distinguishes legacy clocks and identifies paused deadline values as the deadline at pause entry.

No business targets, employee owners or policy weights were changed. Scorecard explanatory text now describes captured rules; unlocked older drafts require the existing source-change return/rebuild/review flow. Locked snapshots stay fixed. Project-handover ratings, response-time KPI, repeat complaints, optional project bonuses, other documented gaps, device checks and full 41-item multi-role acceptance remain pending.

Validation: 1,561 checks across 40 suites, TypeScript and production build passed. Coverage includes multiple positive-duration waits, reply while paused, resolution snapshots, forged fields, frozen scanners/reminders/alerts, retained pre-pause breaches, legacy clocks, company isolation and paused UI/report results. Migration 038 applied; live authenticated rollback QA verified server guarding, reply/resolution transitions, exact saved deadline basis and company isolation. The live batch has one statement timestamp, so its waits have zero duration; positive duration and multiple-wait calculations were verified in the PostgreSQL regression suite. Synthetic live data rolled back. Security advisor findings are unchanged from the prior release.


## Project-handover customer ratings (migration 039)

The designated client who personally signed the current archived handover may optionally submit one permanent 1–5 rating with a comment. Signed-but-unarchived, cancelled and pending revisions cannot be rated. Staff, consultants and other client accounts cannot impersonate the designated client. An exact retry is idempotent; changed/duplicate ratings are rejected. Feedback is separate from acceptance and never changes the signed PDF. Clients can read their own accessible ratings; staff need existing handover access.

Administrators explicitly configure an already project-assigned performance owner before closure, with version/reason/actor/time history. This grants no project access. Archiving captures immutable ownership/time/scope-hash evidence; an owner who lost assigned access must be cleared or replaced before archive. Closed ownership is fixed. Existing archived handovers may receive client feedback but no legacy employee attribution is reconstructed. Unconfigured new closures likewise receive no invented employee credit. No actual owners or customer ratings were configured.

Monthly CSAT combines individual attributed ticket-service and project-handover ratings submitted in the Pakistan calendar month, using average / 5 × 100. Service, project and combined counts/raw averages are displayed separately. Unrated work is excluded rather than scored zero. Scorecard sources omit customer comments and identity. Existing weights, salary basis, fixed/percentage bonus bands, source-change review gates and locked summaries remain intact; administrators supply actual policies. Unlocked old drafts require return/rebuild/review when source evidence changes.

Response-time KPI, repeat complaints, optional project-completion bonuses, other documented module gaps, physical-device checks and full 41-item multi-role browser acceptance remain pending.

Validation: 1,609 checks across 40 suites, TypeScript and production build passed. Tests cover legacy/unconfigured attribution, explicit/stale/unassigned ownership, revoked-owner archive blocking with certificate rollback, unsigned/unarchived/cancelled restrictions, staff/consultant/other-company denial, permanent/idempotent ratings, revoked assignment visibility, combined individual-average/count normalization, weighted percentage bonuses and omission of private feedback from employee scorecard sources. UI checks cover optional signed-client rating, saved read-only feedback, staff restrictions, explicit owner submission and actual project_id pagination. Migration 039 applied. Authenticated live rollback QA completed release → three own signatures → archive → rating, verified exact closure/rating attribution, retry/immutability, private basis/company privacy and denied direct update; all synthetic records rolled back. The two new public definer RPCs explicitly enforce authorization; helpers remain private.

## Response SLA and reviewed repeat complaints (migration 040)

New first shared staff replies capture immutable response time, effective SLA deadline, active reply minutes and explicit performance owner. Waiting extensions are excluded from active minutes. First closure without a shared reply captures a failed measured response outcome; reopening, later replies and reassignment cannot erase it. No historical responses are reconstructed. Monthly response SLA uses completed outcomes in their Pakistan outcome month; open unanswered tickets are excluded and missing deadlines make the cohort unknown. Administrators may explicitly weight this metric using existing reviewed policy and bonus rules. No actual business weights were changed.

An administrator can confirm a new complaint against an earlier recorded resolution of another ticket in the same project, with a reason and current version. Different known assets, future resolutions and duplicate confirmations are rejected. Attribution uses the earlier resolution's fixed owner. Withdrawals append history rather than editing evidence. Monthly complaint-receipt counts and affected original-resolution counts use the latest reviewed disposition. Employee scorecard sources omit review reasons and reviewer identity. These are descriptive counts: recurrence windows, denominators and repeat-quality bonus scoring require actual business rules; zero confirmations does not prove repeat-free quality. Existing access restrictions remain in both database and interface.

Full 41-item multi-role browser acceptance, physical-device checks, repeat-quality scoring rules, optional project bonuses and other documented module gaps remain pending. External messaging remains excluded.

Validation: 1,656 checks across 40 suites, TypeScript and production build passed. Tests include waiting-adjusted elapsed minutes, unanswered closure/reopen failures, immutable ownership, missing SLA unknowns, explicit response weighting/percentage bonuses, client/staff classification denial, cross-project/same-ticket rejection, stale/duplicate review prevention, reasoned withdrawal history, private scorecard sources and guarded interface submissions. Migration 040 applied. Live authenticated rollback QA verified first shared reply capture, fixed original-resolution repeat attribution and client isolation; synthetic fixtures rolled back. The new public review RPC intentionally checks active administrator authorization; private capture/monthly helpers remain non-callable.

## Reports acceptance follow-up — 9 October 2026

Signed-in administrator production review loaded Reports with 12 tickets (completed response/resolution compliance 1/3 each), 6 tasks, 3 assets and 4 contracts. No actual business records were changed. The review exposed export buttons enabled during report refresh and outdated no-pause explanations. Reports now disable all five CSV/PDF download controls during initial load, refresh and load failure; a successful retry restores them. Filters remain mounted across refresh. SLA CSV adds the captured clock rule and pause-entry timestamp; PDF identifies each ticket's clock rule. Report and contract explanations distinguish new waiting-pause rules from legacy recorded 24/7 terms.

Eight regression checks cover loading, stale refresh, failure/recovery, selected-dataset isolation, pause-aware CSV fields/PDF rows and explanatory copy. Administrator sign-in succeeded, but native credential protection subsequently blocked browser observations and rejected the fresh-document recovery. No live download was completed, so item 20 remains partial with live CSV/PDF content/download verification pending; technician/client report visibility and full 41-item acceptance remain pending. This is an implementation fix prompted by live page review, not completed export acceptance.

Release validation: 1,664 checks across 41 test suites, TypeScript and production build passed. A synthetic 44-row six-column SLA PDF rendered across four pages; repeated headers, wrapped clock rules and the final record were visually checked. The 41 test suites are not the 41 acceptance items. No database migration was needed for these report fixes.

## Reusing saved task standards — 9 October 2026

Administrators can copy an individual task from a current active template revision into another unsaved template draft. Required formula parameters are copied only when their range/default is compatible; duplicate keys, missing predecessors, phase-order violations and template size limits are rejected. Empty task placeholders are replaced. Copied task/checklist/parameter values are independent of the saved source; changes are saved through the existing administrator-only versioned template RPC, preserving running project plans. Non-administrators retain preview-only access. No actual task times or business standards were configured.

This adds reuse of existing saved template standards. A standalone independently managed task library, node-list import, project-specific plan edits, resource allocation and actual-time learning remain pending, along with browser acceptance and the full 41-item checklist. No database migration is required. Eight additional interaction/validation checks cover parameter conflicts, copying, duplicate keys, staff restrictions, predecessors, phase ordering, source isolation and size limits.

Validation: 1,672 checks across 41 test suites, TypeScript and production build passed. The 41 suites are not the 41 acceptance items. Live configurator copy/save and multi-role acceptance remain pending; the preceding browser credential-protection block has not been resolved by this increment.


## Recorded-name trade summaries — 9 October 2026

Accounts can inspect outstanding, overdue, due-today and not-due balances plus open/total document counts grouped by exact recorded counterparty name, direction and document type. The grouping follows the selected currency and document direction/due-status filters; all-record currency totals retain their existing scope. CSV/PDF exports include the same groups and the grouping basis. Same-name customer invoices, vendor bills and expenses remain separate, with no receivable/payable netting. Decimal balances accumulate in cents. No new database access, business entries or policies are introduced; no migration is needed.

This is a recorded-name summary, not verified account-level consolidation. The current report does not return stable counterparty identities; names shared by different accounts can share a name group, and renamed records remain separate. Identity-based customer/vendor consolidation and reviewed opening-balance imports remain pending. Loans and advances remain excluded.

Validation: 1,683 automated checks across 42 suites, TypeScript and production build passed. Eleven new checks cover amount reconciliation, settled/open counts, same-name type separation, renamed records, currency/empty scopes, decimal accumulation, client denial, UI/export agreement and direction/status/currency filter changes. A synthetic 44-group, six-column PDF rendered across six pages; repeated headers, wrapped names, the final group and report-basis note were visually checked. Live authenticated finance/download acceptance and the full 41-item multi-role browser review remain pending. The 42 suites are not acceptance items.

Resume checkpoint: baseline main d6acdce8b04960340f224df0c78b2d81a5d38c7d already contains migrations 036–040 and task-standard reuse. Historical on-time task KPI, ticket SLA, service/project CSAT, response SLA and reviewed repeat-count implementations are present and their automated regressions passed in this run. Repeat-quality scoring needs actual recurrence/denominator rules; optional project-completion bonus policies and other documented module gaps remain pending. No actual salaries, KPI weights/targets, owners or reviewers were configured. External email/SMS/WhatsApp remains excluded.


## Identity-based trade summaries — migration 041

The Accounts-only trade snapshot now returns existing customer company IDs and vendor IDs, plus current account names, without changing the saved invoice/payee labels or any balance, aging or due-schedule calculation. Customer invoices consolidate by company identity; same-name companies remain separate even when their invoice labels match. Vendor bills and expenses explicitly linked to that vendor consolidate as vendor payables. Unlinked payees stay recorded-name groups and are never matched to a customer/vendor by name. Currency and direction stay separate; receivables and payables are not netted. Full account references distinguish same-name accounts in the view and CSV/PDF exports.

The report explicitly versions its identity output. The deployed UI supports both this output and the preceding recorded-name response, preserving a safe frontend/database rollout boundary. Document filters apply to both groups and detail; all-record currency totals retain their existing scope. No grants, business records, opening balances, salaries, policies, targets or reviewer assignments were added. This replacement intentionally retains the existing authorization-checked security-definer report, empty search path and authenticated-only execution grant; no new public RPC is introduced.

Validation: 1,712 checks across 42 suites, TypeScript and production build passed. Twenty-one added database checks verify migration compatibility, financial/document preservation, current names, fixed customer/vendor IDs, unlinked names, renaming, private-field omission and role/disabled/revocation boundaries. Eight added UI/helper checks cover renamed and same-name accounts, linked vendor aggregation, unlinked-name separation, legacy compatibility, scoped filters and matching account-reference exports. A synthetic 44-group PDF with long names/full account references was visually reviewed across all eight pages, including repeated headers, final group and basis note.

Migration 041 applied to production project iman-client-portal (rozbzrciuhnswmvmqdvx); the separate CRM project/repository was untouched. Authenticated live rollback QA passed 13 assertions for account IDs, name history, same-name separation, linked/unlinked expenses, private-field omission and client/technician/inactive/revoked/anonymous denial. The report's currency/aging/due totals fingerprint matched the pre-migration baseline before fixtures were added. A separate follow-up found zero QA companies, profiles, invoices or expenses, confirming rollback. Security-advisor findings are unchanged. The reusable rollback script is tests/qa/trade-identity-rollback.sql.

Resume checkpoint: prior deployed main 6fba1ead25cb122af3032296a6909a97d76f908c (PR #42); database now includes 041. Full 41-item administrator/technician/client browser acceptance, authenticated finance downloads, physical-device PWA/camera checks, reviewed opening-balance imports, repeat-quality business scoring, optional project-completion bonus rules and other documented module gaps remain pending. Unlinked expenses intentionally remain names until an actual vendor is explicitly linked; no legacy identity is inferred. External email/SMS/WhatsApp delivery remains excluded.

### Administrator finance browser checkpoint — 9 October 2026

Reviewed production main e0fda67a342a8e598abeb6e7aa185680b6a339be (PR #43), migrations through 041, at https://www.imanservice.com/portal. Secure email/password sign-in visibly reached the administrator project workspace. Finance & expenses loaded its dashboard with zero current trade and loan amounts. Receivables & payables loaded the identity-version report: as-of 2026-10-09 in Asia/Karachi, PKR, Both, Outstanding; currency totals, aging and upcoming windows displayed zero, account/name totals had zero groups, document detail had zero records and the explicit empty-state message. Identity grouping scope and unchanged document-name basis were visible. This is empty-state browser evidence only; populated identity cases remain supported by the previously recorded automated/live rollback checks.

Browser credential protection blocked further interaction and reported that native credential state could not safely resume. The one recovery attempt on the same existing tab failed. Changing direction/due filters and triggering actual CSV/PDF downloads were therefore not verified. No browser download was captured; do not treat the visible export buttons as successful exports. Administrator read-only finance rendering passed within this limited scope; authenticated download/filter acceptance, technician/client finance visibility and the full 41-item multi-role review remain pending. No business records, permissions or credentials were changed; no new migration or application release was required. Resume with secure browser access, then validate filters and real files before advancing these acceptance checks.

### Project portfolio progress export — 9 October 2026

The portfolio's filtered CSV now includes the same visible-task progress as its table, with an explicitly scoped column heading. Previously the CSV omitted task progress and the table temporarily reported 0 / 0 while tasks were loading. Pending reads now show Loading in the table and CSV; failures show Unavailable rather than zero; refreshing clears previous task counts and errors until the new read settles. Confirmed empty results retain 0 / 0 done. Existing row filters, pagination and database role boundaries are unchanged; these counts are current visible task states, not historical on-time KPI evidence or all-project completion percentages.

Validation: 1,721 automated checks across 43 suites, TypeScript and production build passed. Nine focused UI checks exercise pending/resolved/failed reads, per-project scoping, confirmed empty results, filtered CSV parity and refresh recovery. No migration or business-policy/data changes. Authenticated browser downloads and the full 41-item multi-role acceptance review remain pending after the preceding credential-protection block. Resume checkpoint starts from main 8a0b769f496a3e82c7dc5b9aabde32e3f2753724 (PR #44), migrations through 041.

### Weekly project schedule measures — 9 October 2026

The project portfolio adds Due this week and No deadline filters and a deadline-status column shared with filtered CSV. Schedule dates use Asia/Karachi; the current week runs Monday–Sunday and includes elapsed days in that week. Unfinished projects can be overdue by a date-only day count, due today, not due, or without a deadline. Completed projects display Completed and are excluded from schedule filters, including upcoming starts. No actual completion date or historical completion variance is inferred. Table basis and CSV status heading explicitly retain the as-of date/timezone; row filters and existing task visibility boundaries remain in force.

This is a bounded weekly schedule/reporting increment toward the workbook requirements, not a structured route register, resource allocation, project baseline/revision history, final financial settlement or full schedule acceptance. No migration, targets, assignments or business-data changes. The resume baseline is main 0531c2d240332d53beeeaf11cbb571b90dc532d4 (PR #45), migrations through 041. Full 41-item multi-role browser review, authenticated exports and previously documented gaps remain pending; the native credential-protection block has not been bypassed.

Validation: 1,742 automated checks across 44 suites, TypeScript and production build passed. Seventeen date-rule checks cover Karachi midnight, Monday/Sunday boundaries, completed/missing/invalid dates and leap-day arithmetic. Four added portfolio UI checks verify visible statuses/basis, weekly and undated filtered exports, and exclusion of today/completed records from overdue results. Actual production browser filter/download acceptance remains pending.

## Independent task library (migration 042)

Administrators maintain reusable standards independently of product/project templates. Each save requires the current version and a reason, then appends immutable name, active state, parameter bounds/defaults, task fields, author and timestamp evidence. Direct browser insert/update/delete of library rows and revision history is denied. Authorized planning staff can read; clients, ordinary technicians and revoked planning accounts cannot gain library access. The private validator is not exposed as an RPC.

The structured editor covers process/step, phase, units, fixed/per-unit time, quantity/formula parameters, crew, tools, readiness and checklist. Independent standards have no predecessors; dependencies are added during template composition. Invalid task/formula/checklist/crew values and stale versions are rejected atomically. Active current library revisions appear in the existing copy-to-draft control. Editing/deactivating a standard changes future copy choices while existing saved templates and running project plans retain their values. No actual business standards or times were configured automatically.

Migration 042 also adds covering indexes for the four response/repeat foreign-key lookups identified in the prior advisor review. Node import, project-specific plan changes, resource allocation, actual-time learning, other documented gaps, device testing and full 41-item browser acceptance remain pending. Live library editor/copy/save browser verification remains pending after the preceding credential-protection block.

Validation: 1,776 automated checks across 44 suites, TypeScript and production build passed on main fe3b4a1efcc8bbbf702b99cc866623f84d5cd163 plus this increment. Existing trade identity and weekly schedule increments were retained. Migration 042 applied to production; tests/qa/task-library-rollback.sql passed 11 authenticated assertions for create/revise/deactivate, preserved timing/author history, stale-edit and direct-write denial, client/ordinary-technician boundaries, planner access and revocation, anonymous RPC denial and private validator exposure. All synthetic fixtures rolled back; a separate query found zero retained QA standards. Advisors add only the intentionally administrator-checked authenticated RPC notice and unused-index informational notices; four unindexed foreign-key findings were resolved. Full browser acceptance remains pending. No actual standards, timings, salaries, targets or reviewers were configured.
