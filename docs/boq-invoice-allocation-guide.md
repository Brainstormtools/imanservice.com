# Private multi-invoice and billed/unbilled allocation — prepared increment

This increment is stacked on PR #227 and its prepared predecessors. Migrations 142–147 remain unapplied; production remains at migration 141. It prepares and independently reviews an actual billed/unbilled split. It is not adjustment issuance, invoice rebilling, an operative contract revision or client acceptance.

## Prepare the actual split

Open **Finance → Invoice allocations**, then **Load current invoice allocation access**. Current Accounts can explicitly select the actual client-Accepted BOQ change and an actual original invoice for that project. Select **Add actual invoice lines to allocation** to inspect its original lines. Add each other actual invoice explicitly. Enter the allocated net against the selected original line(s); tax rates come from those actual invoice lines and cannot be edited. All source/invoice/amount choices start blank.

Enter the actual **Explicit unbilled net PKR**, including an explicit 0 when none remains. The sum of mapped billed nets and that unbilled net must equal the complete accepted BOQ net difference. The unbilled value is an actual manual classification to be justified and reviewed, not a number inferred from invoice descriptions or an automatic balance adjustment. This bounded workflow needs at least one actual billed invoice line; an entirely unbilled change remains a separate path.

For example, an accepted PKR 1,000 net reduction can be explicitly mapped as PKR 400 on one actual invoice line at its original 10% rate, PKR 500 on another invoice line at its original 15% rate, plus PKR 100 unbilled net. The mapped tax is PKR 115 and mapped gross PKR 1,015. **Unbilled tax is unassessed**, not PKR 0 or tax-exempt; the workflow does not invent a tax rate for an unbilled amount.

**Calculate exact invoice allocation preview** freezes the accepted commercial source, complete selected invoice headers/lines, mapped amounts, original rates/taxes, current original-line credit capacity and explicit unbilled remainder. Duplicate invoice-line IDs, wrong invoice/company/project/currency, unsupported line/net precision, excess original-line credit capacity or unexplained remainder are rejected. Draft/Cancelled, supplementary/rebill chains and unmapped issued legacy credits/settlement applications require separate reconciliation.

Enter the actual reason, explicitly check the statement and select **Submit frozen invoice allocation for Manager review**. This records an immutable Accounts version and actual account/server time. Editing inputs invalidates the preview. A pending or Approved allocation cannot be silently replaced; a correction must explicitly follow the exact latest Returned version, retaining its immutable predecessor. Existing pending/Approved single-invoice preparation blocks this alternative, and pending/Approved multi-invoice allocation blocks a competing single-invoice preparation.

## Review independently

A different explicitly designated financial Manager opens the same Finance entry and loads authorized allocation evidence. Managers receive the frozen allocations, not the Accounts source/invoice directory. Actual Manager designations are manually maintained under **BOQ adjustments**; Admin/PM or staff role alone does not infer authority. A maker who also has a Manager designation cannot self-approve.

Inspect the full frozen invoice split, original rates, remaining credit capacity and reason for the unbilled classification. Explicitly choose Approved or Returned, enter the actual reason and check the review statement. Approval requires the exact latest frozen allocation, current Accounts preparer authority, current actual Manager designation and unchanged commercial/invoice/capacity evidence. Revoked authority, changed invoices and stale previews are rejected. An exact stale allocation may still be Returned for correction. Actual Manager designation, reviewer/server time and complete prepared version stay immutable; unchanged retries create no duplicate decision.

## Evidence and financial limits

Use **Export private invoice allocation evidence CSV** for the permitted frozen source, allocation, reason, actual accounts/times and immutable review evidence. Clients and unrelated staff cannot load the private register or tables. Account/role/company/permission changes, failed reads and late responses clear earlier evidence and exports. No client-visible financial document is created by this workflow.

Preparation and approval create no invoice, credit/debit note, client-credit application, cash/refund entry, WHT posting, unbilled contract adjustment, work/cost change or invoice-capacity reservation. A different approved change may consume capacity later; future issuance must revalidate it atomically. This increment does not move an already approved single-invoice document into a split or guess attribution for an existing generic credit. It does not automatically bill or cancel the unbilled remainder.

## Precise resume

Keep the stacked PRs unmerged and migrations 142–147 unapplied for the grouped release. Next implement atomic issuance of the approved billed portions with per-original-invoice documents, current capacity/payment checks, original tax rates and default excess client-credit accounting, without treating the unbilled classification as a posted contract/tax adjustment. Complete explicit legacy-credit/rounding/change-chain reconciliation and WHT financial settlement separately. Refund correction/reversal, partial payouts and dedicated refund files, and PM/Operations Manager execution changes remain open. Ordered schema/security/source and exact deployment verification remain required before release. Catalogue unchanged: 50 open packages, eight development complete; DEV-028 and all 41 client acceptance items remain open.
