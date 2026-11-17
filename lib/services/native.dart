import 'package:flutter/services.dart';

/// Talks to the Android side of the app (MainActivity.kt): phone calendar and home-screen widget.
class Native {
  Native._();

  static const _ch = MethodChannel('todo_app/native');

  static Future<bool> hasCalendarPermission() async {
    try {
      return await _ch.invokeMethod<bool>('hasCalendarPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestCalendarPermission() async {
    try {
      return await _ch.invokeMethod<bool>('requestCalendarPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Events from the phone's calendars (Google Calendar included) between [from] and [to].
  static Future<List<PhoneEvent>> calendarEvents(DateTime from, DateTime to) async {
    try {
      final raw = await _ch.invokeMethod<List<Object?>>('calendarEvents', {
        'start': from.millisecondsSinceEpoch,
        'end': to.millisecondsSinceEpoch,
      });
      return [
        for (final e in raw ?? const <Object?>[])
          if (e is Map) PhoneEvent.fromMap(e),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Asks Android to redraw the home-screen widget.
  static Future<void> updateWidget() async {
    try {
      await _ch.invokeMethod<void>('updateWidget');
    } catch (_) {}
  }
}

class PhoneEvent {
  const PhoneEvent({required this.title, required this.start, required this.end, required this.allDay, required this.color});

  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final int color;

  factory PhoneEvent.fromMap(Map<Object?, Object?> m) => PhoneEvent(
        title: (m['title'] as String?)?.trim().isNotEmpty == true ? m['title'] as String : '(No title)',
        start: DateTime.fromMillisecondsSinceEpoch((m['begin'] as num? ?? 0).toInt()),
        end: DateTime.fromMillisecondsSinceEpoch((m['end'] as num? ?? 0).toInt()),
        allDay: m['allDay'] == true,
        color: (m['color'] as num? ?? 0xFF8A7F77).toInt() | 0xFF000000,
      );
}
