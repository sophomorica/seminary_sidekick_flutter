import 'enums.dart';

/// Chunk-tap difficulty for the Group Scripture Builder race.
///
/// Mirrors the solo `DifficultyLevel.beginner` / `intermediate` chunk-tap
/// tiers. Typing-based tiers (Advanced / Master) are intentionally NOT
/// supported in v1 — owner's seminary-teaching feedback: "most kids won't
/// be able to type the answers very well."
enum GroupSbChunkDifficulty {
  beginner,
  intermediate;

  static GroupSbChunkDifficulty fromName(String name) =>
      GroupSbChunkDifficulty.values.firstWhere(
        (v) => v.name == name,
        orElse: () => GroupSbChunkDifficulty.beginner,
      );

  /// Number of consecutive words in a single chunk tile.
  int get chunkSize =>
      this == GroupSbChunkDifficulty.beginner ? 3 : 2;

  /// Whether the chunk pool includes distractor tiles drawn from
  /// other in-scope scriptures.
  bool get hasDistractors => this == GroupSbChunkDifficulty.intermediate;

  /// Number of distractor tiles mixed into the pool. Derived from the solo
  /// [DifficultyLevel.extraDistractors] so the race stays in lockstep with
  /// solo difficulty tuning instead of drifting on a hardcoded constant.
  int get extraDistractors => this == GroupSbChunkDifficulty.intermediate
      ? DifficultyLevel.intermediate.extraDistractors
      : DifficultyLevel.beginner.extraDistractors;
}

/// How the race progresses across the set of scriptures.
///
/// `roundByRound`: host advances one scripture at a time. Per-scripture race;
/// fastest correct completion wins the round. Cumulative score across rounds
/// determines the overall winner.
///
/// `setOfN`: host picks N scriptures. Queue starts simultaneously; each player
/// works through all N in order. First to finish the set wins; cumulative
/// elapsed time orders runners-up.
enum GroupSbPlayMode {
  roundByRound,
  setOfN;

  static GroupSbPlayMode fromName(String name) =>
      GroupSbPlayMode.values.firstWhere(
        (v) => v.name == name,
        orElse: () => GroupSbPlayMode.roundByRound,
      );
}

/// Frozen Word-Builder-race configuration that travels inside a
/// [GroupRoomScope] when `mode == GroupGameMode.scriptureBuilder`.
///
/// `scriptureIds` is the explicit, ordered list of scripture ids the host
/// selected for this race. Order matters in Set-of-N (players race through
/// in order); in Round-by-Round the host advances through the same order.
///
/// `perScriptureTimeoutSeconds` is optional. When set, a client-side timer
/// auto-files a DNF finish on expiry. Server-side enforcement is deferred
/// to v2.
class GroupSbConfig {
  final GroupSbChunkDifficulty chunkDifficulty;
  final GroupSbPlayMode playMode;
  final List<String> scriptureIds;
  final int? perScriptureTimeoutSeconds;

  const GroupSbConfig({
    required this.chunkDifficulty,
    required this.playMode,
    required this.scriptureIds,
    this.perScriptureTimeoutSeconds,
  });

  GroupSbConfig copyWith({
    GroupSbChunkDifficulty? chunkDifficulty,
    GroupSbPlayMode? playMode,
    List<String>? scriptureIds,
    int? perScriptureTimeoutSeconds,
    bool clearTimeout = false,
  }) {
    return GroupSbConfig(
      chunkDifficulty: chunkDifficulty ?? this.chunkDifficulty,
      playMode: playMode ?? this.playMode,
      scriptureIds: scriptureIds ?? this.scriptureIds,
      perScriptureTimeoutSeconds: clearTimeout
          ? null
          : (perScriptureTimeoutSeconds ?? this.perScriptureTimeoutSeconds),
    );
  }

  Map<String, dynamic> toJson() => {
        'chunkDifficulty': chunkDifficulty.name,
        'playMode': playMode.name,
        'scriptureIds': scriptureIds,
        if (perScriptureTimeoutSeconds != null)
          'perScriptureTimeoutSeconds': perScriptureTimeoutSeconds,
      };

  factory GroupSbConfig.fromJson(Map<String, dynamic> json) {
    return GroupSbConfig(
      chunkDifficulty: GroupSbChunkDifficulty.fromName(
        json['chunkDifficulty'] as String? ?? 'beginner',
      ),
      playMode: GroupSbPlayMode.fromName(
        json['playMode'] as String? ?? 'roundByRound',
      ),
      scriptureIds: (json['scriptureIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      perScriptureTimeoutSeconds:
          json['perScriptureTimeoutSeconds'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! GroupSbConfig) return false;
    if (other.chunkDifficulty != chunkDifficulty) return false;
    if (other.playMode != playMode) return false;
    if (other.perScriptureTimeoutSeconds != perScriptureTimeoutSeconds) {
      return false;
    }
    if (other.scriptureIds.length != scriptureIds.length) return false;
    for (var i = 0; i < scriptureIds.length; i++) {
      if (other.scriptureIds[i] != scriptureIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        chunkDifficulty,
        playMode,
        perScriptureTimeoutSeconds,
        Object.hashAll(scriptureIds),
      );
}
