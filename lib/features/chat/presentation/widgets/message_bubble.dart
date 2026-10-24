import 'package:flutter/material.dart';

import '../../../../core/errors/api_error.dart';
import '../../../../core/errors/error_localizer.dart';
import '../../domain/models.dart';
import '../../../../l10n/app_localizations.dart';
import 'attachment_view.dart';

/// A single chat bubble: user messages use `primaryContainer`, assistant
/// messages `surfaceContainerHigh` (Material 3).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.streamingText,
    required this.isStreaming,
    required this.showRegenerate,
    this.onEdit,
    this.onBranch,
    this.onRegenerate,
  });

  final Message message;
  final String streamingText;
  final bool isStreaming;
  final bool showRegenerate;
  final VoidCallback? onEdit;
  final VoidCallback? onBranch;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUser = message.role == 'user';
    final text = isStreaming ? streamingText : message.content;
    final storedError = message.errorType;
    final error = storedError == null
        ? null
        : ApiError.fromStored(storedError, details: message.errorDetails);

    final hasActions = onEdit != null ||
        onBranch != null ||
        (onRegenerate != null && error == null);

    final generatingStyle = theme.textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
      color: scheme.onSurfaceVariant,
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            if (message.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final attachment in message.attachments)
                      AttachmentPreview(attachment: attachment),
                  ],
                ),
              ),
            if (isStreaming)
              text.isEmpty
                  ? Text(l10n.generating, style: generatingStyle)
                  : Text(text)
            else if (message.content.isNotEmpty)
              SelectableText(message.content)
            else if (error == null)
              Text(l10n.generating, style: generatingStyle),
            if (error != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                localizeApiError(l10n, error),
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
              if (showRegenerate)
                TextButton.icon(
                  onPressed: onRegenerate,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.retry),
                ),
            ],
            if (hasActions)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      tooltip: l10n.editMessage,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (onBranch != null)
                    IconButton(
                      onPressed: onBranch,
                      tooltip: l10n.branchFromHere,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.account_tree_outlined),
                    ),
                  if (onRegenerate != null && error == null)
                    IconButton(
                      onPressed: onRegenerate,
                      tooltip: l10n.regenerate,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
