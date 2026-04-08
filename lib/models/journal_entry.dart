/// A single journal entry created by the user, optionally inspired by
/// an AI-generated reflection prompt.
class JournalEntry {
  /// Unique identifier (ISO timestamp of creation).
  final String id;

  /// The entry's title (user-editable, defaults to date or prompt excerpt).
  final String title;

  /// Rich-text body content (stored as plain text with simple markdown).
  final String content;

  /// Scripture IDs this entry is tagged with.
  final List<String> scriptureIds;

  /// Scripture references (human-readable) for display without lookup.
  final List<String> scriptureReferences;

  /// The AI-generated prompt that inspired this entry, if any.
  final String? prompt;

  /// When the entry was first created.
  final DateTime createdAt;

  /// When the entry was last modified.
  final DateTime updatedAt;

  /// Whether this entry is marked as a favorite.
  final bool isFavorite;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    this.scriptureIds = const [],
    this.scriptureReferences = const [],
    this.prompt,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  JournalEntry copyWith({
    String? title,
    String? content,
    List<String>? scriptureIds,
    List<String>? scriptureReferences,
    String? prompt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return JournalEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      scriptureIds: scriptureIds ?? this.scriptureIds,
      scriptureReferences: scriptureReferences ?? this.scriptureReferences,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Whether this entry has any actual content.
  bool get isEmpty => content.trim().isEmpty;

  /// Whether this entry was prompted by the Sidekick.
  bool get hasPrompt => prompt != null && prompt!.isNotEmpty;

  /// A short preview of the content (first 100 chars).
  String get preview {
    if (content.isEmpty) return '';
    final trimmed = content.trim();
    if (trimmed.length <= 100) return trimmed;
    return '${trimmed.substring(0, 100)}...';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'scriptureIds': scriptureIds,
        'scriptureReferences': scriptureReferences,
        if (prompt != null) 'prompt': prompt,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      scriptureIds: (json['scriptureIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      scriptureReferences: (json['scriptureReferences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      prompt: json['prompt'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  /// Create a new empty entry, optionally seeded by a prompt and/or scripture.
  factory JournalEntry.create({
    String? prompt,
    String? scriptureId,
    String? scriptureReference,
  }) {
    final now = DateTime.now();
    return JournalEntry(
      id: now.toIso8601String(),
      title: '',
      content: '',
      scriptureIds: scriptureId != null ? [scriptureId] : const [],
      scriptureReferences:
          scriptureReference != null ? [scriptureReference] : const [],
      prompt: prompt,
      createdAt: now,
      updatedAt: now,
    );
  }
}
