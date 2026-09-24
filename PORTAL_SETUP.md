# i Man Service — original portal setup

**Existing installations:** use `UPGRADE_GUIDE.md` and run only `supabase/002_operations.sql` for this update. This document describes the original installation and its original verification status. For a new installation, apply `001_portal.sql` once and then `002_operations.sql` once. The current upgrade adds contracts, SLA clocks, equipment and task boards; see the upgrade guide for current behavior.

This ZIP adds an original project-management application to the supplied React/Vite website at `/portal`. It is not RISE software and contains no RISE code. The public website, contact/proposal handlers, branding and existing routes remain in the project. A Client portal link is included in desktop and mobile navigation.

## What is implemented

- Email/password login, password-reset flow and invitation password setup.
- Admin, team and client roles. Accounts without a profile have no project access.
- Admin: create client companies and assign existing authentication accounts to roles/companies.
- Team/admin: create and edit projects, set deadlines/status, create and assign tasks, schedule milestones and update progress.
- Client: view only their company's projects, shared tasks, milestones and deadlines.
- Private project files: upload/download with a 10 MB per-file limit. Supported formats: PDF, PNG, JPG, TXT, CSV, ZIP, DOCX and XLSX.
- Team deliverables with client approval/change requests and immutable decision history. A revision is a new file; the previous file's approval does not approve the revision.
- Project conversations and ticket replies. Internal messages/tasks are visible to team/admin only.
- Client and team support requests with priority and staff-managed status.
- Search projects, refresh, responsive layout, loading/error/empty states.

Clients assigned to the same company share that company's projects, files and support requests. Staff can access all companies. There is no per-project staff restriction in this version. Any client contact in a company may approve that company's deliverables. Confirm these rules match your business before adding real clients.

## Current status

Source implementation is complete for this first version. It has not been connected to your Supabase account or deployed to your Vercel account. There are no real client records or credentials in the ZIP. If environment variables are absent, `/portal` shows an honest setup-pending screen rather than a fake login or sample data.

You need a Supabase project for authentication, PostgreSQL and private file storage. Free plans may support a small pilot; confirm current limits and commercial-use terms with Supabase and Vercel. Zero recurring cost is not guaranteed. Existing website webhook environment variables must be retained.

## 1. Create the backend

1. In your own Supabase account, create a new project. Use a region appropriate to your clients.
2. Open the SQL editor and run `supabase/001_portal.sql` once. It creates the schema, access policies and private `project-files` bucket in one transaction. It is an initial migration, not an idempotent script; do not rerun it after success.
3. In Authentication settings, disable public user signup. Accounts should be created/invited by the owner. The application does not include public signup, and unassigned users cannot access business data even if signup is accidentally enabled.
4. Set Authentication Site URL to `https://www.imanservice.com/portal`. Add that exact URL to permitted redirect URLs. For local testing only, add `http://localhost:3000/portal`. Add staging URLs explicitly, not a broad production wildcard.
5. Configure email delivery for invitations/password resets. Verify delivery with test accounts. Production email may need your own SMTP provider; do not assume the default mail service is adequate for clients.
6. Review password strength, email confirmation and rate-limit settings in Supabase. The app requires at least 12 characters in its password setup form; also enforce your password policy in the provider settings.

## 2. Configure the website

Copy `.env.example` to `.env.local` for local development and set:

```dotenv
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_PUBLIC_PUBLISHABLE_OR_ANON_KEY
```

These two values are intentionally public. Database and storage RLS enforce access. Never put the service-role/secret key in a `VITE_` variable, source code, ZIP or browser. Keep existing `CONSULTATION_WEBHOOK_URL` configuration for website enquiry forms.

The project retains the Bun package manager and updated `bun.lock`:

```sh
bun install --frozen-lockfile
bun run lint
bun run build
bun run dev
```

`lint` in this repository is TypeScript checking. Run from the project root. The dev server uses port 3000.

In Vercel, use the existing project's normal Git deployment workflow. Add the two public variables to the intended environment, preserve existing variables, select Vite, use `bun install --frozen-lockfile`, build `bun run build`, and publish `dist`. The existing rewrite supports direct visits to `/portal`. Environment changes need a new build because Vite embeds these public values at build time.

Deploy to a preview first and run the acceptance checks below before promoting to production. No production deployment was performed in this session.

## 3. Create the first administrator

In Supabase Authentication → Users, create/invite your own account. Copy its UUID. Run this once in the SQL editor, replacing the example UUID and name:

