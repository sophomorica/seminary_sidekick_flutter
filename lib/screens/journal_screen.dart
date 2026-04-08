import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../providers/scripture_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/journal_export_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_teaser.dart';

/// Premium journal screen — list of entries + AI reflection prompts.
///
/// Free users see a teaser; premium users get the full experience.
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
    // If launched with a prompt, auto-create a new entry
    if (widget.initialPrompt != null) {
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
      return _JournalEditorView(entry: activeEntry);
    }

    // Otherwise show the journal list
    return _JournalListView(isPremium: isPremium);
  }
}

// ─── Journal List View ──────────────────────────────────────────────────────

class _JournalListView extends ConsumerStatefulWidget {
  final bool isPremium;

  const _JournalListView({required this.isPremium});

  @override
  ConsumerState<_JournalListView> createState() => _JournalListViewState();
}

class _JournalListViewState extends ConsumerState<_JournalListView> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String entryId) {
    setState(() {
      if (_selectedIds.contains(entryId)) {
        _selectedIds.remove(entryId);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(entryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalEntriesProvider);
    final prompts = ref.watch(currentReflectionPromptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? '${_selectedIds.length} selected'
            : 'Journal'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            // Share selected with family
            IconButton(
              icon: const Icon(Icons.family_restroom),
              tooltip: 'Share with family',
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () => _shareWithFamily(context, entries),
            ),
            // Export selected
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Export selected',
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () => _exportSelected(entries),
            ),
          ] else if (widget.isPremium) ...[
            // Export / sharing menu
            if (entries.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'export_all':
                      _exportAll(entries);
                      break;
                    case 'select':
                      _toggleSelectionMode();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'select',
                    child: ListTile(
                      leading: Icon(Icons.checklist),
                      title: Text('Select entries'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_all',
                    child: ListTile(
                      leading: Icon(Icons.file_download_outlined),
                      title: Text('Export all'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New entry',
              onPressed: () {
                ref.read(journalProvider.notifier).createEntry();
              },
            ),
          ],
        ],
      ),
      body: !widget.isPremium
          ? _FreeUserJournalView()
          : entries.isEmpty && prompts.isEmpty
              ? _EmptyJournalView()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Reflection Prompts section
                      if (prompts.isNotEmpty && !_isSelectionMode) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: AppTheme.premiumGold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reflection Prompts',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'From your Seminary Sidekick',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...prompts.map((prompt) => _ReflectionPromptCard(
                              prompt: prompt,
                              onReflect: () {
                                ref
                                    .read(journalProvider.notifier)
                                    .createEntry(prompt: prompt);
                              },
                            )),
                        const SizedBox(height: 8),
                      ],

                      // Entries list
                      if (entries.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            _isSelectionMode
                                ? 'Tap to select entries'
                                : 'Your Entries',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ...entries.map((entry) => _JournalEntryCard(
                              entry: entry,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(entry.id),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(entry.id);
                                } else {
                                  ref
                                      .read(journalProvider.notifier)
                                      .editEntry(entry);
                                }
                              },
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedIds.add(entry.id);
                                  });
                                }
                              },
                              onToggleFavorite: () {
                                ref
                                    .read(journalProvider.notifier)
                                    .toggleFavorite(entry.id);
                              },
                              onDelete: () =>
                                  _confirmDelete(context, ref, entry),
                              onExport: () => _exportSingle(entry),
                              onShareFamily: () =>
                                  _shareEntriesWithFamily([entry]),
                            )),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content:
            const Text('This cannot be undone. Your reflection will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(journalProvider.notifier).deleteEntry(entry.id);
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportSingle(JournalEntry entry) {
    JournalExportService.instance.shareEntry(entry);
  }

  void _exportSelected(List<JournalEntry> allEntries) {
    final selected =
        allEntries.where((e) => _selectedIds.contains(e.id)).toList();
    if (selected.isEmpty) return;
    JournalExportService.instance.exportAsTextFile(selected);
    _toggleSelectionMode();
  }

  void _exportAll(List<JournalEntry> entries) {
    if (entries.isEmpty) return;
    JournalExportService.instance.exportAsTextFile(entries);
  }

  void _shareWithFamily(
      BuildContext context, List<JournalEntry> allEntries) {
    final selected =
        allEntries.where((e) => _selectedIds.contains(e.id)).toList();
    if (selected.isEmpty) return;
    _shareEntriesWithFamily(selected);
    _toggleSelectionMode();
  }

  void _shareEntriesWithFamily(List<JournalEntry> entries) {
    showDialog(
      context: context,
      builder: (ctx) {
        final noteController = TextEditingController();
        return AlertDialog(
          title: const Text('Share with Family'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share ${entries.length == 1 ? 'this reflection' : '${entries.length} reflections'} '
                'with your family. AI prompts will be removed for privacy.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: 'Add a personal note (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                HapticFeedback.lightImpact();
                JournalExportService.instance.shareWithFamily(
                  entries: entries,
                  personalNote: noteController.text.trim().isNotEmpty
                      ? noteController.text.trim()
                      : null,
                );
              },
              icon: const Icon(Icons.family_restroom, size: 18),
              label: const Text('Share'),
            ),
          ],
        );
      },
    );
  }
}

// ─── Reflection Prompt Card ─────────────────────────────────────────────────

class _ReflectionPromptCard extends StatelessWidget {
  final String prompt;
  final VoidCallback onReflect;

