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

part 'widgets/planner_widgets.dart';
part 'widgets/timeline_view.dart';

String elapsedLabel(int seconds) =>
    '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

Future<void> completeWithFeedback(
  PlannerController controller,
  Task task,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 280));
  await controller.completeTask(task);
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

