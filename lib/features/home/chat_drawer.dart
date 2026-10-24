import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../settings/presentation/settings_screen.dart';
import '../chat/domain/models.dart';
import '../chat/state/chat_providers.dart';
import '../chat/state/chat_session.dart';
import '../chat/state/current_chat.dart';

/// Left drawer in the ChatGPT layout: brand header with a new-chat button,
/// the recent chats list and a footer row (new-chat pill + settings).
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
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.appTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l10n.newChat,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _startNewChat(context, ref, l10n),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                          switch (value) {
                            case 'rename':
                              _renameChat(context, ref, l10n, chat);
                            case 'summarize':
                              _summarizeChat(context, ref, l10n, chat);
                            case 'prompt':
                              _chatSystemPrompt(context, ref, chat);
                            case 'delete':
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
                            value: 'summarize',
                            child: Text(l10n.handoff),
                          ),
                          PopupMenuItem<String>(
                            value: 'prompt',
                            child: Text(l10n.systemPromptLabel),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () => _startNewChat(context, ref, l10n),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.newChat),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: l10n.settingsTitle,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
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

  /// Handoff: asks the model for a summary and opens a new chat with it.
  Future<void> _summarizeChat(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Chat chat,
  ) async {
    final newChatId = await ref
        .read(chatSessionProvider.notifier)
        .summarize(chat.id, prompt: l10n.handoffPrompt);
    if (!context.mounted || newChatId == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.handoffDone)),
    );
    ref.read(currentChatProvider.notifier).open(newChatId);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _chatSystemPrompt(
    BuildContext context,
    WidgetRef ref,
    Chat chat,
  ) async {
    final controller = TextEditingController(text: chat.systemPrompt ?? '');
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          final l10n = AppLocalizations.of(dialogContext);
          return AlertDialog(
            title: Text(l10n.chatSystemPromptLabel),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(helperText: l10n.systemPromptHint),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
    if (result == null || !context.mounted) return;
    await ref.read(chatRepositoryProvider).setSystemPrompt(chat.id, result);
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
