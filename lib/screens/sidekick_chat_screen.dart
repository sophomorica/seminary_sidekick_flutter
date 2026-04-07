import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/scriptures_data.dart';
import '../models/sidekick_response.dart';
import '../providers/sidekick_provider.dart';
import '../providers/scripture_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

/// "Ask Your Sidekick" — direct chat interface with the Seminary Sidekick AI.
///
/// Premium-only screen. Users can ask questions about any scripture, their
/// progress, or gospel topics. Scripture references in responses are tappable
/// and navigate to the scripture detail screen.
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

    final scripture = ref.read(scriptureByIdProvider(widget.initialScriptureId!));
    if (scripture == null) return;

    // Only auto-send if chat is empty (don't re-send on rebuild)
    final chatHistory = ref.read(chatHistoryProvider);
    if (chatHistory.isNotEmpty) return;

    final message = 'I\'d like to learn more about ${scripture.reference} '
        '("${scripture.name}"). Can you help me understand its context, '
        'doctrine, and how I can apply it?';

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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 20, color: AppTheme.premiumGold),
            const SizedBox(width: 8),
            Text(
              'Your Sidekick',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (chatHistory.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Clear conversation'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              color: AppTheme.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.error,
                          ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        ref.read(sidekickProvider.notifier).clearError(),
                    child: const Icon(Icons.close, size: 16, color: AppTheme.error),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: chatHistory.isEmpty && !isLoading
                ? _EmptyState(
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
                      vertical: AppTheme.spacingSm,
                    ),
                    itemCount: chatHistory.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatHistory.length && isLoading) {
                        return const _TypingIndicator();
                      }
                      return _ChatBubble(
                        message: chatHistory[index],
                        onScriptureTap: _navigateToScripture,
                      );
                    },
                  ),
          ),

          // Input area
          _ChatInput(
            controller: _messageController,
            focusNode: _inputFocusNode,
            isLoading: isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _navigateToScripture(String scriptureId) {
    context.push('/scripture/$scriptureId');
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: const Text(
          'This will remove all messages. Your Sidekick will start fresh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(sidekickProvider.notifier).clearChat();
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat Bubble ───────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final SidekickMessage message;
  final void Function(String scriptureId) onScriptureTap;

  const _ChatBubble({
    required this.message,
    required this.onScriptureTap,
  });

  bool get isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Sidekick avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.premiumGradientStart,
                    AppTheme.premiumGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm + 4,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primary
                    : (isDark ? AppTheme.darkCard : AppTheme.surface),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppTheme.radiusMd),
                  topRight: const Radius.circular(AppTheme.radiusMd),
                  bottomLeft: Radius.circular(
                      isUser ? AppTheme.radiusMd : AppTheme.radiusSm / 2),
                  bottomRight: Radius.circular(
                      isUser ? AppTheme.radiusSm / 2 : AppTheme.radiusMd),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            height: 1.4,
                          ),
                    )
                  : _RichMessageText(
                      text: message.content,
                      onScriptureTap: onScriptureTap,
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ─── Rich Text with Tappable Scripture References ──────────────────────────

/// Regex pattern that matches common scripture references in the 100 DM list.
///
/// Matches patterns like:
///   "1 Nephi 3:7", "D&C 76:22–24", "Moses 1:39",
///   "Alma 7:11–13", "John 3:16", "Abraham 2:9–11"
final _scriptureRefPattern = RegExp(
  r'\b('
  // Books that start with a number
  r'[1-4]\s?(?:Nephi|John|Corinthians|Thessalonians|Timothy|Peter|Samuel|Kings|Chronicles)'
  r'|'
  // Named books (no leading number)
  r'(?:Genesis|Exodus|Leviticus|Deuteronomy|Joshua|Judges|Ruth|Psalms?|Proverbs|Ecclesiastes|Isaiah|Jeremiah|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi'
  r'|Matthew|Mark|Luke|John|Acts|Romans|Galatians|Ephesians|Philippians|Colossians|Hebrews|James|Jude|Revelation'
  r'|Mosiah|Alma|Helaman|Mormon|Ether|Moroni|Jacob|Enos|Jarom|Omni|Words of Mormon'
  r'|Moses|Abraham|Joseph Smith[—–\-]History|JS[—–\-]H|Articles of Faith'
  r'|D&C|Doctrine and Covenants)'
  r')'
  r'\s+\d+:\d+(?:\s?[–—\-]\s?\d+)?'
  r'\b',
  caseSensitive: false,
);

class _RichMessageText extends StatelessWidget {
  final String text;
  final void Function(String scriptureId) onScriptureTap;

  const _RichMessageText({
    required this.text,
    required this.onScriptureTap,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(context);

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context) {
    final spans = <InlineSpan>[];
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5,
        );

    int lastEnd = 0;
    for (final match in _scriptureRefPattern.allMatches(text)) {
      // Text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: textStyle,
        ));
      }

      // The scripture reference — tappable
      final refText = match.group(0)!;
      final scriptureId = _findScriptureIdByReference(refText);

      if (scriptureId != null) {
        spans.add(TextSpan(
          text: refText,
          style: textStyle?.copyWith(
            color: AppTheme.accent,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppTheme.accent.withValues(alpha: 0.4),
          ),
          recognizer: (TapGestureRecognizer()
            ..onTap = () {
              HapticFeedback.lightImpact();
              onScriptureTap(scriptureId);
            }),
        ));
      } else {
        // Reference not in our 100 DM list — style it but don't make tappable
        spans.add(TextSpan(
          text: refText,
          style: textStyle?.copyWith(
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: textStyle,
      ));
    }

    return spans;
  }

  /// Look up a scripture ID from a reference string.
  /// Matches against the allScriptures data list.
  static String? _findScriptureIdByReference(String refText) {
    final normalised = refText.trim().toLowerCase();
    for (final s in allScriptures) {
      if (s.reference.toLowerCase() == normalised) return s.id;
      // Also try partial match (e.g., "D&C 76:22" matches "D&C 76:22–24")
      if (s.reference.toLowerCase().startsWith(normalised) ||
          normalised.startsWith(s.reference.toLowerCase())) {
        return s.id;
      }
    }
    return null;
  }
}

