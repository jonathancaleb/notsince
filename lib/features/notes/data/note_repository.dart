import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/features/notes/domain/note.dart';

/// One box holding every note, keyed by id.
class NoteRepository {
  const NoteRepository(this._box);

  static const boxName = 'notes';

  final Box<Note> _box;

  /// Most recently edited first — the one you are most likely to want next.
  List<Note> readAll() {
    final all = _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  Future<void> write(Note note) => _box.put(note.id, note);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();
}

final noteBoxProvider = Provider<Box<Note>>(
  (ref) => throw UnimplementedError('noteBoxProvider must be overridden'),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(ref.watch(noteBoxProvider)),
);
