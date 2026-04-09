import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../services/journal_export_service.dart';
import '../../theme/app_theme.dart';
import 'empty_journal_view.dart';

class JournalListView extends ConsumerStatefulWidget {
  final bool isPremium;

  const JournalListView({super.key, required this.isPremium});

  @override
  ConsumerState<JournalListView> createState() => _JournalListViewState();
}

class _JournalListViewState extends ConsumerState<JournalListView> {
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
        title: Text(
            _isSelectionMode ? '${_selectedIds.length} selected' : 'Journal'),
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
              onPressed:
                  _selectedIds.isEmpty ? null : () => _exportSelected(entries),
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
          ? const FreeUserJournalView()
          : entries.isEmpty && prompts.isEmpty
              ? const EmptyJournalView()
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
                        ...prompts.map((prompt) => ReflectionPromptCard(
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

  void _confirmDelete(BuildContext context, WidgetRef ref, JournalEntry entry) {
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

  void _shareWithFamily(BuildContext context, List<JournalEntry> allEntries) {
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

class ReflectionPromptCard extends StatelessWidget {
  final String prompt;
  final VoidCallback onReflect;

  const ReflectionPromptCard({
    super.key,
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
        color: isSelected ? AppTheme.accent.withValues(alpha: 0.08) : null,
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
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
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
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
