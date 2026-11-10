part of '../planner_screen.dart';

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
          icon: const DoodleIcon(Icons.calendar_today_rounded),
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
                    '${entry.subjectType.name} ┬╖ ${_subjectLabel(entry, state)}',
                  ),
                  Text(
                    '${dayKey(entry.startedAt)} ${TimeOfDay.fromDateTime(entry.startedAt).format(context)} ┬╖ ${elapsedLabel(TimeAggregation.between([entry], start, end).totalSeconds)}',
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
