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

/// Explicit scripture-detail starter (hot button). These always wipe the
/// prior thread and send — journal is the keep path; chat history is not
/// treated as durable context here.
@visibleForTesting
bool isExplicitSidekickStarter(String? initialMessage) {
  return initialMessage != null && initialMessage.trim().isNotEmpty;
}

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

class _SidekickChatScreenState extends ConsumerState<SidekickChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _hasAutoSentInitial = false;

  /// Brief title banner — collapses so chat gets the real estate.
  late final AnimationController _titleBannerController;
  late final Animation<double> _titleBannerFactor;

  @override
  void initState() {
    super.initState();
    _titleBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    _titleBannerFactor = CurvedAnimation(
      parent: _titleBannerController,
      curve: Curves.easeInOut,
    );
    // Show "Acquiring Spiritual Knowledge" briefly, then fold it away.
    // Skip entirely if a conversation is already in progress.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(chatHistoryProvider).isNotEmpty) {
        _titleBannerController.value = 0;
        return;
      }
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) _titleBannerController.reverse();
      });
    });

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

    final explicit = widget.initialMessage?.trim();
    if (isExplicitSidekickStarter(explicit)) {
      // Hot button from scripture detail: refresh to a new conversation,
      // then send the starter. Prior turns are disposable (journal keeps
      // anything worth saving).
      _hasAutoSentInitial = true;
      ref.read(sidekickProvider.notifier).clearChat();
      ref.read(sidekickProvider.notifier).sendMessage(explicit!);
      return;
    }

    // Scripture-only open ("Or ask anything" / deep link): only auto-send
    // a generic opener when the thread is already empty.
    final chatHistory = ref.read(chatHistoryProvider);
    if (chatHistory.isNotEmpty) return;

    final scriptureId = widget.initialScriptureId;
    if (scriptureId == null) return;
    final scripture = ref.read(scriptureByIdProvider(scriptureId));
    if (scripture == null) return;

    _hasAutoSentInitial = true;
    ref.read(sidekickProvider.notifier).sendMessage(
          'Can you help me understand ${scripture.reference}? '
          'I\'ve been studying "${scripture.keyPhrase}"',
        );
  }

  @override
  void dispose() {
    _titleBannerController.dispose();
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

  Future<void> _confirmNewConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new conversation?'),
        content: const Text(
          'This clears the current chat. You can always start fresh — '
          'your study progress is unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('New conversation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    ref.read(hapticProvider).light();
    ref.read(sidekickProvider.notifier).clearChat();
    _messageController.clear();
    // Bring the title banner back for the empty state.
    _titleBannerController.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && ref.read(chatHistoryProvider).isEmpty) {
        _titleBannerController.reverse();
      }
    });
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

    // Auto-scroll when new messages arrive; fold the title as soon as
    // a conversation is underway so it never competes with bubbles.
    ref.listen(chatHistoryProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        _scrollToBottom();
        if (_titleBannerController.value > 0) {
          _titleBannerController.reverse();
        }
      }
    });

    // After a 403, the provider pulls the bubble and stashes the text —
    // put it back in the input so the user doesn't lose what they typed.
    ref.listen(sidekickProvider, (prev, next) {
      final pending = next.pendingRetryMessage;
      if (pending != null && pending != prev?.pendingRetryMessage) {
        _messageController.text = pending;
        _messageController.selection = TextSelection.collapsed(
          offset: pending.length,
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Lift the input above the keyboard. The shell turns off extendBody on
      // this tab so the column is already laid out above the tab bar — no
      // hardcoded nav-height padding needed (flex, not overlay).
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Editorial header
          _buildEditorialHeader(context),

          // Error banner
          if (error != null) _buildErrorBanner(context),

          // Chat messages — free users always see the premium teaser state.
          // Tap empty space / drag scroll dismisses the keyboard so the
          // bottom nav can return.
          Expanded(
            child: GestureDetector(
              onTap: () => _inputFocusNode.unfocus(),
              behavior: HitTestBehavior.opaque,
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
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
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
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

  /// Slim chrome: optional back, a brief title that auto-collapses, and
  /// Journal / New conversation (when history exists).
  ///
  /// When this screen is a bottom-nav tab, the shell already owns the top
  /// chrome — skip SafeArea so we don't double-pad under the status bar.
  Widget _buildEditorialHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();
    final hasHistory = ref.watch(chatHistoryProvider).isNotEmpty;
    final isPremium = ref.watch(isPremiumProvider);
    final journalButton = IconButton(
      onPressed: () => context.push('/journal'),
      icon: const Icon(Icons.auto_stories_outlined, size: 22),
      color: AppTheme.sidekickColor(context),
      tooltip: 'Journal',
      visualDensity: VisualDensity.compact,
    );

    return Container(
      color: isDark
          ? AppTheme.darkBackground
          : Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.fromLTRB(
        canPop ? AppTheme.spacingSm : AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        0,
      ),
      child: SafeArea(
        // Tab mode sits under the shell header — don't re-apply top inset.
        top: canPop,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Persistent slim row: back (if pushed) + new chat + Journal
            Row(
              children: [
                if (canPop)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Back',
                  ),
                const Spacer(),
                if (isPremium && hasHistory)
                  IconButton(
                    onPressed: _confirmNewConversation,
                    icon: const Icon(Icons.add_comment_outlined, size: 22),
                    color: AppTheme.sidekickColor(context),
                    tooltip: 'New conversation',
                    visualDensity: VisualDensity.compact,
                  ),
                journalButton,
              ],
            ),
            // Title banner — shows briefly, then folds away.
            SizeTransition(
              sizeFactor: _titleBannerFactor,
              // Vertical fold from the top (Flutter 3.44+: alignment, not
              // axisAlignment).
              alignment: Alignment.topCenter,
              child: FadeTransition(
                opacity: _titleBannerFactor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingSm,
                    0,
                    AppTheme.spacingSm,
                    AppTheme.spacingMd,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Acquiring Spiritual Knowledge',
                      style: GoogleFonts.merriweather(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    final sidekick = ref.watch(sidekickProvider);
    final error = sidekick.error;
    final isEntitlement = sidekick.isEntitlementError;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark
        ? AppTheme.error.withValues(alpha: 0.18)
        : AppTheme.errorLight;
    final bannerFg = isDark
        ? Theme.of(context).colorScheme.onSurface
        : AppTheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      color: bannerBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber, size: 16, color: bannerFg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: bannerFg,
                  ),
            ),
          ),
          if (isEntitlement)
            TextButton(
              onPressed: _refreshEntitlementAndRetry,
              style: TextButton.styleFrom(
                foregroundColor: bannerFg,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Refresh',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: bannerFg,
                    ),
              ),
            )
          else
            GestureDetector(
              onTap: () => ref.read(sidekickProvider.notifier).clearError(),
              child: Padding(
                padding: const EdgeInsets.only(top: 2, left: 4),
                child: Icon(Icons.close, size: 16, color: bannerFg),
              ),
            ),
        ],
      ),
    );
  }

  /// Re-sync RevenueCat after a proxy 403; retry the message if still premium,
  /// otherwise send the user to the upgrade screen (TASK-067).
  Future<void> _refreshEntitlementAndRetry() async {
    final notifier = ref.read(sidekickProvider.notifier);
    final pending = ref.read(sidekickProvider).pendingRetryMessage;
    notifier.clearError();

    final stillPremium =
        await ref.read(subscriptionProvider.notifier).refreshEntitlement();
    if (!mounted) return;

    if (!stillPremium) {
      if (pending != null) {
        _messageController.text = pending;
        notifier.clearPendingRetry();
      }
      context.push('/upgrade');
      return;
    }

    if (pending != null && pending.isNotEmpty) {
      notifier.clearPendingRetry();
      _messageController.clear();
      await notifier.sendMessage(pending);
      _scrollToBottom();
    }
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
