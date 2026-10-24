import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

class Chats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant('New chat'))();
  TextColumn get systemPrompt => text().nullable()();
  IntColumn get activeBranchId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Cumulative usage reported by the provider (or estimated locally).
  IntColumn get usageInput => integer().withDefault(const Constant(0))();
  IntColumn get usageOutput => integer().withDefault(const Constant(0))();
  IntColumn get usageThinking => integer().withDefault(const Constant(0))();
}

@DataClassName('Branch')
class Branches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chatId => integer()();
  TextColumn get name => text().withDefault(const Constant('main'))();
  IntColumn get forkedFromMessageId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chatId => integer()();
  IntColumn get branchId => integer()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get role => text()();
  TextColumn get content => text().withDefault(const Constant(''))();

  /// JSON array of {@link ChatAttachment} objects (base64 payloads) —
  /// added in schema v2 for multimodal input.
  TextColumn get attachments => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get errorType => text().nullable()();
  TextColumn get errorDetails => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Stored in the `providers_config` table (never holds API keys).
@DataClassName('ProviderConfig')
class ProvidersConfig extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get providerId => text().unique()();
  TextColumn get baseUrlOverride => text().nullable()();
}

@DriftDatabase(tables: [Chats, Messages, Branches, ProvidersConfig])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'anychat'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(messages, messages.attachments);
          }
          if (from < 3) {
            await m.addColumn(chats, chats.usageInput);
            await m.addColumn(chats, chats.usageOutput);
            await m.addColumn(chats, chats.usageThinking);
          }
        },
      );
}
