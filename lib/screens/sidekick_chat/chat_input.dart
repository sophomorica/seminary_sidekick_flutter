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
    final colorScheme = Theme.of(context).colorScheme;
    final sendGradient = isDark
        ? [
            colorScheme.primary,
            colorScheme.secondary,
          ]
        : const [
            AppTheme.primary,
            AppTheme.primaryContainer,
          ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkBackground
            : colorScheme.surface,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkSurfaceContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: isDark
              ? Border.all(color: colorScheme.outlineVariant)
              : null,
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onTapOutside: (_) => focusNode.unfocus(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                decoration: InputDecoration(
                  hintText: 'Ask about scripture, history, or your journey...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
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
            _SendButton(
              isLoading: isLoading,
              gradientColors: sendGradient,
              onTap: isLoading ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isLoading;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _SendButton({
    required this.isLoading,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(right: AppTheme.spacingSm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: !isLoading
                ? [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              isLoading ? Icons.hourglass_empty : Icons.send,
              color: isDark
                  ? Theme.of(context).colorScheme.onPrimary
                  : AppTheme.onPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
