# Optional administrator-configured lead routing

This Phase 1 increment is prepared on a separate branch following merged Meta intake [PR #233](https://github.com/Brainstormtools/imanservice.com/pull/233), which follows merged API intake [PR #232](https://github.com/Brainstormtools/imanservice.com/pull/232). Its new migration `20261022101932_phase_one_lead_routing.sql` is unapplied. Production remains the earlier verified deployment; newly discovered exact API/Meta automatic previews are READY, so normal Git-based release is being verified after final regression/merge. This is not live routing or completion of Phase 1.

## Configure actual rules after release

An active Administrator opens **Sales board configuration → Optional lead routing**, then explicitly loads the current register. No rules, owners, boards, business criteria or follow-up intervals are seeded or preselected. With no enabled matching rule, existing intake behavior remains unchanged.

For a new actual rule, enter its actual name and priority (1–9999), at least one exact source/form/campaign condition, actual product boards, actual eligible owner(s), owner method and follow-up interval. Enter a reason and tick the fresh confirmation. New rules start inactive; tick **Enable this exact actual routing rule for future leads** only when the actual configuration is intended to run. Revisions require the exact current version, a new reason and fresh confirmation. Disable a rule by saving an explicitly unchecked enabled action; its immutable history remains, even if a previously selected owner/board has become unavailable.

Supported source labels currently include `Manual`, `CSV import`, `Website`, `API` and `Meta`. Source, form and campaign conditions use exact, case-sensitive equality; all specified conditions combine with AND. Do not enter an invented form/campaign name. Use the actual values recorded by the relevant intake path. No catch-all rule is created automatically. At most 200 rules may be configured; each has one to six distinct current product boards and up to 100 explicitly selected owners.

Rules apply in ascending priority order; equal priorities use ascending rule UUID order. Only the first matching rule is considered. An unavailable matching rule does **not** fall through to a different team/owner. This deterministic initial matching rule is a documented technical default, not an inferred business assignment.

**Fixed** requires exactly one actual owner. **Round robin** uses the manually ordered selected pool. Add actual eligible people, remove them or use **Move owner earlier** to set the intended sequence. Board selection never selects an owner. A successful route advances the pool pointer once; duplicate enquiries and failed eligibility checks do not consume a turn. Explicit owner-order/method revisions reset the pointer; other configuration revisions retain it. A currently ineligible person is skipped; reactivation does not invent a new pool member.

Every owner needs an actual active staff/Admin account and current sales-own or sales-manage permission. A staff owner needs membership on **every** selected board; existing Administrator board access follows the current manual-assignment safeguards. Enabling validates all selected owners/boards. Runtime checks repeat eligibility against current accounts, CRM roles/teams, board memberships, active boards and active New stages. No membership or permission is granted by routing configuration.

The next follow-up interval is entered explicitly, 0–365 **server UTC calendar days** from capture date. There is no prefilled interval, response target, working-hour/weekend policy or inferred SLA. The resulting date uses the existing Deal follow-up field. A later actual business policy can replace this documented date calculation through a separate change.

## What a match does

Routing runs transactionally only after inserting an actual new lead with status New. The same integration covers manual/CSV, website, API and validated Meta contact capture; a newly corrected Meta receipt can route only if it creates a new lead. Existing lead updates and repeated enquiries never rerun initial routing or change the current owner, stage or product lines. Enabling/revising rules does not retroactively assign old leads.

A successful match creates **one Deal**, stage New, and one product line per selected board, with the actual configured owner and follow-up interval. It assigns the new lead, records a system Assignment activity and preserves an immutable receipt containing the actual rule/version/definition, chosen owner, Deal and server time. The Deal's display title is limited to 200 characters; the original full contact/company fields remain unchanged. No quotation/value, customer, project or transaction is invented. Automated assignment does not impersonate a staff actor; configuration history identifies the actual authorizing Administrator separately.

Only the selected actual owner receives the routing reminder, respecting their current portal reminder preference. Existing channel enquiry reminders remain preference-respecting. There is no external email/SMS/WhatsApp delivery.

If the matching board/New stage is unavailable or no configured owner remains eligible, retain the actual enquiry on Raw Lead Board without making a new assignment. An existing manual-intake creator/owner is preserved. Record **Needs review** with the exact matched rule/version and issue, and notify current enabled Administrators in-app. Configuration repair affects future new leads only; use the actual existing manual triage/assignment workflow for the retained lead. No automatic retrospective rerouting is offered.

## History, privacy and review

The Administrator register shows actual configuration authors, server times, reasons and immutable revisions, plus up to 100 initial routing receipts per page. **Load older routing outcomes** uses a stable server-time/lead-ID cursor. The CSV exports configuration history and the currently loaded receipt page; it does not imply every historical receipt was loaded.

Routing authority and evidence tables are private with RLS and no direct browser/service-role access. Public RPCs require current active Administrator authority; a service key alone cannot configure business assignments. Exact uncertain configuration retries do not duplicate revisions; stale changed versions are rejected. Receipt and revision updates/deletes are blocked. Failed reads and access changes clear private screen/export data, and late responses cannot restore it in another account scope. No actual routing rules or business fixtures were inserted into production.

## Release and next step

API/Meta migrations have now applied once as actual database versions `20261022103801`/`20261022103855` after PR merge, with source scaffolds `20261022010819`/`20261022093715`. Do not reapply either scaffold or run automatic CLI migration push before history alignment. This routing migration remains unapplied until its PR is merged. Do not reapply website migration `20261022005821` or apply held finance migrations 142–148. Use the normal Git-based release path only after final regression and PR merge; verify the actual production deployment and alias. Do not retry the earlier capped manual deployment endpoint or change billing/protection settings. Actual Meta activation still needs actual account authorization.

Next implement the detailed Phase 1 sales/quotation gaps recorded in [Phase 1 progress](phase-one-progress.md), beginning with actual Administrator board creation/custom fields and the missing List actions. Phase 1 is incomplete and all 41 client-owned signed-in/live/browser/export/device acceptance items remain pending.
