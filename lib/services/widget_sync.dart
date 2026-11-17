import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../utils/dates.dart';
import '../utils/prayer_times.dart';
import 'native.dart';

/// What the home-screen widget shows, worked out from the current data.
class WidgetData {
  const WidgetData(this.title, this.lines, this.sub);
  final String title;
  final List<String> lines;
  final String sub;
}

/// Writes the widget's text where Android can read it, then asks it to redraw.
class WidgetSync {
  WidgetSync._();

  static WidgetData build(String content) {
    final s = AppStore.instance;
    final now = DateTime.now();
    final left = s.overdue.length + s.dueToday.length;
    final leftText = left == 0 ? tr('All clear today') : trn(left, '1 task left today', '{n} tasks left today');
    String line(t) => '${t.due != null && t.hasTime ? '${fmtTime(t.due!)}  ' : ''}${t.title}';

    switch (content) {
      case 'next':
        final upcoming = [...s.overdue, ...s.dueToday.where((t) => !t.hasTime || !t.due!.isBefore(now))];
        return WidgetData(tr('Next up'), upcoming.take(3).map(line).toList(), leftText);
      case 'prayer':
        final pt = s.prayersFor(now);
        if (pt != null) {
          final next = pt.nextAfter(now);
          final title = next == null
              ? tr('Isha done · plan tomorrow')
              : tr('Next: {p} at {time}', {'p': next.label, 'time': fmtTime(pt[next])});
          final before = next == null
              ? s.dueToday
              : s.dueToday.where((t) => t.hasTime && t.due!.isBefore(pt[next]) && !t.due!.isBefore(now)).toList();
          final lines = (before.isEmpty ? s.topThree : before).take(3).map(line).toList();
          return WidgetData(title, lines, leftText);
        }
        break;
      case 'habits':
        if (s.habits.isNotEmpty) {
          final done = s.habits.where((h) => s.habitDone(h, now)).length;
          return WidgetData(
            tr('Habits today'),
            s.habits.take(3).map((h) => '${s.habitDone(h, now) ? '✓' : '○'}  ${h.name}').toList(),
            tr('{a} of {b} done', {'a': done, 'b': s.habits.length}),
          );
        }
        break;
    }
    return WidgetData(tr('Today’s top 3'), s.topThree.map(line).toList(), leftText);
  }

  static Future<void> update() async {
    try {
      final s = AppStore.instance;
      final d = build(s.widgetContent);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_title', d.title);
      await prefs.setString('widget_l1', d.lines.isNotEmpty ? d.lines[0] : tr('Nothing planned. Tap to add.'));
      await prefs.setString('widget_l2', d.lines.length > 1 ? d.lines[1] : '');
      await prefs.setString('widget_l3', d.lines.length > 2 ? d.lines[2] : '');
      await prefs.setString('widget_sub', d.sub);
      await prefs.setString('widget_style', s.widgetStyle);
      await Native.updateWidget();
    } catch (_) {}
  }
}
