import 'dart:io';

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';

/// Built-in avatars the user can pick instead of a photo.
const avatarIcons = <IconData>[
  Icons.face_rounded,
  Icons.face_2_rounded,
  Icons.face_3_rounded,
  Icons.face_4_rounded,
  Icons.face_5_rounded,
  Icons.face_6_rounded,
  Icons.mosque_rounded,
  Icons.menu_book_rounded,
  Icons.sports_cricket_rounded,
  Icons.local_cafe_rounded,
  Icons.rocket_launch_rounded,
  Icons.spa_rounded,
];

/// Background colors for avatars and letters.
const avatarColors = <int>[0xFFF0672A, 0xFF1C1714, 0xFFD14B5A, 0xFFB7791F, 0xFF8A5A3C, 0xFFC99A2E];

/// The user's picture: photo, built-in avatar, or the first letter of their name.
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
    final onColor = store.avatarColor == 0xFF1C1714 ? c.orange : Colors.white;

    Widget inner;
    final path = store.photoPath;
    if (store.avatarKind == 'photo' && path != null && File(path).existsSync()) {
      inner = Image.file(File(path), width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (store.avatarKind == 'avatar') {
      inner = Container(
        color: color,
        alignment: Alignment.center,
        child: Icon(avatarIcons[store.avatarIndex.clamp(0, avatarIcons.length - 1)], size: size * 0.58, color: onColor),
      );
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
