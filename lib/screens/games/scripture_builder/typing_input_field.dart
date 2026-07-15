import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

/// The typing-mode input row for Scripture Builder (Advanced & Master).
///
/// Presentation-only: focus management, controller clearing, and feedback
/// orchestration stay with the owning screen. Kept as its own widget so a
/// future Group Play typing tier can reuse the exact same input behavior.
///
/// Master enables the OS keyboard's autocorrect and suggestions — judgment
/// happens per committed word (see `WordCommitEngine`), so autocorrect fixes
/// fat-finger typos instead of corrupting per-character state. Advanced keeps
/// autocorrect off because every keystroke is judged as it lands.
class SbTypingInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isMaster;
  final bool hasActiveError;
  final Color difficultyColor;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  const SbTypingInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isMaster,
    required this.hasActiveError,
    required this.difficultyColor,
    required this.onChanged,
    this.onSubmitted,
  });

  String get _hintText {
    // hasActiveError is an Advanced-only state (Master never enters the
    // red-character flow), so the error hint is scoped to Advanced.
    if (!isMaster && hasActiveError) {
      return 'Delete the error and try again...';
    }
    return isMaster
        ? 'Type each word from memory — space checks it'
        : 'Type the scripture (first letters shown)...';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('sb_typing_field'),
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              autocorrect: isMaster,
              enableSuggestions: isMaster,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              // Master judges whole words, so multi-word insertions (paste)
              // are blocked but single-word autocorrect rewrites are allowed.
              // Advanced judges per keystroke, so any multi-char insertion
              // would bypass mastery checking.
              inputFormatters: isMaster
                  ? const [SingleWordFormatter()]
                  : const [NoPasteFormatter()],
              contextMenuBuilder: (context, editableTextState) {
                final items = editableTextState.contextMenuButtonItems
                    .where(
                      (item) => item.type != ContextMenuButtonType.paste,
                    )
                    .toList();
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: items,
                );
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: _hintText,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide(
                    color: hasActiveError ? AppTheme.error : difficultyColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingSm,
                ),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rejects multi-character insertions (paste / clipboard) while allowing
/// single keystrokes and deletions. Used by the Advanced typing field.
class NoPasteFormatter extends TextInputFormatter {
  const NoPasteFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final selectionLength = oldValue.selection.isValid
        ? oldValue.selection.end - oldValue.selection.start
        : 0;
    final insertedLength =
        newValue.text.length - (oldValue.text.length - selectionLength);
    if (insertedLength > 1) {
      return oldValue;
    }
    return newValue;
  }
}

/// Keeps the Master field to the few words currently in progress:
/// autocorrect's whole-word rewrites ("cjeck" → "check ") and typo splits
/// ("ofthe" → "of the ") pass through, while pasting a chunk of the verse
/// is rejected. The 3-word ceiling matches what autocorrect realistically
/// produces in one rewrite; `WordCommitEngine` can judge multi-word buffers.
class SingleWordFormatter extends TextInputFormatter {
  const SingleWordFormatter();

  static final _whitespaceRun = RegExp(r'\s+');
  static const _maxWords = 3;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final words = newValue.text
        .trim()
        .split(_whitespaceRun)
        .where((w) => w.isNotEmpty)
        .length;
    if (words > _maxWords) {
      return oldValue;
    }
    return newValue;
  }
}
