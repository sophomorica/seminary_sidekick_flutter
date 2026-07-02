import 'package:flutter/material.dart';

import '../../models/enums.dart';

class BookCard extends StatelessWidget {
  final ScriptureBook book;
  final int passageCount;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.passageCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForBook(book),
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                book.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$passageCount passages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForBook(ScriptureBook book) {
    switch (book) {
      case ScriptureBook.oldTestament:
        return Icons.book;
      case ScriptureBook.newTestament:
        return Icons.favorite;
      case ScriptureBook.bookOfMormon:
        return Icons.star;
      case ScriptureBook.doctrineAndCovenants:
        return Icons.lightbulb;
    }
  }
}
