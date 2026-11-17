import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/smart_parser.dart';

/// Text controller that colors the words the smart parser understood.
class SmartTextController extends TextEditingController {
  SmartTextController({super.text});

  List<TokenSpan> spans = const [];
  AppColors colors = AppColors.light;

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final text = value.text;
    if (spans.isEmpty || value.composing.isValid && withComposing) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    final children = <TextSpan>[];
    var pos = 0;
    for (final s in spans) {
      if (s.start < pos || s.end > text.length) continue;
      if (s.start > pos) children.add(TextSpan(text: text.substring(pos, s.start)));
      children.add(TextSpan(text: text.substring(s.start, s.end), style: _styleFor(s.kind)));
      pos = s.end;
    }
    if (pos < text.length) children.add(TextSpan(text: text.substring(pos)));
    return TextSpan(style: style, children: children);
  }

  TextStyle _styleFor(TokenKind k) {
    final c = colors;
    final (Color bg, Color fg) = switch (k) {
      TokenKind.date => (c.orangeSoft, c.orangeText),
      TokenKind.time => (c.orangeSoft, c.orangeText),
      TokenKind.prayer => (c.sel, c.onSel),
      TokenKind.list => (c.raised, c.ink),
      TokenKind.tag => (c.raised, c.ink),
      TokenKind.priority => (c.orange, c.onOrange),
      TokenKind.repeat => (c.raised, c.orangeText),
      TokenKind.energy => (c.raised, c.ink),
    };
    return TextStyle(backgroundColor: bg, color: fg, fontWeight: FontWeight.w800);
  }
}
