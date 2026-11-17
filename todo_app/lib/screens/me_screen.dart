import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../utils/prayer_times.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';
import 'brain_dump_screen.dart';
import 'help_screen.dart';
import 'lists_screen.dart';
import 'privacy_screen.dart';
import 'profile_setup_screen.dart';

const appVersion = '2.1.0';
const contactEmail = 'innovexa.technologies01@gmail.com';

/// Profile and settings.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _deleteAll(BuildContext context) async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: const Text('Delete all data?'),
        content: const Text('All tasks, lists, habits and history on this phone will be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (ok == true) {
      AppStore.instance.clearAll();
      if (context.mounted) toast(context, 'All data deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final name = store.userName;
        return Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            backgroundColor: c.bg,
            surfaceTintColor: Colors.transparent,
            title: Text('Profile & settings', style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              AppCard(
                color: c.peach,
                onTap: () => _push(context, const ProfileSetupScreen(editing: true)),
                child: Row(
                  children: [
                    const UserAvatar(size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? 'Add your name' : name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink, height: 1.25)),
                          const SizedBox(height: 2),
                          Text('Change name or picture',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.peachText, height: 1.35)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.ink),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('No account needed. Everything stays on this phone.',
                    style: TextStyle(fontSize: 12.5, color: c.muted)),
              ),
              const SizedBox(height: 20),
              const _Group('Look'),
              AppCard(
                child: Row(
                  children: [
                    for (final m in const [
                      (ThemeMode.light, 'Light', Icons.light_mode_outlined),
                      (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
                      (ThemeMode.system, 'Auto', Icons.brightness_auto_outlined),
                    ]) ...[
                      Expanded(
                        child: ChoicePill(
                          label: m.$2,
                          icon: m.$3,
                          selected: store.themeMode == m.$1,
                          onTap: () => store.setTheme(m.$1),
                        ),
                      ),
                      if (m.$1 != ThemeMode.system) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _Group('Prayer times'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: store.prayerOn,
                      activeTrackColor: c.orange,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text('Plan around prayer times', style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                      subtitle: Text('Day arc, groups and “after Maghrib” style planning',
                          style: TextStyle(fontSize: 12.5, color: c.muted)),
                      onChanged: (v) => store.setPrayer(on: v),
                    ),
                    if (store.prayerOn) ...[
                      _Row(
                        icon: Icons.location_city_rounded,
                        title: 'City',
                        value: store.city.name,
                        onTap: () async {
                          final id = await pickOption<String>(
                            context,
                            'Your city',
                            [for (final ct in cities) OptionItem(ct.id, ct.name)],
                            store.cityId,
                          );
                          if (id != null) store.setPrayer(city: id);
                        },
                      ),
                      _Row(
                        icon: Icons.wb_twilight_rounded,
                        title: 'Asr time',
                        value: store.hanafi ? 'Hanafi' : 'Shafi, Maliki, Hanbali',
                        onTap: () async {
                          final v = await pickOption<bool>(context, 'Asr calculation', const [
                            OptionItem(true, 'Hanafi', subtitle: 'Later Asr, common in Pakistan'),
                            OptionItem(false, 'Shafi, Maliki, Hanbali', subtitle: 'Earlier Asr'),
                          ], store.hanafi);
                          if (v != null) store.setPrayer(hanafiAsr: v);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: Text(
                          'Times are calculated on your phone (Karachi method). Your local masjid may differ by a few minutes.',
                          style: TextStyle(fontSize: 12, color: c.muted, height: 1.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _Group('Organize'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(icon: Icons.folder_outlined, title: 'Lists', value: '${store.lists.length}', onTap: () => _push(context, const ListsScreen())),
                    _Row(icon: Icons.bolt_rounded, title: 'Brain dump', value: 'Many tasks at once', onTap: () => _push(context, const BrainDumpScreen())),
                    _Row(icon: Icons.auto_awesome_outlined, title: 'Smart typing guide', value: 'Roman Urdu', onTap: () => _push(context, const HelpScreen())),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _Group('Your data'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.file_copy_outlined,
                      title: 'Export data',
                      value: 'Copy as JSON',
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: store.exportJson()));
                        if (context.mounted) toast(context, 'Copied. Paste it into a note or email to keep a backup.');
                      },
                    ),
                    _Row(
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete all data',
                      value: '',
                      danger: true,
                      onTap: () => _deleteAll(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _Group('About'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(icon: Icons.privacy_tip_outlined, title: 'Privacy policy', value: '', onTap: () => _push(context, const PrivacyScreen())),
                    _Row(
                      icon: Icons.mail_outline_rounded,
                      title: 'Contact',
                      value: contactEmail,
                      onTap: () async {
                        await Clipboard.setData(const ClipboardData(text: contactEmail));
                        if (context.mounted) toast(context, 'Email copied');
                      },
                    ),
                    _Row(icon: Icons.info_outline_rounded, title: 'Version', value: appVersion, onTap: null),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.c.muted)),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.value, required this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = danger ? c.danger : c.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
        child: Row(
          children: [
            Icon(icon, size: 21, color: danger ? c.danger : c.muted),
            const SizedBox(width: 14),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: col, height: 1.2)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: c.muted, height: 1.2)),
            ),
            if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.chevron_right_rounded, color: c.muted)],
          ],
        ),
      ),
    );
  }
}
