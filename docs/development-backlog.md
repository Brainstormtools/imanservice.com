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
| DEV-028 | Commercial change approvals | Reviewed BOQ revisions and client approval | In progress: existing/new-product offers, client decisions and fixed invoice drafts; reviewed new-product workstream application added; replacement/removal/extensions remain |
| DEV-029 | Commercial change approvals | Reviewed budget releases/revisions | Pending development |
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

DEV-028 fourth increment: reviewed template/parameter/date preview and atomic administrator application of accepted new products into internal unassigned tasks and dedicated milestones, with immutable source/plan/application receipts, implemented under migration 063. Original baseline/budget/project dates preserved. Validation/release checkpoint is recorded in both requirement documents. Existing-line replacement/removal and existing/dropped-product adoption/extensions remain pending. Backlog remains 58 open packages (one in progress, 57 not started).
