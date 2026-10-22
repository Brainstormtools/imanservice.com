# Phase 2 development checkpoint

Updated 23 October 2026. Scope: Brainstormtools/imanservice.com portal only. User authorization now permits sequential SRS phase development without waiting for Vercel deployment. Earlier draft PR #245's production-before-development gate is superseded. Its existing-code audit and bounded sequence remain useful, but are not completion evidence.

## First bounded increment: planning and conversion UI access

`crm-project-planning.tsx` now scopes Configurator state to actual account, active status, role and CRM permissions. Won conversion additionally scopes to Deal identity, version and owner. Inactive accounts and client roles cannot query these private staff workflows even if a supplied permission label matches. Account/authority/Deal changes discard local state immediately. Mounted/epoch guards reject delayed reads from obsolete instances and failed reads clear server snapshots; failed Configurator reads also clear the selected private template draft. Same-authority successful reloads preserve manually entered template content. Server permissions and conversion semantics are unchanged.

`tests/planning-access-ui.cjs` adds 11 isolated UI checks covering these access boundaries, failed reads and delayed cross-account/Deal responses. The existing 17 planning UI checks continue to cover template reuse, parameters, exact accepted-publication conversion and existing sale results. Test results are recorded in the release PR once complete. No migration or production data mutation is required.

This is the initial Phase 2 access-hardening increment, not completion of Accounts routing, scheduled payments, customer creation, full Configurator, calendar, PWA or Phase 2.

## Remaining ordered development

1. Inspect latest Won-conversion overrides and integration tests. DEV-006: manual actual Accounts routing with current eligible recipient validation, atomic immutable routing evidence and in-portal notification semantics. Never choose an employee automatically.
2. DEV-007: duplicate-safe actual customer linking/creation without silently merging contacts or granting accounts. Preserve accepted quotation customer identity and resolve conflicts explicitly.
3. DEV-005: later scheduled payment drafts tied to actual accepted terms. Drafts are not posted invoices or invented payment dates; Phase 3 financial accounting stays separate.
4. Reviewed standards/QA/SOP, criteria and parameterized import gaps; route/device-linked execution; task/dependency/baseline revisions; actual resource capacity/tool booking; calendar/activity continuity; field PWA audit, in bounded tested increments.

Use actual configured calendars, standards, rates, recipients and people. If required business data is absent, show missing configuration rather than inventing shifts, holidays, salaries, skills, targets or assignments. Existing user decisions on training certificates, Deal TADA and change-order finance/execution remain authoritative. External email/SMS/WhatsApp delivery is excluded. No native/mobile offline-sync completion claim is made from web PWA installation/public fallback support.

## Release and acceptance

Keep code development, tests, PR merge, migration application, production release and client acceptance separate. Phase 1 final release is still waiting on Vercel; all five recently applied Phase 1 migration versions are recorded in the requirement documents and must not be repeated. No production test fixtures are allowed. Necessary future migrations are tested locally and tracked as unapplied until coordinated with release, unless an explicitly compatible independent application is justified.

Do not retry the blocked Supabase CLI status/telemetry action or the capped manual Vercel create-deployment endpoint. The user confirmed the same daily-cap error manually. Review cumulative release compatibility and apply only new required migrations once before eventual deployment. Verify exact production source/domain/assets before saying live. All 41 client-owned signed-in/browser/export/device acceptance items remain pending; actual Meta connection is separate. No whole-phase or CRM completion is claimed here.
