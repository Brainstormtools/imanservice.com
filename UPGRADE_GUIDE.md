# i Man Service portal upgrade

This package upgrades your existing portal with Tasks and team, AMC and SLA tracking, and Equipment. It contains your complete website source, plus one new database update. Your live website is not changed by downloading this ZIP.

## What is included

- **Tasks and team:** board and list views; Low, Normal, High and Urgent priorities; team assignments; deadlines; checklists; internal tasks; links to equipment and support tickets. Use the status selector to move a card between columns. Drag-and-drop and bulk spreadsheet task imports are not included.
- **AMC and SLA:** contracts for each client, covered services, start/end dates, renewal follow-ups, and separate response/resolution targets for every priority. Administrators manage contracts; team members and clients can read the contracts available to them.
- **Equipment:** company devices, category, serial number or asset tag, location, warranty, state, linked contract and service history. Staff maintain these records; clients can see their company's records. Notes and service history are shared with that company.
- **Service attention:** overdue SLA tickets and renewal follow-up counts in the staff workspace. These are portal alerts, not email, SMS or WhatsApp notifications. Use the refresh icon to retrieve another user's updates. Open-screen countdowns update every 30 seconds.

## Agreed SLA rules

1. Each contract has its own targets for Low, Normal, High and Urgent.
2. Both clocks start when the database creates the ticket, and count elapsed time continuously, 24/7. There are no weekends, holidays or business-hour pauses.
3. Waiting on client does not pause either clock or extend a deadline.
4. The response is the first **shared staff reply in that ticket**. A client reply, an internal note, a project conversation message, or a status change does not count as a response.
5. Resolution is recorded when staff change the ticket to Resolved. Closing without a shared reply is labelled Closed without reply, not a successful response.
6. Reopening clears the current resolution completion time and keeps the original deadlines. Status history records the transitions.
7. The project must be linked to an Active contract valid on the submission date. If a ticket names equipment, that equipment must belong to the same company, be linked to that same contract, and not be retired. Otherwise the request is saved with an explanation and no SLA.
8. New tickets snapshot the applicable targets and contract title. Contract changes, cancellations or expiry do not move existing deadlines. Priority, project and equipment are fixed on a submitted ticket; clarify an incorrect request with staff and open a corrected request if needed.
9. Contract start/end dates use UTC calendar dates, including the whole end date. Ticket deadlines are displayed in the viewer's local time zone. Targets are entered in minutes: 60 = one hour; 1,440 = one day. Resolution must be at least as long as response.
10. Existing tickets are retained and labelled **Legacy ticket — SLA not measured**. No historic response or resolution evidence is invented.

## Before applying the update

Keep the original ZIP and the current working GitHub main branch as your code backup. Have the owner or technical helper take a current database backup and confirm how to restore it. Database backups and stored files are separate. Use harmless sample records when testing on your existing database.

The update adds tables, columns, access rules and timing triggers. It does not delete existing data. It also prevents future company changes on projects, contracts and equipment, and prevents ticket identity/priority edits that would invalidate SLA evidence.

## Installation one step at a time

### Step 1 — Extract this ZIP

Open the extracted `imanservice.com-main` folder. Find this guide and the `supabase` folder. Do not upload the outer folder or the ZIP itself to GitHub.

### Step 2 — Apply only the new database update

In your existing Supabase project, open SQL Editor and start a new query. Open `supabase/002_operations.sql` from this ZIP in a text editor, copy all its contents, and paste into the new query. Check that the final line is `commit;`, then run once.

Expected: **Success. No rows returned**. If there is an error, stop and share the error text. All changes are in one transaction. Do not rerun `001_portal.sql`; that file is only for the original installation. Do not rerun `002_operations.sql` after success.

The previous website remains usable after this additive migration. Existing ticket creation then follows the new server rules. Do not configure real contracts until the preview is tested.

### Step 3 — Create a testing branch

In GitHub, select `main`, open the branch selector and create `portal-operations` from main. Check that the new branch is selected.

### Step 4 — Upload the updated code

Choose Add file → Upload files. Upload the contents inside this ZIP's `imanservice.com-main` folder to the repository root. Commit directly to `portal-operations` with message `Add task board contracts SLA and equipment`.

No new Vercel variables are required. Keep the existing `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` and website form settings. Never enter the Supabase secret or service-role key in browser variables.

### Step 5 — Open the preview

In Vercel → Deployments, find `portal-operations`. Wait for Ready, then Visit. Open `/portal` and sign in as administrator. Look for **AMC & SLA** and **Equipment** in the sidebar, and the new board inside a project's **Tasks** tab.

