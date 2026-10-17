import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/features/notes/application/notes_controller.dart';
import 'package:notsince/features/notes/domain/note.dart';
import 'package:notsince/features/notes/presentation/note_editor_screen.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  /// Asks which kind first, because a note and a task are different things to
  /// sit down and write â€” not a setting you flip afterwards.
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final isTask = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => const _KindSheet(),
    );
    if (isTask == null || !context.mounted) return;

    final note = ref.read(notesProvider.notifier).create(isTask: isTask);
    if (!context.mounted) return;
    await NoteEditorScreen.open(context, note.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final notes = ref.watch(notesProvider);
    final doneCount = notes.where((n) => n.isTask && n.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & tasks'),
        actions: [
          if (doneCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notesProvider.notifier).clearCompleted(),
              child: Text('Clear $doneCount done'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: notes.isEmpty
                  ? const _NothingYet()
                  : GridView.builder(
                      // Bottom padding clears the floating nav island.
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.86,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (_, i) => _NoteCard(note: notes[i]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: StickerButton(
                color: ns.primary,
                onPressed: () => _add(context, ref),
                child: const Text('Create note or task'),
              ),
            ),
            // The nav island floats over the bottom of every screen.
            const SizedBox(height: Sticker.navClearance),
          ],
        ),
      ),
    );
  }
}

class _KindSheet extends StatelessWidget {
  const _KindSheet();

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('What are you making?', style: AppType.cardTitle),
            const SizedBox(height: 6),
            Text(
              'A note is for keeping. A task is for finishing.',
              style: AppType.muted(ns),
            ),
            const SizedBox(height: 22),
            StickerButton(
              color: ns.noteTag('yellow'),
              foreground: ns.ink,
              padding: const EdgeInsets.symmetric(vertical: 20),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ðŸ“   Note'),
            ),
            const SizedBox(height: 12),
            StickerButton(
              color: ns.noteTag('blue'),
              foreground: ns.ink,
              padding: const EdgeInsets.symmetric(vertical: 20),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('â˜‘   Task'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NothingYet extends StatelessWidget {
  const _NothingYet();

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Text(
          'Nothing written down yet.\nNotes to keep, tasks to finish.',
          textAlign: TextAlign.center,
          style: AppType.muted(ns),
        ),
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    // A degree of rotation, alternating by id, so the grid reads as cards stuck
    // to a page rather than as cells in a table. Any more and the text starts
    // to look broken rather than placed.
    final tilt = (note.id.hashCode % 2 == 0 ? 1 : -1) * 0.012;
    final done = note.isTask && note.isDone;

    return Transform.rotate(
      angle: tilt,
      child: Opacity(
        // A finished task stays legible but stops competing for attention.
        opacity: done ? 0.55 : 1,
        child: GestureDetector(
          onTap: () => NoteEditorScreen.open(context, note.id),
          child: StickerCard(
            color: ns.noteTag(note.colorTag),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.isTask) ...[
                      StickerCheckbox(
                        value: note.isDone,
                        onChanged: (v) =>
                            ref.read(notesProvider.notifier).setDone(note.id, v),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        note.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.cardSmall.copyWith(
                          decoration: done
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: ns.ink,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ],
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
  }
}

/// A checkbox drawn in the app's own language. Material's has its own palette
/// and a ripple, both of which would be the only ones on screen.
class StickerCheckbox extends StatelessWidget {
  const StickerCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 24,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Semantics(
      checked: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: value ? ns.ink : ns.paper,
            border: Sticker.thinOutline(ns.ink),
            borderRadius: BorderRadius.circular(8),
          ),
          child: value
              ? Icon(Icons.check_rounded,
                  size: size * 0.72, color: ns.paper)
              : null,
        ),
      ),
    );
  }
}

/// Shared by the editor and anywhere else a tag is chosen.
class NoteTagPicker extends StatelessWidget {
  const NoteTagPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final tag in kNoteTags)
          Semantics(
            button: true,
            selected: tag == selected,
            label: 'Tag $tag',
            child: GestureDetector(
              onTap: () => onSelected(tag),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ns.noteTag(tag),
                  border: Border.all(
                    color: ns.ink,
                    width: tag == selected ? 4 : Sticker.thinBorder,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: tag == selected
                      ? Sticker.shadow(ns.ink, const Offset(3, 3))
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
