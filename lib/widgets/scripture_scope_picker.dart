import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/scripture.dart';
import '../models/scripture_mastery.dart';
import '../models/scripture_scope.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/scripture_provider.dart';
import '../providers/scripture_scope_provider.dart';

/// Reusable scripture-scope picker.
///
/// Shows three sections — quick presets, by-book multi-select, and an
/// individual-scripture searchable list — and emits a [ScriptureScope] via
/// [onChanged]. Used by solo Quick Quiz, solo Scripture Match, group Quiz
/// host lobby, and group Scripture Builder host lobby.
///
/// Two ways to embed:
///   * Drop the widget into a form (lobby setup view)
///   * Call [showScriptureScopePicker] to present a draggable modal sheet
class ScriptureScopePicker extends ConsumerStatefulWidget {
  /// Initial scope. Pass the last-used scope for this context from
  /// [scriptureScopeProvider], or a default like `ScopeAll()`.
  final ScriptureScope initial;

  /// Storage key for the "Restore last used" affordance. When null the
  /// affordance is hidden — useful when the caller wants ad-hoc usage.
  final String? usageContext;

  /// Called every time the local scope changes. The caller is responsible
  /// for persisting via [ScriptureScopeNotifier.saveScope] when the user
  /// commits (e.g. taps Start / Create Room).
  final ValueChanged<ScriptureScope> onChanged;

  /// Whether to render the trailing "Use this scope" CTA. Modal usage
  /// turns this on; inline-form usage typically leaves it off because the
  /// parent screen has its own primary CTA.
  final bool showConfirmButton;

  /// Optional override for the confirm button label.
  final String confirmLabel;

  /// Called when the user taps the confirm CTA. Only invoked if
  /// [showConfirmButton] is true.
  final VoidCallback? onConfirm;

  /// Optional override for the individual-scripture disclosure label.
  final String individualLabel;

  /// When true (default), shows the "Pick specific scriptures" disclosure
  /// section. The host-lobby variant currently leaves this on so teachers
  /// can hand-pick a custom set.
  final bool showIndividualSection;

  const ScriptureScopePicker({
    super.key,
    required this.initial,
    required this.onChanged,
    this.usageContext,
    this.showConfirmButton = false,
    this.confirmLabel = 'Use this scope',
    this.onConfirm,
    this.individualLabel = 'Pick specific scriptures',
    this.showIndividualSection = true,
  });

  @override
  ConsumerState<ScriptureScopePicker> createState() =>
      _ScriptureScopePickerState();
}

class _ScriptureScopePickerState extends ConsumerState<ScriptureScopePicker> {
  late ScriptureScope _scope;
  String _search = '';
  bool _individualOpen = false;

  @override
  void initState() {
    super.initState();
    _scope = widget.initial;
    // If the initial scope is the individual-id variant, expand the section
    // so the current selection is visible.
    if (_scope is ScopeScriptureIds) {
      _individualOpen = true;
    }
  }

  void _update(ScriptureScope next) {
    setState(() => _scope = next);
    widget.onChanged(next);
  }

  void _toggleBook(ScriptureBook b) {
    final currentBooks = _scope is ScopeBooks
        ? Set<ScriptureBook>.from((_scope as ScopeBooks).books)
        : <ScriptureBook>{};
    if (currentBooks.contains(b)) {
      currentBooks.remove(b);
    } else {
      currentBooks.add(b);
    }
    if (currentBooks.isEmpty) {
      _update(const ScopeAll());
    } else if (currentBooks.length == ScriptureBook.values.length) {
      _update(const ScopeAll());
    } else {
      _update(ScopeBooks(currentBooks));
    }
  }

  void _toggleScripture(String id) {
    final current = _scope is ScopeScriptureIds
        ? List<String>.from((_scope as ScopeScriptureIds).ids)
        : <String>[];
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    _update(ScopeScriptureIds(current));
  }

