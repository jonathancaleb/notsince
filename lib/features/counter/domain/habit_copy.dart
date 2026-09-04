import 'package:notsince/features/counter/domain/tracker.dart';

/// The small lines that sit between the big numbers.
///
/// Written to be quietly encouraging without ever congratulating or scolding:
/// nothing here says "well done", "keep going" or "don't break it", because
/// all three turn a count into a performance. They describe what is true and
/// stop. Chosen by how long the run is, so the copy changes as the run does
/// rather than repeating one line forever.
String habitEncouragement(Duration elapsed, {bool hasHistory = false}) {
  if (elapsed.inHours < 1) {
    return hasHistory ? 'Starting again. That counts.' : 'The clock is running.';
  }
  if (elapsed.inDays < 1) return 'Day one, in progress.';
  if (elapsed.inDays < 7) return 'Early days, and they add up.';
  if (elapsed.inDays < 30) return 'This is becoming a habit.';
  if (elapsed.inDays < 90) return 'Well past the hard part.';
  if (elapsed.inDays < 365) return 'This is just how you live now.';
  return 'Over a year of this.';
}

/// The line under a habit's name, saying what kind of thing it is.
String habitSubtitle(Tracker tracker) =>
    tracker.history.isEmpty ? 'Keeping track' : 'Back at it';

/// Header copy for the tab, so the word "habit" appears with a purpose rather
/// than as a bare label.
const String kHabitTagline = 'Breaking one, or keeping one';
