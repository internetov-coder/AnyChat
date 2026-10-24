import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../chat/presentation/chat_screen.dart';
import '../chat/state/current_chat.dart';
import 'chat_drawer.dart';

/// ChatGPT-style entry point: opens straight into the current chat.
///
/// The hamburger in the chat's app bar opens [ChatDrawer] with recent chats
/// and the settings entry point; when there is no chat yet, a "new chat"
/// home is shown.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(currentChatProvider);
    return current.when<Widget>(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: Center(child: Text(l10n.errUnknown('$error'))),
      ),
      data: (int? chatId) {
        if (chatId == null) {
          return _EmptyHome(l10n: l10n);
        }
        return ChatScreen(key: ValueKey<int>(chatId), chatId: chatId);
      },
    );
  }
}

class _EmptyHome extends ConsumerWidget {
  const _EmptyHome({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const ChatDrawer(),
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.chat_bubble_outline,
                size: 72,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(l10n.appTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                l10n.emptyChatHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await ref
                      .read(currentChatProvider.notifier)
                      .startNewChat(l10n.newChat);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.newChat),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
