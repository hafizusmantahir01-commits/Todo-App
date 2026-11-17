import 'package:flutter/material.dart';

import 'app_colors.dart';

const appFont = 'PlusJakartaSans';
const urduFont = 'NotoNaskhArabic';

final Map<bool, ThemeData> _cache = {};

ThemeData buildTheme({required bool dark}) {
  return _cache.putIfAbsent(dark, () {
    final c = dark ? AppColors.darkTheme : AppColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: c.orange,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: c.orange,
      onPrimary: c.onOrange,
      secondary: c.inv,
      onSecondary: c.onInv,
      surface: c.bg,
      onSurface: c.ink,
      onSurfaceVariant: c.muted,
      surfaceContainerLowest: c.card,
      surfaceContainerLow: c.card,
      surfaceContainer: c.card,
      surfaceContainerHigh: c.card,
      surfaceContainerHighest: c.raised,
      outline: c.border,
      outlineVariant: c.line,
      error: c.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: appFont,
      fontFamilyFallback: const [urduFont],
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inv,
        contentTextStyle: TextStyle(fontFamily: appFont, color: c.onInv, fontWeight: FontWeight.w600),
        actionTextColor: c.orange,
      ),
      // Clear on/off look for switches in both themes.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? c.onOrange : (dark ? c.muted : Colors.white)),
        trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? c.orange : (dark ? c.raised : c.ring)),
        trackOutlineColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? c.orange : c.border),
      ),
      extensions: [c],
    );
    // One consistent type scale with even line spacing, so text and icons line up.
    final tt = base.textTheme.apply(
        fontFamily: appFont, fontFamilyFallback: const [urduFont], bodyColor: c.ink, displayColor: c.ink);
    return base.copyWith(
      textTheme: tt.copyWith(
        headlineMedium: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15),
        headlineSmall: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.2),
        titleLarge: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.25),
        titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
        titleSmall: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
        bodyLarge: tt.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: tt.bodyMedium?.copyWith(height: 1.45),
        bodySmall: tt.bodySmall?.copyWith(height: 1.35, color: c.muted),
        labelLarge: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
      ),
    );
  });
}
