import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/scripture_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/mastery_badge.dart';

class ScriptureListScreen extends ConsumerWidget {
  final String bookId;

  const ScriptureListScreen({
    Key? key,
    required this.bookId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse bookId to ScriptureBook enum
    late final ScriptureBook book;
    try {
      book = ScriptureBook.values.firstWhere(
        (b) => b.name == bookId,
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invalid Book'),
        ),
        body: const Center(
          child: Text('Scripture book not found'),
        ),
      );
    }

    final scriptures = ref.watch(scripturesByBookProvider(book));

    return Scaffold(
      appBar: AppBar(
        title: Text(book.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: scriptures.isEmpty
          ? const Center(
              child: Text('No scriptures found for this book'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scriptures.length,
              itemBuilder: (context, index) {
                final scripture = scriptures[index];

                // Get highest mastery level across all game types
                MasteryLevel highestMastery = MasteryLevel.newScripture;
                for (final gameType in GameType.values) {
                  final mastery = ref.watch(
                    masteryLevelProvider((scripture.id, gameType)),
                  );
                  if (_getMasteryRank(mastery) >
                      _getMasteryRank(highestMastery)) {
                    highestMastery = mastery;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      context.go('/scripture/${scripture.id}');
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scripture.reference,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    scripture.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    scripture.keyPhrase,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            MasteryBadge.compact(
                              masteryLevel: highestMastery,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  int _getMasteryRank(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newScripture:
        return 0;
      case MasteryLevel.learning:
        return 1;
      case MasteryLevel.familiar:
        return 2;
      case MasteryLevel.memorized:
        return 3;
      case MasteryLevel.mastered:
        return 4;
    }
  }
}
