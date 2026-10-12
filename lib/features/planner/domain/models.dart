DateTime calendarDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);
String dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

enum SubjectType { day, project, task, habit }

class Project {
  const Project({required this.id, required this.name, required this.color});
  final String id, name;
  final int color;
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color};
  factory Project.fromMap(Map m) =>
      Project(id: m['id'], name: m['name'], color: m['color']);
}

class RecurrenceRule {
  const RecurrenceRule({this.weekdays = const [], this.intervalDays = 0});
  final List<int> weekdays;
  final int intervalDays;
  bool get repeats => weekdays.isNotEmpty || intervalDays > 0;
  Map<String, dynamic> toMap() => {
    'weekdays': weekdays,
    'intervalDays': intervalDays,
  };
  factory RecurrenceRule.fromMap(Map m) => RecurrenceRule(
    weekdays: List<int>.from(m['weekdays'] ?? []),
    intervalDays: m['intervalDays'] ?? 0,
  );
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.projectId,
    this.recurrenceRule = const RecurrenceRule(),
    this.isDone = false,
  });
  final String id, title;
  final String? projectId;
  final DateTime dueDate;
  final RecurrenceRule recurrenceRule;
  final bool isDone;
  Task copyWith({
    DateTime? dueDate,
    bool? isDone,
    RecurrenceRule? recurrenceRule,
  }) => Task(
    id: id,
    title: title,
    dueDate: dueDate ?? this.dueDate,
    projectId: projectId,
    recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    isDone: isDone ?? this.isDone,
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'dueDate': dueDate.toIso8601String(),
    'projectId': projectId,
    'recurrenceRule': recurrenceRule.toMap(),
    'isDone': isDone,
  };
  factory Task.fromMap(Map m) => Task(
    id: m['id'],
    title: m['title'],
    dueDate: DateTime.parse(m['dueDate']),
    projectId: m['projectId'],
    recurrenceRule: RecurrenceRule.fromMap(m['recurrenceRule']),
    isDone: m['isDone'],
  );
}

class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.subjectType,
    required this.subjectId,
    required this.startedAt,
    required this.durationSec,
    this.projectId,
  });
  final String id, subjectId;
  final SubjectType subjectType;
  final DateTime startedAt;
  final int durationSec;
  final String? projectId;
  DateTime get endedAt => startedAt.add(Duration(seconds: durationSec));
  Map<String, dynamic> toMap() => {
    'id': id,
    'subjectType': subjectType.name,
    'subjectId': subjectId,
    'startedAt': startedAt.toIso8601String(),
    'durationSec': durationSec,
    'projectId': projectId,
  };
  factory TimeEntry.fromMap(Map m) => TimeEntry(
    id: m['id'],
    subjectType: SubjectType.values.byName(m['subjectType']),
    subjectId: m['subjectId'],
    startedAt: DateTime.parse(m['startedAt']),
    durationSec: m['durationSec'],
    projectId: m['projectId'],
  );
}

class Attachment {
  const Attachment(this.type, this.id);
  final SubjectType type;
  final String id;
  Map<String, dynamic> toMap() => {'type': type.name, 'id': id};
  factory Attachment.fromMap(Map m) =>
      Attachment(SubjectType.values.byName(m['type']), m['id']);
}

class PlannerNote {
  const PlannerNote({
    required this.id,
    required this.body,
    this.attachments = const [],
    this.folderId,
  });
  final String id, body;
  final List<Attachment> attachments;
  final String? folderId;
  String get title => body.trim().isEmpty
      ? 'Untitled note'
      : body.trim().split('\n').first.replaceFirst(RegExp(r'^#+\s*'), '');
  Map<String, dynamic> toMap() => {
    'id': id,
    'body': body,
    'attachments': attachments.map((a) => a.toMap()).toList(),
    'folderId': folderId,
  };
  factory PlannerNote.fromMap(Map m) => PlannerNote(
    id: m['id'],
    body: m['body'],
    attachments: (m['attachments'] as List)
        .map((a) => Attachment.fromMap(a))
        .toList(),
    folderId: m['folderId'],
  );
}

class Folder {
  const Folder({required this.id, required this.name, this.parentId});
  final String id, name;
  final String? parentId;
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'parentId': parentId,
  };
  factory Folder.fromMap(Map m) =>
      Folder(id: m['id'], name: m['name'], parentId: m['parentId']);
}

class JournalEntry {
  const JournalEntry({required this.date, required this.body});
  final DateTime date;
  final String body;
  Map<String, dynamic> toMap() => {'date': dayKey(date), 'body': body};
  factory JournalEntry.fromMap(Map m) =>
      JournalEntry(date: DateTime.parse(m['date']), body: m['body']);
}
