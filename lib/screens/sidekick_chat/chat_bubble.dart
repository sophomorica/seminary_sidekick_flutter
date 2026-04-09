import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/scriptures_data.dart';
import '../../models/sidekick_response.dart';
import '../../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final SidekickMessage message;
  final void Function(String scriptureId) onScriptureTap;

  const ChatBubble({
    super.key,
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
                gradient: LinearGradient(
                  colors: AppTheme.sidekickGradient(context),
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
                  : RichMessageText(
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

class RichMessageText extends StatelessWidget {
  final String text;
  final void Function(String scriptureId) onScriptureTap;

  const RichMessageText({
    super.key,
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
