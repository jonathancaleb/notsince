import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/time/ticker.dart';
import 'package:notsince/core/theme/app_colors.dart';
import 'package:notsince/core/widgets/soft_card.dart';
import 'package:notsince/features/notes/application/notes_controller.dart';
import 'package:notsince/features/notes/presentation/note_editor_screen.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';

import '../data/planner_store.dart';
import '../domain/models.dart';
import '../domain/time_aggregation.dart';
import 'reports_screen.dart';

String elapsedLabel(int seconds) =>
    '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

Future<void> completeWithFeedback(
  PlannerController controller,
  Task task,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 280));
  await controller.completeTask(task);
}

class TimerButton extends ConsumerWidget {
  const TimerButton({
    super.key,
    required this.type,
    required this.id,
    this.projectId,
  });
  final SubjectType type;
  final String id;
  final String? projectId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(plannerProvider.select((s) => s.active));
    final running = active?.subjectType == type && active?.subjectId == id;
    return IconButton(
      tooltip: running ? 'Pause timer' : 'Start timer',
      icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
      onPressed: () => ref
          .read(plannerProvider.notifier)
          .toggleTimer(type, id, projectId: projectId),
    );
  }
}

class DayTimer extends ConsumerWidget {
  const DayTimer({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(tickProvider).value ?? ref.read(clockProvider).now();
    final state = ref.watch(plannerProvider);
    final start = calendarDay(now),
        end = DateTime(now.year, now.month, now.day + 1);
    final entries = [...state.entries];
    final active = state.active;
    if (active != null) {
      entries.add(
        TimeEntry(
          id: active.id,
          subjectType: active.subjectType,
          subjectId: active.subjectId,
          startedAt: active.startedAt,
          durationSec: now
              .difference(active.startedAt)
              .inSeconds
              .clamp(0, 2147483647),
          projectId: active.projectId,
        ),
      );
    }
    final report = TimeAggregation.between(entries, start, end);
    final daySeconds = entries
        .where((e) => e.subjectType == SubjectType.day)
        .fold<int>(
          0,
          (sum, e) =>
              sum + TimeAggregation.between([e], start, end).totalSeconds,
        );
    return SoftCard(
      color: Theme.of(context).colorScheme.primaryContainer,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.surface,
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Make room for today'),
                Text(
                  elapsedLabel(daySeconds),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  '${elapsedLabel(report.totalSeconds)} tracked across your day',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (active != null && active.subjectType != SubjectType.day)
                  Text('${active.subjectType.name} timer running'),
              ],
            ),
          ),
          TimerButton(type: SubjectType.day, id: dayKey(now)),
        ],
      ),
    );
  }
}

class TaskQuickAdd extends ConsumerStatefulWidget {
  const TaskQuickAdd({super.key});
  @override
  ConsumerState<TaskQuickAdd> createState() => _TaskQuickAddState();
}

