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

/// The three game types (expandable later).
enum GameType {
  matching('Scripture Match', 'Match passages to their references', Icons.swap_horiz),
  wordOrder('Word Builder', 'Arrange scrambled words in order', Icons.sort_by_alpha),
  quiz('Quick Quiz', 'Test your knowledge of key phrases', Icons.quiz);

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
    description: 'Type perfectly — any error resets all',
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
}
