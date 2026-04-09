import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../models/scripture.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../journal/journal_screen.dart';
import '../memorize_screen.dart';
import '../sidekick_chat/sidekick_chat_screen.dart';
import '../upgrade_screen.dart';
import '../games/matching_game_screen.dart';
import '../games/word_builder/word_builder_screen.dart';
import '../games/quiz_game_screen.dart';
import 'encouragement_card.dart';
import 'mastery_path_section.dart';
import 'scripture_connections_card.dart';

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
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient header with back button and reference
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.surfaceContainerLow,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.surfaceContainerLow,
                      AppTheme.surface,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.spacingLg,
                    right: AppTheme.spacingLg,
                    top: AppTheme.spacingXl,
                    bottom: AppTheme.spacingLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        scripture.reference,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: AppTheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scripture.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scripture text section
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scripture.fullText,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontFamily: 'Merriweather',
                                  fontStyle: FontStyle.italic,
                                  height: 1.8,
                                  fontSize: 17,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Word Builder Preview section
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingLg,
                      ),
                      child: _WordBuilderPreview(
                        scriptureId: widget.scriptureId,
                        scripture: scripture,
                      ),
                    ),

                    // Mastery insights
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXl,
                      ),
                      child: _MasteryInsights(scriptureId: widget.scriptureId),
                    ),

                    // Premium: Ask Your Sidekick section
                    if (ref.watch(isPremiumProvider))
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingLg,
                        ),
                        child: _AskSidekickCard(
                          scriptureId: widget.scriptureId,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingLg,
                        ),
                        child: _SidekickUpgradeCard(),
                      ),

                    // Holistic mastery progress section
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXl,
                      ),
                      child: HolisticMasterySection(
                        scriptureId: widget.scriptureId,
                        scripture: scripture,
                      ),
                    ),

                    // Premium: Encouragement + Scripture Connections
                    if (ref.watch(isPremiumProvider)) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingMd,
                        ),
                        child: const EncouragementCard(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingLg,
                        ),
                        child: ScriptureConnectionsCard(
                          currentScriptureId: widget.scriptureId,
                        ),
                      ),
                    ],

                    // Key phrase
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingLg,
                      ),
                      child: _KeyPhraseCard(scripture: scripture),
                    ),

                    // Notes section
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingLg,
                      ),
                      child: _NotesSection(
                        isEditing: _isEditingNotes,
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

                    // Study tool — Memorize
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingLg,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MemorizeScreen(scripture: scripture),
                              ),
                            );
                          },
                          icon: const Icon(Icons.psychology_alt, size: 20),
                          label: const Text('Study with Memorize Tool'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMd,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Reflect on this verse — journal for premium
                    if (ref.watch(isPremiumProvider))
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingXl,
                        ),
                        child: _ReflectLink(
                          scriptureId: widget.scriptureId,
                          reference: scripture.reference,
                        ),
                      ),

                    // Practice quizzes section
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingMd,
                      ),
                      child: Text(
                        'Practice Quizzes',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingMd,
                      ),
                      child: Text(
                        'Build recognition and comprehension',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ),
                    ..._buildPracticeButtons(context, widget.scriptureId),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPracticeButtons(
    BuildContext context,
    String scriptureId,
  ) {
    final scripture = ref.read(scriptureByIdProvider(scriptureId));
    if (scripture == null) return [];

    return GameType.values
        .where((gameType) => gameType != GameType.wordOrder)
        .map((gameType) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () =>
                _showDifficultyPicker(context, gameType, scripture),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(gameType.icon),
                const SizedBox(width: 8),
                Text('Practice ${gameType.displayName}'),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showDifficultyPicker(
    BuildContext context,
    GameType gameType,
    Scripture scripture,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose Difficulty',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  scripture.reference,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...DifficultyLevel.values.map((difficulty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _launchGame(gameType, difficulty, scripture);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest),
                      ),
                      child: Text(
                        difficulty.label,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchGame(
    GameType gameType,
    DifficultyLevel difficulty,
    Scripture scripture,
  ) {
    final scriptures = [scripture];
    Widget screen;
    switch (gameType) {
      case GameType.matching:
        screen = MatchingGameScreen(
          difficulty: difficulty,
          scriptures: scriptures,
        );
      case GameType.wordOrder:
        screen = WordBuilderScreen(
          difficulty: difficulty,
          scriptures: scriptures,
        );
      case GameType.quiz:
        screen = QuizGameScreen(
          difficulty: difficulty,
          scriptures: scriptures,
        );
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

// Private widget: Word Builder Preview card
class _WordBuilderPreview extends ConsumerWidget {
  final String scriptureId;
  final Scripture scripture;

  const _WordBuilderPreview({
    required this.scriptureId,
    required this.scripture,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Word Builder Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Master the text word by word. Start with guided chunks, progress to blind typing.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
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
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              children: [
                Text(
                  'Retention',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '85%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.success,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              children: [
                Text(
                  'Current Streak',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '7 days',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.secondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Private widget: Ask Your Sidekick card for premium users
class _AskSidekickCard extends ConsumerWidget {
  final String scriptureId;

  const _AskSidekickCard({required this.scriptureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.sidekickGradient(context),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ask Your Sidekick',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Get AI-powered insights about this scripture, journal prompts, and deeper understanding.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SidekickChatScreen(
                      initialScriptureId: scriptureId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
              ),
              child: const Text('Start Conversation'),
            ),
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
        color: AppTheme.surfaceContainerLow,
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

// Private widget: Reflect in journal link
class _ReflectLink extends StatelessWidget {
  final String scriptureId;
  final String reference;

  const _ReflectLink({
    required this.scriptureId,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JournalScreen(
              initialScriptureId: scriptureId,
              initialScriptureReference: reference,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note,
              size: 16,
              color: AppTheme.sidekickColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              'Reflect on this verse in your journal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.sidekickColor(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: AppTheme.sidekickColor(context),
            ),
          ],
        ),
      ),
    );
  }
}
