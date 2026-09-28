# Upgrade verification

Source: user-supplied `imanservice.com-main.zip`, archive commit `21a5982c41defb95f3751ef35af2b10abbd17b0b`.

## Passed locally

- TypeScript check (`npm run lint`).
- Production build (`npm run build`).
- 33 original database/access assertions against the original migration.
- The same 33 assertions after applying the operations migration.
- 63 additional PostgreSQL assertions covering migration preservation, SLA timing, contract/equipment links, immutable ticket evidence, cross-company access, disabled accounts and task checklists.
- 17 DOM interaction and SLA-display checks, including contract creation, task movement, checklist updates, service records and switching from administrator to client.
- Original `001_portal.sql` preserved byte-for-byte. No public website pages, API handlers, package dependencies, lockfile or hosting settings were changed.

## Scope of this evidence

Database tests use PGlite with simulated Supabase auth/storage schemas. UI interaction tests use jsdom and a simulated transport. These tests do not contact the live site or Supabase account.

Real browser visual/responsive QA and hosted integration tests have not been completed for this upgrade. Follow the preview checklist in `UPGRADE_GUIDE.md`, including the original login, file, approval and support workflows. The archive contains source code; no hosted deployment was performed.

## Files to review

- `supabase/002_operations.sql`: additive database migration and server access/timing rules.
- `src/portal/operations.tsx`: task board, contracts, equipment and SLA displays.
- `src/portal/Portal.tsx`: integration with the existing portal.
- `src/portal/portal.css`: responsive module styles.
- `tests/operations.mjs` and `tests/operations-ui.cjs`: new verification suites.
- `tests/security.mjs`: optional operations-migration regression mode.
- `UPGRADE_GUIDE.md`: setup, semantics, preview tests and code rollback guidance.
- `PORTAL_SETUP.md`: original setup guide with updated routing to the upgrade guide.
