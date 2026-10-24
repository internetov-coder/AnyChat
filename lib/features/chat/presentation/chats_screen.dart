import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/models.dart';
import '../state/chat_providers.dart';
import 'chat_screen.dart';

/// The list of chats with create / rename / delete actions.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chatsAsync = ref.watch(chatListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navChats)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newChat,
        onPressed: () => _openNewChat(context, ref, l10n),
        child: const Icon(Icons.add),
      ),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            Center(child: Text(l10n.errUnknown('$error'))),
        data: (List<Chat> chats) {
          if (chats.isEmpty) {
            return Center(child: Text(l10n.chatsEmpty));
          }
          final dateFormat = DateFormat('dd.MM.yyyy HH:mm', l10n.localeName);
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (BuildContext ctx, int index) =>
                const Divider(height: 1),
            itemBuilder: (BuildContext ctx, int index) {
              final chat = chats[index];
              return ListTile(
                title: Text(
                  chat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(dateFormat.format(chat.createdAt)),
                trailing: PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'rename') {
                      _renameChat(context, ref, l10n, chat);
                    } else if (value == 'delete') {
                      _deleteChat(context, ref, l10n, chat);
                    }
                  },
                  itemBuilder: (BuildContext menuContext) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'rename',
                      child: Text(l10n.renameChat),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(l10n.deleteChat),
                    ),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext routeContext) =>
                        ChatScreen(chatId: chat.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openNewChat(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final created =
        await ref.read(chatRepositoryProvider).createChat(title: l10n.newChat);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) =>
            ChatScreen(chatId: created.chatId),
      ),
    );
  }

  Future<void> _renameChat(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Chat chat,
  ) async {
    final controller = TextEditingController(text: chat.title);
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          final dialogL10n = AppLocalizations.of(dialogContext);
          return AlertDialog(
            title: Text(dialogL10n.renameChat),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: dialogL10n.chatNameLabel,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(dialogL10n.cancel),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text),
                child: Text(dialogL10n.save),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
    final title = result?.trim();
    if (title == null || title.isEmpty || !context.mounted) return;
    await ref.read(chatRepositoryProvider).renameChat(chat.id, title);
  }

  Future<void> _deleteChat(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Chat chat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.deleteChat),
          content: Text(chat.title),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogL10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(chatRepositoryProvider).deleteChat(chat.id);
  }
}
