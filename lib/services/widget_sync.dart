import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../utils/dates.dart';
import 'native.dart';

/// Writes today's top tasks where the home-screen widget can read them.
class WidgetSync {
  WidgetSync._();

  static Future<void> update() async {
    try {
      final s = AppStore.instance;
      final prefs = await SharedPreferences.getInstance();
      final top = s.topThree;
      final left = s.overdue.length + s.dueToday.length;
      final lines = <String>[
        for (final t in top) '${t.due != null && t.hasTime ? '${fmtTime(t.due!)}  ' : ''}${t.title}',
      ];
      await prefs.setString('widget_title', tr('Today’s top 3'));
      await prefs.setString('widget_l1', lines.isNotEmpty ? lines[0] : tr('Nothing planned. Tap to add.'));
      await prefs.setString('widget_l2', lines.length > 1 ? lines[1] : '');
      await prefs.setString('widget_l3', lines.length > 2 ? lines[2] : '');
      await prefs.setString('widget_sub', left == 0 ? tr('All clear today') : trn(left, '1 task left today', '{n} tasks left today'));
      await Native.updateWidget();
    } catch (_) {}
  }
}
