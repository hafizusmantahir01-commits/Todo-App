/// A daily habit. [target] is 1 for a simple check habit, or a count
/// (for example 8 glasses of water).
class Habit {
  Habit({required this.id, required this.name, required this.color, this.target = 1, Map<String, int>? log})
      : log = log ?? <String, int>{};

  final String id;
  String name;
  int color;
  int target;

  /// Day key (yyyy-mm-dd) to how many times it was done that day.
  Map<String, int> log;

  bool get isCount => target > 1;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color, 'target': target, 'log': log};

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Habit',
        color: (j['color'] as num? ?? 0xFFF0672A).toInt(),
        target: (j['target'] as num? ?? 1).toInt(),
        log: (j['log'] as Map? ?? const {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      );
}

/// What the user wrote about a day in the evening review.
class DayLog {
  DayLog({this.mood, this.note = ''});

  int? mood;
  String note;

  Map<String, dynamic> toJson() => {'mood': mood, 'note': note};

  factory DayLog.fromJson(Map<String, dynamic> j) =>
      DayLog(mood: (j['mood'] as num?)?.toInt(), note: j['note'] as String? ?? '');
}
