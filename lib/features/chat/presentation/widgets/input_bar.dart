import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../providers/domain/model_info.dart';
import '../../domain/models.dart';
import 'attachment_view.dart';

/// ChatGPT-style composer: one rounded capsule with the "+" attachment button
/// on the left, the message field in the middle and a circular send/stop
/// button on the right. Attachment chips float above the capsule.
class InputBar extends StatelessWidget {
  const InputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.onSend,
    required this.onStop,
    this.attachments = const <ChatAttachment>[],
    this.supportedModalities = const <ModelModality>{},
    this.onAttach,
    this.onRemoveAttachment,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final List<ChatAttachment> attachments;
  final Set<ModelModality> supportedModalities;
  final VoidCallback? onAttach;
  final ValueChanged<int>? onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final remove = onRemoveAttachment;
    final canAttach =
        !isBusy && supportedModalities.isNotEmpty && onAttach != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (var i = 0; i < attachments.length; i++)
                    AttachmentChip(
                      attachment: attachments[i],
                      onRemove: remove == null ? null : () => remove(i),
                    ),
                ],
              ),
            ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: l10n.messageInputHint,
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 12,
              ),
              prefixIcon: IconButton(
                icon: const Icon(Icons.add),
                tooltip: canAttach ? l10n.attach : l10n.unsupportedForModel,
                onPressed: canAttach ? onAttach : null,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: isBusy
                    ? IconButton.filled(
                        onPressed: onStop,
                        tooltip: l10n.stop,
                        icon: const Icon(Icons.stop),
                      )
                    : IconButton.filled(
                        onPressed: onSend,
                        tooltip: l10n.send,
                        icon: const Icon(Icons.arrow_upward),
                      ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
