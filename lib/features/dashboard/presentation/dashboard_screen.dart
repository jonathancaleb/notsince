import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/time/duration_text.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/core/widgets/habit_plant.dart';
import 'package:notsince/core/widgets/wordmark.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/counter/application/progress_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/domain/habit_copy.dart';
import 'package:notsince/features/counter/domain/milestones.dart';
import 'package:notsince/features/counter/domain/tracker_progress.dart';
import 'package:notsince/features/counter/presentation/counter_form_screen.dart';
import 'package:notsince/features/notes/application/notes_controller.dart';
import 'package:notsince/features/notes/presentation/note_editor_screen.dart';
import 'package:notsince/features/settings/presentation/app_settings_screen.dart';
import 'package:notsince/features/shell/home_shell.dart';
import 'package:notsince/core/widgets/doodle_icon.dart';

/// Home. One screen that answers "how am I doing" for all three domains.
///
/// It owns no state — everything here is a derived provider from counter,
/// alarms or notes. The count keeps the whole top of the screen because it is
/// still what the app is for; the alarm and notes are glanceable summaries that
part 'widgets/dashboard_cards.dart';

/// hand off to their own tabs rather than trying to be usable in miniature.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackers = ref.watch(trackersProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, Sticker.navClearance),
          children: [
            const _Header(),
            const SizedBox(height: 20),
            if (trackers.isEmpty)
              const _NoCounterYet()
            else
              _CountHero(id: trackers.first.id),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: _NextAlarmCard()),
                SizedBox(width: 14),
                Expanded(child: _NotesCard()),
              ],
            ),
            const SizedBox(height: 28),
            const _NotesStrip(),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime dt) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
}

/// The top of the app.
///
/// The date used to be grey small print next to a grey gear. Both are now
/// objects: the date is a tinted sticker chip that says what day it is in
/// words, and settings is a proper outlined button rather than a bare icon —
/// so the header has the same physical language as everything under it.
