import 'package:flutter/material.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../services/widget_sync.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Choose what the home-screen widget shows and how it looks, with a live preview.
class WidgetSettingsScreen extends StatelessWidget {
  const WidgetSettingsScreen({super.key});

  static const contents = <(String, IconData)>[
    ('top3', Icons.star_outline_rounded),
    ('next', Icons.schedule_rounded),
    ('prayer', Icons.mosque_outlined),
    ('habits', Icons.track_changes_rounded),
  ];

  static String contentLabel(String k) => switch (k) {
        'next' => tr('Next tasks'),
        'prayer' => tr('Next prayer + tasks'),
        'habits' => tr('Habits'),
        _ => tr('Today’s top 3'),
      };

  static String styleLabel(String k) => switch (k) {
        'light' => tr('Light'),
        'gold' => tr('Gold'),
        _ => tr('Navy'),
      };

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final data = WidgetSync.build(store.widgetContent);
        final (Color bg, Color title, Color text, Color sub) = switch (store.widgetStyle) {
          'light' => (Colors.white, const Color(0xFF7A5C05), const Color(0xFF14213D), const Color(0xFF5D6475)),
          'gold' => (const Color(0xFFC9A227), const Color(0xFF14213D), const Color(0xFF14213D), const Color(0xFF3B3420)),
          _ => (const Color(0xFF14213D), const Color(0xFFE9C46A), Colors.white, const Color(0xFFAAB3C8)),
        };
        return Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            backgroundColor: c.bg,
            surfaceTintColor: Colors.transparent,
            title: Text(tr('Home screen widget'), style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              Text(tr('Preview'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.muted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(24),
                  border: store.widgetStyle == 'light' ? Border.all(color: c.border) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: TextStyle(color: title, fontWeight: FontWeight.w800, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    if (data.lines.isEmpty)
                      Text(tr('Nothing planned. Tap to add.'), style: TextStyle(color: text, fontSize: 15.5))
                    else
                      for (final l in data.lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(l,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: text, fontSize: 15.5, fontWeight: FontWeight.w600)),
                        ),
                    const SizedBox(height: 6),
                    Text(data.sub, style: TextStyle(color: sub, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionTitle(tr('What it shows')),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final k in contents)
                      ListTile(
                        leading: Icon(k.$2, color: store.widgetContent == k.$1 ? c.orange : c.muted),
                        title: Text(contentLabel(k.$1), style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                        trailing: store.widgetContent == k.$1 ? Icon(Icons.check_rounded, color: c.orange) : null,
                        onTap: () => store.setSettings(widgetShows: k.$1),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionTitle(tr('Look')),
              Row(
                children: [
                  for (final k in const ['navy', 'light', 'gold']) ...[
                    Expanded(
                      child: ChoicePill(
                        label: styleLabel(k),
                        selected: store.widgetStyle == k,
                        onTap: () => store.setSettings(widgetLook: k),
                      ),
                    ),
                    if (k != 'gold') const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              AppCard(
                color: c.orangeSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.widgets_outlined, color: c.orangeText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr('To add it: press and hold an empty spot on your home screen, tap Widgets, find Todo App and drag it out. Changes here show on the widget within a few seconds.'),
                        style: TextStyle(fontSize: 13, color: c.orangeText, height: 1.45, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
