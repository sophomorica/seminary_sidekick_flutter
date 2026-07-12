import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../models/scripture.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/sidekick_provider.dart';
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
  _DetailTab _activeTab = _DetailTab.study;

  @override
  Widget build(BuildContext context) {
    final scripture = ref.watch(scriptureByIdProvider(widget.scriptureId));

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

  const _MainContent({
    required this.scripture,
    required this.scriptureId,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteByScriptureProvider(scriptureId));
    final hasNote = note != null && note.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scripture text card — notes icon + passage + Memorize footer
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingXl,
                      AppTheme.spacingXl,
                      AppTheme.spacingXl + 36,
                      AppTheme.spacingMd,
                    ),
                    child: _ScriptureTextWidget(scripture: scripture),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      tooltip: hasNote ? 'Edit notes' : 'Add notes',
                      onPressed: () => showScriptureNotesSheet(
                        context,
                        scriptureId: scriptureId,
                        reference: scripture.reference,
                      ),
                      icon: Badge(
                        isLabelVisible: hasNote,
                        smallSize: 8,
                        backgroundColor: AppTheme.secondary,
                        child: Icon(
                          hasNote
                              ? Icons.sticky_note_2
                              : Icons.sticky_note_2_outlined,
                          size: 22,
                          color: hasNote
                              ? AppTheme.secondary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
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
        Row(
          children: [
            _TabButton(
              label: 'Study',
              isActive: activeTab == _DetailTab.study,
              onPressed: () => onTabChanged(_DetailTab.study),
            ),
            const SizedBox(width: AppTheme.spacingXl),
            _TabButton(
              label: 'Scripture Builder',
              isActive: activeTab == _DetailTab.scriptureBuilder,
              onPressed: () => onTabChanged(_DetailTab.scriptureBuilder),
            ),
            const SizedBox(width: AppTheme.spacingXl),
            _TabButton(
              label: 'Progress',
              isActive: activeTab == _DetailTab.progress,
              onPressed: () => onTabChanged(_DetailTab.progress),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXl),
        // Tab content
        if (activeTab == _DetailTab.study) ...[
          _KeyPhraseCard(scripture: scripture),
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

// Tab button widget
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.secondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 40,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ],
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

  /// Template starter questions for THIS scripture, tuned to how far along
  /// the mastery path the user is. Seeded by scripture ID + day-of-year so
  /// the same scripture rotates day to day but stays stable across rebuilds.
  List<String> _templateQuestions(Scripture scripture, MasteryLevel level) {
    final ref_ = scripture.reference;
    final common = <String>[
      'What does "${scripture.name}" mean in $ref_?',
      'How can I apply $ref_ in my life this week?',
      'What\'s the historical background of $ref_?',
      'Help me understand $ref_ in simple terms.',
      'What other scriptures connect to $ref_?',
      'Why does "${scripture.keyPhrase}" matter?',
      'Give me a memory trick for $ref_.',
      'What would a prophet say about $ref_?',
    ];
    final byLevel = switch (level) {
      MasteryLevel.newScripture || MasteryLevel.learning => <String>[
          'Where do I start with $ref_?',
          'Break $ref_ into pieces I can memorize.',
          'What\'s the one big idea in $ref_?',
        ],
      MasteryLevel.familiar || MasteryLevel.memorized => <String>[
          'Quiz me on $ref_.',
          'What details of $ref_ do people miss?',
          'How does $ref_ fit the rest of ${scripture.volume}?',
        ],
      MasteryLevel.mastered || MasteryLevel.eternal => <String>[
          'How would I teach $ref_ to a friend?',
          'What deeper meaning is in $ref_?',
          'Challenge me: hardest question about $ref_.',
        ],
    };
    final pool = [...byLevel, ...common];

    // Deterministic daily rotation: scripture ID + day-of-year as seed.
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final seed = (int.tryParse(scripture.id) ?? scripture.id.hashCode) * 31 +
        dayOfYear;
    final picks = <String>[];
    for (var i = 0; picks.length < 3 && i < pool.length; i++) {
      final candidate = pool[(seed + i * 7) % pool.length];
      if (!picks.contains(candidate)) picks.add(candidate);
    }
    return picks;
  }

  void _openChat(BuildContext context, String? question) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SidekickChatScreen(
          initialScriptureId: scriptureId,
          initialMessage: question,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scripture = ref.watch(scriptureByIdProvider(scriptureId));
    if (scripture == null) return const SizedBox.shrink();

    final masteryLevel = ref.watch(scriptureMasteryProvider(scriptureId)).level;
    final aiQuestion =
        ref.watch(starterQuestionForScriptureProvider(scriptureId));

    // AI question (when the session response has one for this scripture)
    // leads; templates fill the remaining chips.
    final questions = <String>[
      if (aiQuestion != null) aiQuestion,
      ..._templateQuestions(scripture, masteryLevel),
    ].take(3).toList();

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
              const SizedBox(height: AppTheme.spacingMd),
              // Lead-in
              Text(
                'Tap a question to start a conversation:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Suggestion chips
              Wrap(
                spacing: AppTheme.spacingSm,
                runSpacing: AppTheme.spacingSm,
                children: [
                  for (var i = 0; i < questions.length; i++)
                    _StarterChip(
                      question: questions[i],
                      // The AI-generated starter gets a sparkle so its
                      // provenance is visible.
                      isAi: aiQuestion != null && i == 0,
                      onTap: () => _openChat(context, questions[i]),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Freeform entry
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _openChat(context, null),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.tertiary,
                  ),
                  child: const Text('Or ask anything →'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Private widget: a tappable starter-question chip on the Ask Sidekick card.
class _StarterChip extends StatelessWidget {
  final String question;
  final bool isAi;
  final VoidCallback onTap;

  const _StarterChip({
    required this.question,
    required this.isAi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: AppTheme.tertiary.withValues(alpha: 0.08),
            border: Border.all(
              color: AppTheme.tertiary.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAi) ...[
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: AppTheme.tertiary,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  question,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
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

/// Opens a notes bottom sheet for a scripture (same slide-up pattern as
/// game setup sheets).
void showScriptureNotesSheet(
  BuildContext context, {
  required String scriptureId,
  required String reference,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScriptureNotesSheet(
      scriptureId: scriptureId,
      reference: reference,
    ),
  );
}

class _ScriptureNotesSheet extends ConsumerStatefulWidget {
  final String scriptureId;
  final String reference;

  const _ScriptureNotesSheet({
    required this.scriptureId,
    required this.reference,
  });

  @override
  ConsumerState<_ScriptureNotesSheet> createState() =>
      _ScriptureNotesSheetState();
}

class _ScriptureNotesSheetState extends ConsumerState<_ScriptureNotesSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _didSave = false;

  @override
  void initState() {
    super.initState();
    final existing =
        ref.read(noteByScriptureProvider(widget.scriptureId)) ?? '';
    _controller = TextEditingController(text: existing);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _persist() {
    if (_didSave) return;
    _didSave = true;
    ref
        .read(notesProvider.notifier)
        .saveNote(widget.scriptureId, _controller.text);
  }

  void _saveAndClose() {
    _persist();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _persist();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
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
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm),
                                ),
                                child: const Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 20,
                                  color: AppTheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notes',
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      widget.reference,
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _saveAndClose,
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          minLines: 8,
                          textCapitalization: TextCapitalization.sentences,
                          onTapOutside: (_) => _focusNode.unfocus(),
                          style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                              ),
                          decoration: InputDecoration(
                            hintText:
                                'Jot a thought, cross-reference, or reminder…',
                            hintStyle:
                                Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                      height: 1.6,
                                    ),
                            filled: true,
                            fillColor: Theme.of(ctx)
                                .colorScheme
                                .surfaceContainerLowest,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(
                              AppTheme.spacingMd,
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
