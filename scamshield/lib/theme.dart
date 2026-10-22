import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared visual tokens for ScamShield.
///
/// The palette uses a calm navy base with high-contrast text so urgent content
/// is easy to read without making the whole product feel like a cyber console.
class Palette {
  static const bg = Color(0xFF0B1220);
  static const bgTop = Color(0xFF0B1220);
  static const surface = Color(0xFF111B2E);
  static const surfaceHi = Color(0xFF16233A);
  static const line = Color(0xFF2B3A55);

  static const text = Color(0xFFF1F5F9);
  static const dim = Color(0xFFB8C4D9);
  static const muted = Color(0xFF94A3B8);

  static const cyan = Color(0xFF60A5FA);
  static const violet = Color(0xFF93C5FD);
  static const green = Color(0xFF2DD4A7);
  static const amber = Color(0xFFF5B83D);
  static const red = Color(0xFFEF4444);

  // Compatibility aliases used by older widgets while the app is migrated.
  static const glass = surface;
  static const glassBorder = line;
}

const shieldGradient = LinearGradient(
  colors: [Palette.cyan, Palette.violet],
);
const dangerGradient = LinearGradient(
  colors: [Palette.red, Color(0xFFF87171)],
);

void drawText(
  Canvas canvas,
  String text,
  Offset center,
  double size,
  Color color, {
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 0,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

/// Calm dark background used across the app.
class CyberBackground extends StatelessWidget {
  final Widget child;
  const CyberBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1220), Color(0xFF0D1627)],
        ),
      ),
      child: child,
    );
  }
}

/// Standard content card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Palette.line),
      ),
      child: child,
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
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
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

  const RingPainter(
    this.value,
    this.color, {
    this.thickness = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - thickness;
    final base = Paint()
      ..color = Palette.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.thickness != thickness;
}
