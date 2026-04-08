import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_theme.dart';

/// First-launch onboarding that explains the mastery journey.
///
/// 4 pages:
///   1. Welcome — introduce the app's purpose
///   2. Word Builder — the central mastery tool with 4 tiers
///   3. What "Mastered" means — 3 perfect Master runs
///   4. Practice quizzes — supplementary recognition tools
///
/// Skippable at any point. Re-accessible from the home screen help button.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// When true, the user launched this from a help/info button (not first-launch).
  /// Changes the final button from "Get Started" to "Got It".
  final bool isRevisit;

  const OnboardingScreen({super.key, this.isRevisit = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  static const _totalPages = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    if (widget.isRevisit) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor =
        isDark ? AppTheme.darkBackground : AppTheme.offWhite;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: AppTheme.spacingSm, right: AppTheme.spacingMd),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: _onPageChanged,
                children: const [
                  _WelcomePage(),
                  _WordBuilderPage(),
                  _MasteredPage(),
                  _PracticeQuizzesPage(),
                ],
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingMd,
                AppTheme.spacingLg,
                AppTheme.spacingLg,
              ),
              child: Row(
                children: [
                  // Page dots
                  Row(
                    children: List.generate(_totalPages, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 8),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.primary.withValues(alpha: 0.25),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusRound),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Next / Get Started button
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(
                      _currentPage == _totalPages - 1
                          ? (widget.isRevisit ? 'Got It' : 'Get Started')
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Page 1: Welcome
// ────────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book,
              size: 56,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Text(
            'Welcome to\nSeminary Sidekick',
            style: theme.textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Your journey to memorizing the 100 Doctrinal Mastery scriptures '
            'starts here. Each scripture has its own mastery path — '
            'we\'ll show you exactly how it works.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Page 2: Word Builder — the central mastery tool
// ────────────────────────────────────────────────────────────────────

class _WordBuilderPage extends StatelessWidget {
  const _WordBuilderPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sort_by_alpha,
              size: 48,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Word Builder',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Your path to mastery',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // 4 tiers visual
          _TierRow(
            color: Color(MasteryLevel.learning.color),
            icon: Icons.touch_app,
            tier: 'Beginner',
            detail: 'Tap 3-word chunks in order',
            earns: 'Learning',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _TierRow(
            color: Color(MasteryLevel.familiar.color),
            icon: Icons.shuffle,
            tier: 'Intermediate',
            detail: 'Smaller chunks + distractors',
            earns: 'Familiar',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _TierRow(
            color: Color(MasteryLevel.memorized.color),
            icon: Icons.keyboard,
            tier: 'Advanced',
            detail: 'Type it — first-letter hints',
            earns: 'Memorized',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _TierRow(
            color: Color(MasteryLevel.mastered.color),
            icon: Icons.visibility_off,
            tier: 'Master',
            detail: 'Type blind — one mistake resets all',
            earns: 'Mastered',
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String tier;
  final String detail;
  final String earns;

  const _TierRow({
    required this.color,
    required this.icon,
    required this.tier,
    required this.detail,
    required this.earns,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm + 2,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            ),
            child: Text(
              earns,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Page 3: What "Mastered" means
// ────────────────────────────────────────────────────────────────────

class _MasteredPage extends StatelessWidget {
  const _MasteredPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masteredColor = Color(MasteryLevel.mastered.color);
    final eternalColor = Color(MasteryLevel.eternal.color);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: masteredColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 48,
              color: masteredColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Prove You Know It',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
              ),
              children: [
                const TextSpan(
                  text:
                      'Complete all four Word Builder tiers to reach Memorized. '
                      'Then prove it with ',
                ),
                TextSpan(
                  text: '3 consecutive perfect runs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: masteredColor,
                  ),
                ),
                const TextSpan(text: ' at Master difficulty to earn '),
                TextSpan(
                  text: 'Mastered',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: masteredColor,
                  ),
                ),
                const TextSpan(text: ' status.'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Visual: 3 stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.star_rounded,
                  size: 44,
                  color: masteredColor,
                ),
              );
            }),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '3 perfect Master runs = Mastered',
            style: theme.textTheme.titleMedium?.copyWith(
              color: masteredColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Eternal mention
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: eternalColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: eternalColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: eternalColor, size: 28),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eternal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: eternalColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stay Mastered for 6 months and it becomes permanent — '
                        'engraven upon your heart.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Page 4: Practice Quizzes (supplementary)
// ────────────────────────────────────────────────────────────────────

class _PracticeQuizzesPage extends StatelessWidget {
  const _PracticeQuizzesPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz,
              size: 48,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Practice Along\nthe Way',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Two supplementary quizzes help sharpen your recognition '
            'and comprehension — but Word Builder is where mastery is earned.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          const _QuizCard(
            icon: Icons.swap_horiz,
            color: AppTheme.secondary,
            title: 'Scripture Match',
            description: 'Match key phrases to their references.',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          const _QuizCard(
            icon: Icons.quiz,
            color: AppTheme.accent,
            title: 'Quick Quiz',
            description: 'Multiple choice on passages and references.',
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Find them in the Practice tab — they\'re a great warm-up!',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Subtle premium Sidekick mention
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.premiumGold.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.premiumGold,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seminary Sidekick AI',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.premiumGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Unlock deeper understanding with AI-powered insights and personal reflection.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _QuizCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
