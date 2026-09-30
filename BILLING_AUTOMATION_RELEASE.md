# Automatic recurring invoice drafts

The production database runs `public.run_billing_automation()` hourly at minute 5 (UTC). It processes one due period per active schedule, at most 100 schedules per run. Monthly schedules catch up one period each hour; manual generation remains available. Unique schedule/period records and row locks prevent duplicate periods across manual and scheduled runs. A database advisory lock excludes overlapping background runs.

Invoices remain Draft. No automatic issuance, transfer, verification, refund or message sending occurs. Source invoice snapshots remain fixed. The worker preserves notes and prices, uses the schedule creator as recorded author, and requires that creator to remain an active administrator. No user credentials or JWT identity are impersonated. Only the database owner may execute the background function.

## Failure handling and monitoring
Each completed run records start/end, generated count, failure count and status. A schedule failure rolls back its partial invoice, records a SQL error code, pauses the schedule and retains its due date. Administrators review the schedule/source/account and resume or replace it. No automatic external alert delivery is configured.

Invoices → Recurring invoice drafts shows the latest 24 runs and schedule error codes. Refresh to load new results. Missing/stale runs must also be checked in Supabase Cron history: a database outage or top-level transaction failure cannot write its own run record. The scheduler depends on the production database being available; this is not an uptime guarantee.

## Rollout
Apply `supabase/010_billing_automation.sql` once after 009. Configure as database owner:

```sql
select cron.schedule('iman-recurring-invoice-drafts','5 * * * *',
  'select public.run_billing_automation();');
```

Call the worker once and verify job history before deploying the interface. Do not create duplicate named jobs. Inspect `cron.job` and `cron.job_run_details`. To stop automation, set the named job inactive in Supabase Cron, or pause individual invoice schedules in the portal. No new packages, keys or provider settings.

## Team acceptance checklist
| Role | Test | Expected |
|---|---|---|
| Admin | Create labelled test schedule due today | Active monthly schedule |
| Admin | Wait for hourly run without portal open | One draft and linked period |
| Admin | Refresh background run history | Finished time/count/status |
| Client | Inspect new invoice before issuance | Hidden draft |
| Admin | Run manual generation near scheduled run | One invoice per schedule/period |
| Admin | Pause schedule | No future generation |
| Admin | Disable schedule creator in disposable test workflow | Schedule pauses with error code |
| Admin | Review failed schedule | Due date unchanged, no partial invoice |
| Admin | Resume corrected schedule | Next run processes retained due period |
| Client/team | Inspect job monitor | No access |
| Admin | Review and issue draft separately | Existing issuance process applies |
| Admin | Inspect Cron run failure/stale history | Operational issue identified |

No real client schedule or invoice was created during development. The user's team performs live role-based acceptance using labelled records.

## Verification
45 PostgreSQL automation/billing regression assertions and 6 billing UI assertions passed, plus TypeScript and production build. Database tests simulate identities on PostgreSQL-compatible PGlite. UI transport is simulated.

Remaining separate work: external messaging-provider setup and historical RISE CRM data migration.
