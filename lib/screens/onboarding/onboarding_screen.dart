import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';
import 'mastery_page.dart';
import 'quizzes_page.dart';
import 'welcome_page.dart';
import 'scripture_builder_page.dart';

/// First-launch onboarding that explains the mastery journey.
///
/// 4 pages:
///   1. Welcome — introduce the app's purpose
///   2. Scripture Builder — the central mastery tool with 4 tiers
///   3. What "Mastered" means — 3 perfect Master runs, score meter grades,
///      and the mastery-avatar journey
///   4. Practice quizzes — supplementary recognition tools (same results meter)
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
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.offWhite;

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
                      color: theme.colorScheme.primary,
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
                  WelcomePage(),
                  ScriptureBuilderPage(),
                  MasteredPage(),
                  PracticeQuizzesPage(),
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
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.25),
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
