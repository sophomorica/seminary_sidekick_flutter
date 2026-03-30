# Mastery System Redesign

> **Status**: Proposal
> **Date**: 2026-03-30
> **Problem**: "Mastered" currently means ≥95% accuracy on a single game type. You can earn it by spamming beginner-level matching rounds without ever proving you can actually recall the words.

---

## The Core Change

**Mastery becomes holistic.** Instead of tracking mastery per game type, a scripture's mastery level is computed across ALL game types, difficulty tiers, and recency. The per-game `UserProgress` records stay (they're useful data), but the mastery badge on a scripture reflects a composite judgment.

---

## What Each Level Means

### 1. New (gray)
You haven't touched this scripture yet.

- **Requirement**: Zero attempts on any game type.
- **Sub-progress**: None.

### 2. Learning (orange)
You've started engaging with this scripture.

- **Requirements**:
  - At least 1 game type attempted
  - At least 1 correct attempt anywhere
- **Sub-progress toward Familiar**: Percentage of Familiar requirements met (see below).

### 3. Familiar (yellow)
You can recognize this scripture — you know the reference, the key phrase, and the general shape of the passage.

- **Requirements**:
  - **Matching Game**: Completed at Beginner difficulty or higher
  - **At least 2 game types** attempted with ≥1 correct each
  - **Overall accuracy** ≥ 60% (aggregated across all game types for this scripture)
  - **At least 5 total attempts** across all games
- **Sub-progress toward Memorized**: Percentage of Memorized requirements met.

### 4. Memorized (green)
You can recall the passage with minimal prompts. You've proven you can *produce* the words, not just recognize them.

- **Requirements**:
  - **Word Builder**: Completed at Advanced difficulty (typing mode — first letters as hints)
  - **Matching Game**: Completed at Intermediate difficulty or higher
  - **Overall accuracy** ≥ 80%
  - **At least 15 total attempts** across all games
  - **Practiced within the last 21 days** (any game type counts)
- **Sub-progress toward Mastered**: Percentage of Mastered requirements met.

### 5. Mastered (blue)
Full recall at the highest difficulty. You can type this scripture blind. This badge means something.

- **Requirements**:
  - **Word Builder**: Completed at **Master** difficulty (blind typing, any error resets everything)
  - **Matching Game**: Completed at Advanced difficulty or higher
  - **Quiz** (when available): Completed at Intermediate difficulty or higher
  - **Overall accuracy** ≥ 90%
  - **At least 25 total attempts** across all games
  - **Practiced within the last 14 days**
- **Note**: Quiz requirement is waived until the Quiz game is fully implemented. Once it ships, existing "Mastered" scriptures get a grace period to complete it.

---

## Gentle Decay

Mastery is maintained, not just earned. But we're gentle about it.

| Time since last practice | What happens |
|---|---|
| 0–14 days | Full mastery. Badge is bright and proud. |
| 14–30 days | **"Needs Review"** flag appears. Badge gets a subtle dimming (reduced opacity or a small clock icon overlay). Level does NOT drop. |
| 30+ days | Level drops by one tier (Mastered → Memorized, Memorized → Familiar). The data isn't lost — you just need to re-prove it with a quick session. |

**Floor rule**: A scripture never drops below **Familiar** due to time decay alone. If you once proved you can type it, you still know it at some level. Only active negative performance (accuracy dropping) can push you below Familiar.

---

## Sub-Progress Within Each Level

Each level shows a progress bar indicating how close you are to the next one. This is calculated as:

```
progress = (requirements met for next level) / (total requirements for next level)
```

Each requirement is weighted equally. For example, if "Memorized" has 5 requirements and you've met 3, you're at 60% within the "Familiar" level.

Requirements are binary (met/not met) except for accuracy and attempt count, which are proportional:
- Accuracy: `min(1.0, currentAccuracy / requiredAccuracy)`
- Attempt count: `min(1.0, currentAttempts / requiredAttempts)`

This means you always see the bar moving forward with every session, even if you haven't cleared a full checkpoint yet.

---

## Data Model Changes

### Keep: `UserProgress` (per scripture × game type)
No changes. This still tracks accuracy, streaks, best time, highest difficulty per game. It's the raw data.

### Add: `ScriptureMastery` (per scripture — computed, not stored)
This is derived from the `UserProgress` records for a given scripture across all game types.

```dart
class ScriptureMastery {
  final String scriptureId;
  final MasteryLevel level;            // The holistic mastery level
  final double subProgress;            // 0.0–1.0 progress toward next level
  final bool needsReview;              // True if any decay flag is active
  final DateTime? lastPracticedAny;    // Most recent practice across all games
  final Map<GameType, DifficultyLevel> highestDifficultyPerGame;
  final double overallAccuracy;        // Weighted across all game types
  final int totalAttemptsAllGames;
  final List<MasteryRequirement> nextLevelRequirements; // For UI: show what's left
}
```

### Add: `MasteryRequirement` (for UI display)
```dart
class MasteryRequirement {
  final String description;    // e.g., "Complete Word Builder at Advanced"
  final bool isMet;
  final double progress;       // 0.0–1.0 for partial requirements
}
```

### New Provider: `scriptureMasteryProvider`
A `Provider.family<ScriptureMastery, String>` that watches all `UserProgress` entries for a given scripture ID and computes the holistic mastery.

---

## What Changes in the UI

### Scripture Detail Screen
Currently shows 3 separate mastery badges (one per game type). **Replace with**:
- One large holistic mastery badge with level name + sub-progress bar
- Below it: a "Requirements" card showing what's been met and what's next (checkboxes)
- Below that: per-game-type cards still exist but show difficulty progress, not mastery level

### Scripture List Screen
Mastery badge already shows per-scripture. Just wire it to the new holistic provider instead of a single game type.

### Progress Screen
Update stats to use holistic mastery counts (total mastered = scriptures at Mastered level holistically).

### Home Screen
"Continue Learning" section can prioritize scriptures that are close to leveling up (high sub-progress) or need review (decay flag).

---

## Why This Works

The key insight is that the games test *different cognitive skills*:

- **Matching** tests **recognition** — can you connect a reference to its key phrase?
- **Word Builder** tests **recall** — can you produce the actual words from memory?
- **Quiz** tests **comprehension** — can you identify what a passage is about from context?

True memorization requires all three. Someone who can match references but can't type the words hasn't memorized anything. Someone who can type the words but doesn't know the reference hasn't fully learned the scripture. The new system ensures you've proven all dimensions before earning the badge.

The difficulty progression within Word Builder is especially important: beginner/intermediate use tapping (recognition), but advanced/master require typing (production). Requiring Master-level Word Builder for the Mastered badge means you literally typed the entire scripture from memory with zero errors. That's real mastery.

---

## Migration

Existing progress data is preserved. When the new system ships:
1. All per-game `UserProgress` records stay exactly as they are
2. Holistic mastery is recomputed from existing data on first load
3. Some users may see their mastery level drop (e.g., from "Mastered" on matching to "Familiar" holistically). This is expected and correct — they now have clear goals to work toward.
4. A one-time toast/modal explains the change: "We've upgraded the mastery system! Your progress is safe — mastery now reflects your skill across all practice modes."
