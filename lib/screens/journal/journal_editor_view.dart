import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../providers/scripture_provider.dart';
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
    HapticFeedback.lightImpact();
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

    HapticFeedback.lightImpact();

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMd)),
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
                color: AppTheme.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _partialSpeechText.isNotEmpty
                            ? _partialSpeechText
                            : 'Listening... speak now',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primary,
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
                    // Daily Reflection Header (Sacred Editorial)
                    if (_taggedScriptureReferences.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How did ${_taggedScriptureReferences.first} apply to your day?',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    height: 1.3,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                          ],
                        ),
                      ),

                    // AI Prompt Card (if present)
                    if (widget.entry.hasPrompt) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppTheme.premiumGold.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: AppTheme.premiumGold.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: Text(
                                widget.entry.prompt!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      height: 1.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],

                    // Main content editor with Sacred Editorial warmth
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title field (optional, subtle)
                          if (_titleController.text.isNotEmpty ||
                              !_hasChanges)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spacingMd,
                              ),
                              child: TextField(
                                controller: _titleController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                decoration: InputDecoration(
                                  hintText: 'Reflection title (optional)',
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.3),
                                        fontWeight: FontWeight.w600,
                                      ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),

                          // Main content field
                          TextField(
                            controller: _contentController,
                            textCapitalization:
                                TextCapitalization.sentences,
                            maxLines: null,
                            minLines: 16,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  height: 1.8,
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
                                        .onSurface
                                        .withValues(alpha: 0.35),
                                    height: 1.8,
                                  ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingLg),

                    // Tagged scriptures (Contextual Verse)
                    if (_taggedScriptureReferences.isNotEmpty) ...[
                      Text(
                        'Scripture Context',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Wrap(
                        spacing: AppTheme.spacingSm,
                        runSpacing: AppTheme.spacingSm,
                        children:
                            _taggedScriptureReferences.map((scriptureRef) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingSm,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusRound,
                              ),
                            ),
                            child: Text(
                              scriptureRef,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],

                    // Save to Portfolio Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _hasChanges ? _save : null,
                        child: const Text('Save to Portfolio'),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingMd),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
