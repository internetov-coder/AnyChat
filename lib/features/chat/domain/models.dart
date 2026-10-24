import '../../../core/storage/db.dart' as db;

/// Domain models for the chat feature.
///
/// Deliberately hand-written instead of reusing the drift row classes:
/// `riverpod_generator` cannot resolve types generated into `db.g.dart`
/// (a `part` file), which failed with `InvalidTypeException` during
/// code generation. Repositories map rows via the `fromRow` factories.
class Chat {
  const Chat({
    required this.id,
    required this.title,
    this.systemPrompt,
    this.activeBranchId,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String? systemPrompt;
  final int? activeBranchId;
  final DateTime createdAt;

  factory Chat.fromRow(db.Chat row) => Chat(
        id: row.id,
        title: row.title,
        systemPrompt: row.systemPrompt,
        activeBranchId: row.activeBranchId,
        createdAt: row.createdAt,
      );
}

class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.branchId,
    this.parentId,
    required this.role,
    this.content = '',
    this.model,
    this.errorType,
    this.errorDetails,
    required this.createdAt,
  });

  final int id;
  final int chatId;
  final int branchId;
  final int? parentId;

  /// `system`, `user` or `assistant`.
  final String role;
  final String content;
  final String? model;

  /// [ApiErrorType.name] of the last failure, if the reply failed.
  final String? errorType;
  final String? errorDetails;
  final DateTime createdAt;

  factory Message.fromRow(db.Message row) => Message(
        id: row.id,
        chatId: row.chatId,
        branchId: row.branchId,
        parentId: row.parentId,
        role: row.role,
        content: row.content,
        model: row.model,
        errorType: row.errorType,
        errorDetails: row.errorDetails,
        createdAt: row.createdAt,
      );
}

class Branch {
  const Branch({
    required this.id,
    required this.chatId,
    this.name = 'main',
    this.forkedFromMessageId,
    required this.createdAt,
  });

  final int id;
  final int chatId;
  final String name;
  final int? forkedFromMessageId;
  final DateTime createdAt;

  factory Branch.fromRow(db.Branch row) => Branch(
        id: row.id,
        chatId: row.chatId,
        name: row.name,
        forkedFromMessageId: row.forkedFromMessageId,
        createdAt: row.createdAt,
      );
}

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
