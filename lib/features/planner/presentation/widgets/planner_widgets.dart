part of '../planner_screen.dart';

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
      icon: DoodleIcon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
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
                // A running clock must stay on one line: at large text sizes
                // it shrinks to fit rather than wrapping mid-number.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    elapsedLabel(daySeconds),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
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
                    icon: const DoodleIcon(Icons.radio_button_unchecked),
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
      hintText: 'Add a task ΓÇö type @ to tag a project',
      suffixIcon: IconButton(
        tooltip: 'Add task',
        onPressed: _saving ? null : _add,
        icon: const DoodleIcon(Icons.add_rounded),
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
        child: Text('A little breathing room. Add a task when youΓÇÖre ready.'),
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
                child: const DoodleIcon(Icons.check_rounded),
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
                        icon: const DoodleIcon(Icons.radio_button_unchecked_rounded),
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
                              '${dayKey(task.dueDate)}${task.recurrenceRule.repeats ? ' ┬╖ repeats' : ''}',
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
                        icon: const DoodleIcon(Icons.more_horiz_rounded),
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
