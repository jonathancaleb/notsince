import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/core/ids.dart';
import 'package:notsince/core/time/clock.dart';

import '../domain/models.dart';
import '../domain/recurrence_engine.dart';

final plannerBoxProvider = Provider<Box<dynamic>?>((ref) => null);
final plannerProvider = NotifierProvider<PlannerController, PlannerState>(
  PlannerController.new,
);

class PlannerState {
  const PlannerState({
    this.projects = const [],
    this.tasks = const [],
    this.entries = const [],
    this.notes = const [],
    this.folders = const [],
    this.journals = const [],
    this.checkIns = const {},
    this.goals = const {},
    this.progress = const {},
    this.colors = const {},
    this.active,
    this.accent = 0xFF639922,
  });
  final List<Project> projects;
  final List<Task> tasks;
  final List<TimeEntry> entries;
  final List<PlannerNote> notes;
  final List<Folder> folders;
  final List<JournalEntry> journals;
  final Map<String, List<String>> checkIns;
  final Map<String, double> goals, progress;
  final Map<String, int> colors;
  final TimeEntry? active;
  final int accent;
  Map<String, dynamic> toMap() => {
    'projects': projects.map((e) => e.toMap()).toList(),
    'tasks': tasks.map((e) => e.toMap()).toList(),
    'entries': entries.map((e) => e.toMap()).toList(),
    'notes': notes.map((e) => e.toMap()).toList(),
    'folders': folders.map((e) => e.toMap()).toList(),
    'journals': journals.map((e) => e.toMap()).toList(),
    'checkIns': checkIns,
    'goals': goals,
    'progress': progress,
    'colors': colors,
    'active': active?.toMap(),
    'accent': accent,
  };
  factory PlannerState.fromMap(Map m) => PlannerState(
    projects: (m['projects'] as List? ?? [])
        .map((e) => Project.fromMap(e))
        .toList(),
    tasks: (m['tasks'] as List? ?? []).map((e) => Task.fromMap(e)).toList(),
    entries: (m['entries'] as List? ?? [])
        .map((e) => TimeEntry.fromMap(e))
        .toList(),
    notes: (m['notes'] as List? ?? [])
        .map((e) => PlannerNote.fromMap(e))
        .toList(),
    folders: (m['folders'] as List? ?? [])
        .map((e) => Folder.fromMap(e))
        .toList(),
    journals: (m['journals'] as List? ?? [])
        .map((e) => JournalEntry.fromMap(e))
        .toList(),
    checkIns: (m['checkIns'] as Map? ?? {}).map(
      (k, v) => MapEntry(k as String, List<String>.from(v)),
    ),
    goals: (m['goals'] as Map? ?? {}).map(
      (k, v) => MapEntry(k as String, (v as num).toDouble()),
    ),
    progress: (m['progress'] as Map? ?? {}).map(
      (k, v) => MapEntry(k as String, (v as num).toDouble()),
    ),
    colors: Map<String, int>.from(m['colors'] ?? {}),
    active: m['active'] == null ? null : TimeEntry.fromMap(m['active']),
    accent: m['accent'] ?? 0xFF639922,
  );
}

class PlannerController extends Notifier<PlannerState> {
  Future<void> _pending = Future<void>.value();
  @override
  PlannerState build() {
    final raw = ref.watch(plannerBoxProvider)?.get('state');
    return raw == null ? const PlannerState() : PlannerState.fromMap(raw);
  }

  DateTime get now => ref.read(clockProvider).now();
  Future<void> _save(Map<String, dynamic> map) async {
    final next = PlannerState.fromMap(map);
    final previous = state;
    state = next;
    final box = ref.read(plannerBoxProvider);
    final write = _pending.then((_) async {
      await box?.put('state', map);
    });
    _pending = write.catchError((Object _) {});
    try {
      await write;
    } catch (_) {
      if (identical(state, next)) state = previous;
      rethrow;
    }
  }

  Future<void> _field(String key, dynamic value) =>
      _save({...state.toMap(), key: value});
  Future<void> addProject(String name, int color) async {
    if (name.trim().isEmpty) return;
    await _field('projects', [
      ...state.projects.map((e) => e.toMap()),
      Project(id: newId(), name: name.trim(), color: color).toMap(),
    ]);
  }

