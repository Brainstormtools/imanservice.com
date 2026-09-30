# Sites, network audits, maintenance visits and AMC renewals

## Included
- Administrator-managed client sites with shared location/contact details and archive state. Existing equipment can be linked to a same-company site; existing location text remains intact.
- Administrator-scheduled audits and visits, assigned to an active technician, with a start/end appointment. A per-technician lock rejects overlapping non-cancelled appointments. Visits appear in a monthly chronological agenda in the browser timezone.
- Optional same-company project and shared project/maintenance task link. Completing a visit does not automatically mark a task done: review and update the task separately.
- Assigned technicians record work, checklist completion and structured audit findings (severity, title, recommendation). Evidence uses existing private project file uploads and authenticated downloads. Only files in the selected project can be linked. Uploads remain subject to existing file size/type limits.
- Staff submit completed records, administrators publish, and the company's clients confirm completion or request changes. Changes reopen the record for revision. Saving the revision hides the draft from clients until it is published again. Published report versions remain saved; records, cancellations and decisions are audited. Current reports download as readable TXT; earlier snapshots download as JSON-formatted TXT. PDF layout and external signatures are separate work.
- Administrator drafts renewal dates, services, price/currency and per-priority 24/7 targets. Publication freezes the proposal. Only the client company accepts/declines. Administrator activation creates exactly one new Active contract period, preserving the original contract and old ticket deadlines. Projects retain their existing contract link until manually reassigned under Projects; review before moving future tickets to the renewed contract. Pricing does not generate or issue an invoice.

## Access
Administrators manage all records. Team accounts can see sites/assets but only their assigned audit/visit jobs; they cannot publish or access financial renewal proposals. Clients see their company's sites and published jobs/renewals only. Accounts without active profiles and anonymous users cannot access these modules. Site contact details are shared with the client company; avoid private staff notes and credentials.

## Rollout
Apply `supabase/011_it_operations.sql` once after 010, then deploy the interface. Five RLS-protected tables, checked functions, and nullable equipment.site_id are additive. No provider credentials or new scheduler required. Keep current SLA and recurring billing jobs. Roll back the UI deployment if necessary; preserve database records.

## Acceptance checklist
| Account | Steps | Expected |
|---|---|---|
| Admin | Create A/B sites; archive a site; link equipment | Cross-company links rejected; old equipment preserved |
| Admin | Schedule technician audit/visit; try overlap | Valid appointment saved; overlap rejected |
| Technician | Open assigned work; fill scope/work, checklist and findings; select uploaded evidence | Other technicians' jobs hidden; allocation controls admin-only |
| Technician/Admin | Submit incomplete checklist, then completed checklist | Incomplete rejected; complete becomes Submitted |
| Admin | Review and publish | Client can now review; published snapshot preserved |
| Client A/B | Inspect published record and direct IDs | Own company only; no unpublished jobs or evidence from another company |
| Client A | Request changes with feedback | Feedback recorded; technician can revise and resubmit |
| Admin/Client A | Republish then confirm | Previous report version retained; current job Confirmed |
| Admin | Create, publish renewal; attempt overlap with previous period | Start after original end; valid SLA targets; draft hidden from clients |
| Client A | Accept or decline as authorized representative | Decision recorded; published terms immutable |
| Admin | Activate accepted proposal twice | One new contract; retry returns same contract |
| Admin | Review/reassign project contract when appropriate | Original period and existing ticket deadlines unchanged |
| All | Download reports/evidence; refresh; try stale saved versions | Authenticated files, history available, stale edits rejected |

## Verification
39 PostgreSQL assertions, 6 new UI assertions and 17 existing operations UI assertions passed (62 total). TypeScript and production build passed. Database identities and UI transport are simulated locally; these do not replace the acceptance workflow with hosted accounts. Database migration and hosted acceptance are pending Supabase sign-in; do not merge before applying 011.

External notification delivery remains inactive pending provider setup. Historical CRM data migration is excluded.
