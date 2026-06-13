import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/data_reset_service.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/study_streak_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(userPreferencesProvider);
    _nameController = TextEditingController(text: prefs.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(userPreferencesProvider);
    final themeMode = ref.watch(themeProvider);
    final audioState = ref.watch(audioProvider);
    final subscription = ref.watch(subscriptionProvider);
    final streak = ref.watch(studyStreakProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ─── Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? AppTheme.primaryFixedDim : AppTheme.primary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 56,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Profile avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppTheme.darkSurfaceContainerHigh
                                : AppTheme.secondaryContainer,
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.secondaryFixedDim.withValues(alpha: 0.3)
                                  : AppTheme.outlineVariant.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 28,
                            color: isDark
                                ? AppTheme.secondaryFixedDim
                                : AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prefs.greetingName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: isDark
                                          ? AppTheme.primaryFixedDim
                                          : AppTheme.primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subscription.tier.isPremium
                                    ? 'Premium Member'
                                    : 'Free Tier',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: subscription.tier.isPremium
                                          ? AppTheme.premiumGold
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Settings Sections ──────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Profile ────────────────────────────────────
                _buildSectionHeader(context, 'PROFILE'),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildTextFieldTile(
                      context,
                      label: 'Display Name',
                      hint: 'Friend',
                      controller: _nameController,
                      onChanged: (value) {
                        ref
                            .read(userPreferencesProvider.notifier)
                            .setDisplayName(value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── Appearance ─────────────────────────────────
                _buildSectionHeader(context, 'APPEARANCE'),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildDropdownTile<ThemeMode>(
                      context,
                      icon: Icons.palette_outlined,
                      label: 'Theme',
                      value: themeMode,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeProvider.notifier).setThemeMode(mode);
                        }
                      },
                    ),
                    _buildDivider(context),
                    _buildDropdownTile<double>(
                      context,
                      icon: Icons.text_fields,
                      label: 'Text Size',
                      value: prefs.fontScale,
                      items: const [
                        DropdownMenuItem(
                          value: 0.85,
                          child: Text('Small'),
                        ),
                        DropdownMenuItem(
                          value: 1.0,
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(
                          value: 1.15,
                          child: Text('Large'),
                        ),
                        DropdownMenuItem(
                          value: 1.3,
                          child: Text('Extra Large'),
                        ),
                      ],
                      onChanged: (scale) {
                        if (scale != null) {
                          ref
                              .read(userPreferencesProvider.notifier)
                              .setFontScale(scale);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── Sound & Feedback ───────────────────────────
                _buildSectionHeader(context, 'SOUND & FEEDBACK'),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildSwitchTile(
                      context,
                      icon: Icons.volume_up_outlined,
                      label: 'Sound Effects',
                      subtitle: 'Play sounds on correct/incorrect answers',
                      value: !audioState.isMuted,
                      onChanged: (enabled) {
                        ref.read(audioProvider.notifier).setMuted(!enabled);
                        ref
                            .read(userPreferencesProvider.notifier)
                            .setSoundEnabled(enabled);
                      },
                    ),
                    _buildDivider(context),
                    _buildSwitchTile(
                      context,
                      icon: Icons.vibration,
                      label: 'Haptic Feedback',
                      subtitle: 'Vibrate on taps and feedback',
                      value: prefs.hapticsEnabled,
                      onChanged: (enabled) {
                        ref
                            .read(userPreferencesProvider.notifier)
                            .setHapticsEnabled(enabled);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── Study Stats ────────────────────────────────
                _buildSectionHeader(context, 'STUDY STATS'),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildInfoTile(
                      context,
                      icon: Icons.local_fire_department,
                      label: 'Current Streak',
                      value: '${streak.currentStreak} day${streak.currentStreak == 1 ? '' : 's'}',
                      valueColor: AppTheme.primary,
                    ),
                    _buildDivider(context),
                    _buildInfoTile(
                      context,
                      icon: Icons.emoji_events_outlined,
                      label: 'Best Streak',
                      value: '${streak.bestStreak} day${streak.bestStreak == 1 ? '' : 's'}',
                      valueColor: AppTheme.tertiary,
                    ),
                    _buildDivider(context),
                    _buildInfoTile(
                      context,
                      icon: Icons.today,
                      label: 'Studied Today',
                      value: streak.studiedToday ? 'Yes' : 'Not yet',
                      valueColor: streak.studiedToday
                          ? AppTheme.success
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── Subscription ───────────────────────────────
                _buildSectionHeader(context, 'SUBSCRIPTION'),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildInfoTile(
                      context,
                      icon: subscription.tier.isPremium
                          ? Icons.workspace_premium
                          : Icons.star_border,
                      label: 'Current Plan',
                      value: subscription.tier.isPremium
                          ? 'Premium (${subscription.activePlan?.label ?? 'Active'})'
                          : 'Free',
                      valueColor: subscription.tier.isPremium
                          ? AppTheme.premiumGold
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    if (!subscription.tier.isPremium) ...[
                      _buildDivider(context),
                      _buildActionTile(
                        context,
                        icon: Icons.workspace_premium,
                        label: 'Upgrade to Premium',
                        subtitle: 'Unlock the Seminary Sidekick AI',
                        iconColor: AppTheme.premiumGold,
                        onTap: () => context.push('/upgrade'),
                      ),
                    ],
                    if (subscription.tier.isPremium &&
                        subscription.expiresAt != null) ...[
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        icon: Icons.calendar_today,
                        label: 'Renews',
                        value: _formatDate(subscription.expiresAt!),
                        valueColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 28),

                // ─── Data & Privacy ─────────────────────────────
                _buildSectionHeader(context, 'DATA & PRIVACY'),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildActionTile(
                      context,
                      icon: Icons.replay,
                      label: 'Replay Onboarding',
                      subtitle: 'See the mastery path tutorial again',
                      onTap: () async {
                        await ref
                            .read(onboardingProvider.notifier)
                            .resetOnboarding();
                        if (context.mounted) {
                          context.go('/onboarding');
                        }
                      },
                    ),
                    _buildDivider(context),
                    _buildActionTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      subtitle: 'How your data is handled',
                      onTap: () => _openPrivacyPolicy(context),
                    ),
                    _buildDivider(context),
                    _buildActionTile(
                      context,
                      icon: Icons.delete_outline,
                      label: 'Delete All My Data',
                      subtitle: 'Erase everything on this device — cannot be undone',
                      iconColor: AppTheme.error,
                      labelColor: AppTheme.error,
                      onTap: () => _showDeleteConfirmation(context),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── About ──────────────────────────────────────
                _buildSectionHeader(context, 'ABOUT'),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildInfoTile(
                      context,
                      icon: Icons.info_outline,
                      label: 'Version',
                      value: '1.0.0',
                      valueColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    _buildDivider(context),
                    _buildInfoTile(
                      context,
                      icon: Icons.menu_book,
                      label: 'Scriptures',
                      value: '100 Doctrinal Mastery',
                      valueColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // ─── Footer ─────────────────────────────────────
                Center(
                  child: Text(
                    'Seminary Sidekick',
                    style: GoogleFonts.merriweather(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Building Blocks ──────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.editorialShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile<T>(
    BuildContext context, {
    required IconData icon,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox.shrink(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primary,
                ),
            dropdownColor: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldTile(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
                labelStyle: Theme.of(context).textTheme.bodySmall,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
              ),
              style: Theme.of(context).textTheme.titleMedium,
              onChanged: onChanged,
              textCapitalization: TextCapitalization.words,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    Color? iconColor,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: labelColor,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse('https://seminarysidekick.com/privacy');
    final opened =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open the privacy policy.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Delete All My Data?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Text(
          'This permanently erases everything stored on this device — your '
          'mastery progress, streaks, notes, journal entries, goals, and '
          'preferences — and signs you out of any group-play session. This '
          'cannot be undone.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await DataResetService.deleteAllData(ref);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All your data has been deleted.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                );
                context.go('/onboarding');
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Something went wrong deleting your data. Please try again.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Delete Everything',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
