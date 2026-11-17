import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/dates.dart';

/// Rounded surface for grouped content.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.radius = 22,
    this.border = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: color ?? c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: border ? BorderSide(color: c.line) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Section heading with an optional note or action on the right.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.note, this.trailing, this.color});

  final String title;
  final String? note;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color ?? c.ink, height: 1.2),
            ),
          ),
          if (note != null)
            Text(note!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.muted, height: 1.2)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small icon and text that always sit on the same center line.
class IconText extends StatelessWidget {
  const IconText({super.key, this.icon, this.dot, required this.text, this.color, this.size = 12.5});

  final IconData? icon;
  final Color? dot;
  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final col = color ?? context.c.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) Icon(icon, size: size + 2, color: col),
        if (dot != null)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(3)),
          ),
        if (icon != null || dot != null) const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: size, color: col, fontWeight: FontWeight.w600, height: 1.2)),
      ],
    );
  }
}

/// Rounded-square check with a 44px touch target.
class CheckBoxSquare extends StatelessWidget {
  const CheckBoxSquare({
    super.key,
    required this.done,
    required this.onTap,
    this.size = 26,
    this.fill,
    this.check,
    this.ringColor,
  });

  final bool done;
  final VoidCallback onTap;
  final double size;
  final Color? fill;
  final Color? check;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final f = fill ?? c.done;
    return Semantics(
      button: true,
      checked: done,
      label: done ? tr('Mark as not done') : tr('Mark as done'),
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: done ? f : Colors.transparent,
                borderRadius: BorderRadius.circular(size * 0.34),
                border: Border.all(color: done ? f : (ringColor ?? c.ring), width: 2),
              ),
              child: done ? Icon(Icons.check_rounded, size: size * 0.66, color: check ?? c.onDone) : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped choice chip used across the app.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.dot,
    this.soft = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? dot;

  /// Soft orange look, used for prayer-time choices.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final Color bg;
    final Color fg;
    final Color side;
    if (selected) {
      bg = soft ? c.orange : c.sel;
      fg = soft ? c.onOrange : c.onSel;
      side = bg;
    } else if (soft) {
      bg = c.orangeSoft;
      fg = c.orangeText;
      side = c.orange.withValues(alpha: 0.45);
    } else {
      bg = c.card;
      fg = c.ink;
      side = c.border;
    }
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13), side: BorderSide(color: side, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 6)],
              if (dot != null) ...[
                Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, fontSize: 13.5, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big rounded button. [primary] is orange, otherwise black.
class BigButton extends StatelessWidget {
  const BigButton({super.key, required this.label, required this.onPressed, this.icon, this.primary = true, this.height = 56});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bg = primary ? c.orange : c.inv;
    final fg = primary ? c.onOrange : c.onInv;
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: c.raised,
          disabledForegroundColor: c.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: !primary && c.dark ? BorderSide(color: c.invLine, width: 1.5) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.w800),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: c.orangeSoft, borderRadius: BorderRadius.circular(24)),
            child: Icon(icon, size: 34, color: c.orangeText),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.ink, height: 1.25)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.muted, height: 1.45)),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

String dueLabel(Task t) {
  final d = t.due;
  if (d == null) return tr('No date');
  return t.hasTime ? '${relDay(d)}, ${fmtTime(d)}' : relDay(d);
}

class OptionItem<T> {
  const OptionItem(this.value, this.label, {this.icon, this.color, this.subtitle});
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
}

/// Bottom sheet with choices. Returns the picked value, or null if dismissed.
Future<T?> pickOption<T>(BuildContext context, String title, List<OptionItem<T>> items, T? current) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    builder: (ctx) {
      final c = ctx.c;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.75),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
              ),
              for (final it in items)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  minVerticalPadding: 12,
                  leading: it.icon != null ? Icon(it.icon, color: it.color ?? c.muted) : null,
                  title: Text(it.label, style: TextStyle(fontWeight: FontWeight.w600, color: c.ink)),
                  subtitle: it.subtitle != null ? Text(it.subtitle!, style: TextStyle(color: c.muted)) : null,
                  trailing: it.value == current ? Icon(Icons.check_rounded, color: c.orange) : null,
                  onTap: () => Navigator.pop(ctx, it.value),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows a short message at the bottom of the screen.
void toast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(message),
    action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
  ));
}
