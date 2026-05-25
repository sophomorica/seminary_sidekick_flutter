import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/enums.dart';
import '../../models/group_play_state.dart';
import '../../models/group_player.dart';
import '../../models/group_room.dart';
import '../../models/scripture_scope.dart';
import '../../providers/group_play_provider.dart';
import '../../providers/scripture_scope_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../services/nickname_validator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/scripture_scope_picker.dart';

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
  ScriptureScope _scope = const ScopeAll();
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
      // Restore last-used group quiz scope if the host has one.
      final last = ref
          .read(scriptureScopeProvider.notifier)
          .lastUsedScope(ScopeUsageContext.groupQuiz);
      if (last != null) {
        setState(() => _scope = last);
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
          onPressed: () => _confirmLeave(isLobby: inLobby),
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
                  scope: _scope,
                  nicknameController: _nicknameController,
                  onDifficultyChanged: (d) =>
                      setState(() => _difficulty = d),
                  onScopeChanged: (s) => setState(() => _scope = s),
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

    // Persist the chosen scope for next time this host opens the setup.
    await ref
        .read(scriptureScopeProvider.notifier)
        .saveScope(ScopeUsageContext.groupQuiz, _scope);

    // Translate the picker scope into the wire-format used by the room row.
    // `ScopeAll` and the dynamic presets (`needsReview`, `nearlyMastered`)
    // map to empty book/id lists — the question factory then draws from all
    // scriptures, matching the original minimal-picker default. Explicit
    // book or scripture-id selections become bookNames or scriptureIds.
    List<String> bookNames = const [];
    List<String> scriptureIds = const [];
    if (_scope is ScopeBooks) {
      bookNames =
          (_scope as ScopeBooks).books.map((b) => b.name).toList();
    } else if (_scope is ScopeScriptureIds) {
      scriptureIds = (_scope as ScopeScriptureIds).ids;
    }

    final scope = GroupRoomScope(
      difficultyName: _difficulty.name,
      bookNames: bookNames,
      scriptureIds: scriptureIds,
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
    // Find the nickname BEFORE we kick so the snackbar can name them even
    // after they're removed from the roster.
    final players = ref.read(groupPlayProvider).players;
    final nickname = players
            .where((p) => p.id == playerId)
            .map((p) => p.nickname)
            .firstOrNull ??
        'Player';

    // Clear any prior snackbar so consecutive kicks don't stack visibly.
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    await ref.read(groupPlayProvider.notifier).hostKickPlayer(playerId);

    if (!mounted) return;
    final state = ref.read(groupPlayProvider);
    final errorMessage = state.error;
    if (errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.error,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$nickname removed from the room'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmLeave({required bool isLobby}) async {
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
  final ScriptureScope scope;
  final TextEditingController nicknameController;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;
  final ValueChanged<ScriptureScope> onScopeChanged;
  final Future<void> Function() onCreate;

  const _SetupView({
    required this.state,
    required this.difficulty,
    required this.scope,
    required this.nicknameController,
    required this.onDifficultyChanged,
    required this.onScopeChanged,
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
          'Pick a difficulty and a scope. Players will join with a 4-letter code.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),

        const SizedBox(height: AppTheme.spacingXl),

        const _SectionLabel('DIFFICULTY'),
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

        const _SectionLabel('SCOPE'),
        const SizedBox(height: AppTheme.spacingSm),
        ScriptureScopePicker(
          initial: scope,
          usageContext: ScopeUsageContext.groupQuiz,
          onChanged: onScopeChanged,
        ),

        const SizedBox(height: AppTheme.spacingXl),

        const _SectionLabel('YOUR NICKNAME'),
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

    // Layout: scrollable code + QR + roster on top, Start button pinned to the
    // bottom so it's always reachable regardless of how big the code renders or
    // how many players are in the lobby.
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: AppTheme.spacingMd),

        // ─── Massive code (projector-friendly) ───
        // FittedBox auto-shrinks on narrow phones so the code never wraps or
        // pushes the Start button off-screen. On wider devices (iPad, projector
        // mirroring) the code renders at full 72sp.
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                room.code,
                style: const TextStyle(
                  fontSize: 72,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onPrimary,
                  letterSpacing: 12,
                ),
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),

        // ─── Start button (pinned footer, always reachable) ───
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingSm),
          child: SizedBox(
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
        ),
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
