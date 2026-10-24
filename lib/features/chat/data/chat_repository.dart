import 'package:drift/drift.dart';

import '../../../core/storage/db.dart';
import '../domain/models.dart' as dm;

class ChatRepository {
  ChatRepository(this._db);

  final AppDatabase _db;

  Stream<List<dm.Chat>> watchChats() {
    final query = _db.select(_db.chats)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(dm.Chat.fromRow).toList());
  }

  Stream<dm.Chat?> watchChat(int chatId) {
    final query = _db.select(_db.chats)..where((t) => t.id.equals(chatId));
    return query
        .watchSingleOrNull()
        .map((row) => row == null ? null : dm.Chat.fromRow(row));
  }

  Future<dm.Chat?> getChat(int chatId) {
    final query = _db.select(_db.chats)..where((t) => t.id.equals(chatId));
    return query
        .getSingleOrNull()
        .then((row) => row == null ? null : dm.Chat.fromRow(row));
  }

  Future<({int chatId, int branchId})> createChat({
    required String title,
    String? systemPrompt,
  }) {
    return _db.transaction(() async {
      final chatId = await _db.into(_db.chats).insert(
            ChatsCompanion.insert(
              title: Value(title),
              systemPrompt: Value(systemPrompt),
            ),
          );
      final branchId = await _db
          .into(_db.branches)
          .insert(BranchesCompanion.insert(chatId: chatId));
      await (_db.update(_db.chats)..where((t) => t.id.equals(chatId)))
          .write(ChatsCompanion(activeBranchId: Value(branchId)));
      return (chatId: chatId, branchId: branchId);
    });
  }

  Future<void> renameChat(int chatId, String title) {
    return (_db.update(_db.chats)..where((t) => t.id.equals(chatId)))
        .write(ChatsCompanion(title: Value(title)));
  }

  Future<void> setSystemPrompt(int chatId, String? prompt) {
    final normalized = (prompt ?? '').trim();
    return (_db.update(_db.chats)..where((t) => t.id.equals(chatId)))
        .write(ChatsCompanion(systemPrompt: Value(normalized.isEmpty ? null : normalized)));
  }

  Future<void> deleteChat(int chatId) {
    return _db.transaction(() async {
      await (_db.delete(_db.messages)..where((t) => t.chatId.equals(chatId)))
          .go();
      await (_db.delete(_db.branches)..where((t) => t.chatId.equals(chatId)))
          .go();
      await (_db.delete(_db.chats)..where((t) => t.id.equals(chatId))).go();
    });
  }

  Future<void> setUsage(
    int chatId, {
    required int input,
    required int output,
    required int thinking,
  }) {
    return (_db.update(_db.chats)..where((t) => t.id.equals(chatId))).write(
      ChatsCompanion(
        usageInput: Value(input),
        usageOutput: Value(output),
        usageThinking: Value(thinking),
      ),
    );
  }

  Future<void> setActiveBranch(int chatId, int branchId) {
    return (_db.update(_db.chats)..where((t) => t.id.equals(chatId)))
        .write(ChatsCompanion(activeBranchId: Value(branchId)));
  }

  Future<int> ensureActiveBranch(int chatId, dm.Chat chat) async {
    final existing = chat.activeBranchId;
    if (existing != null) return existing;
    final branchId = await _db
        .into(_db.branches)
        .insert(BranchesCompanion.insert(chatId: chatId));
    await setActiveBranch(chatId, branchId);
    return branchId;
  }

  Stream<List<dm.Branch>> watchBranches(int chatId) {
    final query = _db.select(_db.branches)
      ..where((t) => t.chatId.equals(chatId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.watch().map((rows) => rows.map(dm.Branch.fromRow).toList());
  }

  Future<List<dm.Branch>> getBranches(int chatId) {
    final query = _db.select(_db.branches)
      ..where((t) => t.chatId.equals(chatId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get().then((rows) => rows.map(dm.Branch.fromRow).toList());
  }

  Future<int> forkBranchFrom({
    required int chatId,
    required int sourceBranchId,
    required int messageId,
    required String name,
  }) {
    return _fork(
      chatId: chatId,
      sourceBranchId: sourceBranchId,
      name: name,
      forkedFromMessageId: messageId,
      include: (t) => t.id.isSmallerOrEqualValue(messageId),
    );
  }

  Future<int> forkBranchBefore({
    required int chatId,
    required int sourceBranchId,
    required int messageId,
    required String name,
  }) {
    return _fork(
      chatId: chatId,
      sourceBranchId: sourceBranchId,
      name: name,
      forkedFromMessageId: messageId,
      include: (t) => t.id.isSmallerThanValue(messageId),
    );
  }

  Future<int> _fork({
    required int chatId,
    required int sourceBranchId,
    required String name,
    required int forkedFromMessageId,
    required Expression<bool> Function(Messages t) include,
  }) {
    return _db.transaction(() async {
      final newBranchId = await _db.into(_db.branches).insert(
            BranchesCompanion.insert(
              chatId: chatId,
              name: Value(name),
              forkedFromMessageId: Value(forkedFromMessageId),
            ),
          );
      final query = _db.select(_db.messages)
        ..where((t) => t.branchId.equals(sourceBranchId) & include(t))
        ..orderBy([(t) => OrderingTerm.asc(t.id)]);
      final sourceMessages = await query.get();
      final idMap = <int, int>{};
      for (final message in sourceMessages) {
        final newId = await _db.into(_db.messages).insert(
              MessagesCompanion.insert(
                chatId: message.chatId,
                branchId: newBranchId,
                parentId: Value(
                  message.parentId == null ? null : idMap[message.parentId],
                ),
                role: message.role,
                content: Value(message.content),
                model: Value(message.model),
                errorType: Value(message.errorType),
                errorDetails: Value(message.errorDetails),
                attachments: Value(message.attachments),
                createdAt: Value(message.createdAt),
              ),
            );
        idMap[message.id] = newId;
      }
      await (_db.update(_db.chats)..where((t) => t.id.equals(chatId)))
          .write(ChatsCompanion(activeBranchId: Value(newBranchId)));
      return newBranchId;
    });
  }
}
