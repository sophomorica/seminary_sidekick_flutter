/// Chunk-tap difficulty for the Group Word Builder race.
///
/// Mirrors the solo `DifficultyLevel.beginner` / `intermediate` chunk-tap
/// tiers. Typing-based tiers (Advanced / Master) are intentionally NOT
/// supported in v1 — owner's seminary-teaching feedback: "most kids won't
/// be able to type the answers very well."
enum GroupWbChunkDifficulty {
  beginner,
  intermediate;

  static GroupWbChunkDifficulty fromName(String name) =>
      GroupWbChunkDifficulty.values.firstWhere(
        (v) => v.name == name,
        orElse: () => GroupWbChunkDifficulty.beginner,
      );

  /// Number of consecutive words in a single chunk tile.
  int get chunkSize =>
      this == GroupWbChunkDifficulty.beginner ? 3 : 2;

  /// Whether the chunk pool includes distractor tiles drawn from
  /// other in-scope scriptures.
  bool get hasDistractors => this == GroupWbChunkDifficulty.intermediate;
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
enum GroupWbPlayMode {
  roundByRound,
  setOfN;

  static GroupWbPlayMode fromName(String name) =>
      GroupWbPlayMode.values.firstWhere(
        (v) => v.name == name,
        orElse: () => GroupWbPlayMode.roundByRound,
      );
}

/// Frozen Word-Builder-race configuration that travels inside a
/// [GroupRoomScope] when `mode == GroupGameMode.wordBuilder`.
///
/// `scriptureIds` is the explicit, ordered list of scripture ids the host
/// selected for this race. Order matters in Set-of-N (players race through
/// in order); in Round-by-Round the host advances through the same order.
///
/// `perScriptureTimeoutSeconds` is optional. When set, a client-side timer
/// auto-files a DNF finish on expiry. Server-side enforcement is deferred
/// to v2.
class GroupWbConfig {
  final GroupWbChunkDifficulty chunkDifficulty;
  final GroupWbPlayMode playMode;
  final List<String> scriptureIds;
  final int? perScriptureTimeoutSeconds;

  const GroupWbConfig({
    required this.chunkDifficulty,
    required this.playMode,
    required this.scriptureIds,
    this.perScriptureTimeoutSeconds,
  });

  GroupWbConfig copyWith({
    GroupWbChunkDifficulty? chunkDifficulty,
    GroupWbPlayMode? playMode,
    List<String>? scriptureIds,
    int? perScriptureTimeoutSeconds,
    bool clearTimeout = false,
  }) {
    return GroupWbConfig(
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

  factory GroupWbConfig.fromJson(Map<String, dynamic> json) {
    return GroupWbConfig(
      chunkDifficulty: GroupWbChunkDifficulty.fromName(
        json['chunkDifficulty'] as String? ?? 'beginner',
      ),
      playMode: GroupWbPlayMode.fromName(
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
    if (other is! GroupWbConfig) return false;
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
