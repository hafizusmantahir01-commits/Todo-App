import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/store.dart';
import 'l10n/strings.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/native.dart';
import 'services/notifications.dart';
import 'services/widget_sync.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.instance.load();
  AppStore.instance.checkInstall(await Native.firstInstallTime());
  await Notifier.init();
  AppStore.afterChange = _refreshOutside;
  _refreshOutside();
  runApp(TodoApp(showOnboarding: !AppStore.instance.onboarded));
}

/// Keeps reminders and the home-screen widget in step with the data.
void _refreshOutside() {
  Notifier.rescheduleAll();
  WidgetSync.update();
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key, required this.showOnboarding});

  /// Decided once at launch; onboarding replaces itself with Home when finished.
  final bool showOnboarding;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app: refresh texts like "3 tasks today" in upcoming reminders.
    if (state == AppLifecycleState.resumed) _refreshOutside();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'Todo App',
        debugShowCheckedModeBanner: false,
        themeMode: store.themeMode,
        theme: buildTheme(dark: false),
        darkTheme: buildTheme(dark: true),
        locale: Locale(store.lang.localeCode),
        supportedLocales: const [Locale('en'), Locale('ur')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          SystemChrome.setSystemUIOverlayStyle(dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
          // Even spacing above and below text keeps words and icons on one line.
          return DefaultTextHeightBehavior(
            textHeightBehavior: const TextHeightBehavior(leadingDistribution: TextLeadingDistribution.even),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: widget.showOnboarding ? const OnboardingScreen() : const HomeShell(),
      ),
    );
  }
}
