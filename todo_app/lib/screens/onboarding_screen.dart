import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/day_arc.dart';
import 'profile_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _toProfile() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
  }

  void _next() {
    if (_page < 2) {
      _pc.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _toProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final last = _page == 2;
    return PopScope<Object?>(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pc.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
      },
      child: Scaffold(
        backgroundColor: c.hero,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: c.inv, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.check_rounded, color: c.orange, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Text('Todo App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        onPressed: _toProfile,
                        style: TextButton.styleFrom(foregroundColor: c.ink),
                        child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [
                    _Page(
                      title: 'Type like you talk.',
                      body: 'Write “kal shaam 6 baje gym” and the date, time and list fill in by themselves. English or Roman Urdu, both work.',
                      art: _TypingDemo(),
                    ),
                    _Page(
                      title: 'Plan around your day.',
                      body: 'Tie tasks to prayer times: “Zuhr se pehle”, “Maghrib ke baad”. Times are worked out on your phone, no internet needed.',
                      art: _ArcDemo(),
                    ),
                    _Page(
                      title: 'Build habits. Close the day.',
                      body: 'Track small daily habits, focus with a timer you set yourself, and wrap up each evening in one minute.',
                      art: _HabitsDemo(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? c.orange : c.peachDeep,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    const Spacer(),
                    BigButton(
                      label: last ? 'Set up profile' : 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.body, required this.art});

  final String title;
  final String body;
  final Widget art;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 8),
              art,
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 33, fontWeight: FontWeight.w800, letterSpacing: -1, color: c.ink, height: 1.15)),
                  const SizedBox(height: 10),
                  Text(body, style: TextStyle(fontSize: 16, color: c.muted, height: 1.55)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Words get recognised one by one, like a live demo.
class _TypingDemo extends StatefulWidget {
  const _TypingDemo();

  @override
  State<_TypingDemo> createState() => _TypingDemoState();
}

class _TypingDemoState extends State<_TypingDemo> {
  Timer? _t;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 950), (_) {
      if (mounted) setState(() => _step = (_step + 1) % 6);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget word(String w, int at, Color bg, Color fg) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: _step >= at ? bg : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Text(w,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _step >= at ? fg : c.ink, height: 1.3)),
        );
    Widget chip(String s, int at, Color bg, Color fg) => AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _step >= at ? 1 : 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: _step >= at ? Offset.zero : const Offset(0, 0.4),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg, height: 1)),
            ),
          ),
        );
    const health = Color(0xFFD14B5A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New task', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  word('kal', 1, c.orangeSoft, c.orangeText),
                  word('shaam 6 baje', 2, c.inv, c.onInv),
                  word('gym', 99, c.card, c.ink),
                  word('#Health', 3, c.tintOf(health), c.textOf(health)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: Row(
                  children: [
                    chip('Tomorrow', 1, c.orangeSoft, c.orangeText),
                    const SizedBox(width: 8),
                    chip('6:00 PM', 2, c.inv, c.onInv),
                    const SizedBox(width: 8),
                    chip('Health', 3, c.tintOf(health), c.textOf(health)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _step >= 4 ? 1 : 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: c.inv, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: c.orange, borderRadius: BorderRadius.circular(11)),
                  child: Icon(Icons.check_rounded, color: c.onOrange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gym', style: TextStyle(fontWeight: FontWeight.w800, color: c.onInv)),
                      Text('Tomorrow · 6:00 PM · Health', style: TextStyle(fontSize: 12.5, color: c.invMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcDemo extends StatelessWidget {
  const _ArcDemo();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget row(String when, String what, {bool dark = false}) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(color: dark ? c.inv : c.card, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                child: Text(when,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: dark ? c.orange : c.orangeText)),
              ),
              Expanded(
                child: Text(what, style: TextStyle(fontWeight: FontWeight.w700, color: dark ? c.onInv : c.ink)),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DayArc(
          height: 190,
          sun: 0.3,
          markers: const [
            ArcMarker(0, 'Fajr', passed: true),
            ArcMarker(0.5, 'Zuhr'),
            ArcMarker(0.72, 'Asr'),
            ArcMarker(0.88, 'Maghrib'),
            ArcMarker(1, 'Isha'),
          ],
          center: Text('10:00',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: c.ink, letterSpacing: -1)),
        ),
        const SizedBox(height: 8),
        row('After Fajr', 'Quran, one page'),
        row('Before Zuhr', 'Submit assignment'),
        row('After Maghrib', 'Gym, legs day', dark: true),
      ],
    );
  }
}

class _HabitsDemo extends StatelessWidget {
  const _HabitsDemo();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget habit(String name, String streak, int filled) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink, height: 1.2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < 7; i++) ...[
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: i < filled ? c.orange : c.raised,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(streak, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: c.orangeText)),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: c.inv, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: c.orange, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your day, wrapped', style: TextStyle(fontWeight: FontWeight.w800, color: c.onInv, fontSize: 16)),
                    Text('5 tasks · 1h 40m focus · 4/5 habits', style: TextStyle(fontSize: 12.5, color: c.invMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        habit('Namaz on time', '12 days', 7),
        habit('Read 10 pages', '3 days', 4),
      ],
    );
  }
}