  const _ReflectionPromptCard({
    required this.prompt,
    required this.onReflect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppTheme.premiumGold.withValues(alpha: 0.08),
                    AppTheme.premiumGold.withValues(alpha: 0.03),
                  ]
                : [
                    AppTheme.premiumGoldLight.withValues(alpha: 0.4),
                    AppTheme.premiumGoldLight.withValues(alpha: 0.15),
                  ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: AppTheme.premiumGold.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prompt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onReflect();
                },
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Reflect Now'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.premiumGold,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Journal Entry Card ─────────────────────────────────────────────────────

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final VoidCallback? onExport;
  final VoidCallback? onShareFamily;
  final bool isSelectionMode;
  final bool isSelected;

  const _JournalEntryCard({
    required this.entry,
    required this.onTap,
    this.onLongPress,
    required this.onToggleFavorite,
    required this.onDelete,
    this.onExport,
    this.onShareFamily,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(entry.updatedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: isSelected
            ? AppTheme.accent.withValues(alpha: 0.08)
            : null,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + selection/favorite
                Row(
                  children: [
                    if (isSelectionMode) ...[
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 22,
                        color: isSelected ? AppTheme.accent : null,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        entry.title.isNotEmpty ? entry.title : 'Untitled',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isSelectionMode)
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: Icon(
                          entry.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: entry.isFavorite
                              ? AppTheme.error
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),

                // Preview
                if (entry.preview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.preview,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Footer: date, tags, prompt indicator, actions
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                    ),
                    if (entry.hasPrompt) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: AppTheme.premiumGold.withValues(alpha: 0.7),
                      ),
                    ],
                    if (entry.scriptureReferences.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.scriptureReferences.join(', '),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppTheme.accent,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),

                    if (!isSelectionMode) ...[
                      // Context menu for individual entry actions
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (value) {
                          switch (value) {
                            case 'export':
                              onExport?.call();
                              break;
                            case 'share_family':
                              onShareFamily?.call();
                              break;
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'export',
                            child: ListTile(
                              leading: Icon(Icons.ios_share, size: 20),
                              title: Text('Export'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share_family',
                            child: ListTile(
                              leading: Icon(Icons.family_restroom, size: 20),
                              title: Text('Share with family'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline,
                                  size: 20, color: AppTheme.error),
                              title: Text('Delete',
                                  style: TextStyle(color: AppTheme.error)),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ─── Journal Editor View ────────────────────────────────────────────────────

class _JournalEditorView extends ConsumerStatefulWidget {
  final JournalEntry entry;

  const _JournalEditorView({required this.entry});

  @override
  ConsumerState<_JournalEditorView> createState() =>
      _JournalEditorViewState();
}

class _JournalEditorViewState extends ConsumerState<_JournalEditorView> {
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
    final needsSpace =
        insertAt > 0 && currentText.isNotEmpty && !' \t\n'.contains(currentText[insertAt - 1]);

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
          final suffix =
              insertAt < currentText.length ? currentText.substring(insertAt) : '';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  padding: const EdgeInsets.all(16),
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
                          isTagged
                              ? Icons.check_circle
                              : Icons.circle_outlined,
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
                  padding: const EdgeInsets.all(16),
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
                  horizontal: 16,
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show the AI prompt that inspired this entry
                    if (widget.entry.hasPrompt) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.premiumGold.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                            color:
                                AppTheme.premiumGold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppTheme.premiumGold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.entry.prompt!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tagged scriptures
                    if (_taggedScriptureReferences.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _taggedScriptureReferences.map((ref) {
                          return Chip(
                            label: Text(ref),
                            labelStyle: const TextStyle(fontSize: 11),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            backgroundColor:
                                AppTheme.accent.withValues(alpha: 0.1),
                            side: BorderSide(
                              color: AppTheme.accent.withValues(alpha: 0.3),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Title field
                    TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                      decoration: const InputDecoration(
                        hintText: 'Title (optional)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Content field
                    TextField(
                      controller: _contentController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      minLines: 12,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.7,
                          ),
                      decoration: InputDecoration(
                        hintText: widget.entry.hasPrompt
                            ? 'Write your reflection...'
                            : 'What\'s on your mind?',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
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

// ─── Empty State ────────────────────────────────────────────────────────────

class _EmptyJournalView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(currentReflectionPromptsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Your journal is empty',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your thoughts, insights, and reflections as you study.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (prompts.isNotEmpty) ...[
              Text(
                'Start with a prompt from your Sidekick:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.premiumGold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _ReflectionPromptCard(
                prompt: prompts.first,
                onReflect: () {
                  ref
                      .read(journalProvider.notifier)
                      .createEntry(prompt: prompts.first);
                },
              ),
            ] else
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(journalProvider.notifier).createEntry();
                },
                icon: const Icon(Icons.add),
                label: const Text('Start Writing'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Free User View ─────────────────────────────────────────────────────────

class _FreeUserJournalView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.premiumGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.book,
                size: 40,
                color: AppTheme.premiumGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Seminary Sidekick Journal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Capture your insights with AI-powered reflection prompts, '
              'scripture tagging, and personalized journal entries.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const PremiumTeaser(
              headline: 'Unlock your journal',
              body:
                  'Premium members get AI reflection prompts and scripture-tagged journaling.',
              icon: Icons.book,
            ),
          ],
        ),
      ),
    );
  }
}
