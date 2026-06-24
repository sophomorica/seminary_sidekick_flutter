import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';
import '../widgets/game_setup_sheet.dart';
import '../widgets/group_play_card.dart';

/// The "Let's Play" screen.
///
/// Reorganised around a single, consistent model: three solo games as peer
/// tiles (Scripture Builder flagged as the mastery tool), then Group Play in
/// its own "play together" section. There is no screen-level difficulty
/// selector anymore — difficulty + scope live inside each game's start sheet
/// ([GameSetupSheet]), so a tap on any tile follows the same flow.
class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48.0),
              Text(
                "Let's Play",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Merriweather',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 12.0),
              Text(
                'Pick a game. Choose your difficulty and which scriptures '
                'when you start.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28.0),

              // ─── Play solo ──────────────────────────────────────────────
              const _SectionEyebrow('PLAY SOLO'),
              const SizedBox(height: 12.0),
              _GameTile(
                title: 'Scripture Builder',
                subtitle: 'Prove a scripture from memory',
                icon: Icons.construction,
                accent: AppTheme.primary,
                masteryBadge: true,
                onTap: () => showGameSetupSheet(
                  context,
                  gameType: GameType.scriptureBuilder,
                ),
              ),
              const SizedBox(height: 12.0),
              _GameTile(
                title: 'Scripture Match',
                subtitle: 'Match key phrases to their references',
                icon: Icons.layers,
                accent: AppTheme.secondary,
                onTap: () => showGameSetupSheet(
                  context,
                  gameType: GameType.matching,
                ),
              ),
              const SizedBox(height: 12.0),
              _GameTile(
                title: 'Quick Quiz',
                subtitle: 'Test your recall and comprehension',
                icon: Icons.quiz,
                accent: AppTheme.accent,
                onTap: () => showGameSetupSheet(
                  context,
                  gameType: GameType.quiz,
                ),
              ),
              const SizedBox(height: 32.0),

              // ─── Play together ──────────────────────────────────────────
              const _SectionEyebrow('PLAY TOGETHER'),
              const SizedBox(height: 12.0),
              const GroupPlayCard(),

              const SizedBox(height: 120), // Bottom padding for floating nav
            ],
          ),
        ),
      ),
    );
  }
}

/// Small uppercase section label.
class _SectionEyebrow extends StatelessWidget {
  final String label;
  const _SectionEyebrow(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

/// A consistent, tappable game tile. Every solo game uses this shape so they
/// read as peers; Scripture Builder gets a small "Mastery" badge to signal it
/// is the tool that actually drives mastery.
class _GameTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool masteryBadge;
  final VoidCallback onTap;

  const _GameTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.masteryBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: masteryBadge
                  ? accent.withValues(alpha: 0.55)
                  : Theme.of(context).colorScheme.outlineVariant,
              width: masteryBadge ? 1.5 : 0.5,
            ),
            boxShadow: AppTheme.editorialShadow,
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontFamily: 'Merriweather',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (masteryBadge) ...[
                          const SizedBox(width: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'MASTERY',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    fontSize: 9,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(
                Icons.chevron_right,
                size: 22,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
