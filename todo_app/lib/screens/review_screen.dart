import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';

/// Evening review: today's numbers, what is left, mood, and the week's insights.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final store = AppStore.instance;
  late final TextEditingController _note;

  static const _moods = [
    (Icons.sentiment_very_dissatisfied_rounded, 'Rough'),
    (Icons.sentiment_dissatisfied_rounded, 'Meh'),
    (Icons.sentiment_neutral_rounded, 'Okay'),
    (Icons.sentiment_satisfied_rounded, 'Good'),
    (Icons.sentiment_very_satisfied_rounded, 'Great'),
  ];

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: store.logFor(DateTime.now()).note);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _hour(int h) => '${h % 12 == 0 ? 12 : h % 12} ${h < 12 ? 'AM' : 'PM'}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final now = DateTime.now();
        final log = store.logFor(now);
        final doneToday = store.completedToday.length;
        final focusToday = store.focusOn(now);
        final habits = store.habits;
        final habitsDone = habits.where((h) => store.habitDone(h, now)).length;
        final left = [...store.overdue, ...store.dueToday];
        final week = store.last7Days();
        final maxV = week.fold<int>(1, (a, b) => b > a ? b : a);
        final rate = store.completionRate;
        final best = store.bestHour;
        final byList = store.completedByList();
        final maxList = byList.values.fold<int>(1, (a, b) => b > a ? b : a);
        final streak = store.streak;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(color: c.inv, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32))),
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${fmtLongDate(now)} · ${fmtTime(now)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.invMuted, height: 1.2)),
                  const SizedBox(height: 4),
                  Text('Your day, wrapped',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: c.onInv, height: 1.2)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _Stat(value: '$doneToday', label: 'tasks done', accent: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _Stat(value: fmtMinutes(focusToday), label: 'focused')),
                      const SizedBox(width: 8),
                      Expanded(child: _Stat(value: habits.isEmpty ? '–' : '$habitsDone/${habits.length}', label: 'habits')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: c.invRaised, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: c.orange, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            streak == 0 ? 'Finish one task today to start a streak.' : '$streak-day streak. Keep it going.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.onInv, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionTitle(
                          left.isEmpty ? 'Nothing left for today' : 'Left for tomorrow?',
                          trailing: left.isEmpty
                              ? null
                              : TextButton(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    store.moveAllToTomorrow(left);
                                    toast(context, 'Moved ${left.length} to tomorrow');
                                  },
                                  style: TextButton.styleFrom(foregroundColor: c.orangeText),
                                  child: const Text('Move all'),
                                ),
                        ),
                        if (left.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('Everything due today is done. Well played.', style: TextStyle(color: c.muted)),
                          ),
                        for (final t in left)
                          Container(
                            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Color(store.listById(t.listId).color),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontWeight: FontWeight.w700, color: c.ink, height: 1.3)),
                                      Text(dueLabel(t), style: TextStyle(fontSize: 12.5, color: c.muted, height: 1.3)),
                                    ],
                                  ),
                                ),
                                ChoicePill(label: 'Tomorrow', onTap: () => store.moveAllToTomorrow([t])),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle('How did today feel?'),
                        Row(
                          children: [
                            for (var i = 0; i < _moods.length; i++) ...[
                              Expanded(
                                child: Material(
                                  color: log.mood == i ? c.orangeSoft : c.raised,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: log.mood == i ? c.orange : Colors.transparent, width: 2),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      log.mood = i;
                                      store.saveLog();
                                    },
                                    child: SizedBox(
                                      height: 68,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(_moods[i].$1, color: log.mood == i ? c.orangeText : c.ink),
                                          const SizedBox(height: 4),
                                          Text(_moods[i].$2,
                                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.ink, height: 1)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (i < _moods.length - 1) const SizedBox(width: 6),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _note,
                          cursorColor: c.orange,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(color: c.ink),
                          decoration: InputDecoration(
                            hintText: 'One line about today (optional)',
                            hintStyle: TextStyle(color: c.muted),
                            filled: true,
                            fillColor: c.raised,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          onChanged: (v) {
                            log.note = v;
                            store.saveLog();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('This week', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _MiniStat(label: 'Done', value: '${week.fold<int>(0, (a, b) => a + b)}')),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniStat(label: 'On time', value: rate == null ? '–' : '${(rate * 100).round()}%')),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniStat(label: 'Focus', value: fmtMinutes(store.focusThisWeek))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle('Tasks completed'),
                        SizedBox(
                          height: 140,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < 7; i++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('${week[i]}',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.muted, height: 1)),
                                        const SizedBox(height: 4),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          height: 4 + week[i] / maxV * 92,
                                          decoration: BoxDecoration(
                                            color: i == 6 ? c.orange : c.orangeSoft,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          weekdaysShort[DateTime(now.year, now.month, now.day - 6 + i).weekday - 1][0],
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.muted, height: 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (byList.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionTitle('Where your time went', note: '30 days'),
                          for (final l in store.lists)
                            if ((byList[l.id] ?? 0) > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(l.name, style: TextStyle(fontWeight: FontWeight.w600, color: c.ink))),
                                      Text('${byList[l.id]}', style: TextStyle(fontSize: 12.5, color: c.muted)),
                                    ]),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (byList[l.id] ?? 0) / maxList,
                                        minHeight: 8,
                                        color: Color(l.color),
                                        backgroundColor: c.raised,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  AppCard(
                    color: c.orangeSoft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, color: c.orangeText),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            best == null
                                ? 'Finish a few tasks and the app will show when you work best.'
                                : 'You finish the most tasks around ${_hour(best)}. Put your hardest task there.',
                            style: TextStyle(color: c.peachText, fontWeight: FontWeight.w600, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.accent = false});

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.invRaised, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: accent ? c.orange : c.onInv, height: 1.1)),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: c.invMuted, height: 1.2)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.muted, height: 1.2)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink, height: 1.1)),
          ),
        ],
      ),
    );
  }
}
