# Billing enhancements

## Included
Monthly invoice schedules snapshot a source invoice's lines, currency, notes and bank instructions. Administrators generate due drafts, review and issue them separately. Each click processes one due period per eligible schedule, up to 100 schedules. Repeated clicks catch up older periods; a unique schedule/period link prevents duplicates. The day of month clamps to month end and returns to its original anchor in later months. Pause/resume uses displayed versions. Existing source edits do not update a schedule; pause it and create a replacement when terms change. Scheduling uses UTC dates. This release uses administrator-triggered generation, without an automatic background billing job or automatic sending/issuance.

Credit notes are administrator-only adjustments to an issued invoice's unpaid balance. Credits cannot exceed the remainder after issued credits and pending/verified payments. They are recorded with request IDs for safe unchanged retries, numbered and audited. Reversal requires a reason and preserves the note. Active credits block invoice voiding. Existing payment submission/verification and dashboard balances now account for credits. No refund or money movement occurs. No tax-credit allocation or regulatory credit-note document is generated; administrators remain responsible for their accounting documents.

Payment/balance reports include issued invoices visible to the account, filtered by company and invoice issue-date range. They show total, verified receipts, pending claims, credits and outstanding balance separately for each currency and export per-invoice CSV. These are invoice balance reports, not bank reconciliation or transfer-date cash-flow reports. Client accounts see their company's issued records; team accounts remain excluded from financial modules.

## Rollout
Apply `supabase/009_billing.sql` once after 008, then deploy. Adds three RLS tables, recurring draft functions and credit-aware payment checks. No new packages, secrets, payment provider or scheduler changes. Original invoice totals remain unchanged; credits adjust the derived balance. Existing payment records and attendance remain intact.

## Client-team acceptance
Use agreed labelled test records. Record tester, expected/actual result and screenshots for failures.

| Role | Test | Expected |
|---|---|---|
| Admin | Create monthly schedule from invoice | Terms/prices captured |
| Admin | Generate when first date is due | Draft created, not issued |
| Admin | Generate again | Same period not duplicated |
| Admin | Check Jan 31 through February/March | Feb month end; March 31 restored |
| Admin | Pause/resume | Version checked; paused generation excluded |
| Admin | Change original invoice | Schedule snapshot remains unchanged |
| Client | Inspect while generated invoice is draft | Hidden until issued |
| Admin | Review draft and issue using existing flow | Visible to relevant client |
| Admin | Credit part of unpaid balance | Numbered note and audit record |
| Admin | Retry same credit request | Original note returned |
| Admin | Credit beyond balance or pending receipt | Rejected |
| Client | Submit payment exceeding credit-adjusted balance | Rejected |
| Admin | Verify valid claim | Verified receipt reduces balance |
| Admin | Reverse credit with reason | Balance restored; audit preserved |
| Admin | Void invoice with issued credit | Blocked until credit reversed |
| Client A/B | Inspect credit notes/invoices/report | Own company's records only |
| Team | Open portal | No financial access |
| Admin/client | Report/export and dashboard | Credit-aware balances, currencies separate |
| All | Existing attendance/projects/orders/contracts | Existing workflows available |

No real client credits, payment verifications or billing schedules were created during development. Live acceptance remains with the user's team.

## Verification
30 PostgreSQL billing workflow/security assertions, 6 billing UI assertions with simulated transport, 17 existing business utility/UI/provider assertions. TypeScript and production build passed.

## Remaining separate work
External email/SMS/WhatsApp provider setup and historical RISE CRM data migration. No claim of full RISE CRM parity. Recurring generation is manual; unattended billing automation is a separate enhancement.
