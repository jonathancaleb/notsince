import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';

/// One box holding every alarm, keyed by id.
class AlarmRepository {
  const AlarmRepository(this._box);

  static const boxName = 'alarms';

  final Box<AlarmEntry> _box;

  /// Ordered by time of day, then by creation, so the list reads like a day.
  List<AlarmEntry> readAll() {
    final all = _box.values.toList()
      ..sort((a, b) {
        final byTime = (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
        return byTime != 0 ? byTime : a.sortIndex.compareTo(b.sortIndex);
      });
    return all;
  }

  Future<void> write(AlarmEntry entry) => _box.put(entry.id, entry);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();
}

final alarmBoxProvider = Provider<Box<AlarmEntry>>(
  (ref) => throw UnimplementedError('alarmBoxProvider must be overridden'),
);

final alarmRepositoryProvider = Provider<AlarmRepository>(
  (ref) => AlarmRepository(ref.watch(alarmBoxProvider)),
);
