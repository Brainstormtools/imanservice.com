# Remaining portal development backlog

Counted on 12 October 2026 (Asia/Karachi) against docs/crm-acceptance.md and docs/workbook-requirements.md, after PR #76 / migration 059.

This is a working breakdown of 58 documented development packages, not 58 modules, release increments, or the 41 acceptance items. Broad requirements are grouped into packages; each can require several small tested releases. It is not a claim that a fresh page-by-page audit of the full original specification found every possible gap. Superseded historical pending entries are excluded where later checkpoints implement them. Newly discovered gaps or approved requirement changes must be recorded and the count revised explicitly.

User direction: Codex handles development, automated tests, necessary migrations, PR/merge and production deployment verification. The client's team handles signed-in workflow/browser/download/responsive/physical-device acceptance. Client acceptance is tracked separately and is never marked passed without their reported evidence. Business values, legal/commercial approval rules, reviewers, salaries, standards, targets and real assignments are not invented. Ask the user when a missing business decision blocks a concrete package. Optional bonus/scoring packages require business confirmation; their presence below is a documented gap, not activation of a policy. External email/SMS/WhatsApp remains excluded; native mobile remains deferred; full payroll execution is outside the documented scope.

Start with DEV-028 (BOQ revisions and client approval), implementing its first bounded increment after inspecting the existing quotation/budget/change models. DEV-029/030 follow according to dependency. The remaining IDs provide stable tracking, not a requirement to work in numeric order when dependencies require another sequence.

| ID | Area | Development package | Status |
|---|---|---|---|
| DEV-001 | Sales intake | Website lead intake | Pending development |
| DEV-002 | Sales intake | Meta lead intake | Pending development |
| DEV-003 | Sales intake | API lead intake | Pending development |
| DEV-004 | Sales intake | Automatic lead routing | Pending development |
| DEV-005 | Conversion and payment scheduling | Later scheduled payment drafts | Pending development |
| DEV-006 | Conversion and payment scheduling | Accounts routing during conversion | Pending development |
| DEV-007 | Conversion and payment scheduling | Customer creation during conversion | Pending development |
| DEV-008 | Planning and execution | General master QA/SOP templates | Pending development |
| DEV-009 | Planning and execution | Project-specific acceptance criteria | Pending development |
| DEV-010 | Planning and execution | Structured route/containment register | Pending development |
| DEV-011 | Planning and execution | Device-specific register attributes | Pending development |
| DEV-012 | Planning and execution | Route-linked execution work | Pending development |
| DEV-013 | Planning and execution | Broader task scope, parent-child and dependency changes | Pending development |
| DEV-014 | Planning and execution | Schedule baselines/revisions and automatic rescheduling | Pending development |
| DEV-015 | Planning and execution | Reviewed parameterized task-standard import | Pending development |
| DEV-016 | Resources | Individual physical-tool identities | Pending development |
| DEV-017 | Resources | Pre-delivery and cross-project resource allocation | Pending development |
| DEV-018 | Resources | Worker skill/capacity/availability rules | Pending development |
| DEV-019 | Lessons | Cross-project reviewed lesson adoption | Pending development |
| DEV-020 | Charter and communication | Structured communication recipients/schedules and portal execution tracking | Pending development |
| DEV-021 | Charter and communication | Client charter publication/sign-off | Pending development |
| DEV-022 | Surveys | Reviewed structured survey batch imports | Pending development |
| DEV-023 | Surveys | Survey unit/calculation and template/BOQ linkage | Pending development |
| DEV-024 | Surveys | Survey instrument/calibration records and evidence uploads | Pending development |
| DEV-025 | Training | Account-linked participants and verified attendance | Pending development |
| DEV-026 | Training | Training evidence uploads and approved-activity linkage | Pending development |
| DEV-027 | Training | Documented competence/certification workflow | Pending development |
| DEV-028 | Commercial change approvals | Reviewed BOQ revisions and client approval | In progress: offers, client decisions, invoice drafts and reviewed new/existing-workstream tasks; replacement/removal/adoption remain |
| DEV-029 | Commercial change approvals | Reviewed budget releases/revisions | In progress: private costs/reviewed release archives and effective financial planning/material approval limits; manual catalogue mapping drafts; mapping reviews; material requests/product/contract integration pending |
| DEV-030 | Commercial change approvals | Reviewed contract revisions and client sign-off | Pending development |
| DEV-031 | Supply chain | Barcode workflow | Pending development |
| DEV-032 | Supply chain | Supplier defaults | Pending development |
| DEV-033 | Supply chain | Reorder-generated purchase requests | Pending development |
| DEV-034 | Supply chain | Rate contracts | Pending development |
| DEV-035 | Supply chain | Multi-line PO headers/amendments | Pending development |
| DEV-036 | Supply chain | Automatic go-live BOQ requests and reviewed legacy-line mapping | Pending development |
| DEV-037 | Supply chain | Standalone logistics/inspection approvals | Pending development |
| DEV-038 | Supply chain | Direct-to-site combined receipt/issue | Pending development |
| DEV-039 | Supply chain | Vendor RMA/returns and credit/debit-note execution | Pending development |
| DEV-040 | Supply chain | Store sales | Pending development |
| DEV-041 | Supply chain | Reviewed legacy opening-stock import | Pending development |
| DEV-042 | Finance | Category/product cost allocations | Pending development |
| DEV-043 | Finance | Project portfolio financial measures and actual date variance | Pending development |
| DEV-044 | Finance | Full applicable invoice tax/charge accounting | Pending development |
| DEV-045 | Finance | Immutable final financial settlement | Pending development |
| DEV-046 | Finance | Bank reconciliation | Pending development |
| DEV-047 | Finance | Supplier advances | Pending development |
| DEV-048 | Finance | Finance evidence file uploads | Pending development |
| DEV-049 | Finance | Staff advance settlement against expenses/payroll summaries | Pending development |
| DEV-050 | Finance | Loan interest accounting | Pending development |
| DEV-051 | Finance | Reviewed financial opening-balance import and loan/advance classification | Pending development |
| DEV-052 | Daily work | Activity-linked TADA claim creation | Pending development |
| DEV-053 | Daily work | Legacy timesheet reconciliation | Pending development |
| DEV-054 | HR/performance | Advanced repeat-quality scoring rules | Pending development |
| DEV-055 | HR/performance | Optional project-completion bonus rules | Pending development |
| DEV-056 | HR/performance | Project allocation of overtime premiums | Pending development |
| DEV-057 | HR/performance | Holiday calendar feeds | Pending development |
| DEV-058 | Design | Remaining specified design-system alignment | Pending development |


