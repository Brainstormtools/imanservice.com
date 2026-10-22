# Actual stage-entry review tasks

Prepared increment; use the requirement documents' latest checkpoint for actual merge, database and deployment status. No configurations, recipients or tasks are seeded.

## Configure manually

An active Administrator opens Sales board configuration → **Stage-entry review tasks** → **Load actual stage actions**. Choose an actual board and stage, enter the actual task title, select an eligible actual recipient, enter the calendar-day due interval and reason, then explicitly confirm. Enable is unchecked by default; the interval and all choices start blank. Creating or enabling a configuration does not create tasks for deals already in that stage.

Documented eligibility assumption: a fixed future recipient must already have enduring board visibility through an active Administrator account or an actual active board membership with Sales Manager or Product Specialist permission. This avoids assigning a future task to an unassigned Sales Agent who may not own the future Deal. No role, team or board membership is created automatically. Changing ownership does not choose a reviewer. Admin can explicitly revise the actual recipient later.

The action stays scoped to its original board/stage; update its task/recipient/interval/enable choice using the exact current action and stage versions. Disable retains the original rule, configuration history and previously generated tasks. An existing rule may be disabled even if its previous recipient, board or stage has become inactive. Invalid or stale changes fail without overwriting the register. The latest 100 immutable configuration revisions and their private CSV are available to Admin; older stored evidence is retained.

## Enter the stage

A genuine stage change through existing checked Deal workflows creates one task for each currently enabled matching action on an active product line/board/stage. The actual task snapshots the action revision, prior/new stage, Deal version, recipient, due date, actual actor and server time. A saved same-stage update or an exact safe bulk retry does not create another task. Leaving and later re-entering the stage creates a distinct new task.

Due date is the server's existing Pakistan business date plus the explicitly configured calendar-day interval. No working-day calendar, response target or approval policy is inferred. The configured actual recipient receives an in-portal reminder when their existing reminder preference is enabled. External email/SMS/WhatsApp remains excluded.

If an enabled action's recipient loses required authority, the stage change fails and rolls back instead of inventing a replacement or silently omitting the task. Admin must revise or disable the actual configuration. This is the documented safe default for an enabled rule; no other mandatory approval or review order is introduced.

## Complete actual work

The assigned actual recipient, currently authorized board Sales Manager or Admin can complete the task with an actual outcome note and exact current task version. Board and Deal access are checked again on the server. Shared Deal access through another board does not reveal or complete this board's review task. Creation and completion preserve separate immutable evidence; completion also appears in the existing activity timeline. Repeated/stale completion is rejected.

Existing unassigned re-engagement tasks keep their existing sales-edit completion rules. Tasks and actual recorded outcomes are retained; disabling a configuration does not delete or reassign them.

## Remaining Phase 1 scope

Lead-detail private files, history-preserving product/board changes and the final quotation/SRS requirement-to-test audit remain open. Actual Meta authorization and all 41 client-owned live acceptance items remain pending. The recommended Calendar view is not silently promoted to a mandatory SRS requirement.
