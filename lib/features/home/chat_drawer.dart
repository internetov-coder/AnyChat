import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/presentation/settings_screen.dart';
import '../domain/models.dart';
import '../state/chat_providers.dart';
import '../state/current_chat.dart';

/// Left drawer (ChatGPT style): recent chats on top, settings at the bottom.
class ChatDrawer extends ConsumerWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chatsAsync = ref.watch(chatListProvider);
    final currentId = ref.watch(currentChatProvider).when(
          data: (int? value) => value,
          loading: () => null,
          error: (Object error, StackTrace stack) => null,
        );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: FilledButton.icon(
              onPressed: () => _startNewChat(context, ref, l10n),
              icon: const Icon(Icons.add),
              label: Text(l10n.newChat),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.recentChats,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
          Expanded(
            child: chatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) =>
                  Center(child: Text(l10n.errUnknown('$error'))),
              data: (List<Chat> chats) {
                if (chats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.chatsEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    final chat = chats[index];
                    return ListTile(
                      dense: true,
                      selected: chat.id == currentId,
                      title: Text(
                        chat.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _openChat(context, ref, chat.id),
                      trailing: PopupMenuButton<String>(
                        onSelected: (String value) {
                          if (value == 'rename') {
                            _renameChat(context, ref, l10n, chat);
                          } else if (value == 'delete') {
                            _deleteChat(context, ref, l10n, chat, currentId);
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
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.push(
                MaterialPageRoute<void>(
                  builder: (BuildContext routeContext) =>
                      const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, WidgetRef ref, int chatId) {
    Navigator.of(context).pop();
    ref.read(currentChatProvider.notifier).open(chatId);
  }

  Future<void> _startNewChat(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    Navigator.of(context).pop();
    await ref.read(currentChatProvider.notifier).startNewChat(l10n.newChat);
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
    int? currentId,
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
    if (!context.mounted) return;
    if (chat.id == currentId) {
      ref.read(currentChatProvider.notifier).closeChat();
    }
  }
}
