import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _rows = <(String, String)>[
    ('aaj / today', 'Due today'),
    ('kal / tomorrow', 'Due tomorrow'),
    ('parson', 'Day after tomorrow'),
    ('juma, peer, friday, mon …', 'Next matching weekday'),
    ('agle hafte / next week', 'One week from today'),
    ('3 din baad / in 3 days', 'That many days from today'),
    ('5 baje, 5pm, 17:30', 'A time (5 baje means 5 PM)'),
    ('sadhe 4 baje', '4:30'),
    ('subah, dopahar, shaam, raat', 'About 9 AM, 2 PM, 6 PM, 9 PM'),
    ('Fajr ke baad, after Fajr', '15 minutes after Fajr'),
    ('Zuhr se pehle, before Zuhr', '30 minutes before Zuhr'),
    ('Asr, Maghrib, Isha', 'Just after that prayer'),
    ('har roz / daily', 'Repeats every day'),
    ('har hafte / har juma', 'Repeats weekly'),
    ('har mahine / monthly', 'Repeats monthly'),
    ('!high  !medium  !low', 'Priority (also: urgent, zaroori)'),
    ('#Study', 'Puts the task in that list'),
    ('#anything', 'Adds a tag'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        title: Text(tr('Smart typing guide'), style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          Text(tr('Type the way you talk. These words fill in the details for you.'),
              style: TextStyle(fontSize: 15, color: c.muted, height: 1.45)),
          const SizedBox(height: 14),
          AppCard(
            color: c.inv,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Example'), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.invMuted)),
                const SizedBox(height: 6),
                Text(tr('kal Maghrib ke baad gym #Health !high'),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.orange, height: 1.35)),
                const SizedBox(height: 6),
                Text(tr('Creates “Gym” for tomorrow, 15 minutes after Maghrib, in Health, high priority.'),
                    style: TextStyle(color: c.onInv, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final r in _rows)
                  Container(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(tr(r.$1), style: TextStyle(fontWeight: FontWeight.w800, color: c.orangeText, height: 1.3)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: Text(tr(r.$2), style: TextStyle(color: c.ink, height: 1.3))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
