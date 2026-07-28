# iOS Take-Home Brief — Ami Engineering Candidates

## The Assignment

### Build a "Nearby Friends" mini-feature

Given a set of users with last-known coordinates and timestamps, build a self-contained iOS feature that:

1. **Renders users on a map** — show each user at their last-known location. You're free to use whatever Map technology you see fit.
2. **Handles staleness** — locations older than 30 minutes should display differently (e.g. grayed out, different icon, explicit label)
3. **Triggers a notification** — when a new "nearby" user appears (within a fixed 500m radius), fire a local notification. If several users become nearby at the same time, group them into a single notification rather than firing one per user
4. **Follow a user** — alongside the map, show the users in a list; tapping a user (in the list *or* on the map) focuses the map on that person and *keeps* the map centered on them as their location updates. Following continues until the user stops it — including by manually panning the map away, which should break the follow

No backend needed — this starter includes a mock data source (see below). Use it as-is, extend it, or replace it.

**Build it like production.** This is a small, time-boxed exercise, but build it the way you'd build a feature meant to ship in a large, long-lived production app — not a throwaway demo. Structure, separation of concerns, clear naming, and decisions you'd be comfortable defending in code review matter to us as much as a working feature. Scope small, but build it properly.

---

## What's Included

Everything you need to start — no project setup, no backend:

- **`BRIEF.md`** — this document.
- **`Friend.swift`** — the data model. A `Friend` has an `id`, a `displayName`, a last-known `coordinate`, and a `lastUpdated` timestamp. It's deliberately plain: how you interpret it (stale vs. fresh, nearby vs. not) and how you render it are up to you.
- **`MockFriendService.swift`** — a mock data source so you can focus on the feature, not the plumbing:
  - `MockFriendService.seed` — a one-shot snapshot, for a static approach.
  - `start(onUpdate:)` / `stop()` — a live feed that emits an updated `[Friend]` roughly every couple of seconds (friends drift; one walks into range). It's delivered via a plain callback, so you can adapt it to whichever reactivity approach you choose.
  - `MockFriendService.currentUserLocation` — a reference point for "you," or use Core Location if you prefer.
- **`demo.mp4`** — a short screen recording of what a finished version looks like.

Drop these into a fresh native iOS app and build from there.

---

## Using AI

AI tools and any other resources are completely allowed with no restrictions. Note that to understand your AI process, we ask that you submit your AI session transcript with your submission.

--
## Submission

Send us a single **`.zip`** containing:

- **Your project** — the full, buildable Xcode project.
- **DECISIONS.md** — a file titled 'DECISIONS.md': that documents any key decisions you made - choices in technology, software design decisions, and any other explanations that you think are relevant.
- **Your AI conversation/transcript** — if you used AI tools, include the transcript(s) (e.g. in a `transcripts/` folder). See below for how to export.

### Exporting your AI transcript

If you used **Claude Code**, the simplest way to export a session:

- Run the `/export` slash command inside your Claude Code session. It exports the current conversation — save it to a file and include it in your zip.
- Alternatively, raw session transcripts are stored on disk as JSONL under `~/.claude/projects/<your-project-path>/` — you can include the relevant `.jsonl` file directly.

If you used another AI tool (Cursor, ChatGPT, etc.), just export or share the conversation however that tool allows and include it — a link or a pasted `.md`/`.txt` is fine.
