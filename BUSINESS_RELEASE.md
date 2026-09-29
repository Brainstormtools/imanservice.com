# Six business modules — deployment and acceptance guide

This release adds notification channels, CSV/XLSX task import, a drag-and-drop task board, SLA reports, bank-transfer billing, and recurring maintenance. The existing 24/7 contract-specific SLA rules remain in place.

## Deployment status — 29 September 2026

Migration 003 is applied to the live portal database. Direct authenticated invoice UPDATE privileges were verified false. The database job `iman-maintenance-and-alerts` is active every minute; a successful automatic execution was verified at 05:55 UTC. PR #3 has been merged into main.

Maintenance and alert queuing run directly in Postgres, independently of the Vercel notification worker. Reproduce the installed job as the database owner with:

```sql
create extension if not exists pg_cron;
select cron.schedule('iman-maintenance-and-alerts', '* * * * *',
  $job$select public.generate_maintenance(); select public.queue_due_alerts();$job$);
```

Email/SMS/WhatsApp **delivery is not activated**. Complete the sender credentials, server variables, and HTTP worker schedule below to enable it. Calling the worker in addition to the database schedule is safe: maintenance occurrences and notification event keys are deduplicated. Do not rerun migration 003 on this database.

## Deployment order

1. Back up the database using your normal Supabase backup procedure. Test against a staging project first.
2. Apply `supabase/003_business.sql` once, after migrations 001 and 002. Do not rerun the older migrations. The new migration is transactional and adds tables/functions without dropping existing client data.
3. Deploy the branch to Vercel. Existing browser Supabase variables remain unchanged. Add the server-only variables below in Vercel; never put secrets in GitHub, chat, or `VITE_` variables.
4. Complete the acceptance workflow with two test client companies, one administrator, and one team account.
5. After migration and acceptance checks, merge the release PR for production. Configure the production scheduler separately; preview deployments must not run the production worker.

## Server settings

| Variable | Purpose |
| --- | --- |
| SUPABASE_URL | Same project's database API URL |
| SUPABASE_SERVICE_ROLE_KEY | Server-only service-role key from that project |
| CRON_SECRET | Random secret of at least 32 characters, shared only with the scheduler |
| PORTAL_PUBLIC_URL | `https://www.imanservice.com/portal` |
| NOTIFICATIONS_ENABLED | Keep `false` until provider and recipient setup is complete; set `true` to enable submissions |
| RESEND_API_KEY / NOTIFICATION_FROM_EMAIL | Resend key and verified sender |
| TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN | Twilio credentials |
| TWILIO_SMS_FROM | SMS-capable sender in international format |
| TWILIO_WHATSAPP_FROM | Approved sender, including `whatsapp:` prefix |
| TWILIO_WHATSAPP_CONTENT_SID | Approved static WhatsApp service-update template with the portal sign-in URL and no template variables |

Redeploy after changing Vercel environment variables. Provider registration, sender verification, destination permissions, WhatsApp template approval, and provider charges are account-owner setup steps. Provider acceptance is recorded as **Submitted**, not confirmed delivery.

## Continuous background processing

The endpoint `POST /api/portal-worker` requires `Authorization: Bearer <CRON_SECRET>`. It generates maintenance tasks, queues overdue/renewal alerts, and submits up to five notifications per request. Overlapping workers cannot claim the same queue entry. A slow/interrupted submission becomes **Unknown** and must be reconciled with provider logs; it is never blindly resent.

Use a production scheduler every minute. In Supabase enable Cron (`pg_cron`) and `pg_net`. Store the same CRON_SECRET in Vault as `portal_worker_secret` using the secure dashboard. Then run the following as the database owner. Do not paste an actual secret into this committed file.

```sql
select cron.schedule('iman-portal-worker', '* * * * *', $job$
  select net.http_post(
    url := 'https://www.imanservice.com/api/portal-worker',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (
        select decrypted_secret from vault.decrypted_secrets
        where name = 'portal_worker_secret'
      )
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
$job$);
```

