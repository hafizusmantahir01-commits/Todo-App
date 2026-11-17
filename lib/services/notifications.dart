import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/store.dart';
import '../l10n/strings.dart';
import '../models/task.dart' show Task;
import '../utils/dates.dart';
import '../utils/prayer_times.dart';

/// Reminders shown by the phone even when the app is closed.
///
/// Times are scheduled as exact moments (UTC), so they are right whatever
/// the phone's time zone is. Android may deliver them a minute or two late
/// to save battery; this keeps the app free of special alarm permissions.
class Notifier {
  Notifier._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _taskChannel = AndroidNotificationDetails(
    'task_reminders',
    'Task reminders',
    channelDescription: 'Reminders before your tasks',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
  );
  static const _prayerChannel = AndroidNotificationDetails(
    'prayer_times',
    'Prayer times',
    channelDescription: 'A gentle note at prayer time, Sehri and Iftar',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  static const _planChannel = AndroidNotificationDetails(
    'planning',
    'Daily and weekly planning',
    channelDescription: 'Morning summary and weekly planning',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static Future<void> init() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_todo')),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Asks for permission to show notifications (Android 13 and newer).
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    } catch (_) {
      return false;
    }
  }

  static int _taskNotificationId(String taskId) => taskId.hashCode & 0x3fffffff;

  static Future<void> _at(int id, DateTime when, String title, String body, AndroidNotificationDetails channel) async {
    if (!_ready || !when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.UTC),
      notificationDetails: NotificationDetails(android: channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
  }

  /// Cancels everything and schedules again from the current data.
  static Future<void> rescheduleAll() async {
    if (!_ready) return;
    final s = AppStore.instance;
    try {
      await _plugin.cancelAll();
      final now = DateTime.now();

      // Tasks
      if (s.remindersOn) {
        final upcoming = s.tasks.where((t) {
          final d = t.due;
          return !t.done && t.hasTime && d != null && t.reminderMinutes >= 0 && d.isAfter(now);
        }).toList()
          ..sort((a, b) => a.due!.compareTo(b.due!));
        // Android allows a limited number of alarms per app; the nearest 50 are plenty.
        for (final t in upcoming.take(50)) {
          final when = t.due!.subtract(Duration(minutes: t.reminderMinutes));
          final body = t.reminderMinutes == 0
              ? tr('Starts now · {list}', {'list': s.listById(t.listId).name})
              : tr('In {m} · {time}', {'m': fmtMinutes(t.reminderMinutes), 'time': fmtTime(t.due!)});
          await _at(_taskNotificationId(t.id), when, t.title, body, _taskChannel);
        }
      }

      // Prayer times, Sehri and Iftar for the next 7 days
      for (var d = 0; d < 7; d++) {
        final day = DateTime(now.year, now.month, now.day + d);
        final pt = s.prayersFor(day);
        if (pt == null) break;
        final ramzan = s.ramzanMode == 'on' || (s.ramzanMode == 'auto' && s.hijriFor(day).isRamadan);
        if (s.prayerAlerts) {
          for (final p in Prayer.values) {
            if (!s.prayerAlertSet.contains(p.name)) continue;
            final next = s.tasks
                .where((t) => !t.done && t.hasTime && t.due != null && t.due!.isAfter(pt[p]) && sameDay(t.due!, day))
                .toList()
              ..sort((a, b) => a.due!.compareTo(b.due!));
            final body = next.isEmpty
                ? tr('Time for {p}. Nothing else planned right after.', {'p': p.label})
                : tr('Time for {p}. Next: {task} at {time}', {'p': p.label, 'task': next.first.title, 'time': fmtTime(next.first.due!)});
            await _at(800000000 + d * 10 + p.index, pt[p], tr('{p} · {time}', {'p': p.label, 'time': fmtTime(pt[p])}), body, _prayerChannel);
          }
        }
        if (ramzan) {
          await _at(800000000 + d * 10 + 7, pt[Prayer.fajr].subtract(const Duration(minutes: 45)), tr('Sehri'),
              tr('Sehri ends at {time}', {'time': fmtTime(pt[Prayer.fajr])}), _prayerChannel);
          await _at(800000000 + d * 10 + 8, pt[Prayer.maghrib].subtract(const Duration(minutes: 10)), tr('Iftar'),
              tr('Iftar at {time}', {'time': fmtTime(pt[Prayer.maghrib])}), _prayerChannel);
        }
      }

      // Morning summary
      if (s.morningSummary) {
        for (var d = 0; d < 7; d++) {
          final day = DateTime(now.year, now.month, now.day + d, s.morningHour);
          final count = s.tasks.where((t) => !t.done && t.due != null && sameDay(t.due!, day)).length;
          final body = count == 0 ? tr('Nothing planned yet. Add your top 3 for today.') : trn(count, '1 task today. Open to see your plan.', '{n} tasks today. Open to see your plan.');
          await _at(810000000 + d, day, tr('Good morning'), body, _planChannel);
        }
      }

      // Weekly planning, Sunday 8 PM
      if (s.weeklyReminder) {
        final daysToSunday = (DateTime.sunday - now.weekday) % 7;
        var sunday = DateTime(now.year, now.month, now.day + daysToSunday, 20);
        if (!sunday.isAfter(now)) sunday = DateTime(sunday.year, sunday.month, sunday.day + 7, 20);
        await _at(820000000, sunday, tr('Plan next week'), tr('Five minutes now saves hours later.'), _planChannel);
      }
    } catch (_) {
      // Never let a reminder problem break the app.
    }
  }

  /// Shows a reminder right away (used to test settings).
  static Future<void> test() async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: 1,
        title: tr('Reminders are on'),
        body: tr('You will be reminded before your tasks.'),
        notificationDetails: const NotificationDetails(android: _taskChannel),
      );
    } catch (_) {}
  }

  /// Minutes offered for task reminders.
  static const reminderChoices = [-1, 0, 5, 10, 15, 30, 60, 120];

  static String reminderLabel(int m) {
    if (m < 0) return tr('No reminder');
    if (m == 0) return tr('At start time');
    return tr('{m} before', {'m': fmtMinutes(m)});
  }

  static bool hasReminder(Task t) => t.reminderMinutes >= 0 && t.hasTime;
}
