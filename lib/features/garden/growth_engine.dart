import '../planner/domain/models.dart';

enum GrowthStage { seed, sprout, sapling, bloom }

class GrowthState {
  const GrowthState({
    required this.stage,
    required this.streak,
    required this.wilted,
    required this.recovery,
  });
  final GrowthStage stage;
  final int streak, recovery;
  final bool wilted;
}

abstract final class GrowthEngine {
  static GrowthState evaluate(
    Iterable<DateTime> checkIns,
    DateTime now, {
    DateTime? plantedAt,
  }) {
    final days = checkIns.map(calendarDay).toSet().toList()..sort();
    final today = calendarDay(now);
    days.removeWhere((d) => d.isAfter(today));
    if (days.isEmpty) {
      return GrowthState(
        stage: GrowthStage.seed,
        streak: 0,
        wilted:
            plantedAt != null &&
            calendarDay(plantedAt)
                .isBefore(DateTime(today.year, today.month, today.day - 1)),
        recovery: 0,
      );
    }
    var consecutive = 0, best = 0;
    var wilted = false;
    DateTime? previous = plantedAt == null ? null : calendarDay(plantedAt);
    for (final day in days) {
      final yesterday = DateTime(day.year, day.month, day.day - 1);
      if (previous != null && previous.isBefore(yesterday)) {
        wilted = true;
        consecutive = 0;
      }
      consecutive++;
      if (consecutive > best) best = consecutive;
      if (consecutive >= 3) wilted = false;
      previous = day;
    }
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final missed = days.last.isBefore(yesterday);
    wilted = wilted || missed;
    final streak = missed ? 0 : consecutive;
    final stage = best >= 21
        ? GrowthStage.bloom
        : best >= 7
        ? GrowthStage.sapling
        : best >= 3
        ? GrowthStage.sprout
        : GrowthStage.seed;
    return GrowthState(
      stage: stage,
      streak: streak,
      wilted: wilted,
      recovery: wilted ? streak.clamp(0, 3) : 3,
    );
  }
}
