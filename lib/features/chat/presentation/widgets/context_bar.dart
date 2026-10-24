import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../../../core/storage/token_estimator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/app_settings.dart';
import '../../../settings/state/settings_controller.dart';

/// Token usage strip shown at the top of the chat: used / limit with the
/// green / amber / red progress bar.
class ContextBar extends ConsumerWidget {
  const ContextBar({
    super.key,
    required this.messages,
    required this.systemPrompt,
  });

  final List<Message> messages;
  final String systemPrompt;

  static const int _defaultLimit = 128000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider).when(
          data: (AppSettings value) => value,
          loading: () => const AppSettings(),
          error: (Object error, StackTrace stack) => const AppSettings(),
        );
    final window = settings.modelContextWindow;
    final limit = window ?? _defaultLimit;
    final approximate = window == null || settings.modelContextApproximate;

    final used = estimateConversationTokens(<String>[
      if (systemPrompt.trim().isNotEmpty) systemPrompt,
      for (final message in messages)
        if (message.content.trim().isNotEmpty) message.content,
    ]);

    final ratio = limit <= 0 ? 0.0 : used / limit;
    final color = ratio < 0.6
        ? const Color(0xFF2E7D32)
        : ratio <= 0.85
            ? const Color(0xFFF9A825)
            : const Color(0xFFE53935);

    final approxSuffix = approximate ? ' · ${l10n.approximateLabel}' : '';
    final percent = '${(ratio * 100).toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${l10n.contextUsage(used, limit)}$approxSuffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Text(
                percent,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0).toDouble(),
              minHeight: 4,
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
