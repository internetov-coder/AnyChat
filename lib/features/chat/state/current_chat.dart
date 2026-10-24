import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app_providers.dart';

part 'current_chat.g.dart';

@Riverpod(keepAlive: true)
class CurrentChat extends _$CurrentChat {
  @override
  Future<int?> build() async {
    final chats = await ref.read(chatRepositoryProvider).watchChats().first;
    if (chats.isEmpty) {
      return null;
    }
    return chats.first.id;
  }

  void open(int chatId) {
    state = AsyncData(chatId);
  }

  Future<void> startNewChat(String title) async {
    final created =
        await ref.read(chatRepositoryProvider).createChat(title: title);
    state = AsyncData(created.chatId);
  }

  void closeChat() {
    state = const AsyncData(null);
  }
}
