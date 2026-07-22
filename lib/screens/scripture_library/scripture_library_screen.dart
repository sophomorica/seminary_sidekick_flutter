import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../models/scripture.dart';
import '../../models/scripture_mastery.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/scripture_mastery_provider.dart';
import '../../services/haptic_service.dart';
import '../../theme/app_theme.dart';

/// How the library list is ordered.
enum _LibrarySort {
  canonical('Canonical order'),
  reference('Reference A–Z'),
  progressHigh('Most progress'),
  progressLow('Least progress'),
  recent('Recently practiced');

  const _LibrarySort(this.label);
  final String label;
}

/// Mastery-status quick filters.
enum _StatusFilter {
  all('All'),
  inProgress('In Progress'),
  needsReview('Needs Review'),
  mastered('Mastered'),
  notStarted('Not Started');

  const _StatusFilter(this.label);
  final String label;
}

/// Sacred Editorial Scripture Library — fast lookup across all 100
/// scriptures with pinned search, volume filter pills, status filters,
/// and sorting. Built for "find it in two taps", not endless scrolling.
///
/// Optional [initialStatus] / [initialBook] come from `/library` query
/// params (e.g. Stats → Mastered drill-down: `?status=mastered&book=oldTestament`).
class ScriptureLibraryScreen extends ConsumerStatefulWidget {
  const ScriptureLibraryScreen({
    super.key,
    this.initialStatus,
    this.initialBook,
  });

  /// `_StatusFilter.name` from the route, e.g. `mastered`.
  final String? initialStatus;

  /// [ScriptureBook.name] from the route, e.g. `oldTestament`.
  final String? initialBook;

  @override
  ConsumerState<ScriptureLibraryScreen> createState() =>
      _ScriptureLibraryScreenState();
}

