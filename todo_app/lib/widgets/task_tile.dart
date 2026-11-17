import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../models/task.dart';
import '../screens/task_detail_screen.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import 'common.dart';

/// One task row. Swipe right to complete, swipe left to delete (both can be undone).
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, this.showDate = true});

  final Task task;
  final bool showDate;

  void _complete(BuildContext context) {
    final store = AppStore.instance;
    final wasDone = task.done;
    final oldRepeat = task.repeat;
    HapticFeedback.mediumImpact();
    final spawned = store.toggleDone(task);
    toast(context, wasDone ? 'Marked as not done' : 'Done: ${task.title}', actionLabel: 'Undo', onAction: () {
      if (wasDone) {
        store.toggleDone(task);
      } else {
        store.undoComplete(task, spawned, oldRepeat);
      }
    });
  }

  void _delete(BuildContext context) {
    final store = AppStore.instance;
    HapticFeedback.mediumImpact();
    final index = store.deleteTask(task);
    toast(context, 'Task deleted', actionLabel: 'Undo', onAction: () => store.restoreTask(task, index));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final c = context.c;
    final list = store.listById(task.listId);
    final due = task.due;
    final overdue = !task.done && due != null && due.isBefore(dayStart(DateTime.now()));

    final meta = <Widget>[
      if (due != null && (showDate || task.hasTime))
        IconText(
          icon: Icons.schedule_rounded,
          text: showDate ? dueLabel(task) : fmtTime(due),
          color: overdue ? c.orangeText : null,
        ),
      IconText(dot: Color(list.color), text: list.name),
      if (task.priority == Priority.high) IconText(icon: Icons.flag_rounded, text: 'High', color: c.orangeText),
      if (task.subtasks.isNotEmpty) IconText(icon: Icons.checklist_rounded, text: '${task.subDone}/${task.subtasks.length}'),
      if (task.repeat != Repeat.none) IconText(icon: Icons.repeat_rounded, text: task.repeat.label),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('task-${task.id}-${task.done}'),
        background: _SwipeBg(
          left: true,
          icon: task.done ? Icons.undo_rounded : Icons.check_rounded,
          label: task.done ? 'Not done' : 'Done',
          color: c.orange,
          fg: c.onOrange,
        ),
        secondaryBackground: _SwipeBg(
          left: false,
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          color: c.danger,
          fg: Colors.white,
        ),
        onDismissed: (dir) => dir == DismissDirection.startToEnd ? _complete(context) : _delete(context),
        child: Material(
          color: c.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.line)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                    child: Container(
                      width: 5,
                      decoration: BoxDecoration(color: Color(list.color), borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: task.done ? c.muted : c.ink,
                              decoration: task.done ? TextDecoration.lineThrough : null,
                              decorationColor: c.muted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(spacing: 12, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: meta),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: CheckBoxSquare(
                      done: task.done,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        store.toggleDone(task);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({required this.left, required this.icon, required this.label, required this.color, required this.fg});

  final bool left;
  final IconData icon;
  final String label;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
