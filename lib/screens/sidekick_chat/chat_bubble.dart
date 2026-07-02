import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/scriptures_data.dart';
import '../../models/sidekick_response.dart';
import '../../services/haptic_service.dart';
import '../../theme/app_theme.dart';

class ChatBubble extends ConsumerWidget {
  final SidekickMessage message;
  final void Function(String scriptureId) onScriptureTap;

  /// Called when the user taps "Save to journal" on a Sidekick message
  /// (TASK-066). Null hides the action (e.g. for user messages).
  final VoidCallback? onSaveToJournal;

  const ChatBubble({
    super.key,
    required this.message,
    required this.onScriptureTap,
    this.onSaveToJournal,
  });

  bool get isUser => message.role == 'user';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Sidekick avatar: 36px circle with secondary gradient
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(top: 4, right: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.secondaryContainer
                    : AppTheme.secondaryContainer,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: AppTheme.onSecondaryContainer,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primary
                        : (isDark
                            ? AppTheme.darkSurfaceContainerLow
                            : Theme.of(context).colorScheme.surfaceContainerLow),
                    borderRadius: isUser
                        ? BorderRadius.circular(AppTheme.radiusXl).copyWith(
                            bottomRight:
                                const Radius.circular(AppTheme.radiusSm))
                        : BorderRadius.circular(AppTheme.radiusXl).copyWith(
                            bottomLeft:
                                const Radius.circular(AppTheme.radiusSm)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    height: 1.6,
                                  ),
                        )
                      : RichMessageText(
                          text: message.content,
                          onScriptureTap: onScriptureTap,
                        ),
                ),
                if (!isUser) ...[
                  const SizedBox(height: 12),
                  _SuggestionChips(onSaveToJournal: onSaveToJournal),
                ],
                const SizedBox(height: 4),
                Text(
                  isUser ? 'You • 10:26 AM' : 'Sidekick • 10:24 AM',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.outline,
                        letterSpacing: 1.5,
                      ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─── Rich Text with Tappable Scripture References ──────────────────────────

/// Regex pattern that matches common scripture references in the 100 DM list.
final _scriptureRefPattern = RegExp(
  r'\b('
  r'[1-4]\s?(?:Nephi|John|Corinthians|Thessalonians|Timothy|Peter|Samuel|Kings|Chronicles)'
  r'|'
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

class RichMessageText extends ConsumerWidget {
  final String text;
  final void Function(String scriptureId) onScriptureTap;

  const RichMessageText({
    super.key,
    required this.text,
    required this.onScriptureTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spans = _buildSpans(context, ref);

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context, WidgetRef ref) {
    final spans = <InlineSpan>[];
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface,
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
              ref.read(hapticProvider).light();
              onScriptureTap(scriptureId);
            }),
        ));
      } else {
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

  static String? _findScriptureIdByReference(String refText) {
    final normalised = refText.trim().toLowerCase();
    for (final s in allScriptures) {
      if (s.reference.toLowerCase() == normalised) return s.id;
      if (s.reference.toLowerCase().startsWith(normalised) ||
          normalised.startsWith(s.reference.toLowerCase())) {
        return s.id;
      }
    }
    return null;
  }
}

// ─── Suggestion Chips (appear below sidekick messages) ─────────────────────

class _SuggestionChips extends StatelessWidget {
  final VoidCallback? onSaveToJournal;

  const _SuggestionChips({this.onSaveToJournal});

  @override
  Widget build(BuildContext context) {
    if (onSaveToJournal == null) return const SizedBox.shrink();

    // "Save to journal" — captures this insight as a journal entry without
    // leaving the conversation (TASK-066).
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SuggestionChip(
          label: 'Save to journal',
          icon: Icons.auto_stories_outlined,
          highlighted: true,
          onTap: onSaveToJournal,
        ),
      ],
    );
  }
}

class _SuggestionChip extends ConsumerWidget {
  final String label;
  final IconData icon;
  final bool highlighted;
  final VoidCallback? onTap;

  const _SuggestionChip({
    required this.label,
    required this.icon,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = highlighted
        ? AppTheme.sidekickColor(context)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(hapticProvider).light();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: highlighted
                ? AppTheme.sidekickTint(context, 0.12)
                : (isDark
                    ? AppTheme.darkSurfaceContainerLow
                    : Theme.of(context).colorScheme.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: highlighted
                ? Border.all(
                    color: AppTheme.sidekickColor(context)
                        .withValues(alpha: 0.35),
                    width: 0.5,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