class _ScriptureLibraryScreenState
    extends ConsumerState<ScriptureLibraryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _searchQuery = '';
  ScriptureBook? _bookFilter; // null = All volumes
  _StatusFilter _statusFilter = _StatusFilter.all;
  _LibrarySort _sort = _LibrarySort.canonical;

  @override
  void initState() {
    super.initState();
    _applyRouteFilters(
      widget.initialStatus,
      widget.initialBook,
      notify: false,
    );
  }

  @override
  void didUpdateWidget(covariant ScriptureLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus ||
        widget.initialBook != oldWidget.initialBook) {
      _applyRouteFilters(widget.initialStatus, widget.initialBook);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Seeds filters from Stats (or other) deep links. No-ops when both
  /// query params are absent so a plain `/library` visit keeps defaults.
  void _applyRouteFilters(
    String? status,
    String? book, {
    bool notify = true,
  }) {
    if (status == null && book == null) return;

    _StatusFilter parsedStatus = _StatusFilter.all;
    if (status != null) {
      for (final value in _StatusFilter.values) {
        if (value.name == status) {
          parsedStatus = value;
          break;
        }
      }
    }

    ScriptureBook? parsedBook;
    if (book != null) {
      for (final value in ScriptureBook.values) {
        if (value.name == book) {
          parsedBook = value;
          break;
        }
      }
    }

    void apply() {
      _statusFilter = parsedStatus;
      _bookFilter = parsedBook;
      _searchController.clear();
      _searchQuery = '';
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _bookFilter != null ||
      _statusFilter != _StatusFilter.all;

  /// Signature used to re-trigger entrance animations when results change.
  String get _filterSignature =>
      '$_searchQuery|${_bookFilter?.name}|${_statusFilter.name}|${_sort.name}';

  void _clearFilters() {
    ref.read(hapticProvider).light();
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _bookFilter = null;
      _statusFilter = _StatusFilter.all;
    });
  }

  void _selectBook(ScriptureBook? book) {
    ref.read(hapticProvider).selection();
    setState(() => _bookFilter = book);
  }

  void _selectStatus(_StatusFilter status) {
    ref.read(hapticProvider).selection();
    setState(() => _statusFilter = status);
  }

  /// Token-based match: every whitespace-separated word in the query must
  /// appear somewhere in the scripture (any field, any order). So
  /// "glory work" still finds Moses 1:39.
  bool _matchesSearch(Scripture s, String query) {
    final haystack = '${s.name} ${s.reference} ${s.keyPhrase} ${s.fullText}'
        .toLowerCase();
    return query
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .every(haystack.contains);
  }

  bool _matchesStatus(ScriptureMastery mastery) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.notStarted:
        return mastery.level == MasteryLevel.newScripture;
      case _StatusFilter.inProgress:
        return mastery.level.index >= MasteryLevel.learning.index &&
            mastery.level.index < MasteryLevel.mastered.index;
      case _StatusFilter.needsReview:
        return mastery.needsReview;
      case _StatusFilter.mastered:
        return mastery.level.index >= MasteryLevel.mastered.index;
    }
  }

  List<Scripture> _visibleScriptures(List<Scripture> all) {
    final query = _searchQuery.trim().toLowerCase();
    final masteries = <String, ScriptureMastery>{
      for (final s in all) s.id: ref.watch(scriptureMasteryProvider(s.id)),
    };

    final filtered = all.where((s) {
      if (_bookFilter != null && s.book != _bookFilter) return false;
      if (!_matchesStatus(masteries[s.id]!)) return false;
      if (query.isNotEmpty && !_matchesSearch(s, query)) return false;
      return true;
    }).toList();

    switch (_sort) {
      case _LibrarySort.canonical:
        break; // Data source is already in canonical order.
      case _LibrarySort.reference:
        filtered.sort((a, b) => a.reference.compareTo(b.reference));
      case _LibrarySort.progressHigh:
        filtered.sort((a, b) => _progressScore(masteries[b.id]!)
            .compareTo(_progressScore(masteries[a.id]!)));
      case _LibrarySort.progressLow:
        filtered.sort((a, b) => _progressScore(masteries[a.id]!)
            .compareTo(_progressScore(masteries[b.id]!)));
      case _LibrarySort.recent:
        filtered.sort((a, b) {
          final aDate = masteries[a.id]!.lastPracticedAny;
          final bDate = masteries[b.id]!.lastPracticedAny;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
    }
    return filtered;
  }

  /// Combined score so higher mastery levels always outrank sub-progress.
  double _progressScore(ScriptureMastery m) =>
      m.level.index * 100 + m.subProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allScriptures = ref.watch(scripturesProvider);
    final visible = _visibleScriptures(allScriptures);

    // Respect the user's font-scale setting when sizing the pinned header.
    final textScale =
        MediaQuery.textScalerOf(context).scale(14) / 14.0;
    final headerExtent = 122.0 * textScale.clamp(1.0, 1.35).toDouble();

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Editorial title — scrolls away to maximize list space
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLg, 60, AppTheme.spacingLg, AppTheme.spacingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Library',
                      style: theme.textTheme.displayMedium?.copyWith(
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${allScriptures.length} SCRIPTURES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.secondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pinned: search + volume pills — always reachable
          SliverPersistentHeader(
            pinned: true,
            delegate: _LibraryHeaderDelegate(
              extent: headerExtent,
              backgroundColor: theme.scaffoldBackgroundColor,
              child: _buildPinnedHeader(context, allScriptures),
            ),
          ),

          // Status filters + sort + result count
          SliverToBoxAdapter(
            child: _buildStatusAndSortRow(context, visible.length),
          ),

          // Results
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd, AppTheme.spacingSm, AppTheme.spacingMd, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildScriptureRow(
                      context, visible[index], index),
                  childCount: visible.length,
                ),
              ),
            ),

          // Bottom padding for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ─── Pinned header: search + volume pills ─────────────────────────

  Widget _buildPinnedHeader(
      BuildContext context, List<Scripture> allScriptures) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search reference, topic, or text...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                prefixIcon:
                    Icon(Icons.search, color: theme.colorScheme.outline),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close,
                            size: 20, color: theme.colorScheme.outline),
                        onPressed: () {
                          ref.read(hapticProvider).light();
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Volume filter pills
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            children: [
              _VolumePill(
                label: 'All',
                color: AppTheme.primary,
                selected: _bookFilter == null,
                onTap: () => _selectBook(null),
              ),
              for (final book in ScriptureBook.values) ...[
                const SizedBox(width: AppTheme.spacingSm),
                _VolumePill(
                  label: book.abbreviation,
                  fullLabel: book.displayName,
                  color: AppTheme.bookColor(book.name),
                  selected: _bookFilter == book,
                  onTap: () =>
                      _selectBook(_bookFilter == book ? null : book),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Status chips + sort menu + result count ──────────────────────

  Widget _buildStatusAndSortRow(BuildContext context, int resultCount) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingSm),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            children: [
              for (final status in _StatusFilter.values) ...[
                _StatusChip(
                  label: status.label,
                  selected: _statusFilter == status,
                  onTap: () => _selectStatus(status),
                ),
                const SizedBox(width: AppTheme.spacingSm),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg, AppTheme.spacingSm, AppTheme.spacingMd, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  resultCount == 1
                      ? '1 SCRIPTURE'
                      : '$resultCount SCRIPTURES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
                ),
              ),
              PopupMenuButton<_LibrarySort>(
                initialValue: _sort,
                onSelected: (value) {
                  ref.read(hapticProvider).selection();
                  setState(() => _sort = value);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                itemBuilder: (context) => [
                  for (final sort in _LibrarySort.values)
                    PopupMenuItem(
                      value: sort,
                      child: Row(
                        children: [
                          Icon(
                            sort == _sort
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: sort == _sort
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(sort.label),
                        ],
                      ),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_vert,
                          size: 16, color: AppTheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        _sort.label.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.secondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Compact scripture row ────────────────────────────────────────

  Widget _buildScriptureRow(
      BuildContext context, Scripture scripture, int index) {
    final theme = Theme.of(context);
    final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
    final level = mastery.level;
    final progress = mastery.subProgress;
    final bookColor = AppTheme.bookColor(scripture.book.name);
    final masteryColor = AppTheme.masteryColor(level.index);
    final started = level != MasteryLevel.newScripture;

    final row = GestureDetector(
      onTap: () {
        ref.read(hapticProvider).light();
        context.push('/scripture/${scripture.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.editorialShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Volume color spine
                Container(width: 4, color: bookColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        14, 12, AppTheme.spacingMd, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                scripture.reference,
                                style:
                                    theme.textTheme.headlineSmall?.copyWith(
                                  fontSize: 15,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (mastery.needsReview) ...[
                              const Icon(Icons.replay_circle_filled,
                                  size: 15, color: AppTheme.warning),
                              const SizedBox(width: 4),
                            ],
                            Icon(level.icon, size: 14, color: masteryColor),
                            const SizedBox(width: 4),
                            Text(
                              level.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: masteryColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scripture.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (started) ...[
                          const SizedBox(height: AppTheme.spacingSm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              minHeight: 3,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                level.index >= MasteryLevel.mastered.index
                                    ? AppTheme.tertiary
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Gentle staggered entrance for the first screenful only.
    if (index < 10) {
      return row
          .animate(key: ValueKey('$_filterSignature-${scripture.id}'))
          .fadeIn(duration: 200.ms, delay: (index * 25).ms)
          .slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut);
    }
    return row;
  }

  // ─── Empty state ──────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final masteredEmpty = _statusFilter == _StatusFilter.mastered &&
        _searchQuery.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            masteredEmpty
                ? Icons.workspace_premium_outlined
                : Icons.menu_book_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            masteredEmpty
                ? 'No mastered scriptures yet'
                : 'No scriptures found',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            masteredEmpty
                ? 'Complete 3 perfect Master runs in Scripture Builder to earn Mastered.'
                : 'Try a different search or clear your filters.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Clear Filters'),
            ),
          ],
          const SizedBox(height: 100), // visual balance above nav bar
        ],
      ),
    );
  }
}

// ─── Pinned header delegate ─────────────────────────────────────────

class _LibraryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Color backgroundColor;
  final Widget child;

  const _LibraryHeaderDelegate({
    required this.extent,
    required this.backgroundColor,
    required this.child,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_LibraryHeaderDelegate oldDelegate) => true;
}

// ─── Volume filter pill ─────────────────────────────────────────────

class _VolumePill extends StatelessWidget {
  final String label;
  final String? fullLabel;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _VolumePill({
    required this.label,
    this.fullLabel,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: fullLabel ?? label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!selected) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status filter chip ─────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              letterSpacing: 0.3,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