/// Existing task reminders keep their repository and notification identity.
class ExistingTasks extends ConsumerWidget {
  const ExistingTasks({super.key, this.todayOnly = false});
  final bool todayOnly;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.read(clockProvider).now();
    final tasks = ref
        .watch(notesProvider)
        .where(
          (n) =>
              n.isOpenTask &&
              (!todayOnly ||
                  n.dueAt == null ||
                  !calendarDay(n.dueAt!).isAfter(calendarDay(now))),
        );
    return Column(
      children: [
        for (final task in tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Complete ${task.displayTitle}',
                    icon: const Icon(Icons.radio_button_unchecked),
                    onPressed: () =>
                        ref.read(notesProvider.notifier).setDone(task.id, true),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => NoteEditorScreen.open(context, task.id),
                      child: Text(task.displayTitle),
                    ),
                  ),
                  TimerButton(type: SubjectType.task, id: task.id),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskQuickAddState extends ConsumerState<TaskQuickAdd> {
  final _text = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_saving || _text.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(plannerProvider.notifier).addTask(_text.text);
      _text.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _text,
    onSubmitted: (_) => _add(),
    decoration: InputDecoration(
      hintText: 'Add a task — type @ to tag a project',
      suffixIcon: IconButton(
        tooltip: 'Add task',
        onPressed: _saving ? null : _add,
        icon: const Icon(Icons.add_rounded),
      ),
    ),
  );
}

class TaskList extends ConsumerWidget {
  const TaskList({super.key, this.todayOnly = false, this.projectId});
  final bool todayOnly;
  final String? projectId;
  Future<void> _edit(BuildContext context, WidgetRef ref, Task task) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (key, label) in [
              ('date', 'Reschedule'),
              ('none', 'Does not repeat'),
              ('daily', 'Every day'),
              ('weekdays', 'Weekdays'),
              ('custom', 'Custom weekdays'),
            ])
              ListTile(
                title: Text(label),
                onTap: () => Navigator.pop(context, key),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'date') {
      final date = await showDatePicker(
        context: context,
        initialDate: task.dueDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        await ref
            .read(plannerProvider.notifier)
            .updateTask(task.copyWith(dueDate: date));
      }
      return;
    }
    var rule = const RecurrenceRule();
    if (action == 'daily') rule = const RecurrenceRule(intervalDays: 1);
    if (action == 'weekdays') {
      rule = const RecurrenceRule(weekdays: [1, 2, 3, 4, 5]);
    }
    if (action == 'custom') {
      final days = task.recurrenceRule.weekdays.toSet();
      final selected = await showDialog<List<int>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Repeat on'),
            content: Wrap(
              spacing: 8,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(
                      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day -
                          1],
                    ),
                    selected: days.contains(day),
                    onSelected: (value) => setState(
                      () => value ? days.add(day) : days.remove(day),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, days.toList()),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
      if (selected == null) return;
      rule = RecurrenceRule(weekdays: selected);
    }
    await ref
        .read(plannerProvider.notifier)
        .updateTask(task.copyWith(recurrenceRule: rule));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerProvider);
    final today = calendarDay(
      ref.watch(tickProvider).value ?? ref.read(clockProvider).now(),
    );
    final tasks =
        state.tasks
            .where(
              (t) =>
                  !t.isDone &&
                  (!todayOnly || !calendarDay(t.dueDate).isAfter(today)) &&
                  (projectId == null || t.projectId == projectId),
            )
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('A little breathing room. Add a task when you’re ready.'),
      );
    }
    return Column(
      children: [
        for (final task in tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Dismissible(
              key: ValueKey(task.id),
              direction: DismissDirection.startToEnd,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(24),
                child: const Icon(Icons.check_rounded),
              ),
              confirmDismiss: (_) async {
                await completeWithFeedback(
                  ref.read(plannerProvider.notifier),
                  task,
                );
                return false;
              },
              child: LongPressDraggable<Task>(
                data: task,
                feedback: Material(
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(task.title),
                  ),
                ),
                child: SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Complete ${task.title}',
                        icon: const Icon(Icons.radio_button_unchecked_rounded),
                        onPressed: () => completeWithFeedback(
                          ref.read(plannerProvider.notifier),
                          task,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title),
                            Text(
                              '${dayKey(task.dueDate)}${task.recurrenceRule.repeats ? ' · repeats' : ''}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            if (task.projectId != null)
                              Text(
                                state.projects
                                        .where((p) => p.id == task.projectId)
                                        .firstOrNull
                                        ?.name ??
                                    'Project',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ),
                      TimerButton(
                        type: SubjectType.task,
                        id: task.id,
                        projectId: task.projectId,
                      ),
                      IconButton(
                        tooltip: 'Task options',
                        onPressed: () => _edit(context, ref, task),
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});
  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  String _section = 'Tasks';
  String? _project;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Planner')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 128),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final section in [
                'Tasks',
                'Projects',
                'Timeline',
                'Reports',
              ])
                ChoiceChip(
                  label: Text(section),
                  selected: section == _section,
                  onSelected: (_) => setState(() => _section = section),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_section == 'Tasks') ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All projects'),
                  selected: _project == null,
                  onSelected: (_) => setState(() => _project = null),
                ),
                for (final project in state.projects)
                  ChoiceChip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.lifted(
                        project.color,
                        Theme.of(context).brightness,
                      ),
                      radius: 6,
                    ),
                    label: Text(project.name),
                    selected: _project == project.id,
                    onSelected: (_) => setState(() => _project = project.id),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: [for (var i = 0; i < 7; i++) _DayDrop(offset: i)],
            ),
            const SizedBox(height: 24),
            TaskList(projectId: _project),
            if (_project == null) const ExistingTasks(),
            const TaskQuickAdd(),
          ],
          if (_section == 'Projects') ...[
            FilledButton.icon(
              onPressed: () => _addProject(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New project'),
            ),
            const SizedBox(height: 24),
            for (final project in state.projects)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.lifted(
                          project.color,
                          Theme.of(context).brightness,
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(project.name)),
                      TimerButton(type: SubjectType.project, id: project.id),
                    ],
                  ),
                ),
              ),
          ],
          if (_section == 'Timeline') const TimelineView(),
          if (_section == 'Reports') const ReportsView(),
        ],
      ),
    );
  }

  Future<void> _addProject(BuildContext context) async {
    final text = TextEditingController();
    var color = AppColors.palette.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('A home for your tasks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: text,
                decoration: const InputDecoration(labelText: 'Project name'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final value in AppColors.palette)
                    ChoiceChip(
                      label: const Text('●'),
                      labelStyle: TextStyle(color: Color(value)),
                      selected: color == value,
                      onSelected: (_) => setState(() => color = value),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await ref.read(plannerProvider.notifier).addProject(text.text, color);
    }
    // Controllers outlive the dialog's closing transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    text.dispose();
  }
}

