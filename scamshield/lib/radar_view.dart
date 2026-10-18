import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'analyzer.dart';
import 'sim.dart';
import 'theme.dart';

class ThreatRadar extends StatefulWidget {
  final ThreatSim sim;
  const ThreatRadar({super.key, required this.sim});

  @override
  State<ThreatRadar> createState() => _ThreatRadarState();
}

class _ThreatRadarState extends State<ThreatRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: CustomPaint(painter: _RadarPainter(widget.sim, _c)),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final ThreatSim sim;
  final Animation<double> anim;
  _RadarPainter(this.sim, this.anim)
      : super(repaint: Listenable.merge([anim, sim]));

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 8;
    final t = anim.value;

    // Rings and cross hairs
    final ring = Paint()
      ..color = Palette.cyan.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(c, r * i / 4, ring);
    }
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), ring);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), ring);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Palette.cyan.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Sweep
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: [
            Colors.transparent,
            Palette.cyan.withOpacity(0),
            Palette.cyan.withOpacity(0.3),
          ],
          stops: const [0.0, 0.7, 1.0],
          transform: GradientRotation(t * 2 * math.pi),
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Message blips
    final recent = sim.feed.take(16).toList();
    for (int i = 0; i < recent.length; i++) {
      final m = recent[i];
      final p = c + Offset(math.cos(m.angle), math.sin(m.angle)) * (m.radius * r);
      final fade = (1 - i * 0.045).clamp(0.25, 1.0).toDouble();
      Color col;
      double size0;
      switch (m.a.verdict) {
        case Verdict.scam:
          col = Palette.red;
          size0 = 5;
          break;
        case Verdict.suspicious:
          col = Palette.amber;
          size0 = 4;
          break;
        case Verdict.safe:
          col = Palette.green;
          size0 = 3;
          break;
      }
      if (m.a.verdict == Verdict.scam && i < 8) {
        final ph = (t + m.id * 0.13) % 1.0;
        canvas.drawCircle(
          p,
          6 + 18 * ph,
          Paint()
            ..color = col.withOpacity((1 - ph) * fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      canvas.drawCircle(
        p,
        size0 + 4,
        Paint()
          ..color = col.withOpacity(0.4 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(p, size0, Paint()..color = col.withOpacity(fade));
    }

    // Shield in the centre
    final shield = Path()
      ..moveTo(c.dx, c.dy - 16)
      ..lineTo(c.dx + 13, c.dy - 10)
      ..lineTo(c.dx + 12, c.dy + 6)
      ..lineTo(c.dx, c.dy + 17)
      ..lineTo(c.dx - 12, c.dy + 6)
      ..lineTo(c.dx - 13, c.dy - 10)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..color = Palette.cyan.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(shield, Paint()..color = const Color(0xFF07182E));
    canvas.drawPath(
      shield,
      Paint()
        ..color = Palette.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final check = Path()
      ..moveTo(c.dx - 5, c.dy)
      ..lineTo(c.dx - 1, c.dy + 4)
      ..lineTo(c.dx + 6, c.dy - 4);
    canvas.drawPath(
      check,
      Paint()
        ..color = Palette.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => false;
}