```sql
insert into public.profiles (id, name, role)
values ('REPLACE_WITH_YOUR_AUTH_USER_UUID', 'Your name', 'admin');
```

If invited by email, follow the invitation link to set a password. Alternatively use the portal's “Set or reset your password” form after creating the account. Do not share passwords in chat or email. Sign in at `/portal`.

## 4. Add clients and team members

1. As admin, open Clients & team and create a client company.
2. Create/invite the person's account in Supabase Authentication. Copy its user UUID.
3. In Clients & team → Grant account access, enter that UUID, their display name and role. For clients, select their company. For team/admin, leave company blank.
4. Ask the person to follow their invitation or use the password-reset form. Until a profile is assigned, they see “awaiting access” and have no project access.
5. Create a project for the company, then add tasks, milestones and shared deliverables.

This version manages invitations in the Supabase dashboard; there is no in-app email invitation service or provider-secret key. The browser administration form only assigns already-created accounts. Duplicate account assignments are rejected. Use “Disable access” in Clients & team to immediately block a person's project access while preserving historical records. All project access functions check active membership, including for existing sessions. Also revoke sessions/disable the account in Supabase Authentication when offboarding. Already-downloaded files cannot be recalled.

For changes to an existing role or company, use the owner SQL editor:

```sql
update public.profiles
set role = 'client', company_id = 'CLIENT_COMPANY_UUID'
where id = 'AUTH_USER_UUID';
```

Do not disable RLS to work around access issues. Do not disable the sole administrator before assigning another trusted administrator.

## 5. Before inviting real clients

Use test users belonging to two different test companies.

- Client A sees only A's projects; client B sees only B's projects.
- Direct API requests for B's project/file IDs with A's token return no data or access denied.
- Internal tasks and internal notes never appear to clients.
- Client cannot change roles/company/project status or mark a file as a team deliverable.
- Anonymous requests cannot read project data; an authenticated user without a profile sees none.
- Upload a permitted file, refresh, download it and compare the contents. Oversized files are rejected by the storage service.
- Test a different company's storage path directly; download/upload must fail. The bucket must remain private.
- Upload a deliverable as staff. Approve it as a client, request changes and verify both decisions remain in history. Upload a revision and verify it requires a new approval.
- Create a ticket, reply as staff, add an internal reply, and resolve it. Verify the client can see shared replies only.
- Test actual invitation and reset emails, expired links, wrong passwords, sign-out and a fresh login.
- Check the public website and enquiry forms on the Vercel preview.
- Establish backups and recovery appropriate to your service. Back up private storage objects separately from database metadata.

## Security design and limits

RLS is enabled on every portal table. Access derives from `auth.uid()` and the server-side profile, never from a client-submitted role/company. Only admins may assign profiles. Helper functions use a fixed empty search path and explicitly qualified table names. Anonymous access is revoked. Storage policies check the project in the object path and protect finalized objects from browser deletion. Files download through authenticated storage requests, not public URLs.

Clients cannot alter approval history, authorship, project details, internal messages or deliverable flags. File metadata requires an actual uploaded object owned by the current user. A failed metadata save attempts to clean up its orphan upload. Monitor orphaned uploads periodically.

Files are restricted by size and accepted MIME types, but the app does not scan malware or verify file signatures. Treat downloaded files as untrusted. No realtime subscriptions, automatic support emails, SLA escalation engine, invoicing, time tracking, SSO, MFA UI or immutable administrator audit system are included. Updates appear after an action or manual refresh. All roles share the same login page. This release uses standard Supabase browser session persistence; avoid shared browser profiles and sign out on shared computers.

## Verification performed

- TypeScript check and production Vite build.
- Browser visual/interaction QA could not run because the browser binary was unavailable and its download timed out. Complete that QA on a Vercel preview before launch.
- 33 PostgreSQL row-level-security assertions in PGlite, using simulated Supabase auth/storage schemas, including cross-client access, role escalation, internal notes, file ownership and immutable approvals. See `tests/security.mjs`.
- Hosted Auth, SMTP, real storage transport and production Vercel integration require the account-level acceptance checks above; local simulation is not a substitute for them.

Run the security test in an isolated temporary directory with `@electric-sql/pglite` installed, or temporarily install it with `npm install --no-save --package-lock=false @electric-sql/pglite` and run `node tests/security.mjs`. The test creates a fresh in-memory PostgreSQL database and does not connect to your hosted database.
