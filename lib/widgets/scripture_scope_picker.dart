import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/scripture.dart';
import '../models/scripture_scope.dart';
import '../providers/mastery_dates_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/scripture_provider.dart';
import '../providers/scripture_scope_provider.dart';
import 'selection_pill.dart';

/// Reusable scripture-scope picker.
///
/// Multi-select filters (books + Needs Review / Nearly Mastered) narrow the
/// pool. "Pick specific scriptures" opens a selection page (in-place when
/// [fillHeight] is true, otherwise a nested sheet) so the user can hand-pick
/// a subset. Used by solo Quick Quiz, solo Scripture Match, group Quiz host
/// lobby, and group Scripture Builder host lobby.
///
/// Two ways to embed:
///   * Drop the widget into a form (lobby setup view)
///   * Call [showScriptureScopePicker] to present a draggable modal sheet
class ScriptureScopePicker extends ConsumerStatefulWidget {
  /// Initial scope. Pass the last-used scope for this context from
  /// [scriptureScopeProvider], or a default like `const ScriptureScope()`.
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

  /// Optional override for the individual-scripture entry label.
  final String individualLabel;

  /// When true (default), shows the "Pick specific scriptures" entry row.
  final bool showIndividualSection;

  /// When true, the picker fills a bounded parent (e.g. [Expanded]) and swaps
  /// to the selection page in place. Sheet embeds should set this true.
  final bool fillHeight;

  /// Scroll controller for the default (filters) view when [fillHeight].
  final ScrollController? scrollController;

  /// Pinned above the default-view scroll area (e.g. sheet title row).
  /// Stays fixed so it shares the same y as the selection-view title (R8.2).
  final Widget? pinnedHeader;

  /// Widgets rendered above the filter section on the default view (e.g.
  /// difficulty controls in [GameSetupSheet]).
  final Widget? aboveFilters;

  /// Widgets rendered below the selection preview on the default view.
  final Widget? belowFilters;

  /// Notifies when the selection page opens/closes (for sheet sizing).
  final ValueChanged<bool>? onSelectionViewChanged;

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
    this.fillHeight = false,
    this.scrollController,
    this.pinnedHeader,
    this.aboveFilters,
    this.belowFilters,
    this.onSelectionViewChanged,
  });

  @override
  ConsumerState<ScriptureScopePicker> createState() =>
      _ScriptureScopePickerState();
}

class _ScriptureScopePickerState extends ConsumerState<ScriptureScopePicker> {
  static const _pageAnim = Duration(milliseconds: 200);

  late ScriptureScope _scope;
  String _search = '';
  bool _selectionView = false;

  @override
  void initState() {
    super.initState();
    _scope = widget.initial;
    _scheduleSanitize();
  }

