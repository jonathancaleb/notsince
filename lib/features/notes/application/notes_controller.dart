import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/ids.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/notes/data/note_repository.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/features/notes/domain/note.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';

/// Everything written down, notes and tasks together.
///
/// Ordering has one rule with one exception: most recently touched first, but
/// finished tasks sink below everything else. A task you ticked is done with —
/// it should not sit at the top of the list purely because it was the last
/// thing you touched.
class NotesController extends Notifier<List<Note>> {
  @override
  List<Note> build() => _sorted(ref.read(noteRepositoryProvider).readAll());

  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  /// Fire-and-forget: a reminder failing to schedule must never stop the note
  /// itself being saved.
  void _syncReminder(Note note) {
    ref.read(notificationServiceProvider).syncTask(
          note,
          enabled: ref.read(appSettingsProvider).notifyTasks,
          now: ref.read(clockProvider).now(),
        );
  }

  Note? byId(String id) {
    for (final note in state) {
      if (note.id == id) return note;
    }
    return null;
  }

  Note create({String colorTag = kDefaultNoteTag, bool isTask = false}) {
    final now = ref.read(clockProvider).now();
    final note = Note(
      id: newId(),
      colorTag: colorTag,
      isTask: isTask,
      createdAt: now,
      updatedAt: now,
    );
    state = _sorted([note, ...state]);
    _repo.write(note);
    return note;
  }

  /// Saves an edit, or removes the note if it was left completely blank.
  ///
  /// Something you opened and never wrote in should not become a card you have
  /// to tidy up later, so the empty case deletes rather than saving nothing.
  void save(
    String id, {
    required String title,
    required String body,
    String? colorTag,
    bool? isTask,
    DateTime? dueAt,
    bool clearDueAt = false,
  }) {
    final current = byId(id);
    if (current == null) return;

    final updated = current.copyWith(
      title: title,
      body: body,
      colorTag: colorTag,
      isTask: isTask,
      // Turning a finished task back into a note has to clear its tick, or it
      // would be a note that is somehow already done.
      isDone: isTask == false ? false : null,
      clearCompletedAt: isTask == false,
      dueAt: dueAt,
      // A note has nothing to be due, so becoming one drops the deadline.
      clearDueAt: clearDueAt || isTask == false,
      updatedAt: ref.read(clockProvider).now(),
    );

    if (updated.isEmpty) {
      delete(id);
      return;
    }

    _put(updated);
  }

  void setTag(String id, String colorTag) {
    final current = byId(id);
    if (current == null) return;
    _put(current.copyWith(
      colorTag: colorTag,
      updatedAt: ref.read(clockProvider).now(),
    ));
  }

  /// Ticks or un-ticks a task. A no-op on a note, which has nothing to finish.
  void setDone(String id, bool isDone) {
    final current = byId(id);
    if (current == null || !current.isTask) return;
    final now = ref.read(clockProvider).now();
    _put(current.copyWith(
      isDone: isDone,
      completedAt: isDone ? now : null,
      clearCompletedAt: !isDone,
      updatedAt: now,
    ));
  }

  /// Converts between a note and a task in place.
  void setIsTask(String id, bool isTask) {
    final current = byId(id);
    if (current == null) return;
    _put(current.copyWith(
      isTask: isTask,
      isDone: isTask ? current.isDone : false,
      clearCompletedAt: !isTask,
      updatedAt: ref.read(clockProvider).now(),
    ));
  }

  Future<void> delete(String id) {
    final current = byId(id);
    if (current != null) {
      ref.read(notificationServiceProvider).cancelTask(current);
    }
    state = [for (final n in state) if (n.id != id) n];
    return _repo.delete(id);
  }

  /// Erases everything. Used by "remove all data" in settings.
  Future<void> clearAll() async {
    state = const [];
    await _repo.clear();
  }

  /// Removes every finished task, leaving notes and outstanding tasks alone.
  Future<void> clearCompleted() async {
    final done = state.where((n) => n.isTask && n.isDone).toList();
    state = [for (final n in state) if (!(n.isTask && n.isDone)) n];
    for (final note in done) {
      await _repo.delete(note.id);
    }
  }

  void _put(Note note) {
    state = _sorted([
      for (final n in state) if (n.id == note.id) note else n,
    ]);
    _repo.write(note);
    _syncReminder(note);
  }

  List<Note> _sorted(List<Note> notes) {
    return [...notes]..sort((a, b) {
        final aDone = a.isTask && a.isDone;
        final bDone = b.isTask && b.isDone;
        if (aDone != bDone) return aDone ? 1 : -1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }
}

final notesProvider =
    NotifierProvider<NotesController, List<Note>>(NotesController.new);

final noteProvider = Provider.family<Note?, String>((ref, id) {
  for (final note in ref.watch(notesProvider)) {
    if (note.id == id) return note;
  }
  return null;
});

/// Outstanding tasks, for the dashboard summary.
final openTaskCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notesProvider).where((n) => n.isOpenTask).length;
});

/// Tasks whose deadline has passed and that are still open.
final overdueTaskCountProvider = Provider.autoDispose<int>((ref) {
  final now = ref.watch(clockProvider).now();
  return ref.watch(notesProvider).where((n) => n.isOverdueAt(now)).length;
});