Check both Cron history and `net._http_response` for HTTP success; a scheduled HTTP request alone does not prove the worker succeeded. The worker's 401 means secret mismatch, 503 means missing database configuration, and 500 means database execution failed. Confirm a scheduled task appears without a portal session open. Pause the named Cron job to stop background runs. Service availability depends on the hosting/database services remaining active; this is not an uptime guarantee.

Maintenance generation catches up at most 50 occurrences per plan and 500 overall per call. Retired equipment and completed plans are skipped. Each `(plan, due date)` can generate only one task. Queue capacity is five submissions per minute at this schedule; monitor backlog and adjust worker capacity/schedule for larger deployments.

## Client-team acceptance workflow

Use clearly named TEST records and consenting test recipients. Record expected result, actual result, pass/fail, screenshot, and tester for each scenario. Never submit a real bank payment merely to test the portal.

| Module | Administrator/team test | Client test and expected boundary |
| --- | --- | --- |
| Notifications | Configure channels; opt in designated test accounts; assign a task, create/reply to a support ticket, issue an invoice, submit/review a test payment; inspect queue and provider logs | Opt in/out to email/SMS/WhatsApp; only own company's events appear. Generic reminder contains no task or financial detail. Disabling a preference cancels pending submissions at worker processing |
| Bulk import | Download template from a project's Tasks tab. Import valid CSV and XLSX; confirm preview, assignee, deadline, visibility and count. Retry same batch after simulated connection loss | Clients cannot import. Mixed valid/invalid rows must save nothing. Import cannot target another project via a column |
| Task board | Drag a task between lanes; refresh and verify persistence. Use status selector on keyboard/mobile | Clients see shared tasks but cannot drag or change staff-only task state |
| SLA reports | Filter company and ticket creation dates; export CSV and print/save PDF; compare a met, missed, pending, overdue and unmeasured ticket | Client A never sees Client B's reports. Contract-specific targets and 24/7 clocks are preserved. Completed compliance excludes pending/overdue/unmeasured tickets, shown separately |
| Billing | Save draft with line items/tax; issue; verify partial bank reference; reject a claim; reverse a verification with reason; inspect audit history | Client sees own issued invoices only; submitting reference leaves payment Pending. Only admin verifies. Team role cannot read billing. No online card charging is included |
| Maintenance | Create daily, weekly and monthly plans with checklist; generate twice; pause/resume; test Jan 31 -> Feb end -> Mar 31; confirm scheduled run without browser | Client sees own shared plans/tasks. Internal plans hidden. Pausing preserves existing tasks; changed frequency needs a new plan |

Import limits: 500 rows, 5 MB source file, first XLSX worksheet, no formulas/macros, dates as text `YYYY-MM-DD`, staff UUIDs listed in import panel. Old XLS files must be converted to CSV/XLSX. Downloaded CSV text is protected against spreadsheet formula interpretation.

Invoices use manually entered tax rates and bank instructions. This is a bank-transfer ledger, not a tax engine or payment gateway. An issued invoice is immutable; an unpaid invoice can be voided. Payment references must be verified against the real bank statement by the administrator. No bank account integration is performed.

## Rollback

If application rollback is needed, redeploy the previous production deployment and pause the scheduler. Leave the additive tables in place to preserve invoices, payment history and generated work. Do not drop new tables or delete generated client records as a rollback shortcut. Set NOTIFICATIONS_ENABLED=false and redeploy to stop new provider submissions.

## Automated verification

`npm run lint` and `npm run build`. Database tests use PGlite; UI/provider tests use jsdom and esbuild with fake network responses. No real notifications or bank transfers are sent by tests. Run `node tests/business.mjs`, `node tests/business-ui.cjs`, and the existing security/operations suites with those test dependencies installed.

Live database migration, configured provider delivery, and scheduled execution must still be verified in the deployment environment; local tests do not establish those facts.

References: [Supabase scheduling](https://supabase.com/docs/guides/functions/schedule-functions), [Cron operations](https://supabase.com/docs/guides/cron/quickstart), [Resend send API](https://resend.com/docs/api-reference/emails/send-email), [Twilio approved templates](https://www.twilio.com/docs/content/send-templates-created-with-the-content-template-builder).
