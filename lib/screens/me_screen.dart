import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../services/backup.dart';
import '../services/native.dart';
import '../services/notifications.dart';
import '../services/pdf_report.dart';
import '../utils/dates.dart';
import '../theme/app_colors.dart';
import '../utils/prayer_times.dart';
import '../widgets/city_picker.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';
import 'brain_dump_screen.dart';
import 'help_screen.dart';
import 'lists_screen.dart';
import 'onboarding_screen.dart';
import 'privacy_screen.dart';
import 'weekly_plan_screen.dart';
import 'widget_settings_screen.dart';
import 'profile_setup_screen.dart';

const appVersion = '3.5.2';
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
        title: Text(tr('Delete all data?')),
        content: Text(tr('All tasks, lists, habits and history on this phone will be removed. This cannot be undone.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Delete everything')),
          ),
        ],
      ),
    );
    if (ok == true) {
      AppStore.instance.clearAll();
      if (context.mounted) toast(context, tr('All data deleted'));
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
            title: Text(tr('Profile & settings'), style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
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
                          Text(name.isEmpty ? tr('Add your name') : name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.onPeach, height: 1.25)),
                          const SizedBox(height: 2),
                          Text(tr('Change name or picture'),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.peachText, height: 1.35)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.onPeach),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(tr('No account needed. Everything stays on this phone.'),
                    style: TextStyle(fontSize: 12.5, color: c.muted)),
              ),
              const SizedBox(height: 20),
              _Group(tr('Language')),
              AppCard(
                child: Row(
                  children: [
                    for (final l in Lang.values) ...[
                      Expanded(
                        child: ChoicePill(
                          label: l.nativeName,
                          selected: store.lang == l,
                          onTap: () => store.setSettings(language: l),
                        ),
                      ),
                      if (l != Lang.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Group(tr('Look')),
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
                          label: tr(m.$2),
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
              _Group(tr('Prayer times')),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: store.prayerOn,
                      activeTrackColor: c.orange,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(tr('Plan around prayer times'), style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                      subtitle: Text(tr('Day arc, groups and “after Maghrib” style planning'),
                          style: TextStyle(fontSize: 12.5, color: c.muted)),
                      onChanged: (v) => store.setPrayer(on: v),
                    ),
                    if (store.prayerOn) ...[
                      _Row(
                        icon: Icons.location_city_rounded,
                        title: tr('City'),
                        value: store.city.name,
                        onTap: () async {
                          final id = await showCityPicker(context, current: store.cityId);
                          if (id != null) store.setPrayer(city: id);
                        },
                      ),
                      _Row(
                        icon: Icons.wb_twilight_rounded,
                        title: tr('Asr time'),
                        value: store.hanafi ? tr('Hanafi') : tr('Shafi, Maliki, Hanbali'),
                        onTap: () async {
                          final v = await pickOption<bool>(context, tr('Asr calculation'), [
                            OptionItem(true, tr('Hanafi'), subtitle: tr('Later Asr, common in Pakistan')),
                            OptionItem(false, tr('Shafi, Maliki, Hanbali'), subtitle: tr('Earlier Asr')),
                          ], store.hanafi);
                          if (v != null) store.setPrayer(hanafiAsr: v);
                        },
                      ),
                      _Row(
                        icon: Icons.nightlight_round,
                        title: tr('Ramzan mode'),
                        value: switch (store.ramzanMode) {
                          'on' => tr('On'),
                          'off' => tr('Off'),
                          _ => store.isRamzan ? tr('Auto (on now)') : tr('Auto'),
                        },
                        onTap: () async {
                          final v = await pickOption<String>(context, tr('Ramzan mode'), [
                            OptionItem('auto', tr('Auto'), subtitle: tr('Turns on by itself in Ramzan')),
                            OptionItem('on', tr('On'), subtitle: tr('Sehri and Iftar on your day')),
                            OptionItem('off', tr('Off')),
                          ], store.ramzanMode);
                          if (v != null) store.setSettings(ramzan: v);
                        },
                      ),
                      _Row(
                        icon: Icons.calendar_today_outlined,
                        title: tr('Islamic date'),
                        value: () {
                          final h = store.hijriFor(DateTime.now());
                          return '${h.day} ${hijriMonthName(h.month)} ${h.year}';
                        }(),
                        onTap: () async {
                          final v = await pickOption<int>(context, tr('Adjust Islamic date'), [
                            for (final d in const [-2, -1, 0, 1, 2])
                              OptionItem(d, d == 0 ? tr('As calculated') : tr('{d} day', {'d': d > 0 ? '+$d' : '$d'})),
                          ], store.hijriOffset);
                          if (v != null) store.setSettings(hijriAdjust: v);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: Text(
                          tr('Times are calculated on your phone (Karachi method). Your local masjid may differ by a few minutes.'),
                          style: TextStyle(fontSize: 12, color: c.muted, height: 1.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Group(tr('Reminders')),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: store.remindersOn,
                      activeTrackColor: c.orange,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(tr('Task reminders'), style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                      subtitle: Text(tr('A notification before tasks that have a time'),
                          style: TextStyle(fontSize: 12.5, color: c.muted)),
                      onChanged: (v) async {
                        if (v) await Notifier.requestPermission();
                        store.setSettings(reminders: v);
                      },
                    ),
                    if (store.remindersOn)
                      _Row(
                        icon: Icons.timer_outlined,
                        title: tr('Default reminder'),
                        value: Notifier.reminderLabel(store.defaultReminder),
                        onTap: () async {
                          final m = await pickOption<int>(context, tr('Default reminder'), [
                            for (final m in Notifier.reminderChoices.where((m) => m >= 0)) OptionItem(m, Notifier.reminderLabel(m)),
                          ], store.defaultReminder);
                          if (m != null) store.setSettings(reminderMinutes: m);
                        },
                      ),
                    if (store.prayerOn) ...[
                      SwitchListTile(
                        value: store.prayerAlerts,
                        activeTrackColor: c.orange,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(tr('Prayer time alerts'), style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                        subtitle: Text(tr('A gentle note at prayer time, with what comes next'),
                            style: TextStyle(fontSize: 12.5, color: c.muted)),
                        onChanged: (v) async {
                          if (v) await Notifier.requestPermission();
                          store.setSettings(prayerAlertsOn: v);
                        },
                      ),
                      if (store.prayerAlerts)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in Prayer.values)
                                ChoicePill(
                                  label: p.label,
                                  soft: true,
                                  selected: store.prayerAlertSet.contains(p.name),
                                  onTap: () {
                                    final set = {...store.prayerAlertSet};
                                    set.contains(p.name) ? set.remove(p.name) : set.add(p.name);
                                    store.setSettings(prayerSet: set);
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                    SwitchListTile(
                      value: store.morningSummary,
                      activeTrackColor: c.orange,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(tr('Morning summary'), style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                      subtitle: Text(tr('How many tasks you have today, at {time}', {'time': fmtHour(store.morningHour)}),
                          style: TextStyle(fontSize: 12.5, color: c.muted)),
                      onChanged: (v) async {
                        if (v) await Notifier.requestPermission();
                        store.setSettings(morning: v);
                      },
                    ),
                    if (store.morningSummary)
                      _Row(
                        icon: Icons.wb_sunny_outlined,
                        title: tr('Summary time'),
                        value: fmtHour(store.morningHour),
                        onTap: () async {
                          final h = await pickOption<int>(context, tr('Summary time'), [
                            for (final h in const [5, 6, 7, 8, 9, 10]) OptionItem(h, fmtHour(h)),
                          ], store.morningHour);
                          if (h != null) store.setSettings(morningAt: h);
                        },
                      ),
                    SwitchListTile(
                      value: store.weeklyReminder,
                      activeTrackColor: c.orange,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(tr('Weekly planning reminder'), style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                      subtitle: Text(tr('Sunday at 8 PM'), style: TextStyle(fontSize: 12.5, color: c.muted)),
                      onChanged: (v) => store.setSettings(weekly: v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Group(tr('Phone calendar')),
              AppCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  value: store.calendarOn,
                  activeTrackColor: c.orange,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(tr('Show my calendar in Planner'), style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                  subtitle: Text(tr('Meetings from Google Calendar and other calendars on this phone. Read only.'),
                      style: TextStyle(fontSize: 12.5, color: c.muted)),
                  onChanged: (v) async {
                    if (v) {
                      final ok = await Native.hasCalendarPermission() || await Native.requestCalendarPermission();
                      if (!ok) {
                        if (context.mounted) toast(context, tr('Calendar access was not allowed.'));
                        return;
                      }
                    }
                    store.setSettings(calendar: v);
                  },
                ),
              ),
              const SizedBox(height: 20),
              _Group(tr('Organize')),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.view_week_outlined,
                      title: tr('Week starts on'),
                      value: dayName(store.weekStart),
                      onTap: () async {
                        final d = await pickOption<int>(context, tr('Week starts on'), [
                          for (final w in const [DateTime.monday, DateTime.saturday, DateTime.sunday]) OptionItem(w, dayName(w)),
                        ], store.weekStart);
                        if (d != null) store.setSettings(weekStartDay: d);
                      },
                    ),
                    _Row(icon: Icons.event_note_rounded, title: tr('Plan your week'), value: '', onTap: () => _push(context, const WeeklyPlanScreen())),
                    _Row(icon: Icons.folder_outlined, title: tr('Lists'), value: '${store.lists.length}', onTap: () => _push(context, const ListsScreen())),
                    _Row(icon: Icons.bolt_rounded, title: tr('Brain dump'), value: tr('Many tasks at once'), onTap: () => _push(context, const BrainDumpScreen())),
                    _Row(
                      icon: Icons.replay_rounded,
                      title: tr('Show welcome screens again'),
                      value: '',
                      onTap: () {
                        store.restartIntro();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                          (_) => false,
                        );
                      },
                    ),
                    _Row(
                      icon: Icons.widgets_outlined,
                      title: tr('Home screen widget'),
                      value: WidgetSettingsScreen.contentLabel(store.widgetContent),
                      onTap: () => _push(context, const WidgetSettingsScreen()),
                    ),
                    _Row(icon: Icons.auto_awesome_outlined, title: tr('Smart typing guide'), value: 'اردو · Roman Urdu · English', onTap: () => _push(context, const HelpScreen())),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Group(tr('Your data')),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.save_alt_rounded,
                      title: tr('Save backup file'),
                      value: tr('Drive, WhatsApp, Files'),
                      onTap: () async {
                        final ok = await Backup.export();
                        if (!ok && context.mounted) toast(context, tr('Could not create the backup.'));
                      },
                    ),
                    _Row(
                      icon: Icons.picture_as_pdf_outlined,
                      title: tr('Save as PDF'),
                      value: tr('Drive, WhatsApp, print'),
                      onTap: () async {
                        toast(context, tr('Making your PDF…'));
                        final ok = await PdfReport.share();
                        if (!ok && context.mounted) toast(context, tr('Could not create the PDF.'));
                      },
                    ),
                    _Row(
                      icon: Icons.restore_rounded,
                      title: tr('Restore from backup'),
                      value: '',
                      onTap: () async {
                        final c2 = context.c;
                        final sure = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: c2.card,
                            title: Text(tr('Restore a backup?')),
                            content: Text(tr('Your current tasks, lists and habits will be replaced by the ones in the file.')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Choose file'))),
                            ],
                          ),
                        );
                        if (sure != true) return;
                        final r = await Backup.restore();
                        if (!context.mounted || r == null) return;
                        toast(context, r ? tr('Backup restored') : tr('That file is not a Todo App backup.'));
                      },
                    ),
                    _Row(
                      icon: Icons.delete_forever_outlined,
                      title: tr('Delete all data'),
                      value: '',
                      danger: true,
                      onTap: () => _deleteAll(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Group(tr('About')),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(icon: Icons.privacy_tip_outlined, title: tr('Privacy policy'), value: '', onTap: () => _push(context, const PrivacyScreen())),
                    _Row(
                      icon: Icons.mail_outline_rounded,
                      title: tr('Contact'),
                      value: contactEmail,
                      onTap: () async {
                        await Clipboard.setData(const ClipboardData(text: contactEmail));
                        if (context.mounted) toast(context, tr('Email copied'));
                      },
                    ),
                    _Row(icon: Icons.info_outline_rounded, title: tr('Version'), value: appVersion, onTap: null),
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
