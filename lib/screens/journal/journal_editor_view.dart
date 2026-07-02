import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../providers/scripture_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/journal_export_service.dart';
import '../../services/speech_service.dart';
import '../../theme/app_theme.dart';

class JournalEditorView extends ConsumerStatefulWidget {
  final JournalEntry entry;

  const JournalEditorView({super.key, required this.entry});

  @override
  ConsumerState<JournalEditorView> createState() => _JournalEditorViewState();
}

class _JournalEditorViewState extends ConsumerState<JournalEditorView> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late List<String> _taggedScriptureIds;
  late List<String> _taggedScriptureReferences;
  bool _hasChanges = false;

  // Voice-to-journal state
  bool _isListening = false;
  String _partialSpeechText = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    _taggedScriptureIds = List.from(widget.entry.scriptureIds);
    _taggedScriptureReferences = List.from(widget.entry.scriptureReferences);

    _titleController.addListener(_markChanged);
    _contentController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    // Stop listening if active
    if (_isListening) {
      SpeechService.instance.stopListening();
    }
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(journalProvider.notifier).saveEntry(
          title: _titleController.text,
          content: _contentController.text,
          scriptureIds: _taggedScriptureIds,
          scriptureReferences: _taggedScriptureReferences,
        );
    ref.read(hapticProvider).light();
    setState(() => _hasChanges = false);
  }

  Future<bool> _onWillPop() async {
    if (_isListening) {
      await SpeechService.instance.stopListening();
      setState(() => _isListening = false);
    }
    if (_hasChanges && _contentController.text.trim().isNotEmpty) {
      await _save();
    }
    ref.read(journalProvider.notifier).closeEditor();
    return false; // We handle navigation ourselves
  }

  // ─── Voice-to-Journal ───────────────────────────────────────────

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await SpeechService.instance.stopListening();
      setState(() => _isListening = false);
      return;
    }

    final speech = SpeechService.instance;
    final available = await speech.initialize();

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is not available. '
              'Please check microphone permissions.',
            ),
          ),
        );
      }
      return;
    }

    // Remember where the cursor is so we can append text there
    final currentText = _contentController.text;
    final cursorPos = _contentController.selection.baseOffset;
    final insertAt = cursorPos >= 0 ? cursorPos : currentText.length;

    // Add a space before dictated text if needed
    final needsSpace = insertAt > 0 &&
        currentText.isNotEmpty &&
        !' \t\n'.contains(currentText[insertAt - 1]);

    setState(() {
      _isListening = true;
      _partialSpeechText = '';
    });

    ref.read(hapticProvider).light();

    await speech.startListening(
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _partialSpeechText = text;
          // Replace from insert point with the latest recognized text
          final prefix = currentText.substring(0, insertAt);
          final suffix = insertAt < currentText.length
              ? currentText.substring(insertAt)
              : '';
          final space = needsSpace ? ' ' : '';
          _contentController.text = '$prefix$space$text$suffix';
          _contentController.selection = TextSelection.collapsed(
            offset: insertAt + space.length + text.length,
          );
          _hasChanges = true;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );

    // The speech service will call _handleStatus('done') which sets
    // _isListening to false automatically via the onResult stopping.
    // But we also poll the service to update our UI:
    Future.delayed(const Duration(seconds: 31), () {
      if (mounted && _isListening) {
        setState(() => _isListening = false);
      }
    });
  }

  // ─── Export from editor ─────────────────────────────────────────

  void _exportCurrentEntry() {
    final entry = widget.entry.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      scriptureIds: _taggedScriptureIds,
      scriptureReferences: _taggedScriptureReferences,
    );
    JournalExportService.instance.shareEntry(entry);
  }

  void _showScriptureTagPicker() {
    final allScriptures = ref.read(scripturesProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMd)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Text(
                    'Tag Scriptures',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: allScriptures.length,
                    itemBuilder: (_, index) {
                      final scripture = allScriptures[index];
                      final isTagged =
                          _taggedScriptureIds.contains(scripture.id);

                      return ListTile(
                        leading: Icon(
                          isTagged ? Icons.check_circle : Icons.circle_outlined,
                          color: isTagged ? AppTheme.success : null,
                          size: 22,
                        ),
                        title: Text(scripture.reference),
                        subtitle: Text(
                          scripture.name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        dense: true,
                        onTap: () {
                          setState(() {
                            if (isTagged) {
                              _taggedScriptureIds.remove(scripture.id);
                              _taggedScriptureReferences
                                  .remove(scripture.reference);
                            } else {
                              _taggedScriptureIds.add(scripture.id);
                              _taggedScriptureReferences
                                  .add(scripture.reference);
                            }
                            _hasChanges = true;
                          });
                          // Rebuild the bottom sheet
                          (ctx as Element).markNeedsBuild();
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get tagged scripture reference for prompt (first tagged scripture)
    final mainScriptureRef = _taggedScriptureReferences.isNotEmpty
        ? _taggedScriptureReferences.first
        : null;
    final mainScripture = _taggedScriptureIds.isNotEmpty
        ? ref.watch(scriptureByIdProvider(_taggedScriptureIds.first))
        : null;

    // Hero heading: the Sidekick prompt that spawned this entry wins;
    // otherwise fall back to a generic question about the tagged scripture.
    final entryPrompt = widget.entry.prompt;
    final heroHeading = (entryPrompt != null && entryPrompt.trim().isNotEmpty)
        ? entryPrompt
        : (mainScriptureRef != null
            ? 'How did $mainScriptureRef apply to your day?'
            : null);

    // Journal progress: real saved-entry count, milestone every 5 entries.
    final entryCount = ref.watch(journalEntryCountProvider);
    final entriesToMilestone = 5 - (entryCount % 5);
    final milestoneProgress = (entryCount % 5) / 5;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onWillPop,
          ),
          title: const Text('Journal Entry'),
          actions: [
            // Export from editor
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Export entry',
              onPressed: _contentController.text.trim().isNotEmpty
                  ? _exportCurrentEntry
                  : null,
            ),
            // Scripture tag button
            IconButton(
              icon: Badge(
                isLabelVisible: _taggedScriptureIds.isNotEmpty,
                label: Text('${_taggedScriptureIds.length}'),
                child: const Icon(Icons.bookmark_outline),
              ),
              tooltip: 'Tag scriptures',
              onPressed: _showScriptureTagPicker,
            ),
            // Save button
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Save',
                onPressed: _save,
              ),
          ],
        ),
        // Voice-to-journal FAB
        floatingActionButton: FloatingActionButton.small(
          onPressed: _toggleVoiceInput,
          backgroundColor: _isListening ? AppTheme.error : AppTheme.primary,
          foregroundColor: Colors.white,
          tooltip: _isListening ? 'Stop dictation' : 'Dictate',
          child: Icon(_isListening ? Icons.stop : Icons.mic),
        ),
        body: Column(
          children: [
            // Voice listening indicator
            if (_isListening)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: 10,
                ),
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _partialSpeechText.isNotEmpty
                            ? _partialSpeechText
                            : 'Listening... speak now',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleVoiceInput,
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "DAILY REFLECTION" label + Hero Heading
                    if (heroHeading != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // "DAILY REFLECTION" uppercase label
                          Text(
                            'DAILY REFLECTION',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.0,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          // Hero heading: Sidekick prompt or scripture question
                          Text(
                            heroHeading,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  height: 1.3,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                        ],
                      ),

                    // Main editor card with gradient background + warm colors
                    Container(
                      constraints: const BoxConstraints(minHeight: 350),
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        // Warm gradient: tertiaryFixed/30 to primaryFixed/30 at 135°
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.tertiaryFixed.withValues(alpha: 0.15),
                            AppTheme.primaryFixed.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: edit icon + date
                          Row(
                            children: [
                              Icon(
                                Icons.edit_note_outlined,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: Text(
                                  'Journal Entry — ${_formatDate()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingLg),

                          // Main textarea with white/surfaceContainerLowest background.
                          // NOT Expanded: this Column sits inside a
                          // SingleChildScrollView, so height is unbounded and a
                          // flex child would fail layout. minLines keeps it tall.
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLowest,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            child: Stack(
                              children: [
                                TextField(
                                  controller: _contentController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: null,
                                  minLines: 8,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        height: 1.6,
                                      ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Begin typing your thoughts here... Let the Spirit guide.',
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.5),
                                          height: 1.6,
                                        ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                // Watermark quote icon (bottom-right, very faint)
                                Positioned(
                                  bottom: 0,
                                  right: -8,
                                  child: Icon(
                                    Icons.format_quote,
                                    size: 120,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.05),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),

                          // Save button, right-aligned. (No chip beside it:
                          // the mockup's milestone chip overflowed narrow
                          // screens and had no real data behind it.)
                          Align(
                            alignment: Alignment.centerRight,
                            // Save button with gradient (primary -> primaryContainer)
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.primaryContainer,
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusRound),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primary.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _hasChanges ? _save : null,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusRound),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingLg,
                                      vertical: AppTheme.spacingMd,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Save Entry',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(
                                            width: AppTheme.spacingMd),
                                        Icon(
                                          Icons.arrow_upward,
                                          size: 18,
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingXl),

                    // Contextual Verse section (if tagged)
                    if (mainScripture != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contextual Verse',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            // Scripture quote in italic Merriweather
                            Text(
                              '"${mainScripture.fullText}"',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.6,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            // Reference below in secondary color
                            Text(
                              mainScripture.reference,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppTheme.secondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                    ],

                    // Portfolio Progress section
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.05),
                        border: Border.all(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JOURNAL PROGRESS',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          // Progress bar
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryContainer
                                  .withValues(alpha: 0.4),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusRound),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: milestoneProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusRound),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            entryCount == 0
                                ? 'Write your first reflection to start your journal.'
                                : '$entryCount ${entryCount == 1 ? 'reflection' : 'reflections'} written — '
                                    '$entriesToMilestone more to your next milestone.',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppTheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingXl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate() {
    // Show when the entry was started, not today — matters when re-editing.
    final now = widget.entry.createdAt;
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.day.toString()}, ${now.year}';
  }
}
