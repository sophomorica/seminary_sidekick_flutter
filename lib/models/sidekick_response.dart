/// Structured response from the Seminary Sidekick (Grok).
///
/// The AI returns this JSON on app launch and can also return it in chat.
/// Each field is optional — the Sidekick decides what's relevant based on
/// the user's snapshot. The app renders whichever fields are present.
class SidekickResponse {
  /// Personalized greeting or thought for the day.
  final String? dailyPrompt;

  /// A suggested goal for the user (e.g., "Master 2 New Testament passages
  /// this week").
  final SidekickGoal? suggestedGoal;

  /// Quick win — a specific, actionable next step the user can take right now.
  final QuickWin? quickWin;

  /// An insight about the user's progress timeline.
  final String? timelineInsight;

  /// A gentle reminder (e.g., "You haven't reviewed Romans 1:16 in 12 days").
  final String? reminder;

  /// Reflection prompts for the journal (TASK-035 will consume these).
  final List<String> reflectionPrompts;

  /// Encouragement message based on recent activity.
  final String? encouragement;

  /// Scripture cross-references or doctrinal connections the Sidekick found
  /// relevant to the user's current study.
  final List<ScriptureConnection> connections;

  /// ISO timestamp of when this response was generated.
  final String generatedAt;

  const SidekickResponse({
    this.dailyPrompt,
    this.suggestedGoal,
    this.quickWin,
    this.timelineInsight,
    this.reminder,
    this.reflectionPrompts = const [],
    this.encouragement,
    this.connections = const [],
    required this.generatedAt,
  });

  factory SidekickResponse.fromJson(Map<String, dynamic> json) {
    return SidekickResponse(
      dailyPrompt: json['dailyPrompt'] as String?,
      suggestedGoal: json['suggestedGoal'] != null
          ? SidekickGoal.fromJson(json['suggestedGoal'] as Map<String, dynamic>)
          : null,
      quickWin: json['quickWin'] != null
          ? QuickWin.fromJson(json['quickWin'] as Map<String, dynamic>)
          : null,
      timelineInsight: json['timelineInsight'] as String?,
      reminder: json['reminder'] as String?,
      reflectionPrompts: (json['reflectionPrompts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      encouragement: json['encouragement'] as String?,
      connections: (json['connections'] as List<dynamic>?)
              ?.map((e) =>
                  ScriptureConnection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      generatedAt:
          json['generatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (dailyPrompt != null) 'dailyPrompt': dailyPrompt,
        if (suggestedGoal != null) 'suggestedGoal': suggestedGoal!.toJson(),
        if (quickWin != null) 'quickWin': quickWin!.toJson(),
        if (timelineInsight != null) 'timelineInsight': timelineInsight,
        if (reminder != null) 'reminder': reminder,
        if (reflectionPrompts.isNotEmpty)
          'reflectionPrompts': reflectionPrompts,
        if (encouragement != null) 'encouragement': encouragement,
        if (connections.isNotEmpty)
          'connections': connections.map((c) => c.toJson()).toList(),
        'generatedAt': generatedAt,
      };

  /// Fallback response when offline or API fails.
  factory SidekickResponse.offlineFallback() {
    return SidekickResponse(
      dailyPrompt:
          'Welcome back! Keep up the great work on your scripture mastery journey.',
      encouragement:
          'Every verse you study brings you closer to understanding.',
      generatedAt: DateTime.now().toIso8601String(),
    );
  }
}

/// A goal the Sidekick suggests for the user.
class SidekickGoal {
  final String title;
  final String description;

  /// Optional scripture IDs this goal relates to.
  final List<String> relatedScriptureIds;

  const SidekickGoal({
    required this.title,
    required this.description,
    this.relatedScriptureIds = const [],
  });

  factory SidekickGoal.fromJson(Map<String, dynamic> json) {
    return SidekickGoal(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      relatedScriptureIds: (json['relatedScriptureIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        if (relatedScriptureIds.isNotEmpty)
          'relatedScriptureIds': relatedScriptureIds,
      };
}

/// A quick, actionable next step.
class QuickWin {
  /// Human-readable suggestion (e.g., "Review Mosiah 3:19 — you're close to
  /// leveling up!").
  final String suggestion;

  /// The scripture ID to act on, if applicable.
  final String? scriptureId;

  /// The action type: 'review', 'practice', 'scriptureBuilder', 'reflect'.
  final String? actionType;

  const QuickWin({
    required this.suggestion,
    this.scriptureId,
    this.actionType,
  });

  factory QuickWin.fromJson(Map<String, dynamic> json) {
    return QuickWin(
      suggestion: json['suggestion'] as String? ?? '',
      scriptureId: json['scriptureId'] as String?,
      actionType: json['actionType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'suggestion': suggestion,
        if (scriptureId != null) 'scriptureId': scriptureId,
        if (actionType != null) 'actionType': actionType,
      };
}

/// A cross-reference or doctrinal connection between scriptures.
class ScriptureConnection {
  final String fromReference;
  final String toReference;
  final String insight;

  const ScriptureConnection({
    required this.fromReference,
    required this.toReference,
    required this.insight,
  });

  factory ScriptureConnection.fromJson(Map<String, dynamic> json) {
    return ScriptureConnection(
      fromReference: json['fromReference'] as String? ?? '',
      toReference: json['toReference'] as String? ?? '',
      insight: json['insight'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'fromReference': fromReference,
        'toReference': toReference,
        'insight': insight,
      };
}

/// A single message in the chat history with the Sidekick.
class SidekickMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const SidekickMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toApiMessage() => {
        'role': role,
        'content': content,
      };

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SidekickMessage.fromJson(Map<String, dynamic> json) {
    return SidekickMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
