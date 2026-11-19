import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/smart_parser.dart';
import '../widgets/common.dart';

/// Write everything on your mind, one per line, then add it all at once.
class BrainDumpScreen extends StatefulWidget {
  const BrainDumpScreen({super.key});

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final store = AppStore.instance;
  final _ctrl = TextEditingController();
  List<ParsedTask> _items = [];
  List<bool> _keep = [];
  bool _preview = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _parse() {
    final names = store.lists.map((l) => l.name).toList();
    final lines = _ctrl.text
        .split(RegExp(r'[\n;]+'))
        .map((l) => l.trim().replaceFirst(RegExp(r'^([-*•]|\d+[.)])\s*'), ''))
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    setState(() {
      _items = lines.map((l) => SmartParser.parse(l, listNames: names, prayerTimes: store.prayersFor)).toList();
      _keep = List<bool>.filled(_items.length, true);
      _preview = true;
    });
  }

  void _addAll() {
    final tasks = <Task>[];
    for (var i = 0; i < _items.length; i++) {
      if (!_keep[i]) continue;
      final p = _items[i];
      final name = p.listName;
      tasks.add(Task(
        id: AppStore.newId(),
        title: p.title,
        listId: (name != null ? store.listByName(name)?.id : null) ?? 'inbox',
        priority: p.priority ?? Priority.none,
        energy: p.energy ?? Energy.medium,
        due: p.due,
        hasTime: p.hasTime,
        reminderMinutes: p.hasTime && store.remindersOn ? store.defaultReminder : -1,
        repeat: p.repeat ?? Repeat.none,
        tags: List.of(p.tags),
      ));
    }
    if (tasks.isEmpty) return;
    store.addTasks(tasks);
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(trn(tasks.length, '1 task added', '{n} tasks added'))));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final count = _keep.where((k) => k).length;
    return PopScope<Object?>(
      canPop: !_preview,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _preview = false);
      },
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          surfaceTintColor: Colors.transparent,
          title: Text(_preview ? tr('Review tasks') : tr('Brain dump'), style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _preview
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr('Untick anything you don’t want.'), style: TextStyle(color: c.muted)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final p = _items[i];
                            final details = <String>[
                              if (p.due != null) dueLabel(Task(id: '', title: '', due: p.due, hasTime: p.hasTime)),
                              if (p.anchor != null) anchorLabel(p.anchor!),
                              if (p.listName != null) p.listName!,
                              if (p.priority != null) tr('{p} priority', {'p': p.priority!.label}),
                              if (p.repeat != null) p.repeat!.label,
                            ];
                            return AppCard(
                              border: true,
                              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.ink)),
                                        if (details.isNotEmpty)
                                          Text(details.join(' · '),
                                              style: TextStyle(fontSize: 12.5, color: c.orangeText, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  CheckBoxSquare(
                                    done: _keep[i],
                                    fill: c.orange,
                                    check: c.onOrange,
                                    onTap: () => setState(() => _keep[i] = !_keep[i]),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      BigButton(label: trn(count, 'Add 1 task', 'Add {n} tasks'), onPressed: count == 0 ? null : _addAll),
                      TextButton(
                        onPressed: () => setState(() => _preview = false),
                        style: TextButton.styleFrom(foregroundColor: c.orangeText),
                        child: Text(tr('Edit text')),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr('Empty your head. One thing per line. Dates, times, prayers and #lists are understood.'),
                          style: TextStyle(color: c.muted, height: 1.45)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          autofocus: true,
                          maxLines: null,
                          expands: true,
                          cursorColor: c.orange,
                          textAlignVertical: TextAlignVertical.top,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(color: c.ink, height: 1.5, fontSize: 15.5),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: tr(
                                'pay electricity bill tomorrow\ncall mom after Maghrib\nsubmit assignment friday #Study !high\nmilk and eggs #Shopping'),
                            hintStyle: TextStyle(color: c.muted),
                            filled: true,
                            fillColor: c.card,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      BigButton(
                        label: tr('Turn into tasks'),
                        icon: Icons.auto_awesome_rounded,
                        onPressed: _ctrl.text.trim().isEmpty ? null : _parse,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