If operations data cannot load, confirm Step 2 succeeded in the same Supabase project used by the preview. Do not change access rules or disable row-level security to make an error disappear.

### Step 6 — Configure a test contract

Open AMC & SLA → New contract. Choose your test company, enter `TEST AMC`, select Active, use a date range including today, and record a renewal follow-up date. Enter covered services. For a short test only, set all four priorities to response **1 minute**, resolution **5 minutes**, then save. These are test values, not recommended customer commitments.

Open a test project for the same company → Overview → Edit project details. Select TEST AMC in Service contract and click Update project. A contract is explicitly selected for each project; the system does not guess between multiple company contracts.

### Step 7 — Add test equipment

Open Equipment → Add equipment. Select the same company, enter `TEST Office Router`, category Router, a sample serial/tag, location, warranty date and status In service. Select TEST AMC and save. Add one service record with today's date and harmless sample work description. Records are append-only; add a new correction if needed.

### Step 8 — Test tasks and staff access

Use an existing team account, or create its login in Supabase and assign role team in Clients & team. In the test project → Tasks, create a task with priority, team assignee and deadline. Link the test router. Add two checklist items. Change To do → In progress → Done and verify the column changes. Try the assignee and priority filters and List view. Check the same data after refresh.

Create a second task marked Internal. A client must not see that task or its checklist. Clients may view shared tasks and checklist progress but cannot edit them.

### Step 9 — Test SLA timing and equipment links

As the test client, open the test project → Support → New request. Choose TEST Office Router and submit. The saved ticket should show TEST AMC and separate response and resolution deadlines.

As staff, open the ticket. Add an internal reply and confirm the response clock still runs. Then add a shared reply: response should change to Met or Missed and retain the first reply time. Set Waiting on client and confirm the resolution deadline does not change. Resolve before or after the five-minute deadline to check Met or Missed. Reopen it and confirm the original deadline remains.

Create another test ticket and leave it unanswered for more than one minute. Refresh the staff project list: Service attention should show it as overdue. Open that project → Tasks and link a task to the ticket under Related support ticket.

Change TEST AMC's targets and create a fresh ticket. Only the new ticket should get the changed targets. A ticket for equipment with no matching contract must clearly show that it has no SLA.

### Step 10 — Check client separation and the public site

Repeat with a second company, its contract and equipment. Client A must not see Company B's contracts, equipment, service history or tickets, and vice versa. Team members may work across all companies, but only administrators can edit contracts or manage people. Disable a disposable client account and confirm it cannot retrieve these records after refresh.

Check the preview on a phone, and retest login, uploads/downloads, approvals, conversations, support and the website's enquiry forms. Ask your technical helper to check direct cross-company database/file requests; hiding screens is not a substitute for server access tests.

### Step 11 — Publish only after the preview checks pass

Create a pull request with base main and compare portal-operations. Review the changes and checks, then merge. In Vercel confirm the main Production deployment is Ready. Test administrator, team and client login on https://www.imanservice.com/portal and repeat one task, contract and equipment workflow.

Replace test targets with the actual agreed customer terms before using contracts for real work. Clearly label test records and disable unused test accounts.

## If you need to undo the website update

Revert the code merge in GitHub and deploy the earlier website version through your existing Vercel workflow. Leave the additive database migration in place; do not manually drop its tables or columns. The old portal remains compatible, but cannot manage the new modules. Server SLA triggers continue to apply to tickets until a technical maintainer deliberately changes them. A code rollback is not a database rollback.

## Verification included with this package

- Production build and TypeScript checks run locally.
- `tests/security.mjs`: original isolation tests, also run with the new migration applied.
- `tests/operations.mjs`: migration preservation, contract/equipment isolation, cross-company link rejection, first reply rules, deadline snapshots, waiting/reopening, expiry, assignments and checklist restrictions in local PostgreSQL via PGlite.
- `tests/operations-ui.cjs`: DOM interaction checks with simulated transport for contracts, task board, checklist, service history, role switching and SLA labels.

Local tests do not verify your live Supabase transport, real browser layout, delivery of account emails or hosting configuration. Complete the preview checks above before publishing. Existing invitation/reset email setup is unchanged.

For a technical maintainer, install temporary test dependencies without changing the committed lockfile:

```sh
npm install --no-save --package-lock=false @electric-sql/pglite jsdom
npm run lint
npm run build
node tests/security.mjs
PORTAL_TEST_OPERATIONS=1 node tests/security.mjs
node tests/operations.mjs
node tests/operations-ui.cjs
```

This test setup is separate from the production Bun install. Test database fixtures contain no real customer records and tests do not connect to Supabase.
