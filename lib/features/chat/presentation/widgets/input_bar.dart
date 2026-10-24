import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../providers/domain/model_info.dart';
import '../../domain/models.dart';
import 'attachment_view.dart';

class InputBar extends StatefulWidget {
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
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final remove = widget.onRemoveAttachment;
    final canAttach = !widget.isBusy &&
        widget.supportedModalities.isNotEmpty &&
        widget.onAttach != null;
    final sendReady = _hasText && !widget.isBusy;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (var i = 0; i < widget.attachments.length; i++)
                    AttachmentChip(
                      attachment: widget.attachments[i],
                      onRemove: remove == null ? null : () => remove(i),
                    ),
                ],
              ),
            ),
          Stack(
            children: <Widget>[
              TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.messageInputHint,
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.fromLTRB(4, 14, 52, 14),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    tooltip:
                        canAttach ? l10n.attach : l10n.unsupportedForModel,
                    onPressed: canAttach ? widget.onAttach : null,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 4,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: widget.isBusy
                      ? IconButton(
                          onPressed: widget.onStop,
                          tooltip: l10n.stop,
                          icon: const Icon(Icons.stop),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.error,
                            foregroundColor: scheme.onError,
                          ),
                        )
                      : IconButton(
                          onPressed: widget.onSend,
                          tooltip: l10n.send,
                          icon: const Icon(Icons.arrow_upward),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: sendReady
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            foregroundColor: sendReady
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
