import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class Palette {
  static const bg = Color(0xFF05070F);
  static const bgTop = Color(0xFF0A1530);
  static const cyan = Color(0xFF00E5FF);
  static const violet = Color(0xFF7C5CFF);
  static const green = Color(0xFF2BFFA0);
  static const amber = Color(0xFFFFB020);
  static const red = Color(0xFFFF2E63);
  static const text = Color(0xFFE8F0FF);
  static const dim = Color(0xFF8091B5);
  static const glass = Color(0x12FFFFFF);
  static const glassBorder = Color(0x22FFFFFF);
}

const shieldGradient = LinearGradient(colors: [Palette.cyan, Palette.violet]);
const dangerGradient =
    LinearGradient(colors: [Palette.red, Color(0xFFFF7A59)]);

void drawText(Canvas canvas, String s, Offset center, double size, Color color,
    {FontWeight weight = FontWeight.w600, double letterSpacing = 0}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// Dark cyber grid with a scan line sweeping down the screen.
class CyberBackground extends StatefulWidget {
  final Widget child;
  const CyberBackground({super.key, required this.child});

  @override
  State<CyberBackground> createState() => _CyberBackgroundState();
}

class _CyberBackgroundState extends State<CyberBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.bgTop, Palette.bg],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _GridPainter(_c)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Animation<double> anim;
  _GridPainter(this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final y = size.height * anim.value;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 60, size.width, 60),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.cyan.withOpacity(0), Palette.cyan.withOpacity(0.07)],
        ).createShader(Rect.fromLTWH(0, y - 60, size.width, 60)),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = Palette.cyan.withOpacity(0.18)
        ..strokeWidth = 1.2,
    );
    for (final o in [
      Offset(size.width * 0.9, size.height * 0.06),
      Offset(size.width * 0.05, size.height * 0.9),
    ]) {
      canvas.drawCircle(
        o,
        250,
        Paint()
          ..shader = RadialGradient(colors: [
            Palette.violet.withOpacity(0.16),
            Palette.violet.withOpacity(0),
          ]).createShader(Rect.fromCircle(center: o, radius: 250)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? tint;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? Palette.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor ?? Palette.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Gradient gradient;
  final Color glow;

  const GlowButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.gradient = shieldGradient,
    this.glow = Palette.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: glow.withOpacity(0.4), blurRadius: 22)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final double thickness;
  RingPainter(this.value, this.color, {this.thickness = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - thickness;
    final rect = Rect.fromCircle(center: c, radius: radius);
    final v = value.clamp(0.0, 1.0).toDouble();
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = const Color(0x1AFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * v,
      false,
      Paint()
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * v,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter old) =>
      old.value != value || old.color != color;
}
