import 'package:flutter/foundation.dart';

/// Development configuration for testing different user experiences.
///
/// **Quick toggle (edit code)**:
///   Set [forcePremium] to `true`  → test premium features locally
///   Set [forcePremium] to `false` → test free-tier experience
///
/// **Runtime toggle (no code changes)**:
///   Tap the bug icon in the home screen app bar (debug builds only)
///   to open the Dev Menu and switch on the fly.
///
/// **Release safety**:
///   [isDevModeActive] is always `false` in release builds regardless
///   of the values below — real RevenueCat subscription state is used.
class AppConfig {
  AppConfig._();

  // ─── Edit these during development ────────────────────────────────

  /// Master switch for development mode. Set to `false` before release.
  static const bool isDevelopmentMode = true;

  /// Force premium experience in development mode.
  /// Ignored when [isDevelopmentMode] is `false` or in release builds.
  static const bool forcePremium = true;

  // ─── Derived ──────────────────────────────────────────────────────

  /// Whether dev mode is actually active.
  /// Always `false` in release builds, even if [isDevelopmentMode] is `true`.
  static bool get isDevModeActive => isDevelopmentMode && kDebugMode;
}
