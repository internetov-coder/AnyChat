import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/db.dart';
import 'core/storage/secure_storage.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/chat/data/message_repository.dart';
import 'features/providers/data/provider_config_repository.dart';

/// Root database instance (drift + drift_flutter).
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(databaseProvider)),
);

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => MessageRepository(ref.watch(databaseProvider)),
);

final providerConfigRepositoryProvider = Provider<ProviderConfigRepository>(
  (ref) => ProviderConfigRepository(ref.watch(databaseProvider)),
);

/// Device-local API key storage.
final keyStoreProvider = Provider<SecureKeyStore>((ref) => SecureKeyStore());
