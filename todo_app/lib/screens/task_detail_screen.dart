import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import 'focus_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final store = AppStore.instance;
  late final TextEditingController _title;
  late final TextEditingController _notes;
  final _newStep = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = store.taskById(widget.taskId);
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _newStep.dispose();
    super.dispose();
  }

  Future<void> _delete(Task t) async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: const Text('Delete this task?'),
        content: Text('"${t.title}" will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final index = store.deleteTask(t);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: const Text('Task deleted'),
      action: SnackBarAction(label: 'Undo', onPressed: () => store.restoreTask(t, index)),
    ));
  }

  Future<void> _editDue(Task t) async {
    final n = DateTime.now();
    final choice = await pickOption<String>(context, 'When', [
      const OptionItem('today', 'Today', icon: Icons.today_rounded),
      const OptionItem('tomorrow', 'Tomorrow', icon: Icons.wb_sunny_outlined),
      const OptionItem('week', 'Next week', icon: Icons.date_range_rounded),
      const OptionItem('pick', 'Pick a date', icon: Icons.event_rounded),
      if (t.due != null) const OptionItem('time', 'Set a time', icon: Icons.schedule_rounded),
      if (t.due != null && t.hasTime) const OptionItem('notime', 'Remove time', icon: Icons.timer_off_outlined),
      if (t.due != null) const OptionItem('clear', 'No date', icon: Icons.event_busy_rounded),
    ], null);
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'today':
        store.moveToDay(t, n);
      case 'tomorrow':
        store.moveToDay(t, DateTime(n.year, n.month, n.day + 1));
      case 'week':
        store.moveToDay(t, DateTime(n.year, n.month, n.day + 7));
      case 'pick':
        final d = await showDatePicker(
          context: context,
          initialDate: t.due ?? n,
          firstDate: DateTime(n.year - 1),
          lastDate: DateTime(n.year + 5),
        );
        if (d != null) store.moveToDay(t, d);
      case 'time':
        final base = t.due!;
        final tm = await showTimePicker(
          context: context,
          initialTime: t.hasTime ? TimeOfDay.fromDateTime(base) : const TimeOfDay(hour: 9, minute: 0),
        );
        if (tm != null) {
          t.due = DateTime(base.year, base.month, base.day, tm.hour, tm.minute);
          t.hasTime = true;
          store.updateTask(t);
        }
      case 'notime':
        final base = t.due!;
        t.due = DateTime(base.year, base.month, base.day);
        t.hasTime = false;
        store.updateTask(t);
      case 'clear':
        store.moveToDay(t, null);
    }
  }

  Future<void> _addTag(Task t) async {
    final c = context.c;
    final ctrl = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: const Text('Add a tag'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(prefixText: '#', hintText: 'exam'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Add')),
        ],
      ),
    );
    ctrl.dispose();
    final clean = (tag ?? '').trim().replaceAll('#', '').replaceAll(' ', '-');
    if (clean.isNotEmpty && !t.tags.contains(clean)) {
      t.tags.add(clean);
      store.updateTask(t);
    }
  }

  void _addStep(Task t) {
    final v = _newStep.text.trim();
    if (v.isEmpty) return;
    t.subtasks.add(SubTask(id: AppStore.newId(), title: v));
    _newStep.clear();
    store.updateTask(t);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final t = store.taskById(widget.taskId);
        if (t == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: c.bg),
            body: const EmptyState(icon: Icons.delete_outline, title: 'Task not found', message: 'This task was deleted.'),
          );
        }
        final list = store.listById(t.listId);
        final listColor = Color(list.color);
        final pct = t.subtasks.isEmpty ? 0.0 : t.subDone / t.subtasks.length;
        final overdue = !t.done && t.due != null && t.due!.isBefore(dayStart(DateTime.now()));

        return Scaffold(
          backgroundColor: c.bg,
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: c.peach,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                      ),
                      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 4, 8, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Back',
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: Icon(Icons.arrow_back_rounded, color: c.ink),
                              ),
                              Expanded(
                                child: Center(child: IconText(dot: listColor, text: list.name, color: c.peachText, size: 13.5)),
                              ),
                              IconButton(
                                tooltip: 'Delete task',
                                onPressed: () => _delete(t),
                                icon: Icon(Icons.delete_outline_rounded, color: c.ink),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CheckBoxSquare(
                                  done: t.done,
                                  size: 28,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    store.toggleDone(t);
                                  },
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: TextField(
                                      controller: _title,
                                      maxLines: null,
                                      textCapitalization: TextCapitalization.sentences,
                                      cursorColor: c.orange,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        height: 1.25,
                                        color: c.ink,
                                        decoration: t.done ? TextDecoration.lineThrough : null,
                                      ),
                                      decoration: const InputDecoration.collapsed(hintText: 'Task title'),
                                      onChanged: (v) {
                                        if (v.trim().isEmpty) return;
                                        t.title = v.trim();
                                        store.updateTask(t);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Badge(text: dueLabel(t), color: c.card, fg: overdue ? c.orangeText : c.ink),
                                if (t.priority == Priority.high) _Badge(text: 'High priority', color: c.inv, fg: c.onInv),
                                if (t.pinned) _Badge(text: 'Top 3 today', color: c.orange, fg: c.onOrange),
                                if (t.repeat != Repeat.none) _Badge(text: t.repeat.label, color: c.card, fg: c.ink),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppCard(
                            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SectionTitle('Steps',
                                      note: t.subtasks.isEmpty ? null : '${t.subDone} of ${t.subtasks.length}'),
                                ),
                                if (t.subtasks.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                          value: pct, minHeight: 6, color: c.orange, backgroundColor: c.line),
                                    ),
                                  ),
                                for (final s in t.subtasks)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            height: 1.35,
                                            color: s.done ? c.muted : c.ink,
                                            decoration: s.done ? TextDecoration.lineThrough : null,
                                            decorationColor: c.muted,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove step',
                                        icon: Icon(Icons.close_rounded, size: 18, color: c.muted),
                                        onPressed: () {
                                          t.subtasks.remove(s);
                                          store.updateTask(t);
                                        },
                                      ),
                                      CheckBoxSquare(
                                        done: s.done,
                                        size: 22,
                                        onTap: () {
                                          s.done = !s.done;
                                          store.updateTask(t);
                                        },
                                      ),
                                    ],
                                  ),
                                Row(
                                  children: [
                                    Icon(Icons.add_rounded, color: c.orangeText),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _newStep,
                                        cursorColor: c.orange,
                                        textInputAction: TextInputAction.done,
                                        style: TextStyle(color: c.ink, fontWeight: FontWeight.w500),
                                        decoration: InputDecoration(
                                          hintText: 'Add a step',
                                          hintStyle: TextStyle(color: c.orangeText, fontWeight: FontWeight.w700),
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (_) => _addStep(t),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _Prop(icon: Icons.event_rounded, label: 'When', value: dueLabel(t), onTap: () => _editDue(t)),
                                _Prop(
                                  icon: Icons.timelapse_rounded,
                                  label: 'Takes',
                                  value: fmtMinutes(t.durationMinutes),
                                  onTap: () async {
                                    final m = await pickOption<int>(context, 'How long will it take?', [
                                      for (final m in const [15, 30, 45, 60, 90, 120, 180]) OptionItem(m, fmtMinutes(m)),
                                    ], t.durationMinutes);
                                    if (m != null) {
                                      t.durationMinutes = m;
                                      store.updateTask(t);
                                    }
                                  },
                                ),
                                _Prop(
                                  icon: Icons.flag_rounded,
                                  label: 'Priority',
                                  value: t.priority.label,
                                  valueColor: t.priority == Priority.high ? c.orangeText : null,
                                  onTap: () async {
                                    final p = await pickOption<Priority>(context, 'Priority', [
                                      for (final p in Priority.values.reversed) OptionItem(p, p.label, icon: Icons.flag_rounded),
                                    ], t.priority);
                                    if (p != null) {
                                      t.priority = p;
                                      store.updateTask(t);
                                    }
                                  },
                                ),
                                _Prop(
                                  icon: Icons.folder_outlined,
                                  label: 'List',
                                  value: list.name,
                                  onTap: () async {
                                    final id = await pickOption<String>(context, 'Move to list', [
                                      for (final l in store.lists) OptionItem(l.id, l.name, icon: Icons.circle, color: Color(l.color)),
                                    ], t.listId);
                                    if (id != null) {
                                      t.listId = id;
                                      store.updateTask(t);
                                    }
                                  },
                                ),
                                _Prop(
                                  icon: Icons.repeat_rounded,
                                  label: 'Repeat',
                                  value: t.repeat.label,
                                  onTap: () async {
                                    final r = await pickOption<Repeat>(context, 'Repeat', [
                                      for (final r in Repeat.values) OptionItem(r, r.label),
                                    ], t.repeat);
                                    if (r != null) {
                                      t.repeat = r;
                                      if (r != Repeat.none && t.due == null) t.due = dayStart(DateTime.now());
                                      store.updateTask(t);
                                    }
                                  },
                                ),
                                _Prop(
                                  icon: Icons.bolt_rounded,
                                  label: 'Effort',
                                  value: t.energy.label,
                                  onTap: () async {
                                    final e = await pickOption<Energy>(context, 'How hard is it?', [
                                      for (final e in Energy.values) OptionItem(e, e.label),
                                    ], t.energy);
                                    if (e != null) {
                                      t.energy = e;
                                      store.updateTask(t);
                                    }
                                  },
                                ),
                                SwitchListTile(
                                  value: t.pinned,
                                  activeTrackColor: c.orange,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  secondary: Icon(Icons.star_outline_rounded, color: c.muted),
                                  title: Text('In today’s top 3',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: c.ink, fontSize: 15)),
                                  subtitle: Text('Shown first on Today', style: TextStyle(color: c.muted, fontSize: 12.5)),
                                  onChanged: (v) {
                                    if (!store.setPinned(t, v)) {
                                      toast(context, 'You already have 3. Unpin one first.');
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in t.tags)
                                InputChip(
                                  label: Text('#$tag'),
                                  backgroundColor: c.card,
                                  side: BorderSide(color: c.border),
                                  onDeleted: () {
                                    t.tags.remove(tag);
                                    store.updateTask(t);
                                  },
                                ),
                              ActionChip(
                                avatar: Icon(Icons.add_rounded, size: 18, color: c.orangeText),
                                label: Text('Tag', style: TextStyle(color: c.orangeText, fontWeight: FontWeight.w700)),
                                backgroundColor: c.card,
                                side: BorderSide(color: c.border),
                                onPressed: () => _addTag(t),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SectionTitle('Notes'),
                                TextField(
                                  controller: _notes,
                                  minLines: 3,
                                  maxLines: null,
                                  cursorColor: c.orange,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: TextStyle(color: c.ink, height: 1.5),
                                  decoration: InputDecoration(
                                    hintText: 'Details, links, ideas…',
                                    hintStyle: TextStyle(color: c.muted),
                                    filled: true,
                                    fillColor: c.raised,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  ),
                                  onChanged: (v) {
                                    t.notes = v;
                                    store.updateTask(t);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Created ${fmtDate(t.createdAt)}'
                            '${t.focusMinutes > 0 ? ' · focused ${fmtMinutes(t.focusMinutes)}' : ''}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: c.card, border: Border(top: BorderSide(color: c.line))),
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: BigButton(
                        label: 'Focus',
                        icon: Icons.timer_outlined,
                        primary: false,
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => FocusScreen(taskId: t.id))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BigButton(
                        label: t.done ? 'Not done' : 'Mark done',
                        icon: t.done ? Icons.undo_rounded : Icons.check_rounded,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          store.toggleDone(t);
                          if (t.done) Navigator.of(context).maybePop();
                        },
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.fg});

  final String text;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg, height: 1.2)),
    );
  }
}

class _Prop extends StatelessWidget {
  const _Prop({required this.icon, required this.label, required this.value, required this.onTap, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
        child: Row(
          children: [
            Icon(icon, size: 21, color: c.muted),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink, height: 1.2)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: valueColor ?? c.muted, fontWeight: FontWeight.w600, height: 1.2),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}
