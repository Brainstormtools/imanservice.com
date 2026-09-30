# Staff attendance release

Includes staff check-in/out, personal history, administrator corrections with immutable audit history, monthly totals and CSV export. Clients cannot read attendance. Administrators see all staff records; team accounts see only their own. Disabled accounts lose access. Repeated clock requests do not duplicate open sessions. Corrections require a reason and displayed record version, reject overlaps/future timestamps, and preserve prior values. Records can be voided without deletion.

Times use Asia/Karachi (UTC+5). Reports assign each session to its check-in month. Hours include only closed, non-voided sessions, without rounding beyond display formatting. Sessions may last up to 48 hours; older open sessions require administrator correction. This is attendance recording, without leave management, overtime rules, payroll, GPS or biometric verification. Project work logs remain separate.

Also fixes sidebar class names that incorrectly contained module components.

## Rollout
Apply `supabase/008_attendance.sql` once after 007, then deploy. Two RLS tables and checked RPC functions; no new secrets, packages or scheduler changes.

## Client-team testing
Use labelled test staff accounts and record expected/actual results and screenshots of failures.

| Role | Test | Expected |
|---|---|---|
| Team | Check in, refresh and retry | One open session |
| Team | Check out and refresh | Closed session with server time |
| Team A/B | View history | Own records only |
| Client | Navigate portal | No attendance navigation or data |
| Admin | View monthly report | All staff, staff filter and totals |
| Admin | Add missed session with reason | Past timestamps persist in Pakistan time |
| Admin | Correct existing record | Version increments; prior values retained in audit |
| Admin | Submit stale correction | Rejected; refresh required |
| Admin | Enter overlap, future or over-48-hour session | Rejected |
| Admin | Void entry | Record/history retained, hours excluded |
| Staff | Export CSV | Selected month's permitted rows and hours |
| Admin | Disable test staff account | Attendance read/write denied |
| All | Existing projects, orders, contracts, calendar | Navigation and workflows available |

## Verification
27 PostgreSQL security/workflow assertions, 5 UI assertions with simulated transport, 9 orders/contract UI regression assertions. TypeScript and production build pass. Live role-based acceptance remains with the user's team.

## Remaining
Billing enhancements: recurring invoices, credit notes and payment reporting. External messaging provider setup and historical RISE data migration remain separate.
