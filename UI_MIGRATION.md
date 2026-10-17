# UI migration

Paths below are relative to `lib/`. “Shared reskin” means the existing screen
retains its implementation and behavior while receiving new theme, typography,
hairlines, rounded surfaces, and soft component shadows. These are intentional
incremental migrations rather than duplicated business logic.

| Old screen/file | New screen/file | Status |
| --- | --- | --- |
| `core/theme/app_theme.dart` | `theme/app_theme.dart` + compatibility builder | Migrated; light/dark + persisted accent |
| `core/theme/ns_colors.dart` | `theme/app_colors.dart` + compatibility extension | Migrated; warm semantic colors |
| `core/theme/app_type.dart` | `theme/app_typography.dart` + compatible type scale | Migrated |
| `core/theme/sticker.dart` | `theme/app_spacing.dart` + soft legacy tokens | Migrated |
| `core/widgets/sticker_card.dart` | `widgets/soft_card.dart` + retained compatible card | Migrated |
| `core/widgets/sticker_button.dart` | `widgets/primary_button.dart` + retained compatible button | Migrated; reduced motion |
| `core/widgets/sticker_switch.dart` | Same file | Shared reskin; reduced motion |
| `features/dashboard/presentation/dashboard_screen.dart` | `features/planner/presentation/today_screen.dart` | Replaced as default home; old dashboard retained and regression tested |
| `features/shell/home_shell.dart` | Same file | Five custom-painted tabs; alarm listener retained |
| `features/onboarding/presentation/onboarding_screen.dart` | `features/onboarding/presentation/warm_onboarding_screen.dart` | Three intros, accent selection, then existing first-habit form; old screen retained |
| `features/counter/presentation/counter_screen.dart` | Same file; linked from Today | Shared reskin; original habit pager retained |
| `features/counter/presentation/widgets/counter_page.dart` | Same file; also embedded in plant detail | Shared reskin; reset/history/milestones retained |
| `features/counter/presentation/counter_form_screen.dart` | Same file | Shared reskin; selected accent persisted as habit ARGB |
| `features/counter/presentation/counter_settings_screen.dart` | Same file | Shared reskin; existing editing/deletion behavior retained |
| `features/counter/presentation/history_screen.dart` | Same file | Shared reskin |
| `features/counter/presentation/milestone_editor_screen.dart` | Same file | Shared reskin |
| `features/counter/presentation/reset_confirm_sheet.dart` | Same file | Shared reskin; original confirmation semantics retained |
| `features/counter/presentation/widgets/milestone_banner.dart` | Same file | Shared reskin |
| `features/alarms/presentation/alarms_screen.dart` | Same file; Today toolbar entry | Shared reskin; alarms remain accessible |
| `features/alarms/presentation/alarm_form_screen.dart` | Same file | Shared reskin |
| `features/alarms/presentation/alarm_ring_screen.dart` | Same file | Shared reskin; platform ring/snooze/dismiss flow retained |
| `features/notes/presentation/notes_screen.dart` | `features/planner/presentation/notes_hub_screen.dart` | New Notes hub; original notes/tasks/reminders accessible in toolbar |
| `features/notes/presentation/note_editor_screen.dart` | Same file + new PlannerNoteEditor | Original editor shared reskin; new markdown notes use first-line titles |
| `features/settings/presentation/app_settings_screen.dart` | Same file | Shared reskin; wipe includes Planner/Garden and alarm schedules |
| `features/legal/presentation/legal_screen.dart` | Same file | Shared reskin |
| — | `widgets/habit_circle.dart` | New; animated progress and long-press check-in |
| — | `features/planner/presentation/planner_screen.dart` | New; tasks/projects/timeline section switcher, recurrence, rescheduling, timers |
| — | `features/planner/presentation/reports_screen.dart` | New; weekly/monthly reports, Insights, completion calendar |
| — | `features/planner/presentation/notes_hub_screen.dart` / JournalEditor | New; attachments, folders, smart folders, dated autosave journal |
| — | `features/garden/presentation/garden_screen.dart` | New; garden, plant detail, numeric goals, growth celebration |

Legacy `HomeTab.habit` and `HomeTab.alarms` remain available to existing callers;
the visible bar has exactly Today, Planner, Garden, Notes, and Insights.

## Storage migration

`features/planner/data/planner_store.dart:migratePlanner` initializes an additive
`planner_v1` Hive box and records schema version 1. It is idempotent and rejects
unknown future versions. Original tracker, alarm, note, and prefs boxes keep their
names and adapters. No existing habit record is rewritten by this migration.
Existing reminder tasks render alongside new tasks through their original
controller so notification IDs and scheduling survive. Existing titled notes
retain their titles and editor rather than losing data to first-line conversion.
