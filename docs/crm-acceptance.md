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
| 28 | Project Configurator | Missing |
| 29 | Execution and handover | Missing |
| 30 | Supply Chain | Missing |
| 31 | Payables and expenses | Missing |
| 32 | Loans and advances | Missing |
| 33 | Project Financials | Missing |
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
