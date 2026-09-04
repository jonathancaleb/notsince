import 'package:notsince/features/counter/domain/milestones.dart';

/// What a notification says.
///
/// Same voice as the app: it tells you what is true and stops. Nothing here
/// congratulates ("well done!"), warns ("don't break your streak!") or nags —
/// all three turn a count into a performance, which is the thing this app is
/// built to avoid. A notification arrives uninvited, so it has less licence to
/// be chatty than the screen does, not more.
abstract final class NotificationCopy {
  /// The line for a milestone, chosen by how long the run is.
  ///
  /// Falls through to a generic line so a custom threshold — three days, say —
  /// still gets something written rather than a blank.
  static String milestone(Duration threshold) {
    final lines = <Duration, String>{
      Duration(hours: 24): 'One full day. The hardest one is behind you.',
      Duration(days: 3): 'Three days. The first stretch is done.',
      Duration(days: 7): 'A week. That is not an accident any more.',
      Duration(days: 14): 'Two weeks. It is starting to feel normal.',
      Duration(days: 30): 'A month of this. It is a habit now.',
      Duration(days: 90): 'Three months. Well past the hard part.',
      Duration(days: 180): 'Half a year. Worth stopping to notice.',
      Duration(days: 365): 'A year. Take the day.',
    };

    return lines[threshold] ??
        '${milestoneLabel(threshold)}. Worth stopping to notice.';
  }

  static String milestoneTitle(String habitName) => habitName;

  /// The line for a task that has gone past its time.
  ///
  /// Deliberately not "you missed it": the task is still there and still
  /// doable, which is the useful thing to say.
  static String overdueTask(String title) => '"$title" was due. '
      'Still there when you are.';

  static const overdueTitle = 'Still on your list';

  /// Shown next to the editable field in settings, so it is obvious what the
  /// habit's own name will be substituted into.
  static const customHint = 'Leave empty to use the written line';
}