  @override
  void didUpdateWidget(covariant ScriptureScopePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync when the parent supplies a genuinely new scope (e.g. the host
    // lobby restoring a different mode's last-used scope). Normal parent
    // rebuilds echo our own onChanged value back, so `initial == _scope`
    // and this is a no-op.
    if (widget.initial != oldWidget.initial && widget.initial != _scope) {
      _scope = widget.initial;
      _scheduleSanitize();
    }
  }

  void _scheduleSanitize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sanitizeUnavailableStatusFlags();
    });
  }

  MasteryLookup get _lookup =>
      (id) => ref.read(scriptureMasteryProvider(id));

  /// Status availability is independent of the current book selection.
  bool _statusAvailable(bool needsReview, bool nearlyMastered) {
    final all = ref.read(scripturesProvider);
    return ScriptureScope(
      needsReview: needsReview,
      nearlyMastered: nearlyMastered,
    ).filterPool(all, masteryLookup: _lookup).isNotEmpty;
  }

  ScriptureScope _clearedUnavailableStatus(ScriptureScope scope) {
    var next = scope;
    if (scope.needsReview && !_statusAvailable(true, false)) {
      next = next.copyWith(needsReview: false);
    }
    if (scope.nearlyMastered && !_statusAvailable(false, true)) {
      next = next.copyWith(nearlyMastered: false);
    }
    return next;
  }

  void _sanitizeUnavailableStatusFlags() {
    final sanitized = _clearedUnavailableStatus(_scope);
    if (sanitized == _scope) return;
    final all = ref.read(scripturesProvider);
    final pruned = sanitized.prunedToFilter(all, masteryLookup: _lookup);
    setState(() => _scope = pruned);
    widget.onChanged(pruned);
  }

  void _update(ScriptureScope next) {
    final all = ref.read(scripturesProvider);
    final sanitized = _clearedUnavailableStatus(next);
    final pruned = sanitized.prunedToFilter(all, masteryLookup: _lookup);
    setState(() => _scope = pruned);
    widget.onChanged(pruned);
  }

  void _toggleBook(ScriptureBook b) {
    final books = Set<ScriptureBook>.from(_scope.books);
    if (books.contains(b)) {
      books.remove(b);
    } else {
      books.add(b);
    }
    _update(_scope.copyWith(books: books));
  }

  void _toggleNeedsReview() {
    _update(_scope.copyWith(needsReview: !_scope.needsReview));
  }

  void _toggleNearlyMastered() {
    _update(_scope.copyWith(nearlyMastered: !_scope.nearlyMastered));
  }

  void _toggleScripture(String id) {
    final current = List<String>.from(_scope.specificIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    _update(_scope.copyWith(specificIds: current));
  }

  void _clearSpecificIds() {
    _update(
      ScriptureScope(
        books: _scope.books,
        needsReview: _scope.needsReview,
        nearlyMastered: _scope.nearlyMastered,
      ),
    );
  }

  void _restoreLastUsed() {
    final ctx = widget.usageContext;
    if (ctx == null) return;
    final last = ref.read(scriptureScopeProvider)[ctx];
    if (last != null) _update(last);
  }

  void _clear() => _update(const ScriptureScope());

  void _setSelectionView(bool open) {
    if (_selectionView == open) return;
    setState(() => _selectionView = open);
    widget.onSelectionViewChanged?.call(open);
  }

  Future<void> _openSelection(List<Scripture> pool, List<Scripture> all) async {
    // The search field starts empty on every open, so the filter state
    // must match — otherwise the list stays filtered by stale text.
    _search = '';
    if (widget.fillHeight) {
      _setSelectionView(true);
      return;
    }
    widget.onSelectionViewChanged?.call(true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final livePool =
                _scope.filterPool(all, masteryLookup: _lookup);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.95,
                minChildSize: 0.7,
                maxChildSize: 0.95,
                expand: false,
                builder: (sheetCtx, _) {
                  return Material(
                    color: Theme.of(sheetCtx).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: _SelectionPage(
                          title: widget.individualLabel,
                          filterSummary:
                              _filterSummary(all, livePool.length),
                          search: _search,
                          onSearchChanged: (v) {
                            setState(() => _search = v);
                            setModalState(() {});
                          },
                          pool: livePool,
                          selectedIds: _scope.specificIds.toSet(),
                          onToggleScripture: (id) {
                            _toggleScripture(id);
                            setModalState(() {});
                          },
                          onBack: () => Navigator.of(sheetCtx).pop(),
                          onDone: () => Navigator.of(sheetCtx).pop(),
                          onClear: _scope.specificIds.isEmpty
                              ? null
                              : () {
                                  _clearSpecificIds();
                                  setModalState(() {});
                                },
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
    if (mounted) widget.onSelectionViewChanged?.call(false);
  }

  String _filterSummary(List<Scripture> all, int poolCount) {
    final filterOnly = ScriptureScope(
      books: _scope.books,
      needsReview: _scope.needsReview,
      nearlyMastered: _scope.nearlyMastered,
    );
    return '${filterOnly.shortLabel(all)} · $poolCount scriptures';
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(scripturesProvider);
    // Rebuild status-chip availability when mastery inputs change.
    ref.watch(progressProvider);
    ref.watch(masteryDatesProvider);
    final resolved = _scope.resolve(all, masteryLookup: _lookup);
    final pool = _scope.filterPool(all, masteryLookup: _lookup);
    final needsReviewEnabled = _statusAvailable(true, false);
    final nearlyMasteredEnabled = _statusAvailable(false, true);
    // If mastery changed while the picker is open and emptied a selected
    // status pool, drop the stale flag — otherwise the pill renders
    // unselected/disabled while the scope still filters on it (empty
    // resolve, Start disabled, no visible cause).
    if ((_scope.needsReview && !needsReviewEnabled) ||
        (_scope.nearlyMastered && !nearlyMasteredEnabled)) {
      _scheduleSanitize();
    }
    final hasLastUsed = widget.usageContext != null &&
        ref.watch(scriptureScopeProvider).containsKey(widget.usageContext);

    final defaultView = _DefaultView(
      key: const ValueKey('default'),
      scrollController: widget.fillHeight ? widget.scrollController : null,
      pinnedHeader: widget.pinnedHeader,
      aboveFilters: widget.aboveFilters,
      belowFilters: widget.belowFilters,
      hasLastUsed: hasLastUsed,
      onRestore: _restoreLastUsed,
      onClear: _clear,
      scope: _scope,
      needsReviewEnabled: needsReviewEnabled,
      nearlyMasteredEnabled: nearlyMasteredEnabled,
      onToggleBook: _toggleBook,
      onToggleNeedsReview: _toggleNeedsReview,
      onToggleNearlyMastered: _toggleNearlyMastered,
      showIndividualSection: widget.showIndividualSection,
      individualLabel: widget.individualLabel,
      poolCount: pool.length,
      selectedCount: _scope.specificIds.length,
      onOpenSelection: () => _openSelection(pool, all),
      resolved: resolved,
      all: all,
      showConfirmButton: widget.showConfirmButton,
      confirmLabel: widget.confirmLabel,
      onConfirm: widget.onConfirm,
    );

    if (!widget.fillHeight) {
      return defaultView;
    }

    // Opaque push (no FadeTransition) — ClipRect + surface fill so views
    // never cross-fade through each other (R8.1).
    final surface = Theme.of(context).colorScheme.surface;
    return ClipRect(
      child: AnimatedSwitcher(
        duration: _pageAnim,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final isSelection = child.key == const ValueKey('selection');
          final offset = Tween<Offset>(
            begin: Offset(isSelection ? 1 : -1, 0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: offset,
            child: ColoredBox(color: surface, child: child),
          );
        },
        child: _selectionView
            ? _SelectionPage(
                key: const ValueKey('selection'),
                title: widget.individualLabel,
                filterSummary: _filterSummary(all, pool.length),
                search: _search,
                onSearchChanged: (v) => setState(() => _search = v),
                pool: pool,
                selectedIds: _scope.specificIds.toSet(),
                onToggleScripture: _toggleScripture,
                onBack: () => _setSelectionView(false),
                onDone: () => _setSelectionView(false),
                onClear:
                    _scope.specificIds.isEmpty ? null : _clearSpecificIds,
              )
            : defaultView,
      ),
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
      return _ScriptureScopePickerSheet(
        initial: initial,
        usageContext: usageContext,
        title: title,
        confirmLabel: confirmLabel,
        onChanged: (s) => working = s,
        onConfirm: () => Navigator.of(sheetContext).pop(working),
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

class _ScriptureScopePickerSheet extends StatefulWidget {
  final ScriptureScope initial;
  final String? usageContext;
  final String title;
  final String confirmLabel;
  final ValueChanged<ScriptureScope> onChanged;
  final VoidCallback onConfirm;

  const _ScriptureScopePickerSheet({
    required this.initial,
    required this.usageContext,
    required this.title,
    required this.confirmLabel,
    required this.onChanged,
    required this.onConfirm,
  });

  @override
  State<_ScriptureScopePickerSheet> createState() =>
      _ScriptureScopePickerSheetState();
}

class _ScriptureScopePickerSheetState extends State<_ScriptureScopePickerSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      // Constant sheet size — page-swap only slides content (R7.1).
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
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
              child: Column(
                children: [
                  // Hoisted drag handle — shared by default + selection (R8.2).
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: ScriptureScopePicker(
                        initial: widget.initial,
                        usageContext: widget.usageContext,
                        onChanged: widget.onChanged,
                        showConfirmButton: true,
                        confirmLabel: widget.confirmLabel,
                        onConfirm: widget.onConfirm,
                        fillHeight: true,
                        scrollController: scrollController,
                        pinnedHeader: SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              const SizedBox(width: 48, height: 48),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  key: const Key('scope-setup-title'),
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Section building blocks ────────────────────────────────────────────────

class _DefaultView extends StatelessWidget {
  final ScrollController? scrollController;
  final Widget? pinnedHeader;
  final Widget? aboveFilters;
  final Widget? belowFilters;
  final bool hasLastUsed;
  final VoidCallback onRestore;
  final VoidCallback onClear;
  final ScriptureScope scope;
  final bool needsReviewEnabled;
  final bool nearlyMasteredEnabled;
  final ValueChanged<ScriptureBook> onToggleBook;
  final VoidCallback onToggleNeedsReview;
  final VoidCallback onToggleNearlyMastered;
  final bool showIndividualSection;
  final String individualLabel;
  final int poolCount;
  final int selectedCount;
  final VoidCallback onOpenSelection;
  final List<Scripture> resolved;
  final List<Scripture> all;
  final bool showConfirmButton;
  final String confirmLabel;
  final VoidCallback? onConfirm;

  const _DefaultView({
    super.key,
    required this.scrollController,
    required this.pinnedHeader,
    required this.aboveFilters,
    required this.belowFilters,
    required this.hasLastUsed,
    required this.onRestore,
    required this.onClear,
    required this.scope,
    required this.needsReviewEnabled,
    required this.nearlyMasteredEnabled,
    required this.onToggleBook,
    required this.onToggleNeedsReview,
    required this.onToggleNearlyMastered,
    required this.showIndividualSection,
    required this.individualLabel,
    required this.poolCount,
    required this.selectedCount,
    required this.onOpenSelection,
    required this.resolved,
    required this.all,
    required this.showConfirmButton,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final scrollBody = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (aboveFilters != null) ...[
          aboveFilters!,
          const SizedBox(height: 20),
        ],
        _SectionHeader(
          label: 'FILTER',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLastUsed)
                TextButton(
                  onPressed: onRestore,
                  child: const Text('Restore'),
                ),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _FilterChips(
          scope: scope,
          needsReviewEnabled: needsReviewEnabled,
          nearlyMasteredEnabled: nearlyMasteredEnabled,
          onToggleBook: onToggleBook,
          onToggleNeedsReview: onToggleNeedsReview,
          onToggleNearlyMastered: onToggleNearlyMastered,
        ),
        if (showIndividualSection) ...[
          const SizedBox(height: 12),
          _IndividualEntryRow(
            label: individualLabel,
            poolCount: poolCount,
            selectedCount: selectedCount,
            onTap: onOpenSelection,
          ),
        ],
        const SizedBox(height: 20),
        _SelectionPreview(
          resolved: resolved,
          scope: scope,
          all: all,
        ),
        if (showConfirmButton) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: resolved.isEmpty ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        if (belowFilters != null) ...[
          const SizedBox(height: 20),
          belowFilters!,
        ],
      ],
    );

    if (scrollController == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinnedHeader != null) ...[
            pinnedHeader!,
            const SizedBox(height: 12),
          ],
          scrollBody,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pinnedHeader != null) ...[
          pinnedHeader!,
          const SizedBox(height: 12),
        ],
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [scrollBody],
          ),
        ),
      ],
    );
  }
}

class _SelectionPage extends StatelessWidget {
  final String title;
  final String filterSummary;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final List<Scripture> pool;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleScripture;
  final VoidCallback onBack;
  final VoidCallback onDone;
  final VoidCallback? onClear;

  const _SelectionPage({
    super.key,
    required this.title,
    required this.filterSummary,
    required this.search,
    required this.onSearchChanged,
    required this.pool,
    required this.selectedIds,
    required this.onToggleScripture,
    required this.onBack,
    required this.onDone,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = search.trim().isEmpty
        ? pool
        : pool.where((s) {
            final q = search.toLowerCase();
            return s.reference.toLowerCase().contains(q) ||
                s.name.toLowerCase().contains(q) ||
                s.keyPhrase.toLowerCase().contains(q);
          }).toList();
    final selectedCount = selectedIds.length;

    // Same 48×48 leading/trailing slots as GameSetupSheet pinnedHeader
    // so title baselines share y under the hoisted drag handle (R8.2).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  key: const Key('scope-selection-title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 48, height: 48),
            ],
          ),
        ),
        Text(
          filterSummary,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('scope-scripture-search'),
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
        Expanded(
          child: pool.isEmpty
              ? Center(
                  child: Text(
                    'No scriptures match the current filters',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                )
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No scriptures match "$search"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final s = filtered[i];
                        return _ScriptureCheckTile(
                          scripture: s,
                          selected: selectedIds.contains(s.id),
                          onTap: () => onToggleScripture(s.id),
                        );
                      },
                    ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      '$selectedCount selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onClear != null)
                    TextButton(
                      onPressed: onClear,
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: SelectionPill(
                label: 'Done',
                selected: true,
                onTap: onDone,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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

class _FilterChips extends StatelessWidget {
  static const double _gap = 8;

  final ScriptureScope scope;
  final bool needsReviewEnabled;
  final bool nearlyMasteredEnabled;
  final ValueChanged<ScriptureBook> onToggleBook;
  final VoidCallback onToggleNeedsReview;
  final VoidCallback onToggleNearlyMastered;

  const _FilterChips({
    required this.scope,
    required this.needsReviewEnabled,
    required this.nearlyMasteredEnabled,
    required this.onToggleBook,
    required this.onToggleNeedsReview,
    required this.onToggleNearlyMastered,
  });

  @override
  Widget build(BuildContext context) {
    final bookChips = [
      for (final book in kScopeBookOrder)
        SelectionPill(
          label: book == ScriptureBook.doctrineAndCovenants
              ? 'Doctrine and Covenants'
              : book.displayName,
          selected: scope.books.contains(book),
          onTap: () => onToggleBook(book),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < bookChips.length; row += 2) ...[
          if (row > 0) const SizedBox(height: _gap),
          Row(
            children: [
              Expanded(child: bookChips[row]),
              const SizedBox(width: _gap),
              Expanded(
                child: row + 1 < bookChips.length
                    ? bookChips[row + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
        const SizedBox(height: _gap),
        Row(
          children: [
            Expanded(
              child: SelectionPill(
                label: 'Needs Review',
                selected: scope.needsReview && needsReviewEnabled,
                enabled: needsReviewEnabled,
                onTap: onToggleNeedsReview,
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: SelectionPill(
                label: 'Nearly Mastered',
                selected: scope.nearlyMastered && nearlyMasteredEnabled,
                enabled: nearlyMasteredEnabled,
                onTap: onToggleNearlyMastered,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IndividualEntryRow extends StatelessWidget {
  final String label;
  final int poolCount;
  final int selectedCount;
  final VoidCallback onTap;

  const _IndividualEntryRow({
    required this.label,
    required this.poolCount,
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = selectedCount > 0
        ? '$selectedCount of $poolCount selected'
        : '$poolCount in filter';

    return InkWell(
      key: const Key('scope-pick-specific'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
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
        ? 'No scriptures match this filter'
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
