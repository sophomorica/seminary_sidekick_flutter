import 'package:flutter/material.dart';

import '../../../models/group_question.dart';
import '../../../theme/app_theme.dart';

/// Renders a single group-play question with four answer buttons.
///
/// Visual style mirrors the solo `quiz_game_screen.dart` so the experience
/// feels familiar across modes:
///   - Tertiary accent for the prompt card border + answer button focus
///   - Success/error fills + icons after the question has been resolved
///   - Selected (but not yet submitted) shows a tertiary tint
///
/// The card is presentation-only — all answer/scoring state is owned by
/// `GroupPlayNotifier`. The host passes `interactive: false` so taps are
/// ignored on the projector view.
class GroupQuestionCard extends StatelessWidget {
  final GroupQuestion question;

  /// The local player's selected option index, if any.
  final int? selectedChoice;

  /// True once the question has been resolved (either the player answered or
  /// the timer expired). Reveals the correct answer and locks all buttons.
  final bool revealAnswer;

  /// True if this is the host's read-only projector view (no taps).
  final bool interactive;

  /// Tap callback for an option. Only fired when `interactive` is true and
  /// the question has not been resolved.
  final ValueChanged<int>? onAnswer;

  const GroupQuestionCard({
    super.key,
    required this.question,
    required this.selectedChoice,
    required this.revealAnswer,
    required this.interactive,
    this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Scripture reference label ───
        Text(
          question.scriptureReference.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.brightness == Brightness.dark
                ? AppTheme.tertiaryFixedDim
                : AppTheme.onTertiaryFixed,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // ─── Prompt card ───
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.tertiary.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    theme.colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            question.prompt,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        // ─── Answer options ───
        ...List.generate(question.options.length, (i) {
          final option = question.options[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AnswerOption(
              text: option,
              index: i,
              isSelected: selectedChoice == i,
              isCorrect: i == question.correctIndex,
              revealAnswer: revealAnswer,
              interactive: interactive,
              onTap: (interactive && !revealAnswer && onAnswer != null)
                  ? () => onAnswer!(i)
                  : null,
            ),
          );
        }),
      ],
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool revealAnswer;
  final bool interactive;
  final VoidCallback? onTap;

  const _AnswerOption({
    required this.text,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.revealAnswer,
    required this.interactive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? trailingIcon;

    if (revealAnswer) {
      if (isCorrect) {
        bgColor = AppTheme.success.withValues(alpha: 0.18);
        borderColor = AppTheme.success;
        textColor = AppTheme.success;
        trailingIcon = Icons.check_circle;
      } else if (isSelected) {
        bgColor = AppTheme.error.withValues(alpha: 0.15);
        borderColor = AppTheme.error;
        textColor = AppTheme.error;
        trailingIcon = Icons.cancel;
      } else {
        bgColor = theme.colorScheme.surface;
        borderColor = theme.colorScheme.outlineVariant;
        textColor = theme.colorScheme.onSurfaceVariant;
        trailingIcon = null;
      }
    } else if (isSelected) {
      bgColor = AppTheme.tertiary.withValues(alpha: 0.12);
      borderColor = AppTheme.tertiary;
      textColor = theme.colorScheme.onSurface;
      trailingIcon = null;
    } else {
      bgColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outlineVariant;
      textColor = theme.colorScheme.onSurface;
      trailingIcon = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: borderColor,
            width: isSelected || (revealAnswer && isCorrect) ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Letter badge (A/B/C/D)
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                String.fromCharCode(65 + index),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: borderColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: isSelected || (revealAnswer && isCorrect)
                      ? FontWeight.w600
                      : FontWeight.normal,
                  height: 1.4,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: borderColor, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
