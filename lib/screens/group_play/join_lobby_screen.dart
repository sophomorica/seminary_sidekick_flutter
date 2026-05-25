import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/group_play_state.dart';
import '../../models/group_player.dart';
import '../../models/group_room.dart';
import '../../providers/group_play_provider.dart';
import '../../services/nickname_validator.dart';
import '../../theme/app_theme.dart';

/// Join screen — kid types a 4-letter code and a nickname, taps Join,
/// lands in the lobby waiting for the host to start.
///
/// Two phases inside one screen:
///   - **Entry view** (default): code + nickname inputs, Join button.
///   - **Waiting view** (after successful join): shows the room code,
///     the live player roster, and a "Waiting for host to start" message.
///
/// State transitions:
///   - phase==`error`  → render the error inline, keep entry inputs visible
///   - phase==`inLobby` → switch to waiting view
///   - phase==`inQuiz`  → auto-navigate to /group-play/quiz/:code (host started)
///   - phase==`viewingResults` (without going through inQuiz) → host ended
///     before starting; pop back to home
class JoinLobbyScreen extends ConsumerStatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  ConsumerState<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends ConsumerState<JoinLobbyScreen> {
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _codeFocus = FocusNode();
  final _nicknameFocus = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    _codeFocus.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for phase transitions so we can navigate when the host starts.
    // Branch on the room's game mode so Word-Builder rooms route to the
    // race screen instead of the quiz screen.
    ref.listen<GroupPlayPhase>(groupPlayPhaseProvider, (prev, next) {
      if (next == GroupPlayPhase.inQuiz) {
        final room = ref.read(currentGroupRoomProvider);
        if (room == null || !mounted) return;
        final path = room.scope.mode == GroupGameMode.wordBuilder
            ? '/group-play/word-builder/${room.code}'
            : '/group-play/quiz/${room.code}';
        context.go(path);
      } else if (next == GroupPlayPhase.viewingResults && mounted) {
        // Host ended the room without starting (or kicked us). Pop back home.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The host ended the room.')),
        );
        context.go('/');
      }
    });

    final state = ref.watch(groupPlayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Leave the room (cleanly disposes streams) before going home.
            ref.read(groupPlayProvider.notifier).leave();
            context.go('/');
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          child: state.phase == GroupPlayPhase.inLobby
              ? _WaitingView(state: state)
              : _EntryView(
                  state: state,
                  formKey: _formKey,
                  codeController: _codeController,
                  nicknameController: _nicknameController,
                  codeFocus: _codeFocus,
                  nicknameFocus: _nicknameFocus,
                  onJoin: _handleJoin,
                ),
        ),
      ),
    );
  }

  Future<void> _handleJoin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final code = _codeController.text.trim().toUpperCase();
    final nickname = _nicknameController.text.trim();
    FocusManager.instance.primaryFocus?.unfocus();
    await ref.read(groupPlayProvider.notifier).joinAsPlayer(
          code: code,
          nickname: nickname,
        );
  }
}

// ─── Entry View ──────────────────────────────────────────────────────────────

class _EntryView extends StatelessWidget {
  final GroupPlayState state;
  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final TextEditingController nicknameController;
  final FocusNode codeFocus;
  final FocusNode nicknameFocus;
  final Future<void> Function() onJoin;

