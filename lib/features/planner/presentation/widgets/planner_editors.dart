part of '../notes_hub_screen.dart';

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
            icon: DoodleIcon(
              _preview ? Icons.edit_outlined : Icons.visibility_outlined,
            ),
            onPressed: () => setState(() => _preview = !_preview),
          ),
          IconButton(
            tooltip: 'Delete note',
            icon: const DoodleIcon(Icons.delete_outline),
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
            icon: const DoodleIcon(Icons.link_rounded),
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
                leading: const DoodleIcon(Icons.calendar_today_outlined),
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
        icon: const DoodleIcon(Icons.calendar_today_outlined),
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
