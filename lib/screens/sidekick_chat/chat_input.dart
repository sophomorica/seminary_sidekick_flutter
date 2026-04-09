import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceContainerLow
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Ask about a scripture...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingMd,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Send button
          _SendButton(
            isLoading: isLoading,
            onTap: isLoading ? null : onSend,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _SendButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppTheme.sidekickColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isLoading ? baseColor.withValues(alpha: 0.4) : baseColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            boxShadow: !isLoading
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              isLoading ? Icons.hourglass_empty : Icons.arrow_upward,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
