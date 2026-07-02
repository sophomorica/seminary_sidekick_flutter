import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book,
              size: 56,
              color: theme.colorScheme.primary,
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
