import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/scripture.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/scripture_mastery_provider.dart';
import '../../providers/study_streak_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../journal/journal_screen.dart';
import '../memorize_screen.dart';
import '../sidekick_chat/sidekick_chat_screen.dart';
import '../upgrade_screen.dart';
import 'encouragement_card.dart';
import 'mastery_path_section.dart';
import 'scripture_connections_card.dart';

enum _DetailTab {
  study,
  scriptureBuilder,
  progress,
}

class ScriptureDetailScreen extends ConsumerStatefulWidget {
  final String scriptureId;

  const ScriptureDetailScreen({
    super.key,
    required this.scriptureId,
  });

  @override
  ConsumerState<ScriptureDetailScreen> createState() =>
      _ScriptureDetailScreenState();
}

class _ScriptureDetailScreenState extends ConsumerState<ScriptureDetailScreen> {
  late final TextEditingController _notesController;
  bool _isEditingNotes = false;
  final FocusNode _notesFocusNode = FocusNode();
  _DetailTab _activeTab = _DetailTab.study;

  @override
  void initState() {
    super.initState();
    final existingNote = ref.read(noteByScriptureProvider(widget.scriptureId));
    _notesController = TextEditingController(text: existingNote ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _saveNotes() {
    ref
        .read(notesProvider.notifier)
        .saveNote(widget.scriptureId, _notesController.text);
    setState(() => _isEditingNotes = false);
    _notesFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final scripture = ref.watch(scriptureByIdProvider(widget.scriptureId));
    final note = ref.watch(noteByScriptureProvider(widget.scriptureId));

    if (scripture == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Scripture not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // Shell already owns the status-bar inset via the app header; don't
      // double-pad. Bottom false so content can clear the floating tab bar
      // with its own spacer (same pattern as Library / Home).
      body: SingleChildScrollView(
          child: Column(
            children: [
              // Header with breadcrumb, reference, topic, and action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLg,
                  AppTheme.spacingMd,
                  AppTheme.spacingLg,
                  AppTheme.spacingXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb navigation
                    Row(
                      children: [
                        GestureDetector(
                          // Opaque so the whole padded area is tappable, not
                          // just the icon/text pixels.
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/library'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingSm,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_back_ios,
                                  size: 14,
                                  color: AppTheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Library',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          scripture.book.displayName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    // Header row: reference + buttons
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Huge reference text
                              Text(
                                scripture.reference,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              // Topic subtitle italic in secondary
                              Text(
                                scripture.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppTheme.secondary,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Main content grid: main (8 cols) + sidebar (4 cols)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    if (isWide) {
                      // Two-column layout
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppTheme.spacingXl,
                        children: [
                          // Main content
                          Expanded(
                            flex: 2,
                            child: _MainContent(
                              scripture: scripture,
                              scriptureId: widget.scriptureId,
                              activeTab: _activeTab,
                              onTabChanged: (tab) {
                                setState(() => _activeTab = tab);
                              },
                              isEditingNotes: _isEditingNotes,
                              onEditToggle: (editing) {
                                setState(() => _isEditingNotes = editing);
                                if (editing) {
                                  _notesFocusNode.requestFocus();
                                } else {
                                  _notesFocusNode.unfocus();
                                }
                              },
                              onSave: _saveNotes,
                              controller: _notesController,
                              focusNode: _notesFocusNode,
                              currentNote: note,
                            ),
                          ),
                          // Sidebar
                          Expanded(
                            flex: 1,
                            child: _Sidebar(
                              scriptureId: widget.scriptureId,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Single column layout
                      return Column(
                        children: [
                          _MainContent(
                            scripture: scripture,
                            scriptureId: widget.scriptureId,
                            activeTab: _activeTab,
                            onTabChanged: (tab) {
                              setState(() => _activeTab = tab);
                            },
                            isEditingNotes: _isEditingNotes,
                            onEditToggle: (editing) {
                              setState(() => _isEditingNotes = editing);
                              if (editing) {
                                _notesFocusNode.requestFocus();
                              } else {
                                _notesFocusNode.unfocus();
                              }
                            },
                            onSave: _saveNotes,
                            controller: _notesController,
                            focusNode: _notesFocusNode,
                            currentNote: note,
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                          _Sidebar(
                            scriptureId: widget.scriptureId,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
      ),
    );
  }
}

// Main content section with scripture text, tabs, and preview
class _MainContent extends ConsumerWidget {
  final Scripture scripture;
  final String scriptureId;
  final _DetailTab activeTab;
  final Function(_DetailTab) onTabChanged;
  final bool isEditingNotes;
  final Function(bool) onEditToggle;
  final VoidCallback onSave;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? currentNote;

  const _MainContent({
    required this.scripture,
    required this.scriptureId,
    required this.activeTab,
    required this.onTabChanged,
    required this.isEditingNotes,
    required this.onEditToggle,
    required this.onSave,
    required this.controller,
    required this.focusNode,
    required this.currentNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scripture text card — passage + footer into Memorize
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingXl,
                  AppTheme.spacingXl,
                  AppTheme.spacingXl,
                  AppTheme.spacingMd,
                ),
                child: _ScriptureTextWidget(scripture: scripture),
              ),
              Material(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MemorizeScreen(scripture: scripture),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                      vertical: AppTheme.spacingMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology_alt_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          'Open Memorization Tool',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingXl),
        // Tab navigation
        _DetailTabGroup(
          activeTab: activeTab,
          onTabChanged: onTabChanged,
        ),
        const SizedBox(height: AppTheme.spacingXl),
        // Tab content
        if (activeTab == _DetailTab.study) ...[
          _KeyPhraseCard(scripture: scripture),
          const SizedBox(height: AppTheme.spacingXl),
          _NotesSection(
            isEditing: isEditingNotes,
            onEditToggle: onEditToggle,
            onSave: onSave,
            controller: controller,
            focusNode: focusNode,
            currentNote: currentNote,
          ),
          if (ref.watch(isPremiumProvider)) ...[
            const SizedBox(height: AppTheme.spacingXl),
            _ReflectLink(
              scriptureId: scriptureId,
              reference: scripture.reference,
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          const _PracticeHubLink(),
        ] else if (activeTab == _DetailTab.scriptureBuilder) ...[
          // Scripture Builder tab content
          HolisticMasterySection(
            scriptureId: scriptureId,
            scripture: scripture,
          ),
        ] else if (activeTab == _DetailTab.progress) ...[
          // Progress tab content
          if (ref.watch(isPremiumProvider)) ...[
            const EncouragementCard(),
            const SizedBox(height: AppTheme.spacingXl),
            ScriptureConnectionsCard(
              currentScriptureId: scriptureId,
            ),
          ],
        ],
      ],
    );
  }
}

// Private widget: pointer to the Practice tab for quiz games.
// Scripture Match and Quick Quiz are multi-scripture games — they live in
// the practice hub, not under an individual scripture.
class _PracticeHubLink extends StatelessWidget {
  const _PracticeHubLink();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/practice'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_esports,
              size: 16,
              color: AppTheme.secondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Looking for Scripture Match or Quick Quiz? Head to Practice',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: AppTheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

// Sidebar section
class _Sidebar extends ConsumerWidget {
  final String scriptureId;

  const _Sidebar({required this.scriptureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ask Your Sidekick card
        if (ref.watch(isPremiumProvider))
          _AskSidekickCard(scriptureId: scriptureId)
        else
          const _SidekickUpgradeCard(),
        const SizedBox(height: AppTheme.spacingXl),
        // Mastery Insights card
        _MasteryInsights(scriptureId: scriptureId),
      ],
    );
  }
}

// Scripture text display with verse numbers
class _ScriptureTextWidget extends StatelessWidget {
  final Scripture scripture;

  const _ScriptureTextWidget({required this.scripture});

  @override
  Widget build(BuildContext context) {
    // Simple display: split by verses if possible
    // For now, just show the full text with proper formatting
    final lines = scripture.fullText.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXl),
            child: Text(
              lines[i],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Merriweather',
                    fontSize: 18,
                    height: 1.8,
                  ),
            ),
          ),
      ],
    );
  }
}

/// Segmented tab group for Study / Scripture Builder / Progress.
class _DetailTabGroup extends StatelessWidget {
  final _DetailTab activeTab;
  final ValueChanged<_DetailTab> onTabChanged;

  const _DetailTabGroup({
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingXs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      // IntrinsicHeight + stretch keeps every pill full-height when the
      // "Scripture Builder" label wraps to two lines on narrow widths.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _DetailTabSegment(
                label: 'Study',
                isActive: activeTab == _DetailTab.study,
                onPressed: () => onTabChanged(_DetailTab.study),
              ),
            ),
            Expanded(
              child: _DetailTabSegment(
                label: 'Scripture Builder',
                isActive: activeTab == _DetailTab.scriptureBuilder,
                onPressed: () => onTabChanged(_DetailTab.scriptureBuilder),
              ),
            ),
            Expanded(
              child: _DetailTabSegment(
                label: 'Progress',
                isActive: activeTab == _DetailTab.progress,
                onPressed: () => onTabChanged(_DetailTab.progress),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTabSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _DetailTabSegment({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // In the dark scheme surfaceContainerLowest is the *darkest* surface, so
    // the "lifted pill" trick inverts — lift with a higher container instead.
    final activePillColor = theme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLowest;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: isActive ? activePillColor : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: isActive ? AppTheme.editorialShadow : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Private widget: Mastery insights
class _MasteryInsights extends ConsumerWidget {
  final String scriptureId;

  const _MasteryInsights({required this.scriptureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(scriptureMasteryProvider(scriptureId));
    final retentionPercent = mastery.overallAccuracy.toInt();
    final streakDays = ref.watch(currentStreakProvider);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Mastery Insights',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Retention Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Retention Rate',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$retentionPercent%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              // Progress bar
              SizedBox(
                width: 96,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: retentionPercent / 100,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.secondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Daily Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Streak',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$streakDays ${streakDays == 1 ? 'Day' : 'Days'}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              // Medal icon
              const Icon(
                Icons.workspace_premium,
                color: AppTheme.tertiary,
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Private widget: Ask Your Sidekick card for premium users
class _AskSidekickCard extends ConsumerWidget {
  final String scriptureId;

  const _AskSidekickCard({required this.scriptureId});

  /// A suggested question about THIS scripture. Picked deterministically by
  /// scripture ID so it stays stable across rebuilds but varies across
  /// scriptures.
  String _suggestedQuestion(Scripture scripture) {
    final templates = [
      'What does "${scripture.name}" mean in ${scripture.reference}?',
      'How can I apply ${scripture.reference} in my life?',
      'What\'s the background of ${scripture.reference}?',
      'Help me understand ${scripture.reference} in simple terms.',
    ];
    final index = (int.tryParse(scripture.id) ?? 0) % templates.length;
    return templates[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scripture = ref.watch(scriptureByIdProvider(scriptureId));
    if (scripture == null) return const SizedBox.shrink();
    final question = _suggestedQuestion(scripture);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.tertiary.withValues(alpha: 0.1),
            AppTheme.tertiaryContainer.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: AppTheme.tertiary.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Stack(
        children: [
          // Blurred decorative circle
          Positioned(
            top: -12,
            right: -12,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tertiary.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.tertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ask Your Sidekick',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.tertiary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),
              // Question
              Text(
                question,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Description
              Text(
                'Your AI companion can explain linguistic roots, cross-reference other scriptures, or help you memorize.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SidekickChatScreen(
                          initialScriptureId: scriptureId,
                          initialMessage: question,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMd,
                    ),
                  ),
                  child: const Text('Start Conversation'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Private widget: Sidekick upgrade card for free users
class _SidekickUpgradeCard extends StatelessWidget {
  const _SidekickUpgradeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.sidekickTint(context, 0.1),
        border: Border.all(
          color: AppTheme.sidekickColor(context).withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.sidekickColor(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Seminary Sidekick',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.sidekickColor(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Unlock AI insights, smart goals, and journal prompts to deepen your understanding.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UpgradeScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sidekickColor(context),
              ),
              child: const Text('Upgrade to Premium'),
            ),
          ),
        ],
      ),
    );
  }
}

// Private widget: Key phrase card
class _KeyPhraseCard extends StatelessWidget {
  final Scripture scripture;

  const _KeyPhraseCard({required this.scripture});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Phrase',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            scripture.keyPhrase,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

// Private widget: Notes section
class _NotesSection extends StatelessWidget {
  final bool isEditing;
  final Function(bool) onEditToggle;
  final VoidCallback onSave;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? currentNote;

  const _NotesSection({
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
    required this.controller,
    required this.focusNode,
    required this.currentNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (isEditing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        controller.text = currentNote ?? '';
                        onEditToggle(false);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onSave,
                      child: const Text('Save'),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => onEditToggle(true),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (isEditing)
            TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Add your notes about this scripture...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => onEditToggle(true),
              child: Text(
                currentNote ?? 'Tap to add notes...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: currentNote != null
                          ? null
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                      height: 1.6,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

// Private widget: Reflect in journal button (TASK-066 — was a faded
// text link that read as body copy; now a real, clearly tappable button).
class _ReflectLink extends StatelessWidget {
  final String scriptureId;
  final String reference;

  const _ReflectLink({
    required this.scriptureId,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.sidekickColor(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JournalScreen(
                initialScriptureId: scriptureId,
                initialScriptureReference: reference,
              ),
            ),
          );
        },
        icon: const Icon(Icons.auto_stories_outlined, size: 18),
        label: const Text('Reflect in your journal'),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
