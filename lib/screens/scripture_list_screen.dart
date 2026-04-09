import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/scripture_provider.dart';
import '../providers/scripture_mastery_provider.dart';
import '../widgets/mastery_badge.dart';

class ScriptureListScreen extends ConsumerWidget {
  final String bookId;

  const ScriptureListScreen({
    super.key,
    required this.bookId,
  });

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
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
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
                final mastery =
                    ref.watch(scriptureMasteryProvider(scripture.id));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      context.push('/scripture/${scripture.id}');
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
                              masteryLevel: mastery.level,
                              needsReview: mastery.needsReview,
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
}
