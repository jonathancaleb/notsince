import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/hive/hive_registrar.g.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/planner/data/planner_store.dart';
import 'package:notsince/features/planner/domain/models.dart';

import '../support/fakes.dart';

void main() {
  late Directory directory;
  late Box<dynamic> box;
  late FixedClock clock;
  late ProviderContainer container;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('planner-test-');
    Hive.init(directory.path);
    box = await Hive.openBox<dynamic>('planner_v1');
    await migratePlanner(box);
    clock = FixedClock(DateTime(2026, 10, 12, 9));
    container = ProviderContainer(
      overrides: [
        plannerBoxProvider.overrideWithValue(box),
        clockProvider.overrideWithValue(clock),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await box.close();
    await directory.delete(recursive: true);
  });
  test('additive migration preserves state and is idempotent', () async {
    await container
        .read(plannerProvider.notifier)
        .addProject('Reading', 0xFF639922);
    final before = box.get('state');
    await migratePlanner(box);
    expect(box.get('state'), before);
    expect(box.get('schemaVersion'), 1);
  });
  test('planner migration leaves existing habit records unchanged', () async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    final habits = await Hive.openBox<Tracker>(TrackerRepository.boxName);
    final tracker = Tracker(
      id: 'existing',
      name: 'Reading',
      startedAt: DateTime(2020, 1, 1),
      acknowledged: {const Duration(days: 1)},
    );
    await habits.put(tracker.id, tracker);
    await migratePlanner(box);
    final restored = habits.get(tracker.id)!;
    expect(restored.startedAt, DateTime(2020, 1, 1));
    expect(restored.name, 'Reading');
    expect(restored.acknowledged, tracker.acknowledged);
    await habits.close();
  });
  test(
    'rapid autosaves and check-ins do not overwrite unrelated edits',
    () async {
      final controller = container.read(plannerProvider.notifier);
      await Future.wait([
        controller.addProject('Work', 0xFF639922),
        controller.saveNote(
          const PlannerNote(id: 'note', body: '# First\nBody'),
        ),
        controller.checkIn('habit'),
      ]);
      final restored = PlannerState.fromMap(box.get('state'));
      expect(restored.projects.single.name, 'Work');
      expect(restored.notes.single.title, 'First');
      expect(restored.checkIns['habit'], ['2026-10-12']);
    },
  );
  test(
    'a running timer restores and switching never overlaps sessions',
    () async {
      var controller = container.read(plannerProvider.notifier);
      await controller.toggleTimer(SubjectType.day, '2026-10-12');
      container.dispose();
      container = ProviderContainer(
        overrides: [
          plannerBoxProvider.overrideWithValue(box),
          clockProvider.overrideWithValue(clock),
        ],
      );
      controller = container.read(plannerProvider.notifier);
      expect(
        container.read(plannerProvider).active?.subjectType,
        SubjectType.day,
      );
      clock.set(DateTime(2026, 10, 12, 9, 10));
      await controller.toggleTimer(SubjectType.project, 'project');
      clock.set(DateTime(2026, 10, 12, 9, 15));
      await controller.toggleTimer(SubjectType.project, 'project');
      final state = container.read(plannerProvider);
      expect(state.active, isNull);
      expect(state.entries.map((e) => e.durationSec), [600, 300]);
    },
  );
  test('numeric goals water a habit only when its target is reached', () async {
    final controller = container.read(plannerProvider.notifier);
    await controller.setHabit('read', goal: 3);
    await controller.checkIn('read');
    await controller.checkIn('read');
    expect(container.read(plannerProvider).checkIns['read'], isEmpty);
    await controller.checkIn('read');
    await controller.checkIn('read');
    expect(container.read(plannerProvider).checkIns['read'], ['2026-10-12']);
    expect(container.read(plannerProvider).progress['read:2026-10-12'], 3);
  });
  test('recurring completion creates one next task with its project', () async {
    final controller = container.read(plannerProvider.notifier);
    await controller.addProject('Work', 0xFF639922);
    await controller.addTask(
      'Write @Work',
      recurrence: const RecurrenceRule(intervalDays: 1),
    );
    final task = container.read(plannerProvider).tasks.single;
    await controller.completeTask(task);
    final state = container.read(plannerProvider);
    expect(state.tasks.length, 2);
    expect(state.tasks.last.projectId, state.projects.single.id);
    expect(state.tasks.last.dueDate, DateTime(2026, 10, 13));
  });
  test('journal dates are unique and notes retain all attachments', () async {
    final controller = container.read(plannerProvider.notifier);
    await controller.saveJournal(clock.now(), 'First');
    await controller.saveJournal(clock.now(), 'Second');
    await controller.saveNote(
      const PlannerNote(
        id: 'note',
        body: 'Title\n**Body**',
        attachments: [
          Attachment(SubjectType.habit, 'habit'),
          Attachment(SubjectType.day, '2026-10-12'),
        ],
        folderId: 'folder',
      ),
    );
    final restored = PlannerState.fromMap(box.get('state'));
    expect(restored.journals.single.body, 'Second');
    expect(restored.notes.single.attachments.length, 2);
    expect(restored.notes.single.folderId, 'folder');
  });
}
