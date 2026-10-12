import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/features/garden/growth_engine.dart';

void main() {
  final start = DateTime(2026, 10, 1);
  List<DateTime> days(int count) =>
      List.generate(count, (i) => DateTime(2026, 10, i + 1));
  test('an unwatered habit starts as a seed', () {
    final plant = GrowthEngine.evaluate([], start, plantedAt: start);
    expect(plant.stage, GrowthStage.seed);
    expect(plant.wilted, isFalse);
  });
  test('three, seven and twenty-one consecutive days unlock growth', () {
    expect(
      GrowthEngine.evaluate(days(3), DateTime(2026, 10, 3)).stage,
      GrowthStage.sprout,
    );
    expect(
      GrowthEngine.evaluate(days(7), DateTime(2026, 10, 7)).stage,
      GrowthStage.sapling,
    );
    expect(
      GrowthEngine.evaluate(days(21), DateTime(2026, 10, 21)).stage,
      GrowthStage.bloom,
    );
  });
  test('today is not counted as missed before its end', () {
    expect(
      GrowthEngine.evaluate(days(7), DateTime(2026, 10, 8, 23)).wilted,
      isFalse,
    );
    expect(
      GrowthEngine.evaluate(days(7), DateTime(2026, 10, 9)).wilted,
      isTrue,
    );
  });
  test('wilting preserves the highest growth stage', () {
    final plant = GrowthEngine.evaluate(days(21), DateTime(2026, 10, 24));
    expect(plant.stage, GrowthStage.bloom);
    expect(plant.streak, 0);
    expect(plant.wilted, isTrue);
  });
  test('three consecutive check-ins restore a wilted plant', () {
    final restored = [
      ...days(7),
      DateTime(2026, 10, 10),
      DateTime(2026, 10, 11),
      DateTime(2026, 10, 12),
    ];
    expect(
      GrowthEngine.evaluate(restored.take(9), DateTime(2026, 10, 11)).wilted,
      isTrue,
    );
    final plant = GrowthEngine.evaluate(restored, DateTime(2026, 10, 12));
    expect(plant.wilted, isFalse);
    expect(plant.streak, 3);
    expect(plant.stage, GrowthStage.sapling);
  });
  test('duplicate and future dates cannot inflate the streak', () {
    final plant = GrowthEngine.evaluate([
      start,
      start,
      DateTime(2026, 10, 2),
    ], start);
    expect(plant.streak, 1);
    expect(plant.stage, GrowthStage.seed);
  });
  test('a never-watered older seed wilts and can recover', () {
    expect(
      GrowthEngine.evaluate([], DateTime(2026, 10, 5), plantedAt: start).wilted,
      isTrue,
    );
    expect(
      GrowthEngine.evaluate(
        [DateTime(2026, 10, 5)],
        DateTime(2026, 10, 5),
        plantedAt: start,
      ).recovery,
      1,
    );
  });
}
