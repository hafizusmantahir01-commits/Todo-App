import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../utils/prayer_times.dart';
import '../widgets/common.dart';
import '../services/native.dart';
import 'quick_add_sheet.dart';
import 'task_detail_screen.dart';
import '../l10n/strings.dart';

/// Week strip plus a time-block view of one day, with prayer times and free slots.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final store = AppStore.instance;
  late DateTime _selected;

  static const _startHour = 6;
  static const _endHour = 24;
  static const _hourH = 60.0;
  static const _labelW = 54.0;

  final Map<String, List<PhoneEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selected = dayStart(DateTime.now());
    _loadEvents();
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  bool _calendarWasOn = false;

  void _onStore() {
    if (store.calendarOn && !_calendarWasOn) _loadEvents();
    _calendarWasOn = store.calendarOn;
  }

  void _select(DateTime d) {
    setState(() => _selected = dayStart(d));
    _loadEvents();
  }

  Future<void> _showMore(List<Object> items) async {
    final id = await pickOption<String>(
      context,
      tr('At the same time'),
      [
        for (final o in items)
          if (o is Task)
            OptionItem(o.id, o.title, subtitle: fmtTime(o.due!), icon: Icons.circle, color: Color(store.listById(o.listId).color))
          else if (o is PhoneEvent)
            OptionItem('', o.title, subtitle: '${fmtTime(o.start)} · ${tr('From your phone calendar')}', icon: Icons.event_rounded),
      ],
      null,
    );
    if (id == null || id.isEmpty || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: id)));
  }

  /// Loads the whole week around the selected day from the phone's calendar.
  Future<void> _loadEvents() async {
    _calendarWasOn = store.calendarOn;
    if (!store.calendarOn) return;
    final start = _weekStart;
    final end = DateTime(start.year, start.month, start.day + 7);
    final list = await Native.calendarEvents(start, end);
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < 7; i++) {
        final d = DateTime(start.year, start.month, start.day + i);
        _events[dayKey(d)] = list.where((e) => sameDay(e.start, d) || (e.start.isBefore(d) && e.end.isAfter(d))).toList();
      }
    });
  }

  DateTime get _weekStart => store.startOfWeek(_selected);

  double _y(DateTime t) {
    final mins = (t.hour - _startHour) * 60 + t.minute;
    return (mins / 60 * _hourH).clamp(0.0, (_endHour - _startHour) * _hourH);
  }

  Future<void> _planUntimed(List<Task> untimed) async {
    final id = await pickOption<String>(
      context,
      tr('Give a task a time'),
      [for (final t in untimed) OptionItem(t.id, t.title, icon: Icons.circle, color: Color(store.listById(t.listId).color))],
      null,
    );
    if (id == null || !mounted) return;
    final t = store.taskById(id);
    if (t == null) return;
    final tm = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (tm == null) return;
    final d = t.due ?? _selected;
    t.due = DateTime(d.year, d.month, d.day, tm.hour, tm.minute);
    if (t.reminderMinutes < 0 && store.remindersOn) t.reminderMinutes = store.defaultReminder;
    t.hasTime = true;
    store.updateTask(t);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final now = DateTime.now();
        final week = [for (var i = 0; i < 7; i++) DateTime(_weekStart.year, _weekStart.month, _weekStart.day + i)];
        final dayTasks = store.tasksOn(_selected);
        final timed = dayTasks.where((t) => t.hasTime).toList()..sort((a, b) => a.due!.compareTo(b.due!));
        final untimed = dayTasks.where((t) => !t.hasTime && !t.done).toList();
        final pt = store.prayersFor(_selected);
        final isToday = sameDay(_selected, now);

        // Phone calendar events for this day (when turned on).
        final events = store.calendarOn ? (_events[dayKey(_selected)] ?? const <PhoneEvent>[]) : const <PhoneEvent>[];
        final timedEvents = events.where((e) => !e.allDay).toList();
        final allDay = events.where((e) => e.allDay).toList();

        // Side-by-side layout for blocks that overlap (tasks and events together).
        // A block is at least 40 minutes tall on screen, so that is used for overlap too.
        DateTime visualEnd(DateTime start, DateTime end) {
          final minEnd = start.add(const Duration(minutes: 40));
          return end.isAfter(minEnd) ? end : minEnd;
        }
        final entries = <(DateTime, DateTime, Object)>[
          for (final t in timed) (t.due!, visualEnd(t.due!, t.due!.add(Duration(minutes: t.durationMinutes))), t),
          for (final e in timedEvents) (e.start, visualEnd(e.start, e.end), e),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        final laneOf = <Object, int>{};
        final colsOf = <Object, int>{};
        final hidden = <Object>{};
        final more = <(DateTime, List<Object>)>[];
        var i = 0;
        while (i < entries.length) {
          // Collect one group of blocks that touch each other in time.
          var groupEnd = entries[i].$2;
          final group = [entries[i]];
          var j = i + 1;
          while (j < entries.length && entries[j].$1.isBefore(groupEnd)) {
            group.add(entries[j]);
            if (entries[j].$2.isAfter(groupEnd)) groupEnd = entries[j].$2;
            j++;
          }
          final laneEnds = <DateTime>[];
          for (final en in group) {
            var lane = laneEnds.indexWhere((e) => !e.isAfter(en.$1));
            if (lane == -1) {
              lane = laneEnds.length;
              laneEnds.add(en.$2);
            } else {
              laneEnds[lane] = en.$2;
            }
            laneOf[en.$3] = lane;
          }
          // At most three columns; anything beyond goes behind a "+N more" button.
          final cols = math.min(3, laneEnds.length);
          final extra = <Object>[];
          for (final en in group) {
            colsOf[en.$3] = cols;
            if (laneEnds.length > 3 && laneOf[en.$3]! >= 2) {
              hidden.add(en.$3);
              extra.add(en.$3);
            }
          }
          if (extra.isNotEmpty) more.add((group.first.$1, extra));
          i = j;
        }

        // Free slots of an hour or more between 8 AM and 10 PM.
        final free = <(DateTime, int)>[];
        var cursor = DateTime(_selected.year, _selected.month, _selected.day, 8);
        if (isToday && now.isAfter(cursor)) {
          cursor = DateTime(now.year, now.month, now.day, now.hour + 1);
        }
        final dayEnd = DateTime(_selected.year, _selected.month, _selected.day, 22);
        final busy = [
          for (final t in timed.where((t) => !t.done)) (t.due!, t.due!.add(Duration(minutes: t.durationMinutes))),
          for (final e in timedEvents) (e.start, e.end),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        for (final b in busy) {
          if (b.$1.difference(cursor).inMinutes >= 60) free.add((cursor, b.$1.difference(cursor).inMinutes));
          if (b.$2.isAfter(cursor)) cursor = b.$2;
        }
        if (dayEnd.difference(cursor).inMinutes >= 60) free.add((cursor, dayEnd.difference(cursor).inMinutes));

        return ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 14, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${monthName(_selected.month)} ${_selected.year}',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: c.ink, height: 1.2)),
                ),
                if (!isToday)
                  TextButton(
                    onPressed: () => _select(dayStart(now)),
                    style: TextButton.styleFrom(foregroundColor: c.orangeText),
                    child: Text(tr('Today')),
                  ),
                IconButton(
                  tooltip: tr('Previous week'),
                  onPressed: () => _select(DateTime(_selected.year, _selected.month, _selected.day - 7)),
                  icon: Icon(Icons.chevron_left_rounded, color: c.ink),
                ),
                IconButton(
                  tooltip: tr('Next week'),
                  onPressed: () => _select(DateTime(_selected.year, _selected.month, _selected.day + 7)),
                  icon: Icon(Icons.chevron_right_rounded, color: c.ink),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final d in week) ...[
                  Expanded(child: _DayChip(day: d, selected: sameDay(d, _selected), onTap: () => _select(d))),
                  if (d != week.last) const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 14),
            if (untimed.isNotEmpty) ...[
              AppCard(
                onTap: () => _planUntimed(untimed),
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.orangeSoft, borderRadius: BorderRadius.circular(12)),
                      child: Text('${untimed.length}',
                          style: TextStyle(fontWeight: FontWeight.w800, color: c.orangeText, fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trn(untimed.length, '1 task without a time', '{n} tasks without a time'),
                              style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                          Text(tr('Tap to give them a slot'), style: TextStyle(fontSize: 12.5, color: c.muted)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.muted),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (allDay.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in allDay)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(e.color), width: 1.5),
                      ),
                      child: IconText(icon: Icons.event_rounded, text: '${tr('All day')}: ${e.title}', color: c.ink),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            AppCard(
              padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
              child: LayoutBuilder(
                builder: (context, box) {
                  final width = box.maxWidth;
                  double colW(Object o) => (width - _labelW - 6) / (colsOf[o] ?? 1);
                  final height = (_endHour - _startHour) * _hourH;
                  return SizedBox(
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var h = _startHour; h < _endHour; h++)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: (h - _startHour) * _hourH,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: _labelW - 8,
                                  child: Text(
                                    '${h % 12 == 0 ? 12 : h % 12} ${h < 12 ? 'AM' : 'PM'}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.muted, height: 1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Container(height: 1, color: c.line)),
                              ],
                            ),
                          ),
                        if (pt != null)
                          for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha])
                            Positioned(
                              left: _labelW,
                              right: 0,
                              top: _y(pt[p]) - 8,
                              child: IgnorePointer(
                                child: Row(
                                  children: [
                                    Expanded(child: Container(height: 2, color: c.orange.withValues(alpha: 0.7))),
                                    const SizedBox(width: 6),
                                    Text('${p.label} ${fmtTime(pt[p])}',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.orangeText, height: 1)),
                                  ],
                                ),
                              ),
                            ),
                        for (final f in free)
                          Positioned(
                            left: _labelW,
                            right: 0,
                            top: _y(f.$1) + 4,
                            height: math.min(f.$2 / 60 * _hourH - 8, 52),
                            child: _FreeSlot(
                              minutes: f.$2,
                              onTap: () => showQuickAdd(
                                context,
                                initialDate: _selected,
                                initialTime: TimeOfDay(hour: f.$1.hour, minute: f.$1.minute),
                              ),
                            ),
                          ),
                        for (final e in timedEvents.where((e) => !hidden.contains(e)))
                          Positioned(
                            left: _labelW + (laneOf[e] ?? 0) * colW(e),
                            width: colW(e) - 4,
                            top: _y(e.start) + 1,
                            height: math.max(38.0, e.end.difference(e.start).inMinutes / 60 * _hourH - 3),
                            child: _EventBlock(event: e),
                          ),
                        for (final t in timed.where((t) => !hidden.contains(t)))
                          Positioned(
                            left: _labelW + (laneOf[t] ?? 0) * colW(t),
                            width: colW(t) - 4,
                            top: _y(t.due!) + 1,
                            height: math.max(38.0, t.durationMinutes / 60 * _hourH - 3),
                            child: _Block(task: t),
                          ),
                        for (final m in more)
                          Positioned(
                            left: _labelW + 2 * ((width - _labelW - 6) / 3),
                            width: (width - _labelW - 6) / 3 - 4,
                            top: _y(m.$1) + 1,
                            height: 38,
                            child: _MoreChip(count: m.$2.length, onTap: () => _showMore(m.$2)),
                          ),
                        if (isToday && now.hour >= _startHour)
                          Positioned(
                            left: _labelW - 6,
                            right: 0,
                            top: _y(now) - 5,
                            child: IgnorePointer(
                              child: Row(
                                children: [
                                  Container(width: 10, height: 10, decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle)),
                                  Expanded(child: Container(height: 2, color: c.ink)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.selected, required this.onTap});

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = AppStore.instance;
    final count = store.tasks.where((t) => !t.done && t.due != null && sameDay(t.due!, day)).length;
    final load = (count / 6).clamp(0.0, 1.0);
    final isToday = sameDay(day, DateTime.now());
    final bg = selected ? c.sel : c.card;
    final fg = selected ? c.onSel : c.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: '${fmtLongDate(day)}, ${trn(count, '1 task', '{n} tasks')}',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isToday && !selected ? c.orange : Colors.transparent, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 74,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dayShort(day.weekday),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.75), height: 1)),
                const SizedBox(height: 6),
                Text('${day.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg, height: 1)),
                const SizedBox(height: 8),
                Container(
                  width: 22,
                  height: 4,
                  decoration: BoxDecoration(color: selected ? c.onSel.withValues(alpha: 0.25) : c.line, borderRadius: BorderRadius.circular(2)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: load,
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? c.onSel : (load > 0.66 ? c.orange : c.ink),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final listColor = Color(AppStore.instance.listById(task.listId).color);
    final strong = !task.done && (task.pinned || task.priority == Priority.high);
    final bg = task.done ? c.raised : (strong ? c.orange : c.tintOf(listColor));
    final fg = task.done ? c.muted : (strong ? c.onOrange : c.textOf(listColor));
    final end = task.due!.add(Duration(minutes: task.durationMinutes));
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  height: 1.2,
                  decoration: task.done ? TextDecoration.lineThrough : null,
                ),
              ),
              if (task.durationMinutes >= 45)
                Text('${fmtTime(task.due!)} – ${fmtTime(end)}',
                    maxLines: 1, style: TextStyle(fontSize: 11.5, color: fg, fontWeight: FontWeight.w600, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreeSlot extends StatelessWidget {
  const _FreeSlot({required this.minutes, required this.onTap});

  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(tr('Free {time} · tap to plan', {'time': fmtMinutes(minutes)}),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.muted, height: 1.2)),
        ),
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({required this.event});

  final PhoneEvent event;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.raised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Color(event.color), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => toast(context, tr('From your phone calendar')),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.event_rounded, size: 15, color: Color(event.color)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.ink, height: 1.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.inv,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(tr('+{n} more', {'n': count}),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.onInv, height: 1)),
        ),
      ),
    );
  }
}