DEV-028 checkpoint: migration 060 and additional-item offer workflow implemented and automatically tested; release verification is recorded in the requirement documents. This does not complete the whole package. Backlog remains 58 open packages: one in progress and 57 not started in this numbered development pass. Existing implemented functionality is preserved; client acceptance is separate.

DEV-028 first increment deployed through PR #77 / b6350f581aee53dc99ca59845ba6cd1eb8b7dfdf. Additional-item offers/client decisions are live; the package remains in progress. Controlled accepted-offer invoice drafts are implemented in the second increment below. Full client acceptance is separate.

DEV-028 second increment: accepted-offer invoice drafts, immutable source amounts, manual payment details, private reasoned draft amendments and project-finance mapping implemented under migration 061. Deployed via PR #78 / 6a1410efe37b17e8520bbecba956182d609c4022; exact production deployment is READY. Release evidence is recorded in both requirement documents. Package remains in progress; existing-line replacements/removals, new product workstreams and explicitly documented replacement/withholding settlement remain separate. Backlog count remains 58 open: one in progress, 57 not started.

DEV-028 third increment: new-project-product commercial BOQ offers implemented under migration 062 with active-product/workstream checks, frozen public product names, mixed existing/new items and existing accepted-offer invoice support. Reviewed executable workstream/template application and existing-line replacement/removal remain pending. Deployed through PR #79 / 2a0620f2739cc2795c54bee0da7a528d11424c54 with exact production READY/domain verification. Final 2,828 checks/65 suites, TypeScript/build and migration 062 verification passed; release evidence is recorded in both requirement documents. Backlog remains 58 open packages (one in progress, 57 not started).

