import 'package:flutter/material.dart';

/// The app's own color tokens: skin + white + orange in light mode,
/// black + orange in dark mode.
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
  final Color hero, peach, peachText, peachDeep, glass;
  final Color orange, onOrange, orangeSoft, orangeText;
  final Color inv, onInv, invMuted, invLine, invRaised;
  final Color done, onDone, ring, track, danger;

  static const light = AppColors(
    dark: false,
    bg: Color(0xFFFFF6EE),
    card: Color(0xFFFFFFFF),
    raised: Color(0xFFFBEDE1),
    line: Color(0xFFF2E4D8),
    border: Color(0xFFEAD5C4),
    ink: Color(0xFF1C1714),
    muted: Color(0xFF6E625A),
    hero: Color(0xFFFFE3CC),
    peach: Color(0xFFFFE3CC),
    peachText: Color(0xFF7A4524),
    peachDeep: Color(0xFFE7B48C),
    glass: Color(0x99FFFFFF),
    orange: Color(0xFFF0672A),
    onOrange: Color(0xFF1C1714),
    orangeSoft: Color(0xFFFFE3CC),
    orangeText: Color(0xFFB5420E),
    inv: Color(0xFF1C1714),
    onInv: Color(0xFFFFF3E8),
    invMuted: Color(0xFFC9B8AA),
    invLine: Color(0xFF3A302A),
    invRaised: Color(0xFF2A221E),
    done: Color(0xFF1C1714),
    onDone: Color(0xFFFFFFFF),
    ring: Color(0xFFCDB9A9),
    track: Color(0x1F1C1714),
    danger: Color(0xFFB4232C),
  );

  static const darkTheme = AppColors(
    dark: true,
    bg: Color(0xFF0E0C0B),
    card: Color(0xFF1A1614),
    raised: Color(0xFF241E1B),
    line: Color(0xFF2A2320),
    border: Color(0xFF3A302A),
    ink: Color(0xFFFFF3E8),
    muted: Color(0xFFBDAEA2),
    hero: Color(0xFF0E0C0B),
    peach: Color(0xFF1F1510),
    peachText: Color(0xFFF5B48A),
    peachDeep: Color(0xFF5A3A26),
    glass: Color(0x12FFFFFF),
    orange: Color(0xFFFF7A36),
    onOrange: Color(0xFF140D09),
    orangeSoft: Color(0xFF3A2214),
    orangeText: Color(0xFFFF9A5E),
    inv: Color(0xFF1F1916),
    onInv: Color(0xFFFFF3E8),
    invMuted: Color(0xFFBDAEA2),
    invLine: Color(0xFF352C27),
    invRaised: Color(0xFF2A2320),
    done: Color(0xFFFF7A36),
    onDone: Color(0xFF140D09),
    ring: Color(0xFF5A4C43),
    track: Color(0x24FFF3E8),
    danger: Color(0xFFFF6B6B),
  );

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

/// List and habit colors: all warm, no blue, green or purple.
const listPalette = <int>[
  0xFFD9541A, // burnt orange
  0xFF1C1714, // black
  0xFFD14B5A, // rose
  0xFFB7791F, // mustard
  0xFF8A5A3C, // cinnamon
  0xFFC99A2E, // gold
  0xFF8A7F77, // stone
];
