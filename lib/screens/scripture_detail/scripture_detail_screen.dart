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
        appBar: AppBar(
          title: const Text('Scripture Not Found'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Scripture not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scripture Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reference + Sidekick button header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    scripture.reference,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primary,
                        ),
                  ),
                ),
                // "Ask your Sidekick" — prominent in header for premium
                if (ref.watch(isPremiumProvider))
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SidekickChatScreen(
                            initialScriptureId: widget.scriptureId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppTheme.sidekickGradient(context),
                        ),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusRound),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Ask Sidekick',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const UpgradeScreen()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.sidekickTint(context),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusRound),
                        border: Border.all(
                          color: AppTheme.sidekickColor(context)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14, color: AppTheme.sidekickColor(context)),
                          const SizedBox(width: 4),
                          Text(
                            'Ask Sidekick',
                            style: TextStyle(
                              color: AppTheme.sidekickColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scripture.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Full text
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Text',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      scripture.fullText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Key phrase
            Card(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(height: 8),
                    Text(
                      scripture.keyPhrase,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Holistic mastery progress section — HERO element
            HolisticMasterySection(
              scriptureId: widget.scriptureId,
              scripture: scripture,
            ),
            const SizedBox(height: 16),

            // Premium: Encouragement + Scripture Connections (TASK-040)
            if (ref.watch(isPremiumProvider)) ...[
              const EncouragementCard(),
              ScriptureConnectionsCard(currentScriptureId: widget.scriptureId),
            ],

            // Study tool — Memorize
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MemorizeScreen(scripture: scripture),
                    ),
                  );
                },
                icon: const Icon(Icons.psychology_alt, size: 20),
                label: const Text('Study with Memorize Tool'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: AppTheme.secondary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notes',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (_isEditingNotes)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _notesController.text = note ?? '';
                                  setState(() => _isEditingNotes = false);
                                  _notesFocusNode.unfocus();
                                },
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: _saveNotes,
                                child: const Text('Save'),
                              ),
                            ],
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              setState(() => _isEditingNotes = true);
                              _notesFocusNode.requestFocus();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditingNotes)
                      TextField(
                        controller: _notesController,
                        focusNode: _notesFocusNode,
                        maxLines: null,
                        minLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add your notes about this scripture...',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          setState(() => _isEditingNotes = true);
                          _notesFocusNode.requestFocus();
                        },
                        child: Text(
                          note ?? 'Tap to add notes...',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: note != null
                                        ? null
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                    height: 1.5,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // "Reflect on this verse" — journal entry for premium users
            if (ref.watch(isPremiumProvider))
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JournalScreen(
                          initialScriptureId: widget.scriptureId,
                          initialScriptureReference: scripture.reference,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingXs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note,
                            size: 16, color: AppTheme.sidekickColor(context)),
                        const SizedBox(width: 6),
                        Text(
                          'Reflect on this verse in your journal',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                ),
              ),

            const SizedBox(height: 24),

            // Practice quizzes (recognition tools — not mastery-gating)
            Text(
              'Practice Quizzes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Build recognition and comprehension',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 12),
            ..._buildPracticeButtons(context, widget.scriptureId),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPracticeButtons(
    BuildContext context,
    String scriptureId,
  ) {
    final scripture = ref.read(scriptureByIdProvider(scriptureId));
    if (scripture == null) return [];

    // Only show supplementary quizzes — Word Builder lives in the mastery section
    return GameType.values
        .where((gameType) => gameType != GameType.wordOrder)
        .map((gameType) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
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
