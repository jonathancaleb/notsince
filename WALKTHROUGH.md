# Walkthrough

The default home is Today, with a fixed day timer, habit circles, today's tasks,
and quick add. Planner contains Tasks, Projects, Timeline, and Reports. Garden
shows one persistent plant per habit. Notes groups markdown notes, folders,
attachment smart folders, and a dated journal. Insights shows completion rates,
check-in streaks, a twelve-week calendar, and weekly/monthly time reports.

## How to try it

1. On a fresh install, go through three intro slides, choose an accent, and create
   your first habit. The existing habit form is reused, and its seed appears in
   Garden. An already-onboarded install opens Today directly.
2. Long press a habit circle on Today or in Garden to check in. Tap to open plant
   detail. Set a numeric daily goal, then log one or a custom amount. Progress
   updates the ring; reaching the goal completes the day's watering.
3. Open the original counter/history from Today or plant detail. Reset, rename,
   reorder, backdate, edit milestones, and inspect history as before. Daily
   watering never resets the original days-since counter.
4. Create a project in Planner → Projects. Quick-add `Draft chapter @Writing`
   after making a Writing project. Filter by project, swipe a task to complete,
   and use its options to select daily, weekdays, custom weekdays, or a due date.
   Long press a task and drop it on a date chip to reschedule.
5. Start a day, project, task, or habit timer. Switching subjects ends the current
   session and starts the next; one session is active at a time. Pause it, restart
   the app, and inspect Timeline's day/week/month ranges. Reports clip sessions
   at period boundaries, including midnight; unassigned time remains visible.
6. Create a markdown note. The first line becomes its title. Attach it to any
   task, project, habit, or date; assign a folder. Create subfolders by choosing
   a parent. Smart folders collect notes by attachment type. Preview supports
   headings, tables, checklists, emphasis, and code. Image markdown renders its
   alternative text so previews never fetch remote resources.
7. Open Journal, choose a date, and type. Every change saves locally; revisit that
   date to confirm restoration. Existing notes and reminder tasks remain in the
   Notes toolbar's archive entry, with their original notification behavior.

Growth thresholds are 3 consecutive days for sprout, 7 for sapling, and 21 for
bloom. An earned stage is retained after a missed day. Yesterday counts as the
last eligible day until today ends. Three consecutive check-ins restore a wilted
plant. Stage-ups open a full-screen celebration after the small check-in pulse.

## Manual device checks

- Upgrade over a copy of existing data; confirm starts, histories, milestones,
  alarms, notes, and reminder tasks survive. Do not uninstall to test migration.
- Test real ringing, snooze, dismiss, notifications, and permission denial.
- Switch system/app light and dark modes, increase text size, and enable reduced
  motion. Inspect the five-tab bar, dialogs, keyboard, note editor, and plant detail.
- Start a timer, background/force-stop/reopen, then pause. Repeat over midnight.
  Timers restore from their persisted start time, including time spent away.
- Exercise drag rescheduling and horizontal completion on an actual touchscreen.
- Use airplane mode for the complete Planner/Garden/Notes workflow.
- Exercise the confirmed “Remove all data” action: original data, alarm schedules,
  Planner sessions/projects/tasks/notes/journals, and Garden progress are cleared.
- Test `notsince:///today`, `/planner`, `/garden`, `/notes`, `/insights`, and
  `/habit/<existing-id>` links on Android and iOS, including cold launch. For
  example: `adb shell am start -a android.intent.action.VIEW -d 'notsince:///planner'`.

Native URL configuration follows [Flutter's deep-link documentation](https://docs.flutter.dev/ui/navigation/deep-linking).
The Planner structure follows the requested [Zympl reference](https://zympl.app/).

## Automated validation

`flutter analyze --no-pub` passes without issues. The expanded suite covers the
original controllers/domain/UI plus recurrence boundaries, plant growth/recovery,
time clipping/aggregation, additive Hive migration, concurrent edits, restored
timers, numeric goals, markdown autosave, five-tab layout at 320dp in both themes,
quick check-in without resetting the counter, onboarding, and named routes.

The full suite currently passes 136 tests. Nine real-widget visual previews were
rendered and checked; rerun with PowerShell:
`$env:SCREENSHOT_OUTPUT='build/ui-preview'; flutter test --no-pub test/screenshots/make_screenshots.dart`.
The output override preserves the checked-in store screenshots.

Physical-device alarms, iOS compilation, and operating-system link dispatch need
the manual checks above; widget tests do not exercise native platform channels.
