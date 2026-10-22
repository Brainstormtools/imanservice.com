# Phase 1 — server-to-server lead API

This is a development increment. It is not evidence that Phase 1 is complete or that the current production deployment contains this code. See [Phase 1 progress](phase-one-progress.md) and the exact release checkpoint in both requirement documents.

## Configure an actual source

An active Administrator opens **Sales board configuration → Lead API sources** and explicitly loads the current register. Source names, reasons and confirmation start blank. Enter the actual integration name and reason, check the statement and create the source. No source, key, person or assignment is seeded by development.

The resulting key is shown once. Store it only on the authorized integration server. Do not put it in a website, mobile app, CSV, source repository or message to support. The register stores only a cryptographic hash and displays a short suffix. It cannot recover the secret. If the response/key was lost, inspect the actual register, revoke that source and create a replacement. An identical creation retry does not generate or redisclose a key.

The source register and CSV include actual names, masked identities, versions, creator/revoker accounts, server times and immutable reasoned history. A different staff role is not source-management authority. Disabled Administrator access is rejected. Failed reads, account/authority changes and late responses clear old source evidence and one-time keys.

Revocation requires the exact current version, an actual reason and explicit confirmation. It immediately rejects new submissions and replays against that key; received enquiries/receipts/history remain. Revoked keys are not silently restored. Rotation is a new actual source creation. Keys do not implicitly expire or disappear when their creator changes role; an active Administrator explicitly revokes the organization integration credential.

## Send actual enquiries

Send **POST application/json** to **`https://www.imanservice.com/api/leads`** once this increment is deployed. Set **Authorization: Bearer YOUR_SOURCE_KEY** and **Idempotency-Key: YOUR_STABLE_EVENT_ID**. An event ID is 1–200 non-control characters, scoped to its source. Keep the same ID and payload when a network response is uncertain. A different genuine enquiry uses a new actual event ID. A changed payload cannot reuse a confirmed ID.

Supported JSON fields:

| Field | Requirement |
| --- | --- |
| `name` | Actual full name, 2–160 characters. |
| `email`, `phone` | At least one actual identity. Email is normalized to lowercase. Structured phones must be international (`+` and country code); punctuation/spacing is normalized and ambiguous local numbers are rejected. No contact identity is invented. |
| `company`, `city`, `country` | Optional actual text; company ≤160, city/country ≤100 characters. |
| `message` | Original enquiry text, at most 8,000 characters; do not replace it with guessed business content. |
| `form`, `campaign` | Optional actual acquisition values, at most 100/300 characters. When no form is supplied, the configured source name identifies the integration. |
| `utm` | Optional object with only `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`; text values ≤300 characters. |
| `tags` | Optional actual labels, at most 20 of 1–40 characters. |

The full HTTP body is limited to 32KB. Combined event/acquisition/message text must also fit the 10,000-character activity budget. Client-supplied source/owner/company IDs and privilege fields are ignored by the HTTP handler; unsupported fields cannot be injected through the server-only database function.

A confirmed request returns **202** with `accepted: true` and the supplied event ID. It does not expose a lead ID or say whether the person already existed. New actual contacts arrive as **New, unassigned** with server-tagged API acquisition. Matching contacts receive a separate enquiry activity; their actual existing owner/status/original acquisition stay unchanged. Every accepted event retains immutable source/event/payload/lead linkage and server receipt time. Conflicting phone/email or multiple-customer matches are rejected for private correction rather than guessed/merged. No customer/company record is automatically created.

In-app notifications go to the actual eligible existing owner, or existing active Admin/Sales Manager accounts for an unassigned lead, respecting reminder preferences. Source credentials do not impersonate a staff submitter, assign work or grant access to CRM records. No email/SMS/WhatsApp or consultation webhook is sent by this API.

## Technical defaults and responses

The assumed technical budget is **100 new events per source in ten minutes**, configurable through server-only `CRM_LEAD_API_WINDOW_LIMIT` (1–1,000). The server derives the bucket from the secret source identity; forwarding-header changes do not evade that budget. Identical confirmed retries do not consume another budget. This limit is an operational abuse control, not a sales target or client business policy.

- **400/413/415:** fix event identity, request size or JSON content type.
- **401:** missing, invalid or revoked source key.
- **409:** confirmed event ID reused with different normalized data.
- **422:** invalid/unsupported contact/acquisition data or a conflicting identity requiring private correction.
- **429:** wait for capacity and retry the same actual event.
- **503:** receipt is unconfirmed; retry the same actual event and payload. Do not create a new ID merely because the response was lost.

Do not use API calls with invented business records as production tests. Development tests use isolated local databases and mocked HTTP services. The client owns real signed-in/live business acceptance.

## Remaining Phase 1 work

Meta lead ads/provider authorization, explicit administrator routing and detailed sales/quotation SRS audit remain separate. The provider daily build limit currently blocks new production releases. Do not reapply the already applied website reconciliation migration; its tracked filename is aligned to the actual `20261022005821` history version in this increment without rerunning that SQL. Held finance migrations 142–148 are not prerequisites and remain unapplied.
