import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ArcMarker {
  const ArcMarker(this.fraction, this.label, {this.passed = false});
  final double fraction;
  final String label;
  final bool passed;
}

/// Half-circle "day arc": the sun travels from the first marker to the last.
class DayArc extends StatelessWidget {
  const DayArc({super.key, required this.markers, required this.sun, required this.center, this.height = 184});

  final List<ArcMarker> markers;

  /// Position of the sun, 0 to 1.
  final double sun;

  /// Shown inside the arc (time and a short line).
  final Widget center;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcPainter(
                markers: markers,
                sun: sun.clamp(0.0, 1.0),
                track: c.peachDeep,
                progress: c.orange,
                fill: c.peach,
                text: c.peachText,
                future: c.onPeach.withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 22, child: center),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.markers,
    required this.sun,
    required this.track,
    required this.progress,
    required this.fill,
    required this.text,
    required this.future,
  });

  final List<ArcMarker> markers;
  final double sun;
  final Color track, progress, fill, text, future;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height - 24;
    final r = math.min(cx - 34, baseY - 14);

    Offset at(double f) {
      final th = math.pi - f * math.pi;
      return Offset(cx + r * math.cos(th), baseY - r * math.sin(th));
    }

    final rect = Rect.fromCircle(center: Offset(cx, baseY), radius: r);

    // Dashed full arc.
    final dash = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const segments = 60;
    for (var i = 0; i < segments; i += 2) {
      final a = math.pi + (i / segments) * math.pi;
      canvas.drawArc(rect, a, math.pi / segments, false, dash);
    }

    // Elapsed part.
    if (sun > 0) {
      final p = Paint()
        ..color = progress
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, math.pi, sun * math.pi, false, p);
    }

    // Markers and labels.
    for (final m in markers) {
      final o = at(m.fraction);
      canvas.drawCircle(o, 5.5, Paint()..color = fill);
      canvas.drawCircle(
        o,
        5.5,
        Paint()
          ..color = m.passed ? progress : future
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: m.label,
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontFamilyFallback: const ['NotoNaskhArabic'], fontSize: 11, fontWeight: FontWeight.w700, color: text, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      Offset pos;
      if (m.fraction < 0.1 || m.fraction > 0.9) {
        pos = Offset(o.dx - tp.width / 2, o.dy + 10);
      } else if (o.dx < cx - 12) {
        pos = Offset(o.dx - tp.width - 10, o.dy - tp.height / 2 - 2);
      } else if (o.dx > cx + 12) {
        pos = Offset(o.dx + 10, o.dy - tp.height / 2 - 2);
      } else {
        pos = Offset(o.dx - tp.width / 2, o.dy - tp.height - 9);
      }
      pos = Offset(pos.dx.clamp(0.0, size.width - tp.width), pos.dy);
      tp.paint(canvas, pos);
    }

    // Sun.
    final s = at(sun);
    canvas.drawCircle(s, 22, Paint()..color = progress.withValues(alpha: 0.2));
    canvas.drawCircle(s, 12, Paint()..color = progress);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.sun != sun || old.markers != markers || old.track != track || old.text != text;
}
