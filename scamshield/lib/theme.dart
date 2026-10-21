import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared visual tokens for ScamShield.
///
/// The palette keeps the dark identity but deliberately reduces the neon
/// "hacker console" feeling. Higher-contrast text and calmer surfaces make the
/// product easier to read for stressed, older and non-technical users.
class Palette {
  static const bg = Color(0xFF0B1220);
  static const bgTop = Color(0xFF0B1220);
  static const surface = Color(0xFF131C2E);
  static const surfaceHi = Color(0xFF1A2540);
  static const line = Color(0xFF2A3753);

  static const text = Color(0xFFEAF0FA);
  static const dim = Color(0xFFA9B6CC);

  static const cyan = Color(0xFF4DA3FF);
  static const violet = Color(0xFF8B7CFF);
  static const green = Color(0xFF2DD4A7);
  static const amber = Color(0xFFF5B83D);
  static const red = Color(0xFFFF5A5F);

  // Compatibility aliases used by older widgets while the app is migrated.
  static const glass = surface;
  static const glassBorder = line;
}

const shieldGradient = LinearGradient(
  colors: [Palette.cyan, Palette.violet],
);
const dangerGradient = LinearGradient(
  colors: [Palette.red, Color(0xFFFF7A59)],
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
///
/// The old animated scan-line/grid was attractive but made the product feel
/// like a cyber-security console. A subtle gradient keeps the brand identity
/// without competing with urgent content.
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
          colors: [Color(0xFF0B1220), Color(0xFF0D1527)],
        ),
      ),
      child: child,
    );
  }
}

/// Standard content card.
///
/// The class keeps its historic name to avoid a noisy migration, but the
/// implementation now uses a solid high-contrast surface instead of blur/glow.
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

  RingPainter(this.value, this.color, {this.thickness = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - thickness;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progress = value.clamp(0.0, 1.0).toDouble();

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Palette.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
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
      old.value != value || old.color != color || old.thickness != thickness;
}
