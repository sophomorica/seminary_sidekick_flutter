import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/announcement.dart';
import '../providers/announcement_provider.dart';
import '../theme/app_theme.dart';

/// Compact Home banner for the current [visibleAnnouncementProvider] item.
///
/// Tap opens a detail sheet (full copy + optional GIF/image + CTA).
/// The close affordance dismisses permanently on this device (Hive).
class AnnouncementBanner extends ConsumerWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = ref.watch(visibleAnnouncementProvider);
    if (announcement == null) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      child: Material(
        color: AppTheme.primaryFixed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => _openDetail(context, announcement),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
              AppTheme.spacingMd,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconFor(announcement.kind),
                  color: AppTheme.onPrimaryFixedVariant,
                  size: 22,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.kind.displayLabel.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.onPrimaryFixedVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        announcement.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppTheme.onPrimaryFixed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (announcement.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          announcement.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.onPrimaryFixedVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref
                      .read(announcementProvider.notifier)
                      .dismiss(announcement.id),
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppTheme.onPrimaryFixedVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(AnnouncementKind kind) {
    switch (kind) {
      case AnnouncementKind.feature:
        return Icons.auto_awesome_outlined;
      case AnnouncementKind.event:
        return Icons.celebration_outlined;
      case AnnouncementKind.tip:
        return Icons.lightbulb_outline;
      case AnnouncementKind.update:
        return Icons.campaign_outlined;
      case AnnouncementKind.info:
        return Icons.campaign_outlined;
    }
  }

  static Future<void> _openDetail(
    BuildContext context,
    Announcement announcement,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (ctx) => _AnnouncementDetailSheet(announcement: announcement),
    );
  }
}

class _AnnouncementDetailSheet extends ConsumerWidget {
  const _AnnouncementDetailSheet({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      // SafeArea already applies the bottom system inset — no manual
      // MediaQuery padding on top of it.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingMd,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                announcement.kind.displayLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                announcement.title,
                style: textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Merriweather',
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                announcement.body,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (announcement.hasInlineMedia) ...[
                const SizedBox(height: AppTheme.spacingLg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Image.network(
                    announcement.mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 160,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (announcement.hasVideoMedia) ...[
                const SizedBox(height: AppTheme.spacingLg),
                OutlinedButton.icon(
                  onPressed: () => _openLink(announcement.mediaUrl!),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Watch tip'),
                ),
              ],
              if (announcement.hasCta) ...[
                const SizedBox(height: AppTheme.spacingLg),
                FilledButton(
                  onPressed: () => _handleCta(context, announcement),
                  child: Text(announcement.ctaLabel!),
                ),
              ],
              const SizedBox(height: AppTheme.spacingSm),
              TextButton(
                onPressed: () {
                  ref
                      .read(announcementProvider.notifier)
                      .dismiss(announcement.id);
                  Navigator.of(context).pop();
                },
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pop the sheet, then run the CTA. The router is captured BEFORE the pop —
  /// after `Navigator.pop`, this sheet's context is unmounted and
  /// `context.push` would be a silent no-op.
  static void _handleCta(BuildContext context, Announcement announcement) {
    final link = announcement.ctaLink!.trim();
    if (announcement.ctaIsInApp) {
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.push(link);
      return;
    }
    Navigator.of(context).pop();
    _openLink(link);
  }

  static Future<void> _openLink(String link) async {
    // Only launch absolute http(s) URLs — never javascript:, file:,
    // scheme-relative //host, etc.
    if (!Announcement.isHttpUrl(link)) return;
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Best-effort — a bad CTA must not crash Home.
    }
  }
}
