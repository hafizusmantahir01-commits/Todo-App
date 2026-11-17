const monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
const weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdaysLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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

String fmtDate(DateTime d) => '${weekdaysShort[d.weekday - 1]}, ${d.day} ${monthsShort[d.month - 1]}';

String fmtLongDate(DateTime d) => '${weekdaysLong[d.weekday - 1]}, ${d.day} ${monthsLong[d.month - 1]}';

String fmtTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

String relDay(DateTime d) {
  final diff = daysFromToday(d);
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  return fmtDate(d);
}

String fmtMinutes(int m) {
  if (m < 60) return '${m}m';
  final r = m % 60;
  return r == 0 ? '${m ~/ 60}h' : '${m ~/ 60}h ${r}m';
}
