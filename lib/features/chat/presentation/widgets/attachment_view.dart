import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models.dart';

final Map<String, MemoryImage> _imageCache = <String, MemoryImage>{};

MemoryImage? _imageFor(ChatAttachment attachment) {
  final cached = _imageCache[attachment.data];
  if (cached != null) return cached;
  try {
    if (_imageCache.length >= 32) {
      _imageCache.clear();
    }
    final image = MemoryImage(base64Decode(attachment.data));
    _imageCache[attachment.data] = image;
    return image;
  } catch (_) {
    return null;
  }
}

IconData iconForAttachment(ChatAttachment attachment) {
  if (attachment.isVideo) return Icons.videocam;
  if (attachment.isAudio) return Icons.music_note;
  if (attachment.isImage) return Icons.image;
  return Icons.attach_file;
}

class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({super.key, required this.attachment});

  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = attachment.isImage ? _imageFor(attachment) : null;
    if (image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(
          image: image,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext ctx, Object error, StackTrace? stack) =>
              _fileCard(theme),
        ),
      );
    }
    return _fileCard(theme);
  }

  Widget _fileCard(ThemeData theme) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(iconForAttachment(attachment), size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class AttachmentChip extends StatelessWidget {
  const AttachmentChip({
    super.key,
    required this.attachment,
    this.onRemove,
  });

  final ChatAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final image = attachment.isImage ? _imageFor(attachment) : null;
    return SizedBox(
      width: 170,
      child: InputChip(
        avatar: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image(
                  image: image,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (BuildContext ctx, Object error, StackTrace? stack) =>
                          Icon(iconForAttachment(attachment), size: 18),
                ),
              )
            : Icon(iconForAttachment(attachment), size: 18),
        label: Text(
          attachment.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onDeleted: onRemove,
        deleteButtonTooltipMessage: l10n.removeAttachment,
      ),
    );
  }
}
