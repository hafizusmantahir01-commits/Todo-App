import '../l10n/strings.dart';

DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

DateTime addMonths(DateTime d, int months) {
  final target = DateTime(d.year, d.month + months, 1);
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  final day = d.day > lastDay ? lastDay : d.day;
  return DateTime(target.year, target.month, day, d.hour, d.minute);
}

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int daysFromToday(DateTime d) {
  final today = dayStart(DateTime.now());
  return (dayStart(d).difference(today).inHours / 24).round();
}

/// "Mon, 16 Nov"
String fmtDate(DateTime d) => '${dayShort(d.weekday)}, ${d.day} ${monthShort(d.month)}';

/// "Monday, 16 November"
String fmtLongDate(DateTime d) => '${dayName(d.weekday)}, ${d.day} ${monthName(d.month)}';

String fmtTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

String fmtHour(int h) => '${h % 12 == 0 ? 12 : h % 12} ${h < 12 ? 'AM' : 'PM'}';

String relDay(DateTime d) {
  final diff = daysFromToday(d);
  if (diff == 0) return tr('Today');
  if (diff == 1) return tr('Tomorrow');
  if (diff == -1) return tr('Yesterday');
  return fmtDate(d);
}

String fmtMinutes(int m) {
  if (m < 60) return tr('{n}m', {'n': m});
  final r = m % 60;
  return r == 0 ? tr('{h}h', {'h': m ~/ 60}) : tr('{h}h {m}m', {'h': m ~/ 60, 'm': r});
}
