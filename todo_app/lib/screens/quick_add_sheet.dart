import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../utils/prayer_times.dart';
import '../utils/smart_parser.dart';
import '../widgets/common.dart';
import '../widgets/smart_text_controller.dart';
import 'brain_dump_screen.dart';

Future<void> showQuickAdd(BuildContext context, {DateTime? initialDate, TimeOfDay? initialTime, String? listId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.c.card,
    builder: (_) => QuickAddSheet(initialDate: initialDate, initialTime: initialTime, listId: listId),
  );
}

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key, this.initialDate, this.initialTime, this.listId});

  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final String? listId;

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

enum _When { today, tomorrow, weekend }

class _QuickAddSheetState extends State<QuickAddSheet> {
  final store = AppStore.instance;
  final _text = SmartTextController();
  final _steps = TextEditingController();

  ParsedTask? _parsed;
  DateTime? _date;
  TimeOfDay? _time;
  String? _anchor;
  Priority _priority = Priority.none;
  late String _listId;
  Repeat _repeat = Repeat.none;
  Energy _energy = Energy.medium;
  bool _showSteps = false;

  bool _mDate = false, _mTime = false, _mPri = false, _mList = false, _mRep = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate == null ? null : dayStart(widget.initialDate!);
    _time = widget.initialTime;
    _mTime = widget.initialTime != null;
    _listId = widget.listId ?? 'inbox';
    _mList = widget.listId != null;
  }

  @override
  void dispose() {
    _text.dispose();
    _steps.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final p = SmartParser.parse(
      v,
      listNames: store.lists.map((l) => l.name).toList(),
      prayerTimes: store.prayersFor,
    );
    _text.spans = p.spans;
    setState(() {
      _parsed = p;
      final due = p.due;
      if (!_mDate) _date = due != null ? dayStart(due) : (widget.initialDate == null ? null : dayStart(widget.initialDate!));
      if (!_mTime) {
        _time = (p.hasTime && due != null) ? TimeOfDay(hour: due.hour, minute: due.minute) : widget.initialTime;
        _anchor = p.anchor;
      }
      if (!_mPri) _priority = p.priority ?? Priority.none;
      if (!_mList) {
        final name = p.listName;
        _listId = (name != null ? store.listByName(name)?.id : null) ?? widget.listId ?? 'inbox';
      }
      if (!_mRep) _repeat = p.repeat ?? Repeat.none;
      _energy = p.energy ?? Energy.medium;
    });
  }

  void _setWhen(_When w) {
    final n = DateTime.now();
    setState(() {
      _mDate = true;
      _date = switch (w) {
        _When.today => DateTime(n.year, n.month, n.day),
        _When.tomorrow => DateTime(n.year, n.month, n.day + 1),
        _When.weekend => DateTime(n.year, n.month, n.day + (6 - n.weekday) % 7),
      };
    });
  }

  bool _isWhen(_When w) {
    final d = _date;
    if (d == null) return false;
    final diff = daysFromToday(d);
    return switch (w) {
      _When.today => diff == 0,
      _When.tomorrow => diff == 1,
      _When.weekend => d.weekday == DateTime.saturday && diff > 1,
    };
  }

  Future<void> _pickDate() async {
    final n = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? n,
      firstDate: DateTime(n.year - 1),
      lastDate: DateTime(n.year + 5),
    );
    if (d != null) {
      setState(() {
        _date = d;
        _mDate = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (t != null) {
      setState(() {
        _time = t;
        _anchor = null;
        _mTime = true;
      });
    }
  }

  void _setPrayer(Prayer p, bool after) {
    final n = DateTime.now();
    var day = _date ?? DateTime(n.year, n.month, n.day);
    DateTime at(DateTime d) => store.prayersFor(d)![p].add(Duration(minutes: after ? 15 : -30));
    var t = at(day);
    if (_date == null && t.isBefore(n)) {
      day = DateTime(n.year, n.month, n.day + 1);
      t = at(day);
    }
    setState(() {
      _date = day;
      _mDate = true;
      _time = TimeOfDay(hour: t.hour, minute: t.minute);
      _anchor = '${after ? 'after' : 'before'} ${p.label}';
      _mTime = true;
    });
  }

  Future<void> _pickPriority() async {
    final c = context.c;
    final p = await pickOption<Priority>(context, 'Priority', [
      OptionItem(Priority.high, 'High', icon: Icons.flag_rounded, color: c.orange),
      OptionItem(Priority.medium, 'Medium', icon: Icons.flag_outlined, color: c.orangeText),
      OptionItem(Priority.low, 'Low', icon: Icons.outlined_flag_rounded, color: c.muted),
      OptionItem(Priority.none, 'None', icon: Icons.remove_rounded, color: c.muted),
    ], _priority);
    if (p != null) {
      setState(() {
        _priority = p;
        _mPri = true;
      });
    }
  }

  Future<void> _pickList() async {
    final id = await pickOption<String>(
      context,
      'List',
      [for (final l in store.lists) OptionItem(l.id, l.name, icon: Icons.circle, color: Color(l.color))],
      _listId,
    );
    if (id != null) {
      setState(() {
        _listId = id;
        _mList = true;
      });
    }
  }

  Future<void> _pickRepeat() async {
    final r = await pickOption<Repeat>(
      context,
      'Repeat',
      [for (final r in Repeat.values) OptionItem(r, r.label, icon: Icons.repeat_rounded)],
      _repeat,
    );
    if (r != null) {
      setState(() {
        _repeat = r;
        _mRep = true;
      });
    }
  }

  void _save() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final pTitle = _parsed?.title ?? '';
    DateTime? due;
    var hasTime = false;
    final d = _date;
    final t = _time;
    if (d != null && t != null) {
      due = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      hasTime = true;
    } else if (d != null) {
      due = DateTime(d.year, d.month, d.day);
    } else if (t != null) {
      final n = DateTime.now();
      due = DateTime(n.year, n.month, n.day, t.hour, t.minute);
      hasTime = true;
    }
    if (_repeat != Repeat.none && due == null) due = dayStart(DateTime.now());
    final steps = _steps.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => SubTask(id: AppStore.newId(), title: s))
        .toList();
    store.addTask(Task(
      id: AppStore.newId(),
      title: pTitle.isEmpty ? text : pTitle,
      listId: _listId,
      priority: _priority,
      energy: _energy,
      due: due,
      hasTime: hasTime,
      repeat: _repeat,
      tags: List.of(_parsed?.tags ?? const <String>[]),
      subtasks: steps,
    ));
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _template(String which) {
    final n = DateTime.now();
    DateTime day(int plus) => DateTime(n.year, n.month, n.day + plus);
    String listOr(String name) => store.listByName(name)?.id ?? 'inbox';
    final tasks = <Task>[];
    switch (which) {
      case 'exam':
        const steps = [
          ('Make a study plan', 0),
          ('Revise chapter notes', 1),
          ('Solve past papers', 3),
          ('Clear doubts with a friend or teacher', 5),
          ('Final revision', 6),
        ];
        for (final s in steps) {
          tasks.add(Task(id: AppStore.newId(), title: s.$1, listId: listOr('Study'), due: day(s.$2), priority: Priority.medium));
        }
      case 'grocery':
        tasks.add(Task(
          id: AppStore.newId(),
          title: 'Grocery run',
          listId: listOr('Shopping'),
          due: day(0),
          subtasks: [
            for (final s in ['Milk', 'Eggs', 'Bread', 'Vegetables', 'Fruit']) SubTask(id: AppStore.newId(), title: s),
          ],
        ));
      case 'bills':
        final tenth = n.day <= 10 ? DateTime(n.year, n.month, 10) : DateTime(n.year, n.month + 1, 10);
        for (final b in ['Electricity bill', 'Gas bill', 'Internet bill']) {
          tasks.add(Task(id: AppStore.newId(), title: b, listId: listOr('Home'), due: tenth, repeat: Repeat.monthly));
        }
    }
    store.addTasks(tasks);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text('${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'} added')));
  }

  String _summary() {
    final parts = <String>[];
    final d = _date;
    if (d != null) parts.add(relDay(d));
    final t = _time;
    if (t != null) {
      final n = DateTime.now();
      parts.add(_anchor != null ? '$_anchor (${fmtTime(DateTime(n.year, n.month, n.day, t.hour, t.minute))})'
          : fmtTime(DateTime(n.year, n.month, n.day, t.hour, t.minute)));
    }
    parts.add(store.listById(_listId).name);
    if (_priority != Priority.none) parts.add('${_priority.label} priority');
    if (_repeat != Repeat.none) parts.add(_repeat.label);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    _text.colors = c;
    final canSave = _text.text.trim().isNotEmpty;
    final prayers = store.prayerOn;
    final list = store.listById(_listId);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Add a task', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: c.ink)),
                ),
                TextButton.icon(
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(MaterialPageRoute(builder: (_) => const BrainDumpScreen()));
                  },
                  style: TextButton.styleFrom(foregroundColor: c.orangeText),
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: const Text('Brain dump'),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.orange, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _text,
                          autofocus: true,
                          minLines: 1,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          cursorColor: c.orange,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.ink, height: 1.5),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: prayers ? 'kal Maghrib ke baad ammi ko call' : 'kal shaam 6 baje gym #Health',
                            hintStyle: TextStyle(color: c.muted, fontWeight: FontWeight.w500),
                          ),
                          onChanged: _onChanged,
                          onSubmitted: (_) => _save(),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 15, color: c.orange),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _summary(),
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.muted, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label(c, 'When'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoicePill(label: 'Today', selected: _isWhen(_When.today), onTap: () => _setWhen(_When.today)),
                        const SizedBox(width: 8),
                        ChoicePill(label: 'Tomorrow', selected: _isWhen(_When.tomorrow), onTap: () => _setWhen(_When.tomorrow)),
                        const SizedBox(width: 8),
                        ChoicePill(label: 'This weekend', selected: _isWhen(_When.weekend), onTap: () => _setWhen(_When.weekend)),
                        const SizedBox(width: 8),
                        ChoicePill(label: 'Pick date', icon: Icons.event_rounded, onTap: _pickDate),
                        const SizedBox(width: 8),
                        ChoicePill(label: 'No date', onTap: () => setState(() {
                              _date = null;
                              _time = null;
                              _anchor = null;
                              _mDate = true;
                              _mTime = true;
                            })),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (prayers) ...[
                          for (final p in const [
                            (Prayer.fajr, true),
                            (Prayer.dhuhr, false),
                            (Prayer.asr, true),
                            (Prayer.maghrib, true),
                            (Prayer.isha, true),
                          ]) ...[
                            ChoicePill(
                              label: '${p.$2 ? 'After' : 'Before'} ${p.$1.label}',
                              soft: true,
                              selected: _anchor == '${p.$2 ? 'after' : 'before'} ${p.$1.label}',
                              onTap: () => _setPrayer(p.$1, p.$2),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                        ChoicePill(
                          label: _time != null && _anchor == null
                              ? fmtTime(DateTime(2000, 1, 1, _time!.hour, _time!.minute))
                              : 'Exact time',
                          icon: Icons.schedule_rounded,
                          selected: _time != null && _anchor == null,
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Tool(
                          icon: Icons.flag_rounded,
                          iconColor: _priority == Priority.none ? null : c.orange,
                          label: _priority == Priority.none ? 'Priority' : _priority.label,
                          onTap: _pickPriority,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Tool(icon: Icons.circle, iconColor: Color(list.color), label: list.name, onTap: _pickList),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Tool(
                          icon: Icons.repeat_rounded,
                          label: _repeat == Repeat.none ? 'Repeat' : _repeat.label,
                          onTap: _pickRepeat,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Tool(
                          icon: Icons.checklist_rounded,
                          label: 'Steps',
                          active: _showSteps,
                          onTap: () => setState(() => _showSteps = !_showSteps),
                        ),
                      ),
                    ],
                  ),
                  if (_showSteps) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _steps,
                      minLines: 2,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: c.ink, height: 1.4),
                      decoration: InputDecoration(
                        hintText: 'One step per line',
                        hintStyle: TextStyle(color: c.muted),
                        filled: true,
                        fillColor: c.raised,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _label(c, 'Or start from a template'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Template(title: 'Exam prep', note: '5 steps over 7 days', onTap: () => _template('exam')),
                        const SizedBox(width: 8),
                        _Template(title: 'Grocery run', note: 'Checklist of 5', onTap: () => _template('grocery')),
                        const SizedBox(width: 8),
                        _Template(title: 'Bills this month', note: 'Monthly repeat', onTap: () => _template('bills')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
            child: BigButton(label: 'Add task', icon: Icons.add_rounded, onPressed: canSave ? _save : null),
          ),
        ],
      ),
    );
  }

  Widget _label(AppColors c, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.muted, height: 1.2)),
      );
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap, this.iconColor, this.active = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: active ? c.inv : c.raised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: icon == Icons.circle ? 14 : 20, color: active ? c.orange : (iconColor ?? c.ink)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: active ? c.onInv : c.ink, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Template extends StatelessWidget {
  const _Template({required this.title, required this.note, required this.onTap});

  final String title;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.raised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.ink, height: 1.25)),
              const SizedBox(height: 2),
              Text(note, style: TextStyle(fontSize: 12, color: c.muted, height: 1.25)),
            ],
          ),
        ),
      ),
    );
  }
}
