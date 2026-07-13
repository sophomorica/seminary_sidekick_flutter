import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/enums.dart';
import '../../models/group_play_state.dart';
import '../../models/group_player.dart';
import '../../models/group_room.dart';
import '../../models/group_sb_config.dart';
import '../../models/scripture_scope.dart';
import '../../providers/group_play_provider.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/scripture_scope_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../services/audio_service.dart';
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
  GroupGameMode _gameMode = GroupGameMode.quiz;
  DifficultyLevel _difficulty = DifficultyLevel.beginner;
  GroupSbChunkDifficulty _sbChunkDifficulty = GroupSbChunkDifficulty.beginner;
  GroupSbPlayMode _sbPlayMode = GroupSbPlayMode.roundByRound;
  int _sbSetSize = 5;
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
      // Restore last-used scope for whatever mode the host opens to.
      _restoreScopeForMode();
    });
  }

  /// Storage key for the current mode. Each game mode keeps its own
  /// last-used scope so changing modes doesn't smear the saved selection.
  String get _scopeUsageContext => _gameMode == GroupGameMode.quiz
      ? ScopeUsageContext.groupQuiz
      : ScopeUsageContext.groupScriptureBuilder;

  void _restoreScopeForMode() {
    final last = ref
        .read(scriptureScopeProvider.notifier)
        .lastUsedScope(_scopeUsageContext);
    if (last != null) {
      setState(() => _scope = last);
    } else {
      setState(() => _scope = const ScopeAll());
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-navigate to the live screen (quiz or word builder) the moment we
    // transition. Branch on the room's selected mode.
    ref.listen<GroupPlayPhase>(groupPlayPhaseProvider, (prev, next) {
      if (next == GroupPlayPhase.inQuiz) {
        final room = ref.read(currentGroupRoomProvider);
        if (room == null || !mounted) return;
        final path = room.scope.mode == GroupGameMode.scriptureBuilder
            ? '/group-play/word-builder/${room.code}'
            : '/group-play/quiz/${room.code}';
        context.go(path);
      }
    });

    // Free hosts who hit the 1-room-per-week ceiling get a tasteful upgrade
    // dialog instead of the raw exception text. Provider exposes a one-shot
    // flag we listen on, then clear once shown.
    ref.listen<bool>(
      groupPlayProvider.select((s) => s.freeHostWeeklyLimitHit),
      (prev, next) {
        if (next && mounted) _showFreeTierLimitDialog();
      },
    );

    // Play a friendly join blip on the host's device whenever a new (non-host)
    // player appears in the roster. Only fires on increases so leaves are silent.
    ref.listen<int>(
      groupPlayProvider.select(
        (s) => s.players.where((p) => !p.isHost).length,
      ),
      (prev, next) {
        if (prev != null && next > prev && mounted) {
          ref.read(audioProvider.notifier).play(SoundEffect.groupJoin);
        }
      },
    );

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
                  gameMode: _gameMode,
                  difficulty: _difficulty,
                  sbChunkDifficulty: _sbChunkDifficulty,
                  sbPlayMode: _sbPlayMode,
                  sbSetSize: _sbSetSize,
                  scope: _scope,
                  scopeUsageContext: _scopeUsageContext,
                  nicknameController: _nicknameController,
                  onGameModeChanged: (m) {
                    setState(() => _gameMode = m);
                    _restoreScopeForMode();
                  },
                  onDifficultyChanged: (d) =>
                      setState(() => _difficulty = d),
                  onSbChunkDifficultyChanged: (d) =>
                      setState(() => _sbChunkDifficulty = d),
                  onSbPlayModeChanged: (m) =>
                      setState(() => _sbPlayMode = m),
                  onSbSetSizeChanged: (n) => setState(() => _sbSetSize = n),
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

    // Scripture Builder needs at least one scripture in scope to race against.
    if (_gameMode == GroupGameMode.scriptureBuilder) {
      final allScrips = ref.read(scripturesProvider);
      final resolved = _scope.resolve(allScrips);
      if (resolved.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pick at least one scripture for the race.'),
          ),
        );
        return;
      }
    }

    FocusManager.instance.primaryFocus?.unfocus();

    // Persist the chosen scope under the current mode's key.
    await ref
        .read(scriptureScopeProvider.notifier)
        .saveScope(_scopeUsageContext, _scope);

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

    final scope = _gameMode == GroupGameMode.quiz
        ? GroupRoomScope(
            mode: GroupGameMode.quiz,
            difficultyName: _difficulty.name,
            bookNames: bookNames,
            scriptureIds: scriptureIds,
            questionCount: _difficulty.quizQuestionCount,
          )
        : _buildScriptureBuilderScope();

    await ref.read(groupPlayProvider.notifier).hostCreateRoom(
          scope: scope,
          hostNickname: nickname,
        );
  }

  /// Build the [GroupRoomScope] for a Word-Builder room. Resolves the picker
  /// scope down to a concrete list of scripture ids (Set-of-N caps to
  /// `_sbSetSize`, Round-by-Round uses all in scope).
  GroupRoomScope _buildScriptureBuilderScope() {
    final allScrips = ref.read(scripturesProvider);
    final resolved = _scope.resolve(allScrips);
    final ids = resolved.map((s) => s.id).toList();
    final raceIds = _sbPlayMode == GroupSbPlayMode.setOfN
        ? ids.take(_sbSetSize).toList()
        : ids;

    final sbConfig = GroupSbConfig(
      chunkDifficulty: _sbChunkDifficulty,
      playMode: _sbPlayMode,
      scriptureIds: raceIds,
    );

    return GroupRoomScope(
      mode: GroupGameMode.scriptureBuilder,
      // Difficulty/questionCount aren't used by SB rooms but the scope row
      // requires both. Stamp safe defaults.
      difficultyName: DifficultyLevel.beginner.name,
      scriptureIds: raceIds,
      questionCount: raceIds.length,
      scriptureBuilderConfig: sbConfig,
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

  Future<void> _showFreeTierLimitDialog() async {
    // Clear the flag immediately so it can re-fire later in the same session.
    ref.read(groupPlayProvider.notifier).clearFreeHostWeeklyLimitHit();

    final upgrade = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('You’ve hosted this week'),
        content: const Text(
          'Free hosts can run one game per week. Upgrade to Premium for '
          'unlimited hosting, class-size rooms (up to 30), and saved rosters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Maybe later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('See Premium'),
          ),
        ],
      ),
    );
    if (upgrade == true && mounted) {
      context.push('/upgrade');
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
  final GroupGameMode gameMode;
  final DifficultyLevel difficulty;
  final GroupSbChunkDifficulty sbChunkDifficulty;
  final GroupSbPlayMode sbPlayMode;
  final int sbSetSize;
  final ScriptureScope scope;
  final String scopeUsageContext;
  final TextEditingController nicknameController;
  final ValueChanged<GroupGameMode> onGameModeChanged;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;
  final ValueChanged<GroupSbChunkDifficulty> onSbChunkDifficultyChanged;
  final ValueChanged<GroupSbPlayMode> onSbPlayModeChanged;
  final ValueChanged<int> onSbSetSizeChanged;
  final ValueChanged<ScriptureScope> onScopeChanged;
  final Future<void> Function() onCreate;

  const _SetupView({
    required this.state,
    required this.gameMode,
    required this.difficulty,
    required this.sbChunkDifficulty,
    required this.sbPlayMode,
    required this.sbSetSize,
    required this.scope,
    required this.scopeUsageContext,
    required this.nicknameController,
    required this.onGameModeChanged,
    required this.onDifficultyChanged,
    required this.onSbChunkDifficultyChanged,
    required this.onSbPlayModeChanged,
    required this.onSbSetSizeChanged,
    required this.onScopeChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = state.isLoading;
    final isQuiz = gameMode == GroupGameMode.quiz;

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
          'Pick a game type and a scope. Players will join with a 4-letter code.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),

        const SizedBox(height: AppTheme.spacingXl),

        const _SectionLabel('GAME TYPE'),
        const SizedBox(height: AppTheme.spacingSm),
        _GameModeSegmented(
          selected: gameMode,
          onChanged: onGameModeChanged,
        ),

        const SizedBox(height: AppTheme.spacingXl),

        if (isQuiz) ...[
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
        ] else ...[
          const _SectionLabel('CHUNK DIFFICULTY'),
          const SizedBox(height: AppTheme.spacingSm),
          _WbChunkDifficultyChips(
            selected: sbChunkDifficulty,
            onChanged: onSbChunkDifficultyChanged,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          const _SectionLabel('PLAY MODE'),
          const SizedBox(height: AppTheme.spacingSm),
          _WbPlayModeChips(
            selected: sbPlayMode,
            onChanged: onSbPlayModeChanged,
          ),
          if (sbPlayMode == GroupSbPlayMode.setOfN) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _WbSetSizeRow(
              value: sbSetSize,
              onChanged: onSbSetSizeChanged,
            ),
          ],
        ],

        const SizedBox(height: AppTheme.spacingXl),

        const _SectionLabel('SCOPE'),
        const SizedBox(height: AppTheme.spacingSm),
        ScriptureScopePicker(
          initial: scope,
          usageContext: scopeUsageContext,
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

// ─── Game mode selector ─────────────────────────────────────────────────────

class _GameModeSegmented extends StatelessWidget {
  final GroupGameMode selected;
  final ValueChanged<GroupGameMode> onChanged;

  const _GameModeSegmented({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<GroupGameMode>(
      segments: const [
        ButtonSegment(
          value: GroupGameMode.quiz,
          label: Text('Quick Quiz'),
          icon: Icon(Icons.quiz),
        ),
        ButtonSegment(
          value: GroupGameMode.scriptureBuilder,
          label: Text('Scripture Builder Race'),
          icon: Icon(Icons.flag_outlined),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      multiSelectionEnabled: false,
      showSelectedIcon: false,
    );
  }
}

class _WbChunkDifficultyChips extends StatelessWidget {
  final GroupSbChunkDifficulty selected;
  final ValueChanged<GroupSbChunkDifficulty> onChanged;

  const _WbChunkDifficultyChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GroupSbChunkDifficulty.values.map((d) {
        final isSelected = d == selected;
        final label = switch (d) {
          GroupSbChunkDifficulty.beginner => 'Beginner — 3-word chunks',
          GroupSbChunkDifficulty.intermediate =>
            'Intermediate — 2-word chunks + distractors',
        };
        return ChoiceChip(
          label: Text(label),
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

class _WbPlayModeChips extends StatelessWidget {
  final GroupSbPlayMode selected;
  final ValueChanged<GroupSbPlayMode> onChanged;

  const _WbPlayModeChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GroupSbPlayMode.values.map((m) {
        final isSelected = m == selected;
        final label = switch (m) {
          GroupSbPlayMode.roundByRound =>
            'Round-by-Round — host advances each scripture',
          GroupSbPlayMode.setOfN =>
            'Set of N — race through the whole set',
        };
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(m),
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

class _WbSetSizeRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _WbSetSizeRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Set size',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 2 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < 30 ? () => onChanged(value + 1) : null,
        ),
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
    // Show the inline upgrade nudge at cap and one-below — the host needs the
    // pointer just as the lobby fills, not after they're locked out. Rate-
    // limited so dismissals across sessions stick.
    final nearOrAtCap = players.length >= room.playerCap - 1;
    final canPrompt = ref.watch(canShowUpgradePromptProvider);
    final showCapUpgrade = !isPremium && nearOrAtCap && canPrompt;

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
              data: 'https://seminarysidekick.com/join/${room.code}',
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
            if (showCapUpgrade)
              TextButton(
                onPressed: () => context.push('/upgrade'),
                child: Text(
                  players.length >= room.playerCap
                      ? 'Room full — go to 30 with Premium →'
                      : 'Up to 30 with Premium →',
                ),
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
