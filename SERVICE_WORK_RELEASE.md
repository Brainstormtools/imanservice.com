# Service work release

Adds technician work records, client completion review and supervisor SLA escalation to each project's **Service work** tab.

## Roles and workflow

1. Administrator selects a project supervisor. Without a valid assigned supervisor, escalations fall back to active administrators.
2. Technician records a ticket or task, date, minutes, work performed, visit type and parts. Internal entries remain staff-only. Entries are immutable; the author or administrator can void an entry with a reason.
3. Staff resolves the ticket and requests completion review. The request preserves a snapshot of shared ticket work records.
4. A client belonging to that project company accepts or requests changes. Staff cannot accept on the client's behalf. Changes require feedback and reopen the ticket. Staff can resolve it and request a new revision.
5. Overdue response and resolution targets create separate supervisor escalations. Acknowledgement records an action note and does not stop or reset the SLA clock.

SLA timing continues 24/7 against each client's contract targets, including while awaiting client feedback. Reopening preserves the original deadlines. Escalations are deduplicated against the original deadline.

## Deployment

Apply `supabase/004_service_work.sql` **once**, after migrations 001–003, before deploying the new interface. The transaction creates four protected tables and checked RPCs. It wraps the existing `queue_due_alerts()` function, so the existing once-per-minute `iman-maintenance-and-alerts` database job also scans escalations. No additional cron job is needed.

Verify the migration and the next successful cron run, then merge the release PR and confirm the production deployment. Email/SMS/WhatsApp delivery still requires the provider credentials and HTTP worker configuration described in BUSINESS_RELEASE.md. Queue creation alone is not delivery.

## Client acceptance checklist

Use agreed test projects and clearly label test tickets. Record expected result, actual result, tester and screenshot for any issue.

| Tester | Check | Expected result |
| --- | --- | --- |
| Staff | Add a 30-minute ticket work record with parts and a visit note | Entry and total time appear |
| Staff | Add an internal work record | Staff can see it; clients cannot |
| Client B | Open another company's project or record | Access denied; no private records visible |
| Staff | Request completion review before resolution | Request rejected |
| Staff | Resolve ticket and request review | Pending review contains shared work evidence |
| Client A | Request changes with feedback | Ticket reopens; original SLA deadlines remain |
| Staff | Resolve and request review again | New revision; previous review remains in history |
| Client A | Accept completion | Acceptance records client and time |
| Staff/admin | Attempt to accept as client | Operation unavailable/rejected |
| Admin | Select project supervisor | Routing saved |
| Supervisor | Review an overdue test ticket after scheduled scan | Response/resolution escalations appear as applicable |
| Supervisor | Acknowledge with action note | Acknowledgement saved without resetting SLA |
| Staff | Resolve overdue ticket | Escalations clear on next scan |
| Staff | Reopen it | Original breach reactivates without a duplicate record |

Use short agreed SLA targets for escalation testing rather than changing historical production deadlines.

## Verification

- TypeScript check and production build passed.
- 41 database assertions passed, including access isolation, immutable evidence, review transitions and escalation scheduling.
- 6 service UI interaction assertions passed.
- 17 existing operations UI regression assertions passed.

UI tests simulate transport; the client's team should complete the live acceptance checklist after deployment.
