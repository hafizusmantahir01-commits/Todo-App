import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../utils/prayer_times.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// Last setup step: lists, prayer times and look.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final store = AppStore.instance;
  final Set<String> _areas = {'Study', 'Work', 'Home', 'Health'};
  bool _prayers = true;
  String _city = 'lahore';
  late ThemeMode _theme;

  @override
  void initState() {
    super.initState();
    _theme = store.themeMode;
  }

  void _finish() {
    store.completeOnboarding(
      name: store.userName,
      areas: _areas.isEmpty ? {'Work'} : _areas,
      prayers: _prayers,
      city: _city,
      theme: _theme,
    );
    // Clear the setup screens so Back on Home closes the app.
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
  }

  Widget _label(AppColors c, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.muted)),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.hero,
      appBar: AppBar(backgroundColor: c.hero, surfaceTintColor: Colors.transparent, foregroundColor: c.ink),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                children: [
                  Text('Almost done.',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: c.ink, height: 1.15)),
                  const SizedBox(height: 8),
                  Text('You can change all of this later from your profile.',
                      style: TextStyle(fontSize: 15, color: c.muted, height: 1.45)),
                  const SizedBox(height: 24),
                  _label(c, 'What will you plan here?'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in AppStore.areaNames)
                        ChoicePill(
                          label: a,
                          selected: _areas.contains(a),
                          onTap: () => setState(() => _areas.contains(a) ? _areas.remove(a) : _areas.add(a)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 6, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          value: _prayers,
                          activeTrackColor: c.orange,
                          contentPadding: EdgeInsets.zero,
                          title: Text('Prayer times on my day', style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                          subtitle: Text('Worked out offline. No location needed.', style: TextStyle(fontSize: 12.5, color: c.muted)),
                          onChanged: (v) => setState(() => _prayers = v),
                        ),
                        if (_prayers)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: c.raised,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  final id = await pickOption<String>(
                                      context, 'Your city', [for (final ct in cities) OptionItem(ct.id, ct.name)], _city);
                                  if (id != null) setState(() => _city = id);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_city_rounded, size: 20, color: c.muted),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text('City: ${cityById(_city).name}',
                                            style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                                      ),
                                      Icon(Icons.expand_more_rounded, color: c.muted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _label(c, 'Look'),
                  Row(
                    children: [
                      for (final m in const [(ThemeMode.light, 'Light'), (ThemeMode.dark, 'Dark'), (ThemeMode.system, 'Auto')]) ...[
                        Expanded(
                          child: ChoicePill(
                            label: m.$2,
                            selected: _theme == m.$1,
                            onTap: () {
                              setState(() => _theme = m.$1);
                              store.setTheme(m.$1);
                            },
                          ),
                        ),
                        if (m.$1 != ThemeMode.system) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: BigButton(label: 'Start my day', icon: Icons.arrow_forward_rounded, onPressed: _finish),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
