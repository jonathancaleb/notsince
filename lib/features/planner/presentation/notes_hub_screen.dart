import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as markdown;
import 'package:notsince/core/ids.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/notes/presentation/notes_screen.dart';
import 'package:notsince/core/widgets/soft_card.dart';

import '../data/planner_store.dart';
import '../domain/models.dart';

class NotesHubScreen extends ConsumerStatefulWidget {
  const NotesHubScreen({super.key});
  @override
  ConsumerState<NotesHubScreen> createState() => _NotesHubScreenState();
}

class _NotesHubScreenState extends ConsumerState<NotesHubScreen> {
  String _section = 'Notes';
  String? _folder;
  SubjectType? _attachment;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerProvider);
    final notes = state.notes
        .where(
          (n) =>
              (_folder == null || n.folderId == _folder) &&
              (_attachment == null ||
                  n.attachments.any((a) => a.type == _attachment)),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            tooltip: 'Existing notes & reminders',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotesScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 128),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final section in [
                'Notes',
                'Folders',
                'Smart folders',
                'Journal',
              ])
                ChoiceChip(
                  label: Text(section),
                  selected: _section == section,
                  onSelected: (_) => setState(() => _section = section),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_section == 'Journal') const JournalEditor(),
          if (_section == 'Folders') ...[
            FilledButton.icon(
              onPressed: () => _newFolder(),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('New folder'),
            ),
            for (final folder in state.folders)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
                subtitle: folder.parentId == null
                    ? null
                    : Text(
                        'Inside ${state.folders.where((f) => f.id == folder.parentId).firstOrNull?.name ?? 'folder'}',
                      ),
                onTap: () => setState(() {
                  _folder = folder.id;
                  _attachment = null;
                  _section = 'Notes';
                }),
              ),
          ],
          if (_section == 'Smart folders') ...[
            for (final type in SubjectType.values)
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: Text('${type.name} notes'),
                trailing: Text(
                  '${state.notes.where((n) => n.attachments.any((a) => a.type == type)).length}',
                ),
                onTap: () => setState(() {
                  _attachment = type;
                  _folder = null;
                  _section = 'Notes';
                }),
              ),
          ],
          if (_section == 'Notes') ...[
            if (_folder != null || _attachment != null)
              TextButton(
                onPressed: () => setState(() {
                  _folder = null;
                  _attachment = null;
                }),
                child: const Text('Show all notes'),
              ),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlannerNoteEditor(folderId: _folder),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('A fresh page'),
            ),
            const SizedBox(height: 24),
            if (notes.isEmpty)
              const Text(
                'Ideas, reflections, little reminders. They all belong here.',
              ),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlannerNoteEditor(note: note),
                    ),
                  ),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          note.body.split('\n').skip(1).join('\n'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note.attachments.isNotEmpty)
                          Text(
                            note.attachments
                                .map((a) => a.type.name)
                                .join(' · '),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _newFolder() async {
    final controller = TextEditingController();
    String? parent;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Folder name'),
              ),
              DropdownButton<String?>(
                value: parent,
                isExpanded: true,
                hint: const Text('Top level'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Top level'),
                  ),
                  for (final folder in ref.read(plannerProvider).folders)
                    DropdownMenuItem(
                      value: folder.id,
                      child: Text(folder.name),
                    ),
                ],
                onChanged: (value) => setState(() => parent = value),
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
    if (result == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(plannerProvider.notifier)
          .addFolder(controller.text.trim(), parentId: parent);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }
}

class PlannerNoteEditor extends ConsumerStatefulWidget {
  const PlannerNoteEditor({super.key, this.note, this.folderId});
  final PlannerNote? note;
  final String? folderId;
  @override
  ConsumerState<PlannerNoteEditor> createState() => _PlannerNoteEditorState();
}

