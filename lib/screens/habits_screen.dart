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
                          Text(tr('Tap ✓ once each day. A fresh week starts every {day}.', {'day': dayName(store.weekStart)}),
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
                          if (habit.isCount)
                            Container(
                              margin: const EdgeInsetsDirectional.only(end: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(8)),
                              child: Text('$count/${habit.target}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.ink, height: 1.1)),
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
                                width: 21,
                                height: 21,
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
                            const SizedBox(width: 3),
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
                        if (doneToday) {
                          // Already done today: ask what to do instead of silently resetting.
                          _doneOptions(context, habit, today);
                          return;
                        }
                        store.tapHabit(habit, today);
                        if (store.habitDone(habit, today)) {
                          toast(context, tr('Well done! “{name}” is done for today.', {'name': habit.name}));
                        }
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

/// Shown when a finished habit is tapped again: keep it, do it again today, or delete it.
Future<void> _doneOptions(BuildContext context, Habit habit, DateTime day) async {
  final store = AppStore.instance;
  final c = context.c;
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: c.card,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('“{name}” is done for today', {'name': habit.name}),
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.ink, height: 1.3)),
            const SizedBox(height: 6),
            Text(tr('What would you like to do?'), style: TextStyle(fontSize: 14, color: c.muted)),
            const SizedBox(height: 14),
            _OptionTile(
              icon: Icons.check_circle_outline_rounded,
              title: tr('Keep it'),
              subtitle: tr('Stays done today and comes back tomorrow'),
              onTap: () => Navigator.pop(ctx, 'keep'),
            ),
            _OptionTile(
              icon: Icons.replay_rounded,
              title: habit.isCount ? tr('Start again today') : tr('Mark as not done'),
              subtitle: habit.isCount
                  ? tr('Count goes back to 0/{n} for today', {'n': habit.target})
                  : tr('Undo today’s tick'),
              onTap: () => Navigator.pop(ctx, 'again'),
            ),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              title: tr('Delete habit'),
              subtitle: tr('Removes it and its history for good'),
              danger: true,
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'again':
      store.resetHabitDay(habit, day);
    case 'delete':
      final sure = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.card,
          title: Text(tr('Delete this habit?')),
          content: Text(tr('“{name}” and all its days will be removed. This cannot be undone.', {'name': habit.name})),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Delete')),
            ),
          ],
        ),
      );
      if (sure == true) store.deleteHabit(habit);
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = danger ? c.danger : c.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.raised,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(icon, color: danger ? c.danger : c.orangeText),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color, height: 1.25)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12.5, color: c.muted, height: 1.3)),
                    ],
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
