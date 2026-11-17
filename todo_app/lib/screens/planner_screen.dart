import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../utils/prayer_times.dart';
import '../widgets/common.dart';
import 'quick_add_sheet.dart';
import 'task_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _selected = dayStart(DateTime.now());
  }

  DateTime get _weekStart => DateTime(_selected.year, _selected.month, _selected.day - (_selected.weekday - 1));

  double _y(DateTime t) {
    final mins = (t.hour - _startHour) * 60 + t.minute;
    return (mins / 60 * _hourH).clamp(0.0, (_endHour - _startHour) * _hourH);
  }

  Future<void> _planUntimed(List<Task> untimed) async {
    final id = await pickOption<String>(
      context,
      'Give a task a time',
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

        // Lanes for overlapping blocks.
        final laneEnds = <DateTime>[];
        final lanes = <Task, int>{};
        for (final t in timed) {
          final start = t.due!;
          final end = start.add(Duration(minutes: t.durationMinutes));
          var lane = laneEnds.indexWhere((e) => !e.isAfter(start));
          if (lane == -1) {
            lane = laneEnds.length;
            laneEnds.add(end);
          } else {
            laneEnds[lane] = end;
          }
          lanes[t] = lane;
        }
        final laneCount = math.max(1, math.min(3, laneEnds.length));

        // Free slots of an hour or more between 8 AM and 10 PM.
        final free = <(DateTime, int)>[];
        var cursor = DateTime(_selected.year, _selected.month, _selected.day, 8);
        if (isToday && now.isAfter(cursor)) {
          cursor = DateTime(now.year, now.month, now.day, now.hour + 1);
        }
        final dayEnd = DateTime(_selected.year, _selected.month, _selected.day, 22);
        final busy = [
          for (final t in timed.where((t) => !t.done)) (t.due!, t.due!.add(Duration(minutes: t.durationMinutes))),
        ];
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
                  child: Text('${monthsLong[_selected.month - 1]} ${_selected.year}',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: c.ink, height: 1.2)),
                ),
                if (!isToday)
                  TextButton(
                    onPressed: () => setState(() => _selected = dayStart(now)),
                    style: TextButton.styleFrom(foregroundColor: c.orangeText),
                    child: const Text('Today'),
                  ),
                IconButton(
                  tooltip: 'Previous week',
                  onPressed: () => setState(() => _selected = DateTime(_selected.year, _selected.month, _selected.day - 7)),
                  icon: Icon(Icons.chevron_left_rounded, color: c.ink),
                ),
                IconButton(
                  tooltip: 'Next week',
                  onPressed: () => setState(() => _selected = DateTime(_selected.year, _selected.month, _selected.day + 7)),
                  icon: Icon(Icons.chevron_right_rounded, color: c.ink),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final d in week) ...[
                  Expanded(child: _DayChip(day: d, selected: sameDay(d, _selected), onTap: () => setState(() => _selected = d))),
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
                          Text(untimed.length == 1 ? '1 task without a time' : '${untimed.length} tasks without a time',
                              style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                          Text('Tap to give them a slot', style: TextStyle(fontSize: 12.5, color: c.muted)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.muted),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppCard(
              padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
              child: LayoutBuilder(
                builder: (context, box) {
                  final width = box.maxWidth;
                  final colW = (width - _labelW - 6) / laneCount;
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
                        for (final t in timed)
                          Positioned(
                            left: _labelW + (lanes[t] ?? 0).clamp(0, laneCount - 1) * colW,
                            width: colW - 4,
                            top: _y(t.due!) + 1,
                            height: math.max(38.0, t.durationMinutes / 60 * _hourH - 3),
                            child: _Block(task: t),
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
    final bg = selected ? c.inv : c.card;
    final fg = selected ? c.onInv : c.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: '${fmtLongDate(day)}, $count tasks',
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
                Text(weekdaysShort[day.weekday - 1],
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.75), height: 1)),
                const SizedBox(height: 6),
                Text('${day.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg, height: 1)),
                const SizedBox(height: 8),
                Container(
                  width: 22,
                  height: 4,
                  decoration: BoxDecoration(color: selected ? c.invLine : c.line, borderRadius: BorderRadius.circular(2)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: load,
                    child: Container(
                      decoration: BoxDecoration(
                        color: load > 0.66 ? c.orange : (selected ? c.onInv : c.ink),
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
          child: Text('Free ${fmtMinutes(minutes)} · tap to plan',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.muted, height: 1.2)),
        ),
      ),
    );
  }
}
