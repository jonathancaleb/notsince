import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/core/ids.dart';
import 'package:notsince/features/counter/domain/tracker.dart';

/// One box holding every counter, keyed by tracker id.
class TrackerRepository {
  const TrackerRepository(this._box);

  static const boxName = 'tracker';

  /// The sole key used by the single-tracker schema, before counters had ids.
  static const legacyKey = 'current';

  final Box<Tracker> _box;

  /// Every counter in pager order.
  ///
  /// Sorted on read rather than trusting insertion order, because Hive boxes
  /// are unordered maps and a reorder only rewrites sortIndex.
  List<Tracker> readAll() {
    final all = _box.values.toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return all;
  }

  Future<void> write(Tracker tracker) => _box.put(tracker.id, tracker);

  Future<void> writeAll(List<Tracker> trackers) =>
      _box.putAll({for (final t in trackers) t.id: t});

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();

  /// Moves a record written by the single-tracker schema into the keyed
  /// collection, giving it an id, an icon and a position.
  ///
  /// Run once at startup, before anything reads the box. Preserves the count in
  /// progress and its whole history — upgrading the app must never cost someone
  /// the streak of days they are actually here for.
  static Future<void> migrate(Box<Tracker> box) async {
    final legacy = box.get(legacyKey);
    if (legacy == null) return;

    final migrated = legacy.copyWith(
      id: newId(),
      sortIndex: 0,
      // Only fill in an icon if the legacy default survived untouched.
      emoji: legacy.emoji,
    );
    await box.put(migrated.id, migrated);
    await box.delete(legacyKey);
  }
}

/// Overridden in [main] with the already-opened box. Opening Hive before
/// `runApp` is what lets the rest of the app read synchronously — no
/// AsyncValue unwrapping, no loading state on the counter.
final trackerBoxProvider = Provider<Box<Tracker>>(
  (ref) => throw UnimplementedError('trackerBoxProvider must be overridden'),
);

final trackerRepositoryProvider = Provider<TrackerRepository>(
  (ref) => TrackerRepository(ref.watch(trackerBoxProvider)),
);
