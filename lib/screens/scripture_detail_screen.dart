import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/scripture_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mastery_badge.dart';
import 'memorize_screen.dart';

class ScriptureDetailScreen extends ConsumerWidget {
  final String scriptureId;

  const ScriptureDetailScreen({
    super.key,
    required this.scriptureId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scripture = ref.watch(scriptureByIdProvider(scriptureId));

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
            // Reference and topic
            Text(
              scripture.reference,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primary,
                  ),
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
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                            color: AppTheme.dark,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Memorize button — prominent CTA
            SizedBox(
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
                icon: const Icon(Icons.psychology_alt, size: 22),
                label: const Text('Memorize This Scripture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mastery progress section
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ..._buildMasteryCards(context, ref, scriptureId),
            const SizedBox(height: 24),

            // Notes section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add notes...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Practice buttons
            Text(
              'Practice',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ..._buildPracticeButtons(context, scriptureId),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMasteryCards(
    BuildContext context,
    WidgetRef ref,
    String scriptureId,
  ) {
    return GameType.values.map((gameType) {
      final mastery = ref.watch(
        masteryLevelProvider((scriptureId, gameType)),
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameType.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mastery.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Color(mastery.color),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                MasteryBadge.compact(masteryLevel: mastery),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPracticeButtons(
    BuildContext context,
    String scriptureId,
  ) {
    return GameType.values.map((gameType) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/games');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(gameType.icon),
                const SizedBox(width: 8),
                Text('Play ${gameType.displayName}'),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
