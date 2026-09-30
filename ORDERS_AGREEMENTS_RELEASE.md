# Orders, catalogue and contract acceptance

## Included

**Catalogue:** administrators create/edit/archive product and service entries with SKU, description, currency, price and tax. Active clients see available items. Team accounts do not access these commercial modules. Existing order pricing remains fixed after catalogue changes.

**Orders:** clients or administrators select quantities, review the cart and confirm an order request. One currency per order, up to 100 distinct items. The server validates item versions and calculates saved prices/taxes. If prices change, refresh and review again. Identical request retries do not duplicate an order. A newly submitted request is a new order. Orders progress through Submitted → Confirmed → In progress → Fulfilled. Clients may cancel only Submitted orders with a reason. Administrators may reject Submitted orders or cancel unconverted open orders with a reason. History and status notes are visible to the client company.

Administrators may convert a confirmed/in-progress/fulfilled order into one project and one draft invoice. Retries return the existing result. Review invoices and add bank details before issuing. Orders with a linked project or invoice cannot be cancelled in this module; handle the linked records separately. No payment capture, inventory stock control, shipping integration or automatic subscription billing is included.

**Contract documents:** administrators create a document from an existing AMC/SLA contract, enter terms and review a snapshot of dates, services and SLA targets. Saving a draft refreshes its snapshot. Publishing freezes the document and makes it visible to the relevant client company. Clients explicitly confirm acceptance or decline; actor, timestamp, revision and note are recorded. A revision creates a separate draft. Earlier accepted revisions remain unchanged; other prior revisions are superseded. Only the latest revision can be revised again.

Acceptance is an authenticated portal record without an external electronic-signature provider. It does not activate or modify operational contracts, billing or SLA clocks. Existing 24/7 timing and client-specific SLA targets remain unchanged. Administrators still manage operational contract settings under AMC & SLA. Published offers/documents must be reviewed by the client's authorized representative. No real client decision was made during automated development tests.

Order and contract copies can be downloaded as plain text. File attachment/PDF signing and automatic email/SMS/WhatsApp delivery are not included.

## Rollout

Apply `supabase/007_orders_agreements.sql` once after 006, then deploy. Adds five RLS-protected tables, two modules and checked functions. No new packages, secrets or scheduler changes. Existing data is preserved.

## Client/team acceptance checklist

| Role | Test | Expected |
|---|---|---|
| Admin | Add product and service with prices/taxes | Valid entries persist |
| Client | Open catalogue | Active items only; no admin controls |
| Team | Open portal | No commercial module navigation or data access |
| Admin | Archive item or change price | New orders use new availability/version; existing orders unchanged |
| Client | Select quantities, review, confirm | Correct currency, total and saved snapshot |
| Client | Select mixed currencies | Submission blocked |
| Client | Submit stale cart after price change | Server rejects; refresh and review required |
| Client A/B | Inspect orders and history | Only own company's data |
| Client | Cancel Submitted order with reason | Cancelled; history contains reason |
| Client | Try to confirm/fulfil order | Denied |
| Admin | Confirm → In progress → Fulfilled | Allowed transitions persist |
| Admin | Convert confirmed order twice | One project / one draft invoice only |
| Admin | Try to cancel converted order | Denied; linked records must be handled separately |
| Admin | Create contract draft with terms | Current dates/services/SLA snapshot shown |
| Client | Inspect while draft | Draft hidden |
| Admin | Publish document; edit operational source | Published snapshot remains unchanged |
| Client | Review and accept/decline | Explicit confirmation; actor/time/revision stored |
| Client B | Attempt other company's document | Hidden and decision denied |
| Two sessions | Act on same order/document version | Stale second action rejected |
| Admin | Create revision after acceptance | Earlier acceptance preserved; new draft private |
| Admin | Publish new revision | Client makes a separate decision |
| Admin | Inspect operational contract after acceptance | No automatic status, SLA or billing changes |
| All | Existing task, support, SLA, calendar, estimates, billing | Existing workflows remain available |

Use agreed labelled test records. Record tester, expected/actual result and screenshot for failures. Live acceptance remains with the client's team.

## Verification

47 PostgreSQL workflow/security assertions; 9 UI assertions with simulated transport; 17 existing UI regression checks. TypeScript and production build pass.

## Remaining planned areas

Attendance and billing enhancements (recurring invoices, credit notes, payment reporting). External messaging provider setup and historical RISE migration remain separate.
