# Calendar and estimates release

## Included

**My workspace & calendar:** month and agenda views combine accessible task, milestone and project deadlines with events; personal task list includes assignments and collaborators and staff status updates. Everyone can create private events. Staff can create project events, shared with the client or internal. Private events are visible only to their owner, including when other staff are administrators. Events support editing, cancellation/restoration, optimistic version checks, in-portal reminders and monthly CSV export. Timed events display in the browser's timezone; deadlines retain their date. Events appear on their start date. Reminders show while the portal is open; no background push, email or SMS reminder delivery is activated.

**Estimates & proposals:** administrators create itemized drafts with scope, terms, currency, tax and validity. Publishing makes the saved offer visible in the relevant company's portal. Clients review the offer and explicitly confirm acceptance or decline. Published content cannot be edited. Revision creates a linked draft and supersedes the earlier offer, preserving its content. Accepted offers can create one project and one draft invoice, with retry-safe conversion. The invoice must be reviewed, given bank instructions and issued separately. Team accounts cannot access financial offers. Offer text can be downloaded; PDF generation and electronic signatures are not included.

A client decision is an authenticated portal action, not an identity-verified digital signature. No external messages are sent by publication. Use existing provider setup for external notifications separately.

## Deployment

Apply `supabase/006_calendar_estimates.sql` once after 005, then deploy the UI. It adds three RLS-protected tables and checked functions; it does not delete existing records or alter the existing SLA clock/scheduler. No new environment variables or packages.

## Team acceptance checklist

| Role | Test | Expected |
|---|---|---|
| Admin / team / client | Create private event and refresh | Event persists with correct local time; other accounts cannot see it |
| Staff | Create project event, internal | Visible to staff, absent for clients |
| Staff | Create project event, shared | Visible to the project's client company only |
| Client | Open shared event | Read-only details; no project event editing |
| Owner / staff | Edit, cancel and restore appropriate event | Correct state persists; cancelled event omitted from active calendar |
| Two sessions | Edit same event | Stale version rejected; refresh required |
| Staff | Check My open tasks | Assigned and collaborating tasks shown; status changes persist |
| All | Check month / agenda / CSV | Accessible events and task/milestone/project deadlines match |
| Owner | Event with reminder due now | Reminder shown on workspace; refresh interval 30 seconds |
| Admin | Create proposal with two taxable lines | Server calculates amounts and rounded taxes |
| Client A / B / team | Inspect offers while draft | No draft exposure; team sees no financial offers |
| Admin | Publish draft with future expiry | Relevant client sees saved revision; no external message implied |
| Client | Review and accept or decline | Explicit confirmation required; decision and time recorded |
| Two clients | Decide same offer | First decision wins; stale second decision rejected |
| Admin | Revise published or declined offer | Old content preserved and superseded; new draft private |
| Client | Try expired or superseded offer | Decision unavailable/rejected |
| Admin | Convert accepted offer to project twice | Exactly one project for that offer |
| Admin | Convert accepted offer to draft invoice twice | Exactly one draft invoice; matching total and currency |
| Admin | Review draft invoice | Add bank details and review before issuing; no automatic payment |
| All | Existing support, SLA, work logs, board and billing | Existing workflows remain available |

Record tester, account role, expected result, actual result and screenshot for any failure. Use agreed labelled test records. Live acceptance is performed by the client's team.

## Automated verification

42 PostgreSQL workflow/security assertions, 7 UI assertions using simulated transport, and the existing portal regression suite. TypeScript and production build pass. No real client decisions, offers or invoices were created during development tests.

## Remaining planned areas

Attendance; billing enhancements; orders/item catalogue; contract acceptance documents. This release is not full RISE CRM parity and does not migrate historical RISE data.