DEV-028 fourth increment: reviewed template/parameter/date preview and atomic administrator application of accepted new products into internal unassigned tasks and dedicated milestones, with immutable source/plan/application receipts, implemented under migration 063. Original baseline/budget/project dates preserved. Final 2,900 checks/66 suites, TypeScript/build and migration 063 metadata validation passed; PR #80 / 2b241679dda84d07ba1ecad9b28f212691e0c1a9 is merged and exact production READY/domain verification passed. Checkpoints are recorded in both requirement documents. Existing-line replacement/removal and existing/dropped-product adoption/extensions remain pending. Backlog remains 58 open packages (one in progress, 57 not started).

DEV-028 fifth increment: reviewed additional-task extensions for accepted offers on existing workstreams, with offer-specific task identities, internal unassigned tasks, dedicated milestones and immutable source/baseline/plan receipts, implemented under migration 064. Original workstream/tasks/product line/sale/budget/project dates preserved. Final 2,989 checks/67 suites, TypeScript/build and applied migration 064 read-only verification passed. PR #81 / af4e8bac0de2137d5ebb5ff1112b5b49ec6e0113 is merged; exact production READY/domain verification passed. Checkpoints remain in both requirement documents. Detailed receipt history/export, commercial replacement/removal and dropped-product adoption remain pending. Backlog remains 58 open packages (one in progress, 57 not started).

DEV-028 sixth increment: detailed frozen new-product/extension application history and scoped CSV export implemented without migration or permission changes. Final 2,998 checks/68 suites, final production-CSV history checks, TypeScript/build and read-only production policy verification passed; PR #82 / 4dfa95b6f6f8c2c11ffb9b1cff23d2c538f3d5c8 is merged and exact production READY/domain verification passed. Checkpoints are recorded in both requirement documents. Commercial replacement/removal and dropped-product adoption remain pending; use documented requirements or seek concrete business rules rather than inventing credits/cancellation. Backlog remains 58 open packages (one in progress, 57 not started).

DEV-029 first increment: administrator-only accepted-additional-scope budget cost drafts, manual existing-block cost inputs, calculated draft totals and private immutable revision history under migration 065. No release or operative finance/procurement change. Checkpoints are in both requirement documents and project-budget-drafts-guide.md. Backlog remains 58 open packages: two in progress (DEV-028/029), 56 not started.

DEV-029 first increment release (13 October 2026, 00:50 PKT): PR #83 / 6a1366b126d1b0f4137936740cf590eaea4c6c6f merged; exact production dpl_34FhQqQo9eNj6eMaHWBCk5X1XhQR READY/domain mapping verified, /portal HTTP 200, recent error/fatal scan empty. Final 3,063 checks/69 suites, TypeScript/build and migration 065 metadata verification passed. Private cost drafts are deployed but unreleased; next is explicit version-specific review/return/release, with effective finance/procurement integration separately bounded. Both requirement documents preserve release evidence/resume point. Backlog: 58 open packages, two in progress (DEV-028/029), 56 not started. Client acceptance remains separate and pending.

DEV-029 second increment (13 October 2026, 01:00 PKT): exact-version private administrator review/return/release archives with frozen costs, actual actors/reasons, stable action retries and scoped CSV. Released cost records do not yet affect original finance/procurement consumers. Requirement documents preserve validation/deployment checkpoint; effective contribution model and consumer integration remain next. Backlog remains 58 open packages: two in progress (DEV-028/029), 56 not started. Client acceptance remains separate and pending.

DEV-029 second increment release (13 October 2026, 01:06 PKT): PR #84 / 163e5c4cab45b7bc3bc7658ba55948602fca2099 merged; exact production dpl_95nHMGNrESnPF6TLX2EfsG7nrNtL READY/domain mapping verified, /portal HTTP 200 and recent error/fatal scan empty. Final 3,127 checks/70 suites, TypeScript/build and applied migration 066 read-only verification passed. Private reviewed cost archives are deployed; effective budget contribution/finance/procurement integration remains next. Both requirement documents retain precise resume points. Backlog remains 58 open packages: two in progress (DEV-028/029), 56 not started. Client acceptance remains pending.

