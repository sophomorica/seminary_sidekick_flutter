# HANDOFF — Planner/Worker/Reviewer Coordination

Protocol: `../narrow-road-hq/standards/LOOP_STANDARDS.md`. Summary:

- **Planner** writes `## Plan`, sets `STATUS: PLAN_READY`.
- **Worker** sets `IN_PROGRESS`, implements, fills `## Worker notes`, sets
  `NEEDS_REVIEW`. Escalates architectural questions with `BLOCKED`.
- **Reviewer** wakes on `NEEDS_REVIEW`/`PLAN_READY`/`BLOCKED`, sets `REVIEWING`,
  reviews the diff against standards, trusts the worker's reported
  analyze/test results, and verifies tests exist for major changes and bug
  fixes; then sets `CHANGES_REQUESTED` with numbered findings
  (`R<round>.<n>`, tagged BUG/STANDARD/NIT) or `PASS`.
- Never set a state you don't own. Loop ends only at `PASS`.

---

## Plan

### PLAN-001: Scope picker filter chip redesign

Problem: the current `_Chip` in `lib/widgets/scripture_scope_picker.dart` uses
`FilterChip` with `showCheckmark: true`. The checkmark icon appearing/disappearing
changes each chip's width, shifting the whole Wrap layout on every tap. The
flat `colorScheme.primary` selected fill also doesn't match the app's hero
treatment.

Design standards for selection controls (apply here and going forward):

1. **No layout shift on state change.** Selection must never change a control's
   size. No conditional icons/checkmarks inside the control. Fixed dimensions:
   selected and unselected render at identical width/height.
2. **Selected = hero gradient.** Selected fill is `AppTheme.heroGradient`
   (navy → steel blue), label `colorScheme.onPrimary`, `FontWeight.w600`.
   Never a flat hardcoded blue.
