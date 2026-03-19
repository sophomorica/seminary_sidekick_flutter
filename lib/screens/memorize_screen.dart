import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/scripture.dart';
import '../theme/app_theme.dart';

/// The two memorization modes.
enum MemorizeMode {
  firstLetter('First Letter', 'Words shrink to their first letter'),
  fullHide('Full Hide', 'Words disappear completely');

  const MemorizeMode(this.label, this.description);
  final String label;
  final String description;
}

/// Tracks the visibility state of a single word.
enum WordVisibility {
  visible,     // Full word shown
  firstLetter, // Only first letter + underscores
  hidden,      // Completely replaced with underscores
}

/// A word in the passage with its display state.
class MemorizeWord {
  final String word;
  final int index;
  WordVisibility visibility;

  MemorizeWord({
    required this.word,
    required this.index,
    this.visibility = WordVisibility.visible,
  });

  /// Display text based on current visibility.
  String get displayText {
    switch (visibility) {
      case WordVisibility.visible:
        return word;
      case WordVisibility.firstLetter:
        if (word.length <= 1) return word;
        // Keep first letter + punctuation structure
        final firstChar = word[0];
        final rest = word.substring(1);
        // Replace letters/digits with underscores, keep punctuation
        final masked = rest.replaceAll(RegExp(r'[a-zA-Z0-9]'), '_');
        return '$firstChar$masked';
      case WordVisibility.hidden:
        // Replace all letters/digits with underscores, keep punctuation
        return word.replaceAll(RegExp(r'[a-zA-Z0-9]'), '_');
    }
  }

  bool get isFullyVisible => visibility == WordVisibility.visible;
}

class MemorizeScreen extends StatefulWidget {
  final Scripture scripture;

  const MemorizeScreen({super.key, required this.scripture});

