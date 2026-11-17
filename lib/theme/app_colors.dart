import 'package:flutter/material.dart';

/// The app's color tokens: "Navy & Gold". Light mode is warm white with a
/// navy header and gold buttons; dark mode is deep navy with gold.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.dark,
    required this.bg,
    required this.card,
    required this.raised,
    required this.line,
    required this.border,
    required this.ink,
    required this.muted,
    required this.hero,
    required this.peach,
    required this.onPeach,
    required this.peachText,
    required this.peachDeep,
    required this.glass,
    required this.orange,
    required this.onOrange,
    required this.orangeSoft,
    required this.orangeText,
    required this.inv,
    required this.onInv,
    required this.invMuted,
    required this.invLine,
    required this.invRaised,
    required this.done,
    required this.onDone,
    required this.ring,
    required this.track,
    required this.danger,
  });

  final bool dark;
  final Color bg, card, raised, line, border, ink, muted;

  /// [peach] is the header color (navy), [onPeach] the text on it,
  /// [peachText] the gold accent text on it. Names kept from earlier versions.
  final Color hero, peach, onPeach, peachText, peachDeep, glass;

  /// [orange] is the main accent (gold) used for buttons and highlights.
  final Color orange, onOrange, orangeSoft, orangeText;
  final Color inv, onInv, invMuted, invLine, invRaised;
  final Color done, onDone, ring, track, danger;

  static const light = AppColors(
    dark: false,
    bg: Color(0xFFF7F6F2),
    card: Color(0xFFFFFFFF),
    raised: Color(0xFFEFEDE6),
    line: Color(0xFFE8E5DC),
    border: Color(0xFFDAD5C8),
    ink: Color(0xFF14213D),
    muted: Color(0xFF5D6475),
    hero: Color(0xFFF7F6F2),
    peach: Color(0xFF14213D),
    onPeach: Color(0xFFFFFFFF),
    peachText: Color(0xFFE9C46A),
    peachDeep: Color(0xFF3E4C6E),
    glass: Color(0x1FFFFFFF),
    orange: Color(0xFFC9A227),
    onOrange: Color(0xFF14213D),
    orangeSoft: Color(0xFFF6EDCF),
    orangeText: Color(0xFF7A5C05),
    inv: Color(0xFF14213D),
    onInv: Color(0xFFFFFFFF),
    invMuted: Color(0xFFAAB3C8),
    invLine: Color(0xFF2A3657),
    invRaised: Color(0xFF1E2C4C),
    done: Color(0xFF14213D),
    onDone: Color(0xFFFFFFFF),
    ring: Color(0xFFC9C3B3),
    track: Color(0x2EFFFFFF),
    danger: Color(0xFFB4232C),
  );

  static const darkTheme = AppColors(
    dark: true,
    bg: Color(0xFF0A0F1C),
    card: Color(0xFF121A2E),
    raised: Color(0xFF1A243C),
    line: Color(0xFF1F2A44),
    border: Color(0xFF33405F),
    ink: Color(0xFFEEF0F6),
    muted: Color(0xFFA6AFC4),
    hero: Color(0xFF0A0F1C),
    peach: Color(0xFF121A2E),
    onPeach: Color(0xFFEEF0F6),
    peachText: Color(0xFFE9C46A),
    peachDeep: Color(0xFF3A4566),
    glass: Color(0x12FFFFFF),
    orange: Color(0xFFE0B73E),
    onOrange: Color(0xFF0A0F1C),
    orangeSoft: Color(0xFF2E2A16),
    orangeText: Color(0xFFF0CF6B),
    inv: Color(0xFF1E2A46),
    onInv: Color(0xFFEEF0F6),
    invMuted: Color(0xFFA6AFC4),
    invLine: Color(0xFF2C3958),
    invRaised: Color(0xFF26324F),
    done: Color(0xFFE0B73E),
    onDone: Color(0xFF0A0F1C),
    ring: Color(0xFF46516E),
    track: Color(0x24EEF0F6),
    danger: Color(0xFFFF6B6B),
  );

  /// Selected chip, tab or day. Black in light mode; in dark mode black would
  /// vanish into the background, so orange is used instead.
  Color get sel => dark ? orange : inv;
  Color get onSel => dark ? onOrange : onInv;

  /// Soft background for a list or habit color.
  Color tintOf(Color c) => Color.lerp(c, card, dark ? 0.78 : 0.84)!;

  /// Readable text color in the family of [c].
  Color textOf(Color c) => dark ? Color.lerp(c, Colors.white, 0.35)! : Color.lerp(c, Colors.black, 0.32)!;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppColorsX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}

/// List and habit colors.
const listPalette = <int>[
  0xFF2563EB, // blue
  0xFF14213D, // navy
  0xFFE11D48, // rose
  0xFFD97706, // amber
  0xFF0D9488, // teal
  0xFFC9A227, // gold
  0xFF6B7280, // stone
];
