import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../utils/prayer_times.dart';
import '../widgets/common.dart';
import '../widgets/day_arc.dart';
import '../widgets/task_tile.dart';
import '../widgets/user_avatar.dart';
import 'me_screen.dart';
import 'quick_add_sheet.dart';
import 'search_screen.dart';
import 'task_detail_screen.dart';
import 'weekly_plan_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _Group {
  _Group(this.name, this.range, this.items);
  final String name;
  final String range;
  final List<Task> items;
}

class _TodayScreenState extends State<TodayScreen> {
  final store = AppStore.instance;
  Timer? _clock;
  bool _showDone = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  String _greeting() {
    final h = DateTime.now().hour;
    final g = h < 12 ? tr('Good morning') : (h < 17 ? tr('Good afternoon') : tr('Good evening'));
    return store.userName.isEmpty ? g : '$g, ${store.userName}';
  }

  String _left(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return tr('{m}m left', {'m': m});
    return tr('{h}h {m}m left', {'h': m ~/ 60, 'm': m % 60});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final now = DateTime.now();
        final pt = store.prayersFor(now);
        final ramzan = store.isRamzan;
        final hijri = store.hijriFor(now);
        final weekBegin = store.startOfWeek(now);
        final dayOfWeek = DateTime(now.year, now.month, now.day).difference(weekBegin).inDays;
        final planWeek = dayOfWeek >= 5 ? DateTime(weekBegin.year, weekBegin.month, weekBegin.day + 7) : weekBegin;
        final showWeekly = (dayOfWeek >= 5 || dayOfWeek == 0) && store.goalsFor(planWeek).isEmpty;
        final overdue = store.overdue;
        final today = store.dueToday;
        final anytime = store.anytime;
        final doneToday = store.completedToday;
        final stale = store.stale;
        final top = store.topThree;
        final total = overdue.length + today.length + doneToday.length;
        final pct = total == 0 ? 0.0 : doneToday.length / total;

        // ----- Day arc -----
        late final List<ArcMarker> markers;
        late final double sun;
        late final String arcLine;
        if (pt != null) {
          final start = pt[Prayer.fajr];
          final end = pt[Prayer.isha];
          final span = end.difference(start).inMinutes.toDouble();
          double f(DateTime t) => (t.difference(start).inMinutes / span).clamp(0.0, 1.0);
          String label(Prayer p) => ramzan && p == Prayer.fajr
              ? tr('Sehri')
              : (ramzan && p == Prayer.maghrib ? tr('Iftar') : p.label);
          markers = [for (final p in Prayer.values) ArcMarker(f(pt[p]), label(p), passed: !pt[p].isAfter(now))];
          sun = f(now);
          final next = pt.nextAfter(now);
          if (ramzan && now.isBefore(pt[Prayer.maghrib]) && now.isAfter(pt[Prayer.fajr])) {
            arcLine = tr('Iftar at {time} · {left}', {'time': fmtTime(pt[Prayer.maghrib]), 'left': _left(pt[Prayer.maghrib].difference(now))});
          } else if (next != null) {
            final before = today.where((t) => t.hasTime && t.due!.isBefore(pt[next])).length;
            arcLine = trn(before, '1 task before {p} · {left}', '{n} tasks before {p} · {left}',
                {'p': next.label, 'left': _left(pt[next].difference(now))});
          } else {
            arcLine = today.isEmpty ? tr('Day is done. Plan tomorrow.') : trn(today.length, '1 left tonight', '{n} left tonight');
          }
        } else {
          final start = DateTime(now.year, now.month, now.day, 6);
          double f(DateTime t) => (t.difference(start).inMinutes / (16 * 60)).clamp(0.0, 1.0);
          markers = [
            ArcMarker(0, tr('6 AM')),
            ArcMarker(0.375, tr('12 PM')),
            ArcMarker(0.75, tr('6 PM')),
            ArcMarker(1, tr('10 PM')),
          ];
          sun = f(now);
          arcLine = today.isEmpty ? tr('Nothing left for today') : '${today.length} tasks left today';
        }

        // ----- Groups -----
        final timed = today.where((t) => t.hasTime).toList();
        final untimed = today.where((t) => !t.hasTime).toList();
        final groups = <_Group>[];
        if (pt != null) {
          final z = pt[Prayer.dhuhr], a = pt[Prayer.asr], m = pt[Prayer.maghrib];
          groups.add(_Group(tr('Before Zuhr'), 'until ${fmtTime(z)}', timed.where((t) => t.due!.isBefore(z)).toList()));
          groups.add(_Group(tr('Zuhr to Asr'), '${fmtTime(z)} – ${fmtTime(a)}',
              timed.where((t) => !t.due!.isBefore(z) && t.due!.isBefore(a)).toList()));
          groups.add(_Group(tr('Asr to Maghrib'), '${fmtTime(a)} – ${fmtTime(m)}',
              timed.where((t) => !t.due!.isBefore(a) && t.due!.isBefore(m)).toList()));
          groups.add(_Group(tr('After Maghrib'), 'from ${fmtTime(m)}', timed.where((t) => !t.due!.isBefore(m)).toList()));
        } else {
          groups.add(_Group(tr('Morning'), 'until 12 PM', timed.where((t) => t.due!.hour < 12).toList()));
          groups.add(_Group(tr('Afternoon'), '12 – 5 PM', timed.where((t) => t.due!.hour >= 12 && t.due!.hour < 17).toList()));
          groups.add(_Group(tr('Evening'), 'from 5 PM', timed.where((t) => t.due!.hour >= 17).toList()));
        }
        if (untimed.isNotEmpty) groups.add(_Group(tr('Anytime today'), 'no set time', untimed));

        final nothing = overdue.isEmpty && today.isEmpty && anytime.isEmpty && doneToday.isEmpty;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // ----- Header -----
            Container(
              decoration: BoxDecoration(
                color: c.peach,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${fmtLongDate(now)} · ${hijri.day} ${hijriMonthName(hijri.month)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.peachText, height: 1.2)),
                            const SizedBox(height: 4),
                            Text(_greeting(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: c.onPeach, height: 1.2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _HeaderButton(
                        tooltip: tr('Search'),
                        color: c.glass,
                        child: Icon(Icons.search_rounded, color: c.onPeach),
                        onTap: () => _push(const SearchScreen()),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: tr('Profile and settings'),
                        child: Semantics(
                          button: true,
                          label: tr('Profile and settings'),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _push(const MeScreen()),
                            child: const UserAvatar(size: 46, showGear: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  DayArc(
                    markers: markers,
                    sun: sun,
                    center: Column(
                      children: [
                        Text(fmtTime(now).replaceAll(' AM', '').replaceAll(' PM', ''),
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1, color: c.onPeach, height: 1.1)),
                        const SizedBox(height: 4),
                        Text(arcLine,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.peachText, height: 1.2)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: c.glass, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: pct, minHeight: 8, color: c.orange, backgroundColor: c.track),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          total == 0
                              ? tr('Nothing due today')
                              : (pct >= 1 ? tr('All done today') : '${doneToday.length} of $total done'),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.onPeach, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (top.isNotEmpty) ...[
                    _TopThree(tasks: top),
                    const SizedBox(height: 18),
                  ],
                  if (showWeekly) ...[
                    AppCard(
                      color: c.inv,
                      onTap: () => _push(const WeeklyPlanScreen()),
                      child: Row(
                        children: [
                          Icon(Icons.event_note_rounded, color: c.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr('Plan your week'),
                                    style: TextStyle(fontWeight: FontWeight.w800, color: c.onInv, height: 1.25)),
                                const SizedBox(height: 2),
                                Text(tr('Set 3 goals and give tasks a day. Takes 5 minutes.'),
                                    style: TextStyle(fontSize: 13, color: c.invMuted, height: 1.3)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: c.onInv),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (stale.isNotEmpty) ...[
                    AppCard(
                      color: c.orangeSoft,
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        showDragHandle: true,
                        backgroundColor: c.card,
                        builder: (_) => const StaleReviewSheet(),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_bottom_rounded, color: c.orangeText),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trn(stale.length, '1 task is gathering dust', '{n} tasks are gathering dust'),
                                  style: TextStyle(fontWeight: FontWeight.w800, color: c.ink, height: 1.25),
                                ),
                                const SizedBox(height: 2),
                                Text(tr('Do it, move it, or let it go.'),
                                    style: TextStyle(fontSize: 13, color: c.orangeText, height: 1.3)),
                              ],
                            ),
                          ),
                          Text(tr('Review'), style: TextStyle(fontWeight: FontWeight.w800, color: c.orangeText)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (nothing)
                    EmptyState(
                      icon: Icons.wb_sunny_outlined,
                      title: tr('A clear day'),
                      message: tr('Tap + and type naturally.\nTry: kal shaam 6 baje gym #Health'),
                      action: BigButton(
                        label: tr('Add a task'),
                        icon: Icons.add_rounded,
                        onPressed: () => showQuickAdd(context, initialDate: DateTime.now()),
                      ),
                    ),
                  if (overdue.isNotEmpty) ...[
                    SectionTitle(tr('Overdue'), note: '${overdue.length}', color: c.orangeText),
                    for (final t in overdue) TaskTile(task: t),
                    const SizedBox(height: 12),
                  ],
                  for (final g in groups)
                    if (g.items.isNotEmpty) ...[
                      SectionTitle(g.name, note: g.range),
                      for (final t in g.items) TaskTile(task: t, showDate: false),
                      const SizedBox(height: 12),
                    ],
                  if (anytime.isNotEmpty) ...[
                    SectionTitle(tr('Someday'), note: tr('no date')),
                    for (final t in anytime) TaskTile(task: t),
                    const SizedBox(height: 12),
                  ],
                  if (doneToday.isNotEmpty) ...[
                    SectionTitle(
                      'Completed today',
                      trailing: TextButton(
                        onPressed: () => setState(() => _showDone = !_showDone),
                        style: TextButton.styleFrom(foregroundColor: c.orangeText),
                        child: Text(_showDone ? tr('Hide') : 'Show ${doneToday.length}'),
                      ),
                    ),
                    if (_showDone) for (final t in doneToday) TaskTile(task: t),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.child, required this.color, required this.onTap, required this.tooltip});

  final Widget child;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(width: 46, height: 46, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _TopThree extends StatelessWidget {
  const _TopThree({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = AppStore.instance;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
      decoration: BoxDecoration(color: c.inv, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(tr('Today’s top 3'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.onInv, height: 1.2)),
                ),
                Text(tr('Do these first'),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.invMuted, height: 1.2)),
              ],
            ),
          ),
          for (var i = 0; i < tasks.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: tasks[i].id))),
              child: Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.invLine))),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text('${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.orange, height: 1)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tasks[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.onInv, height: 1.3)),
                          const SizedBox(height: 2),
                          Text(
                            '${tasks[i].due == null ? tr('No date') : dueLabel(tasks[i])} · ${store.listById(tasks[i].listId).name}',
                            style: TextStyle(fontSize: 12.5, color: c.invMuted, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                    CheckBoxSquare(
                      done: tasks[i].done,
                      fill: c.orange,
                      check: c.onOrange,
                      ringColor: c.invMuted,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        store.toggleDone(tasks[i]);
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Quick decisions for old tasks.
class StaleReviewSheet extends StatelessWidget {
  const StaleReviewSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final stale = store.stale;
        final now = DateTime.now();
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Text(tr('Clean up old tasks'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 4),
                Text(tr('These have waited a while. Decide once and move on.'), style: TextStyle(color: c.muted)),
                const SizedBox(height: 16),
                if (stale.isEmpty)
                  EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: tr('All clean'),
                    message: tr('Nothing old is waiting.'),
                    action: BigButton(label: tr('Done'), onPressed: () => Navigator.pop(context)),
                  ),
                for (final t in stale)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      color: c.raised,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                          const SizedBox(height: 2),
                          Text(t.due == null ? tr('No date, untouched for a week') : 'Was due ${dueLabel(t)}',
                              style: TextStyle(fontSize: 13, color: c.muted)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoicePill(label: tr('Today'), selected: true, onTap: () => store.moveToDay(t, now)),
                              ChoicePill(
                                  label: tr('Tomorrow'),
                                  onTap: () => store.moveToDay(t, DateTime(now.year, now.month, now.day + 1))),
                              ChoicePill(label: tr('Someday'), onTap: () => store.moveToDay(t, null)),
                              ChoicePill(label: tr('Drop'), soft: true, onTap: () => store.deleteTask(t)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
