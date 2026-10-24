import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Message input: filled `TextField` with `extraLarge` (28dp) rounding and a
/// `FilledIconButton` on the right (send / stop while streaming).
class InputBar extends StatelessWidget {
  const InputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: TextField(
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
          suffixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: isBusy
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
          ),
        ),
      ),
    );
  }
}
