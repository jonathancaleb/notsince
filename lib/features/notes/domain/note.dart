/// One note or one task.
///
/// Both are the same shape — a title, some body, a colour — and a task is
/// simply one that can be finished. Keeping them as one type rather than two
/// means the list, the editor and the storage are each written once, and
/// switching a note to a task never has to move data between boxes.
///
/// Persisted directly by Hive without annotations (see core/hive/hive_adapters.dart).
class Note {
  const Note({
    this.id = '',
    this.title = '',
    this.body = '',
    this.colorTag = kDefaultNoteTag,
    this.isTask = false,
    this.isDone = false,
    this.completedAt,
    this.dueAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;

  /// One of [kNoteTags]. Stored as a name rather than a colour so the palette
  /// can be retuned without rewriting saved notes.
  final String colorTag;

  /// Whether this can be ticked off. Notes written before tasks existed read
  /// back as `false`, which is what they were.
  final bool isTask;

  final bool isDone;

  /// When it was ticked, for the "done" ordering. Null while outstanding.
  final DateTime? completedAt;

  /// Optional deadline. Only a task can have one, and only a task with one can
  /// be overdue — a note has nothing to be late for.
  final DateTime? dueAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  /// An outstanding task — what the list surfaces first.
  bool get isOpenTask => isTask && !isDone;

  bool isOverdueAt(DateTime now) =>
      isOpenTask && dueAt != null && now.isAfter(dueAt!);

  /// A stable 32-bit id for the notification scheduler, which keys by int.
  /// Offset so it can never collide with an alarm's id.
  int get notificationId => (id.hashCode & 0x3FFFFFFF) | 0x40000000;

  /// What to show when there is no title: the first line of the body, so a
  /// card is never a blank rectangle you have to open to identify.
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    final firstLine = body.trim().split('\n').first.trim();
    if (firstLine.isNotEmpty) return firstLine;
    return isTask ? 'Untitled task' : 'Untitled';
  }

  Note copyWith({
    String? id,
    String? title,
    String? body,
    String? colorTag,
    bool? isTask,
    bool? isDone,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      colorTag: colorTag ?? this.colorTag,
      isTask: isTask ?? this.isTask,
      isDone: isDone ?? this.isDone,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const List<String> kNoteTags = ['sage', 'yellow', 'coral', 'blue'];
const String kDefaultNoteTag = 'sage';
