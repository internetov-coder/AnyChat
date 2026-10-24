import 'package:flutter/material.dart';

import '../../../settings/app_settings.dart';
import '../../../../core/storage/token_estimator.dart';
import '../../../../core/storage/db.dart';

/// Shared context statistics for the strip and the detail circle.
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

/// Slim token usage strip above the chat: `12.4K / 128K` + percent and a
/// 3px progress bar.
class ContextBar extends StatelessWidget {
  const ContextBar({
    super.key,
    required this.used,
    required this.limit,
    required this.approximate,
  });

  final int used;
  final int limit;
  final bool approximate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ratio = limit <= 0 ? 0.0 : used / limit;
    final color = contextStatusColor(ratio);
    final approxSuffix = approximate ? ' · ${l10n.approximateLabel}' : '';
    final percent = '${(ratio * 100).toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${l10n.contextUsage(
                    formatTokenCount(used),
                    formatTokenCount(limit),
                  )}$approxSuffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(height: 1.2),
                ),
              ),
              Text(
                percent,
                style: theme.textTheme.labelSmall?.copyWith(height: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0).toDouble(),
              minHeight: 3,
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
