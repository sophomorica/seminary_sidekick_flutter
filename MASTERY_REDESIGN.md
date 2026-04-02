# Mastery System Redesign

> **Status**: In Progress (implementation ~80% complete)
> **Date**: 2026-04-02 (revised from 2026-03-30)
> **Problem**: "Mastered" previously meant >= 95% accuracy on a single game type. You could earn it by spamming beginner-level matching rounds without ever proving you can recall the words.

---

## The Core Change

**Mastery is driven by Word Builder progression.** The mastery path is a clear, linear journey through Word Builder difficulty tiers. Scripture Match and Quiz are helpful recognition/comprehension tools but do NOT gate mastery — only Word Builder does.

The per-game `UserProgress` records stay (they're useful data), but the mastery badge on a scripture reflects your Word Builder progression.

---

## The Linear Mastery Path

Each level maps directly to a Word Builder difficulty tier:

### 1. New (gray)
You haven't started Word Builder for this scripture yet.

### 2. Learning (orange)
You've completed Word Builder at **Beginner** difficulty (tap 3-word chunks into order).

### 3. Familiar (yellow)
You've completed Word Builder at **Intermediate** difficulty (tap 2-word chunks with distractor words mixed in).

### 4. Memorized (green)
You've completed Word Builder at **Advanced** difficulty (typed with first-letter hints — real recall starts here).

### 5. Mastered (blue)
You've achieved **3 consecutive perfect completions** at Word Builder **Master** difficulty (blind typing, no hints, timed). This badge means something — you proved you can type the entire scripture from memory, perfectly, three times in a row.

- The `consecutivePerfectMaster` counter tracks this. Any failure at Master difficulty resets it to 0.
- Completions are timed (best time is recorded).

### 6. Eternal (gold)
You've sustained Mastered status for **6 continuous months** (183 days). Once earned, this badge is **permanent** — no decay, no review needed, ever.

This represents a scripture that has truly been "engraven upon your heart."

---

## Gentle Decay

Mastery is maintained, not just earned. But we're gentle about it.

| Time since last practice | What happens |
|---|---|
| 0-14 days | Full mastery. Badge is bright and proud. |
| 14-30 days | **"Needs Review"** flag appears. Badge gets subtle dimming (reduced opacity + clock icon overlay). Level does NOT drop. |
| 30+ days | Level drops by one tier (Mastered -> Memorized, Memorized -> Familiar). The data isn't lost — you just need to re-prove it with a quick session. |

**Floor rule**: A scripture never drops below **Familiar** due to time decay alone. If you once proved you can type it at Advanced, you still know it at some level.

**Exception**: Eternal scriptures never decay. Once earned, the badge is permanent.

---

## Sub-Progress Within Each Level

Each level shows a progress bar indicating how close you are to the next one. Since the path is linear through Word Builder, progress is straightforward:

- **New -> Learning**: Complete WB Beginner (binary)
- **Learning -> Familiar**: Complete WB Intermediate (binary)
- **Familiar -> Memorized**: Complete WB Advanced (binary)
- **Memorized -> Mastered**: Two requirements — reach WB Master difficulty + get 3 consecutive perfect runs (progressive: 0/3, 1/3, 2/3, 3/3)
- **Mastered -> Eternal**: Days sustained at Mastered (progressive: days/183)

The progress bar always moves forward with each session, giving clear feedback.

---

## Data Model

### `UserProgress` (per scripture x game type)
Added `consecutivePerfectMaster` field (int, default 0). Tracks consecutive perfect completions at Master difficulty for the Word Builder game type. Resets to 0 on any failure at Master. Backward compatible — existing Hive data defaults to 0.

### `ScriptureMastery` (per scripture — computed, not stored)
Derived from the `UserProgress` records. Now includes `consecutivePerfectMaster` for display in the UI path visualization.

Key fields: `level`, `subProgress`, `needsReview`, `lastPracticedAny`, `highestDifficultyPerGame`, `overallAccuracy`, `totalAttemptsAllGames`, `nextLevelRequirements`, `consecutivePerfectMaster`, `masteredSince`.

### `MasteryDatesNotifier` (Hive-backed)
Tracks `masteredSince` timestamps and permanent Eternal status. When a scripture first reaches Mastered, the date is recorded. If it drops, the date is cleared (clock resets). When 6 months pass, Eternal is conferred permanently via a sentinel date.

---

## What Changed in the UI

### Scripture Detail Screen
- **"Mastery Path" section** replaces the old "Your Progress" section
- Shows a **linear timeline visualization** of the Word Builder journey (Beginner -> Intermediate -> Advanced -> Master -> Eternal) with checkmarks for completed steps
- **"Next Step" card** shows exactly what you need to do next (clear, actionable)
- **"Practice Tools" card** shows per-game progress but reframes Match/Quiz as supplementary recognition tools
- Word Builder is visually emphasized as the mastery driver

### Scripture List / Card
Uses holistic `scriptureMasteryProvider` for the badge.

### Progress Screen
Uses `holisticStatsProvider` for aggregate counts. Shows Eternal count when > 0.

### Home Screen
"Continue Learning" prioritizes scriptures needing review or close to leveling up.

---

## Why Word Builder Is The Path

The key insight: Word Builder is the only game that actually tests *production* — can you produce the words from memory? The other games test recognition and comprehension, which are valuable but different cognitive skills.

The Word Builder difficulty tiers map perfectly to increasing levels of recall:
- **Beginner**: Ordering chunked phrases (guided assembly)
- **Intermediate**: Ordering with distractors (selective recognition)
- **Advanced**: Typing with first-letter hints (prompted recall)
- **Master**: Blind typing (full recall)

Scripture Match and Quiz are still valuable — they help you learn references, key phrases, and context. But they don't prove you've memorized the actual words. Only Word Builder does that.

---

## Migration

Existing progress data is preserved. When the new system runs:
1. All per-game `UserProgress` records stay exactly as they are
2. Holistic mastery is recomputed from existing data on first load
3. Some users may see their mastery level change based on their Word Builder progress. This is expected — they now have a clear path to work toward.
4. The `consecutivePerfectMaster` field defaults to 0 for existing records (backward compatible).
