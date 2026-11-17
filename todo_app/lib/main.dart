import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/store.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.instance.load();
  runApp(TodoApp(showOnboarding: !AppStore.instance.onboarded));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.showOnboarding});

  /// Decided once at launch; onboarding replaces itself with Home when finished.
  final bool showOnboarding;

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
        // Even line spacing above and below text keeps words and icons on one line.
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          SystemChrome.setSystemUIOverlayStyle(dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
          return DefaultTextHeightBehavior(
            textHeightBehavior: const TextHeightBehavior(leadingDistribution: TextLeadingDistribution.even),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: showOnboarding ? const OnboardingScreen() : const HomeShell(),
      ),
    );
  }
}
