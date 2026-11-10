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
import 'package:notsince/core/widgets/doodle_icon.dart';
part 'widgets/planner_editors.dart';


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
            icon: const DoodleIcon(Icons.inventory_2_outlined),
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
              icon: const DoodleIcon(Icons.create_new_folder_outlined),
              label: const Text('New folder'),
            ),
            for (final folder in state.folders)
              ListTile(
                leading: const DoodleIcon(Icons.folder_outlined),
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
                leading: const DoodleIcon(Icons.auto_awesome_outlined),
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
              icon: const DoodleIcon(Icons.add_rounded),
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

