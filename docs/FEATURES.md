## Mastery Tool: Scripture Builder

Scripture Builder is the PRIMARY mastery tool. It lives under each scripture (accessed from scripture detail), not in the quizzes/games hub. It's how you prove you know a scripture. The four difficulty tiers map directly to mastery levels:

- **Beginner** (chunk-tap): 3-word chunks, tap in order → earns **Learning** mastery
- **Intermediate** (chunk-tap): 2-word chunks + distractors from other scriptures → earns **Familiar** mastery
- **Advanced** (typing): Type the passage with first-letter hints. Wrong char turns red, must backspace → earns **Memorized** mastery
- **Master** (typing): Blind typing (all underscores), judged **per word, not per keystroke**: the field holds one word at a time, OS autocorrect is enabled, and the word is only checked when committed with the spacebar (`WordCommitEngine`). A wrong word resets everything. Typing-only (no mic — see TASK-069 for the future premium AI voice recite feature) → 3 consecutive perfect runs earns **Mastered**

**Shortcut rule**: If a user can complete Master difficulty perfectly, they've proven mastery regardless of whether they did Beginner/Intermediate/Advanced. The system should recognize this (planned — see TODO.md TASK-031).

### Study Tool: Memorize

Study aid accessed from scripture detail. Two modes: First Letter (progressive shrink to first letter then underscore) and Full Hide (straight to underscores). Tap words to toggle, or use Hide Next / Reveal All / Hide All. This is for studying — no mastery progression attached.

### Supplementary Quizzes (not mastery-gating)

These help with recognition and comprehension but do NOT drive mastery. They live in a "Practice" or "Quizzes" tab (currently called "Games" — rename planned).

- **Scripture Match**: Two columns — key phrases vs references. Tap-to-select to match. Tests reference recognition.
- **Quick Quiz**: Given a passage/reference, select correct key phrase/reference from 4 choices. Three question types rotate. Tests comprehension.

