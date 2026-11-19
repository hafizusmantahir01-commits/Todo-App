import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../services/sound.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';

enum _Mode { focus, shortBreak, longBreak }

/// Focus timer with any length the user wants (1 to 180 minutes).
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final store = AppStore.instance;
  _Mode _mode = _Mode.focus;
  String? _taskId;
  int _sessions = 0;
  Timer? _timer;
  DateTime? _endAt;
  late int _remaining;

  bool get _running => _timer != null;
  bool get _fresh => !_running && _remaining == _total;
  Task? get _task => _taskId == null ? null : store.taskById(_taskId!);

  int _minutesFor(_Mode m) => switch (m) {
        _Mode.focus => store.focusMinutes,
        _Mode.shortBreak => store.shortBreakMinutes,
        _Mode.longBreak => store.longBreakMinutes,
      };

  int get _total => _minutesFor(_mode) * 60;

  String _label(_Mode m) => switch (m) {
        _Mode.focus => tr('Focus'),
        _Mode.shortBreak => tr('Short break'),
        _Mode.longBreak => tr('Long break'),
      };

  @override
  void initState() {
    super.initState();
    _taskId = widget.taskId;
    _remaining = _total;
  }

  @override
  void dispose() {
    _timer?.cancel();
    FocusSound.stop();
    super.dispose();
  }

  String _soundLabel(String k) => switch (k) {
        'rain' => tr('Rain'),
        'white' => tr('White noise'),
        'brown' => tr('Deep noise'),
        _ => tr('Silent'),
      };

  void _setSound(String k) {
    store.setSettings(sound: k);
    if (_running && _mode == _Mode.focus) FocusSound.play(k);
    setState(() {});
  }

  void _start() {
    _endAt = DateTime.now().add(Duration(seconds: _remaining));
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    if (_mode == _Mode.focus) FocusSound.play(store.focusSound);
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _tick() {
    final end = _endAt;
    if (end == null) return;
    final left = end.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      _finish();
    } else if (left != _remaining) {
      setState(() => _remaining = left);
    }
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    FocusSound.stop();
    setState(() {});
  }

  void _setMode(_Mode m) {
    _timer?.cancel();
    _timer = null;
    FocusSound.stop();
    setState(() {
      _mode = m;
      _remaining = _total;
    });
  }

  /// Changes the length of the current mode by [delta] minutes (before starting).
  void _adjust(int delta) {
    final cur = _minutesFor(_mode);
    final next = (cur + delta).clamp(1, 180);
    switch (_mode) {
      case _Mode.focus:
        store.setFocusDurations(focus: next);
      case _Mode.shortBreak:
        store.setFocusDurations(shortBreak: next);
      case _Mode.longBreak:
        store.setFocusDurations(longBreak: next);
    }
    HapticFeedback.selectionClick();
    setState(() => _remaining = _total);
  }

  int get _elapsedFocus => _mode == _Mode.focus ? (_total - _remaining) ~/ 60 : 0;

  void _finish() {
    _timer?.cancel();
    _timer = null;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    if (_mode == _Mode.focus) {
      _sessions++;
      store.addFocus(_task, _minutesFor(_Mode.focus));
      _setMode(_sessions % 4 == 0 ? _Mode.longBreak : _Mode.shortBreak);
      if (mounted) toast(context, tr('Session done. Take a short break.'));
    } else {
      _setMode(_Mode.focus);
      if (mounted) toast(context, tr('Break is over. Ready for the next one?'));
    }
  }

  void _skip() {
    if (_mode == _Mode.focus) {
      store.addFocus(_task, _elapsedFocus);
      _sessions++;
      _setMode(_sessions % 4 == 0 ? _Mode.longBreak : _Mode.shortBreak);
    } else {
      _setMode(_Mode.focus);
    }
  }

  Future<void> _customize() async {
    if (_running) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: context.c.card,
      builder: (_) => const _DurationSheet(),
    );
    if (mounted) setState(() => _remaining = _total);
  }

  Future<void> _chooseTask() async {
    final open = store.sortTasks(store.tasks.where((t) => !t.done));
    final id = await pickOption<String>(
      context,
      tr('What are you working on?'),
      [
        OptionItem('', tr('No task'), icon: Icons.remove_circle_outline_rounded),
        for (final t in open) OptionItem(t.id, t.title, subtitle: dueLabel(t), icon: Icons.circle, color: Color(store.listById(t.listId).color)),
      ],
      _taskId ?? '',
    );
    if (id != null) setState(() => _taskId = id.isEmpty ? null : id);
  }

  Future<void> _confirmLeave() async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(tr('Stop this session?')),
        content: Text(tr('The timer is still running. Minutes you already focused will be saved.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Keep going'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Stop'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      store.addFocus(_task, _elapsedFocus);
      _timer?.cancel();
      _timer = null;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final total = _total;
    final progress = total == 0 ? 0.0 : 1 - _remaining / total;
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');
    final task = _task;
    final ends = DateTime.now().add(Duration(seconds: _remaining));

    return PopScope<Object?>(
      canPop: !_running,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: c.hero,
        appBar: AppBar(
          backgroundColor: c.hero,
          surfaceTintColor: Colors.transparent,
          foregroundColor: c.ink,
          centerTitle: true,
          title: Text(tr('Session {n} of 4', {'n': (_sessions % 4) + 1}),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.muted)),
          actions: [
            IconButton(
              tooltip: tr('Timer lengths'),
              onPressed: _running ? null : _customize,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, box) {
              final ring = (box.maxWidth - 80).clamp(200.0, 280.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight - 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              for (final m in _Mode.values) ...[
                                Expanded(
                                  child: ChoicePill(
                                    label: _label(m),
                                    selected: _mode == m,
                                    onTap: _running ? null : () => _setMode(m),
                                  ),
                                ),
                                if (m != _Mode.longBreak) const SizedBox(width: 8),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          AppCard(
                            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                            onTap: _running ? null : _chooseTask,
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: task == null ? c.ring : Color(store.listById(task.listId).color),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(task == null ? tr('No task selected') : tr('Working on'),
                                          style: TextStyle(fontSize: 12, color: c.muted, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(task?.title ?? tr('Tap to choose a task'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.swap_horiz_rounded, color: c.muted),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          SizedBox(
                            width: ring,
                            height: ring,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 14,
                                  strokeCap: StrokeCap.round,
                                  color: c.orange,
                                  backgroundColor: c.peachDeep.withValues(alpha: 0.5),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$mm:$ss',
                                        style: TextStyle(
                                          fontSize: ring * 0.22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -2,
                                          height: 1,
                                          color: c.ink,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _running ? tr('Ends at {time}', {'time': fmtTime(ends)}) : (_fresh ? _label(_mode) : tr('Paused')),
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Change the length right here, before starting.
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _fresh ? 1 : 0.35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _RoundIcon(icon: Icons.remove_rounded, label: tr('Five minutes less'), onTap: _fresh ? () => _adjust(-5) : null),
                                const SizedBox(width: 10),
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _fresh ? _customize : null,
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 18),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
                                    child: Text(tr('{n} min', {'n': _minutesFor(_mode)}),
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _RoundIcon(icon: Icons.add_rounded, label: tr('Five minutes more'), onTap: _fresh ? () => _adjust(5) : null),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final m in _mode == _Mode.focus ? const [15, 25, 45, 60, 90] : const [5, 10, 15, 20, 30]) ...[
                                  ChoicePill(
                                    label: '$m',
                                    soft: true,
                                    selected: _minutesFor(_mode) == m,
                                    onTap: _fresh ? () => _adjust(m - _minutesFor(_mode)) : null,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(Icons.graphic_eq_rounded, size: 20, color: c.muted),
                            const SizedBox(width: 8),
                            for (final k in FocusSound.choices) ...[
                              ChoicePill(label: _soundLabel(k), selected: store.focusSound == k, onTap: () => _setSound(k)),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RoundIcon(icon: Icons.replay_rounded, label: tr('Reset'), big: true, onTap: () => _setMode(_mode)),
                          const SizedBox(width: 26),
                          Semantics(
                            button: true,
                            label: _running ? tr('Pause') : tr('Start'),
                            child: Material(
                              color: c.orange,
                              borderRadius: BorderRadius.circular(30),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: _running ? _pause : _start,
                                child: SizedBox(
                                  width: 88,
                                  height: 88,
                                  child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      size: 44, color: c.onOrange),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 26),
                          _RoundIcon(icon: Icons.skip_next_rounded, label: tr('Skip'), big: true, onTap: _skip),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.label, required this.onTap, this.big = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = big ? 58.0 : 44.0;
    return Tooltip(
      message: label,
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(big ? 20 : 14),
        child: InkWell(
          borderRadius: BorderRadius.circular(big ? 20 : 14),
          onTap: onTap,
          child: SizedBox(width: s, height: s, child: Icon(icon, color: c.ink, size: big ? 26 : 22)),
        ),
      ),
    );
  }
}

/// Sliders for focus and break lengths.
class _DurationSheet extends StatefulWidget {
  const _DurationSheet();

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  final store = AppStore.instance;

  Widget _row(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink))),
            IconButton(
              tooltip: tr('Less'),
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 64,
              child: Text(tr('{n} min', {'n': value}),
                  textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
            ),
            IconButton(
              tooltip: tr('More'),
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: c.orange,
          inactiveColor: c.raised,
          label: tr('{n} min', {'n': value}),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('Timer lengths'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 4),
            Text(tr('Set any length you like. It is saved for next time.'), style: TextStyle(color: c.muted)),
            const SizedBox(height: 12),
            _row(tr('Focus'), store.focusMinutes, 1, 180, (v) => setState(() => store.setFocusDurations(focus: v))),
            _row(tr('Short break'), store.shortBreakMinutes, 1, 60, (v) => setState(() => store.setFocusDurations(shortBreak: v))),
            _row(tr('Long break'), store.longBreakMinutes, 1, 90, (v) => setState(() => store.setFocusDurations(longBreak: v))),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BigButton(label: tr('Done'), onPressed: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }
}