DEV-029 third increment (13 October 2026, 01:15 PKT): latest released additional-scope cost contributions integrated into Project Financials planning and CSV/PDF with immutable original baseline, nonduplicating source revisions, explicit unknowns and original contract-revenue labels. Procurement limits/material requests and other consumer gaps remain pending. Both requirement documents retain validation/release checkpoint. Backlog remains 58 open packages: two in progress (DEV-028/029), 56 not started. Client acceptance remains separate and pending.

DEV-029 third increment release (13 October 2026, 03:37 PKT): PR #85 / 8f76516d4f2ce738b6b14a37f65a2ea3862d6584 merged; exact production dpl_F4oWo9TVNXakoMquHrgHbksWRj8N READY/domain mapping verified, /portal HTTP 200 and recent error/fatal scan empty. Full 3,194 checks/71 suites, TypeScript/build and applied migration 067 read-only verification passed. Effective financial planning now uses latest releases per accepted source without changing original budget or contract revenue. Procurement consumer integration remains next; both requirement documents preserve resume points. Backlog: 58 open packages, two in progress (DEV-028/029), 56 not started. Client acceptance remains separate and pending.

DEV-029 fourth increment (13 October 2026, 03:54 PKT): material-request and PO approval budgets use latest released Material contributions with original baseline preserved and all existing authority/commitment/overrun guards unchanged. Both requirement documents retain validation/release checkpoints. Additional catalogue-backed material requests/product allocation, contract revenue and tax/charge gaps remain pending. Backlog: 58 open packages, two in progress (DEV-028/029), 56 not started. Client acceptance remains separate.

DEV-029 fourth increment release (13 October 2026, 04:00 PKT): PR #86 / f85dd3a6289c62f93112c3899ce077a3b35fedd2 merged; exact production dpl_CxEf7s7UthQhuYPTi1Fam1AJ9UKC READY/domain mapping verified, /portal HTTP 200 and recent error/fatal scan empty. Full 3,214 checks/71 suites, TypeScript/build and applied migration 068 readonly verification passed. Material approval limits now use latest released Material contributions while retaining existing guards. Explicit manual catalogue/product mapping and additional material requests remain next; both requirement documents preserve resume points. Backlog: 58 open packages, two in progress (DEV-028/029), 56 not started. Client acceptance remains pending.

DEV-029 fifth increment (13 October 2026, 04:05 PKT): private manual catalogue/stock-quantity mapping drafts against exact released Material lines, frozen source/catalogue identities, reasoned revision history and CSV. Mapping review/product allocation/request generation remain pending. Both requirement documents preserve validation/release checkpoint. Backlog remains 58 open packages: two in progress (DEV-028/029), 56 not started. Client acceptance remains separate.

DEV-029 fifth increment release (13 October 2026, 04:12 PKT): PR #87 / 854c6fa269dfaffc4e9bf894e1d30e2ab99a6957 merged; exact production dpl_6ZB2gPBgQnWY4pLSRayhCNcX6K2D READY/domain mapping verified, /portal HTTP 200 and recent error/fatal scan empty. Full 3,271 checks/72 suites, TypeScript/build and applied migration 069 readonly verification passed. Manual mapping drafts/history/CSV deployed; mapping review and checked material requests remain next. Both requirement documents preserve resume points. Backlog remains 58 open packages: two in progress (DEV-028/029), 56 not started. Client acceptance remains pending.

DEV-029 sixth increment (13 October 2026, 04:19 PKT): exact-version private Approved/Returned material-mapping review with immutable complete snapshots, actual actors/reasons and CSV. Material-request generation and product/contract gaps remain pending. Both requirement documents preserve validation/release checkpoint. Backlog: 58 open packages, two in progress (DEV-028/029), 56 not started. Client acceptance remains separate.

DEV-029 sixth increment release (13 October 2026, 04:26 PKT): PR #88 / 05f8b7c809dbd78ad0d14284d19306ae79ee8dca merged; exact production dpl_2Ri7ynZnod3uoc9MxC5shavkqwUF READY/domain mapping verified, /portal HTTP 200 and recent error/fatal scan empty. Full 3,315 checks/73 suites, TypeScript/build and applied migration 070 readonly verification passed. Exact-version mapping reviews/approved snapshots deployed; checked request generation remains next after confirming quantity/fulfilment rules. Both requirement documents preserve resume points. Backlog: 58 open packages, two in progress (DEV-028/029), 56 not started. Client acceptance remains pending.
