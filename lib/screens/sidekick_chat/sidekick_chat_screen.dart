import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/sidekick_provider.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/subscription_provider.dart';
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

  const SidekickChatScreen({
    super.key,
    this.initialScriptureId,
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
    // If opened from a scripture detail, auto-send a context message
    if (widget.initialScriptureId != null && !_hasAutoSentInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendInitialContextMessage();
      });
    }
  }

  void _sendInitialContextMessage() {
    if (_hasAutoSentInitial) return;
    _hasAutoSentInitial = true;

    final scripture =
        ref.read(scriptureByIdProvider(widget.initialScriptureId!));
    if (scripture == null) return;

    // Only auto-send if chat is empty (don't re-send on rebuild)
    final chatHistory = ref.read(chatHistoryProvider);
    if (chatHistory.isNotEmpty) return;

    // Build a contextual message that references the scripture
    final message = 'Peace be with you. I see you\'ve spent some time today in '
        '${scripture.reference}. The imagery of "${scripture.keyPhrase}" is '
        'powerful. Let\'s sit with that.';

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

          // Chat messages
          Expanded(
            child: chatHistory.isEmpty && !isLoading
                ? ChatEmptyState(
                    isPremium: isPremium,
                    onSuggestionTap: (suggestion) {
                      _messageController.text = suggestion;
                      _sendMessage();
                    },
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
                      return ChatBubble(
                        message: chatHistory[index],
                        onScriptureTap: _navigateToScripture,
                      );
                    },
                  ),
          ),

          // Input area
          ChatInput(
            controller: _messageController,
            focusNode: _inputFocusNode,
            isLoading: isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();
    return Container(
      color: isDark ? AppTheme.darkBackground : Theme.of(context).colorScheme.surface,
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
}
