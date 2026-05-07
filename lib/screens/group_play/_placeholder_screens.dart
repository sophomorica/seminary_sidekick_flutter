import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// Placeholder screens for Group Play routes.
///
/// Each route in `app.dart` points at one of these stubs so Phase-3 agents
/// (TASK-053..TASK-056) can replace one screen at a time without ever
/// editing `app.dart`. When a real screen lands, the corresponding placeholder
/// import + reference in `app.dart` is swapped for the real screen.
///
/// Style: matches the project's "still-developing" placeholder pattern —
/// scaffold + back button + screen name + the TASK number that owns the build.

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String taskId;
  final String description;

  const _PlaceholderScreen({
    required this.title,
    required this.taskId,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/practice'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction,
                  size: 64, color: AppTheme.primary),
              const SizedBox(height: AppTheme.spacingLg),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  taskId,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
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

class HostLobbyPlaceholderScreen extends StatelessWidget {
  const HostLobbyPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Host a Game',
      taskId: 'TASK-053',
      description:
          'The host lobby — room setup, code display, joined players, '
          'and Start Game button — lives here once TASK-053 lands.',
    );
  }
}

class JoinLobbyPlaceholderScreen extends StatelessWidget {
  const JoinLobbyPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Join a Game',
      taskId: 'TASK-054',
      description:
          'The join screen — code entry, nickname, and waiting view — '
          'lives here once TASK-054 lands.',
    );
  }
}

class GroupLobbyPlaceholderScreen extends StatelessWidget {
  final String code;
  const GroupLobbyPlaceholderScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderScreen(
      title: 'Lobby — $code',
      taskId: 'TASK-053 / TASK-054',
      description:
          'The shared lobby waiting view. Replaced as part of the host or '
          'join lobby implementation, depending on flow.',
    );
  }
}

class GroupQuizPlaceholderScreen extends StatelessWidget {
  final String code;
  const GroupQuizPlaceholderScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderScreen(
      title: 'Group Quiz — $code',
      taskId: 'TASK-055',
      description:
          'The live multiplayer quiz screen — current question, countdown, '
          'live answer counter, between-question leaderboard — lives here '
          'once TASK-055 lands.',
    );
  }
}

class GroupResultsPlaceholderScreen extends StatelessWidget {
  final String code;
  const GroupResultsPlaceholderScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderScreen(
      title: 'Results — $code',
      taskId: 'TASK-056',
      description:
          'The post-game results screen — top-3 podium, full leaderboard, '
          'share, Play Again — lives here once TASK-056 lands.',
    );
  }
}
