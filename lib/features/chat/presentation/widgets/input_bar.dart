import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../providers/domain/model_info.dart';
import '../../domain/models.dart';
import 'attachment_view.dart';

/// Message input: filled `TextField` with `extraLarge` (28dp) rounding,
/// attachment chip row and a filled icon button on the right
/// (send / stop while streaming). The attach button is disabled when the
/// current model accepts no media at all.
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
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    tooltip:
                        canAttach ? l10n.attach : l10n.unsupportedForModel,
                    onPressed: canAttach ? onAttach : null,
                  ),
                  isBusy
                      ? IconButton.filled(
                          onPressed: onStop,
                          tooltip: l10n.stop,
                          icon: const Icon(Icons.stop),
                        )
                      : IconButton.filled(
                          onPressed: onSend,
                          tooltip: l10n.send,
                          icon: const Icon(Icons.send),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
