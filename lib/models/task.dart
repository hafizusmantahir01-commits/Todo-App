import '../l10n/strings.dart';

enum Priority { none, low, medium, high }

enum Energy { low, medium, high }

enum Repeat { none, daily, weekly, monthly }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.none => tr('None'),
        Priority.low => tr('Low'),
        Priority.medium => tr('Medium'),
        Priority.high => tr('High'),
      };
}

extension EnergyX on Energy {
  String get label => switch (this) {
        Energy.low => tr('Easy'),
        Energy.medium => tr('Normal'),
        Energy.high => tr('Hard'),
      };
}

extension RepeatX on Repeat {
  String get label => switch (this) {
        Repeat.none => tr('Never'),
        Repeat.daily => tr('Daily'),
        Repeat.weekly => tr('Weekly'),
        Repeat.monthly => tr('Monthly'),
      };
}

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

class SubTask {
  SubTask({required this.id, required this.title, this.done = false});

  final String id;
  String title;
  bool done;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory SubTask.fromJson(Map<String, dynamic> j) => SubTask(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.listId = 'inbox',
    this.priority = Priority.none,
    this.energy = Energy.medium,
    this.due,
    this.hasTime = false,
    this.durationMinutes = 30,
    this.repeat = Repeat.none,
    this.pinned = false,
    this.reminderMinutes = -1,
    List<String>? tags,
    List<SubTask>? subtasks,
    this.done = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
    this.focusMinutes = 0,
  })  : tags = tags ?? <String>[],
        subtasks = subtasks ?? <SubTask>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  String notes;
  String listId;
  Priority priority;
  Energy energy;
  DateTime? due;
  bool hasTime;
  int durationMinutes;
  Repeat repeat;
  bool pinned;

  /// Minutes before the due time to remind. -1 means no reminder.
  int reminderMinutes;
  List<String> tags;
  List<SubTask> subtasks;
  bool done;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? completedAt;
  int focusMinutes;

  int get subDone => subtasks.where((s) => s.done).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'listId': listId,
        'priority': priority.name,
        'energy': energy.name,
        'due': due?.toIso8601String(),
        'hasTime': hasTime,
        'durationMinutes': durationMinutes,
        'repeat': repeat.name,
        'pinned': pinned,
        'reminderMinutes': reminderMinutes,
        'tags': tags,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'done': done,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'focusMinutes': focusMinutes,
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        listId: j['listId'] as String? ?? 'inbox',
        priority: enumByName(Priority.values, j['priority'], Priority.none),
        energy: enumByName(Energy.values, j['energy'], Energy.medium),
        due: _date(j['due']),
        hasTime: j['hasTime'] as bool? ?? false,
        durationMinutes: (j['durationMinutes'] as num? ?? 30).toInt(),
        repeat: enumByName(Repeat.values, j['repeat'], Repeat.none),
        pinned: j['pinned'] as bool? ?? false,
        reminderMinutes: (j['reminderMinutes'] as num? ?? -1).toInt(),
        tags: (j['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
        subtasks: (j['subtasks'] as List? ?? const [])
            .map((e) => SubTask.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        done: j['done'] as bool? ?? false,
        createdAt: _date(j['createdAt']),
        updatedAt: _date(j['updatedAt']),
        completedAt: _date(j['completedAt']),
        focusMinutes: (j['focusMinutes'] as num? ?? 0).toInt(),
      );
}

class TaskList {
  TaskList({required this.id, required this.name, required this.color});

  final String id;
  String name;
  int color;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};

  factory TaskList.fromJson(Map<String, dynamic> j) => TaskList(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'List',
        color: (j['color'] as num? ?? 0xFF8A7F77).toInt(),
      );
}
