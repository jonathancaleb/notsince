part of '../dashboard_screen.dart';

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final now = ref.watch(clockProvider).now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wordmark(fontSize: 30),
                  const SizedBox(height: 2),
                  Text(kHabitTagline, style: AppType.muted(ns)),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              width: 44,
              child: StickerButton(
                color: ns.tint,
                foreground: ns.ink,
                thin: true,
                expand: false,
                radius: Sticker.tinyRadius,
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                ),
                child: const Center(
                  child: Icon(Icons.settings_rounded, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: ns.tint,
            border: Sticker.thinOutline(ns.ink),
            borderRadius: BorderRadius.circular(Sticker.tinyRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wb_sunny_rounded, size: 15, color: ns.ink),
              const SizedBox(width: 8),
              Text(_dateLabel(now), style: AppType.kicker),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoCounterYet extends ConsumerWidget {
  const _NoCounterYet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StickerCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nothing is being counted yet.', style: AppType.cardTitle),
          const SizedBox(height: 16),
          StickerButton(
            onPressed: () => CounterFormScreen.create(context),
            child: const Text('Start a habit'),
          ),
        ],
      ),
    );
  }
}

/// The count, at full size. Tapping it opens the counter tab rather than a
/// separate screen, so there is only ever one place the counter lives.
class _CountHero extends ConsumerWidget {
  const _CountHero({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final tracker = ref.watch(trackerProvider(id));
    final progress = ref.watch(progressProvider(id));
    if (tracker == null || progress == null) return const SizedBox.shrink();

    final crayon = ns.crayon(tracker.colorIndex);
    final days = daysOf(progress.elapsed);
    final next = progress.nextMilestone;
    final passedCount = crossedMilestones(
      tracker,
      tracker.startedAt.add(progress.elapsed),
    ).length;

    return Semantics(
      button: true,
      onTap: () => ref.read(homeTabProvider.notifier).select(HomeTab.habit),
      child: GestureDetector(
        onTap: () => ref.read(homeTabProvider.notifier).select(HomeTab.habit),
        child: StickerCard(
          color: ns.crayonTint(tracker.colorIndex),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(tracker.emoji, style: AppType.glyph(26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tracker.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.cardTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                habitEncouragement(
                  progress.elapsed,
                  hasHistory: tracker.history.isNotEmpty,
                ),
                textAlign: TextAlign.center,
                style: AppType.hint,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  HabitPlant(
                    stage: HabitPlant.stageFor(
                      passed: passedCount,
                      total: tracker.sortedMilestones.length,
                    ),
                    color: crayon,
                    size: const Size(88, 100),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$days',
                          style: AppType.counter(64).copyWith(color: ns.ink),
                        ),
                        Text(
                          days == 1 ? 'day' : 'days',
                          style: AppType.subtitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          next == null
                              ? 'Fully grown'
                              : '$passedCount of ${tracker.sortedMilestones.length} Â· next ${milestoneLabel(next)}',
                          style: AppType.muted(ns),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextAlarmCard extends ConsumerWidget {
  const _NextAlarmCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final next = ref.watch(nextAlarmProvider);

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => ref.read(homeTabProvider.notifier).select(HomeTab.alarms),
        child: StickerCard(
          color: next == null ? ns.paper : ns.alarmTint,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          radius: Sticker.radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ðŸ””', style: AppType.glyph(20)),
              const SizedBox(height: 8),
              Text(
                next == null
                    ? 'None set'
                    : clockLabel(next.entry.hour, next.entry.minute),
                style: next == null ? AppType.statSmall : AppType.stat,
              ),
              const SizedBox(height: 2),
              Text(
                next == null
                    ? 'Next alarm'
                    : repeatLabel(next.entry.repeatDays),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.muted(ns),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends ConsumerWidget {
  const _NotesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final notes = ref.watch(notesProvider);
    final openTasks = ref.watch(openTaskCountProvider);
    final now = ref.watch(clockProvider).now();

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => ref.read(homeTabProvider.notifier).select(HomeTab.notes),
        child: StickerCard(
          color: notes.isEmpty ? ns.paper : ns.tint,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(openTasks > 0 ? 'â˜‘' : 'ðŸ“', style: AppType.glyph(20)),
              const SizedBox(height: 8),
              Text('${notes.length}', style: AppType.stat),
              const SizedBox(height: 2),
              Text(
                notes.isEmpty
                    ? 'Notes & tasks'
                    : openTasks > 0
                    ? '$openTasks to do'
                    : 'edited ${_ago(now.difference(notes.first.updatedAt))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.muted(ns),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _ago(Duration d) {
  if (d.inDays >= 1) return '${d.inDays}d ago';
  if (d.inHours >= 1) return '${d.inHours}h ago';
  if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
  return 'just now';
}

/// Recent notes as a sideways strip of stickers. Reading only â€” tapping one
/// opens it in the editor.
class _NotesStrip extends ConsumerWidget {
  const _NotesStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final notes = ref.watch(notesProvider).take(6).toList();
    if (notes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lately', style: AppType.cardTitle),
        const SizedBox(height: 14),
        SizedBox(
          // Tall enough for the card plus the offset shadow, which takes no
          // layout space of its own and would otherwise be clipped.
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(right: 6),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final note = notes[i];
              return Transform.rotate(
                angle: (i.isEven ? 1 : -1) * 0.016,
                child: SizedBox(
                  width: 148,
                  child: GestureDetector(
                    onTap: () => NoteEditorScreen.open(context, note.id),
                    child: StickerCard(
                      color: ns.noteTag(note.colorTag),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.cardSmall,
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              note.body,
                              overflow: TextOverflow.fade,
                              style: AppType.small,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