class _DayDrop extends ConsumerWidget {
  const _DayDrop({required this.offset});
  final int offset;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.read(clockProvider).now(),
        date = DateTime(
          ref.read(clockProvider).now().year,
          ref.read(clockProvider).now().month,
          ref.read(clockProvider).now().day + offset,
        );
    return DragTarget<Task>(
      onAcceptWithDetails: (details) => ref
          .read(plannerProvider.notifier)
          .updateTask(details.data.copyWith(dueDate: date)),
      builder: (context, candidates, rejected) => Chip(
        backgroundColor: candidates.isEmpty
            ? null
            : Theme.of(context).colorScheme.primaryContainer,
        label: Text(
          offset == 0
              ? 'Today'
              : offset == 1
              ? 'Tomorrow'
              : '${date.day}/${now.month == date.month ? now.month : date.month}',
        ),
      ),
    );
  }
}

class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({super.key});
  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  String _range = 'Day';
  late DateTime _date = calendarDay(ref.read(clockProvider).now());
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerProvider);
    final now = ref.watch(tickProvider).value ?? ref.read(clockProvider).now();
    final start = _range == 'Month'
        ? DateTime(_date.year, _date.month)
        : _range == 'Week'
        ? DateTime(_date.year, _date.month, _date.day - _date.weekday + 1)
        : _date;
    final end = _range == 'Month'
        ? DateTime(start.year, start.month + 1)
        : DateTime(
            start.year,
            start.month,
            start.day + (_range == 'Week' ? 7 : 1),
          );
    final active = state.active;
    final entries =
        [
              ...state.entries,
              if (active != null)
                TimeEntry(
                  id: active.id,
                  subjectType: active.subjectType,
                  subjectId: active.subjectId,
                  startedAt: active.startedAt,
                  durationSec: now
                      .difference(active.startedAt)
                      .inSeconds
                      .clamp(0, 2147483647),
                  projectId: active.projectId,
                ),
            ]
            .where((e) => e.startedAt.isBefore(end) && e.endedAt.isAfter(start))
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final range in ['Day', 'Week', 'Month'])
              ChoiceChip(
                label: Text(range),
                selected: _range == range,
                onSelected: (_) => setState(() => _range = range),
              ),
          ],
        ),
        TextButton.icon(
          icon: const Icon(Icons.calendar_today_rounded),
          label: Text(dayKey(_date)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Your time will find its place here.'),
          ),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.subjectType.name} · ${_subjectLabel(entry, state)}',
                  ),
                  Text(
                    '${dayKey(entry.startedAt)} ${TimeOfDay.fromDateTime(entry.startedAt).format(context)} · ${elapsedLabel(TimeAggregation.between([entry], start, end).totalSeconds)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value:
                        (TimeAggregation.between(
                                  [entry],
                                  start,
                                  end,
                                ).totalSeconds /
                                3600)
                            .clamp(.02, 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _subjectLabel(
    TimeEntry entry,
    PlannerState state,
  ) => switch (entry.subjectType) {
    SubjectType.project =>
      state.projects.where((p) => p.id == entry.subjectId).firstOrNull?.name ??
          'Archived project',
    SubjectType.task =>
      state.tasks.where((t) => t.id == entry.subjectId).firstOrNull?.title ??
          ref
              .watch(notesProvider)
              .where((n) => n.id == entry.subjectId)
              .firstOrNull
              ?.displayTitle ??
          'Archived task',
    SubjectType.habit =>
      ref
              .watch(trackersProvider)
              .where((t) => t.id == entry.subjectId)
              .firstOrNull
              ?.name ??
          'Archived habit',
    SubjectType.day => entry.subjectId,
  };
}
