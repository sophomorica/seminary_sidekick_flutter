import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Push a widget above the shell (header + bottom nav).
///
/// The app shell uses a nested navigator. A plain `Navigator.of(context).push`
/// stacks under "Seminary Sidekick" + the tab bar and creates a large gap
/// above the page's own AppBar/SafeArea. Solo games already use this pattern;
/// use it for Memorize, Upgrade (MaterialPageRoute), Journal with args,
/// and Sidekick chat launched with an initial message.
void pushFullscreen(BuildContext context, Widget page) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}

/// GoRouter sibling routes that live *outside* the shell (`/upgrade`,
/// `/settings`, `/journal`, group-play, …). Prefer these when no constructor
/// args are needed — they never sit under the shell chrome.
void pushUpgrade(BuildContext context) => context.push('/upgrade');
