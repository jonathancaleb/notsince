import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/ids.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/counter/domain/tracker_run.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';

/// Every counter, in pager order. The only mutable state in the app.
class TrackersController extends Notifier<List<Tracker>> {
  @override
  List<Tracker> build() => ref.read(trackerRepositoryProvider).readAll();

  TrackerRepository get _repo => ref.read(trackerRepositoryProvider);

  Tracker? byId(String id) {
    for (final tracker in state) {
      if (tracker.id == id) return tracker;
    }
    return null;
  }

  void _commit(Tracker tracker) {
    state = [
      for (final t in state) if (t.id == tracker.id) tracker else t,
    ];
    _repo.write(tracker);
    _syncNotifications(tracker);
  }

  /// Milestones are at known future instants, so they are scheduled rather than
  /// noticed. Anything that moves them — a reset, a new start time, an edited
  /// threshold list — has to reschedule.
  void _syncNotifications(Tracker tracker) {
    ref.read(notificationServiceProvider).syncHabit(
          tracker,
          enabled: ref.read(appSettingsProvider).notifyMilestones,
          now: ref.read(clockProvider).now(),
        );
  }

  /// Returns the new counter so the caller can navigate straight to it.
  Tracker create({
    required String name,
    required DateTime startedAt,
    required String emoji,
    required int colorIndex,
  }) {
    final tracker = Tracker(
      id: newId(),
      name: name.trim(),
      startedAt: startedAt,
      emoji: emoji,
      colorIndex: colorIndex,
      sortIndex: state.length,
    );
    state = [...state, tracker];
    _repo.write(tracker);
    _syncNotifications(tracker);
    return tracker;
  }

  /// Returns when the change has reached disk. Callers in the UI ignore it —
  /// state updates synchronously — but the two operations that remove data are
  /// awaitable so anything that needs to know it landed can wait for it.
  Future<void> delete(String id) {
    final current = byId(id);
    if (current != null) {
      ref.read(notificationServiceProvider).cancelHabit(current);
    }
    state = _resequenced([for (final t in state) if (t.id != id) t]);
    return Future.wait([_repo.delete(id), _repo.writeAll(state)]);
  }

  /// [newIndex] is the destination *after* the dragged item is removed, which
  /// is what `ReorderableListView.onReorderItem` reports.
  void reorder(int oldIndex, int newIndex) {
    final next = [...state];
    next.insert(newIndex, next.removeAt(oldIndex));

    state = _resequenced(next);
    _repo.writeAll(state);
  }

  /// See [delete] on why this is awaitable.
  Future<void> wipeAll() {
    ref.read(notificationServiceProvider).cancelAll();
    state = const [];
    return _repo.clear();
  }

  /// Closes the current run into history and begins a new count.
  ///
  /// Not a failure path: nothing is scored, nothing is lost, and the
  /// acknowledged set is cleared so the same milestones can be met again.
  void reset(String id, {DateTime? at}) {
    final current = byId(id);
    if (current == null) return;

    final now = at ?? ref.read(clockProvider).now();
    // A reset can never run backwards past the start of the run it closes.
    final endedAt = now.isBefore(current.startedAt) ? current.startedAt : now;

    _commit(
      current.copyWith(
        startedAt: endedAt,
        history: [
          ...current.history,
          TrackerRun(startedAt: current.startedAt, endedAt: endedAt),
        ],
        acknowledged: const {},
      ),
    );
  }

  void rename(String id, String name) {
    final current = byId(id);
    if (current == null || name.trim().isEmpty) return;
    _commit(current.copyWith(name: name.trim()));
  }

  void setAppearance(String id, {String? emoji, int? colorIndex}) {
    final current = byId(id);
    if (current == null) return;
    _commit(current.copyWith(emoji: emoji, colorIndex: colorIndex));
  }

  /// Editing the start time can un-cross milestones, so acknowledgements that
  /// no longer correspond to reached thresholds are dropped.
  void editStartedAt(String id, DateTime startedAt) {
    final current = byId(id);
    if (current == null) return;
    final moved = current.copyWith(startedAt: startedAt);
    _commit(moved.copyWith(acknowledged: _prune(moved)));
  }

  void setMilestones(String id, List<Duration> milestones) {
    final current = byId(id);
    if (current == null) return;
    final unique = milestones.where((d) => d > Duration.zero).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    final updated = current.copyWith(milestones: unique);
    _commit(updated.copyWith(acknowledged: _prune(updated)));
  }

  void acknowledgeMilestone(String id, Duration milestone) {
    final current = byId(id);
    if (current == null) return;
    _commit(
      current.copyWith(acknowledged: {...current.acknowledged, milestone}),
    );
  }

  /// Keeps sortIndex contiguous and matching list position.
  List<Tracker> _resequenced(List<Tracker> trackers) => [
        for (var i = 0; i < trackers.length; i++)
          trackers[i].copyWith(sortIndex: i),
      ];

  /// Keeps only acknowledgements that still refer to a configured threshold
  /// that is still behind us.
  Set<Duration> _prune(Tracker tracker) {
    final elapsed = tracker.elapsedAt(ref.read(clockProvider).now());
    return tracker.acknowledged
        .where((m) => tracker.milestones.contains(m) && elapsed >= m)
        .toSet();
  }
}

final trackersProvider =
    NotifierProvider<TrackersController, List<Tracker>>(TrackersController.new);

/// A single counter by id. Watching this rather than the whole list means a
/// page only rebuilds when its own counter changes.
final trackerProvider = Provider.family<Tracker?, String>((ref, id) {
  for (final tracker in ref.watch(trackersProvider)) {
    if (tracker.id == id) return tracker;
  }
  return null;
});
