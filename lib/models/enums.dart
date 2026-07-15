import 'package:flutter/material.dart';

/// The four scriptural volumes in the Doctrinal Mastery curriculum.
enum ScriptureBook {
  oldTestament('Old Testament', 'OT'),
  newTestament('New Testament', 'NT'),
  bookOfMormon('Book of Mormon', 'BoM'),
  doctrineAndCovenants('Doctrine & Covenants', 'D&C');

  const ScriptureBook(this.displayName, this.abbreviation);
  final String displayName;
  final String abbreviation;
}

/// Mastery is earned through consistent accuracy across difficulty levels.
enum MasteryLevel {
  newScripture(
    label: 'New',
    description: 'Not yet attempted',
    minAccuracy: 0.0,
    color: 0xFF9E9E9E,
    icon: Icons.circle_outlined,
  ),
  learning(
    label: 'Learning',
    description: 'Started practicing, building familiarity',
    minAccuracy: 0.0,
    color: 0xFFFF8A65,
    icon: Icons.auto_stories,
  ),
  familiar(
    label: 'Familiar',
    description: 'Can recognize key phrases and references',
    minAccuracy: 0.60,
    color: 0xFFFFD54F,
    icon: Icons.lightbulb,
  ),
  memorized(
    label: 'Memorized',
    description: 'Can recall passage with minor prompts',
    minAccuracy: 0.80,
    color: 0xFF81C784,
    icon: Icons.psychology,
  ),
  mastered(
    label: 'Mastered',
    description: 'Full recall at highest difficulty',
    minAccuracy: 0.95,
    color: 0xFF64B5F6,
    icon: Icons.workspace_premium,
  ),
  eternal(
    label: 'Eternal',
    description: 'Sustained mastery — engraven upon your heart',
    minAccuracy: 0.95,
    color: 0xFFFFD700,
    icon: Icons.auto_awesome,
  );

  const MasteryLevel({
    required this.label,
    required this.description,
    required this.minAccuracy,
    required this.color,
    required this.icon,
  });

  final String label;
  final String description;
  final double minAccuracy;
  final int color;
  final IconData icon;
}

/// Practice types: Scripture Builder is the mastery tool; matching and quiz are supplementary practice quizzes.
enum GameType {
  matching('Scripture Match', 'Practice matching passages to their references',
      Icons.swap_horiz),
  scriptureBuilder(
      'Scripture Builder', 'Reproduce scripture text from memory', Icons.sort_by_alpha),
  quiz('Quick Quiz', 'Test your recall of key phrases and references', Icons.quiz);

  const GameType(this.displayName, this.description, this.icon);
  final String displayName;
  final String description;
  final IconData icon;
}

/// Difficulty tiers within each game.
enum DifficultyLevel {
  beginner(
    label: 'Beginner',
    description: 'Tap 3-word chunks in order',
    scriptureCount: 4,
    hasTimer: false,
    allowRetry: true,
    extraDistractors: 0,
  ),
  intermediate(
    label: 'Intermediate',
    description: 'Tap 2-word chunks, distractors mixed in',
    scriptureCount: 8,
    hasTimer: true,
    allowRetry: true,
    extraDistractors: 3,
  ),
  advanced(
    label: 'Advanced',
    description: 'Type the passage — errors show red',
    scriptureCount: 4,
    hasTimer: true,
    allowRetry: false,
    extraDistractors: 0,
  ),
  master(
    label: 'Master',
    description: 'Type blind — a wrong word resets all',
    scriptureCount: 4,
    hasTimer: true,
    allowRetry: false,
    extraDistractors: 0,
  );

  const DifficultyLevel({
    required this.label,
    required this.description,
    required this.scriptureCount,
    required this.hasTimer,
    required this.allowRetry,
    required this.extraDistractors,
  });

  final String label;
  final String description;
  final int scriptureCount;
  final bool hasTimer;
  final bool allowRetry;
  final int extraDistractors;

  /// Scripture count specifically for Scripture Match, which scales more
  /// aggressively than other game types. Returns `null` for Master (use all).
  int? get matchingScriptureCount {
    switch (this) {
      case DifficultyLevel.beginner:
        return 8;
      case DifficultyLevel.intermediate:
        return 15;
      case DifficultyLevel.advanced:
        return 25;
      case DifficultyLevel.master:
        return null; // All available scriptures
    }
  }

  /// Question count for Quick Quiz — scales with difficulty.
  int get quizQuestionCount {
    switch (this) {
      case DifficultyLevel.beginner:
        return 10;
      case DifficultyLevel.intermediate:
        return 20;
      case DifficultyLevel.advanced:
        return 30;
      case DifficultyLevel.master:
        return 40;
    }
  }

  /// Returns a description tailored to the specific [gameType].
  String descriptionForGame(GameType gameType) {
    switch (gameType) {
      case GameType.matching:
        switch (this) {
          case DifficultyLevel.beginner:
            return 'Match 8 passages to their references';
          case DifficultyLevel.intermediate:
            return 'Match 15 passages — timed';
          case DifficultyLevel.advanced:
            return 'Match 25 passages — timed, no retries';
          case DifficultyLevel.master:
            return 'Match ALL passages — timed, no retries';
        }
      case GameType.scriptureBuilder:
        switch (this) {
          case DifficultyLevel.beginner:
            return 'Tap 3-word chunks in order';
          case DifficultyLevel.intermediate:
            return 'Tap 2-word chunks, distractors mixed in';
          case DifficultyLevel.advanced:
            return 'Type the passage — first letters shown as hints';
          case DifficultyLevel.master:
            return 'Type blind, word by word — a wrong word resets all';
        }
      case GameType.quiz:
        switch (this) {
          case DifficultyLevel.beginner:
            return '10 questions — pick the right answer';
          case DifficultyLevel.intermediate:
            return '20 questions — a solid challenge';
          case DifficultyLevel.advanced:
            return '30 questions — test your depth';
          case DifficultyLevel.master:
            return '40 questions — the ultimate quiz';
        }
    }
  }
}
