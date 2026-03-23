import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../providers/quiz_game_provider.dart';
import '../../theme/app_theme.dart';
import 'game_results_screen.dart';

class QuizGameScreen extends ConsumerStatefulWidget {
  final DifficultyLevel difficulty;
  final ScriptureBook? bookFilter;

  const QuizGameScreen({
    super.key,
    required this.difficulty,
    this.bookFilter,
  });

  @override
  ConsumerState<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends ConsumerState<QuizGameScreen> {
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizGameProvider.notifier).startGame(
            difficulty: widget.difficulty,
            bookFilter: widget.bookFilter,
          );
      _startTimer();
    });
  }

  void _startTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(
            ref.read(quizGameProvider).startTime,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(quizGameProvider);
    final notifier = ref.read(quizGameProvider.notifier);

    // Navigate to results when complete
    ref.listen<QuizGameState>(quizGameProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        _onGameComplete(next);
      }
    });

    final question = gameState.currentQuestion;

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        title: Text(widget.difficulty.label),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_elapsed),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: question == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress header
                _ProgressHeader(
                  current: gameState.currentIndex + 1,
                  total: gameState.totalQuestions,
                  correct: gameState.correctAnswers,
                  incorrect: gameState.incorrectAnswers,
                ),
                // Question area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question type label
                        Text(
                          _getQuestionLabel(question.type),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        // Prompt card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            question.prompt,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Answer options
                        ...question.options.map((option) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AnswerOption(
                              text: option,
                              isSelected: gameState.selectedAnswer == option,
                              isAnswered: gameState.isAnswered,
                              isCorrect: option == question.correctAnswer,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                notifier.selectAnswer(option);
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        // Action button
                        if (!gameState.isAnswered)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.gold,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            onPressed: gameState.selectedAnswer != null
                                ? () {
                                    HapticFeedback.mediumImpact();
                                    notifier.submitAnswer();
                                  }
                                : null,
                            child: const Text('Submit Answer',
                                style: TextStyle(fontSize: 16)),
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              notifier.nextQuestion();
                            },
                            child: Text(
                              gameState.currentIndex + 1 >=
                                      gameState.totalQuestions
                                  ? 'See Results'
                                  : 'Next Question',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        // Feedback text after answering
                        if (gameState.isAnswered) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: gameState.isCorrect
                                  ? AppTheme.successLight
                                  : AppTheme.errorLight,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  gameState.isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: gameState.isCorrect
                                      ? AppTheme.success
                                      : AppTheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    gameState.isCorrect
                                        ? 'Correct!'
                                        : 'The answer was: ${question.correctAnswer}',
                                    style: TextStyle(
                                      color: gameState.isCorrect
                                          ? AppTheme.success
                                          : AppTheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _getQuestionLabel(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.phraseToReference:
        return 'WHICH REFERENCE MATCHES THIS KEY PHRASE?';
      case QuizQuestionType.referenceToPhrase:
        return 'WHICH KEY PHRASE MATCHES THIS REFERENCE?';
      case QuizQuestionType.passageToReference:
        return 'WHICH SCRIPTURE CONTAINS THIS PASSAGE?';
    }
  }

  void _onGameComplete(QuizGameState finalState) {
    _elapsedTimer?.cancel();
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameResultsScreen(
            gameType: GameType.quiz,
            difficulty: widget.difficulty,
            correctMatches: finalState.correctAnswers,
            incorrectAttempts: finalState.incorrectAnswers,
            totalPairs: finalState.totalQuestions,
            completionTime:
                finalState.completionTime ?? _elapsed,
            starRating: finalState.starRating,
          ),
        ),
      );
    });
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Playing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quit', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ─── Progress Header ────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final int correct;
  final int incorrect;

  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.correct,
    required this.incorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $current of $total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Row(
                children: [
                  if (correct > 0) ...[
                    const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                    const SizedBox(width: 2),
                    Text('$correct',
                        style: const TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600)),
                  ],
                  if (correct > 0 && incorrect > 0) const SizedBox(width: 12),
                  if (incorrect > 0) ...[
                    const Icon(Icons.cancel, size: 16, color: AppTheme.error),
                    const SizedBox(width: 2),
                    Text('$incorrect',
                        style: const TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? (current - 1) / total : 0,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Answer Option Tile ─────────────────────────────────────────

class _AnswerOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.text,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? trailingIcon;

    if (isAnswered) {
      if (isCorrect) {
        bgColor = AppTheme.successLight;
        borderColor = AppTheme.success;
        textColor = AppTheme.success;
        trailingIcon = Icons.check_circle;
      } else if (isSelected) {
        bgColor = AppTheme.errorLight;
        borderColor = AppTheme.error;
        textColor = AppTheme.error;
        trailingIcon = Icons.cancel;
      } else {
        bgColor = Colors.white;
        borderColor = Colors.grey.shade200;
        textColor = Colors.grey.shade400;
        trailingIcon = null;
      }
    } else if (isSelected) {
      bgColor = AppTheme.gold.withValues(alpha: 0.1);
      borderColor = AppTheme.gold;
      textColor = AppTheme.dark;
      trailingIcon = null;
    } else {
      bgColor = Colors.white;
      borderColor = Colors.grey.shade300;
      textColor = AppTheme.dark;
      trailingIcon = null;
    }

    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: borderColor,
            width: isSelected || (isAnswered && isCorrect) ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: isSelected || (isAnswered && isCorrect)
                          ? FontWeight.w600
                          : FontWeight.normal,
                      height: 1.4,
                    ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: borderColor, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
