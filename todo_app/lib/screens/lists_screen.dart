import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';
import 'quick_add_sheet.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  Future<void> _newList(BuildContext context) async {
    final c = context.c;
    final ctrl = TextEditingController();
    var color = listPalette.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: c.card,
          title: const Text('New list'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Freelance'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final col in listPalette)
                    InkResponse(
                      onTap: () => setLocal(() => color = col),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(col),
                          shape: BoxShape.circle,
                          border: Border.all(color: col == color ? c.orange : Colors.transparent, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (ok == true && name.isNotEmpty) AppStore.instance.addList(name, color);
  }

  Future<void> _deleteList(BuildContext context, TaskList l) async {
    if (l.id == 'inbox') return;
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Delete "${l.name}"?'),
        content: const Text('Its tasks will move to Inbox.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) AppStore.instance.deleteList(l);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        return Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            backgroundColor: c.bg,
            surfaceTintColor: Colors.transparent,
            title: Text('Lists', style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: BigButton(label: 'New list', icon: Icons.add_rounded, height: 42, onPressed: () => _newList(context)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              for (final l in store.lists)
                Builder(builder: (context) {
                  final all = store.tasks.where((t) => t.listId == l.id).toList();
                  final done = all.where((t) => t.done).length;
                  final color = Color(l.color);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      border: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ListTasksScreen(title: l.name, listId: l.id, filter: (t) => t.listId == l.id),
                      )),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.tintOf(color), borderRadius: BorderRadius.circular(14)),
                            child: Text(l.name.isEmpty ? '?' : l.name[0].toUpperCase(),
                                style: TextStyle(color: c.textOf(color), fontWeight: FontWeight.w800, fontSize: 17, height: 1)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(l.name, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink, fontSize: 15.5)),
                                  ),
                                  Text('${all.length - done} open', style: TextStyle(fontSize: 12.5, color: c.muted)),
                                ]),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: all.isEmpty ? 0 : done / all.length,
                                    minHeight: 6,
                                    color: color,
                                    backgroundColor: c.raised,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (l.id != 'inbox')
                            IconButton(
                              tooltip: 'Delete list',
                              icon: Icon(Icons.more_vert_rounded, color: c.muted),
                              onPressed: () => _deleteList(context, l),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

/// Tasks for one list or a filter.
class ListTasksScreen extends StatelessWidget {
  const ListTasksScreen({super.key, required this.title, required this.filter, this.listId});

  final String title;
  final bool Function(Task) filter;
  final String? listId;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final items = store.sortTasks(store.tasks.where(filter));
        final open = items.where((t) => !t.done).toList();
        final done = items.where((t) => t.done).toList();
        return Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            backgroundColor: c.bg,
            surfaceTintColor: Colors.transparent,
            title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
          ),
          floatingActionButton: listId == null
              ? null
              : FloatingActionButton(
                  tooltip: 'Add task',
                  backgroundColor: c.orange,
                  foregroundColor: c.onOrange,
                  onPressed: () => showQuickAdd(context, listId: listId),
                  child: const Icon(Icons.add_rounded),
                ),
          body: items.isEmpty
              ? const EmptyState(icon: Icons.inbox_outlined, title: 'No tasks here', message: 'Tap + to add the first one.')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    for (final t in open) TaskTile(task: t),
                    if (done.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SectionTitle('Completed', note: '${done.length}'),
                      for (final t in done) TaskTile(task: t),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