  @override
  State<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends State<MemorizeScreen>
    with SingleTickerProviderStateMixin {
  late List<MemorizeWord> _words;
  late List<int> _hideOrder; // Randomized order to hide words
  int _hideStep = 0; // How many words have been hidden
  MemorizeMode _mode = MemorizeMode.firstLetter;
  final _random = Random();

  // Animation for the word that just changed
  late AnimationController _fadeController;
  int? _lastChangedIndex;

  @override
  void initState() {
    super.initState();
    _initWords();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initWords() {
    final words = widget.scripture.words;
    _words = List.generate(
      words.length,
      (i) => MemorizeWord(word: words[i], index: i),
    );
    // Create a random order for hiding
    _hideOrder = List.generate(words.length, (i) => i);
    _hideOrder.shuffle(_random);
    _hideStep = 0;
  }

  void _hideNextWord() {
    // Find the next word that can be further hidden.
    // In firstLetter mode: visible → firstLetter, then firstLetter → hidden
    // In fullHide mode: visible → hidden

    // First pass: look for visible words (in hide order)
    int? targetIndex;
    for (final idx in _hideOrder) {
      final w = _words[idx];
      if (w.visibility == WordVisibility.visible) {
        targetIndex = idx;
        break;
      }
    }

    // Second pass (firstLetter mode only): if no visible words left,
    // look for firstLetter words to fully hide
    if (targetIndex == null && _mode == MemorizeMode.firstLetter) {
      for (final idx in _hideOrder) {
        final w = _words[idx];
        if (w.visibility == WordVisibility.firstLetter) {
          targetIndex = idx;
          break;
        }
      }
    }

    if (targetIndex == null) return; // Everything is already fully hidden

    setState(() {
      final word = _words[targetIndex!];
      if (_mode == MemorizeMode.firstLetter) {
        if (word.visibility == WordVisibility.visible) {
          word.visibility = WordVisibility.firstLetter;
        } else {
          word.visibility = WordVisibility.hidden;
        }
      } else {
        word.visibility = WordVisibility.hidden;
      }
      _lastChangedIndex = targetIndex;
    });

    HapticFeedback.lightImpact();
    _fadeController.forward(from: 0);
  }

  void _revealAll() {
    setState(() {
      for (final w in _words) {
        w.visibility = WordVisibility.visible;
      }
      _hideStep = 0;
      _hideOrder.shuffle(_random);
      _lastChangedIndex = null;
    });
    HapticFeedback.mediumImpact();
  }

  void _hideAll() {
    setState(() {
      for (final w in _words) {
        w.visibility = _mode == MemorizeMode.firstLetter
            ? WordVisibility.firstLetter
            : WordVisibility.hidden;
      }
      _hideStep = _words.length;
      _lastChangedIndex = null;
    });
    HapticFeedback.mediumImpact();
  }

  int get _visibleCount =>
      _words.where((w) => w.visibility == WordVisibility.visible).length;

  int get _partialCount =>
      _words.where((w) => w.visibility == WordVisibility.firstLetter).length;

  int get _hiddenCount =>
      _words.where((w) => w.visibility == WordVisibility.hidden).length;

  double get _memorizeProgress {
    if (_words.isEmpty) return 0;
    // Each word can be 0 (visible), 0.5 (first letter), or 1.0 (hidden)
    double total = 0;
    for (final w in _words) {
      switch (w.visibility) {
        case WordVisibility.visible:
          total += 0;
        case WordVisibility.firstLetter:
          total += 0.5;
        case WordVisibility.hidden:
          total += 1.0;
      }
    }
    return total / _words.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Memorize'),
        actions: [
          // Mode toggle
          PopupMenuButton<MemorizeMode>(
            icon: const Icon(Icons.tune),
            tooltip: 'Change mode',
            onSelected: (mode) {
              setState(() {
                _mode = mode;
                _revealAll();
              });
            },
            itemBuilder: (context) => MemorizeMode.values.map((mode) {
              return PopupMenuItem(
                value: mode,
                child: Row(
                  children: [
                    Icon(
                      mode == _mode
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: mode == _mode ? AppTheme.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mode.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(mode.description,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scripture header
          _buildHeader(),

          // Progress bar
          _buildProgressBar(),

          // Scripture text with words
          Expanded(child: _buildPassageArea()),

          // Control bar
          _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.scripture.reference,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.scripture.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 8),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(
                Icons.visibility,
                '$_visibleCount',
                AppTheme.success,
              ),
              const SizedBox(width: 8),
              if (_partialCount > 0) ...[
                _buildStatChip(
                  Icons.text_fields,
                  '$_partialCount',
                  AppTheme.accent,
                ),
                const SizedBox(width: 8),
              ],
              _buildStatChip(
                Icons.visibility_off,
                '$_hiddenCount',
                AppTheme.dark.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
              // Mode indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _mode.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _memorizeProgress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            _memorizeProgress < 0.5
                ? AppTheme.secondary
                : (_memorizeProgress < 1.0
                    ? AppTheme.accent
                    : AppTheme.gold),
          ),
          minHeight: 5,
        ),
      ),
    );
  }

  Widget _buildPassageArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 10,
          children: _words.map((mw) {
            final isLastChanged = _lastChangedIndex == mw.index;

            return AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                // Subtle scale animation for the last changed word
                final scale = isLastChanged
                    ? 1.0 + (0.1 * (1.0 - _fadeController.value))
                    : 1.0;

                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: () => _onWordTap(mw),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _wordBackgroundColor(mw),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _wordBorderColor(mw),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    mw.displayText,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.4,
                      fontWeight: mw.isFullyVisible
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: _wordTextColor(mw),
                      letterSpacing:
                          mw.visibility == WordVisibility.hidden ? 1.5 : 0,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _wordBackgroundColor(MemorizeWord mw) {
    switch (mw.visibility) {
      case WordVisibility.visible:
        return Colors.transparent;
      case WordVisibility.firstLetter:
        return AppTheme.accent.withOpacity(0.06);
      case WordVisibility.hidden:
        return AppTheme.dark.withOpacity(0.04);
    }
  }

  Color _wordBorderColor(MemorizeWord mw) {
    switch (mw.visibility) {
      case WordVisibility.visible:
        return Colors.transparent;
      case WordVisibility.firstLetter:
        return AppTheme.accent.withOpacity(0.2);
      case WordVisibility.hidden:
        return Colors.grey.shade200;
    }
  }

  Color _wordTextColor(MemorizeWord mw) {
    switch (mw.visibility) {
      case WordVisibility.visible:
        return AppTheme.dark;
      case WordVisibility.firstLetter:
        return AppTheme.accent;
      case WordVisibility.hidden:
        return Colors.grey.shade400;
    }
  }

  /// Tapping a word toggles its visibility manually.
  void _onWordTap(MemorizeWord mw) {
    setState(() {
      if (_mode == MemorizeMode.firstLetter) {
        // Cycle: visible → firstLetter → hidden → visible
        switch (mw.visibility) {
          case WordVisibility.visible:
            mw.visibility = WordVisibility.firstLetter;
          case WordVisibility.firstLetter:
            mw.visibility = WordVisibility.hidden;
          case WordVisibility.hidden:
            mw.visibility = WordVisibility.visible;
        }
      } else {
        // Full hide mode: toggle visible ↔ hidden
        mw.visibility = mw.visibility == WordVisibility.visible
            ? WordVisibility.hidden
            : WordVisibility.visible;
      }
      _lastChangedIndex = mw.index;
    });
    HapticFeedback.selectionClick();
    _fadeController.forward(from: 0);
  }

  Widget _buildControlBar() {
    final allHidden = _visibleCount == 0 && _partialCount == 0;
    final allVisible =
        _visibleCount == _words.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main action: hide next word
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: allHidden ? null : _hideNextWord,
                icon: Icon(
                  _mode == MemorizeMode.firstLetter
                      ? Icons.text_decrease
                      : Icons.visibility_off,
                ),
                label: Text(allHidden
                    ? 'All Words Hidden'
                    : 'Hide Next Word'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Secondary actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: allVisible ? null : _revealAll,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Reveal All'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: allHidden ? null : _hideAll,
                    icon: const Icon(Icons.visibility_off, size: 18),
                    label: const Text('Hide All'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
