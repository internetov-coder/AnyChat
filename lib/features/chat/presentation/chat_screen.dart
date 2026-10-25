import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_localizer.dart';
import '../../../core/storage/token_estimator.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/chat_drawer.dart';
import '../../settings/app_settings.dart';
import '../../settings/state/settings_controller.dart';
import '../domain/models.dart';
import '../state/chat_providers.dart';
import '../state/chat_session.dart';
import '../state/current_chat.dart';
import 'widgets/chat_composer.dart';
import 'widgets/context_circle.dart';
import 'widgets/menu_glyph.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final int chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  Future<void> _editMessage(Message message) async {
    final controller = TextEditingController(text: message.content);
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          final l10n = AppLocalizations.of(dialogContext);
          return AlertDialog(
            title: Text(l10n.editMessageTitle),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(helperText: l10n.editMessageHint),
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
    final edited = result?.trim();
    if (edited == null || edited.isEmpty || !mounted) return;
    if (edited == message.content) return;
    await ref
        .read(chatSessionProvider.notifier)
        .editMessage(widget.chatId, message.id, edited);
  }

  Future<void> _branchFrom(Message message) async {
    await ref
        .read(chatSessionProvider.notifier)
        .branchFrom(widget.chatId, message.id);
  }

  Future<void> _startNewChat() async {
    final l10n = AppLocalizations.of(context);
    await ref.read(currentChatProvider.notifier).startNewChat(l10n.newChat);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chatAsync = ref.watch(chatByIdProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final branchesAsync = ref.watch(chatBranchesProvider(widget.chatId));
    final session = ref.watch(chatSessionProvider);

    ref.listen<ChatSessionState>(
      chatSessionProvider,
      (ChatSessionState? previous, ChatSessionState next) {
        if (!next.hasFailure) return;
        final sameError = previous != null &&
            identical(previous.lastError, next.lastError) &&
            identical(previous.lastIssue, next.lastIssue);
        if (sameError) return;
        final issue = next.lastIssue;
        final error = next.lastError;
        final String message;
        if (issue != null) {
          message = _issueMessage(l10n, issue);
        } else if (error != null) {
          message = localizeApiError(l10n, error);
        } else {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );

    final branches = branchesAsync.when(
      data: (List<Branch> value) => value,
      loading: () => <Branch>[],
      error: (Object error, StackTrace stack) => <Branch>[],
    );

    return chatAsync.when<Widget>(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        body: Center(child: Text(l10n.errUnknown('$error'))),
      ),
      data: (Chat? chat) {
        if (chat == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(currentChatProvider.notifier).closeChat();
            }
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return Scaffold(
          drawer: const ChatDrawer(),
          body: Builder(
            builder: (BuildContext scaffoldContext) => SafeArea(
              child: Stack(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      if (session.busy)
                        const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: 56),
                      Expanded(
                        child: messagesAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (Object error, StackTrace stack) => Center(
                            child: Text(l10n.errUnknown('$error')),
                          ),
                          data: (List<Message> allMessages) => _buildChatBody(
                            l10n,
                            chat,
                            allMessages,
                            branches,
                            session,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton.filledTonal(
                      tooltip: l10n.menu,
                      icon: const MenuGlyph(),
                      onPressed: () =>
                          Scaffold.of(scaffoldContext).openDrawer(),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      tooltip: l10n.newChat,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: _startNewChat,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatBody(
    AppLocalizations l10n,
    Chat chat,
    List<Message> allMessages,
    List<Branch> branches,
    ChatSessionState session,
  ) {
    final branchId = chat.activeBranchId;
    final messages = branchId == null
        ? <Message>[]
        : allMessages
            .where((Message message) => message.branchId == branchId)
            .toList();

    final settings = ref.watch(settingsControllerProvider).when(
          data: (AppSettings value) => value,
          loading: () => const AppSettings(),
          error: (Object error, StackTrace stack) => const AppSettings(),
        );
    final chatPrompt = chat.systemPrompt;
    final systemPrompt = (chatPrompt != null && chatPrompt.trim().isNotEmpty)
        ? chatPrompt
        : settings.systemPrompt;

    final usage = computeContextUsage(settings, messages, systemPrompt);
    final reversed = messages.reversed.toList();

    return Column(
      children: <Widget>[
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    l10n.startWith,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: reversed.length,
                  itemBuilder: (BuildContext itemContext, int index) {
                    final message = reversed[index];
                    final isLast = index == 0;
                    final isAssistant = message.role == 'assistant';
                    final isStreaming = session.isStreaming &&
                        session.streamingMessageId == message.id;
                    final canRegenerate = isLast && isAssistant;
                    BranchPager? branchPager;
                    if (isLast &&
                        branches.length > 1 &&
                        !session.isStreaming &&
                        !session.busy) {
                      var index = branches
                          .indexWhere((Branch b) => b.id == chat.activeBranchId);
                      if (index < 0) index = 0;
                      branchPager = (
                        current: index + 1,
                        total: branches.length,
                        onPrev: index > 0
                            ? () => _switchTo(branches[index - 1].id)
                            : null,
                        onNext: index < branches.length - 1
                            ? () => _switchTo(branches[index + 1].id)
                            : null,
                      );
                    }
                    return MessageBubble(
                      message: message,
                      streamingText: session.streamText,
                      isStreaming: isStreaming,
                      isLast: isLast,
                      showRegenerate: canRegenerate,
                      onEdit: message.role == 'user'
                          ? () => _editMessage(message)
                          : null,
                      onBranch: () => _branchFrom(message),
                      onRegenerate: canRegenerate
                          ? () => ref
                              .read(chatSessionProvider.notifier)
                              .regenerate(widget.chatId)
                          : null,
                      branchPager: branchPager,
                    );
                  },
                ),
        ),
        ChatComposer(
          isBusy: session.isStreaming || session.busy,
          onStop: () => ref.read(chatSessionProvider.notifier).stop(),
          onSend: (String text, List<ChatAttachment> attachments) =>
              ref.read(chatSessionProvider.notifier).send(
                    widget.chatId,
                    text,
                    attachments: attachments,
                  ),
          contextUsed: usage.used,
          contextLimit: usage.limit,
          onContextTap: () => _showContextStats(
            l10n,
            chat,
            usage.used,
            usage.limit,
            usage.approximate,
          ),
        ),
      ],
    );
  }

  void _showContextStats(
    AppLocalizations l10n,
    Chat chat,
    int used,
    int limit,
    bool approximate,
  ) {
    final free = limit > used ? limit - used : 0;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final dl = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dl.contextDetails),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _statRow(dl.statUsed, formatTokenCount(used)),
              _statRow(dl.statFree, formatTokenCount(free)),
              if (approximate)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '≈ ${dl.approximateLabel}',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ),
              const Divider(height: 16),
              _statRow(dl.statInput, formatTokenCount(chat.usageInput)),
              _statRow(dl.statOutput, formatTokenCount(chat.usageOutput)),
              _statRow(dl.statThinking, formatTokenCount(chat.usageThinking)),
            ],
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dl.cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _statRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  void _switchTo(int branchId) {
    ref
        .read(chatSessionProvider.notifier)
        .switchBranch(widget.chatId, branchId);
  }

  static String _issueMessage(AppLocalizations l10n, ChatIssue issue) {
    return switch (issue) {
      ChatIssue.noKey => l10n.keyMissing,
      ChatIssue.noModel => l10n.errNoModel,
      ChatIssue.noChat => l10n.errNoChat,
      ChatIssue.noProvider => l10n.errNoProvider,
    };
  }
}
