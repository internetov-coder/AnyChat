import 'package:flutter/material.dart';

import '../../../../core/storage/token_estimator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/app_settings.dart';
import '../../domain/models.dart';

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

Color contextStatusColor(double ratio) {
  if (ratio < 0.6) return const Color(0xFF2E7D32);
  if (ratio <= 0.85) return const Color(0xFFF9A825);
  return const Color(0xFFE53935);
}

/// Compact determinate progress ring (MD3 proportions) showing how much of
/// the context window the current conversation already uses. Meant to sit
/// inside the composer, right before the send button.
class ContextCircle extends StatelessWidget {
  const ContextCircle({
    super.key,
    required this.used,
    required this.limit,
    this.size = 30,
    this.onTap,
  });

  final int used;
  final int limit;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ratio = limit <= 0 ? 0.0 : used / limit;
    final color = contextStatusColor(ratio);
    final percent = '${(ratio.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%';

    return Tooltip(
      message: l10n.statUsed,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  backgroundColor: scheme.outlineVariant,
                  color: color,
                ),
              ),
              Text(
                percent,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      height: 1,
                      letterSpacing: -0.3,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
