import 'dart:io';

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';

/// Background colors for avatars and letters.
const avatarColors = <int>[0xFFF6EDCF, 0xFFDCE7FB, 0xFFFCE1E7, 0xFFDDF3EC, 0xFFC9A227, 0xFF14213D, 0xFF2563EB, 0xFF0D9488];

/// The user's picture: a photo, or the first letter of their name.
/// With [showGear], a small settings badge sits on the corner.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.size = 46, this.showGear = false, this.radius});

  final double size;
  final bool showGear;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = AppStore.instance;
    final r = radius ?? size * 0.32;
    final color = Color(store.avatarColor);
    final onColor = store.avatarColor == 0xFF14213D
        ? const Color(0xFFE9C46A)
        : (color.computeLuminance() > 0.35 ? const Color(0xFF14213D) : Colors.white);

    Widget inner;
    final path = store.photoPath;
    if (store.avatarKind == 'photo' && path != null && File(path).existsSync()) {
      inner = Image.file(File(path), width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true);
    } else {
      final name = store.userName.trim();
      inner = Container(
        color: color,
        alignment: Alignment.center,
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w800, color: onColor, height: 1),
        ),
      );
    }

    final pic = ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: SizedBox(width: size, height: size, child: inner),
    );
    if (!showGear) return pic;
    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, child: pic),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: c.inv,
                shape: BoxShape.circle,
                border: Border.all(color: c.peach, width: 2),
              ),
              child: Icon(Icons.settings_rounded, size: 12, color: c.onInv),
            ),
          ),
        ],
      ),
    );
  }
}
