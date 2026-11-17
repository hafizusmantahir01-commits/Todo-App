import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'habits_screen.dart';
import 'planner_screen.dart';
import 'quick_add_sheet.dart';
import 'review_screen.dart';
import 'today_screen.dart';

/// Bottom-tab shell.
///
/// Back button rules (Android):
/// 1. On Planner, Habits or Review, Back returns to Today.
/// 2. On Today, Back closes the app.
/// Pushed screens simply return here.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[TodayScreen(), PlannerScreen(), HabitsScreen(), ReviewScreen()];

  void _go(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PopScope<Object?>(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: c.inv,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Tab(icon: Icons.wb_sunny_outlined, label: 'Today', active: _index == 0, onTap: () => _go(0)),
                _Tab(icon: Icons.calendar_month_outlined, label: 'Planner', active: _index == 1, onTap: () => _go(1)),
                Semantics(
                  button: true,
                  label: 'Add task',
                  child: Material(
                    color: c.orange,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => showQuickAdd(context, initialDate: _index == 0 ? DateTime.now() : null),
                      child: SizedBox(width: 56, height: 56, child: Icon(Icons.add_rounded, size: 30, color: c.onOrange)),
                    ),
                  ),
                ),
                _Tab(icon: Icons.track_changes_rounded, label: 'Habits', active: _index == 2, onTap: () => _go(2)),
                _Tab(icon: Icons.insights_rounded, label: 'Review', active: _index == 3, onTap: () => _go(3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = active ? c.orange : c.invMuted;
    return Semantics(
      selected: active,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          width: 62,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: col),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(fontSize: 11, height: 1.1, color: col, fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
