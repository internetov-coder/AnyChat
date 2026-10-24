import 'package:flutter/material.dart';

/// ChatGPT-style two-line menu glyph used by the floating hamburger button.
class MenuGlyph extends StatelessWidget {
  const MenuGlyph({super.key, this.size = 20, this.color});

  /// Width of the glyph; height follows the 20:14 aspect ratio.
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.black;
    return CustomPaint(
      size: Size(size, size * 0.7),
      painter: _MenuGlyphPainter(resolved),
    );
  }
}

class _MenuGlyphPainter extends CustomPainter {
  const _MenuGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height * 0.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.55, size.height * 0.75),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MenuGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
