import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/journal_provider.dart';
import '../../providers/subscription_provider.dart';
import 'journal_editor_view.dart';
import 'journal_list_view.dart';

/// Premium journal screen — list of entries + AI reflection prompts.
///
/// Free users see a teaser; premium users get the full experience.
/// Sacred Editorial design system with warm, inviting aesthetic.
/// Redesigned to match HTML mockup with hero heading, gradient editor card,
/// and portfolio progress tracking.
class JournalScreen extends ConsumerStatefulWidget {
  /// Optional: pre-select a prompt to start writing immediately.
  final String? initialPrompt;

  /// Optional: pre-tag a scripture.
  final String? initialScriptureId;
  final String? initialScriptureReference;

  const JournalScreen({
    super.key,
    this.initialPrompt,
    this.initialScriptureId,
    this.initialScriptureReference,
  });

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  @override
  void initState() {
    super.initState();
    // If launched with a prompt or a scripture to reflect on,
    // auto-create a new entry (TASK-066: scripture-only launches used to
    // land on the list, which made "Reflect on this verse" feel broken).
    if (widget.initialPrompt != null || widget.initialScriptureId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(journalProvider.notifier).createEntry(
              prompt: widget.initialPrompt,
              scriptureId: widget.initialScriptureId,
              scriptureReference: widget.initialScriptureReference,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final activeEntry = ref.watch(activeJournalEntryProvider);

    // If there's an active entry being edited, show the editor
    if (activeEntry != null && isPremium) {
      return JournalEditorView(entry: activeEntry);
    }

    // Otherwise show the journal list
    return JournalListView(isPremium: isPremium);
  }
}
