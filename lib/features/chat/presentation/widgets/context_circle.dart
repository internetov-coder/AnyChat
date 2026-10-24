import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'context_bar.dart';

/// Small donut above the composer showing how full the context window is;
/// tapping it opens the detailed usage/usage-stats dialog.
class ContextCircle extends StatelessWidget {
  const ContextCircle({
    super.key,
    required this.used,
    required this.limit,
    this.onTap,
  });

  final int used;
  final int limit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ratio = limit <= 0 ? 0.0 : used / limit;
    final color = contextStatusColor(ratio);
    final percent = '${(ratio * 100).toStringAsFixed(0)}%';

    return Tooltip(
      message: l10n.statUsed,
      child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: CustomPaint(
          size: const Size(36, 36),
          painter: _DonutPainter(
            ratio: ratio.clamp(0.0, 1.0).toDouble(),
            color: color,
            trackColor: scheme.surfaceContainerHighest,
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                percent,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.ratio,
    required this.color,
    required this.trackColor,
  });

  final double ratio;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 3;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    if (ratio <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90°, start at the top
      ratio * 6.2832,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
