import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/enums.dart';
import '../../models/group_play_state.dart';
import '../../models/group_player.dart';
import '../../models/group_room.dart';
import '../../providers/group_play_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../services/nickname_validator.dart';
import '../../theme/app_theme.dart';

/// Host screen — pick a difficulty + book scope, create a room, watch
/// players join, tap Start when you're ready.
///
/// Two views:
///   - Setup view (default): difficulty / book / nickname / Create Room.
///   - Lobby view (after createRoom succeeds): huge code, QR, live roster
///     with kick button per row, Start Game button.
class HostLobbyScreen extends ConsumerStatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  ConsumerState<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends ConsumerState<HostLobbyScreen> {
  DifficultyLevel _difficulty = DifficultyLevel.beginner;
  // null == "All Books"; otherwise a specific volume.
  ScriptureBook? _book;
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    // Default the host's nickname from their saved greeting name.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final defaultName = ref.read(greetingNameProvider);
      if (_nicknameController.text.isEmpty && defaultName.isNotEmpty) {
        _nicknameController.text = defaultName;
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-navigate to the live quiz screen the moment we transition.
    ref.listen<GroupPlayPhase>(groupPlayPhaseProvider, (prev, next) {
      if (next == GroupPlayPhase.inQuiz) {
        final code = ref.read(currentGroupRoomProvider)?.code;
        if (code != null && mounted) {
          context.go('/group-play/quiz/$code');
        }
      }
    });

    final state = ref.watch(groupPlayProvider);
    final inLobby = state.phase == GroupPlayPhase.inLobby && state.room != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(inLobby ? 'Lobby' : 'Host a Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _confirmLeave(context, isLobby: inLobby),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          child: inLobby
              ? _LobbyView(
                  state: state,
                  onStart: _handleStart,
                  onKick: _handleKick,
                )
              : _SetupView(
                  state: state,
                  difficulty: _difficulty,
                  book: _book,
                  nicknameController: _nicknameController,
                  onDifficultyChanged: (d) =>
                      setState(() => _difficulty = d),
                  onBookChanged: (b) => setState(() => _book = b),
                  onCreate: _handleCreate,
                ),
        ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    final nickname = _nicknameController.text.trim();
    final result = NicknameValidator.validate(nickname);
    final errorText = switch (result) {
      NicknameValid() => null,
      NicknameTooShort() => 'Pick a nickname (2+ characters)',
      NicknameTooLong() => 'Nickname must be 14 characters or fewer',
      NicknameInvalidChars() => 'Letters, numbers, and spaces only',
      NicknameProfanity() => 'Pick something else.',
    };
    if (errorText != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText)),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final scope = GroupRoomScope(
      difficultyName: _difficulty.name,
      bookNames: _book == null ? const [] : [_book!.name],
      questionCount: _difficulty.quizQuestionCount,
    );

    await ref.read(groupPlayProvider.notifier).hostCreateRoom(
          scope: scope,
          hostNickname: nickname,
        );
  }

  Future<void> _handleStart() async {
    final state = ref.read(groupPlayProvider);
    final nonHostCount =
        state.players.where((p) => !p.isHost).length;
    if (nonHostCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait for at least one player to join.'),
        ),
      );
      return;
    }
    await ref.read(groupPlayProvider.notifier).hostStartGame();
  }

  Future<void> _handleKick(String playerId) async {
    await ref.read(groupPlayProvider.notifier).hostKickPlayer(playerId);
  }

  Future<void> _confirmLeave(BuildContext context,
      {required bool isLobby}) async {
    if (!isLobby) {
      // Setup view — nothing was created, just pop.
      ref.read(groupPlayProvider.notifier).resetToIdle();
      context.go('/practice');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End this room?'),
        content: const Text(
          'Players will be kicked back to the home screen. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('End Room'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(groupPlayProvider.notifier).leave();
      if (mounted) context.go('/practice');
    }
  }
}

// ─── Setup View ──────────────────────────────────────────────────────────────

class _SetupView extends StatelessWidget {
  final GroupPlayState state;
  final DifficultyLevel difficulty;
  final ScriptureBook? book;
  final TextEditingController nicknameController;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;
  final ValueChanged<ScriptureBook?> onBookChanged;
  final Future<void> Function() onCreate;