  void _restoreLastUsed() {
    final ctx = widget.usageContext;
    if (ctx == null) return;
    final last = ref.read(scriptureScopeProvider)[ctx];
    if (last != null) _update(last);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(scripturesProvider);
    ScriptureMastery? lookup(String id) =>
        ref.read(scriptureMasteryProvider(id));
    final resolved = _scope.resolve(all, masteryLookup: lookup);
    final hasLastUsed = widget.usageContext != null &&
        ref.watch(scriptureScopeProvider).containsKey(widget.usageContext);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          label: 'QUICK PRESETS',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLastUsed)
                TextButton(
                  onPressed: _restoreLastUsed,
                  child: const Text('Restore'),
                ),
              TextButton(
                onPressed: () => _update(const ScopeAll()),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _PresetChips(
          scope: _scope,
          allCount: all.length,
          onSelect: _update,
        ),

        const SizedBox(height: 20),
        const _SectionHeader(label: 'BY BOOK'),
        const SizedBox(height: 6),
        _BookChipRow(
          scope: _scope,
          onToggle: _toggleBook,
        ),

        if (widget.showIndividualSection) ...[
          const SizedBox(height: 12),
          _IndividualDisclosure(
            label: widget.individualLabel,
            open: _individualOpen,
            onToggle: () =>
                setState(() => _individualOpen = !_individualOpen),
          ),
          if (_individualOpen)
            _IndividualSection(
              search: _search,
              onSearchChanged: (v) => setState(() => _search = v),
              scope: _scope,
              onToggleScripture: _toggleScripture,
            ),
        ],

        const SizedBox(height: 20),
        _SelectionPreview(
          resolved: resolved,
          scope: _scope,
          all: all,
        ),

        if (widget.showConfirmButton) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: resolved.isEmpty ? null : widget.onConfirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
                widget.confirmLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Convenience helper — opens the picker in a draggable modal bottom sheet.
///
/// Returns the final scope the user committed (`null` if dismissed). When
/// [usageContext] is provided, the chosen scope is automatically persisted
/// to [scriptureScopeProvider] under that key.
Future<ScriptureScope?> showScriptureScopePicker(
  BuildContext context, {
  required WidgetRef ref,
  required ScriptureScope initial,
  String? usageContext,
  String title = 'Choose scriptures',
  String confirmLabel = 'Use this scope',
}) async {
  ScriptureScope working = initial;

  final result = await showModalBottomSheet<ScriptureScope>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(ctx)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ScriptureScopePicker(
                      initial: initial,
                      usageContext: usageContext,
                      onChanged: (s) => working = s,
                      showConfirmButton: true,
                      confirmLabel: confirmLabel,
                      onConfirm: () =>
                          Navigator.of(ctx).pop(working),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (result != null && usageContext != null) {
    await ref
        .read(scriptureScopeProvider.notifier)
        .saveScope(usageContext, result);
  }

  return result;
}

// ─── Section building blocks ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _PresetChips extends StatelessWidget {
  final ScriptureScope scope;
  final int allCount;
  final ValueChanged<ScriptureScope> onSelect;

  const _PresetChips({
    required this.scope,
    required this.allCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'All $allCount',
          selected: scope is ScopeAll,
          onTap: () => onSelect(const ScopeAll()),
        ),
        _Chip(
          label: 'Old Testament',
          selected: scope is ScopeBooks &&
              (scope as ScopeBooks).books.length == 1 &&
              (scope as ScopeBooks).books.contains(ScriptureBook.oldTestament),
          onTap: () => onSelect(
            const ScopeBooks({ScriptureBook.oldTestament}),
          ),
        ),
        _Chip(
          label: 'Book of Mormon',
          selected: scope is ScopeBooks &&
              (scope as ScopeBooks).books.length == 1 &&
              (scope as ScopeBooks).books.contains(ScriptureBook.bookOfMormon),
          onTap: () => onSelect(
            const ScopeBooks({ScriptureBook.bookOfMormon}),
          ),
        ),
        _Chip(
          label: 'Needs Review',
          selected: scope is ScopeNeedsReview,
          onTap: () => onSelect(const ScopeNeedsReview()),
        ),
        _Chip(
          label: 'Nearly Mastered',
          selected: scope is ScopeNearlyMastered,
          onTap: () => onSelect(const ScopeNearlyMastered()),
        ),
      ],
    );
  }
}

class _BookChipRow extends StatelessWidget {
  final ScriptureScope scope;
  final ValueChanged<ScriptureBook> onToggle;

  const _BookChipRow({required this.scope, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final selected = scope is ScopeBooks
        ? (scope as ScopeBooks).books
        : <ScriptureBook>{};
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ScriptureBook.values.map((b) {
        return _Chip(
          label: b.abbreviation,
          tooltip: b.displayName,
          selected: selected.contains(b),
          onTap: () => onToggle(b),
        );
      }).toList(),
    );
  }
}

class _IndividualDisclosure extends StatelessWidget {
  final String label;
  final bool open;
  final VoidCallback onToggle;

  const _IndividualDisclosure({
    required this.label,
    required this.open,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              open ? Icons.expand_less : Icons.expand_more,
              size: 22,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndividualSection extends ConsumerWidget {
  final String search;
  final ValueChanged<String> onSearchChanged;
  final ScriptureScope scope;
  final ValueChanged<String> onToggleScripture;

  const _IndividualSection({
    required this.search,
    required this.onSearchChanged,
    required this.scope,
    required this.onToggleScripture,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(scripturesProvider);
    final selectedIds = scope is ScopeScriptureIds
        ? (scope as ScopeScriptureIds).ids.toSet()
        : <String>{};

    final filtered = search.trim().isEmpty
        ? all
        : all.where((s) {
            final q = search.toLowerCase();
            return s.reference.toLowerCase().contains(q) ||
                s.name.toLowerCase().contains(q) ||
                s.keyPhrase.toLowerCase().contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search by reference, topic, or key phrase…',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No scriptures match "$search"',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final s = filtered[i];
                    final isSelected = selectedIds.contains(s.id);
                    return _ScriptureCheckTile(
                      scripture: s,
                      selected: isSelected,
                      onTap: () => onToggleScripture(s.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ScriptureCheckTile extends StatelessWidget {
  final Scripture scripture;
  final bool selected;
  final VoidCallback onTap;

  const _ScriptureCheckTile({
    required this.scripture,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scripture.reference,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    scripture.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionPreview extends StatelessWidget {
  final List<Scripture> resolved;
  final ScriptureScope scope;
  final List<Scripture> all;

  const _SelectionPreview({
    required this.resolved,
    required this.scope,
    required this.all,
  });

  @override
  Widget build(BuildContext context) {
    final count = resolved.length;
    final sample = resolved.take(1).map((s) => s.reference).join();
    final preview = count == 0
        ? 'No scriptures match this scope'
        : count == 1
            ? sample
            : '$sample + ${count - 1} more';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            count == 0 ? Icons.error_outline : Icons.menu_book_outlined,
            size: 18,
            color: count == 0
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count scripture${count == 1 ? '' : 's'} selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  preview,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final chip = ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onPrimary
            : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: Theme.of(context).colorScheme.primary,
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: chip);
    }
    return chip;
  }
}
