import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/features/notes/application/notes_controller.dart';
import 'package:notsince/core/time/duration_text.dart';
import 'package:notsince/features/notes/presentation/notes_screen.dart';

/// Writing happens on an island.
///
/// The page is the note's colour, and the text sits on its own outlined card
/// floating on top of it â€” so the thing you are writing is visibly a separate
/// object from the app around it, rather than text loose on a background. The
/// controls live outside the island, which keeps the writing surface clear.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.id});

  final String id;

  static Future<void> open(BuildContext context, String id) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(id: id)),
    );
  }

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late String _tag;
  late bool _isTask;
  DateTime? _dueAt;

  @override
  void initState() {
    super.initState();
    final note = ref.read(notesProvider.notifier).byId(widget.id);
    _title = TextEditingController(text: note?.title ?? '');
    _body = TextEditingController(text: note?.body ?? '');
    _tag = note?.colorTag ?? kDefaultTag;
    _isTask = note?.isTask ?? false;
    _dueAt = note?.dueAt;
  }

  static const kDefaultTag = 'sage';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(notesProvider.notifier).save(
          widget.id,
          title: _title.text,
          body: _body.text,
          colorTag: _tag,
          isTask: _isTask,
          dueAt: _dueAt,
          clearDueAt: _dueAt == null,
        );
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now.add(const Duration(hours: 1)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
    );
    if (!mounted) return;

    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day,
          time?.hour ?? 9, time?.minute ?? 0);
    });
    _save();
  }

  Future<void> _delete() async {
    await ref.read(notesProvider.notifier).delete(widget.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final ground = ns.noteTag(_tag);
    final note = ref.watch(noteProvider(widget.id));
    final isDone = note?.isDone ?? false;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        backgroundColor: ground,
        appBar: AppBar(
          backgroundColor: ground,
          title: Text(_isTask ? 'Task' : 'Note', style: AppType.screenTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The island itself.
                Expanded(
                  child: StickerCard(
                    color: ns.paper,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_isTask) ...[
                              StickerCheckbox(
                                value: isDone,
                                size: 28,
                                onChanged: (v) => ref
                                    .read(notesProvider.notifier)
                                    .setDone(widget.id, v),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: TextField(
                                controller: _title,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: AppType.editorTitle.copyWith(
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: ns.ink,
                                  decorationThickness: 2,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      _isTask ? 'What needs doing?' : 'Title',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintStyle: AppType.editorTitle.copyWith(
                                    color: ns.muted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Expanded(
                          child: TextField(
                            controller: _body,
                            autofocus:
                                _title.text.isEmpty && _body.text.isEmpty,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            textCapitalization: TextCapitalization.sentences,
                            style: AppType.bodyText,
                            decoration: InputDecoration(
                              hintText: _isTask
                                  ? 'Any detail worth remembering'
                                  : 'Write something',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: AppType.bodyText.copyWith(
                                color: ns.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Controls sit off the island, so nothing competes with the
                // writing surface.
                Row(
                  children: [
                    Expanded(
                      child: NoteTagPicker(
                        selected: _tag,
                        onSelected: (tag) {
                          setState(() => _tag = tag);
                          ref
                              .read(notesProvider.notifier)
                              .setTag(widget.id, tag);
                        },
                      ),
                    ),
                    if (_isTask) ...[
                      _DueChip(
                        dueAt: _dueAt,
                        onTap: _pickDue,
                        onClear: () {
                          setState(() => _dueAt = null);
                          _save();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    _KindToggle(
                      isTask: _isTask,
                      onChanged: (v) {
                        setState(() => _isTask = v);
                        ref.read(notesProvider.notifier).setIsTask(widget.id, v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StickerButton(
                  color: ns.ink,
                  foreground: ns.paper,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_isTask ? 'Save task' : 'Save note'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// When a task is due. Absent until you set one â€” most tasks never need a time,
/// and an empty date field on every task would be noise.
class _DueChip extends StatelessWidget {
  const _DueChip({
    required this.dueAt,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? dueAt;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final overdue = dueAt != null && DateTime.now().isAfter(dueAt!);

    return GestureDetector(
      onTap: onTap,
      onLongPress: dueAt == null ? null : onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          // Overdue is marked by weight, not by red â€” a late task is still a
          // task, not a failure.
          color: overdue ? ns.ink : ns.paper,
          border: Sticker.thinOutline(ns.ink),
          borderRadius: BorderRadius.circular(Sticker.tinyRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded,
                size: 17, color: overdue ? ns.paper : ns.ink),
            const SizedBox(width: 6),
            Text(
              dueAt == null ? 'Due' : dateTimeLabel(dueAt!),
              style: AppType.smallStrong.copyWith(
                color: overdue ? ns.paper : ns.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swaps a note for a task without leaving the editor.
class _KindToggle extends StatelessWidget {
  const _KindToggle({required this.isTask, required this.onChanged});

  final bool isTask;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return GestureDetector(
      onTap: () => onChanged(!isTask),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isTask ? ns.ink : ns.paper,
          border: Sticker.thinOutline(ns.ink),
          borderRadius: BorderRadius.circular(Sticker.tinyRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTask
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: isTask ? ns.paper : ns.ink,
            ),
            const SizedBox(width: 6),
            Text(
              'Task',
              style: AppType.kicker.copyWith(
                color: isTask ? ns.paper : ns.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