  const _SetupView({
    required this.state,
    required this.difficulty,
    required this.book,
    required this.nicknameController,
    required this.onDifficultyChanged,
    required this.onBookChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = state.isLoading;

    return ListView(
      children: [
        const SizedBox(height: AppTheme.spacingMd),

        Text(
          'Set up the game',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'Merriweather',
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick a difficulty and a book. Players will join with a 4-letter code.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),

        const SizedBox(height: AppTheme.spacingXl),

        _SectionLabel('DIFFICULTY'),
        const SizedBox(height: AppTheme.spacingSm),
        _DifficultyChips(
          selected: difficulty,
          onChanged: onDifficultyChanged,
        ),
        const SizedBox(height: 8),
        Text(
          difficulty.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),

        const SizedBox(height: AppTheme.spacingXl),

        _SectionLabel('SCOPE'),
        const SizedBox(height: AppTheme.spacingSm),
        _BookChips(
          selected: book,
          onChanged: onBookChanged,
        ),

        const SizedBox(height: AppTheme.spacingXl),

        _SectionLabel('YOUR NICKNAME'),
        const SizedBox(height: AppTheme.spacingSm),
        TextField(
          controller: nicknameController,
          maxLength: 14,
          decoration: InputDecoration(
            hintText: 'Shows in the lobby',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingMd),

        if (state.phase == GroupPlayPhase.error && state.error != null)
          _ErrorBanner(message: state.error!),

        const SizedBox(height: AppTheme.spacingLg),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            onPressed: isLoading ? null : onCreate,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.onPrimary,
                    ),
                  )
                : const Text(
                    'Create Room',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }
}

// ─── Lobby View ──────────────────────────────────────────────────────────────

class _LobbyView extends ConsumerWidget {
  final GroupPlayState state;
  final Future<void> Function() onStart;
  final Future<void> Function(String) onKick;

  const _LobbyView({
    required this.state,
    required this.onStart,
    required this.onKick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final room = state.room!;
    final players = state.players;
    final nonHostCount = players.where((p) => !p.isHost).length;
    final atCap = players.length >= room.playerCap;

    return ListView(
      children: [
        const SizedBox(height: AppTheme.spacingMd),

        // ─── Massive code (projector-friendly) ───
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: AppTheme.editorialShadow,
            ),
            child: Text(
              room.code,
              style: const TextStyle(
                fontSize: 72,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppTheme.onPrimary,
                letterSpacing: 16,
              ),
            ),
          ),
        ),

        Center(
          child: Text(
            'Players join at this code',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingLg),

        // ─── QR code ───
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.editorialShadow,
            ),
            child: QrImageView(
              data: 'seminary-sidekick://group-play/join?code=${room.code}',
              size: 140,
              backgroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingXl),

        // ─── Player count + cap indicator ───
        Row(
          children: [
            _SectionLabel('PLAYERS  ${players.length}/${room.playerCap}'),
            const Spacer(),
            if (!isPremium && atCap)
              TextButton(
                onPressed: () => context.push('/upgrade'),
                child: const Text('Up to 30 with Premium →'),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // ─── Roster ───
        ...players.map((p) => _PlayerRow(
              player: p,
              isMe: p.userId == ref.read(groupPlayServiceProvider).currentUserId,
              onKick: p.isHost ? null : () => onKick(p.id),
            )),

        if (players.length == 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Waiting for someone to join…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: AppTheme.spacingXl),

        // ─── Start button ───
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tertiary,
              foregroundColor: AppTheme.onTertiary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            onPressed: nonHostCount < 1 ? null : onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              nonHostCount < 1
                  ? 'Waiting for players…'
                  : 'Start Game ($nonHostCount ${nonHostCount == 1 ? 'player' : 'players'})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _DifficultyChips extends StatelessWidget {
  final DifficultyLevel selected;
  final ValueChanged<DifficultyLevel> onChanged;

  const _DifficultyChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DifficultyLevel.values.map((d) {
        final isSelected = d == selected;
        return ChoiceChip(
          label: Text(d.label),
          selected: isSelected,
          onSelected: (_) => onChanged(d),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.onPrimary : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          selectedColor: AppTheme.primary,
        );
      }).toList(),
    );
  }
}

class _BookChips extends StatelessWidget {
  final ScriptureBook? selected;
  final ValueChanged<ScriptureBook?> onChanged;

  const _BookChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "All 100" chip — null means no filter.
        ChoiceChip(
          label: const Text('All 100'),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
          labelStyle: TextStyle(
            color: selected == null ? AppTheme.onPrimary : null,
            fontWeight:
                selected == null ? FontWeight.bold : FontWeight.normal,
          ),
          selectedColor: AppTheme.primary,
        ),
        ...ScriptureBook.values.map((b) {
          final isSelected = b == selected;
          return ChoiceChip(
            label: Text(b.abbreviation),
            selected: isSelected,
            onSelected: (_) => onChanged(b),
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.onPrimary : null,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            selectedColor: AppTheme.primary,
            tooltip: b.displayName,
          );
        }),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final GroupPlayer player;
  final bool isMe;
  final VoidCallback? onKick;

  const _PlayerRow({
    required this.player,
    required this.isMe,
    required this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: player.isHost
                ? AppTheme.tertiary.withValues(alpha: 0.2)
                : AppTheme.secondary.withValues(alpha: 0.15),
            child: Icon(
              player.isHost ? Icons.star : Icons.person,
              size: 18,
              color:
                  player.isHost ? AppTheme.tertiary : AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.nickname + (isMe ? '  (you)' : ''),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isMe ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ),
          if (player.isHost)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'HOST',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.tertiary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),
            )
          else if (onKick != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Kick player',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: onKick,
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