class _PlannerNoteEditorState extends ConsumerState<PlannerNoteEditor> {
  late final _body = TextEditingController(text: widget.note?.body ?? '');
  late final _id = widget.note?.id ?? newId();
  late final List<Attachment> _attachments = [...?widget.note?.attachments];
  late String? _folder = widget.note?.folderId ?? widget.folderId;
  bool _preview = false;
  String _status = 'Saved on this device';
  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await ref
          .read(plannerProvider.notifier)
          .saveNote(
            PlannerNote(
              id: _id,
              body: _body.text,
              attachments: _attachments,
              folderId: _folder,
            ),
          );
      if (mounted) setState(() => _status = 'Saved on this device');
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Could not save. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('A page of your own'),
        actions: [
          IconButton(
            tooltip: _preview ? 'Edit' : 'Preview markdown',
            icon: Icon(
              _preview ? Icons.edit_outlined : Icons.visibility_outlined,
            ),
            onPressed: () => setState(() => _preview = !_preview),
          ),
          IconButton(
            tooltip: 'Delete note',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete this note?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (yes == true) {
                await ref.read(plannerProvider.notifier).deleteNote(_id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_status, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          DropdownButton<String?>(
            value: _folder,
            isExpanded: true,
            hint: const Text('No folder'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No folder'),
              ),
              for (final folder in state.folders)
                DropdownMenuItem(value: folder.id, child: Text(folder.name)),
            ],
            onChanged: (value) {
              setState(() => _folder = value);
              _save();
            },
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final attachment in _attachments)
                InputChip(
                  label: Text(
                    '${attachment.type.name} · ${_attachmentName(attachment, state)}',
                  ),
                  onDeleted: () {
                    setState(() => _attachments.remove(attachment));
                    _save();
                  },
                ),
            ],
          ),
          TextButton.icon(
            onPressed: () => _attach(),
            icon: const Icon(Icons.link_rounded),
            label: const Text('Attach to a task, project, habit or day'),
          ),
          if (_preview)
            MarkdownBody(body: _body.text)
          else
            TextField(
              controller: _body,
              minLines: 12,
              maxLines: null,
              onChanged: (_) => _save(),
              decoration: const InputDecoration(
                hintText: 'First line is your title\n\nWrite in markdown. Make it yours.',
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _attach() async {
    final state = ref.read(plannerProvider),
        trackers = ref.read(trackersProvider);
    final result = await showModalBottomSheet<Attachment>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .6,
          child: ListView(
            children: [
              ListTile(
                title: const Text('Choose a day'),
                leading: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final now = ref.read(clockProvider).now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null && context.mounted) {
                    Navigator.pop(
                      context,
                      Attachment(SubjectType.day, dayKey(date)),
                    );
                  }
                },
              ),
              for (final project in state.projects)
                ListTile(
                  title: Text('Project · ${project.name}'),
                  onTap: () => Navigator.pop(
                    context,
                    Attachment(SubjectType.project, project.id),
                  ),
                ),
              for (final task in state.tasks)
                ListTile(
                  title: Text('Task · ${task.title}'),
                  onTap: () => Navigator.pop(
                    context,
                    Attachment(SubjectType.task, task.id),
                  ),
                ),
              for (final habit in trackers)
                ListTile(
                  title: Text('Habit · ${habit.name}'),
                  onTap: () => Navigator.pop(
                    context,
                    Attachment(SubjectType.habit, habit.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null &&
        mounted &&
        !_attachments.any((a) => a.type == result.type && a.id == result.id)) {
      setState(() => _attachments.add(result));
      await _save();
    }
  }

  String _attachmentName(Attachment attachment, PlannerState state) =>
      switch (attachment.type) {
        SubjectType.project =>
          state.projects
                  .where((p) => p.id == attachment.id)
                  .firstOrNull
                  ?.name ??
              'Archived project',
        SubjectType.task =>
          state.tasks.where((t) => t.id == attachment.id).firstOrNull?.title ??
              'Archived task',
        SubjectType.habit =>
          ref
                  .watch(trackersProvider)
                  .where((t) => t.id == attachment.id)
                  .firstOrNull
                  ?.name ??
              'Archived habit',
        SubjectType.day => attachment.id,
      };
}

class JournalEditor extends ConsumerStatefulWidget {
  const JournalEditor({super.key});
  @override
  ConsumerState<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends ConsumerState<JournalEditor> {
  late DateTime _date = calendarDay(ref.read(clockProvider).now());
  late final _body = TextEditingController(text: _entry(_date));
  bool _preview = false;
  String _status = 'Saved on this device';
  String _entry(DateTime date) =>
      ref
          .read(plannerProvider)
          .journals
          .where((e) => dayKey(e.date) == dayKey(date))
          .firstOrNull
          ?.body ??
      '';
  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await ref.read(plannerProvider.notifier).saveJournal(_date, _body.text);
      if (mounted) setState(() => _status = 'Saved on this device');
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Could not save. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextButton.icon(
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(dayKey(_date)),
        onPressed: () async {
          await _save();
          if (!context.mounted) return;
          final date = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            setState(() {
              _date = date;
              _body.text = _entry(date);
            });
          }
        },
      ),
      Text(_status, style: Theme.of(context).textTheme.labelSmall),
      TextButton(
        onPressed: () => setState(() => _preview = !_preview),
        child: Text(_preview ? 'Keep writing' : 'Preview markdown'),
      ),
      if (_preview)
        MarkdownBody(body: _body.text)
      else
        TextField(
          controller: _body,
          minLines: 12,
          maxLines: null,
          onChanged: (_) => _save(),
          decoration: const InputDecoration(
            hintText: 'What grew today?\n\nYour daily markdown journal…',
          ),
        ),
    ],
  );
}

/// Markdown is rendered locally; image URLs never trigger network requests.
class MarkdownBody extends StatelessWidget {
  const MarkdownBody({super.key, required this.body});
  final String body;
  @override
  Widget build(BuildContext context) => markdown.MarkdownBody(
    data: body,
    selectable: true,
    imageBuilder: (uri, title, alt) => Text(alt ?? 'Image'),
    styleSheet: markdown.MarkdownStyleSheet.fromTheme(Theme.of(context))
        .copyWith(
          h1: Theme.of(context).textTheme.displaySmall,
          h2: Theme.of(context).textTheme.titleLarge,
          p: Theme.of(context).textTheme.bodyLarge,
        ),
  );
}
