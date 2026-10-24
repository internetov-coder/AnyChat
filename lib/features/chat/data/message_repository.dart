import 'package:drift/drift.dart';

import '../../../core/storage/db.dart';

/// Message persistence for a single chat (branches included).
class MessageRepository {
  MessageRepository(this._db);

  final AppDatabase _db;

  /// All messages of a chat across branches, ordered chronologically.
  /// The UI filters them by the active branch.
  Stream<List<Message>> watchMessages(int chatId) {
    final query = _db.select(_db.messages)
      ..where((t) => t.chatId.equals(chatId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.watch();
  }

  /// Messages of one branch in chronological order.
  Future<List<Message>> messagesInBranch(int branchId) {
    final query = _db.select(_db.messages)
      ..where((t) => t.branchId.equals(branchId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }

  Future<int> insertMessage({
    required int chatId,
    required int branchId,
    required String role,
    String content = '',
    String? model,
    int? parentId,
  }) {
    return _db.into(_db.messages).insert(
          MessagesCompanion.insert(
            chatId: chatId,
            branchId: branchId,
            parentId: Value(parentId),
            role: role,
            content: Value(content),
            model: Value(model),
          ),
        );
  }

  Future<void> setContent(int messageId, String content) {
    return (_db.update(_db.messages)..where((t) => t.id.equals(messageId)))
        .write(MessagesCompanion(content: Value(content)));
  }

  Future<void> setError(
    int messageId, {
    required String? errorType,
    required String? errorDetails,
  }) {
    return (_db.update(_db.messages)..where((t) => t.id.equals(messageId)))
        .write(
      MessagesCompanion(
        errorType: Value(errorType),
        errorDetails: Value(errorDetails),
      ),
    );
  }

  Future<void> deleteMessage(int messageId) {
    return (_db.delete(_db.messages)..where((t) => t.id.equals(messageId)))
        .go();
  }
}