// ─── Typing Indicator ──────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.premiumGradientStart,
                  AppTheme.premiumGradientEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm + 4,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppTheme.radiusMd),
                topRight: const Radius.circular(AppTheme.radiusMd),
                bottomLeft: const Radius.circular(AppTheme.radiusSm / 2),
                bottomRight: const Radius.circular(AppTheme.radiusMd),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final offset = (_controller.value + i * 0.33) % 1.0;
                    final opacity = (0.3 + 0.7 * (1 - (offset - 0.5).abs() * 2))
                        .clamp(0.3, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.premiumGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isPremium;
  final void Function(String suggestion) onSuggestionTap;

  const _EmptyState({
    required this.isPremium,
    required this.onSuggestionTap,
  });

  static const _suggestions = [
    'What does this scripture teach about faith?',
    'How can I apply this passage in my life?',
    'Which scriptures connect to the plan of salvation?',
    'Help me understand the Abrahamic covenant',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sidekick icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.premiumGradientStart,
                    AppTheme.premiumGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            Text(
              'Ask Your Sidekick',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'I can help you understand scriptures, find connections, '
              'and apply doctrines in your life.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Suggestion chips
            Text(
              'Try asking...',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              alignment: WrapAlignment.center,
              children: _suggestions.map((suggestion) {
                return ActionChip(
                  label: Text(
                    suggestion,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => onSuggestionTap(suggestion),
                  avatar: const Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: AppTheme.premiumGold,
                  ),
                  side: BorderSide(
                    color: AppTheme.premiumGold.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Input ────────────────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingSm,
        top: AppTheme.spacingSm,
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Ask about a scripture...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkSurfaceColor
                    : AppTheme.offWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm + 2,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Send button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onSend,
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLoading
                      ? AppTheme.premiumGold.withValues(alpha: 0.3)
                      : AppTheme.premiumGold,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLoading ? Icons.hourglass_empty : Icons.arrow_upward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
