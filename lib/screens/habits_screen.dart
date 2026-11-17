import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import '../l10n/strings.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  static const _ideas = <(String, int)>[
    ('Namaz on time', 1),
    ('Drink water', 8),
    ('Read 10 pages', 1),
    ('Walk 20 minutes', 1),
    ('Quran, one page', 1),
    ('No phone after Isha', 1),
  ];

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final today = DateTime.now();
        final habits = store.habits;
        final done = habits.where((h) => store.habitDone(h, today)).length;
        final pct = habits.isEmpty ? 0.0 : done / habits.length;

        return ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 14, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tr('Habits'),
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: c.ink, height: 1.2)),
                ),
                BigButton(
                  label: tr('New habit'),
                  icon: Icons.add_rounded,
                  height: 44,
                  onPressed: () => showHabitEditor(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (habits.isEmpty) ...[
              EmptyState(
                icon: Icons.track_changes_rounded,
                title: tr('Build small daily wins'),
                message: tr('Pick one to start. You can add your own any time.'),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < _ideas.length; i++)
                    ChoicePill(
                      label: tr(_ideas[i].$1),
                      soft: true,
                      onTap: () => store.addHabit(tr(_ideas[i].$1), listPalette[i % listPalette.length], _ideas[i].$2),
                    ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: c.inv, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: pct,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            color: c.orange,
                            backgroundColor: c.invLine,
                          ),
                          Center(
                            child: Text('$done/${habits.length}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.onInv, height: 1)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            done == habits.length ? tr('All done today') : tr('{n} left for today', {'n': habits.length - done}),
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.onInv, height: 1.25),
                          ),
                          const SizedBox(height: 4),
                          Text(tr('Small daily wins add up. Long-press a habit to edit it.'),
                              style: TextStyle(fontSize: 13, color: c.invMuted, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final h in habits) _HabitRow(habit: h),
            ],
          ],
        );
      },
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = AppStore.instance;
    final today = DateTime.now();
    final color = Color(habit.color);
    final doneToday = store.habitDone(habit, today);
    final streak = store.habitStreak(habit);
    final count = habit.log[dayKey(today)] ?? 0;
    final days = store.weekOf(today);
    final todayStart = DateTime(today.year, today.month, today.day);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: () => showHabitEditor(context, habit: habit),
          onTap: () => showHabitEditor(context, habit: habit),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.tintOf(color), borderRadius: BorderRadius.circular(14)),
                  child: Text(habit.name.isEmpty ? '?' : habit.name[0].toUpperCase(),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.textOf(color), height: 1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(habit.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.ink, height: 1.25)),
                          ),
                          if (streak > 0)
                            Text(tr('{n}-day streak', {'n': streak}),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.orangeText, height: 1.2)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final d in days) ...[
                            Builder(builder: (context) {
                              final isToday = sameDay(d, todayStart);
                              final future = d.isAfter(todayStart);
                              final ok = store.habitDone(habit, d);
                              return Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: ok ? c.orange : (future ? Colors.transparent : c.raised),
                                  borderRadius: BorderRadius.circular(7),
                                  border: isToday
                                      ? Border.all(color: c.ink, width: 1.5)
                                      : (future ? Border.all(color: c.line, width: 1.5) : null),
                                ),
                                child: Text(
                                  dayInitial(d.weekday),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    color: ok ? c.onOrange : (future ? c.muted.withValues(alpha: 0.6) : c.muted),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(width: 4),
                          ],
                          if (habit.isCount) ...[
                            const SizedBox(width: 4),
                            Text('$count/${habit.target}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.muted, height: 1)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: habit.isCount ? tr('Add one') : (doneToday ? tr('Mark not done') : tr('Mark done')),
                  child: Material(
                    color: doneToday ? c.done : c.raised,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        store.tapHabit(habit, today);
                      },
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: habit.isCount && !doneToday
                              ? Text('+1', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.ink, height: 1))
                              : Icon(Icons.check_rounded, color: doneToday ? c.onDone : c.ink),
                        ),
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

Future<void> showHabitEditor(BuildContext context, {Habit? habit}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.c.card,
    builder: (_) => _HabitEditor(habit: habit),
  );
}

class _HabitEditor extends StatefulWidget {
  const _HabitEditor({this.habit});

  final Habit? habit;

  @override
  State<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<_HabitEditor> {
  final store = AppStore.instance;
  late final TextEditingController _name;
  late int _color;
  late int _target;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.habit?.name ?? '');
    _color = widget.habit?.color ?? listPalette.first;
    _target = widget.habit?.target ?? 1;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    final h = widget.habit;
    if (h == null) {
      store.addHabit(n, _color, _target);
    } else {
      h.name = n;
      h.color = _color;
      h.target = _target;
      store.updateHabit(h);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.habit == null ? tr('New habit') : tr('Edit habit'),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              autofocus: widget.habit == null,
              cursorColor: c.orange,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
              decoration: InputDecoration(
                hintText: tr('e.g. Read 10 pages'),
                hintStyle: TextStyle(color: c.muted),
                filled: true,
                fillColor: c.raised,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            Text(tr('How often each day'), style: TextStyle(fontWeight: FontWeight.w700, color: c.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoicePill(label: tr('Once'), selected: _target == 1, onTap: () => setState(() => _target = 1)),
                const SizedBox(width: 8),
                ChoicePill(label: tr('Count'), selected: _target > 1, onTap: () => setState(() => _target = _target > 1 ? _target : 8)),
                const Spacer(),
                if (_target > 1) ...[
                  IconButton(
                    tooltip: tr('Less'),
                    onPressed: _target > 2 ? () => setState(() => _target--) : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Text('$_target', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c.ink)),
                  IconButton(
                    tooltip: tr('More'),
                    onPressed: _target < 50 ? () => setState(() => _target++) : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Text(tr('Color'), style: TextStyle(fontWeight: FontWeight.w700, color: c.muted)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                for (final col in listPalette)
                  Semantics(
                    button: true,
                    selected: col == _color,
                    child: InkResponse(
                      onTap: () => setState(() => _color = col),
                      radius: 24,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Color(col),
                          shape: BoxShape.circle,
                          border: Border.all(color: col == _color ? c.orange : Colors.transparent, width: 3),
                        ),
                        child: col == _color ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (widget.habit != null) ...[
                  Expanded(
                    child: BigButton(
                      label: tr('Delete'),
                      primary: false,
                      onPressed: () {
                        store.deleteHabit(widget.habit!);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: BigButton(label: tr('Save'), onPressed: _name.text.trim().isEmpty ? null : _save)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
