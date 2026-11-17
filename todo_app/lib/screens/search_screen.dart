import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final store = AppStore.instance;
  final _q = TextEditingController();
  bool _high = false;
  bool _week = false;
  bool _done = false;
  String? _listId;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  bool _match(Task t) {
    final q = _q.text.trim().toLowerCase();
    if (!_done && t.done) return false;
    if (_high && t.priority != Priority.high) return false;
    if (_listId != null && t.listId != _listId) return false;
    if (_week) {
      final d = t.due;
      final n = DateTime.now();
      if (d == null || !d.isBefore(DateTime(n.year, n.month, n.day + 7))) return false;
    }
    if (q.isEmpty) return true;
    final tag = q.startsWith('#') ? q.substring(1) : q;
    return t.title.toLowerCase().contains(q) ||
        t.notes.toLowerCase().contains(q) ||
        t.tags.any((x) => x.toLowerCase().contains(tag)) ||
        t.subtasks.any((s) => s.title.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final active = _q.text.trim().isNotEmpty || _high || _week || _listId != null;
        final results = active ? store.sortTasks(store.tasks.where(_match)) : const <Task>[];
        return Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            backgroundColor: c.bg,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            title: TextField(
              controller: _q,
              autofocus: true,
              cursorColor: c.orange,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
              decoration: InputDecoration(
                hintText: 'Search tasks, notes, #tags',
                hintStyle: TextStyle(color: c.muted, fontWeight: FontWeight.w500),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
            actions: [
              if (_q.text.isNotEmpty)
                IconButton(tooltip: 'Clear', icon: const Icon(Icons.close_rounded), onPressed: () => setState(_q.clear)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoicePill(label: 'High priority', selected: _high, onTap: () => setState(() => _high = !_high)),
                    const SizedBox(width: 8),
                    ChoicePill(label: 'Next 7 days', selected: _week, onTap: () => setState(() => _week = !_week)),
                    const SizedBox(width: 8),
                    ChoicePill(label: 'Include done', selected: _done, onTap: () => setState(() => _done = !_done)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final l in store.lists) ...[
                      ChoicePill(
                        label: l.name,
                        dot: Color(l.color),
                        selected: _listId == l.id,
                        onTap: () => setState(() => _listId = _listId == l.id ? null : l.id),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!active)
                const EmptyState(
                  icon: Icons.search_rounded,
                  title: 'Find anything',
                  message: 'Search by words, #tags or notes, or tap a filter.',
                )
              else if (results.isEmpty)
                const EmptyState(icon: Icons.search_off_rounded, title: 'No matches', message: 'Try another word or remove a filter.')
              else ...[
                SectionTitle(results.length == 1 ? '1 result' : '${results.length} results'),
                for (final t in results) TaskTile(task: t),
              ],
            ],
          ),
        );
      },
    );
  }
}
