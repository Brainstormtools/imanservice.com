# Product board creation and board-specific fields

This Phase 1 implementation is released through merged PR #236 at `8677f76765c57a7dff30a5f1f2a90316070f15df`. Exact production `dpl_HCiQfUgmVtYVXi7grAvwWZkSboji` is READY; www alias, public portal and deployed board/field assets are verified. Migration `20261022111906_phase_one_board_fields.sql` applied once, originally scaffolded as `20261022105756`. Its renamed source is byte-identical and must not be reapplied. Seven actual existing boards are preserved; no products, members, fields/values or other business fixtures were seeded. DEV-059 implementation is released; Phase 1 and client acceptance remain open.

## Create an actual product board

An active Administrator opens **Sales board configuration → Product board definitions and fields**, then explicitly loads the register. Enter the actual unique lowercase code (2–50 characters), name, badge color, Won outcome and days-without-activity highlight interval. All inputs start blank. Choose the actual existing board whose exact stage definitions should be copied, inspect the stage preview, enter a creation reason and tick the confirmation. New boards start inactive unless the Administrator explicitly checks the enable action.

The copied stage snapshot includes actual source board/stage identities and versions, names, sequence, probabilities and active actions. An intervening source change rejects the stale request. Active New, Won and Lost system stages are required; Won/Lost retain their existing system semantics. Copying a selected stage layout does not invent a product's commercial/execution policy. Select the appropriate actual source and review/configure its new stages using the existing controls.

Only stages are copied. No members, owners, field definitions/values, project templates, reviewers or assignments are copied. Add actual staff through the existing board-membership controls. Any project template or contract configuration required by the actual Won workflow remains a separate manual business setup. Creating/enabling a board grants no employee access by itself and does not modify existing Deals or product lines.

Existing boards are preserved without inventing historical creators or backfilling synthetic creation receipts. New creation records immutable actual author, server time, reason, requested definition and exact copied source/hash. Identical uncertain retries retain one board/receipt; changed retries cannot rewrite creation evidence. Existing board code and outcome remain governed by the existing creation/configuration model. No board is physically deleted by this feature.

## Define optional fields for an actual board

The same Administrator register has a blank **Create actual field** form per actual board. Enter a unique lowercase key (2–50 characters) and actual label, choose a type, explicitly enable when intended, supply a reason and confirm. New fields are inactive unless explicitly enabled. Nothing inserts a business value or marks an existing enquiry qualified.

| Type | Actual entry |
| --- | --- |
| Text | Up to 2,000 characters. |
| Number | An unchanged JSON-round-trippable number, including zero or decimals. Unsafe large/high-precision entries are rejected; use Text to preserve exact digits. No inferred unit, cost, target or rounding policy. |
| Date | Actual ISO calendar date; no timezone or working-day inference. |
| Yes/No | Explicit Yes, No or unset; No is retained as false, not missing. |
| Single choice | One of 1–50 actual distinct Administrator-entered options, or unset. No sample choices are seeded. |

Technical limits: 50 definitions per board including archived definitions; definition payload up to 32,000 bytes; value payload up to 120,000 bytes; numeric representation up to 50 characters. These are bounded input limits, not business policies or financial precision rules. **All custom fields are optional** in this increment. No required-field/stage gate is inferred or activated. Fields do not change quotation totals, task standards, payroll or resource policies.

Revisions use the exact current field version, actual reason and fresh confirmation. Labels and active state may change; Single choice options may be appended/reordered but previously available options cannot be removed or renamed. Existing key, type and board scope are fixed to protect historical meaning. Archive and create a replacement field to change meaning. Definitions and actual author/reason/server-time history remain immutable and available in the private loaded configuration CSV.

## Enter actual product-line values

Open the shared Deal's actual product section, then **Product board custom fields → Load current product custom fields**. The field register belongs to that product line and its board, rather than the whole shared Deal. A user needs current access to **both this board and this Deal**. Seeing a mixed Deal through one board does not disclose another board's private values or history. Administrator access follows existing scope; an actual assigned product specialist can edit their board's open active product, and commercial editors need the same board scope.

An explicit load shows current receipt and schema versions, actual labels/types and retained actual values. A new register starts empty. Enter actual values and reason and tick the replacement confirmation. Zero and No are meaningful entries. Blank means clear that active field. Saving replaces only the active field set; archived current values and all earlier receipts are retained. An entirely empty replacement is permitted only through the same actual reason/confirmation flow.

The server rechecks current authority, active board/product, open Deal, exact receipt and exact schema under a board-scoped transaction lock. Another user edit or field-definition change rejects a stale form. Unknown, archived, other-board fields, invalid types/dates/options and injected owner/access fields are rejected. Exact uncertain retries do not duplicate receipts. Won/Lost Deals, dropped product lines and inactive boards retain values/history read-only; this feature cannot reopen work or bypass the existing sales lifecycle.

Each accepted receipt freezes actual field definitions/versions and resulting values, actual saving account, server time and reason. Original values and definitions are never silently rewritten. Private CSV exports only the loaded receipt page; **Load older product field receipts** uses an exact version cursor, up to 100 receipts per page. Configuration CSV and product-value CSV have separate scope. Failed reads and account/permission/product changes clear private data/exports and suppress late responses. No positive production test fixtures are submitted.

## Release and next work

The new migration is already applied once at `20261022111906`; original source scaffold `20261022105756` was renamed with identical SQL bytes. Never reapply SQL to align a filename, or rerun the earlier website/API/Meta/routing migrations. Finance migrations 142–148 remain separate/unapplied. The current source-file alignment updates only local test paths and release records; it changes no application behavior. Release used normal Git/PR merges; no blocked CLI status retry, manual capped deployment retry, credential/billing/protection change or production test fixture occurred.

Next Phase 1 work is advanced sales List sorting/columns/inline/bulk/filter behavior, then the remaining lead-timer, stage-action and sales/quotation SRS audit. Actual Meta account activation remains unavailable. Phase 1 is not complete and all 41 client-owned acceptance items remain pending.

Exact-number follow-up: independent browser/server guards reject lossy JSON-number conversion rather than silently rounding. New precision migration scaffold `20261022112524` is prepared/unapplied; original board/field `20261022111906` remains applied once and byte-identical. This follow-up passed 8,701 checks/160 suites, TypeScript/build; PR merge and its new migration must precede production verification.
