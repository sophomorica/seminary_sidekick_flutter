## What This App Is

A focused scripture mastery tool for the 100 Doctrinal Mastery scriptures of The Church of Jesus Christ of Latter-day Saints.

The core loop is **Study → Build → Prove → Master**. Users study the text, then use **Scripture Builder** (the primary mastery tool) to progressively prove they can reproduce it from memory. Supplementary practice tools (Scripture Match, Quick Quiz) help with recognition and comprehension but do not gate mastery.

The viral mechanic is **Class Play** (Group Play) — Kahoot-style live multiplayer rounds for the whole seminary class. One teacher running a live round = 20-30 students opening the app at once; it's the highest-leverage growth lever the brand has and the feature that turns "great scripture mastery app" into "the defacto seminary app." **Shipped (v1, 2026-05)**: Supabase-backed (Realtime + anonymous auth), 4-letter join codes + QR, two game modes — live Quick Quiz and Scripture Builder Race — with lobby, countdown, answer-distribution reveal, live leaderboard with rank deltas, podium results, and free/premium host tiers (6-player casual vs 30-player class rooms). See TASK-048's decomposition (TASK-051–062) in `TODO.md` and `SUPABASE_SETUP.md` for the backend runbook. Group play NEVER writes to personal mastery/progress — it's purely social.

**Key UX principle**: The path to mastery must be obvious. When a user opens a scripture, they should immediately see where they are on the mastery path, what to do next, and what “mastered” means. Scripture Builder lives directly under each scripture as the central mastery tool.

**Landing principle**: The app should open to **"Let's Learn / Let's Play"** — not a dashboard. Home is the jumping-off point to study and practice. Stats, progress rings, and long descriptions belong on the Stats tab, not on the first thing a kid sees. Keep Home punchy: pick up where you left off, start a quick quiz, launch Scripture Builder. The dashboard view is reachable via the Stats tab for users who want it.

**Design philosophy**: Fun first with warm, satisfying feedback (animations, haptics, confetti, progressive difficulty). The experience is reverent and purposeful while remaining engaging for seminary students. The primary success metrics are **engagement with friends and mastery retention** — we want kids to come back on their own AND invite their seminary group to play together.

**Status**: Free-tier MVP complete. Premium tier (Seminary Sidekick AI — Grok-powered journal prompts, reflection questions, smart goals, timeline insights, chat) built. Group Play v1 (quiz + Scripture Builder race) shipped end-to-end. Code-side launch readiness verified claim-by-claim in `LAUNCH_READINESS_REPORT.md` (2026-07-01). **iOS v1.0.0 (build 2) is WAITING FOR REVIEW since 2026-07-05** — build 1 was rejected in processing (ITMS-91061: `share_plus` 7.2.2 missing privacy manifest; fixed by bumping to `share_plus` ^10.1.4 and version 1.0.0+2), build 2 uploaded, swapped onto the version, and the submission resubmitted same day. Screenshots, listing, privacy labels, subscriptions all in; sidekick-proxy premium gate enforcing. What's still open (Supabase auto-pause decision, post-approval RevenueCat tidy-up, group-play smoke test, Android) lives in the "🚀 Launch Status" section at the top of `TODO.md`.

**Business model**: Freemium.

- **Free tier** = Full mastery loop (Scripture Builder, Practice tools, spaced repetition, progress tracking, activity feed).
- **Premium tier** = Seminary Sidekick AI (JSON snapshot → structured response), journal with dynamic prompts, curriculum awareness, gentle reminders, and light engagement layers.

