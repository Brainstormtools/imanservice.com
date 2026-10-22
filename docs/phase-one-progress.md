# Phase 1 — leads, deals and quotations

The client has requested sequential development by the six **build phases** in the uploaded 41-page SRS. Seven modules are not seven build phases. Complete and release Phase 1 before starting further later-phase development. Client-owned live/browser/export/device acceptance is tracked separately; none of the 41 acceptance items is passed by automated tests.

The client authorizes reasonable documented assumptions instead of waiting for unanswered business questions. Previously confirmed decisions still take precedence. Configurable defaults are preferred. Actual people, assignments, credentials, contacts, transactions and business records are not invented. External email/SMS/WhatsApp delivery remains excluded. This instruction does not make a missing external-provider authorization available.

## Current Phase 1 development status: in progress

| SRS Phase 1 requirement | Repository status / next action |
| --- | --- |
| Manual lead entry and mapped CSV/Excel import | Existing implementation; included in regression verification. |
| Normalization, phone/email deduplication and repeat enquiry history | Existing manual/import path; website path being reconciled and tested. Preserve actual ownership and original acquisition. Conflicting contacts/customer matches require private review. |
| Website enquiry capture | Contact/proposal handlers and browser submission identity restored from an earlier unreleased branch, reconciled through a new migration. New durable abuse limiting and eligible in-app notification. Release verification pending. |
| API-key lead capture | DEV-003 remains pending. Build controlled source connections and ingestion; never expose a service-role key. |
| Facebook/Instagram lead-ad intake | DEV-002 remains pending. Implement verified webhook/retrieval and source mapping. No Meta credential bindings were found in the target Vercel project; actual provider activation requires an authorized account/app connection. |
| Optional administrator-configured automatic routing | DEV-004 remains pending. Only actual administrator-selected boards/eligible owners; no invented assignments or silently seeded rules. |
| Raw Lead Board statuses, List/Kanban, filters, saved views and bulk assignment | Existing implementation; verify detailed SRS behavior before phase closure. |
| Product boards, memberships, stage rules, activities, multi-product deals and Won/Lost | Existing core implementation; detailed SRS audit remains open, including board creation/custom fields and product changes. |
| Product catalogue, combined quotation/BOQ, document versions and roles | Existing core implementation; detailed Phase 1 requirement-to-test audit remains open. Later project execution/finance adoption work is not substituted for this audit. |

This is the initial Phase 1 map, not a claim that the four intake packages cover every sentence of the SRS. Check the detailed module 1/2 and quotation requirements before declaring Phase 1 complete. Record newly discovered development gaps explicitly.

## Website increment assumptions and boundaries

Website forms retain their existing validation and actual raw phone text. Only unambiguous international numbers become structured phone identities; an ambiguous local phone is not guessed. Email is normalized, genuine repeat enquiries retain their own source/form/UTM/message history, identical retries are idempotent, and no public contact lookup/lead ID is returned. Receipt and origin-limit tables remain private with RLS/no browser writes.

Technical abuse default: 20 new enquiries per server-derived origin fingerprint in ten minutes, configurable through server-only `WEBSITE_INTAKE_WINDOW_LIMIT` (1–100). Exact confirmed retries do not consume another budget. Raw IPs and service keys are not stored in the limiter or returned to the browser. The limiter's inactive buckets expire after a day; business enquiry receipts are retained independently.

New unassigned website enquiries notify existing active Admin/Sales Manager accounts with actual current sales permissions and enabled portal reminders. Repeat enquiries notify the actual existing eligible owner. These notifications do not create assignments. No external delivery is enabled; optional legacy consultation-webhook behavior is preserved, and no webhook binding was present during inspection.

The earlier hosted-only `capture_website_crm_lead` function and private receipt table were inspected read-only. Their objects existed, but no website-intake migration history entry was present. The new CLI-generated reconciliation migration records the supported schema, preserves existing receipts and adds the bounded v2 endpoint. Existing migration 141 and all prior migrations must not be reapplied. Held finance migrations 142–148/PRs #223–229 stay separate and unapplied.

## Closure rule

Say **“Phase 1 development is complete and live on the portal”** only after its remaining SRS requirements are implemented, tested, merged through PRs, deployed to the intended production project, and the exact release is verified. Provider setup that remains unavailable must be disclosed; a READY build alone does not verify an operational Meta connection. Client acceptance stays separate.
