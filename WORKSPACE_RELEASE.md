# Workspace management release

Four upgrades based on the client's supplied RISE screenshots. This is a focused release, not full RISE CRM parity.

## Included

1. **Dashboard**: accessible project/task/ticket totals and status charts; overdue and assigned/collaborating tasks; issued invoice balances separated by currency for administrators and clients; staff-only recent activity. Pending payments are excluded. Activity starts with this migration.
2. **Client directory**: company contact information and labels; searchable companies; active contact counts and open project counts; administrator-managed contacts with staff-only notes and archive state. Team members can read the directory. Contacts do not create accounts or grant portal access; use existing Clients & team administration for accounts/new companies.
3. **Project portfolio**: searchable table, client/status/date filters, sorting, visible task completion counts, CSV export, start dates and labels. CSV/XLSX import creates new projects; use company IDs from the provided reference.
4. **Task planning**: start/deadline dates, same-project milestones, active staff collaborators, labels, search, milestone filter, CSV export, a date-based Gantt view and atomic bulk changes to status, priority, assignee, milestone or deadline. The existing board, checklists and task import remain available below planning.

Gantt is a read-only schedule display. It does not implement dependencies, critical path or automatic rescheduling. Unscheduled tasks remain in Table/Board views. Bulk selection remains selected when filters change; its count is shown before applying. Clients cannot edit task plans.

## Import behavior

Clients (administrator only) and projects (staff) accept CSV/XLSX, first worksheet, maximum 500 rows and 5 MB. Download the template, populate it, upload and review the preview, then confirm. Dates must be text YYYY-MM-DD. Labels are comma-separated, at most 20 labels of 40 characters each. Imports create records; they do not match, merge or overwrite existing clients/projects. Repeating the same request ID after a transport error does not duplicate records; uploading the same file as a new batch can create duplicates. A failed row rolls back the entire batch.

## Deployment

Apply `supabase/005_workspace.sql` once after 004, then deploy the interface. No new secrets or scheduler jobs are required. Existing SLA scheduling is unchanged. This migration adds contact, import and staff activity tables plus planning fields; it does not delete existing records.

## Team acceptance checklist

| Role | Action | Expected |
| --- | --- | --- |
| Admin | Open Dashboard | Counts and currency-separated balances match existing records |
| Team | Open Dashboard | No invoice balances or billing data |
| Client A/B | Open Dashboard and projects | Only own company's accessible records |
| Admin | Open Client directory, edit company, add/edit/archive a contact | Changes persist; notes visible to staff only |
| Team | Open directory | Can read; cannot edit contacts or import clients |
| Admin | Import 2 sample clients with template | Preview before save; both created together |
| Staff | Import 2 projects with valid company IDs | Both created with dates and labels |
| Staff | Try batch with invalid company/date | No partial import |
| Staff | Filter portfolio by company/status/overdue/label and export | Matching rows only in export |
| Staff | Edit project start date and labels | Dates validated and values preserved |
| Staff | Plan a task with milestone, collaborator and labels | Saved values remain after refresh |
| Staff | Open Gantt | Dated tasks have correctly positioned bars; unscheduled count shown |
| Staff | Select 2 tasks and bulk-change priority/status | Only selected tasks change together |
| Client | Open task planning | Table/Gantt visible; staff editing controls absent |
| Staff | Use existing board, checklist, SLA, work logs and sign-off | Previous workflows remain available |

Record the tester, expected/actual result and screenshot for failures. Use clearly labelled agreed test records.

## Automated verification

34 PostgreSQL workflow/security assertions; 10 UI/import assertions; 17 existing portal UI regression assertions. TypeScript and production build pass. UI tests use simulated transport; live acceptance remains with the client's team.

## Remaining backlog

Calendar/personal workspace; attendance; recurring billing/credit notes/payment reporting; orders/item catalogue; contract acceptance documents; estimates/proposals. External email/SMS/WhatsApp sending still requires provider setup. No historical RISE data was migrated in this release.
