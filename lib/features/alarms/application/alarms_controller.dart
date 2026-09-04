import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/ids.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/alarms/data/alarm_repository.dart';
import 'package:notsince/features/alarms/data/alarm_scheduler.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';

/// Every alarm, ordered by time of day.
///
/// Hive is the source of truth; the platform schedule is a projection of it.
/// Every mutation writes Hive first and then re-syncs that one alarm, so the
/// two can never disagree about an alarm this app knows exists.
class AlarmsController extends Notifier<List<AlarmEntry>> {
  @override
  List<AlarmEntry> build() => ref.read(alarmRepositoryProvider).readAll();

  AlarmRepository get _repo => ref.read(alarmRepositoryProvider);
  AlarmScheduler get _scheduler => ref.read(alarmSchedulerProvider);

  AlarmEntry? byId(String id) {
    for (final entry in state) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Future<void> _commit(AlarmEntry entry) async {
    state = _sorted([
      for (final e in state) if (e.id == entry.id) entry else e,
    ]);
    await _repo.write(entry);
    await _scheduler.sync(entry, from: ref.read(clockProvider).now());
  }

  Future<AlarmEntry> create({
    required String label,
    required int hour,
    required int minute,
    required List<int> repeatDays,
    required String soundId,
    int snoozeMinutes = 5,
  }) async {
    final entry = AlarmEntry(
      id: newId(),
      label: label.trim().isEmpty ? 'Alarm' : label.trim(),
      hour: hour,
      minute: minute,
      repeatDays: _normalised(repeatDays),
      soundId: soundId,
      snoozeMinutes: snoozeMinutes,
      sortIndex: state.length,
    );

    state = _sorted([...state, entry]);
    await _repo.write(entry);
    await _scheduler.sync(entry, from: ref.read(clockProvider).now());
    return entry;
  }

  Future<void> update(
    String id, {
    String? label,
    int? hour,
    int? minute,
    List<int>? repeatDays,
    String? soundId,
    int? snoozeMinutes,
  }) async {
    final current = byId(id);
    if (current == null) return;
    await _commit(
      current.copyWith(
        label: label?.trim().isEmpty ?? false ? 'Alarm' : label?.trim(),
        hour: hour,
        minute: minute,
        repeatDays: repeatDays == null ? null : _normalised(repeatDays),
        soundId: soundId,
        snoozeMinutes: snoozeMinutes,
      ),
    );
  }

  Future<void> setEnabled(String id, bool isEnabled) async {
    final current = byId(id);
    if (current == null) return;
    await _commit(current.copyWith(isEnabled: isEnabled));
  }

  Future<void> delete(String id) async {
    final current = byId(id);
    if (current == null) return;
    state = [for (final e in state) if (e.id != id) e];
    await _scheduler.cancel(current);
    await _repo.delete(id);
  }

  /// Called when an alarm has finished ringing.
  ///
  /// A one-off alarm disables itself rather than being deleted, so it stays in
  /// the list to be re-armed instead of vanishing the moment it does its job.
  /// A repeating alarm is re-scheduled onto its next day.
  Future<void> settleAfterRing(String id) async {
    final current = byId(id);
    if (current == null) return;
    if (current.repeats) {
      await _commit(current);
    } else {
      await _commit(current.copyWith(isEnabled: false));
    }
  }

  Future<void> snooze(String id) async {
    final current = byId(id);
    if (current == null) return;
    await _scheduler.snooze(current, from: ref.read(clockProvider).now());
  }

  List<int> _normalised(List<int> days) {
    final valid = days.where((d) => d >= DateTime.monday && d <= DateTime.sunday);
    return valid.toSet().toList()..sort();
  }

  List<AlarmEntry> _sorted(List<AlarmEntry> entries) {
    return [...entries]..sort((a, b) {
        final byTime = (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
        return byTime != 0 ? byTime : a.sortIndex.compareTo(b.sortIndex);
      });
  }
}

final alarmsProvider =
    NotifierProvider<AlarmsController, List<AlarmEntry>>(AlarmsController.new);

final alarmProvider = Provider.family<AlarmEntry?, String>((ref, id) {
  for (final entry in ref.watch(alarmsProvider)) {
    if (entry.id == id) return entry;
  }
  return null;
});

/// The next alarm due to ring, with the instant it will ring at.
///
/// Null when nothing is enabled — the dashboard treats that as an invitation
/// to set one rather than as an error.
final nextAlarmProvider =
    Provider.autoDispose<({AlarmEntry entry, DateTime at})?>((ref) {
  final now = ref.watch(clockProvider).now();

  ({AlarmEntry entry, DateTime at})? soonest;
  for (final entry in ref.watch(alarmsProvider)) {
    if (!entry.isEnabled) continue;
    final at = entry.nextOccurrence(now);
    if (at == null) continue;
    if (soonest == null || at.isBefore(soonest.at)) {
      soonest = (entry: entry, at: at);
    }
  }
  return soonest;
});
