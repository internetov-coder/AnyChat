import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../core/errors/error_localizer.dart';
import '../domain/models.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../../settings/state/settings_controller.dart';
import '../state/chat_providers.dart';
import '../state/chat_session.dart';
import 'widgets/context_bar.dart';
import 'widgets/input_bar.dart';
import 'widgets/message_bubble.dart';

/// Single chat: message list with streaming, branching, context strip and the
/// message composer.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final int chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await ref.read(chatSessionProvider.notifier).send(widget.chatId, text);
    if (!mounted) return;
    _focus.requestFocus();
  }

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

  Future<void> _renameChat(Chat chat) async {
    final controller = TextEditingController(text: chat.title);
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          final l10n = AppLocalizations.of(dialogContext);
          return AlertDialog(
            title: Text(l10n.renameChat),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.chatNameLabel),
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
    final title = result?.trim();
    if (title == null || title.isEmpty || !mounted) return;
    await ref.read(chatRepositoryProvider).renameChat(chat.id, title);
  }

  Future<void> _chatSystemPrompt(Chat chat) async {
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
                onPressed: () => Navigator.of(dialogContext).pop(controller.text),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
    if (result == null || !mounted) return;
    await ref.read(chatRepositoryProvider).setSystemPrompt(chat.id, result);
  }

  Future<void> _summarize(Chat chat) async {
    final l10n = AppLocalizations.of(context);
    final newChatId = await ref
        .read(chatSessionProvider.notifier)
        .summarize(widget.chatId, prompt: l10n.handoffPrompt);
    if (!mounted || newChatId == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.handoffDone)),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => ChatScreen(chatId: newChatId),
      ),
    );
  }

  Future<void> _deleteChat(Chat chat) async {
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
    if (confirmed != true || !mounted) return;
    await ref.read(chatRepositoryProvider).deleteChat(chat.id);
    if (!mounted) return;
    Navigator.of(context).pop();
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
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: Center(child: Text(l10n.errUnknown('$error'))),
      ),
      data: (Chat? chat) {
        if (chat == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).maybePop();
            }
          });
          return Scaffold(
            appBar: AppBar(),
            body: const SizedBox.shrink(),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              chat.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'rename') {
                    _renameChat(chat);
                  } else if (value == 'prompt') {
                    _chatSystemPrompt(chat);
                  } else if (value == 'summarize') {
                    _summarize(chat);
                  } else if (value == 'delete') {
                    _deleteChat(chat);
                  }
                },
                itemBuilder: (BuildContext menuContext) =>
                    <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'rename',
                    child: Text(l10n.renameChat),
                  ),
                  PopupMenuItem<String>(
                    value: 'prompt',
                    child: Text(l10n.systemPromptLabel),
                  ),
                  PopupMenuItem<String>(
                    value: 'summarize',
                    child: Text(l10n.handoff),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(l10n.deleteChat),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              if (session.busy) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (Object error, StackTrace stack) =>
                      Center(child: Text(l10n.errUnknown('$error'))),
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

    final reversed = messages.reversed.toList();

    return Column(
      children: <Widget>[
        ContextBar(messages: messages, systemPrompt: systemPrompt),
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.emptyChatHint,
                      textAlign: TextAlign.center,
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
                    return MessageBubble(
                      message: message,
                      streamingText: session.streamText,
                      isStreaming: isStreaming,
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
                    );
                  },
                ),
        ),
        _buildBranchStrip(chat, branches),
        InputBar(
          controller: _input,
          focusNode: _focus,
          isBusy: session.isStreaming || session.busy,
          onSend: _send,
          onStop: () => ref.read(chatSessionProvider.notifier).stop(),
        ),
      ],
    );
  }

  Widget _buildBranchStrip(Chat chat, List<Branch> branches) {
    if (branches.length <= 1) return const SizedBox.shrink();
    final activeId = chat.activeBranchId;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: <Widget>[
          for (final branch in branches)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(branch.name),
                selected: branch.id == activeId,
                onSelected: (bool selected) {
                  if (!selected || branch.id == activeId) return;
                  ref
                      .read(chatSessionProvider.notifier)
                      .switchBranch(widget.chatId, branch.id);
                },
              ),
            ),
        ],
      ),
    );
  }

  static String _issueMessage(AppLocalizations l10n, ChatIssue issue) {
    return switch (issue) {
      ChatIssue.noKey => l10n.keyMissing,
      ChatIssue.noModel => l10n.errNoModel,
      ChatIssue.noChat => l10n.errNoChat,
    };
  }
}
