import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ChatEmptyState extends StatelessWidget {
  final bool isPremium;
  final void Function(String suggestion) onSuggestionTap;

  const ChatEmptyState({
    super.key,
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppTheme.sidekickGradient(context),
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
                  avatar: Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: AppTheme.sidekickColor(context),
                  ),
                  side: BorderSide(
                    color:
                        AppTheme.sidekickColor(context).withValues(alpha: 0.3),
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