  Future<void> addTask(
    String input, {
    DateTime? date,
    RecurrenceRule recurrence = const RecurrenceRule(),
  }) async {
    var title = input.trim();
    if (title.isEmpty) return;
    String? projectId;
    for (final project in state.projects) {
      if (title.toLowerCase().contains('@${project.name.toLowerCase()}')) {
        projectId = project.id;
        title = title
            .replaceAll(
              RegExp('@${RegExp.escape(project.name)}', caseSensitive: false),
              '',
            )
            .trim();
        break;
      }
    }
    if (title.isEmpty) return;
    await _field('tasks', [
      ...state.tasks.map((e) => e.toMap()),
      Task(
        id: newId(),
        title: title,
        dueDate: calendarDay(date ?? now),
        projectId: projectId,
        recurrenceRule: recurrence,
      ).toMap(),
    ]);
  }

  Future<void> updateTask(Task task) => _field(
    'tasks',
    state.tasks.map((e) => (e.id == task.id ? task : e).toMap()).toList(),
  );
  Future<void> completeTask(Task task) async {
    if (state.tasks.where((e) => e.id == task.id).firstOrNull?.isDone !=
        false) {
      return;
    }
    final tasks = state.tasks
        .map((e) => (e.id == task.id ? e.copyWith(isDone: true) : e).toMap())
        .toList();
    final next = RecurrenceEngine.next(task.dueDate, task.recurrenceRule);
    if (next != null) {
      tasks.add(
        Task(
          id: newId(),
          title: task.title,
          projectId: task.projectId,
          dueDate: next,
          recurrenceRule: task.recurrenceRule,
        ).toMap(),
      );
    }
    await _field('tasks', tasks);
  }

  Future<void> toggleTimer(
    SubjectType type,
    String id, {
    String? projectId,
  }) async {
    final map = state.toMap();
    final active = state.active;
    if (active != null) {
      final seconds = now
          .difference(active.startedAt)
          .inSeconds
          .clamp(0, 2147483647);
      map['entries'] = [
        ...state.entries.map((e) => e.toMap()),
        TimeEntry(
          id: active.id,
          subjectType: active.subjectType,
          subjectId: active.subjectId,
          startedAt: active.startedAt,
          durationSec: seconds,
          projectId: active.projectId,
        ).toMap(),
      ];
    }
    map['active'] = active?.subjectType == type && active?.subjectId == id
        ? null
        : TimeEntry(
            id: newId(),
            subjectType: type,
            subjectId: id,
            startedAt: now,
            durationSec: 0,
            projectId: projectId,
          ).toMap();
    await _save(map);
  }

  Future<void> checkIn(String habitId, {double amount = 1}) async {
    if (!amount.isFinite || amount <= 0) return;
    final key = dayKey(now);
    final dates = state.checkIns[habitId] ?? [];
    if (dates.contains(key)) return;
    final progressKey = '$habitId:$key';
    final progress = {
      ...state.progress,
      progressKey: (state.progress[progressKey] ?? 0) + amount,
    };
    final goal = state.goals[habitId] ?? 1;
    await _save({
      ...state.toMap(),
      'progress': progress,
      'checkIns': {
        ...state.checkIns,
        habitId: [
          ...dates,
          if (!dates.contains(key) && progress[progressKey]! >= goal) key,
        ],
      },
    });
  }

  Future<void> setHabit(String id, {double? goal, int? color}) => _save({
    ...state.toMap(),
    'goals': {
      ...state.goals,
      if (goal != null && goal.isFinite && goal > 0) id: goal,
    },
    'colors': {...state.colors, id: ?color},
  });
  Future<void> setAccent(int color) => _field('accent', color);
  Future<void> saveNote(PlannerNote note) => _field('notes', [
    ...state.notes.where((e) => e.id != note.id).map((e) => e.toMap()),
    note.toMap(),
  ]);
  Future<void> deleteNote(String id) => _field(
    'notes',
    state.notes.where((e) => e.id != id).map((e) => e.toMap()).toList(),
  );
  Future<void> addFolder(String name, {String? parentId}) => _field('folders', [
    ...state.folders.map((e) => e.toMap()),
    Folder(id: newId(), name: name, parentId: parentId).toMap(),
  ]);
  Future<void> saveJournal(DateTime date, String body) => _field('journals', [
    ...state.journals
        .where((e) => dayKey(e.date) != dayKey(date))
        .map((e) => e.toMap()),
    JournalEntry(date: date, body: body).toMap(),
  ]);
  Future<void> clear() async {
    await _pending;
    await ref.read(plannerBoxProvider)?.clear();
    state = const PlannerState();
  }
}

/// Additive, idempotent migration. Existing typed Hive boxes and adapters stay intact.
Future<void> migratePlanner(Box<dynamic> box) async {
  final version = box.get('schemaVersion', defaultValue: 0) as int;
  if (version > 1) throw StateError('Planner data requires a newer app');
  if (version < 1) {
    if (!box.containsKey('state')) {
      await box.put('state', const PlannerState().toMap());
    }
    await box.put('schemaVersion', 1);
  }
}
