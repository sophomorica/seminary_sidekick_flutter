import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/journal_provider.dart';
import '../../providers/sidekick_provider.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/haptic_service.dart';
import '../../theme/app_theme.dart';
import 'chat_bubble.dart';
import 'chat_empty_state.dart';
import 'chat_input.dart';
import 'typing_indicator.dart';

/// "Walking in the Light" — The Seminary Sidekick chat interface.
///
/// Premium-only screen. Users can ask questions about scriptures, their
/// progress, or gospel topics in a conversational format. Scripture references
/// in responses are tappable and navigate to the scripture detail screen.
///
/// This screen works both as a main tab (when accessed from the bottom nav)
/// and as a full-screen route when navigated with an initialScriptureId.
class SidekickChatScreen extends ConsumerStatefulWidget {
  /// Optional scripture ID to pre-populate context (e.g., from scripture detail).
  final String? initialScriptureId;

  /// Optional message to auto-send on open (e.g., the suggested question shown
  /// on the scripture detail card). Takes precedence over the generic
  /// scripture-context message built from [initialScriptureId].
  final String? initialMessage;

  const SidekickChatScreen({
    super.key,
    this.initialScriptureId,
    this.initialMessage,
  });

  @override
  ConsumerState<SidekickChatScreen> createState() => _SidekickChatScreenState();
}

class _SidekickChatScreenState extends ConsumerState<SidekickChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _hasAutoSentInitial = false;

  @override
  void initState() {
    super.initState();
    // If opened with a question or scripture context, auto-send it
    if ((widget.initialMessage != null || widget.initialScriptureId != null) &&
        !_hasAutoSentInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendInitialContextMessage();
      });
    }
  }

  void _sendInitialContextMessage() {
    if (_hasAutoSentInitial) return;
    // Chat is premium-only — never auto-spend an API call for free users.
    if (!ref.read(isPremiumProvider)) return;
    _hasAutoSentInitial = true;

    // Only auto-send if chat is empty (don't re-send on rebuild)
    final chatHistory = ref.read(chatHistoryProvider);
    if (chatHistory.isNotEmpty) return;

    var message = widget.initialMessage;
    if (message == null) {
      final scripture =
          ref.read(scriptureByIdProvider(widget.initialScriptureId!));
      if (scripture == null) return;
      message = 'Can you help me understand ${scripture.reference}? '
          'I\'ve been studying "${scripture.keyPhrase}"';
    }

    ref.read(sidekickProvider.notifier).sendMessage(message);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    // Chat is premium-only; the UI never offers send affordances to free
    // users, but guard anyway.
    if (!ref.read(isPremiumProvider)) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    ref.read(sidekickProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatHistory = ref.watch(chatHistoryProvider);
    final isLoading = ref.watch(isChatLoadingProvider);
    final error = ref.watch(sidekickProvider).error;
    final isPremium = ref.watch(isPremiumProvider);

    // Auto-scroll when new messages arrive
    ref.listen(chatHistoryProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Editorial header
          _buildEditorialHeader(context),

          // Error banner
          if (error != null) _buildErrorBanner(context),

          // Chat messages — free users always see the premium teaser state.
          Expanded(
            child: !isPremium || (chatHistory.isEmpty && !isLoading)
                ? ChatEmptyState(
                    isPremium: isPremium,
                    onSuggestionTap: (suggestion) {
                      _messageController.text = suggestion;
                      _sendMessage();
                    },
                    onUpgradeTap: () => context.push('/upgrade'),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingMd,
                    ),
                    itemCount: chatHistory.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatHistory.length && isLoading) {
                        return const TypingIndicator();
                      }
                      final msg = chatHistory[index];
                      return ChatBubble(
                        message: msg,
                        onScriptureTap: _navigateToScripture,
                        onSaveToJournal: msg.role == 'assistant'
                            ? () => _saveMessageToJournal(index)
                            : null,
                      );
                    },
                  ),
          ),

          // Input area — locked for free users, routes to upgrade.
          if (isPremium)
            ChatInput(
              controller: _messageController,
              focusNode: _inputFocusNode,
              isLoading: isLoading,
              onSend: _sendMessage,
            )
          else
            _buildLockedInput(context),
        ],
      ),
    );
  }

  /// Faux input bar for free users — looks like the chat input but taps
  /// through to the upgrade screen instead of accepting text.
  Widget _buildLockedInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingMd,
      ),
      color: isDark
          ? AppTheme.darkBackground
          : Theme.of(context).colorScheme.surface,
      child: Material(
        color: isDark
            ? AppTheme.darkSurfaceContainerLow
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: InkWell(
          onTap: () {
            ref.read(hapticProvider).light();
            context.push('/upgrade');
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingMd,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    'Subscribe to chat with your Sidekick',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const Icon(
                  Icons.workspace_premium,
                  size: 20,
                  color: AppTheme.premiumGold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorialHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();
    return Container(
      color: isDark
          ? AppTheme.darkBackground
          : Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.fromLTRB(
        canPop ? AppTheme.spacingSm : AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingLg,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canPop)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Theme.of(context).colorScheme.onSurface,
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  tooltip: 'Back',
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label
                      Text(
                        'Your Spiritual Guide',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.secondary,
                              letterSpacing: 2.0,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      // Title
                      Text(
                        'Walking in the Light',
                        style: GoogleFonts.merriweather(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.2,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                // Journal — the Sidekick's companion surface. This is the
                // journal's one persistent entry point in the app.
                TextButton.icon(
                  onPressed: () => context.push('/journal'),
                  icon: const Icon(Icons.auto_stories_outlined, size: 18),
                  label: const Text('Journal'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.sidekickColor(context),
                    backgroundColor:
                        AppTheme.sidekickColor(context).withValues(alpha: 0.10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Subtitle
            Text(
              'Your Sidekick is here to help you bridge the gap between ancient scripture and modern life.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    final error = ref.watch(sidekickProvider).error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      color: AppTheme.errorLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber, size: 16, color: AppTheme.error),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(sidekickProvider.notifier).clearError(),
            child: const Padding(
              padding: EdgeInsets.only(top: 2, left: 4),
              child: Icon(Icons.close, size: 16, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScripture(String scriptureId) {
    context.push('/scripture/$scriptureId');
  }

  /// Save a Sidekick insight as a journal entry without leaving the chat
  /// (TASK-066). The preceding user question is stored as the entry's
  /// prompt so the journal shows what inspired it.
  Future<void> _saveMessageToJournal(int messageIndex) async {
    final chatHistory = ref.read(chatHistoryProvider);
    if (messageIndex < 0 || messageIndex >= chatHistory.length) return;
    final message = chatHistory[messageIndex];

    // Walk back to the user question that led to this insight.
    String? question;
    for (var i = messageIndex - 1; i >= 0; i--) {
      if (chatHistory[i].role == 'user') {
        question = chatHistory[i].content;
        break;
      }
    }

    final entry = await ref.read(journalProvider.notifier).addQuickEntry(
          content: message.content,
          prompt: question,
        );

    if (!mounted) return;
    ref.read(hapticProvider).light();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Insight saved to your journal'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              ref.read(journalProvider.notifier).editEntry(entry);
              context.push('/journal');
            },
          ),
        ),
      );
  }
}
