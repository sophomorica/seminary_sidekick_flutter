/// A broadcast in-app announcement fetched from Supabase.
///
/// Shown as a dismissible Home banner. Optional media (GIF/image) and CTA
/// open in a detail sheet. See `supabase/migrations/0009_announcements.sql`.
class Announcement {
  final String id;
  final String title;
  final String body;
  final AnnouncementKind kind;
  final String? mediaUrl;
  final AnnouncementMediaType? mediaType;
  final String? ctaLabel;
  final String? ctaLink;
  final int priority;
  final DateTime startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.kind = AnnouncementKind.info,
    this.mediaUrl,
    this.mediaType,
    this.ctaLabel,
    this.ctaLink,
    this.priority = 0,
    required this.startsAt,
    this.endsAt,
    required this.createdAt,
  });

  bool get hasMedia =>
      mediaUrl != null && mediaUrl!.isNotEmpty && mediaType != null;

  bool get hasInlineMedia =>
      hasMedia &&
      (mediaType == AnnouncementMediaType.image ||
          mediaType == AnnouncementMediaType.gif);

  bool get hasCta =>
      ctaLink != null &&
      ctaLink!.isNotEmpty &&
      ctaLabel != null &&
      ctaLabel!.isNotEmpty;

  /// Whether this announcement is within its publish window for [now].
  bool isLiveAt(DateTime now) {
    if (startsAt.isAfter(now)) return false;
    if (endsAt != null && !endsAt!.isAfter(now)) return false;
    return true;
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      kind: AnnouncementKind.fromName(json['kind'] as String?),
      mediaUrl: json['media_url'] as String?,
      mediaType: AnnouncementMediaType.fromName(json['media_type'] as String?),
      ctaLabel: json['cta_label'] as String?,
      ctaLink: json['cta_link'] as String?,
      priority: json['priority'] as int? ?? 0,
      startsAt: DateTime.parse(json['starts_at'] as String).toUtc(),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String).toUtc()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'kind': kind.name,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (mediaType != null) 'media_type': mediaType!.name,
        if (ctaLabel != null) 'cta_label': ctaLabel,
        if (ctaLink != null) 'cta_link': ctaLink,
        'priority': priority,
        'starts_at': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt!.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum AnnouncementKind {
  info,
  feature,
  event,
  tip,
  update;

  static AnnouncementKind fromName(String? name) {
    if (name == null) return AnnouncementKind.info;
    return AnnouncementKind.values.firstWhere(
      (v) => v.name == name,
      orElse: () => AnnouncementKind.info,
    );
  }

  String get displayLabel {
    switch (this) {
      case AnnouncementKind.info:
        return 'News';
      case AnnouncementKind.feature:
        return 'New';
      case AnnouncementKind.event:
        return 'Event';
      case AnnouncementKind.tip:
        return 'Tip';
      case AnnouncementKind.update:
        return 'Update';
    }
  }
}

enum AnnouncementMediaType {
  image,
  gif,
  video;

  static AnnouncementMediaType? fromName(String? name) {
    if (name == null || name.isEmpty) return null;
    return AnnouncementMediaType.values.firstWhere(
      (v) => v.name == name,
      orElse: () => AnnouncementMediaType.image,
    );
  }
}
