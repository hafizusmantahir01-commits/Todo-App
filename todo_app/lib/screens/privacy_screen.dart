import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'me_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = <(String, String)>[
    ('What we collect', 'Nothing. Todo App does not collect, send or sell any personal data. There is no account and no sign-in.'),
    ('Where your data lives', 'Tasks, lists, habits, reviews and settings are saved only on this phone, in the app’s private storage.'),
    ('Internet and permissions', 'The app works fully offline. Prayer times are calculated on the phone. It does not use the internet, your location or contacts. The camera or gallery opens only when you choose a profile photo, and that photo stays on this phone.'),
    ('Ads and analytics', 'There are no ads, no analytics and no third-party tracking.'),
    ('Your control', 'Copy your data with Export data, or erase everything with Delete all data. Uninstalling the app also removes all data.'),
    ('Children', 'The app is not directed at children under 13 and does not knowingly collect information from anyone.'),
    ('Contact', 'Questions? Email $contactEmail'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        title: Text('Privacy policy', style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Text('Short version: your tasks never leave your phone.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink, height: 1.35)),
          const SizedBox(height: 18),
          for (final s in _sections) ...[
            Text(s.$1, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 4),
            Text(s.$2, style: TextStyle(color: c.muted, height: 1.55)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
