## Mastery Tool: Scripture Builder

Scripture Builder is the PRIMARY mastery tool. It lives under each scripture (accessed from scripture detail), not in the quizzes/games hub. It's how you prove you know a scripture. The four difficulty tiers map directly to mastery levels:

- **Beginner** (chunk-tap): adaptive word chunks, tap in order → earns **Learning** mastery
- **Intermediate** (chunk-tap): adaptive word chunks + distractors from other scriptures → earns **Familiar** mastery

**Adaptive chunking** (Beginner / Intermediate): target-chunk-count strategy calibrated to 1 Nephi 3:7 (56 words). Formula: `chunkSize = clamp(ceil(wordCount / cap), baseSize, maxSize)`. Beginner: cap 19, base 3, max 8. Intermediate: cap 28, base 2, max 6. Passages ≤ 56 words keep the historic 3-word / 2-word sizes; longer passages grow chunk size so tap counts stay bounded. Chunking is purely positional (every `chunkSize` words) — deterministic, no phrase/punctuation snapping.
- **Advanced** (typing): Type the passage with first-letter hints. Wrong char turns red, must backspace → earns **Memorized** mastery
- **Master** (typing): Blind typing (all underscores), judged **per word, not per keystroke**: the field holds one word at a time, OS autocorrect is enabled, and the word is only checked when committed with the spacebar (`WordCommitEngine`). A wrong word resets everything. Typing-only (no mic — see TASK-069 for the future premium AI voice recite feature) → 3 consecutive perfect runs earns **Mastered**

**Shortcut rule**: If a user can complete Master difficulty perfectly, they've proven mastery regardless of whether they did Beginner/Intermediate/Advanced. The system should recognize this (planned — see TODO.md TASK-031).

### Study Tool: Memorize

Study aid accessed from scripture detail. Two modes: First Letter (progressive shrink to first letter then underscore) and Full Hide (straight to underscores). Tap words to toggle, or use Hide Next / Reveal All / Hide All. This is for studying — no mastery progression attached.

### Supplementary Quizzes (not mastery-gating)

These help with recognition and comprehension but do NOT drive mastery. They live in a "Practice" or "Quizzes" tab (currently called "Games" — rename planned).

- **Scripture Match**: Two columns — key phrases vs references. Tap-to-select to match. Tests reference recognition.
- **Quick Quiz**: Given a passage/reference, select correct key phrase/reference from 4 choices. Three question types rotate. Tests comprehension.

### Results feedback (solo)

Scripture Builder, Scripture Match, and Quick Quiz all share `GameResultsScreen`. After a round the player sees an animated **score meter** (0–1000) with a word grade — **Masterful**, **Strong**, **Getting there**, or **Keep practicing** — not a three-star rating. Below the meter, a **mastery avatar** stage (Quick to Observe → Stalwart → Stripling Warrior → Standard Bearer) advances from how many scriptures they’ve Mastered overall. Provider `starRating` getters remain for internal/legacy call sites; the results UI does not show stars.

Group Play Scripture Builder race finish banners still use mistake-based star pips for that social mode only — separate from the solo meter.

