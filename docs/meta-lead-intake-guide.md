# Meta lead-ad intake and contact review

This Phase 1 increment is prepared in source, not released or connected to a real Meta account. It depends on API-intake draft [PR #232](https://github.com/Brainstormtools/imanservice.com/pull/232). Its migration `20261022093715_phase_one_meta_intake.sql` remains unapplied. Production still serves the earlier deployment while the Vercel daily build limit blocks release. Do not call this an operational Facebook/Instagram connection or mark DEV-002 complete.

## Actual provider setup after release

The authorized Meta account/app owner must configure the actual app and Pages, grant its required lead-retrieval and Page webhook permissions, and subscribe the actual Page to `leadgen`. Check the app's current supported Graph version and permission requirements in Meta's dashboard/documentation. Facebook and Instagram lead ads use the actual connected Page's delivery; no linked account or Page is inferred.

Use the deployed HTTPS callback `/api/meta-leads` on the intended environment. In production its address will be `https://www.imanservice.com/api/meta-leads`. Configure these server-only variables through the authorized provider settings; never paste actual secrets into chat, browser code, repository files or CSV:

| Variable | Actual value and purpose |
| --- | --- |
| `META_APP_SECRET` | Actual app secret used to verify HMAC-SHA256 over original callback bytes. |
| `META_WEBHOOK_VERIFY_TOKEN` | Account owner's private verification token, matching Meta's callback setup. |
| `META_GRAPH_API_VERSION` | Actual supported app version, explicitly `v<number>.0`; no guessed latest version or arbitrary URL. |
| `META_LEAD_PAGES_JSON` | JSON object keyed by actual numeric Page IDs. Each value contains its actual `accessToken`, optionally `fieldMap` and `formNames`. No Page is seeded. |
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Existing protected server database bindings. Never expose the service key to clients. |

The optional `fieldMap` maps supported semantic keys (`full_name`, `first_name`, `last_name`, `email`, `phone_number`, `company_name`, `city`, `country`) to the actual provider field names. Default interpretation uses those same field names. Optional `formNames` maps actual numeric form IDs to their actual administrator-entered labels, up to 100 characters. Without a configured actual label, retain the form ID; do not invent a form name. These are configuration contracts, not invitations to create sample business records or connections.

GET subscription verification requires the exact configured token and returns only the bounded challenge as plain text. POST requires a correct `X-Hub-Signature-256` against the original bytes. Body parsing is disabled for this route. An unconnected Page, invalid identity or signature never reaches lead retrieval. Page tokens travel only in the fixed Graph host's Authorization header; redirects are rejected. An app-secret proof is generated server-side. Tokens and raw provider errors are never returned or stored as integration metadata.

## Recording an actual enquiry

After signature verification, retrieve the actual provider lead by its Page-scoped lead ID. Retain original field values and actual Page, lead, form, ad, ad-set, campaign and platform metadata when supplied. Campaign name/ID is read from the provider, never inferred from ad IDs. Meta's own [Lead SDK fields](https://github.com/facebook/facebook-python-business-sdk/blob/main/facebook_business/adobjects/lead.py) define the retrieval fields. Provider activation still needs real permission/flow verification; local mocks do not prove an account connection.

A single full name, or actual first/last names, supplies the contact name. Single email values are trimmed/lowercased. An unambiguous international phone becomes a structured identity; ambiguous local phone text remains in the original receipt/enquiry without an invented country code. Missing or multivalued contact answers are not guessed.

Valid contact details enter Raw Lead status New, source Meta, with no automatic assignment. Deduplication shares the manual/import/website/API transaction lock. A genuine repeat enquiry adds activity and an immutable source receipt while preserving the actual existing owner, stage/status and original source. No company record is created automatically. Eligible existing owners or Admin/Sales Manager accounts receive preference-respecting in-app reminders. No external email/SMS/WhatsApp is sent and no staff actor is impersonated.

Page ID plus provider lead ID identifies the receipt. Duplicate delivery retains the first original receipt and adds no activity or correction. A later changed Graph response cannot replace evidence. No HTTP success is returned before every receipt in the accepted batch is durably recorded. Provider/transport/database failures return a generic non-success response so the provider can retry; account operators remain responsible for checking actual delivery failures in Meta.

Technical bounds: 128 KiB callback, up to 20 lead events, four bounded retrieval workers, eight-second Graph retrieval timeout, 64 KiB Graph response and a 60-second function budget. Oversized batches are rejected rather than partially acknowledged. Retried batches can include already confirmed events safely. No billing or credential-protection setting is changed.

## Private contact correction

Missing/invalid actual contacts, conflicting email/phone identities or ambiguous customer matches are durably retained as **Needs contact review**. No lead/person or assignment is invented. Active Administrators receive an in-app review reminder. Administrator-only review is the conservative initial operational default; this does not expand other staff's sales permissions.

Open **Sales board configuration → Meta lead contact review**, explicitly load the register, inspect original provider fields, then enter the actual contact details and correction reason and tick the confirmation. Blank reasons and unchecked confirmation cannot submit. A valid actual email or international phone is required. The server rechecks current active Administrator authority and contact conflicts. This form cannot merge two people, inject an owner or rewrite a valid captured receipt.

The accepted correction records actual account, server time, reason, corrected payload and linked lead separately. Both original provider receipt and correction remain immutable. Identical uncertain retries do not duplicate correction or activity; changed retries are rejected. Original enquiry/acquisition stays available. Resolution clears stale screen data; reload to inspect the result. Permission changes and failed reads clear private data and prevent late responses restoring it.

The private CSV exports only the loaded review page, including original evidence and accepted correction. Pages contain up to 100 receipts; use **Load older Meta review receipts** for the next stable timestamp/Page/lead cursor. Direct browser/service table access is revoked, RLS is enabled and capture is service-only. The private normalization helper is not callable by API roles.

## Resume and release boundaries

Complete regression, preserve a branch/draft PR stacked on #232, then implement explicit Administrator routing and finish the detailed Phase 1 sales/quotation audit. Keep both new intake migrations unapplied until a supported release is ready. Never reapply the already-applied website migration `20261022005821` or apply held finance migrations 142–148. Restore legitimate deployment capacity before production release; do not retry the blocked manual deployment endpoint, bypass protection or change billing. All 41 signed-in/live/browser/export/device acceptance checks remain client-owned and pending.