3. **Unselected = dark surface.** `colorScheme.surfaceContainerHighest` (or
   the theme's dark card surface) with `colorScheme.onSurfaceVariant` label
   and a subtle `colorScheme.outlineVariant` border. Same border width in both
   states (transparent or gradient-matched when selected) so edges don't jump.
4. **Even placement.** Replace the ragged `Wrap` with an even layout: 2-column
   grid of equal-width cells for the 4 book filters, and the 2 status filters
   (Needs Review / Nearly Mastered) on a row below, also equal width. Fixed
   row height ≥ 44pt touch target.
5. **Theme tokens only** — `AppTheme.*` / `colorScheme.*`; no hardcoded colors
   (CLAUDE.md non-negotiable).

Implementation notes for the worker:

- Replace `FilterChip` in `_Chip` with a custom `InkWell` + `Ink`/`DecoratedBox`
  (gradient fill needs a custom container; `FilterChip` can't take a gradient).
  Keep ripple feedback. Add `Semantics(selected: ...)` or use
  `Material`+`InkWell` with proper semantics so accessibility doesn't regress.
- Restructure `_FilterChips` to the grid layout in (4). Keep `kScopeBookOrder`.
- Text may not overflow: 'Doctrine and Covenants' must fit its cell —
  center-aligned, `maxLines: 1`, `TextOverflow.ellipsis`, and verify on a
  320pt-wide layout.
- Update/extend widget tests if any reference `FilterChip`/checkmarks.
- Definition of done: `flutter analyze` clean, `flutter test` passes, no
  layout shift when toggling (identical constraints both states).

STATUS: PASS

## Worker notes
Round 8 (R8.1 + R8.2):

- R8.1: Opaque push transition — ClipRect + ColoredBox(surface) slide,
  no FadeTransition; 200ms easeOutCubic. Views never cross-fade.
- R8.2: Drag handle hoisted above the swap in GameSetupSheet and
  showScriptureScopePicker. Setup title is `pinnedHeader` (outside the
  scroll). Selection/setup headers share 48×48 leading/trailing slots.
  Alignment test: setup vs selection title top-left y match.
- Analyze clean; full suite pass.

## Review findings
Round 8 final — 2026-07-16 15:18 — PASS

- R8.1 resolved (verified in code): opaque push — ClipRect + Stack
  layoutBuilder, each child wrapped in ColoredBox(surface), no
  FadeTransition anywhere in the swap; direction-aware slide (selection
  from right, default from left), 200ms easeOutCubic.
- R8.2 resolved (verified): drag handle hoisted above the swap in both
  sheet paths; headers share 48px leading/trailing slots; alignment test
  asserts setup and selection title top-left y are identical.
- Re-derived: analyze clean; 765/765 tests pass.

### Round 8 — 2026-07-16 15:12 — CHANGES_REQUESTED (product polish, 2 items)

- R8.1 [STANDARD] The view swap "bleeds": AnimatedSwitcher cross-fades the
  outgoing and incoming views while both slide, so for ~250ms both screens
  are semi-transparent on top of each other. Fix: no cross-fade overlap —
  wrap the switcher in a ClipRect and use a push transition where the
  outgoing view slides fully out one way while the incoming slides in from
  the other (both at full opacity, e.g. custom transitionBuilder with
  layoutBuilder stacking, or replace AnimatedSwitcher with an
  AnimationController/Stack or small nested Navigator with a horizontal
  page transition). Opaque throughout — at no point should both views be
  readable through each other. Consider dropping to ~200ms.
- R8.2 [STANDARD] Title misalignment between views: the default view
  renders the drag-handle bar above its title, the selection view doesn't,
  so "Set up Scripture Match" and "Pick specific scriptures" sit at
  different heights and the header visibly jumps during the swap. Fix:
  hoist the drag handle (and its 12px bottom margin) OUT of the swapped
  content so it renders once, always, above both views — in both
  GameSetupSheet and showScriptureScopePicker paths. The two titles must
  sit at the identical y-position (widget test: getTopLeft of the title
  Text in both views matches after the transition settles).
- Definition of done: analyze clean, all tests pass + new alignment test;
  transition is opaque (no bleed) and headers don't jump.

### Round 7 final — 2026-07-16 15:11 — PASS

- R7.1 resolved via the constant-size alternative (0.92 both views, both
  sheet paths); DraggableScrollableController removed (no orphan); slide
  is the only motion, 250ms easeOutCubic both directions. Rationale
  documented in Worker notes — accepted.
- Re-derived: analyze clean; 764/764 tests pass incl. single-tap
  regression.

### Round 7 — 2026-07-16 15:09 — CHANGES_REQUESTED (product polish)

- R7.1 [STANDARD] Opening the selection view causes a visible height jump:
  the sheet expands (0.85 → 0.95 via
  DraggableScrollableController.animateTo) while the content
  simultaneously slide-swaps, and the two motions aren't coordinated —
  the sheet edge visibly pops above where the default view sat. Smooth it:
  - Preferred: synchronize the two animations — same duration AND curve
    for the controller's `animateTo` and the AnimatedSwitcher slide
    (~250ms, Curves.easeOutCubic for both), so the sheet growth and
    content slide read as one motion.
  - If still janky after syncing, alternative: don't resize the sheet at
    all — keep it at the default size for both views (0.9 constant for
    both, single size, zero jump) and let the selection view's
    full-height list simply use the space. Choose whichever reads
    smoother; state which you picked and why in Worker notes.
  - Also cover the reverse direction (Done/back) — no jump on the way
    back down.
- Definition of done: analyze clean, all tests (incl. single-tap
  regression) pass; open/close transition reads as one continuous motion.

### Round 6 final — 2026-07-16 15:08 — PASS

- R6.1 resolved (verified): root cause was `ValueKey(_selectionView)` on
  the DraggableScrollableSheet — first tap remounted the sheet and reset
  the picker's internal state (dead intermediate view). Fixed by removing
  the key and animating expand/collapse via DraggableScrollableController;
  picker state now survives.
- Regression test verified: single tap on 'scope-pick-specific' asserts
  search field visible, entry row + DIFFICULTY absent. Correctly locks the
  first-tap behavior.
- Re-derived: flutter analyze clean; flutter test 764/764 pass.

### Round 6 — 2026-07-16 15:04 — CHANGES_REQUESTED (product bug report)

- R6.1 [BUG] In GameSetupSheet, tapping "Pick specific scriptures" the
  FIRST time does not open the selection view — it re-renders the default
  setup content but with the sheet title missing (only the "DIFFICULTY"
  section label shows). Tapping the row a SECOND time opens the selection
  view correctly, and Done returns to the original setup view.
  - Repro: open Set up Scripture Match → tap "Pick specific scriptures" →
    observe broken intermediate state → tap again → selection view.
  - Likely area: the round-5 restructure moved the sheet's
    title/difficulty/count into the picker's `aboveFilters`/`belowFilters`
    slots and swaps views with AnimatedSwitcher. Suspects: (a) the
    AnimatedSwitcher's children lack distinct/stable keys so the first
    toggle rebuilds the same-typed child (default view) instead of
    transitioning, only picking up the new child on the second state
    change; (b) `_setSelectionView(true)` toggling state on a widget that
    gets recreated by the parent's rebuild (state loss → first tap eaten);
    (c) two nested state holders both tracking "selection open" and the
    first tap only updating the inner one while the outer rebuilds stale.
  - Diagnose the actual cause — do not blind-fix. Then fix so ONE tap
    opens the selection view with the title/header correct throughout.
  - Required test: widget test that pumps GameSetupSheet (matching), taps
    "Pick specific scriptures" ONCE, and asserts the selection view search
    field is visible AND the default view is not. This must fail before
    the fix and pass after (regression lock).
- Definition of done: analyze clean, all tests pass including the new
  single-tap regression test; no visual dead state between views.

### Round 5 final — 2026-07-16 15:01 — PASS

- R5.1 resolved (verified): in-sheet page swap (250ms slide) with
  chevron_right entry row; selection view has back/title/filter summary,
  pinned search, full-height list, pinned "N selected" + Done bar;
  viewInsets.bottom applied in both sheet paths; sheet expands to 0.95
  while selection is open; inline disclosure + 280pt box removed (no
  orphans — remaining "_FilterChips" matches are the private class name,
  not Material FilterChip).
- Worker adaptation accepted: inline embeds without an Expanded parent
  (host lobby) open the selection UI in a nested 0.95 sheet — consistent
  UX, sound reasoning, within spec spirit.
- Re-derived: flutter analyze clean; flutter test 763/763 pass (4 new
  selection-view tests: swap, search, Done/back round-trip, BoM pool).

### Round 5 — 2026-07-16 14:56 — CHANGES_REQUESTED (product UX redesign)

- R5.1 [STANDARD] Rework "Pick specific scriptures" from an inline
  disclosure into an in-sheet page swap. Problem: the search field sits
  mid-sheet with the list below; the keyboard covers both (the sheet has
  no viewInsets handling). Spec:
  - Keep the existing bottom-sheet container (both embeds: GameSetupSheet
    and showScriptureScopePicker). Inside the sheet, introduce two views
    swapped with a horizontal slide transition (~250ms, e.g.
    AnimatedSwitcher + SlideTransition or a nested Navigator):
    1. DEFAULT view — exactly the current content (setup/filters). The
       "Pick specific scriptures" disclosure row becomes a tap-through row
       (chevron_right instead of expand arrows, keep the
       "N of M selected" subtitle).
    2. SELECTION view (replaces the sheet content, full sheet height):
       - Top bar: back arrow (returns to default view, selection kept),
         title "Pick specific scriptures", subtitle with active-filter
         summary via `scope.shortLabel` context (e.g. "Book of Mormon ·
         24 scriptures").
       - Search field pinned directly under the top bar — keyboard can
         never cover it. Give the sheet
         `padding: MediaQuery.viewInsetsOf(context).bottom` so the list
         and bottom bar resize above the keyboard.
       - The list fills all remaining height (no 280pt cap). Pool is the
         ALREADY-FILTERED pool (existing `filterPool` behavior — book and
         status filters apply; this already works, keep it).
       - Pinned bottom bar: "N selected" + a "Done" SelectionPill-styled
         primary button returning to the default view. Optional "Clear"
         text button when N > 0.
     - When the selection view is open the sheet should sit at its max
       size (expand DraggableScrollableSheet to 0.95 or use a fixed-height
       view) so the list gets real estate.
  - No orphans: remove the now-unused inline expansion code
    (_IndividualDisclosure open/close state, the 280pt ConstrainedBox) if
    no longer referenced.
  - Tests: (a) tapping the row swaps to the selection view; (b) search
    filters the list; (c) toggling + Done preserves specificIds in the
    emitted scope; (d) back arrow keeps selection; (e) filtered pool only
    (BoM filter → only BoM scriptures listed). Keep all existing tests
    green.
- Definition of done: analyze clean, all tests pass, search field always
  visible with keyboard open, list fills the sheet, filters pre-applied.

### Round 4 final — 2026-07-16 14:52 — PASS

- R4.2 resolved (verified): shared `SelectionPill` extracted to
  lib/widgets/selection_pill.dart (gradient/dark-mode/disabled/44pt, no
  checkmark, no animation); picker `_Chip` replaced by it (no duplicated
  styling); `_CountSegmented` and `_DifficultyChips` in game_setup_sheet
  migrated — zero ChoiceChip/FilterChip left in either file.
- Re-derived: flutter analyze clean; flutter test 759/759 pass.
- Round 4 complete (R4.1 passed earlier this round).

### Round 4 re-review — 2026-07-16 14:48 — CHANGES_REQUESTED (R4.2 open)

- R4.1 RESOLVED (verified): availability computed status-alone against the
  full corpus; chips get enabled flag with dimmed 0.38 style, onTap null
  when disabled, Semantics(enabled); stale persisted status flags cleared
  on init/restore; tests added (757/757 pass, analyze clean).
- R4.2 STILL OPEN: worker started before this item was added (same race as
  R3.2). Extract shared SelectionPill (lib/widgets/selection_pill.dart),
  migrate `_CountSegmented` + `_DifficultyChips` in game_setup_sheet.dart,
  widget test for count pills. Full spec below under "Round 4".

### Round 4 — 2026-07-16 14:45 — CHANGES_REQUESTED (product request)

- R4.1 [STANDARD] Disable the Needs Review / Nearly Mastered chips when
  their pools are empty. In `lib/widgets/scripture_scope_picker.dart`:
  - In the picker state, compute availability once per build using the
    existing `_lookup` against `scripturesProvider`: a status chip is
    available iff at least one scripture matches that status ALONE
    (`ScriptureScope(needsReview: true)` / `ScriptureScope(nearlyMastered:
    true)` resolved against all scriptures — do NOT AND with the current
    book selection, so availability doesn't flicker as books toggle).
  - `_Chip` gets an `enabled` flag (default true). Disabled state: no
    onTap (InkWell onTap: null so no ripple), fill stays
    `surfaceContainerLow`, label + border at reduced emphasis
    (`onSurfaceVariant.withValues(alpha: 0.38)` label, outlineVariant
    border at 0.5 alpha) — visually distinct from BOTH selected and normal
    unselected. Same fixed size — no layout change.
  - Safety: if a persisted/restored scope has a status flag on while that
    pool is empty, clear that flag on init (and after `_restoreLastUsed`)
    so a disabled chip can never render selected.
  - Add `Semantics(enabled: ...)` so screen readers announce the state.
  - Widget test: with a mastery override where nothing needs review,
    Needs Review chip is disabled (tap does not change scope) and renders
    the dimmed style; with one flagged scripture it is enabled.
- R4.2 [STANDARD] Apply the same selection-pill styling to the count pills
  in `lib/widgets/game_setup_sheet.dart` (`_CountSegmented` — the
  PAIR COUNT / QUESTION COUNT / SESSION LENGTH ChoiceChips):
  - Extract the picker's `_Chip` into a shared public widget —
    `lib/widgets/selection_pill.dart`, `class SelectionPill` — with the
    same API (label, selected, onTap, enabled) and identical styling:
    selected = `AppTheme.selectedChipGradient(context)` + onPrimary w600 +
    primary shadow; unselected = surfaceContainerLow + outlineVariant
    border + onSurfaceVariant @0.8; fixed 44pt height; no checkmark; no
    animation; ellipsis. The picker's `_Chip` becomes a thin re-export or
    is replaced by SelectionPill directly (no duplicated styling code —
    no orphans, single source of truth).
  - Replace both `ChoiceChip`s in `_CountSegmented` with SelectionPill in
    an equal-width 2-cell row (same layout pattern as the status filter
    row in the picker).
  - `_DifficultyChips` in the same file uses the identical legacy
    ChoiceChip style — migrate it to SelectionPill too (4 pills, one row
    of 4 equal cells or 2x2 grid, whichever fits 320pt without ellipsis
    on 'Intermediate'; 2x2 recommended).
  - Widget test: count pills toggle correctly and render no ChoiceChip.
- Definition of done: analyze clean, all tests pass, both status chips
  disabled when their pools are empty, enabled otherwise; count +
  difficulty pills share SelectionPill; no layout shift anywhere.

### Round 3 final — 2026-07-16 14:44 — PASS

- R3.2 resolved: AnimatedContainer/AnimatedDefaultTextStyle/_animDuration all
  removed; plain Container + Text, selection snaps, ripple only.
- Re-derived: flutter analyze clean; flutter test 754/754 pass (worker added
  a selectedChipGradient light/dark test; size-equality test still green).
- PLAN-001 complete: fixed-grid chips, hero gradient light / lifted-blue dark,
  no layout shift, no animation lag, theme tokens only.

### Round 3 re-review — 2026-07-16 14:41 — CHANGES_REQUESTED (one item open)

- R3.1 RESOLVED: `heroGradientDark` (primaryFixedDim → primaryContainer) +
  `selectedChipGradient(context)` added and wired into `_Chip`; light mode
  unchanged; dark label flips via onPrimary. Verified in the diff.
- R3.2 STILL OPEN: `AnimatedContainer`/`AnimatedDefaultTextStyle` and
  `_animDuration` are still in `_Chip` — the worker likely started before
  this finding was updated. To close: replace with plain Container + plain
  Text style, delete `_animDuration`; selection must snap instantly, ripple
  is the only motion. Then re-run analyze + tests and set NEEDS_REVIEW.

### Round 3 — 2026-07-16 14:39 — CHANGES_REQUESTED (product: dark-mode contrast
still insufficient; light mode approved as-is)

- R3.1 [STANDARD] In Midnight mode the navy heroGradient is nearly
  isoluminant with the dark slate surfaces — selected vs unselected can't
  be distinguished. Add a dark-mode selected treatment that INVERTS
  brightness instead of relying on the navy gradient:
  - Add to `app_theme.dart`: `heroGradientDark` = LinearGradient(topLeft →
    bottomRight, colors: [primaryFixedDim /*0xFF9FB4E8*/, primaryContainer
    /*0xFF5C77AE*/]) plus a helper
    `static LinearGradient selectedChipGradient(BuildContext context)`
    returning heroGradient in light, heroGradientDark in dark (same pattern
    as the existing `sidekickGradient(context)` helper).
  - `_Chip` selected state: fill = `AppTheme.selectedChipGradient(context)`;
    label color = `colorScheme.onPrimary` (already flips to darkBackground
    in Midnight — dark text on the light gradient, correct in both modes).
    Keep the existing shadow (colorScheme.primary in dark is light blue, so
    it reads as a glow — good).
  - Do NOT change the light-mode appearance — product approved it.
- R3.2 [STANDARD] (supersedes the earlier "keep it" note) Product reports
  the chip background transition feels slow/not snappy. REMOVE the
  animation: replace `AnimatedContainer` with a plain `Container` (or
  `Ink`) and `AnimatedDefaultTextStyle` with a plain `Text` style — the
  selection change should snap instantly. Keep the InkWell ripple; that's
  the only motion the tap needs. Delete the now-unused `_animDuration`.

Definition of done: analyze clean, tests pass (size-equality test still
green), selected chips clearly light-on-dark in Midnight while light mode
is unchanged.

### Round 2 re-review — 2026-07-16 14:37 — PASS

- Re-derived: flutter analyze clean; flutter test 753/753 pass (size-equality
  test at 320pt still green).
- R2.1 resolved: unselected = surfaceContainerLow + onSurfaceVariant @0.8 +
  outlineVariant border; selected = heroGradient + primary-tinted shadow
  (blur 8, offset 0,2, alpha 0.35). Border width identical both states.
- R2.2 resolved (amended): dark surfaceContainerHighest existed inline
  (0xFF46577F) — my finding overstated "never sets". Worker correctly
  promoted it to a named token `AppTheme.darkSurfaceContainerHighest`
  (0xFF445580). Contrast fix comes primarily from R2.1's move to
  surfaceContainerLow, which in Midnight is 0xFF2B3757 vs the 0xFF2F4374 →
  0xFF5C77AE gradient + shadow — clearly distinct.
- R2.3 resolved: 150ms AnimatedContainer + AnimatedDefaultTextStyle, easeOut.

### Round 2 — 2026-07-16 14:33 — CHANGES_REQUESTED (design feedback from product)

- R2.1 [STANDARD] Selected/unselected chip contrast is too low. Fix in
  `lib/widgets/scripture_scope_picker.dart` `_Chip`:
  - Unselected: recede it. Fill = `colorScheme.surfaceContainerLow`
    (a step darker/quieter than the current surfaceContainerHighest),
    label `onSurfaceVariant` at 80% opacity
    (`.withValues(alpha: 0.8)` on the color — token-derived, not hardcoded),
    keep the 1px `outlineVariant` border.
  - Selected: pop it. Keep `AppTheme.heroGradient` + `onPrimary` w600, and
    add a soft elevation shadow (BoxShadow using
    `colorScheme.primary.withValues(alpha: 0.35)`, blur ~8, offset (0,2))
    so gradient chips visibly lift off the sheet.
  - Constraint: identical box size both states (shadow paints outside the
    border box, so no layout shift — keep the size-equality widget test).
- R2.2 [BUG] Dark theme never sets `surfaceContainerHighest` (see
  `app_theme.dart` getDarkTheme — only lowest/low/container/high are set),
  so in Midnight mode the unselected chip fill falls back to a Flutter
  default that sits nearly on top of the navy gradient. Add an explicit
  `surfaceContainerHighest` (suggest `Color(0xFF445580)`, one step above
  darkSurfaceContainerHigh `0xFF3B4A6E`) so the surface ramp is complete —
  this fixes contrast for every widget using that token, not just chips.
- R2.3 [NIT, optional] Consider AnimatedContainer/AnimatedSwitcher (~150ms)
  on the chip decoration so the gradient fade-in feels intentional.

Definition of done: analyze clean, all tests pass, size-equality test still
green, visually distinct selected vs unselected in BOTH light and Midnight.

### Round 1 re-review — 2026-07-16 14:28 — PASS

- Re-derived: flutter analyze clean (0 issues); flutter test 753/753 pass
  (includes the 2 new widget tests).
- R1.1 resolved: FilterChip gone; fixed 44pt grid cells (2-col books +
  status row); selected = AppTheme.heroGradient with onPrimary w600;
  unselected = surfaceContainerHighest + outlineVariant 1px border
  (transparent same-width border when selected — no edge jump); labels
  centered, maxLines 1, ellipsis; Semantics(selected) present.
- Widget test verifies identical chip size before/after toggle at 320pt.
- Theme tokens only; no orphaned code.

### Round 1 findings (resolved) — CHANGES_REQUESTED

- R1.1 [STANDARD] Implement PLAN-001 (see ## Plan above): replace the
  FilterChip checkmark chips in `lib/widgets/scripture_scope_picker.dart`
  with fixed-size selection controls — no layout shift on toggle, selected
  fill = `AppTheme.heroGradient` with `onPrimary` label, unselected = dark
  surface token with subtle border, even 2-column grid for the 4 book
  filters + equal-width row for the 2 status filters, theme tokens only.
  Full spec and implementation notes are in the Plan section. Definition of
  done: `flutter analyze` clean, `flutter test` passes, no text overflow at
  320pt width.

## History

### Round 0 — ad-hoc review of ScriptureScope refactor — PASS (2026-07-16 14:05)
- flutter analyze: clean (0 issues); flutter test: 751/751 pass
- ScriptureScope refactor (sealed variants → composable filter) sound; legacy JSON + Hive payloads migrate correctly with tests.
- Matching-game difficulty cap regression fixed and covered by tests.
- Host lobby empty-scope guard correct (prevents empty filter widening to full corpus on the wire).
- Non-blocking: picker mastery lookup uses ref.read, so status chips don't live-update while the sheet is open. Pre-existing; fine to leave.
