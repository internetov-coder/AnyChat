/// Domain models for the chat feature.
///
/// AnyChat persists chats with drift; the generated row classes are immutable
/// value types and double as the domain models.
export '../../../core/storage/db.dart' show Chat, Message, Branch;

/// Derives a chat title from the first user message: whitespace-normalized
/// and cut at a word boundary around 40 characters.
String deriveChatTitle(String text) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return 'New chat';
  if (normalized.length <= 40) return normalized;
  final cut = normalized.substring(0, 40);
  final lastSpace = cut.lastIndexOf(' ');
  if (lastSpace > 10) return cut.substring(0, lastSpace).trimRight();
  return cut.trimRight();
}
