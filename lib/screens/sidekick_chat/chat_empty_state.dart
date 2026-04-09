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
    'Show me verses about faith',
    'Write a prayer with me',
    'Explore the plan of salvation',
    'Help me apply this to my life',
  ];

  @override
  Widget build(BuildContext context) {

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sidekick icon with gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppTheme.sidekickGradient(context),
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.sidekickColor(context).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Main heading
            Text(
              'Begin the Conversation',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Subtitle
            Text(
              'Your Sidekick is ready to explore scripture with you—ask about doctrines, find connections, or dive deeper into your faith.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // Suggestion chips label
            Text(
              'Try one of these',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Suggestion chips
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              alignment: WrapAlignment.center,
              children: _suggestions.map((suggestion) {
                return _SuggestionChip(
                  label: suggestion,
                  onTap: () => onSuggestionTap(suggestion),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkSurfaceContainerLow
                : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