  const _EntryView({
    required this.state,
    required this.formKey,
    required this.codeController,
    required this.nicknameController,
    required this.codeFocus,
    required this.nicknameFocus,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = state.isLoading;

    return Form(
      key: formKey,
      child: ListView(
        children: [
          const SizedBox(height: AppTheme.spacingLg),

          // Hero icon
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondary.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.groups,
                size: 36,
                color: AppTheme.secondary,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          Center(
            child: Text(
              'Enter your code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Merriweather',
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Get the 4-letter code from the host.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // ─── Code field ───
          Text(
            'ROOM CODE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextFormField(
            controller: codeController,
            focusNode: codeFocus,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            maxLength: 4,
            autofocus: true,
            inputFormatters: [
              LengthLimitingTextInputFormatter(4),
              // Force uppercase + alphanumeric only as the user types.
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              _UpperCaseFormatter(),
            ],
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
            decoration: InputDecoration(
              hintText: 'ABCD',
              hintStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                    color: (isDark
                            ? AppTheme.darkOnSurface
                            : AppTheme.onSurface)
                        .withValues(alpha: 0.20),
                  ),
              counterText: '',
              filled: true,
              fillColor: (isDark
                      ? AppTheme.darkSurfaceContainerHigh
                      : AppTheme.surfaceContainer)
                  .withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
            validator: (value) {
              if (value == null || value.trim().length != 4) {
                return 'Code must be 4 letters';
              }
              return null;
            },
            onFieldSubmitted: (_) => nicknameFocus.requestFocus(),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // ─── Nickname field ───
          Text(
            'YOUR NICKNAME',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextFormField(
            controller: nicknameController,
            focusNode: nicknameFocus,
            maxLength: 14,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(14),
              // Letters, digits, spaces, no punctuation/emoji.
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
            ],
            decoration: InputDecoration(
              hintText: 'e.g., Patrick L.',
              filled: true,
              fillColor: (isDark
                      ? AppTheme.darkSurfaceContainerHigh
                      : AppTheme.surfaceContainer)
                  .withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
            validator: (value) {
              final result = NicknameValidator.validate(value ?? '');
              return switch (result) {
                NicknameValid() => null,
                NicknameTooShort() => 'At least 2 characters',
                NicknameTooLong() => 'No more than 14 characters',
                NicknameInvalidChars() => 'Letters, numbers, and spaces only',
                NicknameProfanity() => 'Pick something else.',
              };
            },
            onFieldSubmitted: (_) => onJoin(),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // ─── Inline error banner ───
          if (state.phase == GroupPlayPhase.error && state.error != null)
            _ErrorBanner(message: state.error!),

          const SizedBox(height: AppTheme.spacingLg),

          // ─── Join button ───
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
              onPressed: isLoading ? null : onJoin,
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
                      'Join Game',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Waiting View ────────────────────────────────────────────────────────────

class _WaitingView extends ConsumerWidget {
  final GroupPlayState state;

  const _WaitingView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = state.room;
    final me = state.me;
    final players = state.players;

    return ListView(
      children: [
        const SizedBox(height: AppTheme.spacingLg),

        // Code chip + status
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: Text(
                  'CODE: ${room?.code ?? "????"}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                "You're in!",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Merriweather',
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                me != null ? 'Playing as ${me.nickname}' : '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingXl),

        // Animated "waiting for host" indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Waiting for host to start…',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingXl),

        // Player roster
        Text(
          'IN THIS ROOM (${players.length}/${room?.playerCap ?? 0})',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        ...players.map((p) => _PlayerRow(player: p, isMe: p.id == me?.id)),

        const SizedBox(height: AppTheme.spacingXl),

        // Leave button
        Center(
          child: TextButton.icon(
            onPressed: () {
              ref.read(groupPlayProvider.notifier).leave();
              context.go('/');
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Leave Room'),
            style: TextButton.styleFrom(
              foregroundColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Player Row ──────────────────────────────────────────────────────────────

class _PlayerRow extends StatelessWidget {
  final GroupPlayer player;
  final bool isMe;

  const _PlayerRow({required this.player, required this.isMe});

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
            Text(
              'HOST',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.tertiary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
        ],
      ),
    );
  }
}

// ─── Error banner ────────────────────────────────────────────────────────────

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

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Forces input to uppercase as the user types. Pairs with
/// `textCapitalization: TextCapitalization.characters` for full coverage
/// (the system flag handles the keyboard suggestion; this formatter
/// guarantees the value even when paste / autofill bypasses the keyboard).
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
