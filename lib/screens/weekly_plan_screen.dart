import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';

/// Sunday-evening planning: three goals for the week, and give undated tasks a day.
class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  final store = AppStore.instance;
  late final DateTime _weekStart;
  late final List<TextEditingController> _goals;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    // In the last two days of the week, plan the coming week; otherwise the current one.
    final cur = store.startOfWeek(n);
    final dayIndex = DateTime(n.year, n.month, n.day).difference(cur).inDays;
    _weekStart = dayIndex >= 5 ? DateTime(cur.year, cur.month, cur.day + 7) : cur;
    final g = store.goalsFor(_weekStart);
    _goals = List.generate(3, (i) => TextEditingController(text: i < g.length ? g[i] : ''));
  }

  @override
  void dispose() {
    for (final g in _goals) {
      g.dispose();
    }
    super.dispose();
  }

  void _saveGoals() => store.setGoals(_weekStart, _goals.map((g) => g.text).toList());

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final days = [for (var i = 0; i < 7; i++) DateTime(_weekStart.year, _weekStart.month, _weekStart.day + i)];
        final someday = store.anytime;
        final end = days.last;
        return Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            backgroundColor: c.bg,
            surfaceTintColor: Colors.transparent,
            title: Text(tr('Plan your week'), style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              Text('${_weekStart.day} ${monthShort(_weekStart.month)} – ${end.day} ${monthShort(end.month)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.muted)),
              const SizedBox(height: 14),
              AppCard(
                color: c.inv,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(tr('Three goals for this week'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.onInv)),
                    const SizedBox(height: 4),
                    Text(tr('What would make this week a good one?'), style: TextStyle(fontSize: 13, color: c.invMuted)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('${i + 1}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.orange, height: 1)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _goals[i],
                                cursorColor: c.orange,
                                textCapitalization: TextCapitalization.sentences,
                                style: TextStyle(color: c.onInv, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: tr('Goal {n}', {'n': i + 1}),
                                  hintStyle: TextStyle(color: c.invMuted),
                                  filled: true,
                                  fillColor: c.invRaised,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                onChanged: (_) => _saveGoals(),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionTitle(tr('Your week')),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final d in days)
                      Builder(builder: (context) {
                        final count = store.tasks.where((t) => !t.done && t.due != null && sameDay(t.due!, d)).length;
                        final busy = (count / 6).clamp(0.0, 1.0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 92,
                                child: Text('${dayShort(d.weekday)} ${d.day}',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: c.ink, height: 1.2)),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: busy,
                                    minHeight: 8,
                                    color: busy > 0.66 ? c.orange : c.ink,
                                    backgroundColor: c.raised,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 64,
                                child: Text(trn(count, '1 task', '{n} tasks'),
                                    textAlign: TextAlign.end, style: TextStyle(fontSize: 12.5, color: c.muted)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionTitle(tr('Give these a day'), note: someday.isEmpty ? null : '${someday.length}'),
              if (someday.isEmpty)
                Text(tr('Every task already has a day.'), style: TextStyle(color: c.muted))
              else
                for (final t in someday) _DayPickRow(task: t, days: days),
            ],
          ),
        );
      },
    );
  }
}

class _DayPickRow extends StatelessWidget {
  const _DayPickRow({required this.task, required this.days});

  final Task task;
  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = AppStore.instance;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        border: true,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(task.title, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink, height: 1.3)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final d in days) ...[
                    ChoicePill(
                      label: dayShort(d.weekday),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        store.moveToDay(task, d);
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
