import 'package:flutter/material.dart';

import '../../../../core/storage/token_estimator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/app_settings.dart';
import '../../domain/models.dart';

/// Shared context statistics for the circle indicator and its dialog.
///
/// Returns `(used, limit, approximate)` for the current settings and the
/// messages of the active branch.
({int used, int limit, bool approximate}) computeContextUsage(
  AppSettings settings,
  List<Message> messages,
  String systemPrompt,
) {
  final override = settings.contextLimit;
  final window = settings.modelContextWindow;
  final limit = (override != null && override > 0)
      ? override
      : (window ?? 128000);
  final approximate = override == null &&
      (window == null || settings.modelContextApproximate);
  final used = estimateConversationTokens(<String>[
    if (systemPrompt.trim().isNotEmpty) systemPrompt,
    for (final message in messages)
      if (message.content.trim().isNotEmpty) message.content,
  ]);
  return (used: used, limit: limit, approximate: approximate);
}

/// Green / amber / red status color for a context fill ratio.
Color contextStatusColor(double ratio) {
  if (ratio < 0.6) return const Color(0xFF2E7D32);
  if (ratio <= 0.85) return const Color(0xFFF9A825);
  return const Color(0xFFE53935);
}

/// Donut above the composer showing how full the context window is.
/// Tapping opens the detailed statistics dialog (handled by the parent).
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
            size: const Size(40, 40),
            painter: _DonutPainter(
              ratio: ratio.clamp(0.0, 1.0).toDouble(),
              color: color,
              trackColor: scheme.surfaceContainerHighest,
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  percent,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
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
