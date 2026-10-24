import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app_providers.dart';
import '../domain/models.dart';

part 'chat_providers.g.dart';

@riverpod
Stream<List<Chat>> chatList(Ref ref) =>
    ref.watch(chatRepositoryProvider).watchChats();

@riverpod
Stream<Chat?> chatById(Ref ref, int chatId) =>
    ref.watch(chatRepositoryProvider).watchChat(chatId);

@riverpod
Stream<List<Branch>> chatBranches(Ref ref, int chatId) =>
    ref.watch(chatRepositoryProvider).watchBranches(chatId);

@riverpod
Stream<List<Message>> chatMessages(Ref ref, int chatId) =>
    ref.watch(messageRepositoryProvider).watchMessages(chatId);
