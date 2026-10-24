import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/errors/api_error.dart';
import '../../../../core/errors/error_localizer.dart';
import '../../domain/models.dart';
import '../../../../l10n/app_localizations.dart';
import 'attachment_view.dart';

/// A single message row (ChatGPT style): the user's own message is a
/// rounded `primaryContainer` bubble, assistant/system replies are plain
/// rendered Markdown directly on the background.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.streamingText,
    required this.isStreaming,
    required this.isLast,
    required this.showRegenerate,
    this.onEdit,
    this.onBranch,
    this.onRegenerate,
  });

  final Message message;
  final String streamingText;
  final bool isStreaming;
  final bool isLast;
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

    final showCopy =
        isLast && !isStreaming && message.content.trim().isNotEmpty;
    final showBranch = onBranch != null && isLast;
    final hasActions = showCopy ||
        onEdit != null ||
        showBranch ||
        (onRegenerate != null && error == null);

    final generatingStyle = theme.textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
      color: scheme.onSurfaceVariant,
    );

    final body = Column(
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
              : _MessageBody(
                  content: text,
                  isUser: isUser,
                  streaming: isStreaming,
                )
        else if (message.content.isNotEmpty)
          _MessageBody(content: message.content, isUser: isUser)
        else if (error == null)
          Text(l10n.generating, style: generatingStyle),
        if (error != null) ...<Widget>[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.error_outline,
                  size: 15,
                  color: scheme.error,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  localizeApiError(l10n, error),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.error),
                ),
              ),
            ],
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
              if (showCopy)
                IconButton(
                  onPressed: () => _copyContent(context, message.content),
                  tooltip: l10n.copy,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  color: scheme.onSurfaceVariant,
                  icon: const Icon(Icons.content_copy),
                ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  tooltip: l10n.editMessage,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  color: scheme.onSurfaceVariant,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (showBranch)
                IconButton(
                  onPressed: onBranch,
                  tooltip: l10n.branchFromHere,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  color: scheme.onSurfaceVariant,
                  icon: const Icon(Icons.account_tree_outlined),
                ),
              if (onRegenerate != null && error == null)
                IconButton(
                  onPressed: onRegenerate,
                  tooltip: l10n.regenerate,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  color: scheme.onSurfaceVariant,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
      ],
    );

    if (!isUser) {
      // Assistant/system replies: plain on the background, like ChatGPT.
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 3, 12, 3),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.88,
          ),
          child: body,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: body,
      ),
    );
  }

  Future<void> _copyContent(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copied),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// Message text: plain selectable text for the user's own messages and
/// rendered Markdown for assistant (and system) replies, with a live
/// cursor while the answer is still streaming.
class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.content,
    required this.isUser,
    this.streaming = false,
  });

  final String content;
  final bool isUser;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return SelectableText(content);
    }
    final theme = Theme.of(context);
    final data = streaming ? '$content▌' : content;
    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: theme.textTheme.bodyMedium,
        code: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        blockquoteDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.outline,
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}
