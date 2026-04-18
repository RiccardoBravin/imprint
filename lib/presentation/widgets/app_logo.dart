import 'package:flutter/material.dart';

/// The imprint icon mark: rounded square with fork-and-pen motif.
/// Adapts automatically to light/dark theme.
class ImprintIcon extends StatelessWidget {
  const ImprintIcon({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size(size, size),
      painter: _ImprintIconPainter(isDark: isDark),
    );
  }
}

/// The full horizontal lockup: icon mark + "imprint" wordmark.
class ImprintLogo extends StatelessWidget {
  const ImprintLogo({super.key, this.iconSize = 64});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ImprintIcon(size: iconSize),
        SizedBox(width: iconSize * 0.22),
        Text(
          'imprint',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: iconSize * 0.75,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _ImprintIconPainter extends CustomPainter {
  const _ImprintIconPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final bgColor = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final fgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    // Rounded square background
    final bgPaint = Paint()..color = bgColor;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.19),
    );
    canvas.drawRRect(rr, bgPaint);

    // All strokes use foreground color
    final stroke = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = fgColor
      ..style = PaintingStyle.fill;

    // ── Fork (left side) ────────────────────────────────────────────────────
    // Positioned at ~37% from left, tines from 26%..58% vertically
    final forkX = s * 0.37; // center of fork group
    final tineTop = s * 0.175;
    final tineBot = s * 0.385;
    final tineSpacing = s * 0.06;

    stroke.strokeWidth = s * 0.038;

    // Three tines
    for (final dx in [-tineSpacing, 0.0, tineSpacing]) {
      canvas.drawLine(
        Offset(forkX + dx, tineTop),
        Offset(forkX + dx, tineBot),
        stroke,
      );
    }

    // Fork neck curve
    final neckPath = Path()
      ..moveTo(forkX - tineSpacing, tineBot)
      ..quadraticBezierTo(forkX - tineSpacing, tineBot + s * 0.1, forkX, tineBot + s * 0.13)
      ..quadraticBezierTo(forkX + tineSpacing, tineBot + s * 0.1, forkX + tineSpacing, tineBot);
    canvas.drawPath(neckPath, stroke);

    // Fork handle
    canvas.drawLine(
      Offset(forkX, tineBot + s * 0.13),
      Offset(forkX, s * 0.82),
      stroke,
    );

    // ── Pen/nib (right side) ────────────────────────────────────────────────
    final penX = s * 0.63;
    final penTop = s * 0.175;
    final penNibTop = s * 0.62;
    final penTipY = s * 0.73;

    // Pen body
    canvas.drawLine(Offset(penX, penTop), Offset(penX, penNibTop), stroke);

    // Nib triangle
    final nibPath = Path()
      ..moveTo(penX - s * 0.06, penNibTop)
      ..lineTo(penX, penTipY)
      ..lineTo(penX + s * 0.06, penNibTop)
      ..close();
    canvas.drawPath(nibPath, fill);

    // Pen clip line (subtle)
    final clipPaint = Paint()
      ..color = fgColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.025;
    canvas.drawLine(
      Offset(penX + s * 0.044, penTop + s * 0.025),
      Offset(penX + s * 0.044, penNibTop - s * 0.05),
      clipPaint,
    );

    // Ink dot
    final dotPaint = Paint()
      ..color = fgColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(penX, penTipY + s * 0.025), s * 0.022, dotPaint);
  }

  @override
  bool shouldRepaint(_ImprintIconPainter old) => old.isDark != isDark;
}
