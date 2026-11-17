import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../models/habit.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../utils/hijri.dart';
import '../utils/prayer_times.dart';

/// Single source of truth for the app. Everything is saved on the device only.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  static final Random _rand = Random();
  static String newId() => '${DateTime.now().microsecondsSinceEpoch}${_rand.nextInt(1000)}';

  SharedPreferences? _prefs;

  List<Task> tasks = [];
  List<TaskList> lists = [];
  List<Habit> habits = [];
  Map<String, DayLog> dayLogs = {};
  Map<String, int> focusByDay = {};

  // Settings
  ThemeMode themeMode = ThemeMode.light;
  bool onboarded = false;
  String userName = '';
  bool prayerOn = true;
  String cityId = 'lahore';
  bool hanafi = true;
  int focusMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;

  // Profile picture: 'initial' (first letter), 'avatar' (built-in picture) or 'photo'.
  String avatarKind = 'initial';
  int avatarIndex = 0;
  int avatarColor = 0xFFC9A227;
  String? photoPath;

  // Language
  Lang lang = Lang.en;

  // Reminders and notifications
  bool remindersOn = true;
  int defaultReminder = 15;
  bool prayerAlerts = false;
  Set<String> prayerAlertSet = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};
  bool morningSummary = true;
  int morningHour = 8;
  bool weeklyReminder = true;

  // Ramzan: 'auto' follows the Hijri calendar, or 'on' / 'off'.
  String ramzanMode = 'auto';
  int hijriOffset = 0;

  // Phone calendar and focus sound
  bool calendarOn = false;
  String focusSound = 'off';

  /// Week start (yyyy-mm-dd of Monday) to up to three goals.
  Map<String, List<String>> weekGoals = {};

  /// Called (once, shortly) after data or settings change: reminders and widget refresh.
  static void Function()? afterChange;
  Timer? _debounce;

  void _scheduleSideEffects() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () => afterChange?.call());
  }

  HijriDate hijriFor(DateTime d) => HijriDate.fromDate(d, offsetDays: hijriOffset);

  bool get isRamzan => ramzanMode == 'on' || (ramzanMode == 'auto' && hijriFor(DateTime.now()).isRamadan);

  static const areaNames = ['Study', 'Work', 'Home', 'Health', 'Shopping', 'Deen'];
  static const _areaColors = {
    'Study': 0xFF2563EB,
    'Work': 0xFF14213D,
    'Home': 0xFFD97706,
    'Health': 0xFFE11D48,
    'Shopping': 0xFF0D9488,
    'Deen': 0xFFC9A227,
  };

  static List<TaskList> listsFor(Iterable<String> areas) => [
        TaskList(id: 'inbox', name: tr('Inbox'), color: 0xFF6B7280),
        for (final a in areas) TaskList(id: a.toLowerCase(), name: tr(a), color: _areaColors[a] ?? listPalette.last),
      ];

  City get city => cityById(cityId);

  /// Prayer times for [day], or null when prayer times are switched off.
  PrayerTimes? prayersFor(DateTime day) => prayerOn ? PrayerTimes.forDay(day, city, hanafi: hanafi) : null;

  // ---------------- Load / save ----------------
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    try {
      final raw = p.getString('data');
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        List<Map<String, dynamic>> maps(Object? v) =>
            (v as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        tasks = maps(j['tasks']).map(Task.fromJson).toList();
        lists = maps(j['lists']).map(TaskList.fromJson).toList();
        habits = maps(j['habits']).map(Habit.fromJson).toList();
        final logs = j['dayLogs'];
        if (logs is Map) {
          dayLogs = logs.map((k, v) => MapEntry(k.toString(), DayLog.fromJson(Map<String, dynamic>.from(v as Map))));
        }
        final f = j['focus'];
        if (f is Map) focusByDay = f.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
        final g = j['weekGoals'];
        if (g is Map) {
          weekGoals = g.map((k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()));
        }
      }
    } catch (_) {
      tasks = [];
      lists = [];
      habits = [];
      dayLogs = {};
      focusByDay = {};
    }
    if (lists.isEmpty) lists = listsFor(areaNames);
    final ti = p.getInt('theme') ?? ThemeMode.light.index;
    themeMode = (ti >= 0 && ti < ThemeMode.values.length) ? ThemeMode.values[ti] : ThemeMode.light;
    onboarded = p.getBool('onboarded') ?? false;
    userName = p.getString('name') ?? '';
    prayerOn = p.getBool('prayerOn') ?? true;
    cityId = p.getString('city') ?? 'lahore';
    hanafi = p.getBool('hanafi') ?? true;
    focusMinutes = p.getInt('focusMin') ?? 25;
    shortBreakMinutes = p.getInt('shortBreak') ?? 5;
    longBreakMinutes = p.getInt('longBreak') ?? 15;
    avatarKind = p.getString('avatarKind') ?? 'initial';
    avatarIndex = p.getInt('avatarIndex') ?? 0;
    avatarColor = p.getInt('avatarColor') ?? 0xFFC9A227;
    photoPath = p.getString('photoPath');
    lang = enumByName(Lang.values, p.getString('lang'), Lang.en);
    currentLang = lang;
    remindersOn = p.getBool('remindersOn') ?? true;
    defaultReminder = p.getInt('defaultReminder') ?? 15;
    prayerAlerts = p.getBool('prayerAlerts') ?? false;
    final pa = p.getStringList('prayerAlertSet');
    if (pa != null) prayerAlertSet = pa.toSet();
    morningSummary = p.getBool('morningSummary') ?? true;
    morningHour = p.getInt('morningHour') ?? 8;
    weeklyReminder = p.getBool('weeklyReminder') ?? true;
    ramzanMode = p.getString('ramzanMode') ?? 'auto';
    hijriOffset = p.getInt('hijriOffset') ?? 0;
    calendarOn = p.getBool('calendarOn') ?? false;
    focusSound = p.getString('focusSound') ?? 'off';
  }

  /// Saves any of the extra settings and refreshes reminders.
  void setSettings({
    Lang? language,
    bool? reminders,
    int? reminderMinutes,
    bool? prayerAlertsOn,
    Set<String>? prayerSet,
    bool? morning,
    int? morningAt,
    bool? weekly,
    String? ramzan,
    int? hijriAdjust,
    bool? calendar,
    String? sound,
  }) {
    final p = _prefs;
    if (language != null) {
      lang = language;
      currentLang = language;
      p?.setString('lang', language.name);
    }
    if (reminders != null) {
      remindersOn = reminders;
      p?.setBool('remindersOn', reminders);
    }
    if (reminderMinutes != null) {
      defaultReminder = reminderMinutes;
      p?.setInt('defaultReminder', reminderMinutes);
    }
    if (prayerAlertsOn != null) {
      prayerAlerts = prayerAlertsOn;
      p?.setBool('prayerAlerts', prayerAlertsOn);
    }
    if (prayerSet != null) {
      prayerAlertSet = prayerSet;
      p?.setStringList('prayerAlertSet', prayerSet.toList());
    }
    if (morning != null) {
      morningSummary = morning;
      p?.setBool('morningSummary', morning);
    }
    if (morningAt != null) {
      morningHour = morningAt;
      p?.setInt('morningHour', morningAt);
    }
    if (weekly != null) {
      weeklyReminder = weekly;
      p?.setBool('weeklyReminder', weekly);
    }
    if (ramzan != null) {
      ramzanMode = ramzan;
      p?.setString('ramzanMode', ramzan);
    }
    if (hijriAdjust != null) {
      hijriOffset = hijriAdjust;
      p?.setInt('hijriOffset', hijriAdjust);
    }
    if (calendar != null) {
      calendarOn = calendar;
      p?.setBool('calendarOn', calendar);
    }
    if (sound != null) {
      focusSound = sound;
      p?.setString('focusSound', sound);
    }
    notifyListeners();
    _scheduleSideEffects();
  }

  // ---------------- Weekly goals ----------------
  String weekKey(DateTime d) => dayKey(DateTime(d.year, d.month, d.day - (d.weekday - 1)));

  List<String> goalsFor(DateTime weekDay) => weekGoals[weekKey(weekDay)] ?? const [];

  void setGoals(DateTime weekDay, List<String> goals) {
    weekGoals[weekKey(weekDay)] = goals.where((g) => g.trim().isNotEmpty).toList();
    _changed();
  }

  // ---------------- Backup ----------------
  /// Replaces all data with a backup made by [exportJson]. Returns false if the file is not a backup.
  bool importJson(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['tasks'] is! List || j['lists'] is! List) return false;
      List<Map<String, dynamic>> maps(Object? v) =>
          (v as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final newTasks = maps(j['tasks']).map(Task.fromJson).toList();
      final newLists = maps(j['lists']).map(TaskList.fromJson).toList();
      final newHabits = maps(j['habits']).map(Habit.fromJson).toList();
      final logs = j['dayLogs'];
      final focus = j['focusMinutesByDay'];
      tasks = newTasks;
      if (newLists.isNotEmpty) lists = newLists;
      habits = newHabits;
      dayLogs = logs is Map
          ? logs.map((k, v) => MapEntry(k.toString(), DayLog.fromJson(Map<String, dynamic>.from(v as Map))))
          : {};
      focusByDay = focus is Map ? focus.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) : {};
      _changed();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _persist() {
    _prefs?.setString(
      'data',
      jsonEncode({
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'lists': lists.map((l) => l.toJson()).toList(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'dayLogs': dayLogs.map((k, v) => MapEntry(k, v.toJson())),
        'focus': focusByDay,
        'weekGoals': weekGoals,
      }),
    );
  }

  void _changed() {
    _persist();
    notifyListeners();
    _scheduleSideEffects();
  }

  // ---------------- Settings ----------------
  /// Saves the profile picture choice.
  void setAvatar({required String kind, int? index, int? color, String? photo}) {
    avatarKind = kind;
    if (index != null) avatarIndex = index;
    if (color != null) avatarColor = color;
    if (photo != null) photoPath = photo;
    final p = _prefs;
    p?.setString('avatarKind', avatarKind);
    p?.setInt('avatarIndex', avatarIndex);
    p?.setInt('avatarColor', avatarColor);
    if (photoPath != null) p?.setString('photoPath', photoPath!);
    notifyListeners();
  }

  void completeOnboarding({
    required String name,
    required Set<String> areas,
    required bool prayers,
    required String city,
    required ThemeMode theme,
  }) {
    userName = name.trim();
    prayerOn = prayers;
    cityId = city;
    themeMode = theme;
    onboarded = true;
    if (tasks.isEmpty) lists = listsFor(areaNames.where(areas.contains));
    final p = _prefs;
    p?.setString('name', userName);
    p?.setBool('prayerOn', prayerOn);
    p?.setString('city', cityId);
    p?.setInt('theme', themeMode.index);
    p?.setBool('onboarded', true);
    _changed();
  }

  void setTheme(ThemeMode m) {
    themeMode = m;
    _prefs?.setInt('theme', m.index);
    notifyListeners();
  }

  void setName(String n) {
    userName = n.trim();
    _prefs?.setString('name', userName);
    notifyListeners();
  }

  void setPrayer({bool? on, String? city, bool? hanafiAsr}) {
    _scheduleSideEffects();
    if (on != null) {
      prayerOn = on;
      _prefs?.setBool('prayerOn', on);
    }
    if (city != null) {
      cityId = city;
      _prefs?.setString('city', city);
    }
    if (hanafiAsr != null) {
      hanafi = hanafiAsr;
      _prefs?.setBool('hanafi', hanafiAsr);
    }
    notifyListeners();
  }

  void setFocusDurations({int? focus, int? shortBreak, int? longBreak}) {
    if (focus != null) {
      focusMinutes = focus;
      _prefs?.setInt('focusMin', focus);
    }
    if (shortBreak != null) {
      shortBreakMinutes = shortBreak;
      _prefs?.setInt('shortBreak', shortBreak);
    }
    if (longBreak != null) {
      longBreakMinutes = longBreak;
      _prefs?.setInt('longBreak', longBreak);
    }
    notifyListeners();
  }

  // ---------------- Lookups ----------------
  TaskList listById(String id) {
    for (final l in lists) {
      if (l.id == id) return l;
    }
    return lists.first;
  }

  TaskList? listByName(String name) {
    for (final l in lists) {
      if (l.name.toLowerCase() == name.toLowerCase()) return l;
    }
    return null;
  }

  Task? taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ---------------- Tasks ----------------
  void addTask(Task t) {
    tasks.add(t);
    _changed();
  }

  void addTasks(List<Task> list) {
    tasks.addAll(list);
    _changed();
  }

  void updateTask(Task t) {
    t.updatedAt = DateTime.now();
    _changed();
  }

  /// Completing a repeating task creates its next copy, which is returned so
  /// the action can be undone.
  Task? toggleDone(Task t) {
    Task? spawned;
    t.done = !t.done;
    t.updatedAt = DateTime.now();
    if (t.done) {
      t.completedAt = DateTime.now();
      t.pinned = false;
      final due = t.due;
      if (t.repeat != Repeat.none && due != null) {
        spawned = Task(
          id: newId(),
          title: t.title,
          notes: t.notes,
          listId: t.listId,
          priority: t.priority,
          energy: t.energy,
          due: switch (t.repeat) {
            Repeat.daily => addDays(due, 1),
            Repeat.weekly => addDays(due, 7),
            Repeat.monthly => addMonths(due, 1),
            Repeat.none => due,
          },
          hasTime: t.hasTime,
          durationMinutes: t.durationMinutes,
          repeat: t.repeat,
          tags: List.of(t.tags),
          subtasks: t.subtasks.map((s) => SubTask(id: newId(), title: s.title)).toList(),
        );
        tasks.add(spawned);
        t.repeat = Repeat.none;
      }
    } else {
      t.completedAt = null;
    }
    _changed();
    return spawned;
  }

  void undoComplete(Task t, Task? spawned, Repeat oldRepeat) {
    t.done = false;
    t.completedAt = null;
    t.repeat = oldRepeat;
    if (spawned != null) tasks.remove(spawned);
    _changed();
  }

  int deleteTask(Task t) {
    final i = tasks.indexOf(t);
    tasks.remove(t);
    _changed();
    return i;
  }

  void restoreTask(Task t, int index) {
    tasks.insert(min(max(index, 0), tasks.length), t);
    _changed();
  }

  /// Moves a task to [day], keeping its time. A null day removes the date.
  void moveToDay(Task t, DateTime? day) {
    if (day == null) {
      t.due = null;
      t.hasTime = false;
    } else {
      final old = t.due;
      t.due = (t.hasTime && old != null)
          ? DateTime(day.year, day.month, day.day, old.hour, old.minute)
          : DateTime(day.year, day.month, day.day);
    }
    updateTask(t);
  }

  void moveAllToTomorrow(Iterable<Task> list) {
    final n = DateTime.now();
    final tomorrow = DateTime(n.year, n.month, n.day + 1);
    for (final t in list.toList()) {
      final old = t.due;
      t.due = (t.hasTime && old != null)
          ? DateTime(tomorrow.year, tomorrow.month, tomorrow.day, old.hour, old.minute)
          : tomorrow;
      t.updatedAt = DateTime.now();
    }
    _changed();
  }

  /// Pins or unpins a task for "Today's top 3". Returns false when 3 are already pinned.
  bool setPinned(Task t, bool value) {
    if (value && !t.pinned && tasks.where((x) => x.pinned && !x.done).length >= 3) return false;
    t.pinned = value;
    updateTask(t);
    return true;
  }

  void addFocus(Task? t, int minutes) {
    if (minutes <= 0) return;
    final k = dayKey(DateTime.now());
    focusByDay[k] = (focusByDay[k] ?? 0) + minutes;
    if (t != null) t.focusMinutes += minutes;
    _changed();
  }

  // ---------------- Lists ----------------
  void addList(String name, int color) {
    lists.add(TaskList(id: newId(), name: name, color: color));
    _changed();
  }

  void deleteList(TaskList l) {
    if (l.id == 'inbox') return;
    for (final t in tasks) {
      if (t.listId == l.id) t.listId = 'inbox';
    }
    lists.remove(l);
    _changed();
  }

  // ---------------- Habits ----------------
  void addHabit(String name, int color, int target) {
    habits.add(Habit(id: newId(), name: name, color: color, target: target));
    _changed();
  }

  void updateHabit(Habit h) => _changed();

  void deleteHabit(Habit h) {
    habits.remove(h);
    _changed();
  }

  /// Check habits toggle; count habits add one and wrap to zero after the target.
  void tapHabit(Habit h, DateTime day) {
    final k = dayKey(day);
    final v = h.log[k] ?? 0;
    final next = h.isCount ? (v >= h.target ? 0 : v + 1) : (v > 0 ? 0 : 1);
    if (next == 0) {
      h.log.remove(k);
    } else {
      h.log[k] = next;
    }
    _changed();
  }

  bool habitDone(Habit h, DateTime day) => (h.log[dayKey(day)] ?? 0) >= h.target;

  int habitStreak(Habit h) {
    var d = dayStart(DateTime.now());
    if (!habitDone(h, d)) d = DateTime(d.year, d.month, d.day - 1);
    var n = 0;
    while (n < 3650 && habitDone(h, d)) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  // ---------------- Day review ----------------
  DayLog logFor(DateTime day) => dayLogs.putIfAbsent(dayKey(day), () => DayLog());

  void saveLog() => _changed();

  // ---------------- Data ----------------
  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'Todo App',
        'exportedAt': DateTime.now().toIso8601String(),
        'lists': lists.map((l) => l.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'dayLogs': dayLogs.map((k, v) => MapEntry(k, v.toJson())),
        'focusMinutesByDay': focusByDay,
      });

  void clearAll() {
    tasks = [];
    habits = [];
    dayLogs = {};
    focusByDay = {};
    lists = listsFor(areaNames);
    _changed();
  }

  // ---------------- Queries ----------------
  DateTime get _today => dayStart(DateTime.now());
  DateTime get _tomorrow => DateTime(_today.year, _today.month, _today.day + 1);

  List<Task> sortTasks(Iterable<Task> it) {
    final l = it.toList();
    l.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      final ad = a.due;
      final bd = b.due;
      if (ad != null && bd != null) {
        final c = ad.compareTo(bd);
        if (c != 0) return c;
      } else if (ad != null) {
        return -1;
      } else if (bd != null) {
        return 1;
      }
      return b.priority.index.compareTo(a.priority.index);
    });
    return l;
  }

  Iterable<Task> get _open => tasks.where((t) => !t.done);

  List<Task> get overdue => sortTasks(_open.where((t) => t.due != null && t.due!.isBefore(_today)));

  List<Task> get dueToday =>
      sortTasks(_open.where((t) => t.due != null && !t.due!.isBefore(_today) && t.due!.isBefore(_tomorrow)));

  List<Task> get anytime => sortTasks(_open.where((t) => t.due == null));

  List<Task> get completedToday => tasks
      .where((t) => t.done && t.completedAt != null && sameDay(t.completedAt!, DateTime.now()))
      .toList();

  List<Task> tasksOn(DateTime day) => sortTasks(tasks.where((t) => t.due != null && sameDay(t.due!, day)));

  /// Pinned tasks first, then the most important tasks due today or overdue.
  List<Task> get topThree {
    final pinned = _open.where((t) => t.pinned).toList();
    if (pinned.length >= 3) return pinned.take(3).toList();
    final pool = [...overdue, ...dueToday].where((t) => !t.pinned).toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return [...pinned, ...pool].take(3).toList();
  }

  /// Overdue for 3+ days, or undated and untouched for a week.
  List<Task> get stale {
    final now = DateTime.now();
    final cutoff = DateTime(_today.year, _today.month, _today.day - 2);
    return sortTasks(_open.where((t) {
      if (t.due != null) return t.due!.isBefore(cutoff);
      return now.difference(t.updatedAt).inDays >= 7;
    }));
  }

  int completedOn(DateTime day) =>
      tasks.where((t) => t.done && t.completedAt != null && sameDay(t.completedAt!, day)).length;

  List<int> last7Days() {
    final t = _today;
    return [for (var i = 6; i >= 0; i--) completedOn(DateTime(t.year, t.month, t.day - i))];
  }

  int get streak {
    var d = _today;
    if (completedOn(d) == 0) d = DateTime(d.year, d.month, d.day - 1);
    var count = 0;
    while (count < 3650 && completedOn(d) > 0) {
      count++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return count;
  }

  int focusOn(DateTime day) => focusByDay[dayKey(day)] ?? 0;

  int get focusThisWeek {
    final t = _today;
    var sum = 0;
    for (var i = 0; i < 7; i++) {
      sum += focusOn(DateTime(t.year, t.month, t.day - i));
    }
    return sum;
  }

  double? get completionRate {
    final from = DateTime(_today.year, _today.month, _today.day - 6);
    final due = tasks.where((t) => t.due != null && !t.due!.isBefore(from) && t.due!.isBefore(_tomorrow)).toList();
    if (due.isEmpty) return null;
    return due.where((t) => t.done).length / due.length;
  }

  int? get bestHour {
    final counts = List<int>.filled(24, 0);
    var any = false;
    for (final t in tasks) {
      final c = t.completedAt;
      if (t.done && c != null) {
        counts[c.hour]++;
        any = true;
      }
    }
    if (!any) return null;
    var best = 0;
    for (var h = 1; h < 24; h++) {
      if (counts[h] > counts[best]) best = h;
    }
    return best;
  }

  Map<String, int> completedByList({int days = 30}) {
    final from = DateTime(_today.year, _today.month, _today.day - days);
    final out = <String, int>{};
    for (final t in tasks) {
      final c = t.completedAt;
      if (t.done && c != null && c.isAfter(from)) out[t.listId] = (out[t.listId] ?? 0) + 1;
    }
    return out;
  }
}
